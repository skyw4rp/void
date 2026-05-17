## Builds floor slabs from template data — mesh and collision share the same size.
class_name ArenaFloorBuilder
extends RefCounted

const FLOOR_GROUP: String = "arena_floor"


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = template.floor_albedo
	mat.roughness = 0.92
	mat.metallic = 0.15

	for piece in template.floor_pieces:
		_add_slab(parent, template.center_position, piece, mat)


static func _add_slab(
	parent: Node3D, arena_center: Vector3, piece: ArenaTemplate.FloorPiece, mat: StandardMaterial3D
) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group(FLOOR_GROUP)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = piece.size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = piece.size
	col.shape = box_shape

	body.add_child(mesh_inst)
	body.add_child(col)
	parent.add_child(body)

	var world_center: Vector3 = arena_center + piece.position
	body.global_position = world_center
