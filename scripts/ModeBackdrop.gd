extends Node2D
class_name ModeBackdrop

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_category("模式背景")
## 背景绘制区域大小，通常与关卡视口范围一致。
@export var size := Vector2(1280.0, 720.0)
## 俯视网格的单元大小。
@export var grid_step := 64.0
## 横版地平线与俯视网格互相淡入淡出的时长。
@export_range(0.0, 1.0, 0.01) var transition_duration := 0.22

var _mode: int = PerspectiveModes.Mode.SIDE
var _transition_progress := 0.0
var _ready_done := false
var _tween: Tween


func _ready() -> void:
	add_to_group("perspective_objects")
	z_index = -100
	_sync_with_controller()
	_ready_done = true
	queue_redraw()


func set_perspective_mode(mode: int) -> void:
	if mode != PerspectiveModes.Mode.SIDE and mode != PerspectiveModes.Mode.TOPDOWN:
		return

	var changed := _mode != mode
	_mode = mode
	var target_progress := 0.0 if _mode == PerspectiveModes.Mode.SIDE else 1.0
	if not changed or not _ready_done or transition_duration <= 0.0:
		_set_transition_progress(target_progress)
		return

	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(
		Callable(self, "_set_transition_progress"),
		_transition_progress,
		target_progress,
		transition_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _draw() -> void:
	var side_color := Color(0.075, 0.085, 0.105, 1.0)
	var topdown_color := Color(0.055, 0.11, 0.095, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), side_color.lerp(topdown_color, _transition_progress))

	_draw_horizon(1.0 - _transition_progress)
	_draw_grid(_transition_progress)


func _set_transition_progress(value: float) -> void:
	_transition_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw_horizon(alpha: float) -> void:
	if alpha <= 0.0:
		return

	draw_rect(Rect2(Vector2(0.0, 640.0), Vector2(size.x, 80.0)), Color(0.045, 0.05, 0.06, 0.96 * alpha))
	draw_rect(Rect2(Vector2(0.0, 680.0), Vector2(size.x, 40.0)), Color(0.028, 0.032, 0.04, 0.85 * alpha))
	draw_line(Vector2(0.0, 640.0), Vector2(size.x, 640.0), Color(0.26, 0.48, 0.82, 0.62 * alpha), 3.0)

	var reference_color := Color(0.42, 0.58, 0.82, 0.13 * alpha)
	for line_y in [520.0, 570.0, 610.0]:
		draw_line(Vector2(0.0, line_y), Vector2(size.x, line_y), reference_color, 1.0)


func _draw_grid(alpha: float) -> void:
	if alpha <= 0.0:
		return

	var grid_color := Color(0.22, 0.95, 0.72, 0.2 * alpha)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_step

	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_step

	var center_color := Color(0.58, 1.0, 0.86, 0.3 * alpha)
	draw_line(Vector2(size.x * 0.5, 0.0), Vector2(size.x * 0.5, size.y), center_color, 2.0)
	draw_line(Vector2(0.0, size.y * 0.5), Vector2(size.x, size.y * 0.5), center_color, 2.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.26, 1.0, 0.78, 0.22 * alpha), false, 3.0)
