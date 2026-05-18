## Builds floor slabs and destructible walls from template data.
class_name ArenaStructureBuilder
extends RefCounted

const FLOOR_GROUP: String = "arena_floor"
const WALL_GROUP: String = "arena_wall"
const STRUCTURAL_WALL_GROUP: String = "structural_wall"


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = template.floor_albedo
	floor_mat.roughness = 0.92
	floor_mat.metallic = 0.15

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = template.wall_albedo
	wall_mat.roughness = 0.9
	wall_mat.metallic = 0.22

	var structural_mat := StandardMaterial3D.new()
	structural_mat.albedo_color = template.wall_albedo.lerp(Color(0.04, 0.045, 0.05), 0.25)
	structural_mat.roughness = 0.94
	structural_mat.metallic = 0.28
	structural_mat.emission_enabled = true
	structural_mat.emission = Color(0.05, 0.07, 0.09)
	structural_mat.emission_energy_multiplier = 0.22

	var arena_slug: String = _arena_slug(template.arena_name)
	var floor_index: int = 0
	for piece in template.floor_pieces:
		floor_index += 1
		var node_name: String
		if piece.is_connector:
			node_name = "StructuralConnector_%s" % arena_slug
		else:
			node_name = "StructuralFloor_%s_%02d" % [arena_slug, floor_index]
		add_structural_floor(
			parent,
			template.center_position,
			piece.size,
			piece.position,
			floor_mat,
			node_name,
			piece.is_connector
		)

	var structural_index: int = 0
	for piece in template.structural_wall_pieces:
		structural_index += 1
		_add_structural_wall(
			parent,
			template.center_position,
			piece,
			structural_mat,
			"%03d" % structural_index
		)

	var wall_index: int = 0
	for piece in template.wall_pieces:
		wall_index += 1
		var wmat := wall_mat.duplicate() as StandardMaterial3D
		if piece.size.y < 1.6:
			wmat.albedo_color = template.wall_albedo.lerp(Color(0.1, 0.11, 0.12), 0.35)
		_add_destructible_wall(
			parent,
			template.center_position,
			piece.size,
			piece.position,
			wmat,
			"%03d" % wall_index
		)

	ArenaBrutalistModules.build(parent, template)
	ArenaPerimeterBuilder.build(parent, template)
	ArenaFallZoneBuilder.build(parent, template)


static func add_structural_floor(
	parent: Node3D,
	arena_center: Vector3,
	size: Vector3,
	local_center: Vector3,
	mat: StandardMaterial3D,
	node_name: String,
	is_connector: bool = false
) -> void:
	var body := StructuralFloor.new()
	body.setup_structural(node_name, is_connector)
	body.collision_layer = 1
	body.collision_mask = 1

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


static func _add_destructible_wall(
	parent: Node3D,
	arena_center: Vector3,
	size: Vector3,
	local_center: Vector3,
	mat: StandardMaterial3D,
	name_suffix: String
) -> void:
	var kind: DestructibleWall.WallKind = DestructibleWall.infer_kind_from_size(size)
	var wall := DestructibleWall.new()
	wall.collision_layer = 1
	wall.collision_mask = 1

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape

	wall.add_child(mesh_inst)
	wall.add_child(col)
	parent.add_child(wall)
	wall.global_position = arena_center + local_center
	wall.setup_wall(kind, mesh_inst, size, false, name_suffix)


static func _add_structural_wall(
	parent: Node3D,
	arena_center: Vector3,
	piece: ArenaTemplate.StructuralWallPiece,
	mat: StandardMaterial3D,
	name_suffix: String
) -> void:
	var wall := StructuralWall.new()
	wall.collision_layer = 1
	wall.collision_mask = 1

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = piece.size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = piece.size
	col.shape = box_shape

	wall.add_child(mesh_inst)
	wall.add_child(col)
	parent.add_child(wall)
	wall.global_position = arena_center + piece.position
	wall.setup_structural_wall(piece.kind as StructuralWall.Kind, mesh_inst, piece.size, name_suffix)


static func _arena_slug(arena_name: String) -> String:
	return arena_name.replace(" ", "")


static func _wall_kind_name(kind: DestructibleWall.WallKind) -> String:
	return DestructibleWall.kind_display_name(kind)
