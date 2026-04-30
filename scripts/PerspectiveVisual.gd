extends Node2D
class_name PerspectiveVisual

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export_category("透视视觉组件")

@export_group("初始状态")
## 没有透视控制器时使用的默认视角模式。
@export_enum("SIDE", "TOPDOWN") var initial_mode: int = PerspectiveModes.Mode.SIDE

@export_group("节点路径")
## 目标视觉节点路径。组件只修改该节点的 position 和 scale，不改变父节点、碰撞或运动逻辑。
@export var visual_path: NodePath = NodePath("../Visual")
## 影子节点路径。推荐使用 Polygon2D，组件只修改 position、scale 和透明度。
@export var shadow_path: NodePath = NodePath("../Shadow")

@export_group("横版视觉")
## 横版模式下目标视觉节点的缩放。
@export var side_visual_scale := Vector2.ONE
## 横版模式下目标视觉节点相对父节点的偏移。
@export var side_visual_offset := Vector2.ZERO
## 横版模式下影子的缩放。
@export var side_shadow_scale := Vector2.ONE
## 横版模式下影子相对父节点的偏移。
@export var side_shadow_offset := Vector2.ZERO
## 横版模式下影子的最终透明度。
@export_range(0.0, 1.0, 0.01) var side_shadow_alpha := 0.3

@export_group("俯视视觉")
## 俯视模式下目标视觉节点的缩放。
@export var topdown_visual_scale := Vector2.ONE
## 俯视模式下目标视觉节点相对父节点的偏移。
@export var topdown_visual_offset := Vector2.ZERO
## 俯视模式下影子的缩放。
@export var topdown_shadow_scale := Vector2.ONE
## 俯视模式下影子相对父节点的偏移。
@export var topdown_shadow_offset := Vector2.ZERO
## 俯视模式下影子的最终透明度。
@export_range(0.0, 1.0, 0.01) var topdown_shadow_alpha := 0.24

@export_group("过渡")
## 视角切换时视觉节点和影子的补间时长。
@export_range(0.0, 1.0, 0.01) var transition_duration := 0.22

@export_group("俯视Y排序")
## 俯视模式下是否根据父节点 global_position.y 调整层级，让靠下物体遮住靠上物体。
@export var topdown_y_sort_enabled := true
## 俯视Y排序的额外层级偏移，用于微调同一高度物体的前后关系。
@export var topdown_y_sort_offset := 0
## 俯视Y排序使用的Y坐标缩放。值越大，层级差距越小。
@export_range(1.0, 32.0, 0.1) var topdown_y_sort_step := 1.0

var _mode: int = PerspectiveModes.Mode.SIDE
var _visual: Node2D
var _shadow: Node2D
var _sort_item: CanvasItem
var _base_z_index := 0
var _base_z_captured := false
var _ready_done := false
var _tween: Tween
var _visual_scale_multiplier := Vector2.ONE
var _shadow_alpha_multiplier := 1.0


func _enter_tree() -> void:
	add_to_group("perspective_objects")


func _ready() -> void:
	_cache_nodes()
	_capture_base_z_index()
	_mode = initial_mode
	_sync_with_controller()
	_ready_done = true
	_apply_mode(false)


func set_perspective_mode(mode: int) -> void:
	if mode != PerspectiveModes.Mode.SIDE and mode != PerspectiveModes.Mode.TOPDOWN:
		return

	var changed := _mode != mode
	_mode = mode
	_cache_nodes()
	_apply_mode(changed and _ready_done)


func get_mode_sample_position() -> Vector2:
	var owner := get_parent()
	if owner != null and owner.has_method("get_mode_sample_position"):
		return owner.get_mode_sample_position()
	if owner is Node2D:
		return (owner as Node2D).global_position
	return global_position


func set_visual_scale_multiplier(multiplier: Vector2) -> void:
	_visual_scale_multiplier = multiplier
	_apply_mode(false)


func set_shadow_alpha_multiplier(multiplier: float) -> void:
	_shadow_alpha_multiplier = clampf(multiplier, 0.0, 1.0)
	_apply_mode(_ready_done and transition_duration > 0.0)


