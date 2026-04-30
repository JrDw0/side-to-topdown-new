extends Camera2D
class_name PerspectiveCamera

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var controller_path: NodePath
@export var transition_duration := 0.18
@export var side_zoom := Vector2(1.16, 1.16)
@export var topdown_zoom := Vector2(0.92, 0.92)
@export var side_offset := Vector2(0.0, 42.0)
@export var topdown_offset := Vector2.ZERO

var _controller: Node
var _mode: int = PerspectiveModes.Mode.SIDE
var _tween: Tween
var _flash_rect: ColorRect


func _ready() -> void:
	add_to_group("perspective_objects")
	enabled = true
	_make_flash_overlay()
	_bind_controller()
	call_deferred("_bind_controller")
	_apply_mode(false)


func set_perspective_mode(mode: int) -> void:
	if _mode == mode:
		_apply_mode(false)
		return

	_mode = mode
	_apply_mode(true)


func _bind_controller() -> void:
	var controller := _get_controller()
	if controller != null and not controller.is_connected("mode_changed", Callable(self, "set_perspective_mode")):
		controller.connect("mode_changed", Callable(self, "set_perspective_mode"))
		if controller.has_method("get_mode"):
			set_perspective_mode(controller.get_mode())


func _get_controller() -> Node:
	if _controller != null and is_instance_valid(_controller):
		return _controller

	if String(controller_path) != "":
		_controller = get_node_or_null(controller_path)
	if _controller == null:
		_controller = get_tree().get_first_node_in_group("perspective_controller")
	return _controller


func _apply_mode(animated: bool) -> void:
	var target_zoom := side_zoom if _mode == PerspectiveModes.Mode.SIDE else topdown_zoom
	var target_offset := side_offset if _mode == PerspectiveModes.Mode.SIDE else topdown_offset

	if _tween != null:
		_tween.kill()

	if not animated:
		zoom = target_zoom
		offset = target_offset
		if _flash_rect != null:
			var clear_color := _flash_rect.color
			clear_color.a = 0.0
			_flash_rect.color = clear_color
		return

	var flash_color := Color(0.72, 0.86, 1.0, 0.42)
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		flash_color = Color(0.45, 1.0, 0.78, 0.42)
	if _flash_rect != null:
		_flash_rect.color = flash_color

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "zoom", target_zoom, transition_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "offset", target_offset, transition_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	if _flash_rect != null:
		var clear_color := flash_color
		clear_color.a = 0.0
		_tween.tween_property(_flash_rect, "color", clear_color, transition_duration * 1.35)


func _make_flash_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)

	_flash_rect = ColorRect.new()
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	layer.add_child(_flash_rect)
