extends Node
## Manages the deck during combat: draw pile, hand, and discard pile.

signal hand_changed(hand: Array)
signal card_drawn(card_id: String)
signal card_discarded(card_id: String)
signal card_exhausted_on_draw(card_id: String)
signal deck_reshuffled()

var draw_pile: Array = []   # Array of card_id strings
var hand: Array = []        # Array of card_id strings
var discard_pile: Array = []  # Array of card_id strings
var exhaust_pile: Array = []  # Array of card_id strings

const MAX_HAND_SIZE: int = 10


func setup_deck(card_ids: Array) -> void:
	draw_pile = card_ids.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	_shuffle_draw_pile()


# Curse IDs that exhaust on draw
const EXHAUST_ON_DRAW := ["echo_of_typo"]

func draw_cards(count: int) -> void:
	for i in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			break
		if draw_pile.is_empty():
			_reshuffle_discard_into_draw()
		if draw_pile.is_empty():
			break
		var card_id: String = draw_pile.pop_back()
		# Echo of Typo: exhaust on draw instead of adding to hand
		if card_id in EXHAUST_ON_DRAW:
			exhaust_pile.append(card_id)
			card_exhausted_on_draw.emit(card_id)
			continue
		hand.append(card_id)
		card_drawn.emit(card_id)
	hand_changed.emit(hand)


func discard_card(card_id: String) -> void:
	var idx := hand.find(card_id)
	if idx >= 0:
		hand.remove_at(idx)
		discard_pile.append(card_id)
		card_discarded.emit(card_id)
		hand_changed.emit(hand)


func discard_hand() -> void:
	for card_id in hand:
		discard_pile.append(card_id)
		card_discarded.emit(card_id)
	hand.clear()
	hand_changed.emit(hand)


func exhaust_card(card_id: String) -> void:
	var idx := hand.find(card_id)
	if idx >= 0:
		hand.remove_at(idx)
		exhaust_pile.append(card_id)
		hand_changed.emit(hand)


func _shuffle_draw_pile() -> void:
	draw_pile.shuffle()


func _reshuffle_discard_into_draw() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	_shuffle_draw_pile()
	deck_reshuffled.emit()


func get_draw_pile_count() -> int:
	return draw_pile.size()


func get_discard_pile_count() -> int:
	return discard_pile.size()


func get_hand() -> Array:
	return hand


func get_hand_size() -> int:
	return hand.size()
