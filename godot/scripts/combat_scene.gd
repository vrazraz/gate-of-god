extends Control
## Combat scene controller. Wires up CombatManager, DeckManager, HUD, PlayerArea, and ChallengePopup.

@onready var combat_manager: Node = $CombatManager
@onready var deck_manager: Node = $DeckManager
@onready var hand_area: HBoxContainer = $HandArea
@onready var enemy_area: Control = $EnemyArea
@onready var player_area: Control = $PlayerArea
@onready var hud: Control = $HUD
@onready var feedback_label: Label = $FeedbackLabel

var card_scene: PackedScene = preload("res://scenes/ui/card.tscn")
var enemy_display_scene: PackedScene = preload("res://scenes/ui/enemy_display.tscn")
var challenge_popup_scene: PackedScene = preload("res://scenes/ui/challenge_popup.tscn")
var tutorial_overlay_scene: PackedScene = preload("res://scenes/ui/tutorial_overlay.tscn")

var _enemy_display: Control = null
var _challenge_popup: Control = null
var _tutorial_overlay = null
var _phase_label: Label = null
var _reward_panel: Control = null
var _reward_card_chosen: bool = false
var _first_challenge_shown: bool = false
var _first_enemy_turn_shown: bool = false

# Player area UI references
var _player_avatar_frame: Control = null
var _hp_bar_fill: ColorRect = null
var _hp_bar_height: float = 190.0
var _player_hp_label: Label = null
var _block_bar_fill: ColorRect = null
var _block_column: Control = null
var _player_block_label: Label = null
var _player_gold_label: Label = null
var _player_status_container: HBoxContainer = null

# Drag & drop
var _drop_zone: ColorRect = null

# Visual deck/discard piles
var _deck_pile_visual: Control = null
var _discard_pile_visual: Control = null
var _deck_count_label: Label = null
var _discard_count_label: Label = null

# Colors
const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_GOLD := Color("#D4AF37")
const COLOR_INK := Color("#1A1A1A")
const COLOR_CRIMSON := Color("#8B1E1E")
const COLOR_BLUE := Color("#2E5090")
const COLOR_EMERALD := Color("#2D5F3F")
const COLOR_HP_HIGH := Color("#4CAF50")
const COLOR_HP_MID := Color("#FF9800")
const COLOR_HP_LOW := Color("#F44336")


func _ready() -> void:
	# Setup deck
	deck_manager.setup_deck(GameState.deck)
	deck_manager.hand_changed.connect(_on_hand_changed)

	# Connect HUD
	if hud:
		hud.end_turn_pressed.connect(_on_end_turn)

	# Connect combat manager signals
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.challenge_requested.connect(_on_challenge_requested)
	combat_manager.challenge_resolved.connect(_on_challenge_resolved)
	combat_manager.enemy_action.connect(_on_enemy_action)
	combat_manager.boss_phase_changed.connect(_on_boss_phase_changed)
	combat_manager.great_exam_triggered.connect(_on_great_exam_triggered)
	combat_manager.great_exam_resolved.connect(_on_great_exam_resolved)
	combat_manager.fatigue_changed.connect(_on_fatigue_changed)

	# Create challenge popup
	_challenge_popup = challenge_popup_scene.instantiate()
	_challenge_popup.visible = false
	add_child(_challenge_popup)
	_challenge_popup.challenge_answered.connect(_on_challenge_answered)
	_challenge_popup.matching_completed.connect(_on_matching_completed)

	# Build player area
	_build_player_area()
	GameState.hp_changed.connect(_update_player_hp)
	GameState.gold_changed.connect(_update_player_gold)

	# Create drop zone indicator
	_create_drop_zone()

	# Build visual deck/discard piles
	_build_deck_piles()
	deck_manager.card_drawn.connect(_on_card_drawn_anim)
	deck_manager.card_discarded.connect(_on_card_discarded_anim)

	# Select enemy based on map node type
	var enemy_data: Dictionary
	var node_type: int = GameState.current_node.get("type", 0)
	if node_type == 6:  # BOSS
		enemy_data = EnemyDatabase.get_boss()
	else:
		enemy_data = EnemyDatabase.get_random_enemy()
	if enemy_data.is_empty():
		enemy_data = {"id": "whisper", "name": "Шёпот", "hp": 25, "ai_pattern": [{"turn": 1, "action": "attack", "value": 5}]}

	_spawn_enemy_display(enemy_data)

	# Create boss phase label if this is a boss fight
	if enemy_data.has("ultimate"):
		_create_phase_label()

	# Setup tutorial overlay
	if TutorialManager.is_active():
		_tutorial_overlay = tutorial_overlay_scene.instantiate()
		add_child(_tutorial_overlay)

	combat_manager.start_combat(enemy_data)


# --- Player Area ---

