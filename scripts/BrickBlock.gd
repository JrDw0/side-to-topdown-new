@tool
extends StaticBody2D
class_name BrickBlock

const DEFAULT_BRICK_TEXTURE := preload("res://assets/地面 墙纸tiles/下水道砖块.png")
const DEFAULT_EDGE_TEXTURE_1 := preload("res://assets/地面 墙纸tiles/下水道包框1.png")
const DEFAULT_EDGE_TEXTURE_2 := preload("res://assets/地面 墙纸tiles/下水道包框2.png")
const DEFAULT_CORNER_TEXTURE_1 := preload("res://assets/地面 墙纸tiles/下水道转角1.png")
const DEFAULT_CORNER_TEXTURE_2 := preload("res://assets/地面 墙纸tiles/下水道转角2.png")

const EDGE_TOP := 1
const EDGE_BOTTOM := 2
const EDGE_LEFT := 4
const EDGE_RIGHT := 8
const DEFAULT_DECORATION_EDGES := EDGE_TOP

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

## 是否显示沿碰撞矩形边缘摆放的下水道包框装饰。只影响视觉，不改变碰撞。
@export var edge_decoration_enabled := true:
	set(value):
		edge_decoration_enabled = value
		_sync_block()

## 需要显示包框装饰的边。默认适合横版平台：上边和两端转角。
@export_flags("上", "下", "左", "右") var edge_decoration_sides := DEFAULT_DECORATION_EDGES:
	set(value):
		edge_decoration_sides = value
		_sync_block()

## 包框分段素材 A。会与素材 B 交替使用，减少长边重复感。
@export var edge_texture_1: Texture2D = DEFAULT_EDGE_TEXTURE_1:
	set(value):
		edge_texture_1 = value
		_sync_block()

## 包框分段素材 B。会与素材 A 交替使用，减少长边重复感。
@export var edge_texture_2: Texture2D = DEFAULT_EDGE_TEXTURE_2:
	set(value):
		edge_texture_2 = value
		_sync_block()

## 兼容旧配置的转角素材 A。新关卡建议优先调下面四个逐角转角素材。
@export var corner_texture_1: Texture2D = DEFAULT_CORNER_TEXTURE_1:
	set(value):
		corner_texture_1 = value
		_sync_block()

## 兼容旧配置的转角素材 B。新关卡建议优先调下面四个逐角转角素材。
@export var corner_texture_2: Texture2D = DEFAULT_CORNER_TEXTURE_2:
	set(value):
		corner_texture_2 = value
		_sync_block()

## 包框在场景中的显示厚度，单位为像素。用于缩放高精度包框素材。
@export_range(2.0, 96.0, 1.0) var edge_display_thickness := 18.0:
	set(value):
		edge_display_thickness = maxf(value, 1.0)
		_sync_block()

## 包框沿碰撞边长度的显示比例。1 为贴合碰撞边，略大于 1 可盖住端部缝隙。
@export_range(0.5, 1.5, 0.01) var edge_display_length_scale := 1.0:
	set(value):
		edge_display_length_scale = maxf(value, 0.01)
		_sync_block()

## 单个包框分段的目标显示尺寸。X 控制段宽，Y 控制段高；Y 小于等于 0 时使用包框显示厚度。
@export var edge_segment_display_size := Vector2(62.0, 0.0):
	set(value):
		edge_segment_display_size = Vector2(maxf(value.x, 4.0), value.y)
		_sync_block()

## 包框分段之间的间隔，单位为像素。负数可让分段互相压住一点。
@export_range(-24.0, 24.0, 1.0) var edge_segment_gap := -2.0:
	set(value):
		edge_segment_gap = value
		_sync_block()

## 包框分段的确定性位置抖动，单位为像素。用于打散过于整齐的边缘。
@export_range(0.0, 24.0, 1.0) var edge_segment_jitter := 3.0:
	set(value):
		edge_segment_jitter = maxf(value, 0.0)
		_sync_block()

## 包框分段变化种子。相同配置会生成稳定一致的分段变化。
@export var edge_variant_seed := 11:
	set(value):
		edge_variant_seed = value
		_sync_block()

