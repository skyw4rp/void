## Arena HUD — weapon, score, and win/lose message.
extends CanvasLayer

@onready var _weapon_label: Label = $WeaponLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _match_label: Label = $MatchLabel


func _ready() -> void:
	_match_label.visible = false
	_update_score(0, 0)

	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.match_over.connect(_on_match_over)
		_on_score_changed(game_manager.player_score, game_manager.enemy_score)

	var weapon_manager := get_tree().get_first_node_in_group("weapon_manager")
	if weapon_manager and weapon_manager.has_signal("weapon_changed"):
		weapon_manager.weapon_changed.connect(_on_weapon_changed)
		_on_weapon_changed(weapon_manager.get_weapon_name())


func _on_weapon_changed(weapon_name: String) -> void:
	_weapon_label.text = "Weapon: %s" % weapon_name


func _on_score_changed(player_score: int, enemy_score: int) -> void:
	_update_score(player_score, enemy_score)


func _update_score(player_score: int, enemy_score: int) -> void:
	_score_label.text = "Player: %d | Enemy: %d" % [player_score, enemy_score]


func _on_match_over(player_won: bool) -> void:
	_match_label.visible = true
	if player_won:
		_match_label.text = "You Win!"
	else:
		_match_label.text = "You Lose!"
