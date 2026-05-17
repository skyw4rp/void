## Deprecated — persistent railgun wall decals removed; use RailgunImpactFlash.
class_name RailgunImpactHole
extends Node3D


static func spawn(_parent: Node, _hit_position: Vector3, _surface_normal: Vector3) -> void:
	pass


static func spawn_on_wall_hit(_scene_root: Node, _hit_position: Vector3, _surface_normal: Vector3) -> void:
	pass


static func clear_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group("railgun_impact_hole"):
		if is_instance_valid(node):
			(node as Node).queue_free()
