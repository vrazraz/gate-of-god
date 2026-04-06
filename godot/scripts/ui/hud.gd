extends Control
## HUD: displays Energy and End Turn button (hourglass in top-right).
## HP, Gold, Block are shown in the player area (combat_scene.gd).

signal end_turn_pressed()

@onready var energy_label: Label = $BottomBar/EnergyLabel
@onready var end_turn_button: TextureButton = $EndTurnArea/EndTurnButton
@onready var end_turn_label: Label = $EndTurnArea/EndTurnLabel

var _end_turn_glow: Control = null
var _glow_tween: Tween = null


func _ready() -> void:
	GameState.energy_changed.connect(_on_energy_changed)

	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	_build_end_turn_glow()
	update_all()


func _build_end_turn_glow() -> void:
	if not end_turn_button:
		return

	_end_turn_glow = Control.new()
	_end_turn_glow.set_script(load("res://scripts/ui/end_turn_glow.gd"))
	_end_turn_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_turn_glow.visible = false
	_end_turn_glow.size = Vector2(120, 120)
	add_child(_end_turn_glow)
	# Move behind EndTurnArea so rays are under the hourglass
	var end_turn_area := $EndTurnArea
	if end_turn_area:
		move_child(_end_turn_glow, end_turn_area.get_index())


func _process(_delta: float) -> void:
	if _end_turn_glow and _end_turn_glow.visible and end_turn_button:
		var btn_center := end_turn_button.global_position + end_turn_button.size / 2.0
		_end_turn_glow.global_position = btn_center - _end_turn_glow.size / 2.0


func _on_end_turn_pressed() -> void:
	# Click animation: quick rotate + scale pulse
	if end_turn_button:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(end_turn_button, "rotation", TAU, 0.5).from(0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(end_turn_button, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(end_turn_button, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
		# Set pivot to center for rotation
		end_turn_button.pivot_offset = end_turn_button.size / 2.0
	end_turn_pressed.emit()


func update_all() -> void:
	_on_energy_changed(GameState.current_energy, GameState.max_energy)


func _on_energy_changed(current: int, maximum: int) -> void:
	if energy_label:
		energy_label.text = "Энергия: %d/%d" % [current, maximum]

	if current <= 0:
		_start_glow_pulse()
	else:
		_stop_glow_pulse()


func _start_glow_pulse() -> void:
	if not _end_turn_glow:
		return
	if _end_turn_glow.visible:
		return
	_end_turn_glow.visible = true
	_end_turn_glow.modulate.a = 0.0

	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_end_turn_glow, "modulate:a", 1.0, 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_end_turn_glow, "modulate:a", 0.25, 0.8) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_glow_pulse() -> void:
	if not _end_turn_glow:
		return
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null
	_end_turn_glow.visible = false


func update_deck_counts(_draw_count: int, _discard_count: int) -> void:
	pass
