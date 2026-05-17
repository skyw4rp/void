## One modular tile in a perforable wall grid — removed by railgun for a real opening.
class_name WallPerforationCell
extends StaticBody3D

var grid_owner: Node = null
var cell_x: int = 0
var cell_y: int = 0

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _removed: bool = false


func setup(
	grid: Node,
	col: int,
	row: int,
	local_center: Vector3,
	cell_size: Vector3,
	material: StandardMaterial3D
) -> void:
	grid_owner = grid
	cell_x = col
	cell_y = row
	name = "Cell_%d_%d" % [col, row]
	collision_layer = 1
	collision_mask = 1

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = cell_size
	_mesh.mesh = box
	_mesh.material_override = material
	add_child(_mesh)

	_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = cell_size
	_shape.shape = shape
	add_child(_shape)

	position = local_center


func get_wall_grid() -> Node:
	return grid_owner


func is_removed() -> bool:
	return _removed


func remove_cell() -> void:
	if _removed:
		return
	_removed = true
	_mesh.visible = false
	_shape.disabled = true
	collision_layer = 0
	collision_mask = 0


func restore_cell() -> void:
	_removed = false
	_mesh.visible = true
	_shape.disabled = false
	collision_layer = 1
	collision_mask = 1


func tint_material(material: StandardMaterial3D) -> void:
	if _mesh:
		_mesh.material_override = material
