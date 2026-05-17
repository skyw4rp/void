## 1v1 arena knock-off: scoring, round states, countdown, and match win at 5 points.
extends Node

const VoidDeathEffect = preload("res://scripts/effects/void_death_effect.gd")

enum RoundState { COUNTDOWN, FIGHTING, ROUND_OVER, MATCH_OVER }

signal score_changed(player_score: int, enemy_score: int)
signal match_over(player_won: bool)
signal countdown_text_changed(text: String)
signal countdown_hidden()
signal death_message_changed(text: String)
signal death_message_hidden()
signal void_overlay_changed(active: bool, player_fell: bool)

const WIN_SCORE: int = 5
const VOID_Y: float = GameBalance.VOID_DEATH_Y
const COUNTDOWN_STEP_SEC: float = 1.0
const FIGHT_TEXT_SEC: float = 0.7
const VOID_FALL_DELAY_SEC: float = 2.0
const VOID_EFFECT_VIEW_SEC: float = 1.2

var player_score: int = 0
var enemy_score: int = 0
var state: RoundState = RoundState.COUNTDOWN

var _handling_round_end: bool = false
var _arena_generator: ArenaGenerator


func _ready() -> void:
	add_to_group("game_manager")
	call_deferred("_begin_match")


func get_void_y() -> float:
	if _arena_generator:
		return _arena_generator.get_void_y()
	return VOID_Y


func is_fighting() -> bool:
	return state == RoundState.FIGHTING


func is_round_active() -> bool:
	return is_fighting()


func get_arena_generator() -> ArenaGenerator:
	return _arena_generator


func get_player_spawn() -> Vector3:
	if _arena_generator:
		return _arena_generator.get_player_spawn_position()
	return Vector3(0.0, 1.1, 10.0)


func get_enemy_spawn() -> Vector3:
	if _arena_generator:
		return _arena_generator.get_enemy_spawn_position()
	return Vector3(0.0, 1.0, -10.0)


func report_player_void_fall() -> void:
	if not is_fighting() or _handling_round_end:
		return
	_run_player_void_death_sequence()


func report_enemy_void_fall() -> void:
	if not is_fighting() or _handling_round_end:
		return
	_run_enemy_void_death_sequence()


func finish_player_void_death() -> void:
	if not _handling_round_end:
		return
	print("Death sequence finished, scoring")
	enemy_score += 1
	print("Enemy scored!")
	death_message_hidden.emit()
	void_overlay_changed.emit(false, true)
	await _finish_round_after_score()


func finish_enemy_void_death() -> void:
	if not _handling_round_end:
		return
	print("Death sequence finished, scoring")
	player_score += 1
	print("Player scored!")
	death_message_hidden.emit()
	void_overlay_changed.emit(false, false)
	await _finish_round_after_score()


func on_health_death(player_died: bool, heavy_death: bool = false) -> void:
	if _handling_round_end:
		return
	_handling_round_end = true
	state = RoundState.ROUND_OVER

	if player_died:
		if heavy_death:
			death_message_changed.emit("YOU WERE OBLITERATED")
		else:
			death_message_changed.emit("You were eliminated!")
	else:
		death_message_changed.emit("Enemy eliminated!")

	var view_sec: float = (
		GameBalance.gib_collapse_score_sec() if heavy_death else GameBalance.KILL_DEATH_VIEW_SEC
	)
	await get_tree().create_timer(view_sec).timeout
	if heavy_death:
		print("Gib collapse finished")
	print("Death sequence finished, scoring")
	death_message_hidden.emit()

	if player_died:
		enemy_score += 1
		print("Enemy scored! (player killed)")
	else:
		player_score += 1
		print("Player scored! (enemy killed)")

	await _finish_round_after_score()


func _run_player_void_death_sequence() -> void:
	_handling_round_end = true
	state = RoundState.ROUND_OVER
	death_message_changed.emit("PLAYER LOST TO THE VOID")
	void_overlay_changed.emit(true, true)

	var player: Node = _get_player()
	if player and player.has_method("begin_void_dying"):
		player.call("begin_void_dying")

	if GameBalance.uses_void_gore_cinematic():
		await VoidGoreSequence.run(get_tree().current_scene, player, get_tree())
	else:
		await get_tree().create_timer(VOID_FALL_DELAY_SEC).timeout
		var effect_pos: Vector3 = _fighter_void_effect_position(player)
		VoidDeathEffect.play_at(get_tree().current_scene, effect_pos, GameBalance.VOID_DEATH_STYLE)
		await get_tree().create_timer(VOID_EFFECT_VIEW_SEC).timeout

	if player and player.has_method("end_void_dying"):
		player.call("end_void_dying")
	await finish_player_void_death()


func _run_enemy_void_death_sequence() -> void:
	_handling_round_end = true
	state = RoundState.ROUND_OVER
	death_message_changed.emit("ENEMY LOST TO THE VOID")
	void_overlay_changed.emit(true, false)

	var opponent: Node = _get_opponent()
	if opponent and opponent.has_method("begin_void_dying"):
		opponent.call("begin_void_dying")

	if GameBalance.uses_void_gore_cinematic():
		await VoidGoreSequence.run(get_tree().current_scene, opponent, get_tree())
	else:
		await get_tree().create_timer(VOID_FALL_DELAY_SEC).timeout
		var effect_pos: Vector3 = _fighter_void_effect_position(opponent)
		VoidDeathEffect.play_at(get_tree().current_scene, effect_pos, GameBalance.VOID_DEATH_STYLE)
		await get_tree().create_timer(VOID_EFFECT_VIEW_SEC).timeout

	if opponent and opponent.has_method("end_void_dying"):
		opponent.call("end_void_dying")
	await finish_enemy_void_death()


