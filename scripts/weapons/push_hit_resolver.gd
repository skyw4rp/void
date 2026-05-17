## Shared projectile / explosion push handling for RigidBody3D and knockback targets.
class_name PushHitResolver
extends RefCounted


static func is_shooter(body: Node, shooter: Node) -> bool:
	if shooter == null:
		return false
	if body == shooter:
		return true
	if shooter.is_ancestor_of(body) or body.is_ancestor_of(shooter):
		return true
	return false


static func apply_projectile_hit(
	body: Node, travel_direction: Vector3, force: float, hit_position: Vector3
) -> bool:
	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		var offset: Vector3 = hit_position - rigid.global_position
		rigid.apply_impulse(travel_direction.normalized() * force, offset)
		print("Projectile: pushed '%s' (force=%.1f)" % [rigid.name, force])
		return true
	if body.has_method("apply_knockback"):
		body.call("apply_knockback", travel_direction, force)
		print("Player knocked back by projectile")
		return true
	return false


static func apply_explosion_hit(body: Node3D, origin: Vector3, force: float, radius: float) -> bool:
	var offset: Vector3 = body.global_position - origin
	if offset.length_squared() < 0.01:
		offset = Vector3.UP * 0.1
	var dir: Vector3 = offset.normalized()
	var falloff: float = 1.0 - clampf(offset.length() / radius, 0.0, 1.0)
	var impulse_strength: float = force * falloff

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		rigid.apply_impulse(dir * impulse_strength, offset)
		print("Explosion: pushed '%s' (force=%.1f)" % [rigid.name, impulse_strength])
		return true
	if body.has_method("apply_knockback"):
		body.call("apply_knockback", dir, impulse_strength)
		print("Player knocked back by explosion")
		return true
	return false
