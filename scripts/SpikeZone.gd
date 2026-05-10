extends Area2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

var _mode: int = PerspectiveModes.Mode.SIDE


func _ready() -> void:
	add_to_group("perspective_objects")
	body_entered.connect(_on_body_entered)
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_state()


func _apply_state() -> void:
	monitoring = _mode == PerspectiveModes.Mode.SIDE


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _on_body_entered(body: Node2D) -> void:
	if _mode == PerspectiveModes.Mode.SIDE and body.has_method("reset_to_safe_point"):
		body.reset_to_safe_point()
