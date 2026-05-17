## Brief railgun hit flash — scene-root parented, auto-despawn (no persistent wall marks).
class_name RailgunImpactFlash
extends Node3D

const FLASH_SCENE: PackedScene = preload("res://scenes/effects/railgun_impact_flash.tscn")
const GROUP: String = "railgun_impact_flash"

const LIFETIME_MIN_SEC: float = 0.25
const LIFETIME_MAX_SEC: float = 0.6


static func spawn(
	parent: Node,
	world_position: Vector3,
	surface_normal: Vector3 = Vector3.UP,
	beam_emission: Color = Color(0.5, 0.85, 1.0)
) -> void:
	if parent == null:
		return
	var flash: RailgunImpactFlash = FLASH_SCENE.instantiate() as RailgunImpactFlash
	parent.add_child(flash)
	flash.setup(world_position, surface_normal, beam_emission)


func setup(world_position: Vector3, surface_normal: Vector3, beam_emission: Color) -> void:
	add_to_group(GROUP)
	var n: Vector3 = surface_normal.normalized()
	if n.length_squared() < 0.0001:
		n = Vector3.UP
	global_position = world_position + n * 0.02

	var core: MeshInstance3D = get_node_or_null("Core") as MeshInstance3D
	var sparks: MeshInstance3D = get_node_or_null("Sparks") as MeshInstance3D
	if core and core.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = (core.material_override as StandardMaterial3D).duplicate()
		mat.emission = beam_emission
		core.material_override = mat
	if sparks and sparks.material_override is StandardMaterial3D:
		var smat: StandardMaterial3D = (sparks.material_override as StandardMaterial3D).duplicate()
		smat.emission = beam_emission.lerp(Color.WHITE, 0.35)
		sparks.material_override = smat

	var lifetime: float = randf_range(LIFETIME_MIN_SEC, LIFETIME_MAX_SEC)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


static func clear_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group(GROUP):
		if is_instance_valid(node):
			(node as Node).queue_free()
