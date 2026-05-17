## Destructible wall built from removable cells — clean railgun see-through holes.
class_name PerforableWallGrid
extends DestructibleWall

var _cells: Array = []
var _grid_cols: int = 1
var _grid_rows: int = 1
var _cell_size: Vector3 = Vector3.ONE
var _cells_root: Node3D
var _rims_root: Node3D
var _width_axis: int = 0
var _height_axis: int = 1
var _depth_axis: int = 2


static func should_use_modular(kind: WallKind, size: Vector3) -> bool:
	match kind:
		WallKind.THIN_SLAB, WallKind.HALF:
			return true
		WallKind.FULL:
			var footprint: float = maxf(size.x, size.z)
			return size.y < 2.6 and footprint < 6.5
		_:
			return false


static func build(
	parent: Node3D,
	arena_center: Vector3,
	local_center: Vector3,
	size: Vector3,
	mat: StandardMaterial3D,
	name_suffix: String,
	kind: WallKind,
	add_perimeter_group: bool = false
) -> PerforableWallGrid:
	var wall := PerforableWallGrid.new()
	wall.collision_layer = 0
	wall.collision_mask = 0
	parent.add_child(wall)
	wall.global_position = arena_center + local_center
	wall.setup_grid(kind, size, mat, name_suffix, add_perimeter_group)
	return wall


func setup_grid(
	kind: WallKind,
	piece_size: Vector3,
	material: StandardMaterial3D,
	name_suffix: String = "",
	add_perimeter_group: bool = false
) -> void:
	_kind = kind
	_piece_size = piece_size
	_max_health = HEALTH.get(kind, 140)
	_health = _max_health
	_broken = false
	_destroying = false
	is_perforable = true
	railgun_holes.clear()
	_base_material = material.duplicate() if material else null

	if name_suffix != "":
		name = "PerforableWall_%s_%s" % [kind_display_name(kind), name_suffix]
	ensure_named()
	add_to_group(DESTRUCTIBLE_GROUP)
	add_to_group(PERFORABLE_GROUP)
	add_to_group(WALL_GROUP)
	if add_perimeter_group:
		add_to_group("arena_perimeter")

	_build_cell_grid()


func _build_cell_grid() -> void:
	_cells.clear()
	if _cells_root and is_instance_valid(_cells_root):
		_cells_root.queue_free()
	if _rims_root and is_instance_valid(_rims_root):
		_rims_root.queue_free()

	_cells_root = Node3D.new()
	_cells_root.name = "Cells"
	add_child(_cells_root)

	_rims_root = Node3D.new()
	_rims_root.name = "PerforationRims"
	add_child(_rims_root)

	var layout: Dictionary = _compute_grid_layout(_piece_size, _kind)
	_grid_cols = layout.cols
	_grid_rows = layout.rows
	_cell_size = layout.cell_size

	_width_axis = layout.width_axis
	_height_axis = layout.height_axis
	_depth_axis = layout.depth_axis
	var width_axis: int = _width_axis
	var height_axis: int = _height_axis
	var depth_axis: int = _depth_axis
	var origin: Vector3 = layout.origin

	for row in _grid_rows:
		for col in _grid_cols:
			var local_pos := Vector3.ZERO
			local_pos[width_axis] = origin[width_axis] + (col + 0.5) * _cell_size[width_axis]
			local_pos[height_axis] = origin[height_axis] + (row + 0.5) * _cell_size[height_axis]
			local_pos[depth_axis] = origin[depth_axis] + 0.5 * _cell_size[depth_axis]

			var cell := WallPerforationCell.new()
			_cells_root.add_child(cell)
			cell.setup(self, col, row, local_pos, _cell_size, _base_material)
			_cells.append(cell)