func _build_player_area() -> void:
	if not player_area:
		return

	var hbox := HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	player_area.add_child(hbox)

	# Hero portrait — no background panel, 210x210 (150% of 140)
	var portrait_container := Control.new()
	portrait_container.custom_minimum_size = Vector2(210, 210)
	portrait_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(portrait_container)
	_player_avatar_frame = portrait_container

	if ResourceLoader.exists("res://assets/sprites/ui/hero_portrait.png"):
		var hero_tex := TextureRect.new()
		hero_tex.texture = load("res://assets/sprites/ui/hero_portrait.png")
		hero_tex.anchors_preset = Control.PRESET_FULL_RECT
		hero_tex.anchor_right = 1.0
		hero_tex.anchor_bottom = 1.0
		hero_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hero_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_container.add_child(hero_tex)

	# --- HP vertical bar ---
	var hp_col := VBoxContainer.new()
	hp_col.add_theme_constant_override("separation", 2)
	hbox.add_child(hp_col)

	var hp_bar_container := Control.new()
	hp_bar_container.custom_minimum_size = Vector2(16, _hp_bar_height)
	hp_col.add_child(hp_bar_container)

	var hp_bg := ColorRect.new()
	hp_bg.color = Color("#1A1410")
	hp_bg.anchors_preset = Control.PRESET_FULL_RECT
	hp_bg.anchor_right = 1.0
	hp_bg.anchor_bottom = 1.0
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_container.add_child(hp_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.color = COLOR_HP_HIGH
	_hp_bar_fill.anchor_left = 0.0
	_hp_bar_fill.anchor_right = 1.0
	_hp_bar_fill.anchor_top = 1.0
	_hp_bar_fill.anchor_bottom = 1.0
	_hp_bar_fill.offset_top = -_hp_bar_height
	_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_container.add_child(_hp_bar_fill)

	_player_hp_label = Label.new()
	_player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_hp_label.add_theme_color_override("font_color", COLOR_PARCHMENT)
	_player_hp_label.add_theme_font_size_override("font_size", 11)
	_player_hp_label.custom_minimum_size = Vector2(16, 0)
	hp_col.add_child(_player_hp_label)

	# --- Block vertical bar (hidden by default) ---
	_block_column = VBoxContainer.new()
	_block_column.add_theme_constant_override("separation", 2)
	_block_column.visible = false
	hbox.add_child(_block_column)

	var block_bar_container := Control.new()
	block_bar_container.custom_minimum_size = Vector2(16, _hp_bar_height)
	_block_column.add_child(block_bar_container)

	var block_bg := ColorRect.new()
	block_bg.color = Color("#1A1410")
	block_bg.anchors_preset = Control.PRESET_FULL_RECT
	block_bg.anchor_right = 1.0
	block_bg.anchor_bottom = 1.0
	block_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_bar_container.add_child(block_bg)

	_block_bar_fill = ColorRect.new()
	_block_bar_fill.color = COLOR_BLUE
	_block_bar_fill.anchor_left = 0.0
	_block_bar_fill.anchor_right = 1.0
	_block_bar_fill.anchor_top = 1.0
	_block_bar_fill.anchor_bottom = 1.0
	_block_bar_fill.offset_top = 0
	_block_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_bar_container.add_child(_block_bar_fill)

	_player_block_label = Label.new()
	_player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_block_label.add_theme_color_override("font_color", COLOR_PARCHMENT)
	_player_block_label.add_theme_font_size_override("font_size", 11)
	_player_block_label.custom_minimum_size = Vector2(16, 0)
	_block_column.add_child(_player_block_label)

	# --- Gold label in top-left corner (separate from player area) ---
	_player_gold_label = Label.new()
	_player_gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	_player_gold_label.add_theme_font_size_override("font_size", 16)
	_player_gold_label.position = Vector2(16, 12)
	_player_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_gold_label)

	# Player status effect icons (above portrait)
	_player_status_container = HBoxContainer.new()
	_player_status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_status_container.add_theme_constant_override("separation", 6)
	_player_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_status_container.position = Vector2(0, -34)
	_player_status_container.custom_minimum_size = Vector2(210, 30)
	portrait_container.add_child(_player_status_container)

	# Initialize display
	_update_player_hp(GameState.current_hp, GameState.max_hp)
	_update_player_gold(GameState.gold)
	_update_player_block()


func _update_player_hp(current: int, maximum: int) -> void:
	var ratio := float(current) / float(maximum) if maximum > 0 else 0.0
	if _hp_bar_fill:
		_hp_bar_fill.offset_top = -_hp_bar_height * ratio
		if ratio > 0.5:
			_hp_bar_fill.color = COLOR_HP_HIGH
		elif ratio > 0.25:
			_hp_bar_fill.color = COLOR_HP_MID
		else:
			_hp_bar_fill.color = COLOR_HP_LOW
	if _player_hp_label:
		_player_hp_label.text = "%d/%d" % [current, maximum]


