## Floor-grid BFS — validates walkable routes between spawns (no rocket jump).
class_name ArenaRouteValidator
extends RefCounted

const CELL_SIZE: float = 1.0
const FOOTPRINT_INSET: float = 0.55
const SPAWN_CLEARANCE_CELLS: int = 3


class GridData:
	var walkable: Dictionary = {}  ## Vector2i -> true
	var blocked: Dictionary = {}  ## Vector2i -> true
	var min_cell: Vector2i = Vector2i.ZERO
	var max_cell: Vector2i = Vector2i.ZERO
	var has_bounds: bool = false


static func validate_template(
	template: ArenaTemplate, block_walls: bool = true
) -> Dictionary:
	var grid: GridData = _build_grid(template, block_walls)
	var start: Vector2i = _local_to_cell(template.player_spawn_local)
	var end: Vector2i = _local_to_cell(template.enemy_spawn_local)

	_mark_walkable_near(grid, start, SPAWN_CLEARANCE_CELLS)
	_mark_walkable_near(grid, end, SPAWN_CLEARANCE_CELLS)

	var path: Array[Vector2i] = _bfs(grid, start, end)
	var spawn_ok: bool = (
		_has_spawn_clearance(grid, start) and _has_spawn_clearance(grid, end)
	)
	var passed: bool = not path.is_empty() and spawn_ok

	var route_count: int = 0
	if passed:
		route_count = count_viable_routes(grid, start, end, path)

	return {
		"passed": passed,
		"grid": grid,
		"path": path,
		"start": start,
		"end": end,
		"spawn_ok": spawn_ok,
		"route_count": route_count,
	}


## Primary path plus at least one detour after soft-blocking the main corridor.
static func count_viable_routes(
	grid: GridData, start: Vector2i, end: Vector2i, primary_path: Array
) -> int:
	if primary_path.is_empty():
		return 0
	var count: int = 1
	if _has_detour_route(grid, start, end, primary_path):
		count += 1
	return count


static func path_to_world_points(template: ArenaTemplate, path: Array[Vector2i]) -> PackedVector3Array:
	var out := PackedVector3Array()
	var center: Vector3 = template.center_position
	for cell in path:
		var local: Vector2 = _cell_to_local(cell)
		out.append(Vector3(center.x + local.x, 0.0, center.z + local.y))
	return out


static func _build_grid(template: ArenaTemplate, block_walls: bool) -> GridData:
	var grid := GridData.new()
	for piece in template.floor_pieces:
		_stamp_floor_rect(grid, piece.position, piece.size)
	if block_walls:
		for piece in template.structural_wall_pieces:
			_stamp_wall_block(grid, piece.position, piece.size)
		for piece in template.wall_pieces:
			_stamp_wall_block(grid, piece.position, piece.size)
	return grid


static func _stamp_floor_rect(grid: GridData, center: Vector3, size: Vector3) -> void:
	var min_x: float = center.x - size.x * 0.5 + FOOTPRINT_INSET
	var max_x: float = center.x + size.x * 0.5 - FOOTPRINT_INSET
	var min_z: float = center.z - size.z * 0.5 + FOOTPRINT_INSET
	var max_z: float = center.z + size.z * 0.5 - FOOTPRINT_INSET
	var cx: int = int(floor(min_x / CELL_SIZE))
	var cxx: int = int(floor(max_x / CELL_SIZE))
	var cz: int = int(floor(min_z / CELL_SIZE))
	var czz: int = int(floor(max_z / CELL_SIZE))
	for x in range(cx, cxx + 1):
		for z in range(cz, czz + 1):
			var cell := Vector2i(x, z)
			_expand_bounds(grid, cell)
			grid.walkable[cell] = true
			grid.blocked.erase(cell)


static func _stamp_wall_block(grid: GridData, center: Vector3, size: Vector3) -> void:
	var min_x: float = center.x - size.x * 0.5
	var max_x: float = center.x + size.x * 0.5
	var min_z: float = center.z - size.z * 0.5
	var max_z: float = center.z + size.z * 0.5
	var cx: int = int(floor(min_x / CELL_SIZE))
	var cxx: int = int(floor(max_x / CELL_SIZE))
	var cz: int = int(floor(min_z / CELL_SIZE))
	var czz: int = int(floor(max_z / CELL_SIZE))
	for x in range(cx, cxx + 1):
		for z in range(cz, czz + 1):
			var cell := Vector2i(x, z)
			_expand_bounds(grid, cell)
			grid.blocked[cell] = true


static func _expand_bounds(grid: GridData, cell: Vector2i) -> void:
	if not grid.has_bounds:
		grid.min_cell = cell
		grid.max_cell = cell
		grid.has_bounds = true
		return
	grid.min_cell.x = mini(grid.min_cell.x, cell.x)
	grid.min_cell.y = mini(grid.min_cell.y, cell.y)
	grid.max_cell.x = maxi(grid.max_cell.x, cell.x)
	grid.max_cell.y = maxi(grid.max_cell.y, cell.y)


static func _local_to_cell(local: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(local.x / CELL_SIZE)),
		int(floor(local.z / CELL_SIZE))
	)


static func _cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * CELL_SIZE,
		(float(cell.y) + 0.5) * CELL_SIZE
	)


static func _is_traversable(grid: GridData, cell: Vector2i) -> bool:
	return grid.walkable.has(cell) and not grid.blocked.has(cell)


static func _bfs(grid: GridData, start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not _is_traversable(grid, start) or not _is_traversable(grid, end):
		return []

	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == end:
			return _reconstruct_path(came_from, start, end)
		for d in dirs:
			var next: Vector2i = current + d
			if not _is_traversable(grid, next):
				continue
			if came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)

	return []


static func _reconstruct_path(
	came_from: Dictionary, start: Vector2i, end: Vector2i
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [end]
	var current: Vector2i = end
	while current != start:
		current = came_from[current]
		path.push_front(current)
	return path


static func _has_spawn_clearance(grid: GridData, origin: Vector2i) -> bool:
	for dx in range(-SPAWN_CLEARANCE_CELLS, SPAWN_CLEARANCE_CELLS + 1):
		for dz in range(-SPAWN_CLEARANCE_CELLS, SPAWN_CLEARANCE_CELLS + 1):
			var cell := Vector2i(origin.x + dx, origin.y + dz)
			if not _is_traversable(grid, cell):
				return false
	return true


static func _mark_walkable_near(grid: GridData, origin: Vector2i, radius_cells: int) -> void:
	for dx in range(-radius_cells, radius_cells + 1):
		for dz in range(-radius_cells, radius_cells + 1):
			var cell := Vector2i(origin.x + dx, origin.y + dz)
			if grid.walkable.has(cell):
				grid.blocked.erase(cell)


static func _has_detour_route(
	grid: GridData, start: Vector2i, end: Vector2i, primary_path: Array
) -> bool:
	var detour_grid := GridData.new()
	detour_grid.walkable = grid.walkable.duplicate()
	detour_grid.blocked = grid.blocked.duplicate()
	detour_grid.min_cell = grid.min_cell
	detour_grid.max_cell = grid.max_cell
	detour_grid.has_bounds = grid.has_bounds

	var soft_block: Dictionary = {}
	for cell in primary_path:
		if cell == start or cell == end:
			continue
		if _manhattan_distance(cell, start) <= 2 or _manhattan_distance(cell, end) <= 2:
			continue
		soft_block[cell] = true

	for cell in soft_block:
		if detour_grid.walkable.has(cell):
			detour_grid.blocked[cell] = true

	return not _bfs(detour_grid, start, end).is_empty()


static func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
