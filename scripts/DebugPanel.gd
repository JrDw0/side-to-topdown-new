extends Control

## 启动关卡时是否默认展开调试面板。
@export var default_expanded := true
## 自动生成选关列表时扫描的关卡目录。
@export_dir var levels_directory := "res://scenes/levels"
## 是否递归扫描“关卡目录”下的子文件夹，用于按分类文件夹整理关卡。
@export var scan_subdirectories := true
## 自动选关列表中需要排除的场景路径，例如测试场景或旧入口场景。
@export var excluded_level_scene_paths := PackedStringArray([
	"res://scenes/levels/Main.tscn",
])
## 面板距离视口左上角的边距，单位为像素。
@export var panel_margin := Vector2(16.0, 16.0)

@onready var expanded_panel: PanelContainer = $ExpandedPanel
@onready var collapsed_button: Button = $CollapsedButton
@onready var collapse_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/Header/CollapseButton
@onready var level_option: OptionButton = $ExpandedPanel/MarginContainer/VBoxContainer/LevelRow/LevelOption
@onready var enter_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/LevelRow/EnterButton
@onready var previous_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/FlowGrid/PreviousButton
@onready var next_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/FlowGrid/NextButton
@onready var restart_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/FlowGrid/RestartButton
@onready var first_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/FlowGrid/FirstButton
@onready var complete_button: Button = $ExpandedPanel/MarginContainer/VBoxContainer/FlowGrid/CompleteButton
@onready var status_label: Label = $ExpandedPanel/MarginContainer/VBoxContainer/StatusLabel

var _expanded := true
var _current_level_index := -1
var _level_scene_paths := PackedStringArray()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expanded_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	collapsed_button.mouse_filter = Control.MOUSE_FILTER_STOP

	_connect_signals()
	_build_level_options()
	_select_current_level()
	_apply_panel_margin()
	_set_expanded(default_expanded)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_panel"):
		_set_expanded(not _expanded)
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	collapse_button.pressed.connect(_on_collapse_pressed)
	collapsed_button.pressed.connect(_on_expand_pressed)
	enter_button.pressed.connect(_on_enter_pressed)
	previous_button.pressed.connect(_on_previous_pressed)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	first_button.pressed.connect(_on_first_pressed)
	complete_button.pressed.connect(_on_complete_pressed)
	level_option.item_selected.connect(_on_level_selected)


func _build_level_options() -> void:
	level_option.clear()
	_level_scene_paths = _find_level_scene_paths()
	for index in range(_level_scene_paths.size()):
		level_option.add_item(_get_level_display_name(_level_scene_paths[index]), index)

	if _level_scene_paths.is_empty():
		status_label.text = "未找到关卡：" + _normalize_directory_path(levels_directory)
		enter_button.disabled = true
		previous_button.disabled = true
		next_button.disabled = true
		first_button.disabled = true


func _select_current_level() -> void:
	var current_path := ""
	if get_tree().current_scene != null:
		current_path = get_tree().current_scene.scene_file_path

	_current_level_index = _level_scene_paths.find(current_path)
	if _current_level_index >= 0 and _current_level_index < level_option.item_count:
		level_option.select(_current_level_index)
	elif level_option.item_count > 0:
		_current_level_index = level_option.get_selected_id()
	else:
		_current_level_index = -1

	_refresh_flow_buttons()


func _refresh_flow_buttons() -> void:
	var has_level := level_option.item_count > 0 and _current_level_index >= 0
	enter_button.disabled = not has_level
	previous_button.disabled = not has_level or _current_level_index <= 0
	next_button.disabled = not has_level or _current_level_index >= level_option.item_count - 1
	first_button.disabled = not has_level or _current_level_index == 0

	if not has_level:
		status_label.text = "当前关卡：未识别"
	elif get_tree().current_scene != null:
		status_label.text = "当前关卡：" + get_tree().current_scene.name


func _set_expanded(expanded: bool) -> void:
	_expanded = expanded
	expanded_panel.visible = _expanded
	collapsed_button.visible = not _expanded


func _apply_panel_margin() -> void:
	var expanded_size := expanded_panel.size
	if expanded_size == Vector2.ZERO:
		expanded_size = Vector2(360.0, 210.0)
	expanded_panel.position = panel_margin
	expanded_panel.size = expanded_size
	collapsed_button.position = panel_margin


func _change_to_level(index: int) -> void:
	if index < 0 or index >= _level_scene_paths.size():
		return

	var scene_path := _level_scene_paths[index]
	if not ResourceLoader.exists(scene_path):
		status_label.text = "关卡不存在：" + scene_path
		return

	get_tree().call_deferred("change_scene_to_file", scene_path)


func _find_level_scene_paths() -> PackedStringArray:
	var level_paths: Array[String] = []
	_collect_level_scene_paths(_normalize_directory_path(levels_directory), level_paths)
	level_paths.sort()
	return PackedStringArray(level_paths)


func _collect_level_scene_paths(directory_path: String, level_paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if file_name == "." or file_name == "..":
			file_name = directory.get_next()
			continue

		var path := directory_path.path_join(file_name)
		if directory.current_is_dir():
			if scan_subdirectories:
				_collect_level_scene_paths(path, level_paths)
		elif file_name.get_extension() == "tscn" and _should_include_level_scene(path):
			level_paths.append(path)

		file_name = directory.get_next()
	directory.list_dir_end()


func _should_include_level_scene(scene_path: String) -> bool:
	if scene_path in excluded_level_scene_paths:
		return false
	return ResourceLoader.exists(scene_path, "PackedScene")


func _get_level_display_name(scene_path: String) -> String:
	var file_name := scene_path.get_file().get_basename()
	return file_name.replace("_", " ")


func _normalize_directory_path(directory_path: String) -> String:
	return directory_path.trim_suffix("/")


func _on_collapse_pressed() -> void:
	_set_expanded(false)


func _on_expand_pressed() -> void:
	_set_expanded(true)


func _on_level_selected(index: int) -> void:
	_current_level_index = level_option.get_item_id(index)
	_refresh_flow_buttons()


func _on_enter_pressed() -> void:
	_change_to_level(_current_level_index)


func _on_previous_pressed() -> void:
	_change_to_level(_current_level_index - 1)


func _on_next_pressed() -> void:
	_change_to_level(_current_level_index + 1)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_first_pressed() -> void:
	_change_to_level(0)


func _on_complete_pressed() -> void:
	var level := get_tree().current_scene
	if level != null and level.has_method("complete_level"):
		level.complete_level()
