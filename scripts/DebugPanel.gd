extends Control

## 启动关卡时是否默认展开调试面板。
@export var default_expanded := true
## 选关下拉框显示的中文名称，需要与“关卡场景路径列表”一一对应。
@export var level_display_names := PackedStringArray([
	"第 1 关：视角切换",
	"第 2 关：推箱平台",
	"第 3 关：箱子压制",
	"第 4 关：模式冰面",
	"第 5 关：飞行陷阱",
])
## 选关下拉框使用的场景路径，需要与“关卡显示名称列表”一一对应。
@export var level_scene_paths := PackedStringArray([
	"res://scenes/Level01_SwitchCamera.tscn",
	"res://scenes/Level02_BoxPlatform.tscn",
	"res://scenes/Level03_BoxCrush.tscn",
	"res://scenes/Level04_ModeIceArea.tscn",
	"res://scenes/Level05_FlyingTrap.tscn",
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
	var option_count := mini(level_display_names.size(), level_scene_paths.size())
	for index in range(option_count):
		level_option.add_item(level_display_names[index], index)

	if option_count == 0:
		status_label.text = "未配置关卡"
		enter_button.disabled = true
		previous_button.disabled = true
		next_button.disabled = true
		first_button.disabled = true


func _select_current_level() -> void:
	var current_path := ""
	if get_tree().current_scene != null:
		current_path = get_tree().current_scene.scene_file_path

	_current_level_index = level_scene_paths.find(current_path)
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
	if index < 0 or index >= level_scene_paths.size():
		return

	var scene_path := level_scene_paths[index]
	if not ResourceLoader.exists(scene_path):
		status_label.text = "关卡不存在：" + scene_path
		return

	get_tree().call_deferred("change_scene_to_file", scene_path)


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