## 转角装饰在场景中的最长边尺寸，单位为像素。用于等比缩放高精度转角素材。
@export_range(4.0, 160.0, 1.0) var corner_display_size := 34.0:
	set(value):
		corner_display_size = maxf(value, 1.0)
		_sync_block()

## 装饰相对碰撞边缘向外偏移的距离。正数会让包框稍微包在碰撞体外侧。
@export_range(-64.0, 64.0, 1.0) var edge_decoration_outset := 3.0:
	set(value):
		edge_decoration_outset = value
		_sync_block()

## 下水道包框装饰的视觉层级微调。
@export var edge_decoration_z_index := 1:
	set(value):
		edge_decoration_z_index = value
		_sync_block()

## 下水道包框装饰整体颜色和透明度微调。
@export var edge_decoration_modulate := Color.WHITE:
	set(value):
		edge_decoration_modulate = value
		_sync_block()

## 左上角转角素材。
@export var top_left_corner_texture: Texture2D = DEFAULT_CORNER_TEXTURE_1:
	set(value):
		top_left_corner_texture = value
		_sync_block()

## 右上角转角素材。默认使用左上角素材镜像，避免右侧转角变成竖直插块。
@export var top_right_corner_texture: Texture2D = DEFAULT_CORNER_TEXTURE_1:
	set(value):
		top_right_corner_texture = value
		_sync_block()

## 左下角转角素材。
@export var bottom_left_corner_texture: Texture2D = DEFAULT_CORNER_TEXTURE_1:
	set(value):
		bottom_left_corner_texture = value
		_sync_block()

## 右下角转角素材。
@export var bottom_right_corner_texture: Texture2D = DEFAULT_CORNER_TEXTURE_1:
	set(value):
		bottom_right_corner_texture = value
		_sync_block()

## 左上角旋转角度，单位为度。
@export_range(-360.0, 360.0, 1.0) var top_left_corner_rotation_degrees := 0.0:
	set(value):
		top_left_corner_rotation_degrees = value
		_sync_block()

## 右上角旋转角度，单位为度。
@export_range(-360.0, 360.0, 1.0) var top_right_corner_rotation_degrees := 0.0:
	set(value):
		top_right_corner_rotation_degrees = value
		_sync_block()

## 左下角旋转角度，单位为度。
@export_range(-360.0, 360.0, 1.0) var bottom_left_corner_rotation_degrees := 180.0:
	set(value):
		bottom_left_corner_rotation_degrees = value
		_sync_block()

## 右下角旋转角度，单位为度。
@export_range(-360.0, 360.0, 1.0) var bottom_right_corner_rotation_degrees := 180.0:
	set(value):
		bottom_right_corner_rotation_degrees = value
		_sync_block()

## 左上角是否水平翻转。
@export var top_left_corner_flip_h := false:
	set(value):
		top_left_corner_flip_h = value
		_sync_block()

## 右上角是否水平翻转。
@export var top_right_corner_flip_h := true:
	set(value):
		top_right_corner_flip_h = value
		_sync_block()

## 左下角是否水平翻转。
@export var bottom_left_corner_flip_h := true:
	set(value):
		bottom_left_corner_flip_h = value
		_sync_block()

## 右下角是否水平翻转。
@export var bottom_right_corner_flip_h := false:
	set(value):
		bottom_right_corner_flip_h = value
		_sync_block()

## 左上角是否垂直翻转。
@export var top_left_corner_flip_v := false:
	set(value):
		top_left_corner_flip_v = value
		_sync_block()

## 右上角是否垂直翻转。
@export var top_right_corner_flip_v := false:
	set(value):
		top_right_corner_flip_v = value
		_sync_block()

## 左下角是否垂直翻转。
@export var bottom_left_corner_flip_v := false:
	set(value):
		bottom_left_corner_flip_v = value
		_sync_block()

## 右下角是否垂直翻转。
@export var bottom_right_corner_flip_v := false:
	set(value):
		bottom_right_corner_flip_v = value
		_sync_block()

## 左上角局部偏移，单位为像素。
@export var top_left_corner_offset := Vector2.ZERO:
	set(value):
		top_left_corner_offset = value
		_sync_block()

