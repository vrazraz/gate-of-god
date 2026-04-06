extends Control
## Challenge popup: displays linguistic challenges and handles player input.

signal challenge_answered(user_answer: String, correct_answer: String, time_taken: float)
signal challenge_timed_out()
signal matching_completed(correct_matches: int, total_pairs: int, time_taken: float)

@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var options_container: VBoxContainer = $Panel/VBoxContainer/OptionsContainer
@onready var text_input: LineEdit = $Panel/VBoxContainer/TextInput
@onready var submit_button: Button = $Panel/VBoxContainer/SubmitButton
@onready var timer_bar: ProgressBar = $Panel/VBoxContainer/TimerBar
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var instruction_label: Label = $Panel/VBoxContainer/InstructionLabel

var _challenge_data: Dictionary = {}
var _correct_answer: String = ""
var _time_limit: float = 10.0
var _time_remaining: float = 10.0
var _is_active: bool = false
var _start_time: float = 0.0
var _keyboard_label: Label = null
var _last_layout: String = ""
var _layout_check_timer: float = 0.0

# Matching mode state
var _matching_container: HBoxContainer = null
var _selected_left_btn: Button = null
var _selected_left_word: String = ""
var _formed_pairs: Array = []
var _correct_mapping: Dictionary = {}
var _total_match_pairs: int = 0
const MATCH_COLORS: Array = [
	Color("#2E5090"),  # Blue
	Color("#2D5F3F"),  # Emerald
	Color("#D4AF37"),  # Gold
	Color("#8B1E1E"),  # Crimson
]

# Colors
const COLOR_SUCCESS := Color("#4CAF50")
const COLOR_WARNING := Color("#FF9800")
const COLOR_ERROR := Color("#F44336")
const COLOR_PARCHMENT_LIGHT := Color("#FAF3E6")
const COLOR_PARCHMENT := Color("#F4E8D0")
const COLOR_ACADEMIC_BLUE := Color("#2E5090")


func _ready() -> void:
	visible = false
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if text_input:
		text_input.text_submitted.connect(_on_text_submitted)
	_build_keyboard_label()


func _process(delta: float) -> void:
	if not _is_active:
		return

	_time_remaining -= delta
	_update_timer_display()

	# Check keyboard layout periodically (only for text input mode)
	if _keyboard_label and _keyboard_label.visible:
		_layout_check_timer -= delta
		if _layout_check_timer <= 0.0:
			_layout_check_timer = 0.5
			_update_keyboard_layout()

	if _time_remaining <= 0:
		_is_active = false
		if _challenge_data.get("input_type", "") == "matching":
			_evaluate_matching_timeout()
		else:
			challenge_timed_out.emit()
			_show_correct_answer_feedback()
			var elapsed := _time_limit
			await get_tree().create_timer(2.5).timeout
			challenge_answered.emit("", _correct_answer, elapsed)
			hide_challenge()


func show_challenge(data: Dictionary) -> void:
	_challenge_data = data
	_time_limit = float(data.get("time_limit", 10))

	# Apply relic bonus
	if GameState.has_relic("speed_readers_monocle"):
		_time_limit += 2.0

	_time_remaining = _time_limit
	_start_time = Time.get_ticks_msec() / 1000.0
	_is_active = true

	# Set question text
	if question_label:
		var question_text: String = data.get("question", "")
		var prompt: String = data.get("prompt", "")
		if prompt != "":
			question_text += "\n\"%s\"" % prompt
		question_label.text = question_text

	# Setup based on input type
	var input_type: String = data.get("input_type", "multiple_choice")

	if input_type == "matching":
		_setup_matching(data)
		if text_input:
			text_input.visible = false
		if submit_button:
			submit_button.visible = false
		if _keyboard_label:
			_keyboard_label.visible = false
		_correct_answer = ""
	elif input_type == "multiple_choice":
		_setup_multiple_choice(data)
		if text_input:
			text_input.visible = false
		if submit_button:
			submit_button.visible = false
		if _keyboard_label:
			_keyboard_label.visible = false
		_correct_answer = data.get("correct_option", data.get("correct_answer", ""))
	else:
		_setup_text_input(data)
		if options_container:
			_clear_options()
		if _keyboard_label:
			_keyboard_label.visible = true
			_last_layout = ""
			_layout_check_timer = 0.0
		_correct_answer = data.get("correct_option", data.get("correct_answer", ""))

	# Set instruction text based on challenge type
	if instruction_label:
		instruction_label.text = _get_instruction_text(data)

	visible = true


