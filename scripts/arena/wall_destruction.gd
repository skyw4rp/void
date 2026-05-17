## Staged wall fracture — proportional chunks, local collapse, impact-aware impulses.
class_name WallDestruction
extends Object

const MIN_CHUNKS: int = 8
const MAX_CHUNKS: int = 40
const MAX_ACTIVE_FRAGMENTS: int = 140
const HOLD_SEC_MIN: float = 0.08
const HOLD_SEC_MAX: float = 0.15
const FADE_SEC: float = 0.12


static func start_staged_break(host: Node3D, payload: BreakPayload) -> void:
	if host == null or not host.is_inside_tree() or payload == null:
		return
	payload.wall_node = host
	payload.wall_name = host.name
	payload.wall_transform = host.global_transform

	_disable_host_collision(host)
	_apply_fracture_visual(host, payload.material, 1.0)

	var volume: float = payload.piece_size.x * payload.piece_size.y * payload.piece_size.z
	var chunk_count: int = chunk_count_for(payload.kind, payload.piece_size)
	print(
		"Wall destruction started: %s volume=%.2f chunks=%d"
		% [payload.wall_name, volume, chunk_count]
	)

	var hold: float = randf_range(HOLD_SEC_MIN, HOLD_SEC_MAX)
	host.get_tree().create_timer(hold).timeout.connect(
		Callable(WallDestruction, "_on_hold_complete").bind(payload)
	)


static func chunk_count_for(kind: DestructibleWall.WallKind, piece_size: Vector3) -> int:
	var volume: float = piece_size.x * piece_size.y * piece_size.z
	match kind:
		DestructibleWall.WallKind.THIN_SLAB:
			return clampi(int(lerpf(8.0, 12.0, volume / 3.5)), MIN_CHUNKS, 12)
		DestructibleWall.WallKind.HALF:
			return clampi(int(lerpf(8.0, 12.0, volume / 6.0)), MIN_CHUNKS, 12)
		DestructibleWall.WallKind.PILLAR:
			return clampi(int(lerpf(10.0, 18.0, volume / 8.0)), 10, 18)
		DestructibleWall.WallKind.OUTER_HEAVY:
			return clampi(int(lerpf(24.0, 40.0, volume / 35.0)), 24, MAX_CHUNKS)
		DestructibleWall.WallKind.FULL:
			return clampi(int(lerpf(14.0, 22.0, volume / 18.0)), 14, 22)
	return clampi(int(lerpf(10.0, 20.0, volume / 12.0)), MIN_CHUNKS, MAX_CHUNKS)


static func _on_hold_complete(payload: BreakPayload) -> void:
	if payload == null:
		return
	if payload.parent != null and not is_instance_valid(payload.parent):
		payload.parent = null
	var plans: Array[Dictionary] = build_fragment_plans(payload)
	DebrisFragment.spawn_fragment_plans(payload.parent, plans, payload.wall_name)
	print("Wall fragments spawned: %d" % plans.size())
	_fade_and_remove_host(payload)


static func build_fragment_plans(payload: BreakPayload) -> Array[Dictionary]:
	var count: int = chunk_count_for(payload.kind as DestructibleWall.WallKind, payload.piece_size)
	var plans: Array[Dictionary] = []
	var half: Vector3 = payload.piece_size * 0.48
	var hit_local: Vector3 = payload.wall_transform.affine_inverse() * payload.hit_world
	var src: String = payload.damage_source

	var chunk_mult: float = _source_chunk_mult(src)
	count = clampi(int(float(count) * chunk_mult), MIN_CHUNKS, MAX_CHUNKS)

	for i in count:
		var local_pos: Vector3 = Vector3(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y),
			randf_range(-half.z, half.z)
		)
		var frag_size: Vector3 = _random_fragment_size(payload.piece_size, src)
		var global_xform: Transform3D = _fragment_transform(payload.wall_transform, local_pos)
		var impulse: Vector3 = _fragment_impulse(
			local_pos, hit_local, payload.hit_direction, payload.wall_transform, src
		)
		var torque: Vector3 = Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)
		).normalized() * randf_range(1.5, 3.0)

		plans.append({
			"transform": global_xform,
			"size": frag_size,
			"impulse": impulse,
			"torque": torque,
			"material": payload.material,
		})
	return plans


