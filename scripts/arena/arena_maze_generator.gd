## Procedural indestructible brutalist maze — lanes, pockets, route validation.
class_name ArenaMazeGenerator
extends RefCounted

enum MazeProfile {
	THREE_LANE_HUB,
	CENTER_CITADEL,
	FLANK_GALLERIES,
	GATE_CROSS,
}

const MAX_ATTEMPTS: int = 10
const SPAWN_EXCLUSION: float = 5.5
const MIN_CORRIDOR_CELLS: int = 2
const MIN_STRUCTURAL_COUNT: int = 5


static func apply(template: ArenaTemplate, template_id: int) -> Dictionary:
	template.structural_wall_pieces.clear()
	var saved_cover: Array = template.wall_pieces.duplicate()
	template.wall_pieces.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(template.arena_name, template_id, "maze", Time.get_ticks_usec()))

	var profiles: Array[int] = _profile_pool(template_id)
	for _attempt in MAX_ATTEMPTS:
		template.structural_wall_pieces.clear()
		var profile: MazeProfile = profiles[rng.randi_range(0, profiles.size() - 1)] as MazeProfile
		_build_profile(template, profile, rng)
		if template.structural_wall_pieces.size() < MIN_STRUCTURAL_COUNT:
			continue
		var validation: Dictionary = ArenaRouteValidator.validate_template(template, true)
		if not validation.get("passed", false):
			continue
		if int(validation.get("route_count", 0)) < 2:
			continue
		var grid: ArenaRouteValidator.GridData = validation.grid
		if not _passes_corridor_check(grid, template):
			continue
		template.wall_pieces = saved_cover
		return {
			"passed": true,
			"layout_name": _profile_name(profile),
			"structural_count": template.structural_wall_pieces.size(),
			"route_count": validation.route_count,
		}

	template.wall_pieces = saved_cover
	return {
		"passed": false,
		"layout_name": "Failed",
		"structural_count": 0,
		"route_count": 0,
	}


static func _profile_pool(template_id: int) -> Array[int]:
	match template_id:
		ArenaTemplates.Id.TOXIC_BRIDGE:
			return [MazeProfile.THREE_LANE_HUB, MazeProfile.GATE_CROSS, MazeProfile.FLANK_GALLERIES]
		ArenaTemplates.Id.SPLIT_PLATFORMS:
			return [MazeProfile.FLANK_GALLERIES, MazeProfile.THREE_LANE_HUB, MazeProfile.CENTER_CITADEL]
		ArenaTemplates.Id.BROKEN_REACTOR:
			return [MazeProfile.CENTER_CITADEL, MazeProfile.GATE_CROSS, MazeProfile.THREE_LANE_HUB]
		ArenaTemplates.Id.RUINED_COURTYARD:
			return [MazeProfile.CENTER_CITADEL, MazeProfile.THREE_LANE_HUB, MazeProfile.FLANK_GALLERIES]
		ArenaTemplates.Id.HANGING_CORRIDORS:
			return [MazeProfile.GATE_CROSS, MazeProfile.FLANK_GALLERIES, MazeProfile.THREE_LANE_HUB]
		_:
			return [MazeProfile.THREE_LANE_HUB, MazeProfile.GATE_CROSS, MazeProfile.FLANK_GALLERIES]


static func _profile_name(profile: MazeProfile) -> String:
	match profile:
		MazeProfile.THREE_LANE_HUB:
			return "ThreeLaneHub"
		MazeProfile.CENTER_CITADEL:
			return "CenterCitadel"
		MazeProfile.FLANK_GALLERIES:
			return "FlankGalleries"
		MazeProfile.GATE_CROSS:
			return "GateCross"
		_:
			return "Unknown"


static func _build_profile(
	template: ArenaTemplate, profile: MazeProfile, rng: RandomNumberGenerator
) -> void:
	var sx: float = template.ai_bounds.safe_half_x
	var sz: float = template.ai_bounds.safe_half_z
	var along_x: bool = _spawns_along_x(template)
	match profile:
		MazeProfile.THREE_LANE_HUB:
			if along_x:
				_build_three_lane_hub(template, sz, sx, rng, true)
			else:
				_build_three_lane_hub(template, sx, sz, rng, false)
		MazeProfile.CENTER_CITADEL:
			_build_center_citadel(template, sx, sz, rng)
		MazeProfile.FLANK_GALLERIES:
			if along_x:
				_build_flank_galleries(template, sz, sx, rng, true)
			else:
				_build_flank_galleries(template, sx, sz, rng, false)
		MazeProfile.GATE_CROSS:
			_build_gate_cross(template, sx, sz, rng)


