extends Control
## Event scene controller. Loads a random event from events.json and presents choices.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var text_label: Label = $VBoxContainer/TextLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel

var challenge_popup_scene: PackedScene = preload("res://scenes/ui/challenge_popup.tscn")
var _challenge_popup: Control = null
var _current_event: Dictionary = {}
var _current_option: Dictionary = {}
var _option_processed: bool = false

const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_GOLD := Color("#D4AF37")
const COLOR_BLUE := Color("#2E5090")
const COLOR_EMERALD := Color("#2D5F3F")
const COLOR_CRIMSON := Color("#8B1E1E")
const COLOR_BROWN := Color("#5C4A3A")
const COLOR_PURPLE := Color("#5A3E5C")


func _ready() -> void:
	_challenge_popup = challenge_popup_scene.instantiate()
	_challenge_popup.visible = false
	add_child(_challenge_popup)
	_challenge_popup.challenge_answered.connect(_on_challenge_answered)

	result_label.text = ""
	_load_random_event()
	_display_event()


func _load_random_event() -> void:
	var file := FileAccess.open("res://data/events.json", FileAccess.READ)
	if not file:
		_current_event = _fallback_event()
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and data.has("events") and not data["events"].is_empty():
		var events: Array = data["events"].duplicate()
		events.shuffle()
		_current_event = events[0]
	else:
		_current_event = _fallback_event()


func _fallback_event() -> Dictionary:
	return {
		"name": "Таинственный путник",
		"text": "На обочине тропы сидит старик с книгой. «Ответь на мой вопрос — и получишь награду. Откажись — и ступай с миром.»",
		"options": [
			{
				"id": "test",
				"label": "Принять вызов",
				"challenge_type": "vocabulary",
				"success_rewards": {"coins": 30},
				"failure_penalty": {"damage": 8},
			},
			{
				"id": "leave",
				"label": "Пройти мимо",
				"rewards": {"heal": 5},
			},
		],
	}


func _display_event() -> void:
	title_label.text = _current_event.get("name", "Событие")
	text_label.text = _current_event.get("text", "")

	for child in options_container.get_children():
		child.queue_free()

	for option in _current_event.get("options", []):
		var btn := Button.new()
		var label_text: String = option.get("label", "...")

		if option.has("cost_coins"):
			label_text += "  (%d золота)" % option["cost_coins"]

		btn.text = label_text
		btn.custom_minimum_size = Vector2(450, 52)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_style_button(btn, _get_option_color(option))
		btn.pressed.connect(_on_option_pressed.bind(option))
		options_container.add_child(btn)

	# "Leave" / back button at bottom
	var back_btn := Button.new()
	back_btn.text = "Вернуться на карту"
	back_btn.custom_minimum_size = Vector2(300, 44)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(back_btn, COLOR_BROWN)
	back_btn.pressed.connect(_return_to_map)
	options_container.add_child(back_btn)


func _get_option_color(option: Dictionary) -> Color:
	if option.has("challenge_type"):
		return COLOR_CRIMSON
	if option.has("cost_coins"):
		return COLOR_GOLD.darkened(0.3)
	return COLOR_EMERALD


func _on_option_pressed(option: Dictionary) -> void:
	if _option_processed:
		return
	_option_processed = true
	_current_option = option
	_disable_all_buttons()

	# Challenge-based option
	if option.has("challenge_type"):
		_start_challenge(option)
		return

	# Gold cost option
	if option.has("cost_coins"):
		var cost: int = option["cost_coins"]
		if GameState.gold < cost:
			_show_result("Недостаточно золота!", COLOR_CRIMSON)
			_option_processed = false
			_re_enable_buttons()
			return
		GameState.spend_gold(cost)

		# Hidden curse chance
		var curse_chance: float = option.get("hidden_curse_chance", 0.0)
		if curse_chance > 0.0 and randf() < curse_chance:
			_apply_penalty({"add_curse": "echo_of_typo"})
			_show_result("Вы заплатили... но что-то пошло не так. Проклятие!", COLOR_PURPLE)
		else:
			_apply_rewards(option.get("rewards", {}))
		await get_tree().create_timer(2.0).timeout
		_return_to_map()
		return

	# Free option
	_apply_rewards(option.get("rewards", {}))
	await get_tree().create_timer(1.5).timeout
	_return_to_map()


