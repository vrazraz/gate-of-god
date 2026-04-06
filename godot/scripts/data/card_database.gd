extends Node
## Loads and provides access to card data from cards.json.

var _cards: Dictionary = {}  # card_id -> card_data
var _starting_deck: Array = []


func _ready() -> void:
	_load_cards()


func _load_cards() -> void:
	var file := FileAccess.open("res://data/cards.json", FileAccess.READ)
	if not file:
		push_error("[CardDatabase] Failed to load cards.json")
		return

	var json_string := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		push_error("[CardDatabase] Invalid cards.json format")
		return

	for card in data.get("cards", []):
		_cards[card["id"]] = card

	_starting_deck = data.get("starting_deck", [])
	print("[CardDatabase] Loaded %d cards" % _cards.size())


func get_card(card_id: String) -> Dictionary:
	return _cards.get(card_id, {})


func get_all_cards() -> Dictionary:
	return _cards


func get_cards_by_type(card_type: String) -> Array:
	var result: Array = []
	for card in _cards.values():
		if card.get("type", "") == card_type:
			result.append(card)
	return result


func get_cards_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for card in _cards.values():
		if card.get("rarity", "") == rarity:
			result.append(card)
	return result


func get_starting_deck() -> Array:
	return _starting_deck


func get_card_count() -> int:
	return _cards.size()
