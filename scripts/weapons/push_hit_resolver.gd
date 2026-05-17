## Shared projectile / explosion push and damage for RigidBody3D and knockback targets.
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


static func compute_rigidbody_impulse(direction: Vector3, force: float, mass: float) -> Vector3:
	var dir: Vector3 = direction.normalized()
	return dir * force * mass * WeaponDefs.RIGIDBODY_KNOCKBACK_MULTIPLIER


static func compute_explosion_forces(
	origin: Vector3, target_position: Vector3, force: float, radius: float
) -> Dictionary:
	var raw_dir: Vector3 = target_position - origin
	var distance: float = raw_dir.length()
	var falloff: float = 1.0 - clampf(distance / radius, 0.0, 1.0)
	var scaled_force: float = force * falloff

	var horizontal_dir: Vector3 = Vector3(raw_dir.x, 0.0, raw_dir.z)
	if horizontal_dir.length_squared() < 0.001:
		horizontal_dir = Vector3.FORWARD
	else:
		horizontal_dir = horizontal_dir.normalized()

	var vertical_force: float = clampf(
		raw_dir.y * scaled_force * WeaponDefs.EXPLOSION_VERTICAL_FACTOR,
		-WeaponDefs.EXPLOSION_MAX_DOWNWARD_FORCE,
		WeaponDefs.EXPLOSION_MAX_UPWARD_FORCE
	)

	return {
		"horizontal_dir": horizontal_dir,
		"horizontal_force": scaled_force,
		"vertical_force": vertical_force,
	}


static func apply_rigidbody_impulse(
	rigid: RigidBody3D, direction: Vector3, force: float, hit_position: Vector3
) -> void:
	var offset: Vector3 = hit_position - rigid.global_position
	var impulse: Vector3 = compute_rigidbody_impulse(direction, force, rigid.mass)
	rigid.apply_impulse(impulse, offset)
	print(
		"RigidBody impulse applied: %s on '%s' (final vel=%s)"
		% [impulse, rigid.name, rigid.linear_velocity]
	)


static func _apply_rigidbody_explosion_impulse(
	rigid: RigidBody3D,
	horizontal_dir: Vector3,
	horizontal_force: float,
	vertical_force: float,
	hit_position: Vector3
) -> void:
	var mass: float = rigid.mass
	var mult: float = WeaponDefs.RIGIDBODY_KNOCKBACK_MULTIPLIER
	var horizontal_impulse: Vector3 = horizontal_dir * horizontal_force * mass * mult
	var vertical_impulse: Vector3 = Vector3.UP * vertical_force * mass * mult
	var impulse: Vector3 = horizontal_impulse + vertical_impulse

	var offset: Vector3 = hit_position - rigid.global_position
	rigid.apply_impulse(impulse, offset)
	print(
		"Explosion knockback on '%s': horizontal=%.1f vertical=%.1f impulse=%s"
		% [rigid.name, horizontal_force, vertical_force, impulse]
	)


static func _compute_damped_vertical_force(raw_dir: Vector3, force: float) -> float:
	return clampf(
		raw_dir.y * force * WeaponDefs.PROJECTILE_HIT_VERTICAL_FACTOR,
		-WeaponDefs.EXPLOSION_MAX_DOWNWARD_FORCE * 0.5,
		WeaponDefs.EXPLOSION_MAX_UPWARD_FORCE * 0.65
	)


static func _horizontal_dir_from(raw_dir: Vector3) -> Vector3:
	var horizontal_dir: Vector3 = Vector3(raw_dir.x, 0.0, raw_dir.z)
	if horizontal_dir.length_squared() < 0.001:
		return Vector3.FORWARD
	return horizontal_dir.normalized()


static func apply_damage_to_target(
	body: Node,
	amount: int,
	attacker: Node,
	direction: Vector3 = Vector3.ZERO,
	force: float = 0.0,
	source: String = ""
) -> void:
	if amount <= 0:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", amount, attacker, direction, force, source)
		return
	var stats: CombatStats = body.get_node_or_null("CombatStats") as CombatStats
	if stats:
		stats.record_hit(direction, force, attacker, source)
		stats.apply_damage(amount, attacker)


## Projectile hit with damped vertical (bazooka direct impact).
static func apply_damped_projectile_hit(
	body: Node,
	travel_direction: Vector3,
	force: float,
	hit_position: Vector3,
	damage: int = 0,
	attacker: Node = null,
	damage_source: String = "bazooka_direct"
) -> bool:
	var raw_dir: Vector3 = travel_direction.normalized()
	var horizontal_dir: Vector3 = _horizontal_dir_from(raw_dir)
	var vertical_force: float = _compute_damped_vertical_force(raw_dir, force)
	var handled: bool = false

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		_apply_rigidbody_explosion_impulse(
			rigid, horizontal_dir, force, vertical_force, hit_position
		)
		handled = true
	elif body.has_method("apply_explosion_knockback"):
		body.call("apply_explosion_knockback", horizontal_dir, force, vertical_force)
		handled = true

	if handled and damage > 0:
		apply_damage_to_target(body, damage, attacker, raw_dir, force, damage_source)
	return handled


static func apply_projectile_hit(
	body: Node,
	travel_direction: Vector3,
	force: float,
	hit_position: Vector3,
	damage: int = 0,
	attacker: Node = null,
	damage_source: String = ""
) -> bool:
	var handled: bool = false
	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		apply_rigidbody_impulse(rigid, travel_direction, force, hit_position)
		handled = true
	elif body.has_method("apply_knockback"):
		body.call("apply_knockback", travel_direction, force)
		handled = true

	if handled and damage > 0:
		var hit_dir: Vector3 = travel_direction.normalized()
		apply_damage_to_target(body, damage, attacker, hit_dir, force, damage_source)
	return handled


static func apply_explosion_hit(
	body: Node3D,
	origin: Vector3,
	force: float,
	radius: float,
	explosion_damage: int = 0,
	attacker: Node = null
) -> bool:
	var forces: Dictionary = compute_explosion_forces(origin, body.global_position, force, radius)
	var horizontal_dir: Vector3 = forces.horizontal_dir
	var horizontal_force: float = forces.horizontal_force
	var vertical_force: float = forces.vertical_force
	var handled: bool = false

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		_apply_rigidbody_explosion_impulse(
			rigid, horizontal_dir, horizontal_force, vertical_force, body.global_position
		)
		handled = true
	elif body.has_method("apply_explosion_knockback"):
		body.call("apply_explosion_knockback", horizontal_dir, horizontal_force, vertical_force)
		handled = true

	if handled and explosion_damage > 0:
		var damage: int = WeaponDefs.explosion_damage_at_distance(
			explosion_damage, origin, body.global_position, radius
		)
		if damage > 0:
			var blast_dir: Vector3 = body.global_position - origin
			if blast_dir.length_squared() < 0.001:
				blast_dir = horizontal_dir
			apply_damage_to_target(
				body,
				damage,
				attacker,
				blast_dir,
				horizontal_force,
				"bazooka_explosion"
			)
	return handled
