extends Control
## Library scene. Offers 3 free cards to choose from (or skip).

var card_scene: PackedScene = preload("res://scenes/ui/card.tscn")

const COLOR_GOLD := Color("#D4AF37")
const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_EMERALD := Color("#2D5F3F")

var _card_chosen: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Title
	var title: Label = $VBoxContainer/TitleLabel
	title.text = "БИБЛИОТЕКА"

	# Subtitle
	var subtitle: Label = $VBoxContainer/SubtitleLabel
	subtitle.text = "Выберите карту для добавления в колоду:"

	# Generate 3 card choices
	var cards_hbox: HBoxContainer = $VBoxContainer/CardsHBox
	var card_choices := _generate_card_choices()

	for card_data in card_choices:
		var card_container := VBoxContainer.new()
		card_container.alignment = BoxContainer.ALIGNMENT_CENTER
		card_container.add_theme_constant_override("separation", 8)

		# Wrap card in fixed-size holder
		var card_holder := Control.new()
		card_holder.custom_minimum_size = Vector2(140, 200)
		card_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_container.add_child(card_holder)

		var card_node: Control = card_scene.instantiate()
		card_holder.add_child(card_node)
		card_node.position = Vector2.ZERO
		card_node.size = Vector2(140, 200)
		# Defer setup until node is in tree (@onready vars need it)
		card_node.ready.connect(func():
			card_node.setup(card_data)
			card_node.set_playable(false)
			card_node.modulate.a = 1.0
			if card_node.has_node("CardPanel"):
				card_node.get_node("CardPanel").modulate.a = 1.0
		)

		# "Take" button below
		var btn := Button.new()
		btn.text = "Взять"
		btn.custom_minimum_size = Vector2(120, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_style_button(btn, COLOR_EMERALD)
		btn.pressed.connect(_on_card_chosen.bind(card_data))
		card_container.add_child(btn)

		cards_hbox.add_child(card_container)

	# Skip button
	var skip_btn: Button = $VBoxContainer/SkipButton
	_style_button(skip_btn, Color("#5C4A3A"))
	skip_btn.pressed.connect(_on_skip)


func _generate_card_choices() -> Array:
	var result: Array = []
	var all_cards: Array = []

	# Gather cards of various rarities
	for rarity in ["common", "uncommon"]:
		var cards_of_rarity: Array = CardDatabase.get_cards_by_rarity(rarity)
		var available := cards_of_rarity.filter(func(c):
			return c["id"] not in GameState.deck
		)
		if available.is_empty():
			available = cards_of_rarity
		all_cards.append_array(available)

	all_cards.shuffle()

	# Pick up to 3 unique cards
	var seen_ids: Dictionary = {}
	for card in all_cards:
		if card["id"] not in seen_ids:
			result.append(card)
			seen_ids[card["id"]] = true
		if result.size() >= 3:
			break

	# Fallback: fill with random commons
	if result.size() < 3:
		var commons := CardDatabase.get_cards_by_rarity("common")
		commons.shuffle()
		for card in commons:
			if card["id"] not in seen_ids:
				result.append(card)
				seen_ids[card["id"]] = true
			if result.size() >= 3:
				break

	return result


func _on_card_chosen(card_data: Dictionary) -> void:
	if _card_chosen:
		return
	_card_chosen = true
	GameState.deck.append(card_data["id"])
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _on_skip() -> void:
	if _card_chosen:
		return
	_card_chosen = true
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _style_button(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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