## 右上角局部偏移，单位为像素。
@export var top_right_corner_offset := Vector2.ZERO:
	set(value):
		top_right_corner_offset = value
		_sync_block()

## 左下角局部偏移，单位为像素。
@export var bottom_left_corner_offset := Vector2.ZERO:
	set(value):
		bottom_left_corner_offset = value
		_sync_block()

## 右下角局部偏移，单位为像素。
@export var bottom_right_corner_offset := Vector2.ZERO:
	set(value):
		bottom_right_corner_offset = value
		_sync_block()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var brick_tile: Sprite2D = get_node_or_null("Visual/BrickTile") as Sprite2D
@onready var edge_decoration: Node2D = get_node_or_null("Visual/EdgeDecoration") as Node2D
@onready var top_edge_segments: Node2D = get_node_or_null("Visual/EdgeDecoration/TopEdgeSegments") as Node2D
@onready var bottom_edge_segments: Node2D = get_node_or_null("Visual/EdgeDecoration/BottomEdgeSegments") as Node2D
@onready var left_edge_segments: Node2D = get_node_or_null("Visual/EdgeDecoration/LeftEdgeSegments") as Node2D
@onready var right_edge_segments: Node2D = get_node_or_null("Visual/EdgeDecoration/RightEdgeSegments") as Node2D
@onready var corner_top_left: Sprite2D = get_node_or_null("Visual/EdgeDecoration/TopLeftCorner") as Sprite2D
@onready var corner_top_right: Sprite2D = get_node_or_null("Visual/EdgeDecoration/TopRightCorner") as Sprite2D
@onready var corner_bottom_left: Sprite2D = get_node_or_null("Visual/EdgeDecoration/BottomLeftCorner") as Sprite2D
@onready var corner_bottom_right: Sprite2D = get_node_or_null("Visual/EdgeDecoration/BottomRightCorner") as Sprite2D


func _ready() -> void:
	_sync_block()


func _validate_property(property: Dictionary) -> void:
	if property.name == "block_size":
		property.hint_string = "suffix:px"
	elif property.name == "edge_display_thickness":
		property.hint_string = "2,96,1,suffix:px"
	elif property.name == "edge_segment_display_size":
		property.hint_string = "suffix:px"
	elif property.name == "edge_segment_gap":
		property.hint_string = "-24,24,1,suffix:px"
	elif property.name == "edge_segment_jitter":
		property.hint_string = "0,24,1,suffix:px"
	elif property.name == "corner_display_size":
		property.hint_string = "4,160,1,suffix:px"
	elif property.name == "edge_decoration_outset":
		property.hint_string = "-64,64,1,suffix:px"
	elif property.name.ends_with("_corner_offset"):
		property.hint_string = "suffix:px"


func _sync_block() -> void:
	if not is_inside_tree():
		return

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	visual = get_node_or_null("Visual") as Node2D
	brick_tile = get_node_or_null("Visual/BrickTile") as Sprite2D
	edge_decoration = get_node_or_null("Visual/EdgeDecoration") as Node2D
	top_edge_segments = get_node_or_null("Visual/EdgeDecoration/TopEdgeSegments") as Node2D
	bottom_edge_segments = get_node_or_null("Visual/EdgeDecoration/BottomEdgeSegments") as Node2D
	left_edge_segments = get_node_or_null("Visual/EdgeDecoration/LeftEdgeSegments") as Node2D
	right_edge_segments = get_node_or_null("Visual/EdgeDecoration/RightEdgeSegments") as Node2D
	corner_top_left = get_node_or_null("Visual/EdgeDecoration/TopLeftCorner") as Sprite2D
	corner_top_right = get_node_or_null("Visual/EdgeDecoration/TopRightCorner") as Sprite2D
	corner_bottom_left = get_node_or_null("Visual/EdgeDecoration/BottomLeftCorner") as Sprite2D
	corner_bottom_right = get_node_or_null("Visual/EdgeDecoration/BottomRightCorner") as Sprite2D

	apply_brick_visual(collision_shape, visual, brick_tile, block_size, brick_texture, brick_tile_size, visual_modulate, visual_z_index)
	_sync_edge_decoration()


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


