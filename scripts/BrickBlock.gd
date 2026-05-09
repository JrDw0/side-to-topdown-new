@tool
extends StaticBody2D
class_name BrickBlock

const DEFAULT_BRICK_TEXTURE := preload("res://assets/地面 墙纸tiles/下水道砖块.png")

## 砖块区域尺寸，同时驱动碰撞和视觉范围。
@export var block_size := Vector2(128.0, 32.0):
	set(value):
		block_size = _sanitize_size(value)
		_sync_block()

## 砖块视觉素材。建议使用可重复平铺的方形贴图。
@export var brick_texture: Texture2D = DEFAULT_BRICK_TEXTURE:
	set(value):
		brick_texture = value
		_sync_block()

## 单块砖在场景中的显示尺寸。
@export_range(8.0, 128.0, 1.0) var brick_tile_size := 32.0:
	set(value):
		brick_tile_size = maxf(value, 1.0)
		_sync_block()

## 砖块整体颜色和透明度微调。
@export var visual_modulate := Color.WHITE:
	set(value):
		visual_modulate = value
		_sync_block()

## 砖块视觉层级微调。
@export var visual_z_index := 0:
	set(value):
		visual_z_index = value
		_sync_block()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var brick_tile: Sprite2D = get_node_or_null("Visual/BrickTile") as Sprite2D


func _ready() -> void:
	_sync_block()


func _validate_property(property: Dictionary) -> void:
	if property.name == "block_size":
		property.hint_string = "suffix:px"


func _sync_block() -> void:
	if not is_inside_tree():
		return

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	visual = get_node_or_null("Visual") as Node2D
	brick_tile = get_node_or_null("Visual/BrickTile") as Sprite2D

	apply_brick_visual(collision_shape, visual, brick_tile, block_size, brick_texture, brick_tile_size, visual_modulate, visual_z_index)


static func apply_brick_visual(
	collision_shape: CollisionShape2D,
	visual_root: Node2D,
	tile: Sprite2D,
	target_size: Vector2,
	texture: Texture2D,
	tile_size: float,
	target_modulate: Color,
	target_z_index: int
) -> void:
	var safe_size := _sanitize_size(target_size)

	if collision_shape != null:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		if rectangle_shape == null:
			rectangle_shape = RectangleShape2D.new()
			collision_shape.shape = rectangle_shape
		elif not rectangle_shape.resource_local_to_scene:
			rectangle_shape = rectangle_shape.duplicate() as RectangleShape2D
			collision_shape.shape = rectangle_shape
		rectangle_shape.resource_local_to_scene = true
		rectangle_shape.size = safe_size

	if visual_root != null:
		visual_root.position = Vector2.ZERO
		visual_root.modulate = target_modulate
		visual_root.z_index = target_z_index

	if tile == null:
		return

	tile.texture = texture
	tile.centered = false
	tile.position = safe_size * -0.5
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tile.region_enabled = true

	if texture == null:
		tile.region_rect = Rect2(Vector2.ZERO, safe_size)
		tile.scale = Vector2.ONE
		return

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		tile.region_rect = Rect2(Vector2.ZERO, safe_size)
		tile.scale = Vector2.ONE
		return

	var safe_tile_size := maxf(tile_size, 1.0)
	tile.scale = Vector2(safe_tile_size / texture_size.x, safe_tile_size / texture_size.y)
	tile.region_rect = Rect2(
		Vector2.ZERO,
		Vector2(safe_size.x / tile.scale.x, safe_size.y / tile.scale.y)
	)


static func _sanitize_size(value: Vector2) -> Vector2:
	return Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