func _setup_multiple_choice(data: Dictionary) -> void:
	_clear_options()

	var options: Array = data.get("options", [])
	for opt in options:
		var btn := Button.new()
		btn.text = "%s) %s" % [opt.get("id", "?").to_upper(), opt.get("text", "")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(400, 48)

		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = COLOR_PARCHMENT
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
		stylebox.content_margin_left = 16
		stylebox.content_margin_right = 16
		stylebox.content_margin_top = 12
		stylebox.content_margin_bottom = 12
		btn.add_theme_stylebox_override("normal", stylebox)

		var hover_style := stylebox.duplicate()
		hover_style.bg_color = Color("#D4C4A8")
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = COLOR_ACADEMIC_BLUE
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.add_theme_color_override("font_color", Color("#1A1A1A"))
		btn.add_theme_color_override("font_hover_color", Color("#1A1A1A"))
		btn.add_theme_color_override("font_pressed_color", Color("#1A1A1A"))
		btn.add_theme_font_size_override("font_size", 18)

		var option_id: String = opt.get("id", "")
		btn.pressed.connect(_on_option_selected.bind(option_id))
		if options_container:
			options_container.add_child(btn)


func _setup_text_input(data: Dictionary) -> void:
	if text_input:
		text_input.visible = true
		text_input.text = ""
		text_input.placeholder_text = "Введите ответ..."
		text_input.grab_focus()
	if submit_button:
		submit_button.visible = true
		submit_button.text = "Ответить"
		# Ensure button text is visible on the light popup panel
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_ACADEMIC_BLUE
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		submit_button.add_theme_stylebox_override("normal", style)
		var hover_s := style.duplicate()
		hover_s.bg_color = COLOR_ACADEMIC_BLUE.lightened(0.1)
		submit_button.add_theme_stylebox_override("hover", hover_s)
		submit_button.add_theme_color_override("font_color", Color("#F4E8D0"))
		submit_button.add_theme_color_override("font_hover_color", Color("#F4E8D0"))
		submit_button.add_theme_color_override("font_pressed_color", Color("#F4E8D0"))


func _clear_options() -> void:
	if options_container:
		for child in options_container.get_children():
			child.queue_free()


func _on_option_selected(option_id: String) -> void:
	if not _is_active:
		return
	_is_active = false
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _start_time
	var is_correct := (option_id == _correct_answer)

	# Disable all option buttons
	if options_container:
		for child in options_container.get_children():
			if child is Button:
				child.disabled = true

	# Highlight correct/wrong options
	_highlight_options(option_id, is_correct)

	if is_correct:
		challenge_answered.emit(option_id, _correct_answer, elapsed)
		await get_tree().create_timer(0.5).timeout
		hide_challenge()
	else:
		_show_correct_answer_feedback()
		await get_tree().create_timer(2.5).timeout
		challenge_answered.emit(option_id, _correct_answer, elapsed)
		hide_challenge()


func _on_text_submitted(_text: String) -> void:
	_on_submit_pressed()


func _on_submit_pressed() -> void:
	if not _is_active:
		return
	if not text_input:
		return
	var answer: String = text_input.text.strip_edges()
	if answer.is_empty():
		return
	_is_active = false
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _start_time
	var is_correct := (answer.to_lower() == _correct_answer.to_lower())

	if text_input:
		text_input.editable = false
	if submit_button:
		submit_button.disabled = true

	if is_correct:
		challenge_answered.emit(answer, _correct_answer, elapsed)
		await get_tree().create_timer(0.5).timeout
		hide_challenge()
	else:
		_show_correct_answer_feedback()
		await get_tree().create_timer(2.5).timeout
		challenge_answered.emit(answer, _correct_answer, elapsed)
		hide_challenge()


func _highlight_options(selected_id: String, is_correct: bool) -> void:
	if not options_container:
		return
	var options: Array = _challenge_data.get("options", [])
	var idx := 0
	for child in options_container.get_children():
		if not (child is Button) or idx >= options.size():
			idx += 1
			continue
		var opt_id: String = options[idx].get("id", "")
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12

		if opt_id == _correct_answer:
			style.bg_color = Color("#2D5F3F")
			child.add_theme_color_override("font_color", Color("#F4E8D0"))
			child.add_theme_color_override("font_disabled_color", Color("#F4E8D0"))
		elif opt_id == selected_id and not is_correct:
			style.bg_color = Color("#8B1E1E")
			child.add_theme_color_override("font_color", Color("#F4E8D0"))
			child.add_theme_color_override("font_disabled_color", Color("#F4E8D0"))
		else:
			style.bg_color = Color("#D5CAB8")
			child.add_theme_color_override("font_disabled_color", Color("#888888"))

		child.add_theme_stylebox_override("normal", style)
		child.add_theme_stylebox_override("disabled", style)
		idx += 1


func _show_correct_answer_feedback() -> void:
	if not instruction_label:
		return
	# For text input: show the correct answer string
	# For multiple choice: the highlighting already shows it, but add text too
	var correct_text: String = _correct_answer
	var input_type: String = _challenge_data.get("input_type", "multiple_choice")
	if input_type == "multiple_choice":
		# Find the text of the correct option
		for opt in _challenge_data.get("options", []):
			if opt.get("id", "") == _correct_answer:
				correct_text = opt.get("text", _correct_answer)
				break
	instruction_label.text = "Правильный ответ: %s" % correct_text
	instruction_label.add_theme_color_override("font_color", Color("#8B1E1E"))
	instruction_label.add_theme_font_size_override("font_size", 20)


func hide_challenge() -> void:
	_is_active = false
	visible = false
	_clear_options()
	_clear_matching()
	if _kb_thread:
		_kb_thread.wait_to_finish()
		_kb_thread = null
	if text_input:
		text_input.editable = true
	if submit_button:
		submit_button.disabled = false
	if _keyboard_label:
		_keyboard_label.visible = false
	if instruction_label:
		instruction_label.add_theme_color_override("font_color", Color(0.361, 0.29, 0.227, 1))
		instruction_label.add_theme_font_size_override("font_size", 18)


func _get_instruction_text(data: Dictionary) -> String:
	var challenge_type: String = data.get("type", "vocabulary")
	var input_type: String = data.get("input_type", "multiple_choice")

	match challenge_type:
		"matching":
			return "Нажмите слово слева, затем его перевод справа."
		"grammar":
			return "Напечатайте слово в правильной форме."
		"vocabulary":
			if input_type == "multiple_choice":
				return "Выберите правильный перевод слова."
			return "Напечатайте перевод слова."
		"spelling":
			return "Напечатайте слово с правильным написанием."
		_:
			if input_type == "multiple_choice":
				return "Выберите правильный ответ."
			return "Напечатайте правильный ответ."


func _update_timer_display() -> void:
	if timer_bar:
		timer_bar.value = (_time_remaining / _time_limit) * 100.0

		var ratio := _time_remaining / _time_limit
		if ratio > 0.6:
			timer_bar.modulate = COLOR_SUCCESS
		elif ratio > 0.3:
			timer_bar.modulate = COLOR_WARNING
		else:
			timer_bar.modulate = COLOR_ERROR

	if timer_label:
		timer_label.text = "%ds" % int(ceil(_time_remaining))


func _build_keyboard_label() -> void:
	_keyboard_label = Label.new()
	_keyboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_keyboard_label.add_theme_font_size_override("font_size", 12)
	_keyboard_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 0.7))
	_keyboard_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keyboard_label.visible = false
	var panel := $Panel
	if panel:
		panel.add_child(_keyboard_label)
		_keyboard_label.position = Vector2(panel.size.x - 60, 8)
		_keyboard_label.size = Vector2(50, 20)