func _sync_edge_decoration() -> void:
	if edge_decoration == null:
		return

	var safe_size := _sanitize_size(block_size)
	edge_decoration.visible = edge_decoration_enabled
	edge_decoration.position = Vector2.ZERO
	edge_decoration.modulate = edge_decoration_modulate
	edge_decoration.z_index = edge_decoration_z_index

	var top_enabled := edge_decoration_enabled and _has_edge(EDGE_TOP)
	var bottom_enabled := edge_decoration_enabled and _has_edge(EDGE_BOTTOM)
	var left_enabled := edge_decoration_enabled and _has_edge(EDGE_LEFT)
	var right_enabled := edge_decoration_enabled and _has_edge(EDGE_RIGHT)

	if not edge_decoration_enabled:
		_clear_edge_segment_containers()
		_set_sprites_visible([
			corner_top_left,
			corner_top_right,
			corner_bottom_left,
			corner_bottom_right,
		], false)
		return

	var half_size := safe_size * 0.5
	var edge_length := Vector2(
		safe_size.x * edge_display_length_scale,
		safe_size.y * edge_display_length_scale
	)

	_build_edge_segments(
		top_edge_segments,
		top_enabled,
		EDGE_TOP,
		Vector2(0.0, -half_size.y - edge_decoration_outset),
		0.0,
		edge_length.x
	)
	_build_edge_segments(
		bottom_edge_segments,
		bottom_enabled,
		EDGE_BOTTOM,
		Vector2(0.0, half_size.y + edge_decoration_outset),
		PI,
		edge_length.x
	)
	_build_edge_segments(
		left_edge_segments,
		left_enabled,
		EDGE_LEFT,
		Vector2(-half_size.x - edge_decoration_outset, 0.0),
		-PI * 0.5,
		edge_length.y
	)
	_build_edge_segments(
		right_edge_segments,
		right_enabled,
		EDGE_RIGHT,
		Vector2(half_size.x + edge_decoration_outset, 0.0),
		PI * 0.5,
		edge_length.y
	)

	_configure_corner_sprite(
		corner_top_left,
		top_left_corner_texture,
		top_enabled or left_enabled,
		Vector2(-half_size.x - edge_decoration_outset, -half_size.y - edge_decoration_outset) + top_left_corner_offset,
		deg_to_rad(top_left_corner_rotation_degrees),
		top_left_corner_flip_h,
		top_left_corner_flip_v
	)
	_configure_corner_sprite(
		corner_top_right,
		top_right_corner_texture,
		top_enabled or right_enabled,
		Vector2(half_size.x + edge_decoration_outset, -half_size.y - edge_decoration_outset) + top_right_corner_offset,
		deg_to_rad(top_right_corner_rotation_degrees),
		top_right_corner_flip_h,
		top_right_corner_flip_v
	)
	_configure_corner_sprite(
		corner_bottom_left,
		bottom_left_corner_texture,
		bottom_enabled or left_enabled,
		Vector2(-half_size.x - edge_decoration_outset, half_size.y + edge_decoration_outset) + bottom_left_corner_offset,
		deg_to_rad(bottom_left_corner_rotation_degrees),
		bottom_left_corner_flip_h,
		bottom_left_corner_flip_v
	)
	_configure_corner_sprite(
		corner_bottom_right,
		bottom_right_corner_texture,
		bottom_enabled or right_enabled,
		Vector2(half_size.x + edge_decoration_outset, half_size.y + edge_decoration_outset) + bottom_right_corner_offset,
		deg_to_rad(bottom_right_corner_rotation_degrees),
		bottom_right_corner_flip_h,
		bottom_right_corner_flip_v
	)


func _has_edge(edge_flag: int) -> bool:
	return (edge_decoration_sides & edge_flag) != 0


