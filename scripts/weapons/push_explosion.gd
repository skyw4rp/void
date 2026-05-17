## Applies outward push to RigidBody3D and knockback targets within a radius.
class_name PushExplosion
extends Object


static func detonate(
	origin: Vector3,
	radius: float,
	force: float,
	source: Node,
	shooter: Node = null,
	explosion_damage: int = 0
) -> void:
	var world: World3D = source.get_world_3d()
	var space := world.direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = radius

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), origin)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = 0xFFFFFFFF

	var hits := space.intersect_shape(params, 64)
	var pushed: int = 0
	var player_handled := false
	var shooter_body: Node3D = _resolve_shooter_body(shooter)
	var affected: Dictionary = {}

	for hit in hits:
		var body: Object = hit.collider
		if not body is Node3D:
			continue
		var node: Node3D = body as Node3D
		var resolved: Node = PushHitResolver.resolve_hit_body(node) as Node
		if resolved == null:
			continue
		if affected.has(resolved.get_instance_id()):
			continue
		if shooter_body != null and resolved == shooter_body:
			continue
		if PushHitResolver.is_shooter(resolved, shooter):
			continue
		affected[resolved.get_instance_id()] = true
		if PushHitResolver.apply_explosion_hit(
			resolved as Node3D, origin, force, radius, explosion_damage, shooter
		):
			pushed += 1
			if resolved.is_in_group("player"):
				player_handled = true

	pushed += _apply_group_destructible_hits(
		source, origin, radius, force, explosion_damage, shooter, shooter_body, affected
	)

	if not player_handled:
		var player: Node3D = source.get_tree().get_first_node_in_group("player") as Node3D
		if player and (shooter_body == null or player != shooter_body):
			if not affected.has(player.get_instance_id()):
				var dist: float = player.global_position.distance_to(origin)
				if dist <= radius:
					if PushHitResolver.apply_explosion_hit(
						player, origin, force, radius, explosion_damage, shooter
					):
						pushed += 1

	if shooter_body != null:
		PushHitResolver.apply_shooter_rocket_jump(
			shooter_body, origin, force, radius, explosion_damage, shooter
		)

	print("Explosion: %d target(s) pushed at %s (radius=%.1f)" % [pushed, origin, radius])


static func _apply_group_destructible_hits(
	source: Node,
	origin: Vector3,
	radius: float,
	force: float,
	explosion_damage: int,
	shooter: Node,
	shooter_body: Node3D,
	affected: Dictionary
) -> int:
	var tree: SceneTree = source.get_tree()
	var extra: int = 0
	if tree == null:
		return extra
	for node in tree.get_nodes_in_group(PushHitResolver.GROUP_DESTRUCTIBLE_WALL):
		if not node is Node3D:
			continue
		var wall: Node3D = node as Node3D
		if affected.has(wall.get_instance_id()):
			continue
		if wall.global_position.distance_to(origin) > radius:
			continue
		if shooter_body != null and wall == shooter_body:
			continue
		if PushHitResolver.is_shooter(wall, shooter):
			continue
		affected[wall.get_instance_id()] = true
		if PushHitResolver.apply_explosion_hit(
			wall, origin, force, radius, explosion_damage, shooter
		):
			extra += 1
	return extra


static func _resolve_shooter_body(shooter: Node) -> Node3D:
	if shooter == null:
		return null
	if shooter is Node3D:
		return shooter as Node3D
	if shooter.get_parent() is Node3D:
		return shooter.get_parent() as Node3D
	return null
