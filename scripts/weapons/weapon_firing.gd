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
	var dir: Vector3 = direction.normalized()
	var max_pierce: int = stats.get("max_pierce_hits", 8)
	var pierce_offset: float = stats.get("pierce_step_offset", 0.05)
	var damage: int = stats.get("damage", 100)
	var push_force: float = stats.get("push_force", 68.0)
	var source: String = stats.get("damage_source", "railgun")
	var beam_color: Color = stats.get("beam_color", Color(0.55, 0.88, 1.0))
	var beam_emission: Color = stats.get("beam_emission", Color(0.4, 0.72, 1.0))

	var beam_end: Vector3 = origin + dir * range_max
	var pierced_fighters: Dictionary = {}
	var ray_origin: Vector3 = origin
	var traveled: float = 0.0
	var pierce_count: int = 0
	var stopped_on_fighter: bool = false

	var space: PhysicsDirectSpaceState3D = scene_root.get_world_3d().direct_space_state
	if space:
		var exclude: Array[RID] = _ray_exclude_rids(shooter)
		while pierce_count < max_pierce and traveled < range_max - 0.01:
			var remaining: float = range_max - traveled
			var ray_end: Vector3 = ray_origin + dir * remaining
			var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collide_with_areas = true
			query.collide_with_bodies = true
			query.collision_mask = 1
			query.exclude = exclude

			var result: Dictionary = space.intersect_ray(query)
			if result.is_empty():
				beam_end = ray_end
				break

			var hit_pos: Vector3 = result.position
			var hit_normal: Vector3 = result.normal
			var collider: Object = result.collider
			beam_end = hit_pos

			var body: Node = PushHitResolver.resolve_hit_body(collider as Node)
			if body != null and not PushHitResolver.is_shooter(body, shooter):
				var body_name: String = PushHitResolver.describe_body(body)
				if PushHitResolver.is_combat_fighter(body):
					var fighter_id: int = body.get_instance_id()
					if not pierced_fighters.has(fighter_id):
						pierced_fighters[fighter_id] = true
						PushHitResolver.apply_railgun_hit(
							body, dir, push_force, hit_pos, damage, shooter, source
						)
					RailgunImpactFlash.spawn(scene_root, hit_pos, hit_normal, beam_emission)
					print("Railgun pierced: %s" % body_name)
					stopped_on_fighter = true
					break
				if _spawn_railgun_pierce_marks(
					body, hit_pos, hit_normal, dir, scene_root, beam_emission
				):
					print("Railgun pierced: %s" % body_name)
				else:
					RailgunImpactFlash.spawn(scene_root, hit_pos, hit_normal, beam_emission)
					PushHitResolver.spawn_wall_hit_vfx(hit_pos, dir, true)
					print("Railgun pierced: %s" % body_name)

			if collider is CollisionObject3D:
				exclude.append((collider as CollisionObject3D).get_rid())

			var step: float = maxf(ray_origin.distance_to(hit_pos), 0.001) + pierce_offset
			traveled += step
			ray_origin = hit_pos + dir * pierce_offset
			pierce_count += 1

		if not stopped_on_fighter:
			beam_end = origin + dir * range_max

	BeamTracer.spawn(scene_root, origin, beam_end, beam_color, beam_emission)


static func _spawn_railgun_pierce_marks(
	body: Node,
	hit_pos: Vector3,
	hit_normal: Vector3,
	beam_dir: Vector3,
	scene_root: Node,
	beam_emission: Color
) -> bool:
	if not body is Node3D:
		return false
	if not (
		PushHitResolver.is_destructible_wall(body)
		or body.is_in_group("round_debris")
	):
		return false
	var host: Node3D = body as Node3D
	RailgunPierceMark.spawn_entry_on_host(host, hit_pos, hit_normal, beam_dir)
	RailgunImpactFlash.spawn(scene_root, hit_pos, hit_normal, beam_emission)
	return true


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
