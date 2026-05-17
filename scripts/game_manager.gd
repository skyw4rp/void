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
const VOID_Y: float = -20.0
const COUNTDOWN_STEP_SEC: float = 1.0
const FIGHT_TEXT_SEC: float = 0.7
const KILL_DEATH_VIEW_SEC: float = 1.2
const VOID_FALL_DELAY_SEC: float = 2.0
const VOID_EFFECT_VIEW_SEC: float = 1.2

var player_score: int = 0
var enemy_score: int = 0
var state: RoundState = RoundState.COUNTDOWN

var _handling_round_end: bool = false

@onready var _player_spawn: Marker3D = $SpawnPoints/PlayerSpawn
@onready var _enemy_spawn: Marker3D = $SpawnPoints/EnemySpawn


func _ready() -> void:
	add_to_group("game_manager")
	call_deferred("_begin_match")


func get_void_y() -> float:
	return VOID_Y


func is_fighting() -> bool:
	return state == RoundState.FIGHTING


func is_round_active() -> bool:
	return is_fighting()


func get_player_spawn() -> Vector3:
	return _player_spawn.global_position


func get_enemy_spawn() -> Vector3:
	return _enemy_spawn.global_position


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
	enemy_score += 1
	print("Enemy scored!")
	death_message_hidden.emit()
	void_overlay_changed.emit(false, true)
	await _finish_round_after_score()


func finish_enemy_void_death() -> void:
	if not _handling_round_end:
		return
	player_score += 1
	print("Player scored!")
	death_message_hidden.emit()
	void_overlay_changed.emit(false, false)
	await _finish_round_after_score()


## Called after corpse spawn — delayed score and countdown so the launch is visible.
func on_health_death(player_died: bool) -> void:
	if _handling_round_end:
		return
	_handling_round_end = true
	state = RoundState.ROUND_OVER

	if player_died:
		death_message_changed.emit("You were eliminated!")
	else:
		death_message_changed.emit("Enemy eliminated!")

	await get_tree().create_timer(KILL_DEATH_VIEW_SEC).timeout
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

	await get_tree().create_timer(VOID_FALL_DELAY_SEC).timeout

	var effect_pos: Vector3 = _fighter_void_effect_position(player)
	VoidDeathEffect.play_at(get_tree().current_scene, effect_pos, GameBalance.VOID_DEATH_STYLE)
	if player and player.has_method("end_void_dying"):
		player.call("end_void_dying")

	await get_tree().create_timer(VOID_EFFECT_VIEW_SEC).timeout
	await finish_player_void_death()


func _run_enemy_void_death_sequence() -> void:
	_handling_round_end = true
	state = RoundState.ROUND_OVER
	death_message_changed.emit("ENEMY LOST TO THE VOID")
	void_overlay_changed.emit(true, false)

	var opponent: Node = _get_opponent()
	if opponent and opponent.has_method("begin_void_dying"):
		opponent.call("begin_void_dying")

	await get_tree().create_timer(VOID_FALL_DELAY_SEC).timeout

	var effect_pos: Vector3 = _fighter_void_effect_position(opponent)
	VoidDeathEffect.play_at(get_tree().current_scene, effect_pos, GameBalance.VOID_DEATH_STYLE)
	if opponent and opponent.has_method("end_void_dying"):
		opponent.call("end_void_dying")

	await get_tree().create_timer(VOID_EFFECT_VIEW_SEC).timeout
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
	_clear_projectiles()
	_clear_corpses()
	_clear_void_effects()
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


func _respawn_fighters() -> void:
	var player := _get_player() as CharacterBody3D
	if player:
		player.global_transform = _player_spawn.global_transform
		player.velocity = Vector3.ZERO
		if player.has_method("arena_respawn"):
			player.arena_respawn(_player_spawn.global_position)
		_reset_combat_stats(player)

	var opponent := _get_opponent() as RigidBody3D
	if opponent:
		opponent.global_transform = _enemy_spawn.global_transform
		opponent.linear_velocity = Vector3.ZERO
		opponent.angular_velocity = Vector3.ZERO
		if opponent.has_method("arena_respawn"):
			opponent.arena_respawn(_enemy_spawn.global_position)
		_reset_combat_stats(opponent)


func _reset_combat_stats(fighter: Node) -> void:
	var stats: CombatStats = fighter.get_node_or_null("CombatStats") as CombatStats
	if stats:
		stats.reset_combat_stats()
