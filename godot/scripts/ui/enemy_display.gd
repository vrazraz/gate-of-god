extends Control
## Displays enemy sprite, name, vertical HP bar (like hero), and intent with icon.

@onready var sprite_rect: TextureRect = $MainVBox/SpriteRow/SpriteWrapper/SpriteRect
@onready var name_label: Label = $MainVBox/NameRow/NameLabel
@onready var hp_bar_container: Control = $MainVBox/SpriteRow/HPCol/HPBarContainer
@onready var hp_label: Label = $MainVBox/SpriteRow/HPCol/HPLabel
@onready var intent_label: Label = $MainVBox/IntentContainer/IntentLabel
@onready var intent_icon: Control = $MainVBox/IntentContainer/IntentIcon
@onready var intent_icon_inline: Control = $MainVBox/NameRow/IntentIconInline

var _hp_bar_fill: ColorRect = null
var _hp_bar_height: float = 288.0
var _tooltip_panel: PanelContainer = null
var _tooltip_label: Label = null
var _status_container: HBoxContainer = null
var _enemy_id: String = ""
# Number shown next to the inline intent icon when player owns "otherworldly_eye".
var _intent_value_label: Label = null


const COLOR_HP_HIGH := Color("#4CAF50")
const COLOR_HP_MID := Color("#FF9800")
const COLOR_HP_LOW := Color("#F44336")

const INTENT_DESCRIPTIONS := {
	"attack": "Враг нанесёт физический урон.\nБлок поглощает входящий урон.",
	"debuff_confusion": "Путаница: буквы в заданиях\nбудут перемешаны на %d хода.",
	"debuff_silence": "Тишина: звуковые подсказки\nотключены на %d хода.",
	"debuff_reverse": "Обратный перевод: переводите\nс русского на английский (%d ход.).",
	"buff_block": "Враг получит блок,\nкоторый поглощает урон.",
	"buff_strength": "Враг усилится: все его\nатаки наносят больше урона.",
	"curse": "Враг добавит проклятие\nв вашу колоду!",
}

var _current_tooltip_text: String = ""


func _ready() -> void:
	# Build status effect icons above sprite
	_build_status_container()

	# Build intent value label (for Otherworldly Eye relic)
	_build_intent_value_label()

	# Build vertical HP bar (same as hero)
	_build_hp_bar()

	# Build tooltip (hidden by default)
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1A1410", 0.92)
	style.border_color = Color("#D4AF37")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_color_override("font_color", Color("#F4E8D0"))
	_tooltip_label.add_theme_font_size_override("font_size", 13)
	_tooltip_panel.add_child(_tooltip_label)
	add_child(_tooltip_panel)

	# Add black outline to intent label text
	if intent_label:
		var ls := LabelSettings.new()
		ls.font = load("res://assets/fonts/Merriweather-Bold.ttf")
		ls.font_size = 16
		ls.font_color = Color("#8B1E1E")
		ls.outline_size = 5
		ls.outline_color = Color.BLACK
		intent_label.label_settings = ls

	# Connect hover on intent container
	var intent_container := $MainVBox/IntentContainer
	if intent_container:
		intent_container.mouse_filter = Control.MOUSE_FILTER_STOP
		intent_container.mouse_entered.connect(_on_intent_hover_enter)
		intent_container.mouse_exited.connect(_on_intent_hover_exit)


func _build_hp_bar() -> void:
	if not hp_bar_container:
		return

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


func _on_intent_hover_enter() -> void:
	if _current_tooltip_text.is_empty():
		return
	_tooltip_label.text = _current_tooltip_text
	_tooltip_panel.visible = true
	_tooltip_panel.reset_size()
	await get_tree().process_frame
	var intent_container := $MainVBox/IntentContainer
	if intent_container:
		_tooltip_panel.position = Vector2(
			(intent_container.size.x - _tooltip_panel.size.x) / 2.0,
			intent_container.position.y - _tooltip_panel.size.y - 6
		)


func _on_intent_hover_exit() -> void:
	_tooltip_panel.visible = false


func setup_enemy(data: Dictionary) -> void:
	if name_label:
		name_label.text = data.get("name", "Неизвестный враг")

	var texture: Texture2D = null
	_enemy_id = data.get("id", "")
	var enemy_id: String = _enemy_id
	var sprite_path := "res://assets/sprites/enemies/%s.png" % enemy_id
	if ResourceLoader.exists(sprite_path):
		texture = load(sprite_path)

	if sprite_rect:
		sprite_rect.texture = texture
		sprite_rect.pivot_offset = sprite_rect.size / 2.0

	update_hp(data.get("hp", 30), data.get("hp", 30))
	_start_idle_animation(enemy_id)


