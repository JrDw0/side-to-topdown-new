extends Node2D
class_name ModeIceArea

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@onready var visual: Polygon2D = $Visual
@onready var ice_area: Area2D = $IceArea
@onready var ice_shape: CollisionShape2D = $IceArea/CollisionShape2D
@onready var solid_shape: CollisionShape2D = $SolidBody/CollisionShape2D

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _ice_bodies: Array[Node2D] = []


func _ready() -> void:
	add_to_group("perspective_objects")
	ice_area.body_entered.connect(_on_ice_body_entered)
	ice_area.body_exited.connect(_on_ice_body_exited)
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	if _mode == mode:
		return

	_clear_ice_bodies()
	_mode = mode
	_apply_state()
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		call_deferred("_sync_overlapping_bodies")


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_state() -> void:
	var topdown := _mode == PerspectiveModes.Mode.TOPDOWN
	ice_area.monitoring = topdown
	ice_area.monitorable = topdown
	ice_shape.disabled = not topdown
	solid_shape.disabled = topdown

	if topdown:
		visual.color = Color(0.42, 0.95, 1.0, 0.42)
	else:
		visual.color = Color(0.68, 0.92, 1.0, 0.92)


func _sync_overlapping_bodies() -> void:
	if _mode != PerspectiveModes.Mode.TOPDOWN:
		return

	for body in ice_area.get_overlapping_bodies():
		_on_ice_body_entered(body)


func _on_ice_body_entered(body: Node2D) -> void:
	if not body.has_method("set_on_ice_surface"):
		return

	if not _ice_bodies.has(body):
		_ice_bodies.append(body)
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		body.set_on_ice_surface(true)


func _on_ice_body_exited(body: Node2D) -> void:
	var had_body := _ice_bodies.has(body)
	_ice_bodies.erase(body)
	if had_body and body.has_method("set_on_ice_surface"):
		body.set_on_ice_surface(false)


func _clear_ice_bodies() -> void:
	for body in _ice_bodies:
		if is_instance_valid(body) and body.has_method("set_on_ice_surface"):
			body.set_on_ice_surface(false)
	_ice_bodies.clear()
