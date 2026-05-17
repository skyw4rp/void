## Applies outward push impulses to RigidBody3D within a radius (bazooka blast).
class_name PushExplosion
extends Object


static func detonate(origin: Vector3, radius: float, force: float, world: World3D) -> void:
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
	for hit in hits:
		var body: Object = hit.collider
		if body is RigidBody3D:
			var rigid := body as RigidBody3D
			var offset := rigid.global_position - origin
			if offset.length_squared() < 0.01:
				offset = Vector3.UP * 0.1
			var dir := offset.normalized()
			var falloff := 1.0 - clampf(offset.length() / radius, 0.0, 1.0)
			rigid.apply_impulse(dir * force * falloff, offset)
			print("Explosion: pushed '%s' (force=%.1f)" % [rigid.name, force * falloff])
			pushed += 1

	print("Explosion: %d RigidBody3D hit(s) at %s (radius=%.1f)" % [pushed, origin, radius])
