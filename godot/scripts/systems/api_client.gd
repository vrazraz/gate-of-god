extends Node
## HTTP client for communicating with the FastAPI backend.
## Falls back to local validation when backend is unavailable.

signal request_completed(result: Dictionary)
signal request_failed(error: String)

const BASE_URL: String = "http://localhost:8000/api"

var _http: HTTPRequest
var _is_backend_available: bool = false


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.timeout = 5.0
	_check_backend()


func _check_backend() -> void:
	var check_http := HTTPRequest.new()
	add_child(check_http)
	check_http.timeout = 3.0
	check_http.request_completed.connect(_on_health_check.bind(check_http))
	var err := check_http.request("http://localhost:8000/health")
	if err != OK:
		_is_backend_available = false


func _on_health_check(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest) -> void:
	_is_backend_available = (result == HTTPRequest.RESULT_SUCCESS and response_code == 200)
	if _is_backend_available:
		print("[ApiClient] Backend is available")
	else:
		print("[ApiClient] Backend unavailable, using local fallback")
	http_node.queue_free()


func is_online() -> bool:
	return _is_backend_available


## Validate a player's answer to a challenge.
func validate_answer(data: Dictionary, callback: Callable) -> void:
	if not _is_backend_available:
		var result := _local_validate(data)
		callback.call(result)
		return

	var url := BASE_URL + "/validate-answer"
	var json_body := JSON.stringify(data)
	var headers := ["Content-Type: application/json"]

	var new_http := HTTPRequest.new()
	add_child(new_http)
	new_http.request_completed.connect(
		func(res: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			new_http.queue_free()
			if res == HTTPRequest.RESULT_SUCCESS and code == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				callback.call(parsed)
			else:
				callback.call(_local_validate(data))
	)
	new_http.request(url, headers, HTTPClient.METHOD_POST, json_body)


## Generate a challenge for a card.
func generate_challenge(data: Dictionary, callback: Callable) -> void:
	if not _is_backend_available:
		var result := _local_generate_challenge(data)
		callback.call(result)
		return

	var url := BASE_URL + "/generate-challenge"
	var json_body := JSON.stringify(data)
	var headers := ["Content-Type: application/json"]

	var new_http := HTTPRequest.new()
	add_child(new_http)
	new_http.request_completed.connect(
		func(res: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			new_http.queue_free()
			if res == HTTPRequest.RESULT_SUCCESS and code == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				callback.call(parsed)
			else:
				callback.call(_local_generate_challenge(data))
	)
	new_http.request(url, headers, HTTPClient.METHOD_POST, json_body)


## Local fallback: validate answer by exact match.
func _local_validate(data: Dictionary) -> Dictionary:
	var user_answer: String = data.get("user_answer", "").strip_edges().to_lower()
	var correct_answer: String = data.get("correct_answer", "").strip_edges().to_lower()
	var time_taken: float = data.get("time_taken", 10.0)
	var correct := (user_answer == correct_answer)

	var quality := "mistake"
	var quality_score := 0
	var effect_modifier := 0.0

	if correct:
		if time_taken < 2.0:
			quality = "perfect"
			quality_score = 5
			effect_modifier = 1.25
		elif time_taken <= 10.0:
			quality = "correct"
			quality_score = 4
			effect_modifier = 1.0
		else:
			quality = "slow"
			quality_score = 3
			effect_modifier = 0.75

	return {
		"correct": correct,
		"quality": quality,
		"quality_score": quality_score,
		"effect_modifier": effect_modifier,
		"feedback": {
			"message": "Отлично!" if quality == "perfect" else ("Верно!" if correct else "Неверно!"),
			"correct_answer": data.get("correct_answer", ""),
			"explanation": null if correct else "Правильный ответ: '%s'" % data.get("correct_answer", ""),
		},
		"spaced_repetition": {
			"word": data.get("word", ""),
			"next_review_days": 1.0,
			"easiness_factor": 2.5,
			"streak": 1 if correct else 0,
		},
		"curse_added": null if correct else {
			"type": "echo_of_typo",
			"source_word": data.get("word", ""),
			"intensity": 0,
		},
	}


## Challenge pool loaded from data/challenge_pool.json (supports hundreds of entries).
var _challenge_pool: Dictionary = {}
var _pool_loaded: bool = false


func _load_challenge_pool() -> void:
	if _pool_loaded:
		return
	var file := FileAccess.open("res://data/challenge_pool.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			_challenge_pool = parsed
	_pool_loaded = true


## Get or create a fixed challenge for a card (persists for the entire run).
## If enhanced is true, the challenge becomes multiple choice (easier).
func get_or_create_card_challenge(card_id: String, card_data: Dictionary, enhanced: bool = false) -> Dictionary:
	var stored := GameState.get_card_challenge(card_id)
	if not stored.is_empty():
		var challenge := stored.duplicate(true)
		# Reverse debuff: flip vocabulary/matching direction (RU→EN)
		var is_reversed: bool = GameState.has_meta("debuff_reverse")
		if is_reversed:
			challenge = _apply_reverse(challenge)
		# Enhanced: convert text to multiple choice
		if enhanced and challenge.get("input_type", "") == "text":
			challenge = _regenerate_as_multiple_choice(challenge)
		if not is_reversed and not enhanced:
			return stored
		return challenge

	# Generate a new challenge based on card's challenge config
	var data := {
		"card_id": card_id,
		"challenge_type": card_data.get("challenge", {}).get("type", "vocabulary"),
		"difficulty": card_data.get("challenge", {}).get("difficulty", GameState.cefr_level),
		"force_multiple_choice": enhanced,
		"match_pairs": card_data.get("challenge", {}).get("pairs", 0),
	}
	var challenge := _local_generate_challenge(data)
	GameState.set_card_challenge(card_id, challenge)
	# Apply reverse on-the-fly (don't save reversed version)
	if GameState.has_meta("debuff_reverse"):
		var reversed := challenge.duplicate(true)
		reversed = _apply_reverse(reversed)
		if enhanced and reversed.get("input_type", "") == "text":
			reversed = _regenerate_as_multiple_choice(reversed)
		return reversed
	return challenge


func _regenerate_as_multiple_choice(challenge: Dictionary) -> Dictionary:
	## Convert a text-input challenge into multiple choice on the fly.
	_load_challenge_pool()
	var ch_type: String = challenge.get("type", "vocabulary")

	if ch_type == "vocabulary":
		var correct: String = challenge.get("correct_answer", "")
		var pool: Array = _challenge_pool.get("vocabulary", [])
		var distractors: Array = []
		for entry in pool:
			if entry["answer"] != correct:
				distractors.append(entry["answer"])
			if distractors.size() >= 3:
				break
		var options: Array = [correct] + distractors.slice(0, 3)
		options.shuffle()
		var labels: Array = ["a", "b", "c", "d"]
		var correct_idx: int = options.find(correct)
		var formatted := []
		for i in range(options.size()):
			formatted.append({"id": labels[i], "text": options[i]})
		challenge["input_type"] = "multiple_choice"
		challenge["options"] = formatted
		challenge["correct_option"] = labels[correct_idx]
		challenge.erase("correct_answer")
	elif ch_type == "grammar":
		var correct: String = challenge.get("correct_answer", "")
		var pool: Array = _challenge_pool.get("grammar", [])
		var distractors: Array = []
		for entry in pool:
			if entry["answer"] != correct:
				distractors.append(entry["answer"])
			if distractors.size() >= 3:
				break
		var options: Array = [correct] + distractors.slice(0, 3)
		options.shuffle()
		var labels: Array = ["a", "b", "c", "d"]
		var correct_idx: int = options.find(correct)
		var formatted := []
		for i in range(options.size()):
			formatted.append({"id": labels[i], "text": options[i]})
		challenge["input_type"] = "multiple_choice"
		challenge["options"] = formatted
		challenge["correct_option"] = labels[correct_idx]
		challenge.erase("correct_answer")

	return challenge


## Reverse debuff: flip vocabulary/matching so player translates RU→EN.
func _apply_reverse(challenge: Dictionary) -> Dictionary:
	var ch_type: String = challenge.get("type", "")

	if ch_type == "vocabulary":
		var input_type: String = challenge.get("input_type", "text")
		if input_type == "text":
			# Text: question shows Russian word, answer is English
			var en_word: String = challenge.get("word", "")
			var ru_answer: String = challenge.get("correct_answer", "")
			if en_word != "" and ru_answer != "":
				challenge["question"] = "Переведите слово '%s':" % ru_answer
				challenge["correct_answer"] = en_word
				challenge["word"] = ru_answer
		elif input_type == "multiple_choice":
			# MC: question shows Russian word, options are English words
			_load_challenge_pool()
			var en_word: String = challenge.get("word", "")
			# Find the Russian translation for this word
			var ru_word := ""
			var pool: Array = _challenge_pool.get("vocabulary", [])
			for entry in pool:
				if entry["word"] == en_word:
					ru_word = entry["answer"]
					break
			if ru_word == "":
				return challenge
			# Build English distractors
			var distractors: Array = []
			for entry in pool:
				if entry["word"] != en_word:
					distractors.append(entry["word"])
				if distractors.size() >= 3:
					break
			var options: Array = [en_word] + distractors.slice(0, 3)
			options.shuffle()
			var labels: Array = ["a", "b", "c", "d"]
			var correct_idx: int = options.find(en_word)
			var formatted := []
			for i in range(options.size()):
				formatted.append({"id": labels[i], "text": options[i]})
			challenge["question"] = "Что означает слово '%s'?" % ru_word
			challenge["options"] = formatted
			challenge["correct_option"] = labels[correct_idx]
			challenge["word"] = ru_word

	elif ch_type == "matching":
		# Swap en/ru in all pairs (left shows Russian, right shows English)
		var pairs: Array = challenge.get("pairs", [])
		for i in range(pairs.size()):
			var p: Dictionary = pairs[i]
			var en_val: String = p.get("en", "")
			var ru_val: String = p.get("ru", "")
			pairs[i] = {"en": ru_val, "ru": en_val}
		challenge["pairs"] = pairs
		challenge["question"] = "Составьте пары: перевод → слово"

	return challenge


## Local fallback: generate a challenge from the pool (vocabulary or grammar).
func _local_generate_challenge(data: Dictionary) -> Dictionary:
	_load_challenge_pool()

	var challenge_type: String = data.get("challenge_type", "vocabulary")
	if challenge_type == "matching":
		return _generate_matching_challenge(data)
	elif challenge_type == "grammar" or challenge_type == "conjugation":
		return _generate_grammar_challenge(data)
	return _generate_vocabulary_challenge(data)


func _generate_vocabulary_challenge(data: Dictionary) -> Dictionary:
	var pool: Array = _challenge_pool.get("vocabulary", [])
	if pool.is_empty():
		pool = [{"word": "happy", "answer": "Счастливый", "distractors": ["Грустный", "Злой", "Уставший"], "difficulty": "A1"}]

	var entry: Dictionary = pool[randi() % pool.size()]
	var word: String = entry["word"]
	var correct_def: String = entry["answer"]

	# Use entry-specific distractors, or pick random ones from pool
	var distractors: Array = entry.get("distractors", []).duplicate()
	if distractors.size() < 3:
		for other in pool:
			if other["word"] != word and other["answer"] not in distractors and other["answer"] != correct_def:
				distractors.append(other["answer"])
			if distractors.size() >= 3:
				break

	distractors.shuffle()
	var options: Array = [correct_def] + distractors.slice(0, 3)
	options.shuffle()
	var correct_idx: int = options.find(correct_def)
	var labels: Array = ["a", "b", "c", "d"]

	var formatted_options := []
	for i in range(options.size()):
		formatted_options.append({"id": labels[i], "text": options[i]})

	# Default: text input. Enhanced mode overrides to multiple choice.
	var use_choices: bool = data.get("force_multiple_choice", false)

	if use_choices:
		return {
			"challenge_id": "ch_local_%d" % randi(),
			"type": "vocabulary",
			"question": "Что означает слово '%s'?" % word,
			"input_type": "multiple_choice",
			"options": formatted_options,
			"correct_option": labels[correct_idx],
			"word": word,
			"time_limit": 12,
		}
	else:
		return {
			"challenge_id": "ch_local_%d" % randi(),
			"type": "vocabulary",
			"question": "Переведите слово '%s':" % word,
			"input_type": "text",
			"correct_answer": correct_def,
			"word": word,
			"time_limit": 15,
		}


func _generate_grammar_challenge(data: Dictionary) -> Dictionary:
	var pool: Array = _challenge_pool.get("grammar", [])
	if pool.is_empty():
		# Minimal fallback
		return _generate_vocabulary_challenge(data)

	var entry: Dictionary = pool[randi() % pool.size()]

	return {
		"challenge_id": "ch_local_%d" % randi(),
		"type": "grammar",
		"question": entry["prompt"],
		"input_type": "text",
		"correct_answer": entry["answer"],
		"word": entry.get("topic", "grammar"),
		"time_limit": 20,
	}


func _generate_matching_challenge(data: Dictionary) -> Dictionary:
	var pair_count: int = data.get("match_pairs", 4)
	var difficulty: String = data.get("difficulty", "A1")
	var pool: Array = _challenge_pool.get("matching", [])

	# Filter by size, then by difficulty
	var candidates: Array = []
	for group in pool:
		if group.get("size", 0) == pair_count:
			candidates.append(group)

	# Prefer matching difficulty
	var best: Array = []
	for c in candidates:
		if c.get("difficulty", "A1") == difficulty:
			best.append(c)
	if best.is_empty():
		best = candidates

	if best.is_empty():
		# Fallback: build from vocabulary pool
		return _generate_matching_from_vocabulary(pair_count)

	var group: Dictionary = best[randi() % best.size()]
	var pairs: Array = group.get("pairs", []).duplicate(true)

	return {
		"challenge_id": "ch_match_%d" % randi(),
		"type": "matching",
		"question": "Составьте пары: слово → перевод",
		"input_type": "matching",
		"pairs": pairs,
		"time_limit": 8 + pair_count * 3,
	}


func _generate_matching_from_vocabulary(pair_count: int) -> Dictionary:
	var vocab_pool: Array = _challenge_pool.get("vocabulary", []).duplicate()
	vocab_pool.shuffle()

	var pairs: Array = []
	for i in range(mini(pair_count, vocab_pool.size())):
		pairs.append({
			"en": vocab_pool[i]["word"],
			"ru": vocab_pool[i]["answer"],
		})

	return {
		"challenge_id": "ch_match_%d" % randi(),
		"type": "matching",
		"question": "Составьте пары: слово → перевод",
		"input_type": "matching",
		"pairs": pairs,
		"time_limit": 8 + pair_count * 3,
	}