# --- Challenge ---

func _start_challenge(option: Dictionary) -> void:
	var challenge_type: String = option.get("challenge_type", "vocabulary")
	# Normalize unknown types to vocabulary
	if challenge_type not in ["vocabulary", "grammar"]:
		challenge_type = "vocabulary"

	var request := {
		"player_id": GameState.player_id,
		"card_id": "event_%s" % _current_event.get("id", "unknown"),
		"challenge_type": challenge_type,
		"difficulty": GameState.cefr_level,
	}

	ApiClient.generate_challenge(request, func(challenge_data: Dictionary) -> void:
		if _challenge_popup:
			_challenge_popup.show_challenge(challenge_data)
	)


func _on_challenge_answered(user_answer: String, correct_answer: String, time_taken: float) -> void:
	var validate_data := {
		"player_id": GameState.player_id,
		"challenge_type": _current_option.get("challenge_type", "vocabulary"),
		"challenge_id": "event_%s_%d" % [_current_event.get("id", "unknown"), randi()],
		"user_answer": user_answer,
		"correct_answer": correct_answer,
		"time_taken": time_taken,
		"word": "event",
		"card_id": "event_%s" % _current_event.get("id", "unknown"),
	}

	ApiClient.validate_answer(validate_data, func(result: Dictionary) -> void:
		var correct: bool = result.get("correct", false)
		if correct:
			_apply_rewards(_current_option.get("success_rewards", {}))
			_show_result("Верно! Награда получена.", COLOR_EMERALD)
		else:
			_apply_penalty(_current_option.get("failure_penalty", {}))
			var correct_ans: String = result.get("feedback", {}).get("correct_answer", correct_answer)
			_show_result("Неверно! Ответ: %s" % correct_ans, COLOR_CRIMSON)

		await get_tree().create_timer(2.5).timeout
		_return_to_map()
	)


# --- Rewards / Penalties ---

func _apply_rewards(rewards: Dictionary) -> void:
	var messages: Array = []

	if rewards.has("coins"):
		var amount: int = rewards["coins"]
		GameState.gain_gold(amount)
		messages.append("+%d золота" % amount)

	if rewards.has("heal"):
		var amount: int = rewards["heal"]
		GameState.heal(amount)
		messages.append("+%d ОЗ" % amount)

	if rewards.has("remove_curse") and rewards["remove_curse"] > 0:
		var curses_in_deck := GameState.get_curses_in_deck()
		if not curses_in_deck.is_empty():
			GameState.remove_curse(curses_in_deck[0])
			messages.append("Проклятие снято!")

	if rewards.has("cards"):
		var card_count: int = rewards["cards"]
		var rarity: String = rewards.get("card_rarity", "common")
		var available := CardDatabase.get_cards_by_rarity(rarity)
		available.shuffle()
		var added: int = 0
		for card in available:
			if added >= card_count:
				break
			if card["id"] not in GameState.deck:
				GameState.deck.append(card["id"])
				added += 1
		if added > 0:
			messages.append("+%d карт" % added)

	if not messages.is_empty():
		_show_result(" | ".join(messages), COLOR_GOLD)


func _apply_penalty(penalty: Dictionary) -> void:
	if penalty.has("damage"):
		var amount: int = penalty["damage"]
		GameState.take_damage(amount)

	if penalty.has("add_curse"):
		var curse_id: String = penalty["add_curse"]
		# Only add known curses
		var known := GameState.get_curses_in_deck()
		if curse_id not in known:
			GameState.deck.append(curse_id)


# --- UI Helpers ---

func _disable_all_buttons() -> void:
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true


func _re_enable_buttons() -> void:
	for child in options_container.get_children():
		if child is Button:
			child.disabled = false


func _show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)
	result_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.3)


func _return_to_map() -> void:
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _style_button(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_s := style.duplicate()
	pressed_s.bg_color = color.darkened(0.05)
	btn.add_theme_stylebox_override("pressed", pressed_s)

	btn.add_theme_color_override("font_color", COLOR_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", COLOR_PARCHMENT)
	btn.add_theme_color_override("font_pressed_color", COLOR_PARCHMENT)
	btn.add_theme_color_override("font_disabled_color", Color(COLOR_PARCHMENT, 0.5))
