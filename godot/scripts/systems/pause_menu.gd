extends CanvasLayer
## Global pause menu. Autoloaded singleton.
## ESC toggles the menu from any scene (except main menu).
## Pauses the game tree while open.

var _panel: Control
var _dimmer: ColorRect
var _container: VBoxContainer
var _is_open: bool = false

const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_GOLD := Color("#D4AF37")
const COLOR_CRIMSON := Color("#8B1E1E")
const COLOR_BROWN := Color("#5C4A3A")
const COLOR_DARK := Color(0.08, 0.06, 0.04, 0.85)

var _btn_normal_tex: Texture2D
var _btn_hover_tex: Texture2D
var _btn_pressed_tex: Texture2D
var _font_bold: Font


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_btn_normal_tex = load("res://assets/sprites/ui/buttons/btn_normal.png")
	_btn_hover_tex = load("res://assets/sprites/ui/buttons/btn_hover.png")
	_btn_pressed_tex = load("res://assets/sprites/ui/buttons/btn_pressed.png")
	_font_bold = load("res://assets/fonts/Merriweather-Bold.ttf")

	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if _is_on_main_menu():
			return
		if _is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _is_on_main_menu() -> bool:
	var current := get_tree().current_scene
	if current and current.scene_file_path == "res://scenes/main_menu.tscn":
		return true
	return false


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_panel.visible = true
	get_tree().paused = true

	# Fade in
	_dimmer.modulate.a = 0.0
	_container.modulate.a = 0.0
	_container.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dimmer, "modulate:a", 1.0, 0.15)
	tween.tween_property(_container, "modulate:a", 1.0, 0.15)
	tween.tween_property(_container, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	get_tree().paused = false

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_dimmer, "modulate:a", 0.0, 0.12)
	tween.tween_property(_container, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_hide_panel).set_delay(0.12)


func _hide_panel() -> void:
	_panel.visible = false


func _build_ui() -> void:
	_panel = Control.new()
	_panel.anchors_preset = Control.PRESET_FULL_RECT
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	# Dark overlay
	_dimmer = ColorRect.new()
	_dimmer.anchors_preset = Control.PRESET_FULL_RECT
	_dimmer.anchor_right = 1.0
	_dimmer.anchor_bottom = 1.0
	_dimmer.color = COLOR_DARK
	_panel.add_child(_dimmer)

	# Centered container
	_container = VBoxContainer.new()
	_container.anchors_preset = Control.PRESET_CENTER
	_container.anchor_left = 0.5
	_container.anchor_top = 0.5
	_container.anchor_right = 0.5
	_container.anchor_bottom = 0.5
	_container.offset_left = -160.0
	_container.offset_top = -200.0
	_container.offset_right = 160.0
	_container.offset_bottom = 200.0
	_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	_container.add_theme_constant_override("separation", 16)
	_container.pivot_offset = Vector2(160, 200)
	_panel.add_child(_container)

	# Title
	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 36)
	_container.add_child(title)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_container.add_child(spacer)

	# Buttons
	_add_button("ВЕРНУТЬСЯ", _on_resume)
	_add_button("В ГЛАВНОЕ МЕНЮ", _on_main_menu)
	_add_button("НАСТРОЙКИ", _on_settings)
	_add_button("ВЫХОД", _on_quit)


func _add_button(text: String, callback: Callable) -> void:
	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(280, 52)
	btn.texture_normal = _btn_normal_tex
	btn.texture_hover = _btn_hover_tex
	btn.texture_pressed = _btn_pressed_tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.pressed.connect(callback)
	_container.add_child(btn)

	var lbl := Label.new()
	lbl.text = text
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", COLOR_PARCHMENT)
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", 16)
	btn.add_child(lbl)


func _on_resume() -> void:
	close()


func _on_main_menu() -> void:
	close()
	SaveManager.save_run()
	SceneTransition.change_scene("res://scenes/main_menu.tscn")


func _on_settings() -> void:
	# TODO: Open settings
	pass


func _on_quit() -> void:
	get_tree().quit()
