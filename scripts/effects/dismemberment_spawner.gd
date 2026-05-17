## Directional dismemberment — body parts + gibs keyed to weapon death profile.
class_name DismembermentSpawner
extends RefCounted

const VOID_DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/void_death_effect.tscn")

static var _active_parts: Array[WeakRef] = []


static func play_from_stats(
	world_root: Node,
	origin: Vector3,
	stats: CombatStats,
	flesh_color: Color,
	armor_color: Color,
	is_enemy: bool
) -> void:
	if world_root == null or stats == null:
		return
	var profile: String = stats.get_dismemberment_profile()
	var primary_dir: Vector3 = _resolve_primary_direction(stats, origin)
	_enforce_cap(world_root)

	if is_enemy:
		_print_enemy_debug(profile)

	_play_impact_flash(world_root, origin)
	_spawn_blood_mist(world_root, origin, profile)

	var force_scale: float = clampf(stats.last_hit_force / 40.0, 0.65, 1.35)
	var body_count: int = randi_range(
		GameBalance.DISMEMBER_BODY_PART_MIN, GameBalance.DISMEMBER_BODY_PART_MAX
	)
	var gib_count: int = randi_range(
		GameBalance.DISMEMBER_SMALL_GIB_MIN, GameBalance.DISMEMBER_SMALL_GIB_MAX
	)

	match profile:
		"explosion":
			_spawn_explosion_dismember(
				world_root, origin, stats, flesh_color, armor_color, body_count, gib_count, force_scale
			)
		"rocket_direct":
			_spawn_directed_dismember(
				world_root, origin, primary_dir, flesh_color, armor_color,
				body_count, gib_count, force_scale, 0.18, 0.35
			)
		"shotgun":
			_spawn_directed_dismember(
				world_root, origin, primary_dir, flesh_color, armor_color,
				body_count, gib_count, force_scale * 1.05, 0.28, 0.2
			)
		"railgun":
			_spawn_railgun_dismember(
				world_root, origin, primary_dir, flesh_color, armor_color,
				body_count, gib_count, force_scale
			)
		_:
			_spawn_directed_dismember(
				world_root, origin, primary_dir, flesh_color, armor_color,
				body_count, gib_count, force_scale, 0.25, 0.25
			)

	print(
		"Dismemberment spawned: profile=%s parts=%d gibs=%d"
		% [profile, body_count, gib_count]
	)


static func clear_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group("dismembered_body_part"):
		if node is Node:
			(node as Node).queue_free()
	for node in tree.get_nodes_in_group("gib_chunk"):
		if node is Node:
			(node as Node).queue_free()
	_active_parts.clear()


static func _resolve_primary_direction(stats: CombatStats, body_origin: Vector3) -> Vector3:
	if stats.last_damage_source == "bazooka_explosion" and stats.has_last_explosion_origin:
		var away: Vector3 = body_origin - stats.last_explosion_origin
		away.y = 0.0
		if away.length_squared() > 0.01:
			return away.normalized()
	if stats.last_hit_direction.length_squared() > 0.01:
		var d: Vector3 = stats.last_hit_direction
		d.y = clampf(d.y, -0.35, 0.35)
		if d.length_squared() > 0.01:
			return d.normalized()
	return Vector3.FORWARD


static func _spawn_explosion_dismember(
	parent: Node,
	origin: Vector3,
	stats: CombatStats,
	flesh: Color,
	armor: Color,
	body_count: int,
	gib_count: int,
	force_scale: float
) -> void:
	var blast_origin: Vector3 = origin
	if stats.has_last_explosion_origin:
		blast_origin = stats.last_explosion_origin
	var kinds: Array[BodyPartChunk.PartKind] = [
		BodyPartChunk.PartKind.TORSO,
		BodyPartChunk.PartKind.HEAD,
		BodyPartChunk.PartKind.ARM,
		BodyPartChunk.PartKind.ARM,
		BodyPartChunk.PartKind.LEG,
		BodyPartChunk.PartKind.ARMOR_SHARD,
	]
	for i in body_count:
		var kind: BodyPartChunk.PartKind = kinds[i % kinds.size()]
		var part: BodyPartChunk = _spawn_part(parent, origin, kind, flesh, armor)
		part.launch_radial(blast_origin, force_scale * 1.1)
	for _g in gib_count:
		var gib: BodyPartChunk = _spawn_part(
			parent, origin, BodyPartChunk.PartKind.SMALL_GIB, flesh, armor
		)
		gib.launch_radial(blast_origin, force_scale * 0.85)


static func _spawn_directed_dismember(
	parent: Node,
	origin: Vector3,
	primary_dir: Vector3,
	flesh: Color,
	armor: Color,
	body_count: int,
	gib_count: int,
	force_scale: float,
	lateral_spread: float,
	upward_bias: float
) -> void:
	var kinds: Array[BodyPartChunk.PartKind] = [
		BodyPartChunk.PartKind.TORSO,
		BodyPartChunk.PartKind.HEAD,
		BodyPartChunk.PartKind.ARM,
		BodyPartChunk.PartKind.LEG,
		BodyPartChunk.PartKind.ARMOR_SHARD,
	]
	for i in body_count:
		var kind: BodyPartChunk.PartKind = kinds[i % kinds.size()]
		var part: BodyPartChunk = _spawn_part(parent, origin, kind, flesh, armor)
		var spread: float = lateral_spread if kind != BodyPartChunk.PartKind.TORSO else lateral_spread * 0.5
		part.launch_impulse(primary_dir, force_scale, spread, upward_bias)
	for _g in gib_count:
		var gib: BodyPartChunk = _spawn_part(
			parent, origin, BodyPartChunk.PartKind.SMALL_GIB, flesh, armor
		)
		gib.launch_impulse(primary_dir, force_scale * 0.9, lateral_spread * 1.2, upward_bias * 0.5)


