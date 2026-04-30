extends Node2D

@onready var win_label: Label = get_node_or_null("CanvasLayer/WinLabel") as Label


func _ready() -> void:
	_ensure_input_actions()
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