func _compute_grid_layout(size: Vector3, kind: WallKind) -> Dictionary:
	var thickness_axis: int = 0
	var min_dim: float = size.x
	if size.y < min_dim:
		min_dim = size.y
		thickness_axis = 1
	if size.z < min_dim:
		thickness_axis = 2

	var height_axis: int = 1
	var width_axis: int = 0
	if thickness_axis == 1:
		height_axis = 2 if size.z >= size.x else 0
		width_axis = 2 if height_axis == 2 else 0
	elif thickness_axis == 2:
		height_axis = 1
		width_axis = 0
	else:
		height_axis = 1
		width_axis = 2 if size.z > size.x else 0

	var width: float = size[width_axis]
	var height: float = size[height_axis]
	var depth: float = size[thickness_axis]

	var cell_pitch: float = WeaponDefs.RAILGUN_CELL_TARGET_SIZE
	var cols: int = clampi(ceili(width / cell_pitch), WeaponDefs.RAILGUN_GRID_MIN_COLS, WeaponDefs.RAILGUN_GRID_MAX_COLS)
	var rows: int = clampi(ceili(height / cell_pitch), WeaponDefs.RAILGUN_GRID_MIN_ROWS, WeaponDefs.RAILGUN_GRID_MAX_ROWS)

	var cell_size := Vector3(size.x, size.y, size.z)
	cell_size[width_axis] = width / float(cols)
	cell_size[height_axis] = height / float(rows)
	cell_size[thickness_axis] = depth

	var origin := Vector3.ZERO
	origin[width_axis] = -width * 0.5
	origin[height_axis] = -height * 0.5
	origin[thickness_axis] = -depth * 0.5

	return {
		"cols": cols,
		"rows": rows,
		"cell_size": cell_size,
		"origin": origin,
		"width_axis": width_axis,
		"height_axis": height_axis,
		"depth_axis": thickness_axis,
	}


func get_cells() -> Array:
	return _cells


func get_grid_cols() -> int:
	return _grid_cols


func get_grid_rows() -> int:
	return _grid_rows


func get_cell_size() -> Vector3:
	return _cell_size


func get_piece_size() -> Vector3:
	return _piece_size


func get_rims_root() -> Node3D:
	return _rims_root


func get_face_axes() -> Dictionary:
	return {"width": _width_axis, "height": _height_axis, "depth": _depth_axis}


func get_cell_at(col: int, row: int) -> Node:
	for cell in _cells:
		if not is_instance_valid(cell):
			continue
		if int(cell.get("cell_x")) == col and int(cell.get("cell_y")) == row:
			if cell.has_method("is_removed") and not cell.call("is_removed"):
				return cell
	return null


func add_railgun_perforation(
	_hit_world: Vector3, _beam_dir: Vector3, _surface_normal: Vector3
) -> bool:
	return false


func remove_cells_from_hit(
	_hit_cell: Node,
	_hit_world: Vector3,
	_beam_dir: Vector3,
	_surface_normal: Vector3
) -> bool:
	return false


func break_apart(hit_direction: Vector3 = Vector3.ZERO, force: float = 0.0) -> void:
	for cell in _cells:
		if is_instance_valid(cell) and cell.has_method("remove_cell"):
			cell.call("remove_cell")
	super.break_apart(hit_direction, force)


func clear_railgun_perforations() -> void:
	railgun_holes.clear()
	for cell in _cells:
		if is_instance_valid(cell) and cell.has_method("restore_cell"):
			cell.call("restore_cell")
	if _rims_root:
		for child in _rims_root.get_children():
			child.queue_free()


func _update_damage_stage() -> void:
	if _max_health <= 0 or _base_material == null:
		return
	var ratio: float = float(_health) / float(_max_health)
	var mat: StandardMaterial3D = _base_material.duplicate()
	var crack_t: float = 1.0 - clampf(ratio, 0.0, 1.0)
	mat.albedo_color = mat.albedo_color.lerp(mat.albedo_color.darkened(0.45), crack_t * 0.55)
	for cell in _cells:
		if is_instance_valid(cell) and cell.has_method("is_removed"):
			if not cell.call("is_removed") and cell.has_method("tint_material"):
				cell.call("tint_material", mat.duplicate())
