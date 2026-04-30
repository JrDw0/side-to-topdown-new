extends Area2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var boundary_path: NodePath
@export var required_box_path: NodePath
@export var required_min_x := 520.0
@export var required_max_x := 610.0
@export var required_track_index := 2

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label

var _boundary: Node
var _required_box: Node
var _player_inside := false
var _used := false
var _message_timer := 0.0


func _ready() -> void:
	_boundary = get_node_or_null(boundary_path)
	_required_box = get_node_or_null(required_box_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _process(delta: float) -> void:
	_message_timer = maxf(0.0, _message_timer - delta)
	if _player_inside and Input.is_action_just_pressed("interact"):
		_try_activate()
	_update_visuals()


func _try_activate() -> void:
	if _used or _boundary == null:
		return

	if not _requirements_met():
		_message_timer = 0.6
		return

	if _boundary.advance_boundary():
		_used = true


func _requirements_met() -> bool:
	if _required_box == null or not _required_box.has_method("is_in_required_position"):
		return true
	return _required_box.is_in_required_position(required_min_x, required_max_x, required_track_index)


func _update_visuals() -> void:
	if _used:
		visual.color = Color(0.45, 0.9, 0.55, 1.0)
		label.text = "已推进"
	elif _message_timer > 0.0:
		visual.color = Color(1.0, 0.35, 0.25, 1.0)
		label.text = "箱子未对齐"
	elif _requirements_met():
		visual.color = Color(0.35, 0.85, 1.0, 1.0)
		label.text = "E"
	else:
		visual.color = Color(0.55, 0.65, 0.72, 1.0)
		label.text = "锁定"


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("reset_to_safe_point"):
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("reset_to_safe_point"):
		_player_inside = false
