## 1v1 arena knock-off: scoring, respawns, and match win at 5 points.
extends Node

signal score_changed(player_score: int, enemy_score: int)
signal match_over(player_won: bool)

const WIN_SCORE: int = 5
const VOID_Y: float = -20.0
const RESPAWN_DELAY: float = 0.35

var player_score: int = 0
var enemy_score: int = 0

var _round_active: bool = true
var _handling_fall: bool = false

@onready var _player_spawn: Marker3D = $SpawnPoints/PlayerSpawn
@onready var _enemy_spawn: Marker3D = $SpawnPoints/EnemySpawn


func _ready() -> void:
	add_to_group("game_manager")
	call_deferred("_place_fighters_at_spawns")


func get_void_y() -> float:
	return VOID_Y


func is_round_active() -> bool:
	return _round_active and not _handling_fall


func get_player_spawn() -> Vector3:
	return _player_spawn.global_position


func get_enemy_spawn() -> Vector3:
	return _enemy_spawn.global_position


func report_player_fell() -> void:
	if not is_round_active():
		return
	_handling_fall = true
	enemy_score += 1
	print("Enemy scored!")
	_after_point()


func report_enemy_fell() -> void:
	if not is_round_active():
		return
	_handling_fall = true
	player_score += 1
	print("Player scored!")
	_after_point()


func _after_point() -> void:
	score_changed.emit(player_score, enemy_score)

	if player_score >= WIN_SCORE:
		_end_match(true)
	elif enemy_score >= WIN_SCORE:
		_end_match(false)
	else:
		_respawn_fighters()
		if RESPAWN_DELAY > 0.0:
			await get_tree().create_timer(RESPAWN_DELAY).timeout
		_handling_fall = false


func _end_match(player_won: bool) -> void:
	_round_active = false
	_handling_fall = false
	if player_won:
		print("You win!")
	else:
		print("You lose!")
	match_over.emit(player_won)


func _place_fighters_at_spawns() -> void:
	_respawn_fighters()


func _respawn_fighters() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player and player.has_method("arena_respawn"):
		player.arena_respawn(_player_spawn.global_position)

	var opponent := get_tree().get_first_node_in_group("arena_opponent") as RigidBody3D
	if opponent and opponent.has_method("arena_respawn"):
		opponent.arena_respawn(_enemy_spawn.global_position)
