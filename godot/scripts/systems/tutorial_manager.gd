extends Node
## Tutorial system singleton (Autoload).
## Tracks tutorial progress and provides step-by-step hints
## for the first 3 nodes of a new player's run.

signal tutorial_step_ready(step: Dictionary)
signal tutorial_completed()

# Tutorial persists across sessions via config file
var tutorial_done: bool = false
var current_step: int = 0

# Which combat number within this run (0-indexed)
var combats_seen: int = 0
var _active: bool = false

const CONFIG_PATH := "user://tutorial.cfg"

# Each step: { "id", "title", "text", "trigger", "highlight" }
# trigger: when to show this step
# highlight: optional node path hint for UI
const STEPS: Array = [
	# --- Node 1: First Combat (basics) ---
	{
		"id": "welcome",
		"title": "Добро пожаловать в Lexica Spire!",
		"text": "Это ваш первый бой. Вы играете картами, отвечая на задания по английскому.\nДавайте изучим основы!",
		"trigger": "combat_start_0",
		"highlight": "",
	},
	{
		"id": "energy",
		"title": "Энергия",
		"text": "У вас 3 Энергии за ход. Каждая карта стоит Энергию.\nСчётчик Энергии — в левом верхнем углу.",
		"trigger": "combat_start_0",
		"highlight": "energy",
	},
	{
		"id": "play_card",
		"title": "Розыгрыш карт",
		"text": "Нажмите на карту в руке, чтобы сыграть её.\nДля активации нужно ответить на задание по английскому!",
		"trigger": "combat_start_0",
		"highlight": "hand",
	},
	{
		"id": "challenge_intro",
		"title": "Языковые задания",
		"text": "Правильный ответ наносит урон или даёт блок.\nОТЛИЧНО — полный эффект. ОШИБКА — карта не сработает и вы получите 5 урона!",
		"trigger": "first_challenge",
		"highlight": "",
	},
	{
		"id": "enemy_intent",
		"title": "Намерение врага",
		"text": "Иконка над врагом показывает, что он сделает в следующий ход.\nМеч означает атаку. Планируйте защиту!",
		"trigger": "first_enemy_turn",
		"highlight": "enemy",
	},
	# --- Узел 2: Защита ---
	{
		"id": "block_intro",
		"title": "Блок и защита",
		"text": "Умения (синяя рамка) дают Блок.\nБлок поглощает входящий урон, но сбрасывается каждый ход.",
		"trigger": "combat_start_1",
		"highlight": "hand",
	},
	{
		"id": "end_turn",
		"title": "Конец хода",
		"text": "Когда закончите играть карты, нажмите «Конец хода» или клавишу [E].\nПосле этого враг выполнит своё действие.",
		"trigger": "combat_start_1",
		"highlight": "end_turn",
	},
	# --- Узел 3: Награды и карта ---
	{
		"id": "reward_intro",
		"title": "Награды за бой",
		"text": "После победы можно добавить новую карту в колоду.\nВыбирайте с умом — сфокусированная колода сильнее раздутой!",
		"trigger": "first_reward",
		"highlight": "",
	},
	{
		"id": "map_intro",
		"title": "Карта Шпиля",
		"text": "Карта показывает ваш путь через Шпиль.\nТипы узлов: Бой, Место отдыха, Магазин и другие.\nПланируйте маршрут к боссу!",
		"trigger": "map_after_combat_2",
		"highlight": "",
	},
	{
		"id": "tutorial_done",
		"title": "Вы готовы!",
		"text": "Вы знаете основы! Исследуйте Шпиль, собирайте мощные карты\nи осваивайте английский, чтобы победить Хранителя Времён!",
		"trigger": "map_after_combat_2",
		"highlight": "",
	},
]


func _ready() -> void:
	_load_state()


func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		tutorial_done = config.get_value("tutorial", "done", false)


func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "done", tutorial_done)
	config.save(CONFIG_PATH)


func is_active() -> bool:
	return _active and not tutorial_done


func start_tutorial() -> void:
	tutorial_done = false
	current_step = 0
	combats_seen = 0
	_active = true
	_save_state()


func reset_tutorial() -> void:
	tutorial_done = false
	current_step = 0
	combats_seen = 0
	_active = false
	_save_state()


func mark_done() -> void:
	tutorial_done = true
	_active = false
	_save_state()
	tutorial_completed.emit()


func on_new_run() -> void:
	if tutorial_done:
		_active = false
		return
	# First run ever => activate tutorial
	_active = true
	combats_seen = 0
	current_step = 0


## Call from combat_scene when combat starts
func on_combat_start() -> void:
	if not is_active():
		return
	var trigger := "combat_start_%d" % combats_seen
	_emit_steps_for_trigger(trigger)


## Call when the first challenge popup appears
func on_first_challenge() -> void:
	if not is_active():
		return
	_emit_steps_for_trigger("first_challenge")


## Call when enemy turn happens for the first time
func on_first_enemy_turn() -> void:
	if not is_active():
		return
	_emit_steps_for_trigger("first_enemy_turn")


## Call from combat_scene when reward screen shows
func on_reward_screen() -> void:
	if not is_active():
		return
	_emit_steps_for_trigger("first_reward")


## Call when combat ends (to track combat count)
func on_combat_end() -> void:
	if not is_active():
		return
	combats_seen += 1


## Call from map_scene when map loads
func on_map_loaded() -> void:
	if not is_active():
		return
	var trigger := "map_after_combat_%d" % combats_seen
	_emit_steps_for_trigger(trigger)

	# Check if tutorial is complete after last step
	if current_step >= STEPS.size():
		mark_done()


func get_pending_steps(trigger: String) -> Array:
	var result: Array = []
	for i in range(current_step, STEPS.size()):
		if STEPS[i]["trigger"] == trigger:
			result.append(STEPS[i])
	return result


func _emit_steps_for_trigger(trigger: String) -> void:
	while current_step < STEPS.size():
		var step: Dictionary = STEPS[current_step]
		if step["trigger"] != trigger:
			break
		tutorial_step_ready.emit(step)
		current_step += 1
