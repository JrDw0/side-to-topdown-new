@tool
extends StaticBody2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")
const BrickBlock := preload("res://scripts/BrickBlock.gd")

@export_enum("SIDE", "TOPDOWN") var active_mode := 1
@export var active_alpha := 0.88
@export var inactive_alpha := 0.14
## 模式墙尺寸，同时驱动碰撞和砖块视觉范围。
@export var wall_size := Vector2(36.0, 220.0):
	set(value):
		wall_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_sync_brick_visual()
## 模式墙的砖块视觉素材。实际碰撞仍由 CollisionShape2D 决定。
@export var brick_texture: Texture2D = BrickBlock.DEFAULT_BRICK_TEXTURE:
	set(value):
		brick_texture = value
		_sync_brick_visual()
## 砖块视觉在场景中的目标尺寸。高精度原图会缩小到这个尺寸重复铺设。
@export_range(8.0, 128.0, 1.0) var brick_tile_size := 32.0:
	set(value):
		brick_tile_size = maxf(value, 1.0)
		_sync_brick_visual()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var brick_tile: Sprite2D = $Visual/BrickTile
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")

var _mode: int = PerspectiveModes.Mode.TOPDOWN


func _ready() -> void:
	add_to_group("perspective_objects")
	_sync_brick_visual()
	if Engine.is_editor_hint():
		return
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	if Engine.is_editor_hint():
		return
	_mode = mode
	_apply_state()


func get_perspective_mode() -> int:
	return _mode


func get_mode_sample_position() -> Vector2:
	return global_position


func _sync_with_controller() -> void:
	if Engine.is_editor_hint():
		return
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_state() -> void:
	if collision_shape == null or visual == null:
		return

	var active: bool = _mode == active_mode
	collision_shape.disabled = not active
	visual.modulate.a = active_alpha if active else inactive_alpha
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(active_alpha if active else inactive_alpha)


func _sync_brick_visual() -> void:
	if not is_inside_tree():
		return

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	visual = get_node_or_null("Visual") as Node2D
	brick_tile = get_node_or_null("Visual/BrickTile") as Sprite2D

	var target_alpha := active_alpha
	if not Engine.is_editor_hint():
		target_alpha = active_alpha if _mode == active_mode else inactive_alpha

	BrickBlock.apply_brick_visual(
		collision_shape,
		visual,
		brick_tile,
		wall_size,
		brick_texture,
		brick_tile_size,
		Color(1.0, 1.0, 1.0, target_alpha),
		0
	)
