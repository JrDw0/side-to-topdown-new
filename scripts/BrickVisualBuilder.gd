extends RefCounted
class_name BrickVisualBuilder

const CONTAINER_NAME := "BrickTiles"
const DEFAULT_TILE_SIZE := 32.0


static func rebuild(
	visual_root: Node2D,
	collision_size: Vector2,
	brick_texture: Texture2D,
	tile_size: float = DEFAULT_TILE_SIZE
) -> Node2D:
	if visual_root == null or brick_texture == null:
		return null
	if collision_size.x <= 0.0 or collision_size.y <= 0.0:
		return null

	var old_container := visual_root.get_node_or_null(CONTAINER_NAME)
	if old_container != null:
		old_container.free()

	var container := Node2D.new()
	container.name = CONTAINER_NAME
	container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual_root.add_child(container)

	var safe_tile_size: float = maxf(tile_size, 1.0)
	var columns: int = maxi(1, ceili(collision_size.x / safe_tile_size))
	var rows: int = maxi(1, ceili(collision_size.y / safe_tile_size))
	var origin := Vector2(-collision_size.x * 0.5, -collision_size.y * 0.5)
	var texture_size := brick_texture.get_size()

	for row in range(rows):
		for column in range(columns):
			var cell_origin := Vector2(column * safe_tile_size, row * safe_tile_size)
			var cell_size := Vector2(
				minf(safe_tile_size, collision_size.x - cell_origin.x),
				minf(safe_tile_size, collision_size.y - cell_origin.y)
			)
			if cell_size.x <= 0.0 or cell_size.y <= 0.0:
				continue

			var tile := Sprite2D.new()
			tile.name = "Brick"
			tile.texture = brick_texture
			tile.centered = true
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			tile.position = origin + cell_origin + cell_size * 0.5
			tile.scale = Vector2(cell_size.x / texture_size.x, cell_size.y / texture_size.y)
			container.add_child(tile)

	return container


static func make_polygon_invisible(visual_root: Node2D) -> void:
	var polygon := visual_root as Polygon2D
	if polygon == null:
		return

	var transparent_color := polygon.color
	transparent_color.a = 0.0
	polygon.color = transparent_color
