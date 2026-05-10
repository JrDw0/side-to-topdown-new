extends Area2D
class_name StarItem

signal star_collected

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _mode: int = PerspectiveModes.Mode.SIDE
var _collected := false


func _ready() -> void:
	add_to_group("perspective_objects")
	add_to_group("star_items")
	body_entered.connect(_on_body_entered)
	_sync_with_controller()
	_apply_state()


func set_perspective_mode(mode: int) -> void:
	_mode = mode
	_apply_state()


func _apply_state() -> void:
	if _collected:
		visible = false
		return
	monitoring = true
	collision_shape.disabled = false
	visual.modulate.a = 1.0


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	star_collected.emit()
	_apply_state()
