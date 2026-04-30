extends CharacterBody2D
class_name FlyingEnemy

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var topdown_speed := 118.0
@export var side_speed := 70.0
@export var aggro_distance := 620.0
@export var trap_min := Vector2(580.0, 300.0)
@export var trap_max := Vector2(780.0, 520.0)

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var side_left: Marker2D = $SideLeft
@onready var side_right: Marker2D = $SideRight

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _player: Node2D
var _trapped := false
var _side_target_right := true
var _side_left_x := 0.0
var _side_right_x := 0.0
var _locked_y := 0.0


func _ready() -> void:
	add_to_group("perspective_objects")
	damage_area.body_entered.connect(_on_damage_body_entered)
	_side_left_x = global_position.x + side_left.position.x
	_side_right_x = global_position.x + side_right.position.x
	_locked_y = global_position.y
	_sync_with_controller()
	call_deferred("_find_player")
	_apply_state()


func _physics_process(delta: float) -> void:
	if _trapped:
		velocity = Vector2.ZERO
		return

	if _mode == PerspectiveModes.Mode.TOPDOWN:
		_topdown_physics()
	else:
		_side_physics(delta)

	move_and_slide()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	if _mode == PerspectiveModes.Mode.TOPDOWN:
		_trapped = false
	else:
		_locked_y = global_position.y
		_trapped = _is_inside_trap()
	_apply_state()


func _topdown_physics() -> void:
	_find_player()
	if _player == null:
		velocity = Vector2.ZERO
		return

	var to_player := _player.global_position - global_position
	if to_player.length() > aggro_distance:
		velocity = Vector2.ZERO
		return

	velocity = to_player.normalized() * topdown_speed


func _side_physics(delta: float) -> void:
	global_position.y = move_toward(global_position.y, _locked_y, 420.0 * delta)
	var target_x := _side_right_x if _side_target_right else _side_left_x
	velocity = Vector2(signf(target_x - global_position.x) * side_speed, 0.0)
	if absf(global_position.x - target_x) < 4.0:
		_side_target_right = not _side_target_right


func _apply_state() -> void:
	collision_shape.disabled = _trapped
	damage_area.monitoring = not _trapped
	damage_area.monitorable = not _trapped
	damage_shape.disabled = _trapped

	if _trapped:
		visual.color = Color(0.42, 0.48, 0.58, 0.72)
	elif _mode == PerspectiveModes.Mode.TOPDOWN:
		visual.color = Color(0.95, 0.32, 1.0, 1.0)
	else:
		visual.color = Color(1.0, 0.34, 0.2, 1.0)


func _is_inside_trap() -> bool:
	return global_position.x >= trap_min.x \
		and global_position.x <= trap_max.x \
		and global_position.y >= trap_min.y \
		and global_position.y <= trap_max.y


func _find_player() -> void:
	if _player != null and is_instance_valid(_player):
		return

	_player = get_tree().get_first_node_in_group("player") as Node2D


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _on_damage_body_entered(body: Node2D) -> void:
	if not _trapped and body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()
