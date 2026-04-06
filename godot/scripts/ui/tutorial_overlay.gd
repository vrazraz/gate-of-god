extends CanvasLayer
## Tutorial overlay that displays step-by-step hints.
## Sits above all other UI as a CanvasLayer.
## Shows a queue of tutorial steps one at a time.

signal overlay_dismissed()

var _step_queue: Array = []
var _showing: bool = false

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var text_label: Label = $Panel/VBox/TextLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton
@onready var dimmer: ColorRect = $Dimmer


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_btn.pressed.connect(_on_continue)
	visible = false
	dimmer.visible = false
	panel.visible = false

	# Style continue button for visibility
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2E5090")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	continue_btn.add_theme_stylebox_override("normal", style)
	var hover_s := style.duplicate()
	hover_s.bg_color = Color("#2E5090").lightened(0.1)
	continue_btn.add_theme_stylebox_override("hover", hover_s)
	var text_color := Color("#F4E8D0")
	continue_btn.add_theme_color_override("font_color", text_color)
	continue_btn.add_theme_color_override("font_hover_color", text_color)
	continue_btn.add_theme_color_override("font_pressed_color", text_color)

	TutorialManager.tutorial_step_ready.connect(_on_step_ready)


func _on_step_ready(step: Dictionary) -> void:
	_step_queue.append(step)
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _step_queue.is_empty():
		_showing = false
		get_tree().paused = false
		visible = false
		dimmer.visible = false
		panel.visible = false
		overlay_dismissed.emit()
		return

	_showing = true
	get_tree().paused = true
	var step: Dictionary = _step_queue.pop_front()
	title_label.text = step.get("title", "")
	text_label.text = step.get("text", "")

	visible = true
	dimmer.visible = true
	panel.visible = true

	# Animate in
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


func _on_continue() -> void:
	_show_next()


func _unhandled_input(event: InputEvent) -> void:
	if not _showing:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_continue()
		get_viewport().set_input_as_handled()
