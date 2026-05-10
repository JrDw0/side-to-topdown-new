extends Area2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_enum("SIDE", "TOPDOWN") var active_mode := 0
@export_file("*.tscn") var next_scene_path := ""
@export var locked := false

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _active := false
var _completed := false
var _locked_state := false


func _ready() -> void:
	add_to_group("perspective_objects")
	add_to_group("level_goal")
	_locked_state = locked
	body_entered.connect(_on_body_entered)
	_sync_with_controller()
	_apply_state()


func unlock() -> void:
	_locked_state = false
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
	_active = _mode == active_mode and not _locked_state
	monitoring = _active
	collision_shape.disabled = not _active
	visual.modulate.a = 1.0 if _active else 0.24
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(1.0 if _active else 0.24)


func _on_body_entered(body: Node2D) -> void:
	if _completed or not _active or not body.has_method("reach_goal"):
		return

	_completed = true
	body.reach_goal()
	if next_scene_path != "":
		get_tree().call_deferred("change_scene_to_file", next_scene_path)
		return

	var level: Node = get_tree().current_scene
	if level != null and level.has_method("complete_level"):
		level.complete_level()
