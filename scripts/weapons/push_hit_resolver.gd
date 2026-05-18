## Shared projectile / explosion push and damage for RigidBody3D and knockback targets.
class_name PushHitResolver
extends RefCounted


const GROUP_DESTRUCTIBLE_WALL: String = "destructible_wall"
const GROUP_STRUCTURAL: String = "structural_geometry"
const GROUP_LOW_IMPULSE_FRAGMENT: String = "low_impulse_fragment"
const FRAGMENT_EXPLOSION_KNOCKBACK_MULT: float = 0.12


static func resolve_hit_body(body: Node) -> Node:
	if body == null:
		return null
	if body.has_method("get_wall_grid"):
		var grid: Node = body.call("get_wall_grid") as Node
		if grid:
			return grid
	if body is CollisionObject3D:
		return body
	var parent: Node = body.get_parent()
	if parent is StaticBody3D:
		return parent
	return body


static func describe_body(body: Node) -> String:
	var target: Node = resolve_hit_body(body)
	if target == null:
		return "null"
	return target.name


static func is_anonymous_static(body: Node) -> bool:
	var target: Node = resolve_hit_body(body)
	if target == null or not target is StaticBody3D:
		return false
	if target is DestructibleWall or target is StructuralFloor or target is StructuralWall:
		return false
	var node_name: String = target.name
	return node_name.begins_with("@") or node_name == "StaticBody3D"


static func is_destructible_wall(body: Node) -> bool:
	var target: Node = resolve_hit_body(body)
	if target == null:
		return false
	if target.is_in_group(GROUP_DESTRUCTIBLE_WALL):
		return true
	return target.has_method("is_destructible_wall") and target.call("is_destructible_wall")


static func is_structural_geometry(body: Node) -> bool:
	var target: Node = resolve_hit_body(body)
	if target == null:
		return false
	return StructuralFloor.is_structural_node(target)


static func log_static_hit(body: Node, source: String) -> void:
	var target: Node = resolve_hit_body(body)
	if target == null:
		return
	if is_anonymous_static(target):
		print(
			"WARNING: Anonymous StaticBody hit; check generator (name='%s', source=%s)"
			% [target.name, source]
		)
		return
	if is_structural_geometry(target):
		var kind: String = "connector" if target.is_in_group("structural_connector") else "floor"
		print("Hit structural %s, not destructible: '%s'" % [kind, target.name])
		return


static func is_combat_fighter(body: Node) -> bool:
	body = resolve_hit_body(body)
	if body == null:
		return false
	if body.get_node_or_null("CombatStats") != null:
		return true
	if body.has_method("take_damage") and (
		body.is_in_group("player") or body.is_in_group("arena_opponent")
	):
		return true
	return false


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


static func _fragment_knockback_multiplier(body: Node) -> float:
	var target: Node = resolve_hit_body(body)
	if target == null or not target.is_in_group(GROUP_LOW_IMPULSE_FRAGMENT):
		return 1.0
	if target.has_method("is_fragment_knockback_immune") and target.call("is_fragment_knockback_immune"):
		return 0.0
	print("Low impulse fragment knockback reduced")
	return FRAGMENT_EXPLOSION_KNOCKBACK_MULT


