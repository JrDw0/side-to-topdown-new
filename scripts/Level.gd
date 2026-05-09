extends Node2D

const BrickVisualBuilder := preload("res://scripts/BrickVisualBuilder.gd")

## 是否在本关启用开发用调试面板。
@export var enable_debug_panel := true
## 调试面板场景。默认使用项目内置的可收起展开关卡调试面板。
@export var debug_panel_scene: PackedScene = preload("res://scenes/DebugPanel.tscn")
## 白盒平台碰撞的砖块视觉素材。只负责显示，实际碰撞仍由原 CollisionShape2D 决定。
@export var collision_brick_texture: Texture2D = preload("res://assets/地面 墙纸tiles/下水道砖块.png")
## 砖块视觉在场景中的目标尺寸。高精度原图会缩小到这个尺寸重复铺设。
@export_range(8.0, 128.0, 1.0) var collision_brick_tile_size := 32.0

@onready var win_label: Label = get_node_or_null("CanvasLayer/WinLabel") as Label


func _ready() -> void:
	_apply_collision_brick_visuals()
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


func _apply_collision_brick_visuals() -> void:
	for child in get_children():
		_apply_collision_brick_visual_to_branch(child)


func _apply_collision_brick_visual_to_branch(node: Node) -> void:
	var body := node as StaticBody2D
	if body != null:
		_apply_collision_brick_visual_to_body(body)

	for child in node.get_children():
		_apply_collision_brick_visual_to_branch(child)


func _apply_collision_brick_visual_to_body(body: StaticBody2D) -> void:
	if body.has_method("get_perspective_mode"):
		return

	var visual := body.get_node_or_null("Visual") as Node2D
	var collision_shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual == null or collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return

	BrickVisualBuilder.rebuild(visual, rectangle_shape.size, collision_brick_texture, collision_brick_tile_size)
	BrickVisualBuilder.make_polygon_invisible(visual)


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
