## Applies chamber loadout and returns to Gladiator Chamber when match ends.
extends Node

const RETURN_DELAY_SEC: float = 2.8


func _ready() -> void:
	add_to_group("arena_match_bridge")
	GameFlow.transitioning = false
	call_deferred("_bind_match_flow")


func _bind_match_flow() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_loadout_to_player()
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("match_over"):
		if not gm.match_over.is_connected(_on_match_over):
			gm.match_over.connect(_on_match_over)


func _apply_loadout_to_player() -> void:
	var wm: Node = get_tree().get_first_node_in_group("weapon_manager")
	if wm and wm.has_method("switch_weapon"):
		wm.call("switch_weapon", GladiatorLoadout.get_weapon_defs_id())
		print(
			"Arena: loadout weapon %s | armor %s | helmet %s"
			% [
				GladiatorLoadout.weapon_display_name(),
				GladiatorLoadout.armor_display_name(),
				GladiatorLoadout.helmet_display_name(),
			]
		)


func _on_match_over(player_won: bool) -> void:
	if GameFlow.transitioning:
		return
	await get_tree().create_timer(RETURN_DELAY_SEC).timeout
	GameFlow.return_to_chamber(player_won)
