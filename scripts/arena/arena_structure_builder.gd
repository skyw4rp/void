## Builds floor slabs and static walls from template data.
class_name ArenaStructureBuilder
extends RefCounted

const FLOOR_GROUP: String = "arena_floor"
const WALL_GROUP: String = "arena_wall"


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = template.floor_albedo
	floor_mat.roughness = 0.92
	floor_mat.metallic = 0.15

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = template.wall_albedo
	wall_mat.roughness = 0.9
	wall_mat.metallic = 0.22

	for piece in template.floor_pieces:
		_add_box_body(parent, template.center_position, piece.size, piece.position, floor_mat, FLOOR_GROUP)

	for piece in template.wall_pieces:
		var wmat := wall_mat.duplicate() as StandardMaterial3D
		if piece.size.y < 1.6:
			wmat.albedo_color = template.wall_albedo.lerp(Color(0.1, 0.11, 0.12), 0.35)
		_add_box_body(parent, template.center_position, piece.size, piece.position, wmat, WALL_GROUP)

	ArenaPerimeterBuilder.build(parent, template)
	ArenaFallZoneBuilder.build(parent, template)


static func _add_box_body(
	parent: Node3D,
	arena_center: Vector3,
	size: Vector3,
	local_center: Vector3,
	mat: StandardMaterial3D,
	group_name: String
) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group(group_name)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape

	body.add_child(mesh_inst)
	body.add_child(col)
	parent.add_child(body)
	body.global_position = arena_center + local_center