func _update_player_gold(amount: int) -> void:
	if _player_gold_label:
		_player_gold_label.text = "Золото: %d" % amount


func _update_player_block() -> void:
	var block: int = GameState.block
	if _block_column:
		_block_column.visible = block > 0
	if _block_bar_fill and block > 0:
		var ratio := clampf(float(block) / float(GameState.max_hp), 0.0, 1.0)
		_block_bar_fill.offset_top = -_hp_bar_height * ratio
	if _player_block_label:
		_player_block_label.text = str(block)


func _update_status_effects() -> void:
	# --- Player debuffs ---
	if _player_status_container:
		for child in _player_status_container.get_children():
			child.queue_free()

		if GameState.has_meta("debuff_confusion"):
			var dur: int = GameState.get_meta("debuff_confusion")
			_player_status_container.add_child(_create_status_badge(
				"res://assets/sprites/ui/status/confusion.png",
				str(dur), "Путаница: буквы перемешаны (%d ход.)" % dur
			))
		if GameState.has_meta("debuff_silence"):
			var dur: int = GameState.get_meta("debuff_silence")
			_player_status_container.add_child(_create_status_badge(
				"res://assets/sprites/ui/status/silence.png",
				str(dur), "Тишина: подсказки отключены (%d ход.)" % dur
			))
		if GameState.has_meta("debuff_reverse"):
			var dur: int = GameState.get_meta("debuff_reverse")
			_player_status_container.add_child(_create_status_badge(
				"res://assets/sprites/ui/status/reverse.png",
				str(dur), "Обратный перевод: переводите с РУ на EN (%d ход.)" % dur
			))

		# Fatigue stacks (slow answers reduce next turn draw)
		if combat_manager.fatigue > 0:
			var draw_next: int = maxi(combat_manager.MIN_DRAW_COUNT, combat_manager.BASE_DRAW_COUNT - combat_manager.fatigue)
			_player_status_container.add_child(_create_status_badge(
				"res://assets/sprites/ui/status/silence.png",
				str(combat_manager.fatigue),
				"Усталость ×%d: следующий ход — %d карт (вместо %d)" % [combat_manager.fatigue, draw_next, combat_manager.BASE_DRAW_COUNT]
			))

	# --- Enemy buffs ---
	if _enemy_display and _enemy_display.has_method("update_status_effects"):
		_enemy_display.update_status_effects(
			combat_manager.enemy_strength,
			combat_manager.enemy_block
		)


func _create_status_badge(icon_path: String, value: String, tip: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 2)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.tooltip_text = tip

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	hbox.add_child(icon)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_color_override("font_color", Color("#F4E8D0"))
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_bold = load("res://assets/fonts/Merriweather-Bold.ttf")
	if font_bold:
		val_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(val_lbl)

	return hbox


# --- Drop Zone ---

func _create_drop_zone() -> void:
	_drop_zone = ColorRect.new()
	_drop_zone.color = Color(0.18, 0.37, 0.25, 0.12)
	_drop_zone.anchors_preset = Control.PRESET_TOP_WIDE
	_drop_zone.anchor_right = 1.0
	_drop_zone.offset_bottom = 430.0
	_drop_zone.visible = false
	_drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drop_zone)


# --- Visual Deck / Discard Piles ---