func _update_keyboard_layout() -> void:
	if not _keyboard_label:
		return
	var layout := _get_current_layout()
	if layout != _last_layout:
		_last_layout = layout
		_keyboard_label.text = layout


var _kb_thread: Thread = null
var _kb_thread_result: String = ""
var _kb_thread_done: bool = false


func _get_current_layout() -> String:
	# Return cached result from background thread
	if _kb_thread_done:
		_kb_thread_done = false
		if _kb_thread:
			_kb_thread.wait_to_finish()
			_kb_thread = null
		return _kb_thread_result
	# Launch background thread if not running
	if _kb_thread == null:
		_kb_thread = Thread.new()
		_kb_thread.start(_kb_layout_thread_func)
	return _last_layout


func _kb_layout_thread_func() -> void:
	if OS.get_name() != "Windows":
		_kb_thread_result = ""
		_kb_thread_done = true
		return
	var output: Array = []
	var script_path: String = ProjectSettings.globalize_path("res://scripts/util/get_kb_layout.ps1")
	var exit_code := OS.execute("powershell", [
		"-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass", "-File", script_path
	], output, true)
	if exit_code == 0 and not output.is_empty():
		var lang_id: String = output[0].strip_edges()
		match lang_id:
			"0419": _kb_thread_result = "RU"
			"0409": _kb_thread_result = "EN"
			"0809": _kb_thread_result = "EN"
			"0804": _kb_thread_result = "中"
			"0404": _kb_thread_result = "中"
			"0411": _kb_thread_result = "JP"
			"0412": _kb_thread_result = "KR"
			"0407": _kb_thread_result = "DE"
			"040C": _kb_thread_result = "FR"
			"0C0A", "040A": _kb_thread_result = "ES"
			"0410": _kb_thread_result = "IT"
			"0416", "0816": _kb_thread_result = "PT"
			_: _kb_thread_result = lang_id
	else:
		_kb_thread_result = ""
	_kb_thread_done = true