func _process(_delta: float) -> void:
	if _mode == PerspectiveModes.Mode.TOPDOWN and topdown_y_sort_enabled:
		_apply_y_sort()


func _cache_nodes() -> void:
	if _visual == null or not is_instance_valid(_visual):
		_visual = get_node_or_null(visual_path) as Node2D
	if _shadow == null or not is_instance_valid(_shadow):
		_shadow = get_node_or_null(shadow_path) as Node2D
	if _sort_item == null or not is_instance_valid(_sort_item):
		_sort_item = get_parent() as CanvasItem


func _capture_base_z_index() -> void:
	if _base_z_captured or _sort_item == null:
		return

	_base_z_index = _sort_item.z_index
	_base_z_captured = true


func _sync_with_controller() -> void:
	var controller := get_tree().get_first_node_in_group("perspective_controller")
	if controller != null and controller.has_method("get_mode"):
		set_perspective_mode(controller.get_mode())


func _apply_mode(animated: bool) -> void:
	_cache_nodes()
	_capture_base_z_index()

	var target_visual_scale := side_visual_scale
	var target_visual_offset := side_visual_offset
	var target_shadow_scale := side_shadow_scale
	var target_shadow_offset := side_shadow_offset
	var target_shadow_alpha := side_shadow_alpha

	if _mode == PerspectiveModes.Mode.TOPDOWN:
		target_visual_scale = topdown_visual_scale
		target_visual_offset = topdown_visual_offset
		target_shadow_scale = topdown_shadow_scale
		target_shadow_offset = topdown_shadow_offset
		target_shadow_alpha = topdown_shadow_alpha

	target_visual_scale = Vector2(
		target_visual_scale.x * _visual_scale_multiplier.x,
		target_visual_scale.y * _visual_scale_multiplier.y
	)
	target_shadow_alpha *= _shadow_alpha_multiplier

	if _tween != null:
		_tween.kill()

	if not animated or transition_duration <= 0.0:
		_set_visual_state(target_visual_scale, target_visual_offset, target_shadow_scale, target_shadow_offset, target_shadow_alpha)
		_update_sorting_state()
		return

	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	if _visual != null:
		_tween.tween_property(_visual, "scale", target_visual_scale, transition_duration)
		_tween.tween_property(_visual, "position", target_visual_offset, transition_duration)
	if _shadow != null:
		_tween.tween_property(_shadow, "scale", target_shadow_scale, transition_duration)
		_tween.tween_property(_shadow, "position", target_shadow_offset, transition_duration)
		var target_modulate := _shadow.modulate
		target_modulate.a = target_shadow_alpha
		_tween.tween_property(_shadow, "modulate", target_modulate, transition_duration)

	_update_sorting_state()


func _set_visual_state(
	target_visual_scale: Vector2,
	target_visual_offset: Vector2,
	target_shadow_scale: Vector2,
	target_shadow_offset: Vector2,
	target_shadow_alpha: float
) -> void:
	if _visual != null:
		_visual.scale = target_visual_scale
		_visual.position = target_visual_offset
	if _shadow != null:
		_shadow.scale = target_shadow_scale
		_shadow.position = target_shadow_offset
		var shadow_modulate := _shadow.modulate
		shadow_modulate.a = target_shadow_alpha
		_shadow.modulate = shadow_modulate


func _update_sorting_state() -> void:
	if _sort_item == null:
		set_process(false)
		return

	if _mode == PerspectiveModes.Mode.TOPDOWN and topdown_y_sort_enabled:
		set_process(true)
		_apply_y_sort()
	else:
		set_process(false)
		if _base_z_captured:
			_sort_item.z_index = _base_z_index


func _apply_y_sort() -> void:
	if _sort_item == null:
		return

	var owner := get_parent()
	var owner_y := global_position.y
	if owner is Node2D:
		owner_y = (owner as Node2D).global_position.y
	var sorted_z := int(round(owner_y / topdown_y_sort_step)) + topdown_y_sort_offset
	_sort_item.z_index = clampi(sorted_z, -4096, 4096)