func _build_deck_piles() -> void:
	# Deck pile: bottom-right of screen, to the right of hand
	_deck_pile_visual = Control.new()
	_deck_pile_visual.position = Vector2(1160, 530)
	_deck_pile_visual.size = Vector2(80, 110)
	_deck_pile_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_pile_visual)

	# Stack of 3 card backs using generated card_back.png
	var card_back_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/sprites/ui/card_back.png"):
		card_back_tex = load("res://assets/sprites/ui/card_back.png")

	for i in range(3):
		# Clipping container to prevent overflow
		var clip := Control.new()
		clip.clip_contents = true
		clip.position = Vector2(i * 3, i * 2)
		clip.size = Vector2(60, 85)
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_pile_visual.add_child(clip)

		if card_back_tex:
			var card_back := TextureRect.new()
			card_back.texture = card_back_tex
			card_back.anchors_preset = Control.PRESET_FULL_RECT
			card_back.anchor_right = 1.0
			card_back.anchor_bottom = 1.0
			card_back.offset_left = 0
			card_back.offset_top = 0
			card_back.offset_right = 0
			card_back.offset_bottom = 0
			card_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card_back.stretch_mode = TextureRect.STRETCH_SCALE
			card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			clip.add_child(card_back)
		else:
			var card_back := Panel.new()
			card_back.size = Vector2(60, 85)
			card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#2A1E14")
			style.border_color = Color("#D4AF37")
			style.set_border_width_all(1)
			style.set_corner_radius_all(4)
			card_back.add_theme_stylebox_override("panel", style)
			clip.add_child(card_back)

		# Gold border overlay
		var border := Panel.new()
		border.size = Vector2(60, 85)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var border_style := StyleBoxFlat.new()
		border_style.bg_color = Color(0, 0, 0, 0)
		border_style.border_color = Color("#D4AF37")
		border_style.set_border_width_all(1)
		border_style.set_corner_radius_all(4)
		border.add_theme_stylebox_override("panel", border_style)
		clip.add_child(border)

	# Deck count label
	_deck_count_label = Label.new()
	_deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_count_label.position = Vector2(0, 90)
	_deck_count_label.size = Vector2(70, 20)
	_deck_count_label.add_theme_color_override("font_color", COLOR_PARCHMENT)
	_deck_count_label.add_theme_font_size_override("font_size", 12)
	_deck_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_pile_visual.add_child(_deck_count_label)

	# Discard pile: above the deck pile
	_discard_pile_visual = Control.new()
	_discard_pile_visual.position = Vector2(1160, 410)
	_discard_pile_visual.size = Vector2(80, 110)
	_discard_pile_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_discard_pile_visual)

	# Single faded card outline for discard
	var discard_card := Panel.new()
	discard_card.custom_minimum_size = Vector2(60, 85)
	discard_card.size = Vector2(60, 85)
	discard_card.modulate.a = 0.5
	discard_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var discard_style := StyleBoxFlat.new()
	discard_style.bg_color = Color("#1A1410", 0.3)
	discard_style.border_color = Color("#8B6A4E", 0.5)
	discard_style.border_width_top = 1
	discard_style.border_width_bottom = 1
	discard_style.border_width_left = 1
	discard_style.border_width_right = 1
	discard_style.corner_radius_top_left = 4
	discard_style.corner_radius_top_right = 4
	discard_style.corner_radius_bottom_left = 4
	discard_style.corner_radius_bottom_right = 4
	discard_card.add_theme_stylebox_override("panel", discard_style)
	_discard_pile_visual.add_child(discard_card)

	# Discard count label
	_discard_count_label = Label.new()
	_discard_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_discard_count_label.position = Vector2(0, 90)
	_discard_count_label.size = Vector2(70, 20)
	_discard_count_label.add_theme_color_override("font_color", Color("#8B6A4E"))
	_discard_count_label.add_theme_font_size_override("font_size", 12)
	_discard_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_discard_pile_visual.add_child(_discard_count_label)

	_update_pile_counts()


func _update_pile_counts() -> void:
	if _deck_count_label:
		_deck_count_label.text = str(deck_manager.get_draw_pile_count())
	if _discard_count_label:
		_discard_count_label.text = str(deck_manager.get_discard_pile_count())


