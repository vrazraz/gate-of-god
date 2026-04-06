extends Control
## Shop scene controller ("The Tutor's Academy").
## Offers cards for purchase, relics, and card removal service.

@onready var title_label: Label = $ScrollContainer/MainVBox/HeaderHBox/TitleLabel
@onready var gold_label: Label = $ScrollContainer/MainVBox/HeaderHBox/GoldLabel
@onready var cards_grid: HBoxContainer = $ScrollContainer/MainVBox/CardsGrid
@onready var relics_grid: HBoxContainer = $ScrollContainer/MainVBox/RelicsGrid
@onready var remove_card_button: Button = $ScrollContainer/MainVBox/ServicesHBox/RemoveCardButton
@onready var feedback_label: Label = $ScrollContainer/MainVBox/FeedbackLabel
@onready var leave_button: Button = $ScrollContainer/MainVBox/LeaveButton
@onready var removal_panel: PanelContainer = $RemovalPanel
@onready var removal_list: VBoxContainer = $RemovalPanel/RemovalVBox/RemovalScroll/RemovalList
@onready var removal_back_button: Button = $RemovalPanel/RemovalVBox/RemovalBackButton
@onready var scroll_container: ScrollContainer = $ScrollContainer

var _card_inventory: Array = []
var _relic_inventory: Array = []
var _sold_cards: Array = []
var _sold_relics: Array = []

const COLOR_GOLD := Color("#D4AF37")
const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_INK := Color("#1A1A1A")
const COLOR_CRIMSON := Color("#8B1E1E")
const COLOR_BLUE := Color("#2E5090")
const COLOR_EMERALD := Color("#2D5F3F")
const COLOR_PURPLE := Color("#5A3E5C")
const COLOR_RED := Color("#F44336")
const COLOR_GRAY := Color("#666666")


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)
	remove_card_button.pressed.connect(_on_remove_card_pressed)
	removal_back_button.pressed.connect(_on_removal_back_pressed)

	_style_button(leave_button, COLOR_GOLD)
	_style_button(remove_card_button, COLOR_PURPLE)
	_style_button(removal_back_button, Color("#5C4A3A"))

	# Style removal panel background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.102, 0.102, 0.102, 0.95)
	panel_style.content_margin_left = 40
	panel_style.content_margin_right = 40
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	removal_panel.add_theme_stylebox_override("panel", panel_style)

	removal_panel.visible = false

	_generate_inventory()
	_update_gold_display()
	_update_remove_button()
	_populate_cards()
	_populate_relics()

	GameState.gold_changed.connect(_on_gold_changed)


# --- Inventory Generation ---

func _generate_inventory() -> void:
	_card_inventory = _generate_card_inventory()
	_relic_inventory = _generate_relic_inventory()


func _generate_card_inventory() -> Array:
	var all_cards: Array = CardDatabase.get_all_cards().values()
	var deck_ids: Array = GameState.deck
	# Filter out cards already in deck (by unique presence) and starter cards
	var available: Array = all_cards.filter(func(c):
		return c["id"] not in deck_ids
	)
	available.shuffle()
	return available.slice(0, mini(5, available.size()))


func _generate_relic_inventory() -> Array:
	var all_relics: Array = RelicDatabase.get_all_relics().values()
	var available: Array = all_relics.filter(func(r):
		return not GameState.has_relic(r["id"]) and r.get("rarity", "") != "boss"
	)
	available.shuffle()
	return available.slice(0, mini(2, available.size()))


# --- Display ---

func _update_gold_display() -> void:
	gold_label.text = "%d лекс-монет" % GameState.gold


func _update_remove_button() -> void:
	var cost := GameState.get_card_removal_cost()
	remove_card_button.text = "Удалить карту  —  %d лекс-монет" % cost
	remove_card_button.disabled = GameState.gold < cost


func _populate_cards() -> void:
	for child in cards_grid.get_children():
		child.queue_free()

	for card_data in _card_inventory:
		var card_id: String = card_data["id"]
		var is_sold: bool = card_id in _sold_cards
		var item := _create_card_item(card_data, is_sold)
		cards_grid.add_child(item)


