## Combat movement wish-direction and weapon-range helpers for ArenaOpponent.
class_name ArenaOpponentMovement
extends RefCounted


static func weapon_ideal_range(weapon: WeaponDefs.Id) -> Vector2:
	match weapon:
		WeaponDefs.Id.RAILGUN:
			return Vector2(7.5, 13.5)
		WeaponDefs.Id.SHOTGUN:
			return Vector2(2.8, 6.2)
		WeaponDefs.Id.BAZOOKA:
			return Vector2(5.5, 10.5)
		_:
			return Vector2(4.0, 9.0)


static func steer_clear_of_walls(
	body: RigidBody3D,
	wish: Vector3,
	probe_distance: float = 1.35
) -> Vector3:
	if wish.length_squared() < 0.01:
		return wish
	var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
	if space == null:
		return wish
	var flat_wish: Vector3 = Vector3(wish.x, 0.0, wish.z).normalized()
	var origin: Vector3 = body.global_position + Vector3(0.0, 0.85, 0.0)
	var steer: Vector3 = Vector3.ZERO
	for side_sign in [-1.0, 1.0]:
		var lateral: Vector3 = flat_wish.cross(Vector3.UP).normalized() * side_sign
		var to: Vector3 = origin + lateral * probe_distance
		var query := PhysicsRayQueryParameters3D.create(origin, to)
		query.collision_mask = 1
		query.exclude = [body.get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			steer -= lateral * 0.85
	var forward_to: Vector3 = origin + flat_wish * probe_distance
	var fwd_query := PhysicsRayQueryParameters3D.create(origin, forward_to)
	fwd_query.collision_mask = 1
	fwd_query.exclude = [body.get_rid()]
	if not space.intersect_ray(fwd_query).is_empty():
		steer += flat_wish.cross(Vector3.UP).normalized() * (1.0 if randf() > 0.5 else -1.0)
	var combined: Vector3 = flat_wish + steer
	if combined.length_squared() < 0.01:
		return flat_wish
	return combined.normalized()


static func compute_combat_wish(
	state: int,
	weapon: WeaponDefs.Id,
	to_player_dir: Vector3,
	distance: float,
	strafe_sign: float,
	edge_zone: int,
	player_in_air: bool,
	can_chase_forward: bool,
	aggression: float,
	fear: float,
	strafe_aggression: float,
	has_los: bool
) -> Vector3:
	if to_player_dir.length_squared() < 0.01:
		return Vector3(strafe_sign, 0.0, 0.0).normalized()

	var strafe_dir: Vector3 = to_player_dir.cross(Vector3.UP).normalized() * strafe_sign
	var ideal: Vector2 = weapon_ideal_range(weapon)
	var wish: Vector3 = Vector3.ZERO
	var strafe_w: float = 0.55 + strafe_aggression * 0.45
	var advance_w: float = 0.35
	var retreat_w: float = 0.0

	match weapon:
		WeaponDefs.Id.RAILGUN:
			ideal = Vector2(8.0, 14.0)
			strafe_w = 0.72
			advance_w = 0.22
		WeaponDefs.Id.SHOTGUN:
			ideal = Vector2(2.5, 5.8)
			strafe_w = 0.58
			advance_w = 0.62
		WeaponDefs.Id.BAZOOKA:
			ideal = Vector2(6.0, 11.0)
			strafe_w = 0.65
			advance_w = 0.38
			retreat_w = 0.15

	# State modifiers (AiState ints passed from opponent)
	const ST_PRESSURING := 1
	const ST_EVADING := 2
	const ST_EXECUTING := 3
	const ST_REPOSITIONING := 6

	match state:
		ST_EVADING:
			retreat_w = 0.75 + fear * 0.35
			advance_w *= 0.25
			strafe_w *= 1.25
		ST_PRESSURING:
			advance_w *= 1.15 + aggression * 0.35
			strafe_w *= 0.92
		ST_EXECUTING:
			advance_w *= 1.35 + aggression * 0.25
			strafe_w *= 1.05
		ST_REPOSITIONING:
			strafe_w *= 1.35
			advance_w *= 0.55

	if player_in_air:
		advance_w *= 0.35
		strafe_w *= 1.2

	if edge_zone == 1:
		advance_w *= 0.7
		strafe_w *= 1.08
	elif edge_zone >= 2:
		advance_w *= 0.25
		strafe_w *= 1.15

	if distance < ideal.x:
		retreat_w = maxf(retreat_w, 0.65 + fear * 0.25)
		if weapon == WeaponDefs.Id.BAZOOKA:
			retreat_w = maxf(retreat_w, 0.85)
	elif distance > ideal.y:
		if can_chase_forward:
			advance_w = maxf(advance_w, 0.55 + aggression * 0.2)
		else:
			strafe_w *= 1.2
	else:
		strafe_w = maxf(strafe_w, 0.85)

	if not has_los and distance > ideal.x:
		advance_w += 0.35

	wish += strafe_dir * strafe_w
	if retreat_w > 0.01:
		wish -= to_player_dir * retreat_w
	if advance_w > 0.01 and can_chase_forward:
		wish += to_player_dir * advance_w

	if wish.length_squared() < 0.05:
		wish = strafe_dir * 0.9 + to_player_dir * 0.1

	return wish.normalized()
