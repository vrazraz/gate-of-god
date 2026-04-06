extends Node
## Loads and provides access to relic data from relics.json.

var _relics: Dictionary = {}  # relic_id -> relic_data


func _ready() -> void:
	_load_relics()


func _load_relics() -> void:
	var file := FileAccess.open("res://data/relics.json", FileAccess.READ)
	if not file:
		push_error("[RelicDatabase] Failed to load relics.json")
		return

	var json_string := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		push_error("[RelicDatabase] Invalid relics.json format")
		return

	for relic in data.get("relics", []):
		_relics[relic["id"]] = relic

	print("[RelicDatabase] Loaded %d relics" % _relics.size())


func get_relic(relic_id: String) -> Dictionary:
	return _relics.get(relic_id, {})


func get_all_relics() -> Dictionary:
	return _relics


func get_relics_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for relic in _relics.values():
		if relic.get("rarity", "") == rarity:
			result.append(relic)
	return result
