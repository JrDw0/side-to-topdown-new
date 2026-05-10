extends CharacterBody2D
class_name GapEnemy

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var patrol_speed := 100.0
@export var topdown_chase_speed := 80.0

@onready var visual: Polygon2D = $Visual
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $BodyShape

var _mode: int = PerspectiveModes.Mode.SIDE
var _player: Node2D
var _patrol_dir: float = 1.0  # 1 = 向右，-1 = 向左


func _ready() -> void:
	add_to_group("perspective_objects")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	damage_area.body_entered.connect(_on_damage_body_entered)
	_sync_with_controller()
	call_deferred("_find_player")
	_apply_state()


func _physics_process(delta: float) -> void:
	match _mode:
		PerspectiveModes.Mode.SIDE:
			# 纯水平移动；move_and_collide 不传 y 分量，不会产生纵向位移
			var col := move_and_collide(Vector2(patrol_speed * _patrol_dir * delta, 0.0))
			if col != null and absf(col.get_normal().x) > 0.1:
				# 碰到有水平法线的物体（platform 侧面 / wall）→ 反向
				_patrol_dir *= -1.0
		PerspectiveModes.Mode.TOPDOWN:
			_find_player()
			if _player == null:
				return
			velocity = (_player.global_position - global_position).normalized() * topdown_chase_speed
			move_and_slide()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	if _mode == PerspectiveModes.Mode.SIDE:
		velocity = Vector2.ZERO
	_apply_state()


func _apply_state() -> void:
	body_shape.disabled = false
	damage_area.monitoring = true
	damage_area.monitorable = true
	damage_shape.disabled = false
	visual.modulate.a = 1.0


func _find_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _on_damage_body_entered(body: Node2D) -> void:
	if body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()
