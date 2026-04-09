extends Node
## Main combat state machine.
## Manages the flow: PLAYER_TURN -> play card -> CHALLENGE -> RESOLUTION -> ENEMY_TURN -> repeat.

signal combat_started()
signal combat_ended(victory: bool)
signal turn_started(turn_number: int)
signal player_turn_started()
signal enemy_turn_started()
signal challenge_requested(card_data: Dictionary)
signal challenge_resolved(result: Dictionary)
signal card_played(card_data: Dictionary)
signal player_status_changed()
signal enemy_status_changed()
signal enemy_action(action: Dictionary)
signal boss_phase_changed(phase: String)
signal great_exam_triggered(exam_data: Dictionary)
signal great_exam_resolved(success: bool)

enum CombatState {
	INACTIVE,
	PLAYER_TURN,
	CHALLENGE,
	RESOLUTION,
	ENEMY_TURN,
	GREAT_EXAM,
	VICTORY,
	DEFEAT,
}

var state: CombatState = CombatState.INACTIVE
var turn_number: int = 0
var enemy_data: Dictionary = {}
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_block: int = 0
var enemy_strength: int = 0
# Temporary enemy debuffs. Keys: "vulnerable", "weak" (turns remaining), "poison" (stacks).
var enemy_debuffs: Dictionary = {}
# ID of relic dropped by current enemy on victory ("" if none). Read by reward screen.
var last_dropped_relic: String = ""
var _current_card: Dictionary = {}
var _pending_challenge_result: Dictionary = {}
var next_card_enhanced: bool = false  # Power card buff: next card gets multiple choice

# Relic state
var _phonetic_ankh_used: bool = false

# Boss-specific state
var is_boss: bool = false
var boss_phase: String = "present"
var boss_phases: Array = []
var _boss_pattern_loops: int = 0
var _boss_action_index: int = 0
var _great_exam_triggered: bool = false

@onready var deck_manager: Node = $"../DeckManager"


func start_combat(enemy: Dictionary) -> void:
	enemy_data = enemy
	enemy_hp = enemy.get("hp", 45)
	enemy_max_hp = enemy_hp
	enemy_block = 0
	enemy_strength = 0
	enemy_debuffs.clear()
	last_dropped_relic = ""
	turn_number = 0
	next_card_enhanced = false
	state = CombatState.INACTIVE

	# Boss detection
	is_boss = enemy.has("ultimate")
	boss_phases = enemy.get("phases", [])
	boss_phase = "present"
	_boss_pattern_loops = 0
	_boss_action_index = 0
	_great_exam_triggered = false

	_phonetic_ankh_used = false

	GameState.reset_block()
	GameState.reset_energy()

	combat_started.emit()
	_start_player_turn()


func _start_player_turn() -> void:
	turn_number += 1
	state = CombatState.PLAYER_TURN

	GameState.reset_energy()
	GameState.reset_block()

	# Polyglot's Amulet: +1 Energy on first turn of combat
	if turn_number == 1 and GameState.has_relic("polyglots_amulet"):
		GameState.current_energy += 1
		GameState.energy_changed.emit(GameState.current_energy, GameState.max_energy)

	if deck_manager:
		deck_manager.draw_cards(5)

	turn_started.emit(turn_number)
	player_turn_started.emit()


func try_play_card(card_id: String) -> bool:
	if state != CombatState.PLAYER_TURN:
		return false

	var card_data := CardDatabase.get_card(card_id)
	if card_data.is_empty():
		return false

	var cost: int = card_data.get("cost", 1)

	# Tense Fog curse: Skill cards cost +1 Energy
	if card_data.get("type", "") == "skill" and "tense_fog" in GameState.deck:
		cost += 1

	if GameState.current_energy < cost:
		return false

	_current_card = card_data

	# Power cards: no challenge, instant effect (enhance next card)
	if card_data.get("type", "") == "power":
		GameState.spend_energy(cost)
		var effect: Dictionary = card_data.get("base_effect", {})
		if effect.get("enhance_next", false):
			next_card_enhanced = true
		# Draw cards if specified
		var draw_count: int = effect.get("draw", 0)
		if draw_count > 0 and deck_manager:
			deck_manager.draw_cards(draw_count)
		# Discard the power card
		if deck_manager:
			deck_manager.discard_card(card_id)
		state = CombatState.PLAYER_TURN
		card_played.emit(card_data)
		challenge_resolved.emit({"quality": "perfect", "correct": true})
		return true

	state = CombatState.CHALLENGE

	# UI handles challenge generation via this signal
	challenge_requested.emit(card_data)
	return true