## Primary axis = first param pair (lane axis half), cross = second.
static func _build_three_lane_hub(
	template: ArenaTemplate,
	lane_half: float,
	cross_half: float,
	rng: RandomNumberGenerator,
	swap_axes: bool
) -> void:
	var h: float = rng.randf_range(3.8, 4.6)
	var thick: float = rng.randf_range(0.55, 0.85)
	var gate: float = rng.randf_range(2.4, 3.4)

	# Central spine with main gate at cross center.
	var spine_len: float = lane_half * 0.42
	_add_divider_run(
		template, 0.0, spine_len, h, thick, gate, 0.0, swap_axes, StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, 0.0, -spine_len, h, thick, gate, 0.0, swap_axes, StructuralWall.Kind.DIVIDER
	)

	# Flank dividers (partial — leave flank lanes open).
	var flank_x: float = cross_half * 0.44
	var flank_len: float = lane_half * 0.32
	var flank_gate: float = gate * 0.9
	_add_divider_run(
		template, flank_x, flank_len, h * 0.92, thick, flank_gate, 0.0, swap_axes,
		StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, flank_x, -flank_len, h * 0.92, thick, flank_gate, 0.0, swap_axes,
		StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, -flank_x, flank_len, h * 0.92, thick, flank_gate, 0.0, swap_axes,
		StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, -flank_x, -flank_len, h * 0.92, thick, flank_gate, 0.0, swap_axes,
		StructuralWall.Kind.DIVIDER
	)

	# Massive corner monoliths (presence, not choke).
	var mx: float = cross_half * 0.62
	var mz: float = lane_half * 0.58
	_add_box(
		template, mx, h * 0.48, mz, 2.6, h, 2.4, StructuralWall.Kind.MONOLITH, swap_axes
	)
	_add_box(
		template, -mx, h * 0.48, -mz, 2.4, h * 0.95, 2.2, StructuralWall.Kind.MONOLITH, swap_axes
	)

	# L-wing pocket breaker on one flank.
	var lx: float = cross_half * 0.28
	var lz: float = lane_half * 0.22
	_add_l_wing(template, lx, h * 0.42, lz, 3.2, h * 0.85, 2.8, swap_axes)


static func _build_center_citadel(
	template: ArenaTemplate, sx: float, sz: float, rng: RandomNumberGenerator
) -> void:
	var h: float = rng.randf_range(4.0, 5.0)
	var thick: float = rng.randf_range(0.7, 1.0)
	var gate_half: float = rng.randf_range(1.4, 1.9)
	var ring: float = mini(sx, sz) * 0.26
	var wing: float = ring * 0.72

	# Square ring — eight wings with cardinal gate openings (no center seal).
	_add_box(template, -(wing + gate_half), h * 0.5, ring, wing, h, thick, StructuralWall.Kind.MASSIVE)
	_add_box(template, wing + gate_half, h * 0.5, ring, wing, h, thick, StructuralWall.Kind.MASSIVE)
	_add_box(template, -(wing + gate_half), h * 0.5, -ring, wing, h, thick, StructuralWall.Kind.MASSIVE)
	_add_box(template, wing + gate_half, h * 0.5, -ring, wing, h, thick, StructuralWall.Kind.MASSIVE)
	_add_box(template, ring, h * 0.5, -(wing + gate_half), thick, h, wing, StructuralWall.Kind.MASSIVE)
	_add_box(template, ring, h * 0.5, wing + gate_half, thick, h, wing, StructuralWall.Kind.MASSIVE)
	_add_box(template, -ring, h * 0.5, -(wing + gate_half), thick, h, wing, StructuralWall.Kind.MASSIVE)
	_add_box(template, -ring, h * 0.5, wing + gate_half, thick, h, wing, StructuralWall.Kind.MASSIVE)

	# Gate posts frame openings.
	var post: float = thick * 1.35
	_add_box(template, gate_half + post * 0.5, h * 0.55, ring, post, h * 1.05, post, StructuralWall.Kind.GATE_POST)
	_add_box(template, -(gate_half + post * 0.5), h * 0.55, ring, post, h * 1.05, post, StructuralWall.Kind.GATE_POST)

	# Offset monolith — pocket anchor, not a full blocker.
	_add_box(template, sx * 0.12, h * 0.45, sz * 0.08, 2.2, h * 0.9, 1.8, StructuralWall.Kind.SLAB)
	_add_box(template, -sx * 0.38, h * 0.5, -sz * 0.32, 1.6, h, 1.6, StructuralWall.Kind.MONOLITH)


