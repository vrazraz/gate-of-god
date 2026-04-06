extends Control
## Visual card component. Handles display, hover, and drag & drop for a single card in hand.

signal card_clicked(card_id: String)
signal card_hovered(card_id: String)
signal card_unhovered(card_id: String)
signal card_drag_started(card_node: Control)
signal card_drag_released(card_node: Control, release_position: Vector2)

@export var card_id: String = ""

var card_data: Dictionary = {}
var is_playable: bool = true

@onready var name_label: Label = $CardPanel/NameLabel
@onready var cost_label: Label = $CardPanel/CostCrystal/CostLabel
@onready var description_label: Label = $CardPanel/DescriptionLabel
@onready var type_label: Label = $CardPanel/TypeLabel
@onready var card_panel: Panel = $CardPanel
@onready var art_rect: TextureRect = $CardPanel/ArtRect

# Colors from FRONTEND.md
const COLOR_ATTACK := Color("#8B1E1E")
const COLOR_SKILL := Color("#2E5090")
const COLOR_POWER := Color("#2D5F3F")
const COLOR_CURSE := Color("#5A3E5C")
const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_INK := Color("#1A1A1A")

var _is_hovered: bool = false
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_start_global_pos: Vector2 = Vector2.ZERO


func setup(data: Dictionary) -> void:
	card_data = data
	card_id = data.get("id", "")

	if name_label:
		name_label.text = data.get("name", "Неизвестная карта")
		name_label.add_theme_color_override("font_color", COLOR_INK)
	if cost_label:
		cost_label.text = str(data.get("cost", 0))
	if description_label:
		description_label.text = data.get("description", "")
		description_label.add_theme_color_override("font_color", Color("#5C4A3A"))
	if type_label:
		var type_names := {"attack": "АТАКА", "skill": "УМЕНИЕ", "power": "СИЛА", "curse": "ПРОКЛЯТИЕ"}
		type_label.text = type_names.get(data.get("type", ""), data.get("type", "").to_upper())

	# Load card art
	if art_rect:
		var art_path := "res://assets/sprites/cards/%s.png" % data.get("id", "")
		if ResourceLoader.exists(art_path):
			art_rect.texture = load(art_path)

	# Set pivot to center for proper scale animation
	pivot_offset = custom_minimum_size / 2.0 if custom_minimum_size != Vector2.ZERO else Vector2(70, 100)

	# Connect hover signals
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	# Show tier badge
	_update_tier_badge(data)

	_update_card_style()
	_add_shadow()


var _shadow: Panel = null

func _add_shadow() -> void:
	_shadow = Panel.new()
	_shadow.name = "Shadow"
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.size = Vector2(140, 200)
	_shadow.position = Vector2(-1.0, 1.0)
	_shadow.show_behind_parent = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.15)
	style.set_corner_radius_all(8)
	_shadow.add_theme_stylebox_override("panel", style)
	add_child(_shadow)


func _update_card_style() -> void:
	if not card_panel:
		return

	var card_type: String = card_data.get("type", "attack")

	# Load PNG frame as background
	var frame_path := "res://assets/sprites/cards/card_frame_%s.png" % card_type
	if ResourceLoader.exists(frame_path):
		var frame_tex: Texture2D = load(frame_path)
		var stylebox := StyleBoxTexture.new()
		stylebox.texture = frame_tex
		card_panel.add_theme_stylebox_override("panel", stylebox)
	else:
		# Fallback to flat style
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = COLOR_PARCHMENT
		stylebox.set_border_width_all(2)
		stylebox.set_corner_radius_all(8)
		match card_type:
			"attack": stylebox.border_color = COLOR_ATTACK
			"skill": stylebox.border_color = COLOR_SKILL
			"power": stylebox.border_color = COLOR_POWER
			"curse": stylebox.border_color = COLOR_CURSE
			_: stylebox.border_color = COLOR_INK
		card_panel.add_theme_stylebox_override("panel", stylebox)


const TIER_COLORS := {
	1: Color("#CCCCCC"),  # White/Silver
	2: Color("#2E5090"),  # Blue
	3: Color("#D4AF37"),  # Gold
}


func _update_tier_badge(_data: Dictionary) -> void:
	pass


func set_playable(playable: bool) -> void:
	is_playable = playable
	if card_panel:
		card_panel.modulate.a = 1.0 if playable else 0.5


func _on_mouse_entered() -> void:
	if not is_playable or _is_dragging:
		return
	_is_hovered = true
	z_index = 10
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	if _shadow:
		tween.tween_property(_shadow, "position", Vector2(-5.0, 5.0), 0.1)
		tween.tween_property(_shadow, "modulate:a", 1.0, 0.1)
	card_hovered.emit(card_id)


func _on_mouse_exited() -> void:
	if _is_dragging:
		return
	_is_hovered = false
	z_index = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	if _shadow:
		tween.tween_property(_shadow, "position", Vector2(-1.0, 1.0), 0.1)
		tween.tween_property(_shadow, "modulate:a", 0.75, 0.1)
	card_unhovered.emit(card_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_playable:
			_start_drag(event.global_position)
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return

	if event is InputEventMouseMotion:
		global_position = event.global_position - _drag_offset
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag(event.global_position)
		get_viewport().set_input_as_handled()


func _start_drag(mouse_global: Vector2) -> void:
	_is_dragging = true
	_drag_start_global_pos = global_position
	_drag_offset = mouse_global - global_position
	z_index = 100
	top_level = true
	global_position = _drag_start_global_pos
	scale = Vector2(1.05, 1.05)
	modulate.a = 0.9
	card_drag_started.emit(self)


func _end_drag(release_pos: Vector2) -> void:
	_is_dragging = false
	top_level = false
	z_index = 0
	scale = Vector2(1.0, 1.0)
	modulate.a = 1.0
	card_drag_released.emit(self, release_pos)