func _on_card_drawn_anim(_card_id: String) -> void:
	# Animate a card-shaped rect from deck pile to hand area
	var card_ghost := ColorRect.new()
	card_ghost.size = Vector2(60, 85)
	card_ghost.color = Color("#D4AF37", 0.5)
	card_ghost.position = Vector2(1170, 535)
	card_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_ghost)

	var hand_center := Vector2(640, 500)
	var tween := create_tween()
	tween.tween_property(card_ghost, "position", hand_center, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(card_ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(card_ghost.queue_free)

	_update_pile_counts()


func _on_card_discarded_anim(_card_id: String) -> void:
	# Animate a card-shaped rect from hand to discard pile
	var card_ghost := ColorRect.new()
	card_ghost.size = Vector2(60, 85)
	card_ghost.color = Color("#8B6A4E", 0.5)
	card_ghost.position = Vector2(640, 500)
	card_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_ghost)

	var discard_pos := Vector2(1170, 420)
	var tween := create_tween()
	tween.tween_property(card_ghost, "position", discard_pos, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(card_ghost, "modulate:a", 0.0, 0.5)
	tween.tween_callback(card_ghost.queue_free)

	_update_pile_counts()


# --- Enemy ---

func _spawn_enemy_display(data: Dictionary) -> void:
	_enemy_display = enemy_display_scene.instantiate()
	enemy_area.add_child(_enemy_display)
	_enemy_display.setup_enemy(data)


# --- Hand & Cards ---

func _on_hand_changed(hand: Array) -> void:
	# Clear existing cards
	for child in hand_area.get_children():
		child.queue_free()

	# Spawn card visuals
	for card_id in hand:
		var card_data := CardDatabase.get_card(card_id)
		if card_data.is_empty():
			continue

		var card_node: Control = card_scene.instantiate()
		hand_area.add_child(card_node)
		card_node.setup(card_data)
		var play_cost: int = card_data.get("cost", 1)
		# Tense Fog curse: Skill cards cost +1 Energy
		if card_data.get("type", "") == "skill" and "tense_fog" in GameState.deck:
			play_cost += 1
		card_node.set_playable(GameState.current_energy >= play_cost)
		card_node.card_drag_started.connect(_on_card_drag_started)
		card_node.card_drag_released.connect(_on_card_drag_released)

	# Update HUD deck counts
	if hud:
		hud.update_deck_counts(deck_manager.get_draw_pile_count(), deck_manager.get_discard_pile_count())
	_update_pile_counts()
	_update_player_block()
	_update_status_effects()


func _on_card_drag_started(_card_node: Control) -> void:
	if _drop_zone:
		_drop_zone.visible = true


func _on_card_drag_released(card_node: Control, release_pos: Vector2) -> void:
	if _drop_zone:
		_drop_zone.visible = false

	# Check if released in upper part of screen (above hand area)
	var threshold_y := get_viewport_rect().size.y * 0.6
	if release_pos.y < threshold_y:
		var played: bool = combat_manager.try_play_card(card_node.card_id)
		if played:
			card_node.visible = false
			return

	# Card not played - rebuild hand to reset positions
	_on_hand_changed(deck_manager.get_hand())


func _on_end_turn() -> void:
	combat_manager.end_player_turn()


# --- Combat Events ---

func _on_combat_started() -> void:
	feedback_label.text = ""
	if hud:
		hud.update_all()
	_update_player_block()
	_update_status_effects()

	# Show enemy intent
	if _enemy_display:
		var intent: Dictionary = combat_manager.get_enemy_intent()
		_enemy_display.update_intent(intent)

	# Tutorial: combat start trigger
	TutorialManager.on_combat_start()


func _on_combat_ended(victory: bool) -> void:
	TutorialManager.on_combat_end()

	if victory:
		if _enemy_display and _enemy_display.has_method("play_death_effect"):
			await _enemy_display.play_death_effect()
		await _show_victory_overlay()
		_show_reward_screen()
	else:
		feedback_label.text = "ПОРАЖЕНИЕ"
		feedback_label.add_theme_color_override("font_color", Color("#F44336"))
		await get_tree().create_timer(2.0).timeout
		GameState.end_run(false)
		SceneTransition.change_scene("res://scenes/main_menu.tscn")


func _on_challenge_requested(card_data: Dictionary) -> void:
	# Tutorial: first challenge trigger
	if not _first_challenge_shown:
		_first_challenge_shown = true
		TutorialManager.on_first_challenge()

	# Use fixed challenge assigned to this card for the entire run
	var card_id: String = card_data.get("id", "")
	var enhanced: bool = combat_manager.next_card_enhanced
	if enhanced:
		combat_manager.next_card_enhanced = false
		_show_feedback("УСИЛЕНИЕ!", COLOR_GOLD)
	var challenge_data := ApiClient.get_or_create_card_challenge(card_id, card_data, enhanced)
	if _challenge_popup:
		_challenge_popup.show_challenge(challenge_data)


func _on_challenge_answered(user_answer: String, correct_answer: String, time_taken: float) -> void:
	combat_manager.submit_challenge_answer(user_answer, correct_answer, time_taken)


func _on_matching_completed(correct_matches: int, total_pairs: int, time_taken: float) -> void:
	combat_manager.submit_matching_result(correct_matches, total_pairs, time_taken)


func _on_challenge_resolved(result: Dictionary) -> void:
	var quality: String = result.get("quality", "mistake")
	var is_matching := result.has("correct_matches")

	if is_matching:
		var cm: int = result.get("correct_matches", 0)
		var tp: int = result.get("total_pairs", 0)
		if cm == tp and quality == "perfect":
			_show_feedback("ОТЛИЧНО! %d/%d" % [cm, tp], Color("#D4AF37"))
			_flash_overlay(Color("#D4AF37"), 0.2)
		elif cm == tp:
			_show_feedback("Все верно! %d/%d" % [cm, tp], Color("#4CAF50"))
		elif cm > 0:
			_show_feedback("%d/%d верно" % [cm, tp], Color("#FF9800"))
		else:
			_show_feedback("ОШИБКА! 0/%d" % tp, Color("#F44336"))
			_screen_shake(4.0, 0.2)
	else:
		match quality:
			"perfect":
				_show_feedback("ОТЛИЧНО!", Color("#D4AF37"))
				_flash_overlay(Color("#D4AF37"), 0.2)
			"correct":
				_show_feedback("Верно!", Color("#4CAF50"))
			"slow":
				_show_feedback("Медленно...", Color("#FF9800"))
			"mistake":
				_show_feedback("ОШИБКА!", Color("#F44336"))
				_screen_shake(4.0, 0.2)

	# Update enemy display
	if _enemy_display:
		_enemy_display.update_hp(combat_manager.enemy_hp, combat_manager.enemy_max_hp)
		var intent: Dictionary = combat_manager.get_enemy_intent()
		_enemy_display.update_intent(intent)

	# Update HUD & player area
	if hud:
		hud.update_all()
		hud.update_deck_counts(deck_manager.get_draw_pile_count(), deck_manager.get_discard_pile_count())
	_update_player_block()
	_update_status_effects()


func _on_enemy_action(action: Dictionary) -> void:
	# Tutorial: first enemy turn trigger
	if not _first_enemy_turn_shown:
		_first_enemy_turn_shown = true
		TutorialManager.on_first_enemy_turn()

	var action_type: String = action.get("action", "attack")
	if action_type == "attack":
		var value: int = action.get("value", 0)
		var hits: int = action.get("hits", 1)
		_show_feedback("-%d" % (value * hits), Color("#F44336"))
		# Enemy lunges toward hero
		if _enemy_display and _player_avatar_frame:
			_enemy_display.play_attack_lunge(_player_avatar_frame.global_position)
		# Hero avatar recoil + blood splatter (delayed to sync with lunge hit)
		var hit_timer := get_tree().create_timer(0.12)
		hit_timer.timeout.connect(func():
			_hero_hit_recoil()
			_spawn_blood_splatter()
		)
		_screen_shake(6.0 + hits * 2.0, 0.3)
		_flash_overlay(Color("#F44336"), 0.2)

	# Update displays
	if _enemy_display:
		var intent: Dictionary = combat_manager.get_enemy_intent()
		_enemy_display.update_intent(intent)
	if hud:
		hud.update_all()
	_update_player_block()
	_update_status_effects()


func _show_feedback(text: String, color: Color) -> void:
	# Show feedback on a high CanvasLayer so it's above all windows
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)

	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_CENTER
	lbl.anchor_left = 0.5
	lbl.anchor_top = 0.35
	lbl.anchor_right = 0.5
	lbl.anchor_bottom = 0.35
	lbl.offset_left = -200.0
	lbl.offset_right = 200.0
	lbl.offset_top = -30.0
	lbl.offset_bottom = 30.0
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 32)
	var font_bold = load("res://assets/fonts/Merriweather-Bold.ttf")
	if font_bold:
		lbl.add_theme_font_override("font", font_bold)
	var ls := LabelSettings.new()
	ls.font = font_bold
	ls.font_size = 32
	ls.font_color = color
	ls.outline_size = 4
	ls.outline_color = Color.BLACK
	lbl.label_settings = ls
	layer.add_child(lbl)

	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.0)
	tween.tween_interval(1.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


func _screen_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	var original_pos := position
	var shake_tween := create_tween()
	var steps := 6
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		intensity *= 0.7  # Decay
		shake_tween.tween_property(self, "position", original_pos + offset, duration / steps)
	shake_tween.tween_property(self, "position", original_pos, duration / steps)


func _flash_overlay(color: Color, duration: float = 0.15) -> void:
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.color = color
	flash.color.a = 0.3
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)


