## Single entry for shield-break audiovisual feedback (once per transition).
class_name CombatFeedback
extends RefCounted


static func on_shield_broken(stats: CombatStats) -> void:
	if stats == null:
		return
	var body: Node3D = stats.get_parent() as Node3D
	if body == null:
		return

	var world_pos: Vector3 = _burst_position(stats, body)
	var normal: Vector3 = stats.last_hit_direction
	if normal.length_squared() < 0.0001:
		normal = Vector3.FORWARD
	else:
		normal = -normal.normalized()

	var is_player: bool = body.is_in_group("player")
	var is_enemy: bool = body.is_in_group("arena_opponent")
	var player_caused: bool = _player_caused_break(stats, is_enemy)

	CombatVfxDirector.play_shield_break_event(world_pos, normal, is_player, is_enemy)
	CombatAudio.play_shield_break(world_pos, is_player, player_caused)

	if is_player:
		_notify_player_local(body)
	if is_enemy and player_caused and body.is_inside_tree():
		var cross: Control = Crosshair.get_instance(body.get_tree())
		if cross and cross.has_method("notify_enemy_shield_broken"):
			cross.call("notify_enemy_shield_broken")


static func _burst_position(stats: CombatStats, body: Node3D) -> Vector3:
	if stats.has_last_hit_world_position:
		return stats.last_hit_world_position + Vector3(0, 0.15, 0)
	return body.global_position + Vector3(0, 1.15, 0)


static func _player_caused_break(stats: CombatStats, is_enemy: bool) -> bool:
	if not is_enemy:
		return false
	var attacker: Node = stats.last_attacker
	if attacker == null:
		return false
	if attacker.is_in_group("player"):
		return true
	var tree: SceneTree = stats.get_tree()
	if tree == null:
		return false
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return false
	return attacker == player or player.is_ancestor_of(attacker)


static func _notify_player_local(player: Node) -> void:
	if player.has_method("notify_shield_broken"):
		player.call("notify_shield_broken")
