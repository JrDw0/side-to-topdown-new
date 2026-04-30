extends Area2D
class_name PerspectiveSwitch

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var controller_path: NodePath

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label

var _controller: Node
var _player_inside := false
var _mode: int = PerspectiveModes.Mode.SIDE


func _ready() -> void:
	add_to_group("perspective_objects")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_bind_controller()
	call_deferred("_bind_controller")
	_apply_visuals()


func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact"):
		var controller := _get_controller()
		if controller != null and controller.has_method("toggle_mode"):
			controller.call("toggle_mode")


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_visuals()


func _bind_controller() -> void:
	var controller := _get_controller()
	if controller != null and not controller.is_connected("mode_changed", Callable(self, "set_perspective_mode")):
		controller.connect("mode_changed", Callable(self, "set_perspective_mode"))
		if controller.has_method("get_mode"):
			set_perspective_mode(controller.get_mode())


func _get_controller() -> Node:
	if _controller != null and is_instance_valid(_controller):
		return _controller

	if String(controller_path) != "":
		_controller = get_node_or_null(controller_path)
	if _controller == null:
		_controller = get_tree().get_first_node_in_group("perspective_controller")
	return _controller


func _apply_visuals() -> void:
	if _mode == PerspectiveModes.Mode.SIDE:
		visual.color = Color(0.25, 0.58, 1.0, 1.0)
		label.text = "E SIDE"
	else:
		visual.color = Color(0.1, 0.88, 0.68, 1.0)
		label.text = "E TOP"


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
