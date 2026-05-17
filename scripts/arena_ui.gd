## Arena HUD — weapon, score, combat stats, countdown, and win/lose message.
extends CanvasLayer

@onready var _weapon_label: Label = $WeaponLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _player_stats_label: Label = $PlayerStatsLabel
@onready var _enemy_stats_label: Label = $EnemyStatsLabel
@onready var _match_label: Label = $MatchLabel
@onready var _countdown_label: Label = $CountdownLabel
@onready var _death_label: Label = $DeathLabel
@onready var _void_overlay: ColorRect = $VoidOverlay


func _ready() -> void:
	_match_label.visible = false
	_countdown_label.visible = false
	_death_label.visible = false
	_void_overlay.visible = false
	_update_score(0, 0)
	_update_player_stats(100, 100)
	_update_enemy_stats(100, 100)

	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.match_over.connect(_on_match_over)
		game_manager.countdown_text_changed.connect(_on_countdown_text)
		game_manager.countdown_hidden.connect(_on_countdown_hidden)
		game_manager.death_message_changed.connect(_on_death_message)
		game_manager.death_message_hidden.connect(_on_death_message_hidden)
		game_manager.void_overlay_changed.connect(_on_void_overlay_changed)
		_on_score_changed(game_manager.player_score, game_manager.enemy_score)

	var weapon_manager := get_tree().get_first_node_in_group("weapon_manager")
	if weapon_manager and weapon_manager.has_signal("weapon_changed"):
		weapon_manager.weapon_changed.connect(_on_weapon_changed)
		_on_weapon_changed(weapon_manager.get_weapon_name())

	call_deferred("_bind_combat_stats")


func _bind_combat_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_node("CombatStats"):
		var stats: CombatStats = player.get_node("CombatStats") as CombatStats
		stats.stats_changed.connect(_on_player_stats_changed)
		_on_player_stats_changed(stats.shield, stats.health)

	var opponent := get_tree().get_first_node_in_group("arena_opponent")
	if opponent and opponent.has_node("CombatStats"):
		var enemy_stats: CombatStats = opponent.get_node("CombatStats") as CombatStats
		enemy_stats.stats_changed.connect(_on_enemy_stats_changed)
		_on_enemy_stats_changed(enemy_stats.shield, enemy_stats.health)


func _on_weapon_changed(weapon_name: String) -> void:
	_weapon_label.text = "Weapon: %s" % weapon_name


func _on_score_changed(player_score: int, enemy_score: int) -> void:
	_update_score(player_score, enemy_score)


func _update_score(player_score: int, enemy_score: int) -> void:
	_score_label.text = "Player: %d | Enemy: %d" % [player_score, enemy_score]


func _on_player_stats_changed(shield: int, health: int) -> void:
	_update_player_stats(health, shield)


func _on_enemy_stats_changed(shield: int, health: int) -> void:
	_update_enemy_stats(health, shield)


func _update_player_stats(health: int, shield: int) -> void:
	_player_stats_label.text = "Player HP: %d | Shield: %d" % [health, shield]


func _update_enemy_stats(health: int, shield: int) -> void:
	_enemy_stats_label.text = "Enemy HP: %d | Shield: %d" % [health, shield]


func _on_countdown_text(text: String) -> void:
	_countdown_label.visible = true
	_countdown_label.text = text


func _on_countdown_hidden() -> void:
	_countdown_label.visible = false


func _on_death_message(text: String) -> void:
	_death_label.visible = true
	_death_label.text = text


func _on_death_message_hidden() -> void:
	_death_label.visible = false


func _on_void_overlay_changed(active: bool, player_fell: bool) -> void:
	_void_overlay.visible = active
	if player_fell:
		_void_overlay.color = Color(0.55, 0.05, 0.12, 0.38)
	else:
		_void_overlay.color = Color(0.08, 0.15, 0.45, 0.32)


func _on_match_over(player_won: bool) -> void:
	_death_label.visible = false
	_void_overlay.visible = false
	_countdown_label.visible = false
	_match_label.visible = true
	if player_won:
		_match_label.text = "You Win!"
	else:
		_match_label.text = "You Lose!"
