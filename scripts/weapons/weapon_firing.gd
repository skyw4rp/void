## Spawns projectiles using shared WeaponDefs stats (player + enemy).
class_name WeaponFiring
extends RefCounted

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/push_projectile.tscn")
const BAZOOKA_PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/bazooka_projectile.tscn")


static func fire(
	weapon: WeaponDefs.Id,
	origin: Vector3,
	direction: Vector3,
	aim_basis: Basis,
	scene_root: Node,
	spawn_forward_offset: float = 0.0
) -> float:
	var data: Dictionary = WeaponDefs.get_data(weapon)
	var base_dir := direction.normalized()
	var spawn_pos := origin + base_dir * spawn_forward_offset

	if data.get("use_bazooka_scene", false):
		_spawn_bazooka(spawn_pos, base_dir, scene_root)
	else:
		var pellets: int = data.pellets
		for i in pellets:
			var dir := _apply_spread(base_dir, data.spread, aim_basis)
			_spawn_standard_projectile(spawn_pos, dir, data.projectile, scene_root)

	return data.cooldown


static func _apply_spread(direction: Vector3, spread: float, aim_basis: Basis) -> Vector3:
	if spread <= 0.0:
		return direction
	var offset := aim_basis.x * randf_range(-spread, spread)
	offset += aim_basis.y * randf_range(-spread, spread)
	return (direction + offset).normalized()


static func _spawn_standard_projectile(
	from: Vector3, direction: Vector3, stats: Dictionary, scene_root: Node
) -> void:
	var projectile: Area3D = PROJECTILE_SCENE.instantiate() as Area3D
	scene_root.add_child(projectile)
	projectile.configure(stats)
	projectile.launch(from, direction)


static func _spawn_bazooka(from: Vector3, direction: Vector3, scene_root: Node) -> void:
	var projectile: Area3D = BAZOOKA_PROJECTILE_SCENE.instantiate() as Area3D
	scene_root.add_child(projectile)
	projectile.launch(from, direction)
