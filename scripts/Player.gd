extends CharacterBody2D
class_name Player

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var side_speed := 240.0
@export var topdown_speed := 245.0
@export var jump_velocity := -455.0
@export var max_fall_speed := 950.0
@export var ice_acceleration := 620.0
@export var ice_friction := 150.0

@onready var visual: Polygon2D = $Visual
@onready var mode_label: Label = $ModeLabel

var _mode: int = PerspectiveModes.Mode.SIDE
var _last_safe_position := Vector2.ZERO
var _gravity := 980.0
var _movement_locked := false
var _on_ice_surface := false


func _ready() -> void:
	add_to_group("player")
	add_to_group("perspective_objects")
	_last_safe_position = global_position
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	_sync_with_controller()
	call_deferred("_sync_with_controller")
	_apply_mode_visuals()


func _physics_process(delta: float) -> void:
	if _movement_locked:
		return

	if _mode == PerspectiveModes.Mode.SIDE:
		_side_physics(delta)
	else:
		_topdown_physics(delta)

	if global_position.y > 940.0:
		reset_to_safe_point()


func set_perspective_mode(mode: int) -> void:
	if _mode == mode:
		return

	_mode = mode
	velocity = Vector2.ZERO
	_on_ice_surface = false
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	_apply_mode_visuals()


func get_perspective_mode() -> int:
	return _mode


func get_mode_sample_position() -> Vector2:
	return global_position


func set_on_ice_surface(active: bool) -> void:
	_on_ice_surface = active and _mode == PerspectiveModes.Mode.TOPDOWN


func reset_to_safe_point() -> void:
	global_position = _last_safe_position
	velocity = Vector2.ZERO
	_movement_locked = false
	_on_ice_surface = false
	_sync_with_controller()


func reach_goal() -> void:
	_movement_locked = true
	velocity = Vector2.ZERO


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _side_physics(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * side_speed

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			_last_safe_position = global_position
	else:
		velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)

	move_and_slide()


func _topdown_physics(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _on_ice_surface:
		var target_velocity := input_vector * topdown_speed
		if input_vector == Vector2.ZERO:
			velocity = velocity.move_toward(Vector2.ZERO, ice_friction * delta)
		else:
			velocity = velocity.move_toward(target_velocity, ice_acceleration * delta)
	else:
		velocity = input_vector * topdown_speed

	if velocity == Vector2.ZERO:
		return

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision == null:
		return

	var collider: Object = collision.get_collider()
	if collider != null and collider.has_method("push_from_player"):
		collider.push_from_player(velocity.normalized(), delta)
		move_and_collide(collision.get_remainder())
	else:
		velocity = velocity.slide(collision.get_normal())
		move_and_collide(collision.get_remainder().slide(collision.get_normal()))


func _apply_mode_visuals() -> void:
	if _mode == PerspectiveModes.Mode.SIDE:
		visual.color = Color(0.2, 0.55, 1.0, 1.0)
		mode_label.text = "SIDE"
	else:
		visual.color = Color(0.15, 0.95, 0.75, 1.0)
		mode_label.text = "TOP"