func _fighter_void_effect_position(fighter: Node) -> Vector3:
	if fighter is Node3D:
		return (fighter as Node3D).global_position
	return Vector3(0.0, VOID_Y - 4.0, 0.0)


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _get_opponent() -> Node:
	return get_tree().get_first_node_in_group("arena_opponent")


func _begin_match() -> void:
	player_score = 0
	enemy_score = 0
	state = RoundState.COUNTDOWN
	score_changed.emit(player_score, enemy_score)
	await _run_countdown()


func _finish_round_after_score() -> void:
	score_changed.emit(player_score, enemy_score)

	if player_score >= WIN_SCORE:
		_end_match(true)
		return
	if enemy_score >= WIN_SCORE:
		_end_match(false)
		return

	state = RoundState.ROUND_OVER
	await _run_countdown()
	_handling_round_end = false


func _run_countdown() -> void:
	if state == RoundState.MATCH_OVER:
		return

	print("Round countdown started")
	state = RoundState.COUNTDOWN
	await _generate_round_arena()
	_clear_projectiles()
	_clear_corpses()
	_clear_void_effects()
	_clear_gib_chunks()
	_clear_railgun_vfx()
	_clear_round_debris()
	_spawn_round_debris()
	death_message_hidden.emit()
	void_overlay_changed.emit(false, false)
	_respawn_fighters()

	var steps: Array[String] = ["3", "2", "1", "FIGHT!"]
	for step_text in steps:
		countdown_text_changed.emit(step_text)
		if step_text == "FIGHT!":
			print("FIGHT!")
		var wait_sec: float = FIGHT_TEXT_SEC if step_text == "FIGHT!" else COUNTDOWN_STEP_SEC
		await get_tree().create_timer(wait_sec).timeout

	countdown_hidden.emit()
	state = RoundState.FIGHTING


func _generate_round_arena() -> void:
	_arena_generator = get_tree().get_first_node_in_group("arena_generator") as ArenaGenerator
	if _arena_generator == null:
		push_warning("GameManager: ArenaGenerator not found.")
		return
	await _arena_generator.generate_round_arena_async()


func _end_match(player_won: bool) -> void:
	state = RoundState.MATCH_OVER
	_handling_round_end = false
	countdown_hidden.emit()
	death_message_hidden.emit()
	void_overlay_changed.emit(false, false)
	if player_won:
		print("You win!")
	else:
		print("You lose!")
	match_over.emit(player_won)


func _clear_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("projectile"):
		if node is Node:
			(node as Node).queue_free()


func _clear_corpses() -> void:
	for node in get_tree().get_nodes_in_group("corpse"):
		if node is Node:
			(node as Node).queue_free()


func _clear_void_effects() -> void:
	for node in get_tree().get_nodes_in_group("void_effect"):
		if node is Node:
			(node as Node).queue_free()
	for node in get_tree().get_nodes_in_group("void_fragment"):
		if node is Node:
			(node as Node).queue_free()
	for node in get_tree().get_nodes_in_group("gore_chunk"):
		if node is Node:
			(node as Node).queue_free()


func _clear_gib_chunks() -> void:
	for node in get_tree().get_nodes_in_group("gib_chunk"):
		if node is Node:
			(node as Node).queue_free()


func _clear_railgun_vfx() -> void:
	RailgunImpactFlash.clear_all(get_tree())
	RailgunImpactHole.clear_all(get_tree())
	RailgunPierceMark.clear_all(get_tree())


func _clear_round_debris() -> void:
	var spawner := _get_debris_spawner()
	if spawner and spawner.has_method("clear_debris"):
		spawner.call("clear_debris")


func _spawn_round_debris() -> void:
	var spawner := _get_debris_spawner()
	if spawner == null or not spawner.has_method("spawn_round_debris_for_generator"):
		return
	if _arena_generator:
		spawner.call("spawn_round_debris_for_generator", _arena_generator)


func _get_debris_spawner() -> Node:
	if _arena_generator:
		var child := _arena_generator.get_node_or_null("DebrisSpawner")
		if child:
			return child
	return get_tree().get_first_node_in_group("debris_spawner")


func _respawn_fighters() -> void:
	if _arena_generator == null:
		return

	var player := _get_player() as CharacterBody3D
	if player:
		player.global_transform = _arena_generator.get_player_spawn_transform()
		player.velocity = Vector3.ZERO
		if player.has_method("arena_respawn"):
			player.arena_respawn(_arena_generator.get_player_spawn_position())
		_reset_combat_stats(player)

	var opponent := _get_opponent() as RigidBody3D
	if opponent:
		opponent.global_transform = _arena_generator.get_enemy_spawn_transform()
		opponent.linear_velocity = Vector3.ZERO
		opponent.angular_velocity = Vector3.ZERO
		if opponent.has_method("arena_respawn"):
			opponent.arena_respawn(_arena_generator.get_enemy_spawn_position())
		if opponent.has_method("apply_arena_bounds_from_dict"):
			opponent.call(
				"apply_arena_bounds_from_dict", _arena_generator.get_current_arena_bounds()
			)
		_reset_combat_stats(opponent)


func _reset_combat_stats(fighter: Node) -> void:
	var stats: CombatStats = fighter.get_node_or_null("CombatStats") as CombatStats
	if stats:
		stats.reset_combat_stats()
