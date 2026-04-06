extends Node
## Manages saving and loading game state to local files.

const SAVE_PATH: String = "user://save_data.json"
const SETTINGS_PATH: String = "user://settings.json"


func save_run() -> void:
	var data := {
		"player_id": GameState.player_id,
		"current_hp": GameState.current_hp,
		"max_hp": GameState.max_hp,
		"gold": GameState.gold,
		"current_floor": GameState.current_floor,
		"current_act": GameState.current_act,
		"deck": GameState.deck,
		"relics": GameState.relics,
		"curses": GameState.curses,
		"card_removal_count": GameState.card_removal_count,
		"card_challenges": GameState.card_challenges,
		"run_stats": GameState.run_stats,
		"cefr_level": GameState.cefr_level,
		"map_data": GameState.map_data,
		"current_node": GameState.current_node,
		"visited_nodes": GameState.visited_nodes,
		"taken_paths": GameState.taken_paths,
		"timestamp": Time.get_datetime_string_from_system(),
	}

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Run saved successfully")
	else:
		push_error("[SaveManager] Failed to save run")


func load_run() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_string := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		return false

	GameState.player_id = data.get("player_id", GameState.player_id)
	GameState.current_hp = data.get("current_hp", 100)
	GameState.max_hp = data.get("max_hp", 100)
	GameState.gold = data.get("gold", 0)
	GameState.current_floor = data.get("current_floor", 0)
	GameState.current_act = data.get("current_act", 1)
	GameState.deck = data.get("deck", [])
	GameState.relics = data.get("relics", [])
	GameState.curses = data.get("curses", [])
	GameState.card_removal_count = data.get("card_removal_count", 0)
	GameState.card_challenges = data.get("card_challenges", {})
	GameState.run_stats = data.get("run_stats", {})
	GameState.cefr_level = data.get("cefr_level", "B1")
	GameState.map_data = data.get("map_data", {})
	GameState.current_node = data.get("current_node", {})
	GameState.visited_nodes = data.get("visited_nodes", [])
	GameState.taken_paths = data.get("taken_paths", [])
	GameState.in_run = true

	print("[SaveManager] Run loaded successfully")
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted")


func save_settings(settings_data: Dictionary) -> void:
	var json_string := JSON.stringify(settings_data, "\t")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()


func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return _default_settings()

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return _default_settings()

	var json_string := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		return _default_settings()

	return data


func _default_settings() -> Dictionary:
	return {
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"text_scale": 1.0,
		"dyslexic_font": false,
		"colorblind_mode": false,
		"screen_shake": true,
	}