func submit_challenge_answer(user_answer: String, correct_answer: String, time_taken: float) -> void:
	if state != CombatState.CHALLENGE:
		return

	var validate_data := {
		"player_id": GameState.player_id,
		"challenge_type": _current_card.get("challenge", {}).get("type", "vocabulary"),
		"challenge_id": "ch_%d" % randi(),
		"user_answer": user_answer,
		"correct_answer": correct_answer,
		"time_taken": time_taken,
		"word": "word",
		"card_id": _current_card.get("id", ""),
	}

	ApiClient.validate_answer(validate_data, _on_answer_validated)


func submit_matching_result(correct_matches: int, total_pairs: int, time_taken: float) -> void:
	if state != CombatState.CHALLENGE:
		return

	var quality := "mistake"
	var effect_modifier := 0.0
	var correct := correct_matches > 0

	if correct_matches == total_pairs and total_pairs > 0:
		if time_taken < 2.0 * total_pairs:
			quality = "perfect"
			effect_modifier = 1.25
		elif time_taken <= 6.0 * total_pairs:
			quality = "correct"
			effect_modifier = 1.0
		else:
			quality = "slow"
			effect_modifier = 0.75
	elif correct_matches > 0:
		quality = "correct"
		effect_modifier = 1.0

	var result := {
		"correct": correct,
		"quality": quality,
		"effect_modifier": effect_modifier,
		"correct_matches": correct_matches,
		"total_pairs": total_pairs,
	}

	_on_answer_validated(result)


func _on_answer_validated(result: Dictionary) -> void:
	_pending_challenge_result = result
	state = CombatState.RESOLUTION
	_resolve_card()


func _resolve_card() -> void:
	var result := _pending_challenge_result
	var correct: bool = result.get("correct", false)
	var quality: String = result.get("quality", "mistake")
	var effect_modifier: float = result.get("effect_modifier", 0.0)

	# Spend energy (including Tense Fog curse modifier)
	var cost: int = _current_card.get("cost", 1)
	if _current_card.get("type", "") == "skill" and "tense_fog" in GameState.deck:
		cost += 1
	GameState.spend_energy(cost)

	# Update run stats
	match quality:
		"perfect":
			GameState.run_stats["perfect_count"] += 1
			if GameState.has_relic("golden_dictionary"):
				GameState.heal(3)
		"correct":
			GameState.run_stats["correct_count"] += 1
		"mistake":
			GameState.run_stats["mistake_count"] += 1
			# Take self-damage on mistake
			GameState.take_damage(5)

	# Matching cards: always apply (damage is per correct match)
	var is_matching: bool = _current_card.get("base_effect", {}).has("damage_per_match")
	if is_matching:
		_apply_card_effect(effect_modifier)
	elif correct:
		_apply_card_effect(effect_modifier)
	elif not correct and not _phonetic_ankh_used and GameState.has_relic("phonetic_ankh"):
		# Phonetic Ankh: first mistake per combat doesn't fizzle
		_phonetic_ankh_used = true
		_apply_card_effect(0.75)
	# else: card fizzles

	GameState.run_stats["cards_played"] += 1

	challenge_resolved.emit(result)
	card_played.emit(_current_card)

	# Discard the card
	if deck_manager:
		deck_manager.discard_card(_current_card.get("id", ""))

	_current_card = {}
	_pending_challenge_result = {}

	# Check for victory
	if enemy_hp <= 0:
		_on_victory()
		return

	# Check for defeat
	if GameState.current_hp <= 0:
		_on_defeat()
		return

	# Check for boss Great Exam trigger
	if is_boss and not _great_exam_triggered:
		if _check_great_exam_trigger():
			return

	state = CombatState.PLAYER_TURN


