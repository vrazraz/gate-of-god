extends Control
## Radiant golden glow with rotating rays behind the End Turn hourglass.

var _angle: float = 0.0
const NUM_RAYS := 12
const RAY_SPEED := 0.3
const COLOR_GOLD := Color("#D4AF37")


func _process(delta: float) -> void:
	_angle += delta * RAY_SPEED
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var r_inner := 20.0
	var r_outer := 56.0

	# Soft radial gradient glow (concentric circles fading out)
	for i in range(10, 0, -1):
		var ratio := float(i) / 10.0
		var r := r_inner + (r_outer - r_inner) * ratio
		var alpha := 0.18 * (1.0 - ratio)
		draw_circle(center, r, Color(COLOR_GOLD, alpha))

	# Rotating light rays
	for i in range(NUM_RAYS):
		var ray_angle := _angle + float(i) / float(NUM_RAYS) * TAU
		var tip := center + Vector2(cos(ray_angle), sin(ray_angle)) * r_outer
		var left_base := center + Vector2(cos(ray_angle - 0.09), sin(ray_angle - 0.09)) * r_inner
		var right_base := center + Vector2(cos(ray_angle + 0.09), sin(ray_angle + 0.09)) * r_inner

		var colors := PackedColorArray([
			Color(COLOR_GOLD, 0.5),
			Color(COLOR_GOLD, 0.5),
			Color(COLOR_GOLD, 0.0),
		])
		draw_polygon(PackedVector2Array([left_base, right_base, tip]), colors)
