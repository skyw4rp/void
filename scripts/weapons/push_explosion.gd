## Applies outward push to RigidBody3D and knockback targets within a radius.
class_name PushExplosion
extends Object


static func detonate(
	origin: Vector3, radius: float, force: float, source: Node, shooter: Node = null
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

	for hit in hits:
		var body: Object = hit.collider
		if not body is Node3D:
			continue
		var node: Node3D = body as Node3D
		if PushHitResolver.is_shooter(node, shooter):
			continue
		if PushHitResolver.apply_explosion_hit(node, origin, force, radius):
			pushed += 1
			if node.is_in_group("player"):
				player_handled = true

	# Fallback: ensure player gets blast if shape query missed CharacterBody3D.
	if not player_handled:
		var player: Node3D = source.get_tree().get_first_node_in_group("player") as Node3D
		if player and not PushHitResolver.is_shooter(player, shooter):
			var dist: float = player.global_position.distance_to(origin)
			if dist <= radius:
				if PushHitResolver.apply_explosion_hit(player, origin, force, radius):
					pushed += 1

	print("Explosion: %d target(s) pushed at %s (radius=%.1f)" % [pushed, origin, radius])
