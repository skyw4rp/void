## Chamber ↔ arena scene flow (local MVP).
extends Node

const CHAMBER_SCENE: String = "res://scenes/chamber/gladiator_chamber.tscn"
const ARENA_SCENE: String = "res://scenes/arena/arena_match.tscn"

const RETURN_DELAY_SEC: float = 2.8

var return_pending: bool = false
var last_match_victory: bool = false
var transitioning: bool = false


func start_arena_match() -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file(ARENA_SCENE)


func return_to_chamber(player_won: bool) -> void:
	if transitioning:
		return
	last_match_victory = player_won
	return_pending = true
	transitioning = true
	get_tree().change_scene_to_file(CHAMBER_SCENE)


func consume_return_mood() -> int:
	if not return_pending:
		return 0
	return_pending = false
	return 1 if last_match_victory else -1
