extends Node2D
class_name ModeBackdrop

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var size := Vector2(1280.0, 720.0)
@export var grid_step := 64.0

var _mode: int = PerspectiveModes.Mode.SIDE


func _ready() -> void:
	add_to_group("perspective_objects")
	z_index = -100
	_sync_with_controller()
	queue_redraw()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	queue_redraw()


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _draw() -> void:
	if _mode == PerspectiveModes.Mode.SIDE:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.075, 0.085, 0.105, 1.0))
		_draw_horizon()
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.11, 0.095, 1.0))
		_draw_grid()


func _draw_horizon() -> void:
	draw_rect(Rect2(Vector2(0.0, 640.0), Vector2(size.x, 80.0)), Color(0.045, 0.05, 0.06, 1.0))
	draw_line(Vector2(0.0, 640.0), Vector2(size.x, 640.0), Color(0.26, 0.48, 0.82, 0.55), 3.0)


func _draw_grid() -> void:
	var grid_color := Color(0.22, 0.95, 0.72, 0.2)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_step

	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_step