func _hero_hit_recoil() -> void:
	if not _player_avatar_frame:
		return
	var original_pos := _player_avatar_frame.position
	var recoil := Vector2(-12, randf_range(-4, 4))
	var tween := create_tween()
	tween.tween_property(_player_avatar_frame, "position", original_pos + recoil, 0.06)
	tween.tween_property(_player_avatar_frame, "position", original_pos + recoil * -0.5, 0.06)
	tween.tween_property(_player_avatar_frame, "position", original_pos, 0.1).set_ease(Tween.EASE_OUT)


func _spawn_blood_splatter() -> void:
	if not _player_avatar_frame:
		return
	var center := _player_avatar_frame.global_position + _player_avatar_frame.size / 2.0
	var particle_count := randi_range(6, 10)
	for i in range(particle_count):
		var drop := ColorRect.new()
		var drop_size := randf_range(3.0, 7.0)
		drop.size = Vector2(drop_size, drop_size)
		drop.color = Color("#8B1E1E")
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(drop)
		drop.global_position = center + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var angle := randf_range(-PI, PI)
		var dist := randf_range(30.0, 80.0)
		var target := drop.global_position + Vector2(cos(angle), sin(angle)) * dist
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(drop, "global_position", target, randf_range(0.25, 0.45)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(drop, "modulate:a", 0.0, randf_range(0.3, 0.5)).set_delay(0.1)
		tween.set_parallel(false)
		tween.tween_callback(drop.queue_free)


# --- Boss UI ---

const PHASE_COLORS := {
	"past": Color("#8B6914"),
	"present": Color("#CCCCCC"),
	"future": Color("#1E90FF"),
}

const PHASE_LABELS := {
	"past": "Эпоха Прошлого",
	"present": "Эпоха Настоящего",
	"future": "Эпоха Будущего",
}


func _create_phase_label() -> void:
	_phase_label = Label.new()
	_phase_label.text = "Эпоха Настоящего"
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 20)
	_phase_label.add_theme_color_override("font_color", PHASE_COLORS["present"])
	_phase_label.position = Vector2(540, 10)
	_phase_label.size = Vector2(200, 30)
	add_child(_phase_label)


