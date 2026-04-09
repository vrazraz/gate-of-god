extends Control
## Circular energy ring around the end-turn button.
## Renders a 3/4-circle (270°) split into segments — one per max-energy unit.
## Filled segments are gold (remaining energy); spent segments fade to dark.

const RING_RADIUS := 56.0
const RING_WIDTH := 8.0
const COLOR_FILLED := Color("#D4AF37")  # gold
const COLOR_EMPTY := Color(0.36, 0.29, 0.23, 0.55)  # warm dark, faded
const TOTAL_SWEEP := TAU * 0.75         # 270°
const START_ANGLE := PI * 0.75          # gap centered at the bottom
const SEGMENT_GAP_DEG := 4.0
const ARC_POINTS := 24


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Engine.has_singleton("GameState"):
		pass  # GameState is an autoload, accessible directly
	GameState.energy_changed.connect(_on_energy_changed)
	queue_redraw()


func _on_energy_changed(_current: int, _maximum: int) -> void:
	queue_redraw()


func _draw() -> void:
	var max_e: int = GameState.max_energy
	var cur_e: int = GameState.current_energy
	if max_e <= 0:
		return

	var center: Vector2 = size / 2.0
	var seg_total: float = TOTAL_SWEEP / float(max_e)
	var gap_rad: float = deg_to_rad(SEGMENT_GAP_DEG)
	var seg_arc: float = max(0.01, seg_total - gap_rad)

	for i in range(max_e):
		var seg_start: float = START_ANGLE + float(i) * seg_total + gap_rad / 2.0
		var seg_end: float = seg_start + seg_arc
		var color: Color = COLOR_FILLED if i < cur_e else COLOR_EMPTY
		draw_arc(center, RING_RADIUS, seg_start, seg_end, ARC_POINTS, color, RING_WIDTH, true)
