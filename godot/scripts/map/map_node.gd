extends Control
## Visual representation of a single node on the map.

signal node_clicked(node_data: Dictionary)

var node_data: Dictionary = {}
var is_available: bool = false
var is_visited: bool = false

@onready var icon_rect: TextureRect = $IconRect
@onready var glow: Panel = $Glow
@onready var check_label: Label = $CheckLabel

const NODE_ICON_PATHS := {
	0: "res://assets/sprites/ui/icon_combat.png",
	1: "res://assets/sprites/ui/icon_elite.png",
	2: "res://assets/sprites/ui/icon_library.png",
	3: "res://assets/sprites/ui/icon_rest.png",
	4: "res://assets/sprites/ui/icon_shop.png",
	5: "res://assets/sprites/ui/icon_event.png",
	6: "res://assets/sprites/ui/icon_boss.png",
}

const NODE_COLORS := {
	0: Color("#8B1E1E"),  # COMBAT - Crimson
	1: Color("#6B0E0E"),  # ELITE - Dark crimson
	2: Color("#2E5090"),  # LIBRARY - Academic blue
	3: Color("#FF9800"),  # REST - Warning orange
	4: Color("#D4AF37"),  # SHOP - Gold
	5: Color("#5A3E5C"),  # EVENT - Curse purple
	6: Color("#D4AF37"),  # BOSS - Gold
}

var _hover_tween: Tween


func setup(data: Dictionary) -> void:
	node_data = data
	is_visited = data.get("visited", false)

	var node_type: int = data.get("type", 0)
	var icon_path: String = NODE_ICON_PATHS.get(node_type, "")
	if icon_rect and icon_path != "" and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)

	# Boss node is larger
	if node_type == 6:
		custom_minimum_size = Vector2(48, 48)
		size = Vector2(48, 48)
		pivot_offset = Vector2(24, 24)

	_update_visual()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_available(available: bool) -> void:
	is_available = available
	_update_visual()


func _update_visual() -> void:
	if is_visited:
		modulate = Color(1, 1, 1, 0.4)
		if check_label:
			check_label.visible = true
	elif is_available:
		modulate = Color(1, 1, 1, 1.0)
		if check_label:
			check_label.visible = false
		_start_pulse()
	else:
		modulate = Color(0.75, 0.75, 0.75, 0.75)
		if check_label:
			check_label.visible = false

	# Apply glow color based on node type
	if glow:
		glow.visible = is_available and not is_visited
		var node_type: int = node_data.get("type", 0)
		var glow_color: Color = NODE_COLORS.get(node_type, Color("#D4AF37"))
		glow_color.a = 0.4
		var style := glow.get_theme_stylebox("panel")
		if style and style is StyleBoxFlat:
			var new_style := style.duplicate()
			new_style.bg_color = glow_color
			glow.add_theme_stylebox_override("panel", new_style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_available and not is_visited:
			node_clicked.emit(node_data)


func _on_mouse_entered() -> void:
	if not is_available or is_visited:
		return
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_hover_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)


func _on_mouse_exited() -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)


func _start_pulse() -> void:
	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(self, "modulate:a", 0.75, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
