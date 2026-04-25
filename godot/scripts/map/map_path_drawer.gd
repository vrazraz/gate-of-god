extends Control
## Draws solid anti-aliased paths between map nodes using Godot's _draw() system.

var node_positions: Dictionary = {}  # "row_col" -> Vector2 (center of node)
var all_paths: Array = []
var taken_paths: Array = []

const COLOR_PATH := Color("#3D2817")  # Dark brown for untaken paths
const COLOR_TAKEN := Color("#E8D9B3")


func setup(positions: Dictionary, paths: Array, taken: Array) -> void:
	node_positions = positions
	all_paths = paths
	taken_paths = taken
	queue_redraw()


func _draw() -> void:
	# Draw untaken paths first (behind)
	for path in all_paths:
		if not _is_path_taken(path):
			_draw_path(path, COLOR_PATH, 2.0)
	# Draw taken paths on top
	for path in all_paths:
		if _is_path_taken(path):
			_draw_path(path, COLOR_TAKEN, 2.5)


func _draw_path(path: Dictionary, color: Color, width: float) -> void:
	var from_key := "%d_%d" % [path["from"]["row"], path["from"]["col"]]
	var to_key := "%d_%d" % [path["to"]["row"], path["to"]["col"]]
	if from_key not in node_positions or to_key not in node_positions:
		return
	var from_pos: Vector2 = node_positions[from_key]
	var to_pos: Vector2 = node_positions[to_key]
	var curve_points := _bezier_curve(from_pos, to_pos, 16)
	draw_polyline(curve_points, color, width, true)


func _bezier_curve(from: Vector2, to: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var mid_y := (from.y + to.y) / 2.0
	var cp1 := Vector2(from.x, mid_y)
	var cp2 := Vector2(to.x, mid_y)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var p := _cubic_bezier(from, cp1, cp2, to, t)
		points.append(p)
	return points


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3


func _is_path_taken(path: Dictionary) -> bool:
	for tp in taken_paths:
		if tp["from"]["row"] == path["from"]["row"] \
				and tp["from"]["col"] == path["from"]["col"] \
				and tp["to"]["row"] == path["to"]["row"] \
				and tp["to"]["col"] == path["to"]["col"]:
			return true
	return false