static func apply_rigidbody_impulse(
	rigid: RigidBody3D, direction: Vector3, force: float, hit_position: Vector3
) -> void:
	var mult: float = _fragment_knockback_multiplier(rigid)
	if mult <= 0.0:
		return
	var offset: Vector3 = hit_position - rigid.global_position
	var impulse: Vector3 = compute_rigidbody_impulse(direction, force * mult, rigid.mass)
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
	var frag_mult: float = _fragment_knockback_multiplier(rigid)
	if frag_mult <= 0.0:
		return
	var mass: float = rigid.mass
	var mult: float = WeaponDefs.RIGIDBODY_KNOCKBACK_MULTIPLIER * frag_mult
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
	source: String = "",
	hit_world: Vector3 = Vector3.ZERO
) -> void:
	if amount <= 0:
		return
	body = resolve_hit_body(body)
	if is_structural_geometry(body):
		log_static_hit(body, source)
		return
	if is_anonymous_static(body):
		log_static_hit(body, source)
		return
	if body.has_method("damage_cover"):
		var origin: Vector3 = hit_world
		if origin.length_squared() < 0.001 and direction.length_squared() > 0.001:
			origin = (body as Node3D).global_position
		if is_destructible_wall(body):
			body.call(
				"damage_cover", amount, attacker, direction, force, source, origin, 0.0
			)
		else:
			body.call("damage_cover", amount, attacker, direction, force, source)
		if _is_player_attacker(attacker) and body.is_inside_tree():
			Crosshair.notify_player_hit_cover(body.get_tree())
		var cover_pos: Vector3 = origin
		if cover_pos.length_squared() < 0.001 and body is Node3D:
			cover_pos = (body as Node3D).global_position
		CombatAudio.play_wall_hit(cover_pos, _is_player_attacker(attacker))
		spawn_wall_hit_vfx(cover_pos, direction, is_destructible_wall(body))
		return
	var stats: CombatStats = body.get_node_or_null("CombatStats") as CombatStats
	if stats:
		var explosion_origin: Vector3 = Vector3(INF, INF, INF)
		if source == "bazooka_explosion" and hit_world.length_squared() > 0.001:
			explosion_origin = hit_world
		var hit_pos: Vector3 = Vector3(INF, INF, INF)
		if hit_world.length_squared() > 0.001:
			hit_pos = hit_world
		stats.record_hit(direction, force, attacker, source, explosion_origin, hit_pos)
		var shield_before: int = stats.shield
		var health_before: int = stats.health
		stats.apply_damage(amount, attacker)
		var hit_pos_audio: Vector3 = hit_pos
		if hit_pos_audio.length_squared() > 1e8 and body is Node3D:
			hit_pos_audio = (body as Node3D).global_position
		if body.is_inside_tree():
			CombatAudio.play_hit_confirm(
				hit_pos_audio,
				shield_before,
				stats.shield,
				health_before,
				stats.health,
				_is_player_attacker(attacker)
			)
		var vfx_pos: Vector3 = hit_pos_audio
		if vfx_pos.length_squared() > 1e8 and body is Node3D:
			vfx_pos = (body as Node3D).global_position
		spawn_fighter_hit_vfx(
			vfx_pos, direction, shield_before, stats.shield, health_before, stats.health
		)
		if _is_player_attacker(attacker) and body.is_in_group("arena_opponent"):
			Crosshair.notify_player_damage_to(
				body.get_tree(), body, shield_before, health_before
			)
		return
	if body.has_method("take_damage"):
		body.call("take_damage", amount, attacker, direction, force, source)
		return


static func spawn_fighter_hit_vfx(
	world_position: Vector3,
	hit_direction: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int
) -> void:
	CombatVfxDirector.spawn_fighter_hit(
		world_position,
		Vector3.ZERO,
		shield_before,
		shield_after,
		health_before,
		health_after,
		hit_direction
	)


static func spawn_wall_hit_vfx(
	world_position: Vector3,
	hit_direction: Vector3,
	metallic: bool = true
) -> void:
	var normal: Vector3 = Vector3.UP
	if hit_direction.length_squared() > 0.0001:
		normal = (-hit_direction).normalized()
	CombatVfxDirector.spawn_wall_hit(world_position, normal, metallic)


static func should_spawn_wall_hit_vfx(body: Node) -> bool:
	body = resolve_hit_body(body)
	if body == null:
		return false
	if is_combat_fighter(body):
		return false
	if body is RigidBody3D:
		return false
	return body is StaticBody3D or is_destructible_wall(body) or is_structural_geometry(body)


