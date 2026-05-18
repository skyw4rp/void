## Combat SFX hooks — delegates to VoidAudio autoload (no gameplay changes).
class_name CombatAudio
extends RefCounted


static func play_weapon_fire(
	weapon: WeaponDefs.Id, world_position: Vector3, from_enemy: bool = false
) -> void:
	VoidAudio.play_weapon_fire(weapon, world_position, from_enemy)


static func play_hit_confirm(
	world_position: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int,
	attacker_is_player: bool
) -> void:
	VoidAudio.play_hit_confirm(
		world_position,
		shield_before,
		shield_after,
		health_before,
		health_after,
		attacker_is_player
	)


static func play_wall_hit(world_position: Vector3, attacker_is_player: bool) -> void:
	VoidAudio.play_wall_hit(world_position, attacker_is_player)


static func play_shield_break(
	world_position: Vector3,
	is_local_player: bool,
	player_caused: bool
) -> void:
	VoidAudio.play_shield_break(world_position, is_local_player, player_caused)
