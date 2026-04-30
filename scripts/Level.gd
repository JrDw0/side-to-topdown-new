extends Node2D

## 是否在本关启用开发用调试面板。
@export var enable_debug_panel := true
## 调试面板场景。默认使用项目内置的可收起展开关卡调试面板。
@export var debug_panel_scene: PackedScene = preload("res://scenes/DebugPanel.tscn")

@onready var win_label: Label = get_node_or_null("CanvasLayer/WinLabel") as Label


func _ready() -> void:
	_ensure_input_actions()
	_ensure_debug_panel()
	if win_label != null:
		win_label.visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()


func complete_level() -> void:
	if win_label != null:
		win_label.visible = true


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("interact", [KEY_E])
	_add_key_action("reset", [KEY_R])
	_add_key_action("debug_panel", [KEY_F1])


func _ensure_debug_panel() -> void:
	if not enable_debug_panel or debug_panel_scene == null:
		return

	var canvas_layer := get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas_layer == null:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)

	if canvas_layer.get_node_or_null("DebugPanel") != null:
		return

	var debug_panel := debug_panel_scene.instantiate() as Control
	if debug_panel == null:
		return

	debug_panel.name = "DebugPanel"
	canvas_layer.add_child(debug_panel)


func _add_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	for keycode in keycodes:
		var already_registered := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.keycode == keycode:
				already_registered = true
				break
		if already_registered:
			continue

		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)