static func _random_fragment_size(wall_size: Vector3, source: String) -> Vector3:
	var fx: float = randf_range(0.08, 0.22)
	var fy: float = randf_range(0.08, 0.20)
	var fz: float = randf_range(0.08, 0.22)
	match source:
		"shotgun":
			fx *= randf_range(0.6, 0.9)
			fy *= randf_range(0.6, 0.9)
			fz *= randf_range(0.6, 0.9)
		"railgun":
			fy *= randf_range(0.85, 1.1)
			fx *= randf_range(0.5, 0.85)
	return Vector3(
		clampf(wall_size.x * fx, 0.12, wall_size.x * 0.35),
		clampf(wall_size.y * fy, 0.10, wall_size.y * 0.32),
		clampf(wall_size.z * fz, 0.12, wall_size.z * 0.35)
	)


static func _fragment_transform(wall_xform: Transform3D, local_offset: Vector3) -> Transform3D:
	var basis: Basis = wall_xform.basis
	var pos: Vector3 = wall_xform * local_offset
	var rot: Basis = Basis.from_euler(
		Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
	)
	return Transform3D(basis * rot, pos)


static func _fragment_impulse(
	local_pos: Vector3,
	hit_local: Vector3,
	hit_direction: Vector3,
	wall_xform: Transform3D,
	source: String
) -> Vector3:
	var outward: Vector3 = local_pos
	if outward.length_squared() < 0.01:
		outward = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	outward = outward.normalized()

	var impact_radius: float = _source_impact_radius(source)
	var dist: float = local_pos.distance_to(hit_local)
	var impact_t: float = clampf(1.0 - dist / impact_radius, 0.0, 1.0)

	var h_force: float = lerpf(0.5, 2.5, impact_t) * _source_outward_mult(source)
	var up_force: float = lerpf(0.0, 1.2, impact_t * 0.65)

	var impulse_local: Vector3 = outward * h_force
	impulse_local.y -= 1.5
	impulse_local.y += up_force

	if source == "railgun" and hit_direction.length_squared() > 0.001:
		var fracture_dir: Vector3 = (wall_xform.basis.inverse() * hit_direction).normalized()
		impulse_local += fracture_dir * lerpf(0.4, 1.8, impact_t)

	if source.begins_with("bazooka"):
		impulse_local += outward * lerpf(0.3, 1.2, impact_t)

	return wall_xform.basis * impulse_local


static func _source_outward_mult(source: String) -> float:
	match source:
		"bazooka_direct", "bazooka_explosion":
			return 1.15
		"railgun":
			return 0.95
		"shotgun":
			return 0.75
	return 1.0


static func _source_chunk_mult(source: String) -> float:
	match source:
		"bazooka_direct", "bazooka_explosion":
			return 1.12
		"shotgun":
			return 0.92
	return 1.0


static func _source_impact_radius(source: String) -> float:
	match source:
		"bazooka_direct", "bazooka_explosion":
			return 2.8
		"railgun":
			return 1.6
		"shotgun":
			return 0.9
	return 1.4


static func _disable_host_collision(host: Node3D) -> void:
	if host is CollisionObject3D:
		(host as CollisionObject3D).collision_layer = 0
		(host as CollisionObject3D).collision_mask = 0
	for child in host.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true


static func apply_damage_visual(
	host: Node3D, base_mat: StandardMaterial3D, health_ratio: float
) -> void:
	var mesh: MeshInstance3D = _find_mesh(host)
	if mesh == null or base_mat == null:
		return
	var mat: StandardMaterial3D = base_mat.duplicate()
	mesh.material_override = mat
	var crack_t: float = 1.0 - clampf(health_ratio, 0.0, 1.0)
	var base_color: Color = base_mat.albedo_color
	mat.albedo_color = base_color.lerp(base_color.darkened(0.45), crack_t * 0.55)
	if crack_t > 0.25:
		mat.emission_enabled = true
		mat.emission = Color(0.55, 0.35, 0.22)
		mat.emission_energy_multiplier = crack_t * 0.35


static func _apply_fracture_visual(
	host: Node3D, base_mat: StandardMaterial3D, crack_t: float
) -> void:
	apply_damage_visual(host, base_mat, 1.0 - crack_t)


static func _fade_and_remove_host(payload: BreakPayload) -> void:
	var host: Node3D = payload.wall_node
	if host == null or not is_instance_valid(host):
		return
	var mesh: MeshInstance3D = _find_mesh(host)
	if mesh and mesh.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh.material_override.duplicate()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		var tween: Tween = host.create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.0, FADE_SEC)
		tween.tween_callback(host.queue_free)
	else:
		host.queue_free()
	print("Wall original removed after fracture")


static func _find_mesh(host: Node) -> MeshInstance3D:
	if host is MeshInstance3D:
		return host as MeshInstance3D
	for child in host.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null