static func _build_flank_galleries(
	template: ArenaTemplate,
	lane_half: float,
	cross_half: float,
	rng: RandomNumberGenerator,
	swap_axes: bool
) -> void:
	var h: float = rng.randf_range(3.6, 4.4)
	var thick: float = rng.randf_range(0.6, 0.9)
	var gate: float = rng.randf_range(2.2, 3.2)
	var wall_x: float = cross_half * 0.52
	var run_len: float = lane_half * 0.7

	for side in [-1.0, 1.0]:
		var x: float = wall_x * side
		_add_divider_run(
			template, x, run_len * 0.35, h, thick, gate, 0.0, swap_axes,
			StructuralWall.Kind.MASSIVE
		)
		_add_divider_run(
			template, x, -run_len * 0.35, h, thick, gate, 0.0, swap_axes,
			StructuralWall.Kind.MASSIVE
		)

	# Short cross-bar near center — creates combat pocket, gate at center.
	var bar_z: float = lane_half * 0.12
	_add_divider_run(
		template, 0.0, bar_z, h * 0.85, thick, gate * 1.1, 0.0, not swap_axes,
		StructuralWall.Kind.DIVIDER
	)

	_add_box(
		template, cross_half * 0.2, h * 0.4, lane_half * 0.45,
		3.0, h * 0.8, 2.0, StructuralWall.Kind.SLAB, swap_axes
	)


static func _build_gate_cross(
	template: ArenaTemplate, sx: float, sz: float, rng: RandomNumberGenerator
) -> void:
	var h: float = rng.randf_range(3.8, 4.8)
	var thick: float = rng.randf_range(0.65, 0.95)
	var gate: float = rng.randf_range(2.8, 3.8)
	var reach_x: float = sx * 0.55
	var reach_z: float = sz * 0.55

	# Long arms with center opening (combat hub).
	_add_divider_run(
		template, 0.0, reach_z * 0.5, h, thick, gate, 0.0, false, StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, 0.0, -reach_z * 0.5, h, thick, gate, 0.0, false, StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, reach_x * 0.5, 0.0, h, thick, gate, 0.0, true, StructuralWall.Kind.DIVIDER
	)
	_add_divider_run(
		template, -reach_x * 0.5, 0.0, h, thick, gate, 0.0, true, StructuralWall.Kind.DIVIDER
	)

	# Quarter slabs — partial sightline breaks.
	_add_box(template, sx * 0.42, h * 0.45, sz * 0.38, 2.8, h * 0.9, 2.2, StructuralWall.Kind.SLAB)
	_add_box(template, -sx * 0.4, h * 0.45, -sz * 0.36, 2.6, h * 0.85, 2.0, StructuralWall.Kind.SLAB)
	_add_box(template, sx * 0.35, h * 0.5, -sz * 0.42, 1.8, h, 1.8, StructuralWall.Kind.MONOLITH)


## Divider along lane axis centered at (lane_pos, lane_center), gap at lane_center.
static func _add_divider_run(
	template: ArenaTemplate,
	cross_pos: float,
	lane_center: float,
	height: float,
	thickness: float,
	gap_half: float,
	_lane_center_gate: float,
	swap_axes: bool,
	kind: StructuralWall.Kind
) -> void:
	if _segment_near_spawn(template, cross_pos, lane_center, swap_axes):
		return
	var lane_half: float = template.ai_bounds.safe_half_z
	if swap_axes:
		lane_half = template.ai_bounds.safe_half_x
	var seg_len: float = lane_half * 0.38
	if absf(lane_center) < 0.01:
		# Split into north/south (or east/west) around center gate.
		var off: float = gap_half + seg_len * 0.5
		_place_divider_segment(
			template, cross_pos, lane_center + off, seg_len, height, thickness,
			swap_axes, kind
		)
		_place_divider_segment(
			template, cross_pos, lane_center - off, seg_len, height, thickness,
			swap_axes, kind
		)
	else:
		_place_divider_segment(
			template, cross_pos, lane_center, seg_len, height, thickness, swap_axes, kind
		)


