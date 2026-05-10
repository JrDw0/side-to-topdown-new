extends CharacterBody2D
class_name BoxEnemy

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var chase_speed := 90.0
@export var push_speed := 210.0
@export var chase_limit_x := 420.0

@onready var visual: Polygon2D = $Visual
@onready var track_label: Label = $TrackLabel
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var _mode: int = PerspectiveModes.Mode.SIDE
var _player: Node2D
var _gravity: float


func _ready() -> void:
	add_to_group("perspective_objects")
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	damage_area.body_entered.connect(_on_damage_body_entered)
	_sync_with_controller()
	call_deferred("_find_player")
	_apply_state()


func _physics_process(delta: float) -> void:
	match _mode:
		PerspectiveModes.Mode.SIDE:
			_side_physics(delta)
		PerspectiveModes.Mode.TOPDOWN:
			velocity = Vector2.ZERO


func _side_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, 950.0)
		velocity.x = 0.0
	else:
		velocity.y = 0.0
		_find_player()
		if _player != null and global_position.x < chase_limit_x:
			velocity.x = signf(_player.global_position.x - global_position.x) * chase_speed
		else:
			velocity.x = 0.0
	move_and_slide()


func push_from_player(direction: Vector2, delta: float) -> bool:
	if _mode != PerspectiveModes.Mode.TOPDOWN or direction == Vector2.ZERO:
		return false
	var push_dir := Vector2.ZERO
	if absf(direction.x) >= absf(direction.y):
		push_dir.x = signf(direction.x)
	else:
		push_dir.y = signf(direction.y)
	move_and_collide(push_dir * push_speed * delta)
	return true


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	velocity = Vector2.ZERO
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	_apply_state()


func _apply_state() -> void:
	var in_side := _mode == PerspectiveModes.Mode.SIDE
	damage_area.monitoring = in_side
	damage_area.monitorable = in_side
	damage_shape.disabled = not in_side
	if in_side:
		visual.color = Color(0.98, 0.26, 0.12, 1.0)
		track_label.text = "CHASE"
	else:
		visual.color = Color(0.52, 0.58, 0.65, 1.0)
		track_label.text = "PUSH"


func _find_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _on_damage_body_entered(body: Node2D) -> void:
	if _mode == PerspectiveModes.Mode.SIDE and body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()
