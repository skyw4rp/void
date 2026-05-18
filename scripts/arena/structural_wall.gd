## Permanent arena architecture — collision, no damage, defines maze routes.
class_name StructuralWall
extends StaticBody3D

enum Kind { MASSIVE, DIVIDER, SLAB, MONOLITH, GATE_POST, L_WING }

const GROUP_STRUCTURAL: String = "structural_geometry"
const GROUP_ARENA_WALL: String = "arena_wall"
const GROUP_STRUCTURAL_WALL: String = "structural_wall"


func setup_structural_wall(
	kind: Kind,
	mesh: MeshInstance3D,
	piece_size: Vector3,
	name_suffix: String = ""
) -> void:
	name = "StructuralWall_%s_%s" % [_kind_slug(kind), name_suffix]
	add_to_group(GROUP_STRUCTURAL)
	add_to_group(GROUP_ARENA_WALL)
	add_to_group(GROUP_STRUCTURAL_WALL)


static func is_structural_wall_node(node: Node) -> bool:
	return node != null and node.is_in_group(GROUP_STRUCTURAL_WALL)


static func _kind_slug(kind: Kind) -> String:
	match kind:
		Kind.MASSIVE:
			return "Massive"
		Kind.DIVIDER:
			return "Divider"
		Kind.SLAB:
			return "Slab"
		Kind.MONOLITH:
			return "Monolith"
		Kind.GATE_POST:
			return "GatePost"
		Kind.L_WING:
			return "LWing"
		_:
			return "Wall"