func update_hp(current: int, maximum: int) -> void:
	if hp_label:
		hp_label.text = "%d/%d" % [current, maximum]
	if _hp_bar_fill:
		var ratio := float(current) / float(maximum) if maximum > 0 else 0.0
		_hp_bar_fill.offset_top = -_hp_bar_height * ratio
		if ratio > 0.5:
			_hp_bar_fill.color = COLOR_HP_HIGH
		elif ratio > 0.25:
			_hp_bar_fill.color = COLOR_HP_MID
		else:
			_hp_bar_fill.color = COLOR_HP_LOW


func play_attack_lunge(target_pos: Vector2) -> void:
	var original_pos := global_position
	var direction := (target_pos - original_pos).normalized()
	var lunge_offset := direction * 140.0
	var tween := create_tween()
	tween.tween_property(self, "global_position", original_pos + lunge_offset, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", original_pos, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func update_intent(intent: Dictionary) -> void:
	if not intent_label:
		return

	var action: String = intent.get("action", "attack")
	var value: int = intent.get("value", 0)
	var hits: int = intent.get("hits", 1)
	var color: Color

	match action:
		"attack":
			if hits > 1:
				intent_label.text = "Атака %d x%d" % [value, hits]
			else:
				intent_label.text = "Атака %d" % value
			color = Color("#8B1E1E")
			_current_tooltip_text = INTENT_DESCRIPTIONS["attack"]
		"debuff":
			var debuff_names := {"confusion": "Путаница", "silence": "Тишина", "reverse": "Обратный перевод"}
			var debuff_type: String = intent.get("type", "confusion")
			var duration: int = intent.get("duration", 2)
			intent_label.text = "Дебафф: %s" % debuff_names.get(debuff_type, debuff_type.capitalize())
			color = Color("#5A3E5C")
			var key := "debuff_%s" % debuff_type
			if INTENT_DESCRIPTIONS.has(key):
				_current_tooltip_text = INTENT_DESCRIPTIONS[key] % duration
			else:
				_current_tooltip_text = "Дебафф: снижает ваши способности."
		"buff":
			var buff_type: String = intent.get("type", "block")
			intent_label.text = "Усиление"
			color = Color("#2E5090")
			var key := "buff_%s" % buff_type
			_current_tooltip_text = INTENT_DESCRIPTIONS.get(key, "Враг усиливается.")
		"curse":
			intent_label.text = "Проклятие!"
			color = Color("#5A3E5C")
			_current_tooltip_text = INTENT_DESCRIPTIONS["curse"]
		_:
			intent_label.text = "???"
			color = Color("#AAAAAA")
			_current_tooltip_text = ""

	if intent_label.label_settings:
		intent_label.label_settings.font_color = color
	else:
		intent_label.add_theme_color_override("font_color", color)
	if intent_icon and intent_icon.has_method("set_intent"):
		intent_icon.set_intent(action, color)
	if intent_icon_inline and intent_icon_inline.has_method("set_intent"):
		intent_icon_inline.set_intent(action, color)

	_update_intent_value_label(action, intent, color)


func _build_intent_value_label() -> void:
	var name_row := $MainVBox/NameRow
	if not name_row:
		return
	_intent_value_label = Label.new()
	_intent_value_label.visible = false
	_intent_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := LabelSettings.new()
	ls.font = load("res://assets/fonts/Merriweather-Bold.ttf")
	ls.font_size = 15
	ls.outline_size = 4
	ls.outline_color = Color.BLACK
	ls.font_color = Color("#F4E8D0")
	_intent_value_label.label_settings = ls
	name_row.add_child(_intent_value_label)


func _update_intent_value_label(action: String, intent: Dictionary, color: Color) -> void:
	if not _intent_value_label:
		return
	# Otherworldly Eye relic gates visibility — without it the badge stays hidden.
	if not GameState.has_relic("otherworldly_eye"):
		_intent_value_label.visible = false
		return

	var text := ""
	match action:
		"attack":
			var v: int = int(intent.get("value", 0))
			var hits: int = int(intent.get("hits", 1))
			text = "%d×%d" % [v, hits] if hits > 1 else str(v)
		"buff":
			# Show value only for block (defense). Strength etc. is hidden.
			var btype: String = intent.get("type", "")
			var v: int = int(intent.get("value", 0))
			if btype == "block" and v > 0:
				text = str(v)

	if text == "":
		_intent_value_label.visible = false
		return

	_intent_value_label.text = text
	_intent_value_label.visible = true
	_intent_value_label.label_settings.font_color = color


# --- Status Effect Icons ---

func _build_status_container() -> void:
	_status_container = HBoxContainer.new()
	_status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_container.add_theme_constant_override("separation", 6)
	_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Insert before NameLabel in MainVBox (index 0)
	var main_vbox := $MainVBox
	if main_vbox:
		main_vbox.add_child(_status_container)
		main_vbox.move_child(_status_container, 0)


func update_status_effects(strength: int, block: int, debuffs: Dictionary = {}) -> void:
	if not _status_container:
		return
	for child in _status_container.get_children():
		child.queue_free()
	# Permanent stats first
	if strength > 0:
		_status_container.add_child(_create_status_icon(
			"res://assets/sprites/ui/status/strength.png",
			str(strength), "Сила: +%d к урону атак" % strength
		))
	if block > 0:
		_status_container.add_child(_create_status_icon(
			"res://assets/sprites/ui/status/block.png",
			str(block), "Блок: %d поглощения урона" % block
		))
	# Temporary debuffs (with countdown)
	var vuln: int = int(debuffs.get("vulnerable", 0))
	if vuln > 0:
		_status_container.add_child(_create_status_icon(
			"res://assets/sprites/ui/status/vulnerable.png",
			str(vuln), "Уязвимость: получает +50%% урона (%d ход.)" % vuln
		))
	var weak: int = int(debuffs.get("weak", 0))
	if weak > 0:
		_status_container.add_child(_create_status_icon(
			"res://assets/sprites/ui/status/weak.png",
			str(weak), "Слабость: атаки -25%% урона (%d ход.)" % weak
		))
	var poison: int = int(debuffs.get("poison", 0))
	if poison > 0:
		_status_container.add_child(_create_status_icon(
			"res://assets/sprites/ui/status/poison.png",
			str(poison), "Яд: %d урона в начале хода врага" % poison
		))


func _create_status_icon(icon_path: String, value_text: String, tooltip_text: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 2)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.tooltip_text = tooltip_text

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	hbox.add_child(icon)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_color_override("font_color", Color("#F4E8D0"))
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_bold = load("res://assets/fonts/Merriweather-Bold.ttf")
	if font_bold:
		val_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(val_lbl)

	return hbox


# --- Idle Animation ---

func _start_idle_animation(enemy_id: String) -> void:
	if not sprite_rect:
		return

	# Per-enemy profiles
	var sway_amp := 2.0       # rotation degrees
	var sway_period := 3.0    # seconds for full cycle
	var breathe_amp := 0.02   # scale Y offset
	var breathe_period := 2.5
	var float_amp := 3.0      # vertical pixels
	var float_period := 2.8

	match enemy_id:
		"whisper":
			sway_amp = 3.0
			float_amp = 5.0
			float_period = 3.2
			breathe_amp = 0.025
		"utgallu":
			sway_amp = 2.5
			float_amp = 4.0
			breathe_amp = 0.02
		"possessed_slave":
			sway_amp = 3.5
			sway_period = 2.0
			breathe_amp = 0.03
			breathe_period = 1.8
			float_amp = 2.0
		"possessed_guard":
			sway_amp = 1.0
			sway_period = 4.0
			breathe_amp = 0.015
			breathe_period = 3.0
			float_amp = 1.0
		"possessed_priest":
			sway_amp = 2.0
			float_amp = 6.0
			float_period = 3.5
			breathe_amp = 0.02
		"the_torn":
			sway_amp = 1.0
			sway_period = 4.0
			breathe_amp = 0.015
			breathe_period = 3.0
			float_amp = 1.0
			float_period = 3.5
		"ashipu":
			sway_amp = 1.5
			sway_period = 4.5
			breathe_amp = 0.015
			breathe_period = 3.5
			float_amp = 2.0
			float_period = 4.0

	# Gentle rotation sway
	var sway_tween := create_tween().set_loops()
	sway_tween.tween_property(sprite_rect, "rotation", deg_to_rad(sway_amp), sway_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	sway_tween.tween_property(sprite_rect, "rotation", deg_to_rad(-sway_amp), sway_period) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	sway_tween.tween_property(sprite_rect, "rotation", 0.0, sway_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Breathing (scale Y pulse)
	var breathe_tween := create_tween().set_loops()
	breathe_tween.tween_property(sprite_rect, "scale", Vector2(1.0, 1.0 + breathe_amp), breathe_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breathe_tween.tween_property(sprite_rect, "scale", Vector2(1.0, 1.0 - breathe_amp * 0.5), breathe_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Floating (vertical bob)
	var base_y := sprite_rect.position.y
	var float_tween := create_tween().set_loops()
	float_tween.tween_property(sprite_rect, "position:y", base_y - float_amp, float_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(sprite_rect, "position:y", base_y + float_amp * 0.5, float_period * 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# --- Death Effects ---

const DEATH_EFFECT_MAP := {
	"whisper": "evaporate",
	"utgallu": "sink",
	"possessed_slave": "disintegrate",
	"possessed_guard": "shatter",
	"possessed_priest": "flash_ash",
	"the_torn": "shatter",
	"ashipu": "flash_ash",
}


func play_death_effect() -> void:
	var effect: String = DEATH_EFFECT_MAP.get(_enemy_id, "disintegrate")

	# Delay before death animation
	await get_tree().create_timer(1.5).timeout

	if _status_container:
		_status_container.visible = false

	match effect:
		"disintegrate":
			await _death_disintegrate()
		"evaporate":
			await _death_evaporate()
		"shatter":
			await _death_shatter()
		"sink":
			await _death_sink()
		"flash_ash":
			await _death_flash_ash()
		_:
			await _death_disintegrate()


func _death_disintegrate() -> void:
	## Sprite breaks into dust particles flying outward
	if not sprite_rect:
		return
	var wrapper: Control = $MainVBox/SpriteRow/SpriteWrapper
	var center := sprite_rect.global_position + sprite_rect.size / 2.0

	# Spawn dust particles
	for i in range(30):
		var p := ColorRect.new()
		var sz := randf_range(3.0, 8.0)
		p.size = Vector2(sz, sz)
		p.color = sprite_rect.modulate.lerp(Color("#5C4A3A"), randf())
		p.color.a = 1.0
		p.global_position = center + Vector2(randf_range(-40, 40), randf_range(-60, 60))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(p)

		var target := p.global_position + Vector2(randf_range(-120, 120), randf_range(-80, 140))
		var dur := randf_range(0.6, 1.2)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", target, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(p, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.tween_property(p, "rotation", randf_range(-PI, PI), dur)
		tw.tween_callback(p.queue_free).set_delay(dur)

	# Fade out sprite
	var tween := create_tween()
	tween.tween_property(sprite_rect, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	await tween.finished
	await get_tree().create_timer(0.5).timeout


func _death_evaporate() -> void:
	## Sprite dissolves bottom-up with dark smoke rising
	if not sprite_rect:
		return
	var wrapper: Control = $MainVBox/SpriteRow/SpriteWrapper
	var sprite_pos := sprite_rect.global_position
	var sprite_size := sprite_rect.size

	# Dark smoke particles rising from the sprite
	for i in range(25):
		var p := ColorRect.new()
		var sz := randf_range(6.0, 14.0)
		p.size = Vector2(sz, sz)
		p.color = Color(0.15, 0.1, 0.2, 0.8)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start_x := randf_range(sprite_pos.x, sprite_pos.x + sprite_size.x)
		var start_y := sprite_pos.y + sprite_size.y - randf_range(0, sprite_size.y * 0.5)
		p.global_position = Vector2(start_x, start_y)
		wrapper.add_child(p)

		var dur := randf_range(0.8, 1.5)
		var delay := randf_range(0.0, 0.6)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p, "global_position:y", start_y - randf_range(80, 160), dur).set_delay(delay).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "global_position:x", start_x + randf_range(-30, 30), dur).set_delay(delay)
		tw.tween_property(p, "modulate:a", 0.0, dur * 0.6).set_delay(delay + dur * 0.4)
		tw.tween_property(p, "scale", Vector2(2.0, 2.0), dur).set_delay(delay)
		tw.tween_callback(p.queue_free).set_delay(delay + dur)

	# Sprite fades from bottom by clipping + alpha
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite_rect, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite_rect, "scale", Vector2(1.0, 0.6), 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite_rect, "position:y", sprite_rect.position.y + 40, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	await get_tree().create_timer(0.3).timeout


func _death_shatter() -> void:
	## Sprite shakes, then explodes into large rotating shards
	if not sprite_rect:
		return
	var wrapper: Control = $MainVBox/SpriteRow/SpriteWrapper
	var center := sprite_rect.global_position + sprite_rect.size / 2.0

	# Shake before shattering
	var orig_pos := sprite_rect.position
	var shake_tw := create_tween()
	for i in range(8):
		var offset := Vector2(randf_range(-6, 6), randf_range(-6, 6))
		shake_tw.tween_property(sprite_rect, "position", orig_pos + offset, 0.04)
	shake_tw.tween_property(sprite_rect, "position", orig_pos, 0.04)
	await shake_tw.finished

	# Spawn shards
	for i in range(12):
		var shard := ColorRect.new()
		var sz := randf_range(10.0, 25.0)
		shard.size = Vector2(sz, sz * randf_range(0.5, 1.5))
		shard.color = Color(randf_range(0.15, 0.35), randf_range(0.1, 0.2), randf_range(0.1, 0.15))
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.pivot_offset = shard.size / 2.0
		shard.global_position = center + Vector2(randf_range(-30, 30), randf_range(-40, 40))
		wrapper.add_child(shard)

		var angle := randf_range(0, TAU)
		var dist := randf_range(100, 220)
		var target := shard.global_position + Vector2(cos(angle), sin(angle)) * dist
		var dur := randf_range(0.5, 0.9)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(shard, "global_position", target, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(shard, "rotation", randf_range(-TAU, TAU), dur)
		tw.tween_property(shard, "modulate:a", 0.0, dur * 0.7).set_delay(dur * 0.3)
		tw.tween_callback(shard.queue_free).set_delay(dur)

	# Hide sprite instantly
	sprite_rect.modulate.a = 0.0
	await get_tree().create_timer(0.8).timeout


func _death_sink() -> void:
	## Sprite sinks downward, shrinking, with purple glow rising from below
	if not sprite_rect:
		return
	var wrapper: Control = $MainVBox/SpriteRow/SpriteWrapper

	# Purple glow from below
	var glow := ColorRect.new()
	glow.color = Color("#5A3E5C", 0.0)
	glow.size = Vector2(sprite_rect.size.x + 40, 30)
	glow.position = Vector2(sprite_rect.position.x - 20, sprite_rect.position.y + sprite_rect.size.y - 10)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(glow)

	var glow_tw := create_tween()
	glow_tw.tween_property(glow, "color:a", 0.6, 0.4).set_ease(Tween.EASE_OUT)
	glow_tw.tween_property(glow, "color:a", 0.0, 0.8).set_delay(0.6)
	glow_tw.tween_callback(glow.queue_free)

	# Sprite sinks and shrinks
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite_rect, "position:y", sprite_rect.position.y + 80, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite_rect, "scale", Vector2(0.4, 0.2), 1.2).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite_rect, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_delay(0.2)
	await tween.finished
	await get_tree().create_timer(0.2).timeout


func _death_flash_ash() -> void:
	## Bright white flash, then darkened silhouette crumbles into falling ash
	if not sprite_rect:
		return
	var wrapper: Control = $MainVBox/SpriteRow/SpriteWrapper
	var center := sprite_rect.global_position + sprite_rect.size / 2.0

	# White flash overlay
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.color = Color(1, 1, 1, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(flash)

	var flash_tw := create_tween()
	flash_tw.tween_property(flash, "color:a", 0.9, 0.1)
	flash_tw.tween_property(flash, "color:a", 0.0, 0.3)
	flash_tw.tween_callback(flash.queue_free)
	await get_tree().create_timer(0.15).timeout

	# Darken sprite to silhouette
	var dark_tw := create_tween()
	dark_tw.tween_property(sprite_rect, "modulate", Color(0.15, 0.1, 0.1, 1.0), 0.2)
	await dark_tw.finished

	# Ash particles falling with gravity
	for i in range(25):
		var ash := ColorRect.new()
		var sz := randf_range(3.0, 7.0)
		ash.size = Vector2(sz, sz)
		ash.color = Color(randf_range(0.2, 0.4), randf_range(0.15, 0.25), randf_range(0.1, 0.2), 1.0)
		ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ash.global_position = center + Vector2(randf_range(-50, 50), randf_range(-70, 30))
		wrapper.add_child(ash)

		var dur := randf_range(0.8, 1.5)
		var delay := randf_range(0.0, 0.4)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(ash, "global_position:y", ash.global_position.y + randf_range(100, 200), dur).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(ash, "global_position:x", ash.global_position.x + randf_range(-40, 40), dur).set_delay(delay)
		tw.tween_property(ash, "modulate:a", 0.0, dur * 0.5).set_delay(delay + dur * 0.5)
		tw.tween_callback(ash.queue_free).set_delay(delay + dur)

	# Fade sprite
	var fade := create_tween()
	fade.tween_property(sprite_rect, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	await fade.finished
	await get_tree().create_timer(0.5).timeout
