## Entry-only energy mark on pierced walls — parented to host, no geometry cut.
class_name RailgunPierceMark
extends Node3D

const MARK_SCENE: PackedScene = preload("res://scenes/effects/railgun_pierce_mark.tscn")
const GROUP: String = "railgun_pierce_mark"

const SURFACE_OFFSET: float = 0.012
const LIFETIME_MIN_SEC: float = 8.0
const LIFETIME_MAX_SEC: float = 12.0
const DIAMETER_MIN: float = 0.35
const DIAMETER_MAX: float = 0.5


static func spawn_entry_on_host(
	host: Node3D, hit_world: Vector3, hit_normal: Vector3, beam_dir: Vector3
) -> void:
	if host == null or not is_instance_valid(host):
		return
	var entry_nrm: Vector3 = hit_normal.normalized()
	if entry_nrm.length_squared() < 0.0001:
		entry_nrm = -beam_dir.normalized()

	var mark: RailgunPierceMark = MARK_SCENE.instantiate() as RailgunPierceMark
	host.add_child(mark)
	mark.setup(host, hit_world, entry_nrm)
	print("Railgun entry mark spawned")


## Legacy name — entry only (exit marks removed).
static func spawn_pair_on_host(
	host: Node3D,
	hit_world: Vector3,
	hit_normal: Vector3,
	beam_dir: Vector3
) -> void:
	spawn_entry_on_host(host, hit_world, hit_normal, beam_dir)


func setup(host: Node3D, world_pos: Vector3, surface_outward: Vector3) -> void:
	add_to_group(GROUP)
	_host = host
	var n: Vector3 = surface_outward.normalized()
	if n.length_squared() < 0.0001:
		n = Vector3.FORWARD

	var diameter: float = randf_range(DIAMETER_MIN, DIAMETER_MAX)
	_apply_visuals(diameter)

	var local_pos: Vector3 = host.to_local(world_pos)
	var local_n: Vector3 = host.global_basis.inverse() * n
	position = local_pos + local_n * SURFACE_OFFSET
	basis = host.global_basis.inverse() * _basis_for_normal(n)

	scale = Vector3.ONE * 0.85
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	_start_fade_lifetime()


var _host: Node3D


func _apply_visuals(diameter: float) -> void:
	var ring: MeshInstance3D = get_node_or_null("Ring") as MeshInstance3D
	var core: MeshInstance3D = get_node_or_null("Core") as MeshInstance3D
	var radius: float = diameter * 0.5
	if ring and ring.mesh is CylinderMesh:
		(ring.mesh as CylinderMesh).top_radius = radius
		(ring.mesh as CylinderMesh).bottom_radius = radius
	if core and core.mesh is CylinderMesh:
		(core.mesh as CylinderMesh).top_radius = radius * 0.42
		(core.mesh as CylinderMesh).bottom_radius = radius * 0.42

	if ring and ring.material_override is StandardMaterial3D:
		var rmat: StandardMaterial3D = (ring.material_override as StandardMaterial3D).duplicate()
		rmat.emission = Color(0.38, 0.68, 1.0)
		rmat.emission_energy_multiplier = 1.55
		ring.material_override = rmat


func _start_fade_lifetime() -> void:
	var lifetime: float = randf_range(LIFETIME_MIN_SEC, LIFETIME_MAX_SEC)
	var fade_start: float = maxf(lifetime - 1.2, lifetime * 0.65)
	get_tree().create_timer(fade_start).timeout.connect(_begin_fade)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _begin_fade() -> void:
	if not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", scale * 0.7, 1.0)
	_fade_materials(get_node_or_null("Ring") as MeshInstance3D)
	_fade_materials(get_node_or_null("Core") as MeshInstance3D)


func _fade_materials(mesh: MeshInstance3D) -> void:
	if mesh == null or not mesh.material_override is StandardMaterial3D:
		return
	var mat: StandardMaterial3D = (mesh.material_override as StandardMaterial3D).duplicate()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	var tween: Tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)


static func clear_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group(GROUP):
		if is_instance_valid(node):
			(node as Node).queue_free()


static func _basis_for_normal(normal: Vector3) -> Basis:
	var n: Vector3 = normal.normalized()
	var tangent: Vector3 = n.cross(Vector3.UP)
	if tangent.length_squared() < 0.0001:
		tangent = n.cross(Vector3.RIGHT)
	tangent = tangent.normalized()
	var bitangent: Vector3 = tangent.cross(n)
	return Basis(tangent, n, bitangent)