func _populate_relics() -> void:
	for child in relics_grid.get_children():
		child.queue_free()

	for relic_data in _relic_inventory:
		var relic_id: String = relic_data["id"]
		var is_sold: bool = relic_id in _sold_relics
		var item := _create_relic_item(relic_data, is_sold)
		relics_grid.add_child(item)


func _create_card_item(card_data: Dictionary, is_sold: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 220)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10

	# Border color by card type
	var card_type: String = card_data.get("type", "attack")
	var border_color := COLOR_CRIMSON if card_type == "attack" else COLOR_BLUE
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = border_color if not is_sold else COLOR_GRAY

	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Energy cost + type
	var cost_label := Label.new()
	var energy_cost: int = card_data.get("cost", 1)
	var type_names := {"attack": "АТАКА", "skill": "УМЕНИЕ", "power": "СИЛА", "curse": "ПРОКЛЯТИЕ"}
	cost_label.text = "%d E  |  %s" % [energy_cost, type_names.get(card_type, card_type.to_upper())]
	cost_label.add_theme_color_override("font_color", COLOR_GRAY if is_sold else border_color)
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)

	# Card name
	var name_label := Label.new()
	name_label.text = card_data.get("name", "Неизвестно")
	name_label.add_theme_color_override("font_color", COLOR_GRAY if is_sold else COLOR_PARCHMENT)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Rarity
	var rarity_label := Label.new()
	var rarity: String = card_data.get("rarity", "common")
	var rarity_names := {"common": "Обычная", "uncommon": "Необычная", "rare": "Редкая"}
	rarity_label.text = rarity_names.get(rarity, rarity.capitalize())
	rarity_label.add_theme_color_override("font_color", COLOR_GOLD if rarity == "uncommon" else COLOR_GRAY)
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = card_data.get("description", "")
	desc_label.add_theme_color_override("font_color", COLOR_GRAY)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(140, 40)
	vbox.add_child(desc_label)

	# Spacer to push price+button to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	if is_sold:
		var sold_label := Label.new()
		sold_label.text = "ПРОДАНО"
		sold_label.add_theme_color_override("font_color", COLOR_GRAY)
		sold_label.add_theme_font_size_override("font_size", 18)
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sold_label)
	else:
		# Price
		var price: int = card_data.get("price", 75)
		var can_afford: bool = GameState.gold >= price
		var price_label := Label.new()
		price_label.text = "%d лекс-монет" % price
		price_label.add_theme_color_override("font_color", COLOR_GOLD if can_afford else COLOR_RED)
		price_label.add_theme_font_size_override("font_size", 14)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(price_label)

		# Buy button
		var buy_btn := Button.new()
		buy_btn.text = "Купить"
		buy_btn.custom_minimum_size = Vector2(100, 36)
		buy_btn.disabled = not can_afford
		_style_button(buy_btn, COLOR_EMERALD if can_afford else COLOR_GRAY)
		buy_btn.pressed.connect(_on_buy_card.bind(card_data["id"], price))
		vbox.add_child(buy_btn)

	panel.add_child(vbox)
	return panel


func _create_relic_item(relic_data: Dictionary, is_sold: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 180)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = COLOR_GOLD if not is_sold else COLOR_GRAY
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Relic name
	var name_label := Label.new()
	name_label.text = relic_data.get("name", "Неизвестно")
	name_label.add_theme_color_override("font_color", COLOR_GRAY if is_sold else COLOR_GOLD)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Rarity
	var rarity_label := Label.new()
	rarity_label.text = relic_data.get("rarity", "common").capitalize()
	rarity_label.add_theme_color_override("font_color", COLOR_GRAY)
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = relic_data.get("description", "")
	desc_label.add_theme_color_override("font_color", Color("#AAAAAA") if not is_sold else COLOR_GRAY)
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(176, 40)
	vbox.add_child(desc_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	if is_sold:
		var sold_label := Label.new()
		sold_label.text = "ПРОДАНО"
		sold_label.add_theme_color_override("font_color", COLOR_GRAY)
		sold_label.add_theme_font_size_override("font_size", 18)
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sold_label)
	else:
		var price: int = relic_data.get("price", 200)
		var can_afford: bool = GameState.gold >= price
		var price_label := Label.new()
		price_label.text = "%d лекс-монет" % price
		price_label.add_theme_color_override("font_color", COLOR_GOLD if can_afford else COLOR_RED)
		price_label.add_theme_font_size_override("font_size", 14)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(price_label)

		var buy_btn := Button.new()
		buy_btn.text = "Купить"
		buy_btn.custom_minimum_size = Vector2(100, 36)
		buy_btn.disabled = not can_afford
		_style_button(buy_btn, COLOR_EMERALD if can_afford else COLOR_GRAY)
		buy_btn.pressed.connect(_on_buy_relic.bind(relic_data["id"], price))
		vbox.add_child(buy_btn)

	panel.add_child(vbox)
	return panel


