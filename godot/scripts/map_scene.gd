extends Control
## Map scene. Shows the procedural map and allows node selection.
## Renders nodes in a scrollable vertical layout with dashed path connections.

@onready var map_container: Control = $MapContainer
@onready var title_label: Label = $TitleLabel
@onready var info_label: Label = $InfoLabel

var map_node_scene: PackedScene = preload("res://scenes/ui/map_node.tscn")
var tutorial_overlay_scene: PackedScene = preload("res://scenes/ui/tutorial_overlay.tscn")

var _scroll_container: ScrollContainer
var _map_surface: Control
var _path_drawer: Control

const ROW_HEIGHT: float = 80.0
const NODE_SIZE: float = 40.0
const MAP_WIDTH: int = 7
const MAP_HEIGHT: int = 15
const VIEWPORT_WIDTH: float = 1280.0
const MAP_CONTENT_WIDTH: float = 760.0
const PADDING_TOP: float = 50.0
const PADDING_BOTTOM: float = 50.0

# Node type names for placeholder display
const NODE_TYPE_NAMES := {
	2: "Библиотека",
	3: "Место отдыха",
	4: "Магазин",
	5: "Событие",
}


func _ready() -> void:
	title_label.text = "Акт %d — Карта" % GameState.current_act

	# Generate map if not already in game state
	if GameState.map_data.is_empty():
		var gen := preload("res://scripts/map/map_generator.gd").new()
		add_child(gen)
		GameState.map_data = gen.generate_map(GameState.current_act)
		gen.queue_free()

	_build_map_display()

	# Tutorial: map loaded trigger
	if TutorialManager.is_active():
		var overlay = tutorial_overlay_scene.instantiate()
		add_child(overlay)
		TutorialManager.on_map_loaded()


func _build_map_display() -> void:
	var map_data: Dictionary = GameState.map_data
	var nodes: Array = map_data.get("nodes", [])
	var paths: Array = map_data.get("paths", [])
	var height: int = map_data.get("height", MAP_HEIGHT)

	# Calculate surface height
	var surface_height: float = height * ROW_HEIGHT + PADDING_TOP + PADDING_BOTTOM

	# Create scroll container inside MapContainer
	_scroll_container = ScrollContainer.new()
	_scroll_container.anchors_preset = Control.PRESET_FULL_RECT
	_scroll_container.anchor_right = 1.0
	_scroll_container.anchor_bottom = 1.0
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_container.add_child(_scroll_container)

	# Create map surface (scrollable content)
	_map_surface = Control.new()
	_map_surface.custom_minimum_size = Vector2(VIEWPORT_WIDTH, surface_height)
	_scroll_container.add_child(_map_surface)

	# Add background inside scroll surface so it scrolls with the map
	var bg_tex = load("res://assets/sprites/ui/map_bg.png")
	if bg_tex:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.custom_minimum_size = Vector2(VIEWPORT_WIDTH, surface_height)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_surface.add_child(bg)

		# Semi-transparent overlay on top of bg
		var overlay := ColorRect.new()
		overlay.custom_minimum_size = Vector2(VIEWPORT_WIDTH, surface_height)
		overlay.size = Vector2(VIEWPORT_WIDTH, surface_height)
		overlay.color = Color(0.957, 0.91, 0.816, 0.3)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_surface.add_child(overlay)

	# Calculate node positions (bottom-up: row 0 at bottom, boss at top)
	var node_positions: Dictionary = {}  # "row_col" -> Vector2
	var available_nodes := GameState.get_available_nodes()

	# Create path drawer first (behind nodes)
	var drawer_script := preload("res://scripts/map/map_path_drawer.gd")
	_path_drawer = Control.new()
	_path_drawer.set_script(drawer_script)
	_path_drawer.custom_minimum_size = Vector2(VIEWPORT_WIDTH, surface_height)
	_path_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_surface.add_child(_path_drawer)

	# Instantiate map nodes
	for row_idx in range(nodes.size()):
		var row: Array = nodes[row_idx]
		for node_data in row:
			var row_num: int = node_data["row"]
			var col_num: int = node_data["col"]

			# Calculate position: bottom-up, centered in columns
			# Boss nodes are larger; account for that in centering
			var node_type: int = node_data.get("type", 0)
			var draw_size := 48.0 if node_type == 6 else NODE_SIZE
			var content_margin: float = (VIEWPORT_WIDTH - MAP_CONTENT_WIDTH) / 2.0
			var x: float = content_margin + (col_num + 1) * (MAP_CONTENT_WIDTH / (MAP_WIDTH + 1)) - draw_size / 2.0
			var y: float = (height - 1 - row_num) * ROW_HEIGHT + PADDING_TOP - draw_size / 2.0
			var center := Vector2(x + draw_size / 2.0, y + draw_size / 2.0)

			# Store center position for path drawing
			var key := "%d_%d" % [row_num, col_num]
			node_positions[key] = center

			# Check if this node was visited
			var is_node_visited := _is_node_visited(row_num, col_num)
			node_data["visited"] = is_node_visited

			# Instantiate visual node
			var map_node: Control = map_node_scene.instantiate()
			_map_surface.add_child(map_node)
			map_node.position = Vector2(x, y)
			map_node.setup(node_data)

			# Set availability
			var is_avail := _is_node_in_list(node_data, available_nodes)
			map_node.set_available(is_avail)

			# Connect click signal
			map_node.node_clicked.connect(_on_node_clicked)

	# Setup path drawer
	_path_drawer.setup(node_positions, paths, GameState.taken_paths)

	# Scroll to current position
	_scroll_to_current_floor(height)


