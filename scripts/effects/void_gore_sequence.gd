## Orchestrates the VOID_GORE pit-death cinematic timeline.
class_name VoidGoreSequence
extends RefCounted

const AMBIENT_SCENE: PackedScene = preload("res://scenes/effects/void_ambient_particles.tscn")
const VoidDeathEffect = preload("res://scripts/effects/void_death_effect.gd")


static func run(world_root: Node, fighter: Node, tree: SceneTree) -> void:
	print("Void death style: VOID_GORE (cinematic)")

	if fighter and fighter.has_method("begin_void_instability"):
		fighter.call("begin_void_instability")

	await tree.create_timer(GameBalance.VOID_GORE_INSTABILITY_SEC).timeout

	await tree.create_timer(
		GameBalance.VOID_GORE_AMBIENT_AT - GameBalance.VOID_GORE_INSTABILITY_SEC
	).timeout
	VoidAudio.play_void_wind()
	_spawn_ambient(world_root, _fighter_position(fighter))

	await tree.create_timer(
		GameBalance.VOID_GORE_CORRUPTION_AT - GameBalance.VOID_GORE_AMBIENT_AT
	).timeout
	VoidCorruptionCloud.spawn(world_root, _fighter_position(fighter))

	await tree.create_timer(
		GameBalance.VOID_GORE_BREAKUP_AT - GameBalance.VOID_GORE_CORRUPTION_AT
	).timeout
	VoidAudio.play_body_rupture()
	var break_pos: Vector3 = _fighter_position(fighter)
	if fighter and fighter.has_method("hide_for_void_breakup"):
		fighter.call("hide_for_void_breakup")
	var chunk_count: int = randi_range(GameBalance.GIB_COUNT_MIN, GameBalance.GIB_COUNT_MAX)
	GibSpawner.spawn_collapse_burst(world_root, break_pos, chunk_count, Vector3.DOWN)
	_spawn_blood_mist(world_root, break_pos)

	await tree.create_timer(
		GameBalance.VOID_GORE_BURST_AT - GameBalance.VOID_GORE_BREAKUP_AT
	).timeout
	VoidAudio.play_disintegration_burst()
	VoidDeathEffect.play_final_burst(world_root, _fighter_position(fighter))

	schedule_post_absorption_horror(world_root, break_pos, tree)


## Delayed impact or silence; optional distant abyss flash — runs during countdown.
static func schedule_post_absorption_horror(
	world_root: Node, fall_position: Vector3, tree: SceneTree
) -> void:
	var silent: bool = randf() < GameBalance.VOID_SILENT_ABSORPTION_CHANCE
	var impact_delay: float = randf_range(
		GameBalance.VOID_IMPACT_SOUND_DELAY_MIN, GameBalance.VOID_IMPACT_SOUND_DELAY_MAX
	)
	tree.create_timer(impact_delay).timeout.connect(
		func() -> void: VoidAudio.play_void_absorption(silent)
	)

	if randf() >= GameBalance.VOID_DISTANT_FLASH_CHANCE:
		return
	var flash_delay: float = randf_range(
		GameBalance.VOID_DISTANT_FLASH_DELAY_MIN, GameBalance.VOID_DISTANT_FLASH_DELAY_MAX
	)
	tree.create_timer(flash_delay).timeout.connect(
		func() -> void: _trigger_distant_flash(world_root, fall_position)
	)


static func _trigger_distant_flash(world_root: Node, fall_position: Vector3) -> void:
	var atmo: Node = world_root.get_tree().get_first_node_in_group("void_atmosphere")
	var flash_pos: Vector3 = fall_position + Vector3(0.0, -35.0, randf_range(-8.0, 8.0))
	if atmo and atmo.has_method("trigger_distant_flash"):
		atmo.call("trigger_distant_flash", flash_pos)


static func _fighter_position(fighter: Node) -> Vector3:
	if fighter == null:
		return Vector3(0.0, -24.0, 0.0)
	if fighter.has_method("get_void_breakup_position"):
		return fighter.call("get_void_breakup_position")
	if fighter is Node3D:
		return (fighter as Node3D).global_position
	return Vector3.ZERO


static func _spawn_ambient(parent: Node, position: Vector3) -> void:
	var ambient: Node3D = AMBIENT_SCENE.instantiate() as Node3D
	parent.add_child(ambient)
	ambient.global_position = position
	if ambient.has_method("activate"):
		ambient.call("activate")


static func _spawn_blood_mist(parent: Node, position: Vector3) -> void:
	var mist: CPUParticles3D = CPUParticles3D.new()
	parent.add_child(mist)
	mist.global_position = position
	mist.add_to_group("void_effect")
	mist.amount = 16
	mist.lifetime = 1.2
	mist.one_shot = true
	mist.explosiveness = 1.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 0.45
	mist.direction = Vector3(0, 1, 0)
	mist.spread = 160.0
	mist.gravity = Vector3(0, -3, 0)
	mist.initial_velocity_min = 0.8
	mist.initial_velocity_max = 3.0
	mist.color = Color(0.22, 0.04, 0.06, 0.7)
	mist.emitting = true
	mist.get_tree().create_timer(2.0).timeout.connect(mist.queue_free)
