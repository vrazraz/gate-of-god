extends Control
## Draws intent icons for enemy actions using colored circle + white symbol.

var intent_type: String = ""
var intent_color: Color = Color.WHITE


func set_intent(type: String, color: Color) -> void:
	intent_type = type
	intent_color = color
	queue_redraw()


func _draw() -> void:
	if intent_type.is_empty():
		return
	var center: Vector2 = size / 2.0
	var r: float = min(size.x, size.y) / 2.0 - 1.0
	# Black outline circle
	draw_circle(center, r + 2.0, Color.BLACK)
	# Background circle
	draw_circle(center, r, Color(intent_color, 0.85))
	# White symbol
	var w := Color.WHITE
	match intent_type:
		"attack":
			_draw_sword(center, r, w)
		"debuff":
			_draw_poison(center, r, w)
		"buff":
			_draw_arrow_up(center, r, w)
		"curse":
			_draw_skull(center, r, w)
		_:
			_draw_question(center, r, w)


func _draw_sword(c: Vector2, r: float, col: Color) -> void:
	# Blade
	draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.1), col, 2.5, true)
	# Blade tip
	draw_line(c + Vector2(-r * 0.12, -r * 0.5), c + Vector2(0, -r * 0.75), col, 2.0, true)
	draw_line(c + Vector2(r * 0.12, -r * 0.5), c + Vector2(0, -r * 0.75), col, 2.0, true)
	# Crossguard
	draw_line(c + Vector2(-r * 0.4, r * 0.1), c + Vector2(r * 0.4, r * 0.1), col, 2.5, true)
	# Handle
	draw_line(c + Vector2(0, r * 0.1), c + Vector2(0, r * 0.55), col, 2.0, true)
	# Pommel
	draw_circle(c + Vector2(0, r * 0.62), r * 0.09, col)


func _draw_poison(c: Vector2, r: float, col: Color) -> void:
	# Droplet body
	var body_c := c + Vector2(0, r * 0.15)
	draw_circle(body_c, r * 0.38, col)
	# Droplet tip
	var pts := PackedVector2Array([
		c + Vector2(0, -r * 0.6),
		body_c + Vector2(-r * 0.3, -r * 0.18),
		body_c + Vector2(r * 0.3, -r * 0.18),
	])
	draw_colored_polygon(pts, col)


func _draw_arrow_up(c: Vector2, r: float, col: Color) -> void:
	var tip := c + Vector2(0, -r * 0.6)
	draw_line(c + Vector2(0, r * 0.6), tip, col, 2.5, true)
	draw_line(tip, tip + Vector2(-r * 0.35, r * 0.35), col, 2.5, true)
	draw_line(tip, tip + Vector2(r * 0.35, r * 0.35), col, 2.5, true)


func _draw_skull(c: Vector2, r: float, col: Color) -> void:
	# Head
	draw_circle(c + Vector2(0, -r * 0.1), r * 0.5, col)
	# Jaw
	draw_line(c + Vector2(-r * 0.25, r * 0.25), c + Vector2(r * 0.25, r * 0.25), col, 2.0, true)
	draw_line(c + Vector2(-r * 0.25, r * 0.25), c + Vector2(-r * 0.25, r * 0.45), col, 1.5, true)
	draw_line(c + Vector2(r * 0.25, r * 0.25), c + Vector2(r * 0.25, r * 0.45), col, 1.5, true)
	draw_line(c + Vector2(-r * 0.25, r * 0.45), c + Vector2(r * 0.25, r * 0.45), col, 1.5, true)
	# Eyes (dark holes)
	var eye_col := Color(intent_color, 0.85)
	draw_circle(c + Vector2(-r * 0.2, -r * 0.15), r * 0.12, eye_col)
	draw_circle(c + Vector2(r * 0.2, -r * 0.15), r * 0.12, eye_col)


func _draw_question(c: Vector2, r: float, col: Color) -> void:
	draw_arc(c + Vector2(0, -r * 0.2), r * 0.25, deg_to_rad(180), deg_to_rad(450), 16, col, 2.5, true)
	draw_circle(c + Vector2(0, r * 0.35), r * 0.08, col)