func _on_boss_phase_changed(phase: String) -> void:
	if _phase_label:
		_phase_label.text = PHASE_LABELS.get(phase, phase.capitalize())
		_phase_label.add_theme_color_override("font_color", PHASE_COLORS.get(phase, Color.WHITE))

	_show_feedback("Сдвиг времени: %s" % PHASE_LABELS.get(phase, phase), PHASE_COLORS.get(phase, Color.WHITE))


func _on_great_exam_triggered(exam_data: Dictionary) -> void:
	_show_feedback("ВЕЛИКИЙ ЭКЗАМЕН!", Color("#D4AF37"))

	# Generate a sentence construction challenge via API
	var phase: String = exam_data.get("boss_phase", "present")
	var request := {
		"player_id": GameState.player_id,
		"card_id": "great_exam",
		"challenge_type": "grammar",
		"difficulty": "B2",
		"boss_phase": phase,
	}
	ApiClient.generate_challenge(request, func(challenge_data: Dictionary):
		# Override time limit with exam's time limit
		challenge_data["time_limit"] = exam_data.get("time_limit", 45)
		if _challenge_popup:
			_challenge_popup.show_challenge(challenge_data)
			# Reconnect for exam answer handling
			if _challenge_popup.challenge_answered.is_connected(_on_challenge_answered):
				_challenge_popup.challenge_answered.disconnect(_on_challenge_answered)
			_challenge_popup.challenge_answered.connect(_on_great_exam_answered, CONNECT_ONE_SHOT)
	)


func _on_great_exam_answered(user_answer: String, correct_answer: String, time_taken: float) -> void:
	# Reconnect normal handler (with safety check to prevent double-connection)
	if not _challenge_popup.challenge_answered.is_connected(_on_challenge_answered):
		_challenge_popup.challenge_answered.connect(_on_challenge_answered)

	# Validate through API
	var validate_data := {
		"player_id": GameState.player_id,
		"challenge_type": "grammar",
		"challenge_id": "great_exam_%d" % randi(),
		"user_answer": user_answer,
		"correct_answer": correct_answer,
		"time_taken": time_taken,
		"word": "great_exam",
		"card_id": "great_exam",
	}
	ApiClient.validate_answer(validate_data, func(result: Dictionary):
		var success: bool = result.get("correct", false)
		if success:
			_show_feedback("ЭКЗАМЕН СДАН!", Color("#4CAF50"))
		else:
			_show_feedback("ЭКЗАМЕН ПРОВАЛЕН!", Color("#F44336"))
		combat_manager.resolve_great_exam(success)

		# Update displays
		if _enemy_display:
			_enemy_display.update_hp(combat_manager.enemy_hp, combat_manager.enemy_max_hp)
		if hud:
			hud.update_all()
		_update_player_block()
	)


func _on_great_exam_resolved(success: bool) -> void:
	# Update enemy display after exam resolution
	if _enemy_display:
		_enemy_display.update_hp(combat_manager.enemy_hp, combat_manager.enemy_max_hp)
		var intent: Dictionary = combat_manager.get_enemy_intent()
		_enemy_display.update_intent(intent)
	if hud:
		hud.update_all()
	_update_player_block()


func _on_fatigue_changed(_stacks: int) -> void:
	_update_status_effects()


# --- Victory Overlay ---

func _show_victory_overlay() -> void:
	# Full-screen dimmer
	var victory_layer := CanvasLayer.new()
	victory_layer.layer = 50
	add_child(victory_layer)

	var dimmer := ColorRect.new()
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.color = Color(0, 0, 0, 0.0)
	victory_layer.add_child(dimmer)

	# Victory text
	var victory_label := Label.new()
	victory_label.text = "ПОБЕДА!"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.anchors_preset = Control.PRESET_FULL_RECT
	victory_label.anchor_right = 1.0
	victory_label.anchor_bottom = 1.0
	victory_label.add_theme_color_override("font_color", COLOR_GOLD)
	victory_label.add_theme_font_size_override("font_size", 64)
	victory_label.modulate.a = 0.0
	victory_label.scale = Vector2(0.3, 0.3)
	victory_label.pivot_offset = Vector2(640, 360)
	victory_layer.add_child(victory_label)

	# Animate: dimmer fades in, text scales up and fades in
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dimmer, "color:a", 0.6, 0.5)
	tween.tween_property(victory_label, "modulate:a", 1.0, 0.4).set_delay(0.2)
	tween.tween_property(victory_label, "scale", Vector2(1.0, 1.0), 0.5).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await tween.finished

	# Hold for a moment
	await get_tree().create_timer(1.5).timeout

	# Fade out victory text, transition to rewards
	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(victory_label, "modulate:a", 0.0, 0.4)
	fade_tween.tween_property(victory_label, "scale", Vector2(1.3, 1.3), 0.4).set_ease(Tween.EASE_IN)
	# Keep dimmer for reward screen

	await fade_tween.finished
	victory_layer.queue_free()


