## Spawns fast collapse gib bursts for rocket / overkill kills.
class_name GibSpawner
extends RefCounted

const VOID_DEATH_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/void_death_effect.tscn")


static func play_heavy_death(
	world_root: Node,
	origin: Vector3,
	direction: Vector3,
	_force: float = 0.0,
	_damage_source: String = ""
) -> void:
	# Legacy entry — dismemberment is handled by DismembermentSpawner at death sites.
	if world_root == null:
		return
	var tree: SceneTree = world_root.get_tree()
	if tree == null:
		return
	_run_collapse_async(tree, world_root, origin, direction)


static func _run_collapse_async(
	tree: SceneTree, parent: Node, origin: Vector3, direction: Vector3
) -> void:
	_play_collapse_flash(parent, origin)
	await tree.create_timer(GameBalance.GIB_COLLAPSE_SPAWN_DELAY_SEC).timeout
	var count: int = randi_range(GameBalance.GIB_COUNT_MIN, GameBalance.GIB_COUNT_MAX)
	spawn_collapse_burst(parent, origin, count, direction)
	print("Gib collapse spawned %d chunks" % count)


static func spawn_collapse_burst(
	parent: Node, origin: Vector3, count: int, direction: Vector3
) -> void:
	_spawn_blood_mist(parent, origin)
	for _i in count:
		var chunk: RigidBody3D = GibChunk.SCENE.instantiate() as RigidBody3D
		parent.add_child(chunk)
		chunk.global_position = origin + _random_cluster_offset()
		var pop_upward: bool = randf() < 0.18
		if chunk.has_method("launch_collapse"):
			chunk.call("launch_collapse", direction, pop_upward)


static func _random_cluster_offset() -> Vector3:
	var offset: Vector3 = Vector3(
		randf_range(-1.0, 1.0), randf_range(-0.35, 0.45), randf_range(-1.0, 1.0)
	)
	if offset.length_squared() < 0.0001:
		return Vector3.ZERO
	var radius: float = randf_range(0.05, GameBalance.GIB_CLUSTER_RADIUS)
	return offset.normalized() * radius


static func _play_collapse_flash(parent: Node, position: Vector3) -> void:
	var effect: Node3D = VOID_DEATH_EFFECT_SCENE.instantiate() as Node3D
	parent.add_child(effect)
	if effect.has_method("_start_collapse_flash"):
		effect.call("_start_collapse_flash", position)


static func _spawn_blood_mist(parent: Node, position: Vector3) -> void:
	var mist: CPUParticles3D = CPUParticles3D.new()
	parent.add_child(mist)
	mist.global_position = position
	mist.add_to_group("void_effect")
	mist.amount = 20
	mist.lifetime = 0.55
	mist.one_shot = true
	mist.explosiveness = 1.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 0.28
	mist.direction = Vector3(0, -0.35, 0)
	mist.spread = 125.0
	mist.gravity = Vector3(0, -6, 0)
	mist.initial_velocity_min = 0.4
	mist.initial_velocity_max = 2.2
	mist.color = Color(0.2, 0.03, 0.05, 0.75)
	mist.emitting = true
	mist.get_tree().create_timer(1.0).timeout.connect(mist.queue_free)
