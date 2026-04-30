extends CharacterBody2D
class_name PushBox

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

enum BoxKind { STATIC_PLATFORM, FALLING_CRUSH }

@export var box_kind: BoxKind = BoxKind.STATIC_PLATFORM
@export var push_speed := 220.0
@export var min_position := Vector2(40.0, 80.0)
@export var max_position := Vector2(1240.0, 660.0)
@export var side_gravity := 980.0
@export var max_fall_speed := 920.0
@export var crush_speed := 160.0

@onready var visual: Polygon2D = $Visual
@onready var track_label: Label = $TrackLabel

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _grounded_after_fall := false


func _ready() -> void:
	add_to_group("perspective_objects")
	side_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", side_gravity))
	_sync_with_controller()
	call_deferred("_sync_with_controller")
	_apply_mode_visuals()


func _physics_process(delta: float) -> void:
	if _mode != PerspectiveModes.Mode.SIDE:
		velocity = Vector2.ZERO
		return

	if box_kind == BoxKind.FALLING_CRUSH and not _grounded_after_fall:
		_falling_physics(delta)
	else:
		velocity = Vector2.ZERO


func set_perspective_mode(mode: int) -> void:
	if _mode == mode:
		return

	_mode = mode
	velocity = Vector2.ZERO
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		_grounded_after_fall = false
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	_apply_mode_visuals()


func get_perspective_mode() -> int:
	return _mode


func get_mode_sample_position() -> Vector2:
	return global_position


func push_from_player(direction: Vector2, delta: float) -> bool:
	if _mode != PerspectiveModes.Mode.TOPDOWN or direction == Vector2.ZERO:
		return false

	var push_direction := Vector2.ZERO
	if absf(direction.x) >= absf(direction.y):
		push_direction.x = signf(direction.x)
	else:
		push_direction.y = signf(direction.y)

	if push_direction == Vector2.ZERO:
		return false

	move_and_collide(push_direction * push_speed * delta)
	global_position.x = clampf(global_position.x, min_position.x, max_position.x)
	global_position.y = clampf(global_position.y, min_position.y, max_position.y)
	return true


func _falling_physics(delta: float) -> void:
	velocity.y = minf(velocity.y + side_gravity * delta, max_fall_speed)
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision == null:
		return

	var collider := collision.get_collider()
	if velocity.y >= crush_speed and collider != null and collider.has_method("crush"):
		if collider.crush():
			move_and_collide(collision.get_remainder())
			return

	if collision.get_normal().y < -0.45:
		_grounded_after_fall = true
	velocity = Vector2.ZERO


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_mode_visuals() -> void:
	if box_kind == BoxKind.STATIC_PLATFORM:
		if _mode == PerspectiveModes.Mode.SIDE:
			visual.color = Color(0.96, 0.72, 0.22, 1.0)
			track_label.text = "STEP"
		else:
			visual.color = Color(1.0, 0.86, 0.3, 1.0)
			track_label.text = "PUSH"
	else:
		if _mode == PerspectiveModes.Mode.SIDE:
			visual.color = Color(0.98, 0.44, 0.18, 1.0)
			track_label.text = "DROP"
		else:
			visual.color = Color(0.94, 0.58, 0.24, 1.0)
			track_label.text = "CRUSH"
