extends StaticBody2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")
const BrickVisualBuilder := preload("res://scripts/BrickVisualBuilder.gd")

@export_enum("SIDE", "TOPDOWN") var active_mode := 1
@export var active_alpha := 0.88
@export var inactive_alpha := 0.14
## 模式墙的砖块视觉素材。实际碰撞仍由 CollisionShape2D 决定。
@export var brick_texture: Texture2D = preload("res://assets/地面 墙纸tiles/下水道砖块.png")
## 砖块视觉在场景中的目标尺寸。高精度原图会缩小到这个尺寸重复铺设。
@export_range(8.0, 128.0, 1.0) var brick_tile_size := 32.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")

var _mode: int = PerspectiveModes.Mode.TOPDOWN


func _ready() -> void:
	add_to_group("perspective_objects")
	_rebuild_brick_visual()
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
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(active_alpha if active else inactive_alpha)


func _rebuild_brick_visual() -> void:
	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return

	BrickVisualBuilder.rebuild(visual, rectangle_shape.size, brick_texture, brick_tile_size)
	BrickVisualBuilder.make_polygon_invisible(visual)