func _apply_card_effect(modifier: float) -> void:
	var effect: Dictionary = _current_card.get("base_effect", {})

	# Matching cards: damage per correct match
	var damage_per_match: int = effect.get("damage_per_match", 0)
	if damage_per_match > 0:
		var correct_matches: int = _pending_challenge_result.get("correct_matches", 0)
		for i in range(correct_matches):
			_deal_damage_to_enemy(damage_per_match)
	else:
		# Normal damage
		var base_damage: int = effect.get("damage", 0)
		if base_damage > 0:
			# Comparative Slash: bonus damage per player block
			var bonus_per_block: int = effect.get("bonus_per_block", 0)
			if bonus_per_block > 0:
				base_damage += bonus_per_block * GameState.block

			var hits: int = effect.get("hits", 1)
			for i in range(hits):
				var final_damage := int(base_damage * modifier)
				_deal_damage_to_enemy(final_damage)

	# Block
	var base_block: int = effect.get("block", 0)
	if base_block > 0:
		var final_block := int(base_block * modifier)
		GameState.gain_block(final_block)

	# Draw
	var draw: int = effect.get("draw", 0)
	if draw > 0 and deck_manager:
		deck_manager.draw_cards(draw)

	# Discard (Synonym Swap)
	var discard_count: int = effect.get("discard", 0)
	if discard_count > 0 and deck_manager:
		# Discard random cards from hand
		for _i in range(discard_count):
			var current_hand: Array = deck_manager.get_hand()
			if current_hand.is_empty():
				break
			var random_idx: int = randi() % current_hand.size()
			deck_manager.discard_card(current_hand[random_idx])

	# Enemy debuffs (Vulnerable / Weak: flat duration; Poison: stacks scale with quality)
	var vuln_turns: int = effect.get("apply_vulnerable", 0)
	if vuln_turns > 0:
		apply_vulnerable_to_enemy(vuln_turns)

	var weak_turns: int = effect.get("apply_weak", 0)
	if weak_turns > 0:
		apply_weak_to_enemy(weak_turns)

	var poison_stacks: int = effect.get("apply_poison", 0)
	if poison_stacks > 0:
		var final_stacks := int(round(poison_stacks * modifier))
		if final_stacks > 0:
			apply_poison_to_enemy(final_stacks)


func _deal_damage_to_enemy(damage: int) -> void:
	var modified := damage
	# Vulnerable: enemy takes +50% damage.
	if int(enemy_debuffs.get("vulnerable", 0)) > 0:
		modified = int(round(damage * 1.5))
	var actual: int = max(0, modified - enemy_block)
	enemy_block = max(0, enemy_block - modified) as int
	enemy_hp = max(0, enemy_hp - actual) as int


# --- Enemy debuff helpers (Vulnerable, Weak, Poison) ---

func apply_vulnerable_to_enemy(turns: int) -> void:
	var current: int = int(enemy_debuffs.get("vulnerable", 0))
	enemy_debuffs["vulnerable"] = max(current, turns)
	enemy_status_changed.emit()


func apply_weak_to_enemy(turns: int) -> void:
	var current: int = int(enemy_debuffs.get("weak", 0))
	enemy_debuffs["weak"] = max(current, turns)
	enemy_status_changed.emit()


func apply_poison_to_enemy(stacks: int) -> void:
	# Poison stacks add up.
	var current: int = int(enemy_debuffs.get("poison", 0))
	enemy_debuffs["poison"] = current + stacks
	enemy_status_changed.emit()


func _tick_enemy_debuffs() -> void:
	# Tick Vulnerable / Weak at end of enemy turn.
	var changed := false
	for key in ["vulnerable", "weak"]:
		if not enemy_debuffs.has(key):
			continue
		var remaining: int = int(enemy_debuffs[key]) - 1
		if remaining <= 0:
			enemy_debuffs.erase(key)
		else:
			enemy_debuffs[key] = remaining
		changed = true
	if changed:
		enemy_status_changed.emit()


func end_player_turn() -> void:
	if state != CombatState.PLAYER_TURN:
		return

	# Discard remaining hand
	if deck_manager:
		deck_manager.discard_hand()

	# Tick down player debuffs (Confusion / Silence / Reverse).
	# Duration N = N full player turns; debuff expires after the Nth end-turn.
	_tick_player_debuffs()

	_start_enemy_turn()


const PLAYER_DEBUFF_KEYS := ["debuff_confusion", "debuff_silence", "debuff_reverse"]

func _tick_player_debuffs() -> void:
	var changed := false
	for key in PLAYER_DEBUFF_KEYS:
		if not GameState.has_meta(key):
			continue
		var remaining: int = int(GameState.get_meta(key)) - 1
		if remaining <= 0:
			GameState.remove_meta(key)
		else:
			GameState.set_meta(key, remaining)
		changed = true
	if changed:
		player_status_changed.emit()


func _start_enemy_turn() -> void:
	state = CombatState.ENEMY_TURN
	enemy_block = 0

	# Poison: damage at start of enemy turn, then -1 stack.
	var poison: int = int(enemy_debuffs.get("poison", 0))
	if poison > 0:
		enemy_hp = max(0, enemy_hp - poison)
		var remaining := poison - 1
		if remaining <= 0:
			enemy_debuffs.erase("poison")
		else:
			enemy_debuffs["poison"] = remaining
		enemy_status_changed.emit()
		if enemy_hp <= 0:
			_on_victory()
			return

	enemy_turn_started.emit()

	_execute_enemy_action()