func _build_edge_segments(
	container: Node2D,
	enabled: bool,
	edge_flag: int,
	target_position: Vector2,
	target_rotation: float,
	target_length: float
) -> void:
	if container == null:
		return

	_clear_children(container)
	container.visible = enabled
	container.position = target_position
	container.rotation = target_rotation

	if not enabled:
		return

	var safe_segment_length: float = maxf(edge_segment_display_size.x, 4.0)
	var safe_segment_height: float = edge_segment_display_size.y
	if safe_segment_height <= 0.0:
		safe_segment_height = maxf(edge_display_thickness, 1.0)

	var stride: float = maxf(safe_segment_length + edge_segment_gap, 4.0)
	var segment_count: int = maxi(1, ceili(maxf(target_length, 1.0) / stride))
	var used_length: float = float(segment_count - 1) * stride + safe_segment_length
	var start_x: float = used_length * -0.5 + safe_segment_length * 0.5

	for index in range(segment_count):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Segment%02d" % index
		sprite.texture = _pick_edge_texture(edge_flag, index)
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		sprite.region_enabled = false
		sprite.flip_h = _pick_bool(edge_flag, index, 17)
		sprite.flip_v = _pick_bool(edge_flag, index, 31)
		sprite.rotation = deg_to_rad(_pick_signed_value(edge_flag, index, 43, 4.0))
		sprite.position = Vector2(
			start_x + float(index) * stride + _pick_signed_value(edge_flag, index, 59, edge_segment_jitter),
			_pick_signed_value(edge_flag, index, 73, edge_segment_jitter * 0.45)
		)
		sprite.scale = _get_segment_scale(sprite.texture, Vector2(safe_segment_length, safe_segment_height), index)
		container.add_child(sprite)


func _pick_edge_texture(edge_flag: int, index: int) -> Texture2D:
	var texture_index: int = absi(edge_variant_seed + edge_flag * 13 + index * 7) % 4
	if texture_index == 0 or texture_index == 3:
		return edge_texture_2 if edge_texture_2 != null else edge_texture_1
	return edge_texture_1 if edge_texture_1 != null else edge_texture_2


func _get_segment_scale(texture: Texture2D, target_size: Vector2, index: int) -> Vector2:
	var texture_size: Vector2 = _get_safe_texture_size(texture)
	var width_scale: float = target_size.x / texture_size.x
	var height_scale: float = target_size.y / texture_size.y
	var size_variation: float = 1.0 + _pick_signed_value(EDGE_TOP, index, 89, 0.08)
	return Vector2(width_scale * size_variation, height_scale * size_variation)


func _configure_corner_sprite(
	sprite: Sprite2D,
	texture: Texture2D,
	enabled: bool,
	target_position: Vector2,
	target_rotation: float,
	flip_horizontal: bool,
	flip_vertical: bool
) -> void:
	if sprite == null:
		return

	sprite.visible = enabled
	sprite.texture = texture
	sprite.centered = true
	sprite.position = target_position
	sprite.rotation = target_rotation
	sprite.flip_h = flip_horizontal
	sprite.flip_v = flip_vertical
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.region_enabled = false

	if not enabled:
		return

	var texture_size: Vector2 = _get_safe_texture_size(texture)
	var longest_side: float = maxf(texture_size.x, texture_size.y)
	var scale_factor: float = maxf(corner_display_size, 1.0) / longest_side
	sprite.scale = Vector2(scale_factor, scale_factor)


func _get_safe_texture_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ONE
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE
	return texture_size


func _pick_bool(edge_flag: int, index: int, salt: int) -> bool:
	return (_hash_to_int(edge_flag, index, salt) % 2) == 0


func _pick_signed_value(edge_flag: int, index: int, salt: int, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var normalized: float = float(_hash_to_int(edge_flag, index, salt) % 1000) / 999.0
	return lerpf(-amount, amount, normalized)


func _hash_to_int(edge_flag: int, index: int, salt: int) -> int:
	var value: int = edge_variant_seed * 73856093
	value += edge_flag * 19349663
	value += index * 83492791
	value += salt * 265443576
	return absi(value)


func _clear_edge_segment_containers() -> void:
	for container in [top_edge_segments, bottom_edge_segments, left_edge_segments, right_edge_segments]:
		if container is Node2D:
			_clear_children(container)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.free()


func _set_sprites_visible(sprites: Array, target_visible: bool) -> void:
	for sprite in sprites:
		if sprite is Sprite2D:
			sprite.visible = target_visible
