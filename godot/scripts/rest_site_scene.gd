extends Control
## Rest Site scene controller. Offers Rest (heal) and Study (curse cleansing).

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var hp_label: Label = $VBoxContainer/HPLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var rest_button: Button = $VBoxContainer/OptionsPanel/RestButton
@onready var study_button: Button = $VBoxContainer/OptionsPanel/StudyButton
@onready var options_panel: VBoxContainer = $VBoxContainer/OptionsPanel
@onready var content_panel: PanelContainer = $VBoxContainer/ContentPanel
@onready var content_title: Label = $VBoxContainer/ContentPanel/ContentVBox/ContentTitle
@onready var curse_list: VBoxContainer = $VBoxContainer/ContentPanel/ContentVBox/CurseList
@onready var no_curses_label: Label = $VBoxContainer/ContentPanel/ContentVBox/NoCursesLabel
@onready var back_button: Button = $VBoxContainer/ContentPanel/ContentVBox/BackButton
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel

var challenge_popup_scene: PackedScene = preload("res://scenes/ui/challenge_popup.tscn")
var _challenge_popup: Control = null
var _pending_curse_id: String = ""
var _pending_challenge_type: String = "vocabulary"

const HEAL_PERCENT := 0.30


func _ready() -> void:
	rest_button.pressed.connect(_on_rest_pressed)
	study_button.pressed.connect(_on_study_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Style buttons (same pattern as main_menu.gd)
	_style_button(rest_button, Color("#2D5F3F"))
	_style_button(study_button, Color("#5A3E5C"))
	_style_button(back_button, Color("#5C4A3A"))

	# Setup challenge popup (same pattern as combat_scene.gd:40-43)
	_challenge_popup = challenge_popup_scene.instantiate()
	_challenge_popup.visible = false
	add_child(_challenge_popup)
	_challenge_popup.challenge_answered.connect(_on_challenge_answered)

	content_panel.visible = false
	feedback_label.text = ""

	var heal_amount := _calculate_heal_amount()
	rest_button.text = "ОТДЫХ  —  Лечение 30%% ОЗ (+%d ОЗ)" % heal_amount
	study_button.text = "УЧЁБА  —  Снять проклятие"

	_update_hp_display()


func _calculate_heal_amount() -> int:
	var raw := int(GameState.max_hp * HEAL_PERCENT)
	return mini(raw, GameState.max_hp - GameState.current_hp)


func _update_hp_display() -> void:
	hp_label.text = "ОЗ: %d / %d" % [GameState.current_hp, GameState.max_hp]
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.current_hp
	var ratio := float(GameState.current_hp) / float(GameState.max_hp) if GameState.max_hp > 0 else 0.0
	if ratio > 0.5:
		hp_bar.modulate = Color("#4CAF50")
	elif ratio > 0.25:
		hp_bar.modulate = Color("#FF9800")
	else:
		hp_bar.modulate = Color("#F44336")


# --- REST ---

func _on_rest_pressed() -> void:
	rest_button.disabled = true
	study_button.disabled = true

	var heal_amount := _calculate_heal_amount()
	GameState.heal(heal_amount)

	# Tween the HP bar
	var tween := create_tween()
	tween.tween_property(hp_bar, "value", float(GameState.current_hp), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_update_hp_display)

	_show_feedback("Восстановлено %d ОЗ!" % heal_amount, Color("#4CAF50"))

	await get_tree().create_timer(1.5).timeout
	_return_to_map()


# --- STUDY ---

func _on_study_pressed() -> void:
	options_panel.visible = false
	content_panel.visible = true

	var curses_in_deck: Array = GameState.get_curses_in_deck()

	# Clear previous curse entries
	for child in curse_list.get_children():
		child.queue_free()

	if curses_in_deck.is_empty():
		no_curses_label.visible = true
		no_curses_label.text = "Нет проклятий для снятия."
	else:
		no_curses_label.visible = false
		_populate_curse_list(curses_in_deck)


func _populate_curse_list(curse_ids: Array) -> void:
	var curse_data_map := _load_curse_data()

	for curse_id in curse_ids:
		var data: Dictionary = curse_data_map.get(curse_id, {})
		var curse_name: String = data.get("name", curse_id)
		var curse_desc: String = data.get("description", "")

		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", 4)

		var name_label := Label.new()
		name_label.text = curse_name
		name_label.add_theme_color_override("font_color", Color("#5A3E5C"))
		name_label.add_theme_font_size_override("font_size", 18)
		entry.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = curse_desc
		desc_label.add_theme_color_override("font_color", Color("#5C4A3A"))
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.add_child(desc_label)

		var cleanse_btn := Button.new()
		cleanse_btn.text = "Снять"
		cleanse_btn.custom_minimum_size = Vector2(120, 40)
		_style_button(cleanse_btn, Color("#5A3E5C"))
		cleanse_btn.pressed.connect(_on_cleanse_pressed.bind(curse_id))
		entry.add_child(cleanse_btn)

		var sep := HSeparator.new()
		entry.add_child(sep)

		curse_list.add_child(entry)


func _load_curse_data() -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open("res://data/curses.json", FileAccess.READ)
	if not file:
		return result
	var json_string := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(json_string)
	if data == null or not data is Dictionary:
		return result
	for curse in data.get("curses", []):
		result[curse["id"]] = curse
	return result


func _on_cleanse_pressed(curse_id: String) -> void:
	_pending_curse_id = curse_id

	# Disable all cleanse buttons to prevent double-click
	for child in curse_list.get_children():
		if child is VBoxContainer:
			for sub in child.get_children():
				if sub is Button:
					sub.disabled = true

	# Map curse purge requirement to challenge type
	var curse_data_map := _load_curse_data()
	var curse_data: Dictionary = curse_data_map.get(curse_id, {})
	var purge: Dictionary = curse_data.get("purge", {})
	_pending_challenge_type = "vocabulary"

	match purge.get("requirement", ""):
		"spell_correctly":
			_pending_challenge_type = "spelling"
		"correct_tense":
			_pending_challenge_type = "grammar"

	var request := {
		"player_id": GameState.player_id,
		"card_id": curse_id,
		"challenge_type": _pending_challenge_type,
		"difficulty": GameState.cefr_level,
	}

	ApiClient.generate_challenge(request, func(challenge_data: Dictionary) -> void:
		if _challenge_popup:
			_challenge_popup.show_challenge(challenge_data)
	)


func _on_challenge_answered(user_answer: String, correct_answer: String, time_taken: float) -> void:
	var validate_data := {
		"player_id": GameState.player_id,
		"challenge_type": _pending_challenge_type,
		"challenge_id": "cleanse_%s_%d" % [_pending_curse_id, randi()],
		"user_answer": user_answer,
		"correct_answer": correct_answer,
		"time_taken": time_taken,
		"word": _pending_curse_id,
		"card_id": _pending_curse_id,
	}

	ApiClient.validate_answer(validate_data, func(result: Dictionary) -> void:
		var correct: bool = result.get("correct", false)
		if correct:
			GameState.remove_curse(_pending_curse_id)
			_show_feedback("Проклятие снято!", Color("#4CAF50"))
		else:
			var correct_ans: String = result.get("feedback", {}).get("correct_answer", correct_answer)
			_show_feedback("Неверно! Ответ: %s" % correct_ans, Color("#F44336"))

		_pending_curse_id = ""

		await get_tree().create_timer(2.0).timeout
		_return_to_map()
	)


# --- BACK ---

func _on_back_pressed() -> void:
	content_panel.visible = false
	options_panel.visible = true


# --- Helpers ---

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.3)


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

	var pressed_style := style.duplicate()
	pressed_style.bg_color = color.darkened(0.05)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var text_color := Color("#F4E8D0")
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", Color(text_color, 0.5))
