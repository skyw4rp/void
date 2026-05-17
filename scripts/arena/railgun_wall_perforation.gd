## Deprecated — modular/CSG railgun wall holes removed from prototype.
class_name RailgunWallPerforation
extends RefCounted


static func remove_cells(
	_grid: Node, _hit_world: Vector3, _beam_dir: Vector3, _surface_normal: Vector3
) -> bool:
	return false


static func remove_cells_from_collider(
	_grid: Node,
	_hit_cell: Node,
	_hit_world: Vector3,
	_beam_dir: Vector3,
	_surface_normal: Vector3
) -> bool:
	return false
