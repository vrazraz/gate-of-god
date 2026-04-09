extends Node
## Loads and provides access to enemy data from enemies.json.

var _enemies: Dictionary = {}  # enemy_id -> enemy_data
var _boss: Dictionary = {}


func _ready() -> void:
	_load_enemies()


func _load_enemies() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if not file:
		push_error("[EnemyDatabase] Failed to load enemies.json")
		return

	var json_string := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		push_error("[EnemyDatabase] Invalid enemies.json format")
		return

	for enemy in data.get("enemies", []):
		_enemies[enemy["id"]] = enemy

	_boss = data.get("boss", {})
	print("[EnemyDatabase] Loaded %d enemies + 1 boss" % _enemies.size())


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})


func get_all_enemies() -> Dictionary:
	return _enemies


func get_random_enemy() -> Dictionary:
	# Regular (non-elite) enemies only.
	var pool: Array = []
	for enemy in _enemies.values():
		if not enemy.get("is_elite", false):
			pool.append(enemy)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


func get_random_elite_enemy() -> Dictionary:
	var pool: Array = []
	for enemy in _enemies.values():
		if enemy.get("is_elite", false):
			pool.append(enemy)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]


func get_boss() -> Dictionary:
	return _boss