static func _is_player_attacker(attacker: Node) -> bool:
	if attacker == null:
		return false
	if attacker.is_in_group("player"):
		return true
	var tree: SceneTree = attacker.get_tree()
	if tree == null:
		return false
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return false
	return attacker == player or player.is_ancestor_of(attacker)


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

	body = resolve_hit_body(body)

	if is_structural_geometry(body):
		log_static_hit(body, damage_source)
		return true

	if is_anonymous_static(body):
		log_static_hit(body, damage_source)
		return true

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		_apply_rigidbody_explosion_impulse(
			rigid, horizontal_dir, force, vertical_force, hit_position
		)
		handled = true
	elif is_destructible_wall(body):
		handled = true
	elif body.has_method("apply_explosion_knockback"):
		body.call("apply_explosion_knockback", horizontal_dir, force, vertical_force)
		handled = true

	if handled and damage > 0:
		apply_damage_to_target(body, damage, attacker, raw_dir, force, damage_source, hit_position)
	return handled


## Railgun hit — strong horizontal shove, minimal vertical lift.
static func apply_railgun_hit(
	body: Node,
	travel_direction: Vector3,
	force: float,
	hit_position: Vector3,
	damage: int = 0,
	attacker: Node = null,
	damage_source: String = "railgun"
) -> bool:
	var raw_dir: Vector3 = travel_direction.normalized()
	var horizontal_dir: Vector3 = _horizontal_dir_from(raw_dir)
	var vertical_force: float = clampf(
		raw_dir.y * force * WeaponDefs.RAILGUN_VERTICAL_FACTOR,
		-2.0,
		3.5
	)
	var handled: bool = false

	body = resolve_hit_body(body)

	if is_structural_geometry(body):
		log_static_hit(body, damage_source)
		return true

	if is_anonymous_static(body):
		log_static_hit(body, damage_source)
		return true

	if is_destructible_wall(body):
		return true

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		if rigid.is_in_group(GROUP_LOW_IMPULSE_FRAGMENT):
			return true
		_apply_rigidbody_explosion_impulse(
			rigid, horizontal_dir, force, vertical_force, hit_position
		)
		handled = true
	elif body.has_method("apply_explosion_knockback"):
		body.call("apply_explosion_knockback", horizontal_dir, force, vertical_force)
		handled = true
	elif body.has_method("apply_knockback"):
		body.call("apply_knockback", horizontal_dir, force, false)
		handled = true

	if handled and damage > 0:
		apply_damage_to_target(
			body, damage, attacker, horizontal_dir, force, damage_source, hit_position
		)
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
	body = resolve_hit_body(body)

	if is_structural_geometry(body):
		log_static_hit(body, damage_source)
		return true

	if is_anonymous_static(body):
		log_static_hit(body, damage_source)
		return true

	var handled: bool = false
	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		apply_rigidbody_impulse(rigid, travel_direction, force, hit_position)
		handled = true
	elif is_destructible_wall(body):
		handled = true
	elif body.has_method("apply_knockback"):
		body.call("apply_knockback", travel_direction, force)
		handled = true

	if handled and damage > 0:
		var hit_dir: Vector3 = travel_direction.normalized()
		apply_damage_to_target(
			body, damage, attacker, hit_dir, force, damage_source, hit_position
		)
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
	body = resolve_hit_body(body) as Node3D
	if body == null:
		return false

	if is_structural_geometry(body):
		log_static_hit(body, "bazooka_explosion")
		return true

	if is_anonymous_static(body):
		log_static_hit(body, "bazooka_explosion")
		return true

	var handled: bool = false

	if body is RigidBody3D:
		var rigid: RigidBody3D = body as RigidBody3D
		_apply_rigidbody_explosion_impulse(
			rigid, horizontal_dir, horizontal_force, vertical_force, body.global_position
		)
		handled = true
	elif is_destructible_wall(body):
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
			if is_destructible_wall(body):
				_apply_wall_explosion_damage(
					body, origin, radius, attacker, blast_dir, horizontal_force
				)
			else:
				apply_damage_to_target(
					body,
					damage,
					attacker,
					blast_dir,
					horizontal_force,
					"bazooka_explosion",
					origin
				)
	return handled


