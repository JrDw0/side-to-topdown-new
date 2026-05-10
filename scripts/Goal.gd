extends Area2D

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_category("通关点")

@export_group("基础配置")
## 通关点响应的视角。只有当前视角匹配时才会触发。
@export_enum("SIDE", "TOPDOWN") var active_mode := 0
## 通关后进入的下一个场景。留空时只调用当前关卡的 complete_level。
@export_file("*.tscn") var next_scene_path := ""
## 解锁通关点需要的钥匙ID。留空表示不需要钥匙。
@export var required_key_id: StringName = &""

@export_group("锁定反馈")
## 没有配置钥匙，或玩家已经拥有钥匙时的通关点颜色。
@export var unlocked_color := Color(0.35, 1.0, 0.42, 1.0)
## 需要钥匙但尚未解锁时的通关点颜色。
@export var locked_color := Color(1.0, 0.18, 0.12, 1.0)
## 玩家缺少钥匙时触碰通关点的闪烁颜色。
@export var locked_feedback_color := Color(1.0, 0.18, 0.12, 1.0)
## 玩家缺少钥匙时是否短暂显示提示文本。
@export var show_locked_label := true

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var perspective_visual: Node = get_node_or_null("PerspectiveVisual")
@onready var locked_label: Label = get_node_or_null("LockedLabel") as Label

var _mode: int = PerspectiveModes.Mode.TOPDOWN
var _active := false
var _completed := false
var _unlocked := true
var _feedback_tween: Tween


func _ready() -> void:
	add_to_group("perspective_objects")
	body_entered.connect(_on_body_entered)
	if locked_label != null:
		locked_label.visible = false
	_sync_with_controller()
	_apply_state()


func _process(_delta: float) -> void:
	if String(required_key_id).is_empty() or _completed:
		return

	_update_unlock_state()


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
	_active = _mode == active_mode
	monitoring = _active
	collision_shape.disabled = not _active
	_update_unlock_state()
	visual.modulate.a = 1.0 if _active else 0.24
	if perspective_visual != null and perspective_visual.has_method("set_shadow_alpha_multiplier"):
		perspective_visual.set_shadow_alpha_multiplier(1.0 if _active else 0.24)


func _on_body_entered(body: Node2D) -> void:
	if _completed or not _active or not body.has_method("reach_goal"):
		return
	if _is_locked_for(body):
		_show_locked_feedback()
		return

	_completed = true
	body.reach_goal()
	if next_scene_path != "":
		get_tree().call_deferred("change_scene_to_file", next_scene_path)
		return

	var level: Node = get_tree().current_scene
	if level != null and level.has_method("complete_level"):
		level.complete_level()


func _is_locked_for(body: Node) -> bool:
	if String(required_key_id).is_empty():
		return false
	if not body.has_method("has_key"):
		return true

	return not body.has_key(required_key_id)


func _show_locked_feedback() -> void:
	if locked_label != null and show_locked_label:
		locked_label.visible = true

	if _feedback_tween != null:
		_feedback_tween.kill()

	_feedback_tween = create_tween()
	_feedback_tween.tween_property(visual, "color", locked_feedback_color, 0.08)
	_feedback_tween.tween_property(visual, "color", _get_target_color(), 0.18)
	if locked_label != null and show_locked_label:
		_feedback_tween.tween_interval(0.55)
		_feedback_tween.tween_callback(func() -> void:
			if locked_label != null:
				locked_label.visible = false
		)


func _update_unlock_state() -> void:
	_unlocked = true
	if not String(required_key_id).is_empty():
		var player := get_tree().get_first_node_in_group("player")
		_unlocked = player != null and player.has_method("has_key") and player.has_key(required_key_id)

	if _feedback_tween == null or not _feedback_tween.is_running():
		visual.color = _get_target_color()


func _get_target_color() -> Color:
	return unlocked_color if _unlocked else locked_color
