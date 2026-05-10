extends Node

var _remaining := 0


func _ready() -> void:
	await get_tree().process_frame
	var stars := get_tree().get_nodes_in_group("star_items")
	_remaining = stars.size()
	for star in stars:
		star.star_collected.connect(_on_star_collected)


func _on_star_collected() -> void:
	_remaining -= 1
	if _remaining <= 0:
		var goal := get_tree().get_first_node_in_group("level_goal")
		if goal != null and goal.has_method("unlock"):
			goal.unlock()
