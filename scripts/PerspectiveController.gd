extends Node
class_name PerspectiveController

signal mode_changed(mode: int)

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_enum("SIDE", "TOPDOWN") var initial_mode: int = PerspectiveModes.Mode.SIDE

var _mode: int = PerspectiveModes.Mode.SIDE


func _enter_tree() -> void:
	add_to_group("perspective_controller")
	_mode = initial_mode


func _ready() -> void:
	_mode = initial_mode
	call_deferred("_refresh_perspective_objects")
	call_deferred("emit_signal", "mode_changed", _mode)


func toggle_mode() -> void:
	if _mode == PerspectiveModes.Mode.SIDE:
		set_mode(PerspectiveModes.Mode.TOPDOWN)
	else:
		set_mode(PerspectiveModes.Mode.SIDE)


func set_mode(mode: int) -> void:
	if mode != PerspectiveModes.Mode.SIDE and mode != PerspectiveModes.Mode.TOPDOWN:
		return

	var changed := _mode != mode
	_mode = mode
	_refresh_perspective_objects()
	if changed:
		mode_changed.emit(_mode)


func get_mode() -> int:
	return _mode


func refresh() -> void:
	_refresh_perspective_objects()


func _refresh_perspective_objects() -> void:
	for node in get_tree().get_nodes_in_group("perspective_objects"):
		if node.has_method("set_perspective_mode"):
			node.set_perspective_mode(_mode)
