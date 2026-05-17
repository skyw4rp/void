## Legacy floor builder — delegates to StructuralFloor naming (prefer ArenaStructureBuilder).
class_name ArenaFloorBuilder
extends RefCounted

const FLOOR_GROUP: String = "arena_floor"


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = template.floor_albedo
	mat.roughness = 0.92
	mat.metallic = 0.15

	var arena_slug: String = template.arena_name.replace(" ", "")
	var floor_index: int = 0
	for piece in template.floor_pieces:
		floor_index += 1
		var node_name: String
		if piece.is_connector:
			node_name = "StructuralConnector_%s" % arena_slug
		else:
			node_name = "StructuralFloor_%s_%02d" % [arena_slug, floor_index]
		ArenaStructureBuilder.add_structural_floor(
			parent,
			template.center_position,
			piece.size,
			piece.position,
			mat,
			node_name,
			piece.is_connector
		)
