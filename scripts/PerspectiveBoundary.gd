extends Node2D
class_name PerspectiveBoundary

const PerspectiveModes := preload("res://scripts/PerspectiveModes.gd")

@export var advance_duration := 0.55
@export var topdown_is_right_side := true

@onready var initial_start: Marker2D = $InitialLine/Start
@onready var initial_end: Marker2D = $InitialLine/End
@onready var advanced_start: Marker2D = $AdvancedLine/Start
@onready var advanced_end: Marker2D = $AdvancedLine/End
@onready var active_line: Line2D = $ActiveLine
@onready var target_line: Line2D = $TargetLine

var _current_start := Vector2.ZERO
var _current_end := Vector2.ZERO
var _tween_from_start := Vector2.ZERO
var _tween_from_end := Vector2.ZERO
var _advanced := false
var _advancing := false


func _ready() -> void:
	add_to_group("perspective_boundary")
	_current_start = initial_start.global_position
	_current_end = initial_end.global_position
	_update_visuals()
	call_deferred("_refresh_perspective_objects")


func advance_boundary() -> bool:
	if _advanced or _advancing:
		return false

	_advanced = true
	_advancing = true
	_tween_from_start = _current_start
	_tween_from_end = _current_end

	var tween := create_tween()
	tween.tween_method(Callable(self, "_set_boundary_progress"), 0.0, 1.0, advance_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_advance_finished)
	return true


func get_mode_for_point(point: Vector2) -> int:
	var line_vector := _current_end - _current_start
	var point_vector := point - _current_start
	var cross := line_vector.cross(point_vector)
	if topdown_is_right_side:
		return PerspectiveModes.Mode.TOPDOWN if cross < 0.0 else PerspectiveModes.Mode.SIDE
	return PerspectiveModes.Mode.SIDE if cross < 0.0 else PerspectiveModes.Mode.TOPDOWN


func _set_boundary_progress(progress: float) -> void:
	_current_start = _tween_from_start.lerp(advanced_start.global_position, progress)
	_current_end = _tween_from_end.lerp(advanced_end.global_position, progress)
	_update_visuals()
	_refresh_perspective_objects()


func _on_advance_finished() -> void:
	_current_start = advanced_start.global_position
	_current_end = advanced_end.global_position
	_advancing = false
	_update_visuals()
	_refresh_perspective_objects()


func _update_visuals() -> void:
	active_line.points = PackedVector2Array([
		to_local(_current_start),
		to_local(_current_end),
	])
	target_line.points = PackedVector2Array([
		to_local(advanced_start.global_position),
		to_local(advanced_end.global_position),
	])


func _refresh_perspective_objects() -> void:
	for node in get_tree().get_nodes_in_group("perspective_objects"):
		if node == self or not node.has_method("set_perspective_mode"):
			continue

		var sample_position := Vector2.ZERO
		if node.has_method("get_mode_sample_position"):
			sample_position = node.get_mode_sample_position()
		elif node is Node2D:
			sample_position = node.global_position
		else:
			continue

		node.set_perspective_mode(get_mode_for_point(sample_position))
