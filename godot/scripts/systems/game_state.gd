extends Node
## Global game state singleton (Autoload).
## Manages current run data, player info, and scene transitions.

signal hp_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)
signal gold_changed(amount: int)
signal run_started()
signal run_ended(victory: bool)
signal floor_changed(floor_number: int)

# Player persistent data
var player_id: String = ""
var player_name: String = "Player"
var cefr_level: String = "B1"
var insight_points: int = 0

# Current run data
var current_run: Dictionary = {}
var in_run: bool = false

# Combat state
var max_hp: int = 100
var current_hp: int = 100
var max_energy: int = 3
var current_energy: int = 3
var block: int = 0
var gold: int = 0

# Deck
var deck: Array = []  # Array of card_id strings
var relics: Array = []  # Array of relic_id strings
var curses: Array = []  # Array of curse data dicts
var card_removal_count: int = 0
var card_challenges: Dictionary = {}  # card_id -> fixed challenge data for the run

# Run progression
var current_floor: int = 0
var current_act: int = 1
var map_data: Dictionary = {}
var current_node: Dictionary = {}
var visited_nodes: Array = []
var taken_paths: Array = []

# Stats for current run
var run_stats: Dictionary = {
	"perfect_count": 0,
	"correct_count": 0,
	"mistake_count": 0,
	"enemies_killed": 0,
	"cards_played": 0,
}


func _ready() -> void:
	_load_or_create_player_id()


func _load_or_create_player_id() -> void:
	var config := ConfigFile.new()
	var path := "user://player_id.cfg"

	if config.load(path) == OK:
		player_id = config.get_value("player", "id", "")
		if player_id != "":
			return

	# Generate a new UUID-like ID
	player_id = _generate_uuid()
	config.set_value("player", "id", player_id)
	config.save(path)


func _generate_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hex_chars := "0123456789abcdef"
	var uuid := ""
	for i in range(32):
		uuid += hex_chars[rng.randi_range(0, 15)]
		if i in [7, 11, 15, 19]:
			uuid += "-"
	return uuid


func start_new_run() -> void:
	current_hp = max_hp
	current_energy = max_energy
	block = 0
	gold = 99
	current_floor = 0
	current_act = 1
	curses.clear()
	card_removal_count = 0
	card_challenges = {}
	map_data = {}
	current_node = {}
	visited_nodes.clear()
	taken_paths.clear()
	run_stats = {
		"perfect_count": 0,
		"correct_count": 0,
		"mistake_count": 0,
		"enemies_killed": 0,
		"cards_played": 0,
	}

	# Build starting deck from CardDatabase
	deck.clear()
	var starting := CardDatabase.get_starting_deck()
	for entry in starting:
		for i in range(entry["count"]):
			deck.append(entry["card_id"])

	relics.clear()
	in_run = true
	run_started.emit()


func take_damage(amount: int) -> void:
	var actual_damage: int = max(0, amount - block)
	block = max(0, block - amount) as int
	current_hp = max(0, current_hp - actual_damage) as int
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		end_run(false)


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)


func gain_block(amount: int) -> void:
	block += amount


func spend_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		energy_changed.emit(current_energy, max_energy)
		return true
	return false


func reset_energy() -> void:
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)


func reset_block() -> void:
	block = 0


func gain_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func advance_floor() -> void:
	current_floor += 1
	floor_changed.emit(current_floor)


func end_run(victory: bool) -> void:
	in_run = false
	run_ended.emit(victory)


func has_relic(relic_id: String) -> bool:
	return relic_id in relics


func add_relic(relic_id: String) -> void:
	if relic_id not in relics:
		relics.append(relic_id)


func get_curses_in_deck() -> Array:
	var known_curse_ids := _load_curse_ids()
	var result: Array = []
	for card_id in deck:
		if card_id in known_curse_ids and card_id not in result:
			result.append(card_id)
	return result


func _load_curse_ids() -> Array:
	var ids: Array = []
	var file := FileAccess.open("res://data/curses.json", FileAccess.READ)
	if not file:
		return ["echo_of_typo", "tense_fog"]  # fallback
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		for curse in data.get("curses", []):
			ids.append(curse["id"])
	return ids if not ids.is_empty() else ["echo_of_typo", "tense_fog"]


func remove_curse(curse_id: String) -> void:
	deck = deck.filter(func(id): return id != curse_id)
	curses = curses.filter(func(c):
		if c is String:
			return c != curse_id
		if c is Dictionary:
			return c.get("id", c.get("type", "")) != curse_id
		return true
	)


func select_map_node(node: Dictionary) -> void:
	if not current_node.is_empty():
		taken_paths.append({
			"from": {"row": current_node["row"], "col": current_node["col"]},
			"to": {"row": node["row"], "col": node["col"]},
		})
	current_node = node
	visited_nodes.append({"row": node["row"], "col": node["col"]})
	current_floor = node["row"]
	floor_changed.emit(current_floor)


func get_available_nodes() -> Array:
	if map_data.is_empty():
		return []
	var nodes: Array = map_data["nodes"]
	var paths: Array = map_data["paths"]
	if visited_nodes.is_empty():
		return nodes[0]
	var available: Array = []
	for path in paths:
		if path["from"]["row"] == current_node["row"] and path["from"]["col"] == current_node["col"]:
			var target_row: int = path["to"]["row"]
			var target_col: int = path["to"]["col"]
			for node in nodes[target_row]:
				if node["col"] == target_col:
					available.append(node)
	return available


func get_card_removal_cost() -> int:
	return 75 + card_removal_count * 25


func get_card_challenge(card_id: String) -> Dictionary:
	return card_challenges.get(card_id, {})


func set_card_challenge(card_id: String, challenge_data: Dictionary) -> void:
	card_challenges[card_id] = challenge_data


func remove_card_from_deck(card_id: String) -> void:
	var idx := deck.find(card_id)
	if idx >= 0:
		deck.remove_at(idx)
		card_removal_count += 1
