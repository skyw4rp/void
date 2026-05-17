## Non-destructible arena floor / route connector — named, grouped for hit routing.
class_name StructuralFloor
extends StaticBody3D

const GROUP_STRUCTURAL: String = "structural_geometry"
const GROUP_FLOOR: String = "arena_floor"
const GROUP_CONNECTOR: String = "structural_connector"


func setup_structural(node_name: String, is_connector: bool) -> void:
	name = node_name
	add_to_group(GROUP_STRUCTURAL)
	add_to_group(GROUP_FLOOR)
	if is_connector:
		add_to_group(GROUP_CONNECTOR)


static func is_structural_node(node: Node) -> bool:
	return node != null and node.is_in_group(GROUP_STRUCTURAL)
