## Spawns projectiles or railgun rays using shared WeaponDefs stats (player + enemy).
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
	spawn_forward_offset: float = 0.0,
	shooter: Node = null
) -> float:
	var data: Dictionary = WeaponDefs.get_data(weapon)
	var base_dir := direction.normalized()
	var spawn_pos := origin + base_dir * spawn_forward_offset

	if data.get("use_railgun_ray", false):
		_fire_railgun(spawn_pos, base_dir, data.railgun, scene_root, shooter)
	elif data.get("use_bazooka_scene", false):
		_spawn_bazooka(spawn_pos, base_dir, data.bazooka, scene_root, shooter)
	else:
		var pellets: int = data.pellets
		for i in pellets:
			var dir := _apply_spread(base_dir, data.spread, aim_basis)
			_spawn_standard_projectile(spawn_pos, dir, data.projectile, scene_root, shooter)

	return data.cooldown


static func _fire_railgun(
	origin: Vector3,
	direction: Vector3,
	stats: Dictionary,
	scene_root: Node,
	shooter: Node
) -> void:
	var range_max: float = stats.get("range", 120.0)
	var end_pos: Vector3 = origin + direction * range_max
	var hit_pos: Vector3 = end_pos
	var hit_body: Node = null

	var space: PhysicsDirectSpaceState3D = scene_root.get_world_3d().direct_space_state
	if space:
		var query := PhysicsRayQueryParameters3D.create(origin, end_pos)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = 1
		query.exclude = _ray_exclude_rids(shooter)
		var result: Dictionary = space.intersect_ray(query)
		if not result.is_empty():
			hit_pos = result.position
			hit_body = result.collider as Node

	var beam_color: Color = stats.get("beam_color", Color(0.72, 0.55, 1.0))
	var beam_emission: Color = stats.get("beam_emission", Color(0.45, 0.25, 0.95))
	BeamTracer.spawn(
		scene_root, origin, hit_pos, beam_color, beam_emission, hit_body != null
	)

	if hit_body != null and not PushHitResolver.is_shooter(hit_body, shooter):
		var damage: int = stats.get("damage", 22)
		var push_force: float = stats.get("push_force", 34.0)
		var source: String = stats.get("damage_source", "railgun")
		PushHitResolver.apply_railgun_hit(
			hit_body, direction, push_force, hit_pos, damage, shooter, source
		)


static func _ray_exclude_rids(shooter: Node) -> Array[RID]:
	var exclude: Array[RID] = []
	if shooter is CollisionObject3D:
		exclude.append((shooter as CollisionObject3D).get_rid())
	return exclude


static func _apply_spread(direction: Vector3, spread: float, aim_basis: Basis) -> Vector3:
	if spread <= 0.0:
		return direction
	var offset := aim_basis.x * randf_range(-spread, spread)
	offset += aim_basis.y * randf_range(-spread, spread)
	return (direction + offset).normalized()


static func _spawn_standard_projectile(
	from: Vector3,
	direction: Vector3,
	stats: Dictionary,
	scene_root: Node,
	shooter: Node
) -> void:
	var projectile: Area3D = PROJECTILE_SCENE.instantiate() as Area3D
	scene_root.add_child(projectile)
	projectile.configure(stats)
	projectile.launch(from, direction, shooter)


static func _spawn_bazooka(
	from: Vector3, direction: Vector3, stats: Dictionary, scene_root: Node, shooter: Node
) -> void:
	var projectile: Area3D = BAZOOKA_PROJECTILE_SCENE.instantiate() as Area3D
	scene_root.add_child(projectile)
	if projectile.has_method("configure"):
		projectile.configure(stats)
	projectile.launch(from, direction, shooter)