func _execute_enemy_action() -> void:
	var pattern: Array = enemy_data.get("ai_pattern", [])
	if pattern.is_empty():
		_start_player_turn()
		return

	if is_boss:
		_execute_boss_turn(pattern)
	else:
		_execute_single_action(pattern)


func _execute_single_action(pattern: Array) -> void:
	var pattern_idx := (turn_number - 1) % pattern.size()
	var action: Dictionary = pattern[pattern_idx]
	_apply_enemy_action(action, 0)

	enemy_action.emit(action)

	if GameState.current_hp <= 0:
		_on_defeat()
		return

	_tick_enemy_debuffs()
	_start_player_turn()


func _execute_boss_turn(pattern: Array) -> void:
	# Boss performs one action per turn from pattern, cycling through
	var action: Dictionary = pattern[_boss_action_index]
	var damage_bonus: int = _boss_pattern_loops * 2

	_apply_enemy_action(action, damage_bonus)

	# Advance boss action index
	_boss_action_index += 1
	if _boss_action_index >= pattern.size():
		_boss_action_index = 0
		_boss_pattern_loops += 1

	enemy_action.emit(action)

	if GameState.current_hp <= 0:
		_on_defeat()
		return

	_tick_enemy_debuffs()
	_start_player_turn()


func _apply_enemy_action(action: Dictionary, damage_bonus: int) -> void:
	var action_type: String = action.get("action", "attack")

	match action_type:
		"attack":
			var damage: int = action.get("value", 5) + damage_bonus + enemy_strength
			# Weak: enemy attacks deal -25% damage.
			if int(enemy_debuffs.get("weak", 0)) > 0:
				damage = int(round(damage * 0.75))
			var hits: int = action.get("hits", 1)
			for i in range(hits):
				GameState.take_damage(damage)
			# Boss compound action: attack can also apply debuff
			if action.has("debuff"):
				_apply_debuff_to_player(action.get("debuff", ""), action.get("debuff_duration", 1))
		"debuff":
			var debuff_type: String = action.get("type", "confusion")
			var duration: int = action.get("duration", 2)
			_apply_debuff_to_player(debuff_type, duration)
		"buff":
			var buff_type: String = action.get("type", "")
			if buff_type == "block":
				enemy_block += action.get("value", 0)
			elif buff_type == "strength":
				enemy_strength += action.get("value", 0)
			# Handle Temporal Shift special
			if action.get("special", "") == "temporal_shift":
				_advance_boss_phase()
		"curse":
			var count: int = action.get("count", 1)
			_add_curses_to_player(count)


func _apply_debuff_to_player(debuff_type: String, duration: int) -> void:
	# Store debuffs on GameState for future use
	if debuff_type == "confusion":
		# Confusion: typos in challenge text (visual effect for UI)
		GameState.set_meta("debuff_confusion", duration)
	elif debuff_type == "silence":
		# Silence: audio challenges disabled
		GameState.set_meta("debuff_silence", duration)
	elif debuff_type == "reverse":
		# Reverse: vocabulary challenges flip direction (RU→EN instead of EN→RU)
		GameState.set_meta("debuff_reverse", duration)


func _add_curses_to_player(count: int) -> void:
	# Add curse cards to player's deck
	var curse_ids := ["echo_of_typo", "tense_fog"]
	for i in range(count):
		var curse_id: String = curse_ids[randi() % curse_ids.size()]
		GameState.deck.append(curse_id)
		if GameState.has_meta("curses"):
			var curses: Array = GameState.get_meta("curses")
			curses.append(curse_id)
			GameState.set_meta("curses", curses)
		else:
			GameState.set_meta("curses", [curse_id])


func _advance_boss_phase() -> void:
	if boss_phases.is_empty():
		return
	var current_idx := boss_phases.find(boss_phase)
	var next_idx := (current_idx + 1) % boss_phases.size()
	boss_phase = boss_phases[next_idx]
	boss_phase_changed.emit(boss_phase)


