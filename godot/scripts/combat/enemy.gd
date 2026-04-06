extends Node
## Enemy instance during combat. Holds HP, pattern state, and intent display data.

signal hp_changed(current_hp: int, max_hp: int)
signal intent_changed(intent: Dictionary)
signal enemy_defeated()

var enemy_id: String = ""
var enemy_name: String = ""
var max_hp: int = 0
var current_hp: int = 0
var block: int = 0
var pattern: Array = []
var current_turn: int = 0
var debuffs: Dictionary = {}  # debuff_type -> {duration, value}
var buffs: Dictionary = {}    # buff_type -> {value}


func setup(data: Dictionary) -> void:
	enemy_id = data.get("id", "")
	enemy_name = data.get("name", "Неизвестный враг")
	max_hp = data.get("hp", 30)
	current_hp = max_hp
	block = 0
	pattern = data.get("ai_pattern", [])
	current_turn = 0
	debuffs.clear()
	buffs.clear()


func take_damage(amount: int) -> int:
	var actual_damage: int = max(0, amount - block)
	block = max(0, block - amount) as int
	current_hp = max(0, current_hp - actual_damage) as int
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		enemy_defeated.emit()

	return actual_damage


func gain_block(amount: int) -> void:
	block += amount


func reset_block() -> void:
	block = 0


func get_current_intent() -> Dictionary:
	if pattern.is_empty():
		return {"action": "attack", "value": 5, "intent": "attack"}
	var idx := current_turn % pattern.size()
	return pattern[idx]


func advance_turn() -> void:
	current_turn += 1
	# Tick down debuffs
	var expired: Array = []
	for debuff_type in debuffs:
		debuffs[debuff_type]["duration"] -= 1
		if debuffs[debuff_type]["duration"] <= 0:
			expired.append(debuff_type)
	for debuff_type in expired:
		debuffs.erase(debuff_type)

	intent_changed.emit(get_current_intent())


func apply_debuff(debuff_type: String, duration: int, value: int = 0) -> void:
	debuffs[debuff_type] = {"duration": duration, "value": value}


func has_debuff(debuff_type: String) -> bool:
	return debuff_type in debuffs


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)