static func _apply_wall_explosion_damage(
	body: Node,
	origin: Vector3,
	radius: float,
	attacker: Node,
	blast_dir: Vector3,
	horizontal_force: float
) -> void:
	var wall_damage: int = WeaponDefs.wall_explosion_damage_at_distance(
		WeaponDefs.WALL_DAMAGE_BAZOOKA_EXPLOSION_MAX,
		origin,
		(body as Node3D).global_position,
		radius
	)
	if wall_damage <= 0:
		return
	body.call(
		"damage_cover",
		wall_damage,
		attacker,
		blast_dir,
		horizontal_force,
		"bazooka_explosion",
		origin,
		radius
	)
	if _is_player_attacker(attacker) and body.is_inside_tree():
		Crosshair.notify_player_hit_cover(body.get_tree())


static func apply_shooter_rocket_jump(
	shooter_body: Node3D,
	origin: Vector3,
	force: float,
	radius: float,
	explosion_damage: int,
	shooter: Node
) -> void:
	var dist: float = shooter_body.global_position.distance_to(origin)
	if dist > radius:
		return

	var forces: Dictionary = compute_rocket_jump_forces(
		origin, shooter_body.global_position, force, radius
	)
	var h_dir: Vector3 = forces.horizontal_dir
	var h_force: float = forces.horizontal_force
	var v_force: float = forces.vertical_force

	if shooter_body.has_method("apply_rocket_jump_knockback"):
		shooter_body.call("apply_rocket_jump_knockback", h_dir, h_force, v_force)
	elif shooter_body is RigidBody3D:
		_apply_rigidbody_explosion_impulse(
			shooter_body as RigidBody3D,
			h_dir,
			h_force,
			v_force,
			shooter_body.global_position
		)
	else:
		return

	if WeaponDefs.SELF_EXPLOSION_DAMAGE_MULTIPLIER <= 0.0:
		return

	var falloff: float = 1.0 - clampf(dist / radius, 0.0, 1.0)
	var self_damage: int = int(
		round(
			float(explosion_damage)
			* falloff
			* WeaponDefs.SELF_EXPLOSION_DAMAGE_MULTIPLIER
		)
	)
	if self_damage <= 0:
		return
	var blast_dir: Vector3 = blast_dir_from(origin, shooter_body)
	if shooter_body.has_method("take_damage"):
		shooter_body.call(
			"take_damage", self_damage, shooter, blast_dir, h_force, "bazooka_explosion"
		)
	elif shooter_body.has_node("CombatStats"):
		var stats: CombatStats = shooter_body.get_node("CombatStats") as CombatStats
		stats.record_hit(blast_dir, h_force, shooter, "bazooka_explosion")
		stats.apply_damage(self_damage, shooter)


static func compute_rocket_jump_forces(
	origin: Vector3, target_position: Vector3, force: float, radius: float
) -> Dictionary:
	var scaled_force: float = force * WeaponDefs.SELF_EXPLOSION_KNOCKBACK_MULTIPLIER
	var base: Dictionary = compute_explosion_forces(origin, target_position, scaled_force, radius)
	var distance: float = origin.distance_to(target_position)
	var falloff: float = 1.0 - clampf(distance / radius, 0.0, 1.0)
	base.vertical_force += WeaponDefs.ROCKET_JUMP_UPWARD_BOOST * falloff
	return base


static func blast_dir_from(origin: Vector3, target: Node3D) -> Vector3:
	var blast_dir: Vector3 = target.global_position - origin
	if blast_dir.length_squared() < 0.001:
		return Vector3.UP
	return blast_dir.normalized()