func _scroll_to_current_floor(map_height: int) -> void:
	await get_tree().process_frame
	if not _scroll_container:
		return

	var surface_height: float = _map_surface.custom_minimum_size.y
	var viewport_height: float = _scroll_container.size.y

	if GameState.visited_nodes.is_empty():
		# Scroll to bottom (start nodes)
		_scroll_container.scroll_vertical = int(surface_height - viewport_height)
	else:
		# Scroll to current floor position
		var current_row: int = GameState.current_node.get("row", 0)
		var y_pos: float = (map_height - 1 - current_row) * ROW_HEIGHT + PADDING_TOP
		var target_scroll := int(y_pos - viewport_height / 2.0)
		target_scroll = clampi(target_scroll, 0, int(surface_height - viewport_height))
		_scroll_container.scroll_vertical = target_scroll


func _is_node_visited(row: int, col: int) -> bool:
	for v in GameState.visited_nodes:
		if v["row"] == row and v["col"] == col:
			return true
	return false


func _is_node_in_list(node: Dictionary, node_list: Array) -> bool:
	for n in node_list:
		if n["row"] == node["row"] and n["col"] == node["col"]:
			return true
	return false


func _on_node_clicked(node_data: Dictionary) -> void:
	GameState.select_map_node(node_data)
	SaveManager.save_run()

	var node_type: int = node_data.get("type", 0)
	match node_type:
		0, 1, 6:  # COMBAT, ELITE, BOSS
			SceneTransition.change_scene("res://scenes/combat.tscn")
		2:  # LIBRARY
			SceneTransition.change_scene("res://scenes/library.tscn")
		3:  # REST
			SceneTransition.change_scene("res://scenes/rest_site.tscn")
		4:  # SHOP
			SceneTransition.change_scene("res://scenes/shop.tscn")
		5:  # EVENT
			SceneTransition.change_scene("res://scenes/event.tscn")
		_:
			_show_placeholder(node_type)


func _show_placeholder(node_type: int) -> void:
	var type_name: String = NODE_TYPE_NAMES.get(node_type, "Неизвестно")
	if info_label:
		info_label.text = "%s — Скоро! Возврат на карту..." % type_name

	# Rebuild map to show updated state
	await get_tree().create_timer(1.5).timeout
	_clear_map()
	_build_map_display()
	if info_label:
		info_label.text = "Выберите узел для продолжения"


func _clear_map() -> void:
	if _scroll_container:
		_scroll_container.queue_free()
		_scroll_container = null
		_map_surface = null
		_path_drawer = null