static func _place_divider_segment(
	template: ArenaTemplate,
	cross_pos: float,
	lane_center: float,
	seg_len: float,
	height: float,
	thickness: float,
	swap_axes: bool,
	kind: StructuralWall.Kind
) -> void:
	if swap_axes:
		_add_box(
			template, lane_center, height * 0.5, cross_pos,
			seg_len * 2.0, height, thickness, kind, true
		)
	else:
		_add_box(
			template, cross_pos, height * 0.5, lane_center,
			thickness, height, seg_len * 2.0, kind
		)


static func _add_l_wing(
	template: ArenaTemplate,
	cx: float,
	cy: float,
	cz: float,
	arm_a: float,
	height: float,
	arm_b: float,
	swap_axes: bool
) -> void:
	if swap_axes:
		_add_box(template, cx, cy, cz, arm_a, height, 0.7, StructuralWall.Kind.L_WING, true)
		_add_box(template, cx, cy, cz + arm_b * 0.45, 0.7, height, arm_b, StructuralWall.Kind.L_WING, true)
	else:
		_add_box(template, cx, cy, cz, 0.7, height, arm_a, StructuralWall.Kind.L_WING)
		_add_box(template, cx + arm_b * 0.45, cy, cz, arm_b, height, 0.7, StructuralWall.Kind.L_WING)


static func _add_box(
	template: ArenaTemplate,
	cx: float,
	cy: float,
	cz: float,
	sx: float,
	sy: float,
	sz: float,
	kind: StructuralWall.Kind,
	swap_axes: bool = false
) -> void:
	if swap_axes:
		template.structural_wall_pieces.append(
			ArenaTemplate.make_structural_wall(
				Vector3(sz, sy, sx), Vector3(cz, cy, cx), kind
			)
		)
	else:
		template.structural_wall_pieces.append(
			ArenaTemplate.make_structural_wall(Vector3(sx, sy, sz), Vector3(cx, cy, cz), kind)
		)


static func _segment_near_spawn(
	template: ArenaTemplate,
	cross_pos: float,
	lane_center: float,
	swap_axes: bool
) -> bool:
	var local: Vector3
	if swap_axes:
		local = Vector3(lane_center, 0.0, cross_pos)
	else:
		local = Vector3(cross_pos, 0.0, lane_center)
	var sp: Vector3 = template.player_spawn_local
	var se: Vector3 = template.enemy_spawn_local
	return (
		Vector2(local.x, local.z).distance_to(Vector2(sp.x, sp.z)) < SPAWN_EXCLUSION
		or Vector2(local.x, local.z).distance_to(Vector2(se.x, se.z)) < SPAWN_EXCLUSION
	)


static func _spawns_along_x(template: ArenaTemplate) -> bool:
	return absf(template.player_spawn_local.x - template.enemy_spawn_local.x) > absf(
		template.player_spawn_local.z - template.enemy_spawn_local.z
	)


static func _passes_corridor_check(
	grid: ArenaRouteValidator.GridData, template: ArenaTemplate
) -> bool:
	var start: Vector2i = ArenaRouteValidator._local_to_cell(template.player_spawn_local)
	var end: Vector2i = ArenaRouteValidator._local_to_cell(template.enemy_spawn_local)
	var path: Array[Vector2i] = ArenaRouteValidator._bfs(grid, start, end)
	if path.is_empty():
		return false
	for i in range(1, path.size() - 1):
		var cell: Vector2i = path[i]
		var wx: int = _axis_clearance(grid, cell, Vector2i(1, 0))
		var wz: int = _axis_clearance(grid, cell, Vector2i(0, 1))
		if wx < MIN_CORRIDOR_CELLS and wz < MIN_CORRIDOR_CELLS:
			return false
	return true


static func _axis_clearance(grid: ArenaRouteValidator.GridData, origin: Vector2i, axis: Vector2i) -> int:
	var count: int = 1
	var c: Vector2i = origin + axis
	while ArenaRouteValidator._is_traversable(grid, c):
		count += 1
		c += axis
	c = origin - axis
	while ArenaRouteValidator._is_traversable(grid, c):
		count += 1
		c -= axis
	return count
