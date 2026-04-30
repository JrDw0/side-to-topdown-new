extends Area2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var patrol_speed := 130.0
@export_enum("SIDE", "TOPDOWN") var active_mode := 0

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var left_marker: Marker2D = $PatrolLeft
@onready var right_marker: Marker2D = $PatrolRight

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _active := false
var _left_x := 0.0
var _right_x := 0.0
var _target_right := true


func _ready() -> void:
	add_to_group("perspective_objects")
	_left_x = global_position.x + left_marker.position.x
	_right_x = global_position.x + right_marker.position.x
	body_entered.connect(_on_body_entered)
	_apply_state()


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var target_x := _right_x if _target_right else _left_x
	global_position.x = move_toward(global_position.x, target_x, patrol_speed * delta)
	if is_equal_approx(global_position.x, target_x):
		_target_right = not _target_right


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_state()


func get_perspective_mode() -> int:
	return _mode


func get_mode_sample_position() -> Vector2:
	return global_position


func _apply_state() -> void:
	_active = _mode == active_mode
	monitoring = _active
	collision_shape.disabled = not _active
	visible = _active


func _on_body_entered(body: Node2D) -> void:
	if _active and body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()
