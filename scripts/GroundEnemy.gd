extends StaticBody2D
class_name GroundEnemy

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")

var _mode: int = PerspectiveModes.Mode.SIDE
var _alive := true


func _ready() -> void:
	add_to_group("perspective_objects")
	damage_area.body_entered.connect(_on_damage_body_entered)
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_state()


func crush() -> bool:
	if not _alive:
		return false

	_alive = false
	_apply_state()
	visual.color = Color(0.26, 0.28, 0.32, 0.65)
	if perspective_visual != null and perspective_visual.has_method("set_visual_scale_multiplier"):
		perspective_visual.set_visual_scale_multiplier(Vector2(1.0, 0.32))
	else:
		visual.scale.y = 0.32
	return true


func is_alive() -> bool:
	return _alive


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_state() -> void:
	var active := _alive and _mode == PerspectiveModes.Mode.SIDE
	collision_shape.disabled = not active
	damage_area.monitoring = active
	damage_area.monitorable = active
	damage_shape.disabled = not active

	if not _alive:
		_set_shadow_alpha_multiplier(0.18)
		return

	if active:
		visual.color = Color(1.0, 0.24, 0.14, 1.0)
		_set_shadow_alpha_multiplier(1.0)
	else:
		visual.color = Color(1.0, 0.24, 0.14, 0.28)
		_set_shadow_alpha_multiplier(0.28)


func _on_damage_body_entered(body: Node2D) -> void:
	if _alive and _mode == PerspectiveModes.Mode.SIDE and body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()


func _set_shadow_alpha_multiplier(multiplier: float) -> void:
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(multiplier)
