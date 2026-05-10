extends Area2D
class_name Key

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_category("钥匙")

@export_group("基础配置")
## 钥匙ID。通关点的 required_key_id 与这里一致时，拾取后即可解锁该通关点。
@export var key_id: StringName = &"key"
## 编辑器和关卡中显示的钥匙名称。
@export var display_name := "钥匙"
## 钥匙响应的视角。只有当前视角匹配时玩家才能拾取。
@export_enum("SIDE", "TOPDOWN") var active_mode := 1

@export_group("视觉")
## 钥匙可拾取时的颜色。
@export var available_color := Color(1.0, 0.86, 0.22, 1.0)
## 钥匙在非响应视角下的透明度。
@export_range(0.0, 1.0, 0.01) var inactive_alpha := 0.24

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = get_node_or_null("Label") as Label
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _active := false
var _collected := false


func _ready() -> void:
	add_to_group("perspective_objects")
	body_entered.connect(_on_body_entered)
	if label != null:
		label.text = display_name
	_sync_with_controller()
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
	_active = not _collected and _mode == active_mode
	monitoring = _active
	collision_shape.disabled = not _active
	visible = not _collected
	visual.color = available_color
	visual.modulate.a = 1.0 if _active else inactive_alpha
	if label != null:
		label.modulate.a = 1.0 if _active else inactive_alpha
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(1.0 if _active else inactive_alpha)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not _active or not body.has_method("collect_key"):
		return

	body.collect_key(key_id)
	_collected = true
	_apply_state()