# --- Matching challenge UI ---

func _setup_matching(data: Dictionary) -> void:
	_clear_matching()
	_clear_options()

	var pairs: Array = data.get("pairs", [])
	_total_match_pairs = pairs.size()
	_correct_mapping.clear()
	_formed_pairs.clear()
	_selected_left_btn = null
	_selected_left_word = ""

	for p in pairs:
		_correct_mapping[p["en"]] = p["ru"]

	_matching_container = HBoxContainer.new()
	_matching_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matching_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_matching_container.add_theme_constant_override("separation", 24)
	_matching_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 8)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 8)

	var left_words: Array = []
	var right_words: Array = []
	for p in pairs:
		left_words.append(p["en"])
		right_words.append(p["ru"])
	right_words.shuffle()

	for word in left_words:
		var btn := _create_match_btn(word, true)
		left_col.add_child(btn)

	for word in right_words:
		var btn := _create_match_btn(word, false)
		right_col.add_child(btn)

	_matching_container.add_child(left_col)
	_matching_container.add_child(right_col)

	var vbox: VBoxContainer = $Panel/VBoxContainer
	vbox.add_child(_matching_container)
	vbox.move_child(_matching_container, 1)


func _create_match_btn(word: String, is_left: bool) -> Button:
	var btn := Button.new()
	btn.text = word
	btn.custom_minimum_size = Vector2(200, 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PARCHMENT
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#C4A882")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover_s := style.duplicate()
	hover_s.border_color = COLOR_ACADEMIC_BLUE
	btn.add_theme_stylebox_override("hover", hover_s)

	btn.add_theme_color_override("font_color", Color("#1A1A1A"))
	btn.add_theme_color_override("font_hover_color", Color("#1A1A1A"))
	btn.add_theme_font_size_override("font_size", 16)

	if is_left:
		btn.pressed.connect(_on_left_word_clicked.bind(btn, word))
	else:
		btn.pressed.connect(_on_right_word_clicked.bind(btn, word))

	return btn


func _on_left_word_clicked(btn: Button, word: String) -> void:
	if not _is_active:
		return

	# If already paired, remove the pair
	for i in range(_formed_pairs.size()):
		if _formed_pairs[i]["left_btn"] == btn:
			_remove_pair(i)
			return

	# Deselect previous
	if _selected_left_btn:
		_reset_match_btn_style(_selected_left_btn)
	_selected_left_btn = btn
	_selected_left_word = word
	_highlight_selected_btn(btn)


func _on_right_word_clicked(btn: Button, word: String) -> void:
	if not _is_active:
		return

	# If already paired, remove the pair
	for i in range(_formed_pairs.size()):
		if _formed_pairs[i]["right_btn"] == btn:
			_remove_pair(i)
			return

	# Need a left word selected
	if not _selected_left_btn:
		return

	_form_pair(_selected_left_btn, btn, _selected_left_word, word)
	_selected_left_btn = null
	_selected_left_word = ""

	if _formed_pairs.size() == _total_match_pairs:
		_finalize_matching()


func _form_pair(left_btn: Button, right_btn: Button, left_word: String, right_word: String) -> void:
	var pair_idx := _formed_pairs.size()
	var color: Color = MATCH_COLORS[pair_idx % MATCH_COLORS.size()]
	_formed_pairs.append({
		"left_btn": left_btn,
		"right_btn": right_btn,
		"left_word": left_word,
		"right_word": right_word,
	})
	_color_match_btn(left_btn, color)
	_color_match_btn(right_btn, color)


func _remove_pair(pair_index: int) -> void:
	var pair: Dictionary = _formed_pairs[pair_index]
	_reset_match_btn_style(pair["left_btn"])
	_reset_match_btn_style(pair["right_btn"])
	_formed_pairs.remove_at(pair_index)
	# Re-color remaining pairs
	for i in range(_formed_pairs.size()):
		var c: Color = MATCH_COLORS[i % MATCH_COLORS.size()]
		_color_match_btn(_formed_pairs[i]["left_btn"], c)
		_color_match_btn(_formed_pairs[i]["right_btn"], c)


func _finalize_matching() -> void:
	_is_active = false
	await get_tree().create_timer(0.4).timeout
	_evaluate_matching()


func _evaluate_matching() -> void:
	var correct_count := 0
	for pair in _formed_pairs:
		var is_correct: bool = (_correct_mapping.get(pair["left_word"], "") == pair["right_word"])
		if is_correct:
			correct_count += 1
			_color_match_btn(pair["left_btn"], COLOR_SUCCESS)
			_color_match_btn(pair["right_btn"], COLOR_SUCCESS)
		else:
			_color_match_btn(pair["left_btn"], COLOR_ERROR)
			_color_match_btn(pair["right_btn"], COLOR_ERROR)

	# Disable all buttons
	if _matching_container:
		for col in _matching_container.get_children():
			for child in col.get_children():
				if child is Button:
					child.disabled = true

	var elapsed := (Time.get_ticks_msec() / 1000.0) - _start_time

	if instruction_label:
		instruction_label.text = "%d/%d верно!" % [correct_count, _total_match_pairs]
		if correct_count == _total_match_pairs:
			instruction_label.add_theme_color_override("font_color", COLOR_SUCCESS)
		elif correct_count > 0:
			instruction_label.add_theme_color_override("font_color", COLOR_WARNING)
		else:
			instruction_label.add_theme_color_override("font_color", COLOR_ERROR)

	var wait_time := 1.0 if correct_count == _total_match_pairs else 2.0
	await get_tree().create_timer(wait_time).timeout

	matching_completed.emit(correct_count, _total_match_pairs, elapsed)
	hide_challenge()


func _evaluate_matching_timeout() -> void:
	var correct_count := 0
	for pair in _formed_pairs:
		var is_correct: bool = (_correct_mapping.get(pair["left_word"], "") == pair["right_word"])
		if is_correct:
			correct_count += 1
			_color_match_btn(pair["left_btn"], COLOR_SUCCESS)
			_color_match_btn(pair["right_btn"], COLOR_SUCCESS)
		else:
			_color_match_btn(pair["left_btn"], COLOR_ERROR)
			_color_match_btn(pair["right_btn"], COLOR_ERROR)

	# Disable all buttons
	if _matching_container:
		for col in _matching_container.get_children():
			for child in col.get_children():
				if child is Button:
					child.disabled = true

	if instruction_label:
		instruction_label.text = "Время! %d/%d верно" % [correct_count, _total_match_pairs]
		instruction_label.add_theme_color_override("font_color", COLOR_WARNING)

	var elapsed := _time_limit

	await get_tree().create_timer(2.0).timeout
	matching_completed.emit(correct_count, _total_match_pairs, elapsed)
	hide_challenge()


func _highlight_selected_btn(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFF3C4")
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = COLOR_ACADEMIC_BLUE
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)


func _color_match_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color.darkened(0.2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_color_override("font_color", Color("#F4E8D0"))
	btn.add_theme_color_override("font_hover_color", Color("#F4E8D0"))
	btn.add_theme_color_override("font_disabled_color", Color("#F4E8D0"))


func _reset_match_btn_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PARCHMENT
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#C4A882")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	var hover_s := style.duplicate()
	hover_s.border_color = COLOR_ACADEMIC_BLUE
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_color_override("font_color", Color("#1A1A1A"))
	btn.add_theme_color_override("font_hover_color", Color("#1A1A1A"))
	btn.disabled = false


func _clear_matching() -> void:
	if _matching_container:
		_matching_container.queue_free()
		_matching_container = null
	_selected_left_btn = null
	_selected_left_word = ""
	_formed_pairs.clear()
	_correct_mapping.clear()