func _on_victory() -> void:
	state = CombatState.VICTORY
	GameState.run_stats["enemies_killed"] += 1

	# Award loot
	var loot: Dictionary = enemy_data.get("loot", {})

	if is_boss:
		# Boss gives flat coin amount
		var coins: int = loot.get("coins", 100)
		GameState.gain_gold(coins)
		# Award relic
		var relic_id: String = loot.get("relic", "")
		if relic_id != "" and not GameState.has_relic(relic_id):
			GameState.add_relic(relic_id)
			last_dropped_relic = relic_id
	else:
		# Regular enemy gives coins in range
		var coins_range: Array = loot.get("coins", [20, 30])
		if coins_range.size() >= 2:
			var gold_reward := randi_range(coins_range[0], coins_range[1])
			GameState.gain_gold(gold_reward)

		# Elite enemies drop a random relic the player doesn't already own.
		if enemy_data.get("is_elite", false):
			var chance: float = float(loot.get("relic_chance", 1.0))
			if randf() <= chance:
				var dropped := _pick_random_relic_for_player()
				if dropped != "":
					GameState.add_relic(dropped)
					last_dropped_relic = dropped

	combat_ended.emit(true)


func _pick_random_relic_for_player() -> String:
	var available: Array = []
	for relic in RelicDatabase.get_all_relics().values():
		var rid: String = relic.get("id", "")
		if rid == "":
			continue
		# Skip relics already owned, and skip the boss-tier relic.
		if GameState.has_relic(rid):
			continue
		if relic.get("rarity", "") == "boss":
			continue
		available.append(rid)
	if available.is_empty():
		return ""
	return available[randi() % available.size()]


func _on_defeat() -> void:
	state = CombatState.DEFEAT
	combat_ended.emit(false)


func get_enemy_intent() -> Dictionary:
	var pattern: Array = enemy_data.get("ai_pattern", [])
	if pattern.is_empty():
		return {}

	if is_boss:
		var intent: Dictionary = pattern[_boss_action_index].duplicate()
		# Show scaled damage including strength
		var damage_bonus: int = _boss_pattern_loops * 2
		if intent.has("value") and intent.get("action", "") == "attack":
			intent["value"] = intent["value"] + damage_bonus + enemy_strength
		return intent
	else:
		var pattern_idx := (turn_number - 1) % pattern.size()
		var intent: Dictionary = pattern[pattern_idx].duplicate()
		# Show damage including strength
		if intent.has("value") and intent.get("action", "") == "attack":
			intent["value"] = intent["value"] + enemy_strength
		return intent


# --- Boss: The Great Exam ---

func _check_great_exam_trigger() -> bool:
	var ultimate: Dictionary = enemy_data.get("ultimate", {})
	if ultimate.is_empty():
		return false

	var trigger_percent: float = ultimate.get("trigger_hp_percent", 0.25)
	var hp_ratio: float = float(enemy_hp) / float(enemy_max_hp)

	if hp_ratio <= trigger_percent:
		_great_exam_triggered = true
		_start_great_exam()
		return true
	return false


func _start_great_exam() -> void:
	state = CombatState.GREAT_EXAM
	var ultimate: Dictionary = enemy_data.get("ultimate", {})

	# Boss gains block
	enemy_block += ultimate.get("block", 30)

	# Prepare exam challenge data
	var exam_data := {
		"name": ultimate.get("name", "The Great Exam"),
		"time_limit": ultimate.get("time_limit", 45),
		"boss_phase": boss_phase,
		"success_damage": ultimate.get("success_damage", 25),
		"failure_damage": ultimate.get("failure_damage", 20),
		"failure_curses": ultimate.get("failure_curses", 3),
	}

	great_exam_triggered.emit(exam_data)


func resolve_great_exam(success: bool) -> void:
	var ultimate: Dictionary = enemy_data.get("ultimate", {})

	if success:
		# Deal damage to boss
		var exam_damage: int = ultimate.get("success_damage", 25)
		_deal_damage_to_enemy(exam_damage)
		# Remove player debuffs
		if GameState.has_meta("debuff_confusion"):
			GameState.remove_meta("debuff_confusion")
		if GameState.has_meta("debuff_silence"):
			GameState.remove_meta("debuff_silence")
		if GameState.has_meta("debuff_reverse"):
			GameState.remove_meta("debuff_reverse")
	else:
		# Player takes damage
		var fail_damage: int = ultimate.get("failure_damage", 20)
		GameState.take_damage(fail_damage)
		# Add curses
		var curse_count: int = ultimate.get("failure_curses", 3)
		_add_curses_to_player(curse_count)

	great_exam_resolved.emit(success)

	# Check victory/defeat after exam
	if enemy_hp <= 0:
		_on_victory()
		return
	if GameState.current_hp <= 0:
		_on_defeat()
		return

	state = CombatState.PLAYER_TURN