# --- Buy Actions ---

func _on_buy_card(card_id: String, price: int) -> void:
	if not GameState.spend_gold(price):
		_show_feedback("Недостаточно лекс-монет!", COLOR_RED)
		return

	GameState.deck.append(card_id)
	_sold_cards.append(card_id)

	var card_data := CardDatabase.get_card(card_id)
	var card_name: String = card_data.get("name", card_id)
	_show_feedback("Куплено: %s!" % card_name, COLOR_EMERALD)

	_refresh_shop()


func _on_buy_relic(relic_id: String, price: int) -> void:
	if not GameState.spend_gold(price):
		_show_feedback("Недостаточно лекс-монет!", COLOR_RED)
		return

	GameState.add_relic(relic_id)
	_sold_relics.append(relic_id)

	var relic_data := RelicDatabase.get_relic(relic_id)
	var relic_name: String = relic_data.get("name", relic_id)
	_show_feedback("Получено: %s!" % relic_name, COLOR_GOLD)

	_refresh_shop()


# --- Card Removal ---

func _on_remove_card_pressed() -> void:
	scroll_container.visible = false
	removal_panel.visible = true
	_populate_removal_list()


func _on_removal_back_pressed() -> void:
	removal_panel.visible = false
	scroll_container.visible = true


func _populate_removal_list() -> void:
	for child in removal_list.get_children():
		child.queue_free()

	for card_id in GameState.deck:
		var card_data := CardDatabase.get_card(card_id)
		if card_data.is_empty():
			continue

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var card_type: String = card_data.get("type", "attack")
		var type_color := COLOR_CRIMSON if card_type == "attack" else COLOR_BLUE

		var name_label := Label.new()
		name_label.text = card_data.get("name", card_id)
		name_label.add_theme_color_override("font_color", type_color)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = card_data.get("description", "")
		desc_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc_label)

		var remove_btn := Button.new()
		remove_btn.text = "Удалить"
		remove_btn.custom_minimum_size = Vector2(100, 36)
		_style_button(remove_btn, COLOR_CRIMSON)
		remove_btn.pressed.connect(_on_confirm_remove.bind(card_id))
		hbox.add_child(remove_btn)

		removal_list.add_child(hbox)


func _on_confirm_remove(card_id: String) -> void:
	var cost := GameState.get_card_removal_cost()
	if not GameState.spend_gold(cost):
		_show_feedback("Недостаточно лекс-монет!", COLOR_RED)
		return

	var card_data := CardDatabase.get_card(card_id)
	var card_name: String = card_data.get("name", card_id)

	GameState.remove_card_from_deck(card_id)
	_show_feedback("Удалено из колоды: %s!" % card_name, COLOR_CRIMSON)

	# Return to shop view
	removal_panel.visible = false
	scroll_container.visible = true
	_refresh_shop()


# --- Refresh ---

func _refresh_shop() -> void:
	_update_gold_display()
	_update_remove_button()
	_populate_cards()
	_populate_relics()


func _on_gold_changed(_amount: int) -> void:
	_update_gold_display()
	_update_remove_button()


# --- Leave ---

func _on_leave_pressed() -> void:
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


# --- Helpers ---

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.3)


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

	var disabled_style := style.duplicate()
	disabled_style.bg_color = COLOR_GRAY
	btn.add_theme_stylebox_override("disabled", disabled_style)

	var text_color := Color("#F4E8D0")
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", Color(text_color, 0.5))