# --- Reward Screen ---

func _show_reward_screen() -> void:
	_reward_card_chosen = false
	TutorialManager.on_reward_screen()

	# Hide combat UI
	hand_area.visible = false
	if _enemy_display:
		_enemy_display.visible = false
	if hud:
		hud.visible = false
	if player_area:
		player_area.visible = false
	feedback_label.visible = false

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.color = Color(0, 0, 0, 0.7)

	# Main panel
	_reward_panel = Control.new()
	_reward_panel.anchors_preset = Control.PRESET_FULL_RECT
	_reward_panel.anchor_right = 1.0
	_reward_panel.anchor_bottom = 1.0
	add_child(_reward_panel)
	_reward_panel.add_child(dimmer)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -360
	vbox.offset_top = -280
	vbox.offset_right = 360
	vbox.offset_bottom = 280
	vbox.add_theme_constant_override("separation", 16)
	_reward_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "НАГРАДЫ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	# Gold reward - calculate what was earned (gold was already added by combat_manager)
	var loot: Dictionary = combat_manager.enemy_data.get("loot", {})
	var coins_data = loot.get("coins", 0)
	var gold_display: int = 0
	if coins_data is int:
		gold_display = coins_data
	elif coins_data is Array and coins_data.size() >= 2:
		gold_display = (coins_data[0] + coins_data[1]) / 2  # approximate
	var gold_label := Label.new()
	gold_label.text = "+%d лекс-монет" % gold_display
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	gold_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(gold_label)

	# Card reward section
	var card_title := Label.new()
	card_title.text = "Выберите карту для добавления в колоду:"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_color_override("font_color", COLOR_PARCHMENT)
	card_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(card_title)

	# Card choices
	var cards_hbox := HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(cards_hbox)

	var card_choices := _generate_card_rewards()
	for card_data in card_choices:
		var card_item := _create_reward_card(card_data)
		cards_hbox.add_child(card_item)

	# Skip button
	var skip_btn := Button.new()
	skip_btn.text = "Пропустить"
	skip_btn.custom_minimum_size = Vector2(200, 48)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_reward_button(skip_btn, Color("#5C4A3A"))
	skip_btn.pressed.connect(_on_reward_continue)
	vbox.add_child(skip_btn)


func _generate_card_rewards() -> Array:
	var loot: Dictionary = combat_manager.enemy_data.get("loot", {})
	var card_drops: Array = loot.get("card_drops", ["common"])
	var result: Array = []

	for rarity in card_drops:
		var cards_of_rarity: Array = CardDatabase.get_cards_by_rarity(rarity)
		# Filter out cards already in deck
		var available := cards_of_rarity.filter(func(c):
			return c["id"] not in GameState.deck
		)
		if available.is_empty():
			available = cards_of_rarity
		available.shuffle()
		if not available.is_empty():
			result.append(available[0])

	# If not enough, add a random common
	while result.size() < 3:
		var all_common := CardDatabase.get_cards_by_rarity("common")
		all_common.shuffle()
		for card in all_common:
			if card not in result:
				result.append(card)
				break
		if result.size() < 3 and all_common.is_empty():
			break

	return result


func _create_reward_card(card_data: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 8)

	# Wrap card in a fixed-size container so it renders correctly inside VBox
	var card_holder := Control.new()
	card_holder.custom_minimum_size = Vector2(140, 200)
	card_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(card_holder)

	var card_node: Control = card_scene.instantiate()
	card_holder.add_child(card_node)
	card_node.position = Vector2.ZERO
	card_node.size = Vector2(140, 200)
	# Defer setup until @onready vars are initialized (node must be in tree)
	card_node.ready.connect(func():
		card_node.setup(card_data)
		card_node.set_playable(false)
		card_node.modulate.a = 1.0
		if card_node.has_node("CardPanel"):
			card_node.get_node("CardPanel").modulate.a = 1.0
	)

	# "Take" button below the card
	var add_btn := Button.new()
	add_btn.text = "Взять"
	add_btn.custom_minimum_size = Vector2(120, 40)
	add_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_reward_button(add_btn, COLOR_EMERALD)
	add_btn.pressed.connect(_on_reward_card_chosen.bind(card_data))
	container.add_child(add_btn)

	return container


func _on_reward_card_chosen(card_data: Dictionary) -> void:
	if _reward_card_chosen:
		return
	_reward_card_chosen = true
	GameState.deck.append(card_data["id"])
	_on_reward_continue()


func _on_reward_continue() -> void:
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _style_reward_button(btn: Button, color: Color) -> void:
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

	var text_color := Color("#F4E8D0")
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