static func _spawn_railgun_dismember(
	parent: Node,
	origin: Vector3,
	beam_dir: Vector3,
	flesh: Color,
	armor: Color,
	body_count: int,
	gib_count: int,
	force_scale: float
) -> void:
	var kinds: Array[BodyPartChunk.PartKind] = [
		BodyPartChunk.PartKind.TORSO,
		BodyPartChunk.PartKind.HEAD,
		BodyPartChunk.PartKind.ARM,
		BodyPartChunk.PartKind.LEG,
	]
	for i in body_count:
		var kind: BodyPartChunk.PartKind = kinds[i % kinds.size()]
		var part: BodyPartChunk = _spawn_part(parent, origin, kind, flesh, armor)
		var offset_origin: Vector3 = origin + beam_dir * float(i) * 0.12
		part.global_position = offset_origin + _cluster_offset(0.35)
		part.launch_impulse(beam_dir, force_scale * 1.15, 0.08, 1.5)
	for _g in gib_count:
		var gib: BodyPartChunk = _spawn_part(
			parent, origin, BodyPartChunk.PartKind.SMALL_GIB, flesh, armor
		)
		gib.global_position = origin + beam_dir * randf_range(0.0, 0.8)
		gib.launch_impulse(beam_dir, force_scale, 0.12, 0.5)


static func _spawn_part(
	parent: Node,
	origin: Vector3,
	kind: BodyPartChunk.PartKind,
	flesh: Color,
	armor: Color
) -> BodyPartChunk:
	var part: BodyPartChunk = BodyPartChunk.SCENE.instantiate() as BodyPartChunk
	parent.add_child(part)
	part.global_position = origin + _cluster_offset(0.55)
	part.configure(kind, flesh, armor)
	_track_part(part)
	return part


static func _cluster_offset(radius: float) -> Vector3:
	var off: Vector3 = Vector3(
		randf_range(-1.0, 1.0), randf_range(-0.2, 0.35), randf_range(-1.0, 1.0)
	)
	if off.length_squared() < 0.001:
		return Vector3.ZERO
	return off.normalized() * randf_range(0.05, radius)


static func _track_part(part: BodyPartChunk) -> void:
	_active_parts.append(weakref(part))
	_trim_active()


static func _trim_active() -> void:
	var alive: Array[WeakRef] = []
	for ref in _active_parts:
		var node: Object = ref.get_ref()
		if node != null and is_instance_valid(node):
			alive.append(ref)
	_active_parts = alive
	while _active_parts.size() > GameBalance.DISMEMBER_MAX_ACTIVE_PARTS:
		var ref: WeakRef = _active_parts[0]
		_active_parts.remove_at(0)
		var node: Object = ref.get_ref()
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()


static func _enforce_cap(parent: Node) -> void:
	var tree: SceneTree = parent.get_tree()
	if tree:
		_trim_active()
		while _active_parts.size() > GameBalance.DISMEMBER_MAX_ACTIVE_PARTS - 8:
			if _active_parts.is_empty():
				break
			var ref: WeakRef = _active_parts[0]
			_active_parts.remove_at(0)
			var node: Object = ref.get_ref()
			if node != null and is_instance_valid(node):
				(node as Node).queue_free()


static func _play_impact_flash(parent: Node, position: Vector3) -> void:
	var effect: Node3D = VOID_DEATH_EFFECT_SCENE.instantiate() as Node3D
	parent.add_child(effect)
	if effect.has_method("_start_collapse_flash"):
		effect.call("_start_collapse_flash", position)


static func _spawn_blood_mist(parent: Node, position: Vector3, profile: String) -> void:
	var mist: CPUParticles3D = CPUParticles3D.new()
	parent.add_child(mist)
	mist.global_position = position
	mist.add_to_group("void_effect")
	mist.amount = 28 if profile == "explosion" else 22
	mist.lifetime = 0.65
	mist.one_shot = true
	mist.explosiveness = 1.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 0.35
	mist.direction = Vector3(0, -0.25, 0)
	mist.spread = 118.0
	mist.gravity = Vector3(0, -7, 0)
	mist.initial_velocity_min = 0.6
	mist.initial_velocity_max = 2.8
	mist.color = Color(0.18, 0.03, 0.05, 0.8)
	mist.emitting = true
	mist.get_tree().create_timer(1.2).timeout.connect(mist.queue_free)


static func _print_enemy_debug(profile: String) -> void:
	match profile:
		"explosion", "rocket_direct":
			print("Enemy dismembered by bazooka")
		"shotgun":
			print("Enemy dismembered by shotgun")
		"railgun":
			print("Enemy dismembered by railgun")
		_:
			print("Enemy dismembered")
