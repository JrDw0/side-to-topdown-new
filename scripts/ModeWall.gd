extends StaticBody2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_enum("SIDE", "TOPDOWN") var active_mode := 1
@export var active_alpha := 0.88
@export var inactive_alpha := 0.14

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var _mode: int = PerspectiveModes.Mode.TOPDOWN


func _ready() -> void:
	add_to_group("perspective_objects")
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_state()


func get_perspective_mode() -> int:
	return _mode


func get_mode_sample_position() -> Vector2:
	return global_position


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_state() -> void:
	var active: bool = _mode == active_mode
	collision_shape.disabled = not active
	visual.modulate.a = active_alpha if active else inactive_alpha
