## Procedural inner-wall variations per round — zones, archetypes, route-safe placement.
class_name ArenaWallSetGenerator
extends RefCounted

enum WallSetProfile {
	OPEN_CENTER,
	CENTER_BLOCKER,
	SIDE_HEAVY,
	DIAGONAL_BARRIERS,
	LONG_SIGHT,
	CLOSE_QUARTERS,
}

enum ZoneKind {
	CENTER,
	SIDE_LANE,
	FLANK,
	EDGE_DANGER,
	SPAWN_APPROACH,
}

enum Archetype {
	THIN_SLAB,
	HALF_WALL,
	PILLAR,
	BROKEN_WALL,
	COVER_CLUSTER,
	SPLIT_BARRIER,
	RUINED_COLUMN,
	ANGLED_COVER,
	DESTROYED_SEGMENT,
}

const MAX_LAYOUT_ATTEMPTS: int = 12
const SPAWN_LANE_CLEARANCE: float = 2.8
const SIGNATURE_KEEP_CHANCE: float = 0.35


static func get_profile_names() -> PackedStringArray:
	return PackedStringArray([
		"OpenCenter",
		"CenterBlocker",
		"SideHeavy",
		"DiagonalBarriers",
		"LongSight",
		"CloseQuarters",
	])


static func apply(template: ArenaTemplate, template_id: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(template.arena_name, template_id, Time.get_ticks_usec()))

	var cover_density: float = rng.randf_range(0.4, 1.0)
	var profile: WallSetProfile = _pick_profile(rng, template_id)
	var signature: Array[ArenaTemplate.WallPiece] = template.wall_pieces.duplicate()

	for _attempt in MAX_LAYOUT_ATTEMPTS:
		template.wall_pieces.clear()
		_restore_signature_walls(template, signature, rng)
		var placed: int = _generate_for_profile(template, profile, cover_density, rng)
		var validation: Dictionary = ArenaRouteValidator.validate_template(template)
		if validation.passed and int(validation.get("route_count", 0)) >= 2:
			return {
				"passed": true,
				"set_name": get_profile_names()[profile],
				"cover_density": cover_density,
				"route_count": validation.route_count,
				"blocker_count": template.wall_pieces.size(),
			}
		if not validation.passed and cover_density > 0.45:
			cover_density = maxf(0.4, cover_density - 0.08)

	# Safe fallback: signature walls, then template defaults only.
	for mode in ["signature", "default"]:
		template.wall_pieces.clear()
		if mode == "signature":
			template.wall_pieces = signature.duplicate()
		var fallback: Dictionary = ArenaRouteValidator.validate_template(template)
		if fallback.passed and int(fallback.get("route_count", 0)) >= 2:
			return {
				"passed": true,
				"set_name": "SignatureFallback" if mode == "signature" else "TemplateDefault",
				"cover_density": 0.4,
				"route_count": fallback.route_count,
				"blocker_count": template.wall_pieces.size(),
			}
	return {
		"passed": false,
		"set_name": "Failed",
		"cover_density": cover_density,
		"route_count": 0,
		"blocker_count": 0,
	}


static func _pick_profile(rng: RandomNumberGenerator, template_id: int) -> WallSetProfile:
	var pool: Array[int] = []
	match template_id:
		ArenaTemplates.Id.TOXIC_BRIDGE:
			pool = [0, 2, 4, 5, 1]
		ArenaTemplates.Id.SPLIT_PLATFORMS:
			pool = [2, 3, 5, 0, 1]
		ArenaTemplates.Id.BROKEN_REACTOR:
			pool = [0, 2, 3, 4, 5]
		ArenaTemplates.Id.RUINED_COURTYARD:
			pool = [1, 3, 5, 0, 2]
		ArenaTemplates.Id.HANGING_CORRIDORS:
			pool = [4, 2, 3, 0, 5]
		_:
			pool = [0, 1, 2, 3, 4, 5]
	return pool[rng.randi_range(0, pool.size() - 1)] as WallSetProfile


static func _restore_signature_walls(
	template: ArenaTemplate,
	signature: Array[ArenaTemplate.WallPiece],
	rng: RandomNumberGenerator
) -> void:
	for piece in signature:
		if rng.randf() <= SIGNATURE_KEEP_CHANCE:
			template.wall_pieces.append(piece)


static func _generate_for_profile(
	template: ArenaTemplate,
	profile: WallSetProfile,
	cover_density: float,
	rng: RandomNumberGenerator
) -> int:
	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var safe: Vector2 = Vector2(bounds.safe_half_x, bounds.safe_half_z)
	var recipe: Dictionary = _recipe_for_template(template.template_id)
	var min_walls: int = int(recipe.get("min_walls", 3))
	var max_walls: int = int(recipe.get("max_walls", 9))
	var target: int = int(round(lerpf(float(min_walls), float(max_walls), cover_density)))
	target = maxi(target - template.wall_pieces.size(), 0)

	var grid: ArenaRouteValidator.GridData = ArenaRouteValidator._build_grid(template, false)
	var candidates: Array[Vector2i] = _collect_candidate_cells(template, grid, safe)

	var placed: int = 0
	var tries: int = 0
	while placed < target and tries < target * 8:
		tries += 1
		if candidates.is_empty():
			break
		var cell: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		var local: Vector2 = ArenaRouteValidator._cell_to_local(cell)
		var zone: ZoneKind = _zone_at(local, template, safe)
		if not _profile_allows_zone(profile, zone):
			continue
		if _is_on_spawn_lane(local, template):
			continue

		var arch: Archetype = _pick_archetype_for_zone(zone, profile, rng)
		var pieces: Array[ArenaTemplate.WallPiece] = _build_archetype(arch, local.x, local.y, rng)
		if pieces.is_empty():
			continue

		var valid_cluster: bool = true
		for piece in pieces:
			if _overlaps_existing(template, piece):
				valid_cluster = false
				break
		if not valid_cluster:
			continue

		for piece in pieces:
			template.wall_pieces.append(piece)
		placed += pieces.size()

		var probe: Dictionary = ArenaRouteValidator.validate_template(template)
		if not probe.passed or int(probe.get("route_count", 0)) < 2:
			for _i in pieces.size():
				template.wall_pieces.pop_back()
			placed -= pieces.size()
			candidates.erase(cell)

	return placed


static func _recipe_for_template(template_id: int) -> Dictionary:
	# Continuous decks — procedural cover stays in flanks, not interior pits.
	match template_id:
		ArenaTemplates.Id.TOXIC_BRIDGE:
			return {"min_walls": 4, "max_walls": 11}
		ArenaTemplates.Id.SPLIT_PLATFORMS:
			return {"min_walls": 5, "max_walls": 12}
		ArenaTemplates.Id.BROKEN_REACTOR:
			return {"min_walls": 5, "max_walls": 12}
		ArenaTemplates.Id.RUINED_COURTYARD:
			return {"min_walls": 4, "max_walls": 11}
		ArenaTemplates.Id.HANGING_CORRIDORS:
			return {"min_walls": 4, "max_walls": 11}
		_:
			return {"min_walls": 4, "max_walls": 11}


static func _collect_candidate_cells(
	template: ArenaTemplate,
	grid: ArenaRouteValidator.GridData,
	safe: Vector2
) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not grid.has_bounds:
		return out

	var spawn_p: Vector2i = ArenaRouteValidator._local_to_cell(template.player_spawn_local)
	var spawn_e: Vector2i = ArenaRouteValidator._local_to_cell(template.enemy_spawn_local)

	for x in range(grid.min_cell.x, grid.max_cell.x + 1):
		for z in range(grid.min_cell.y, grid.max_cell.y + 1):
			var cell := Vector2i(x, z)
			if not grid.walkable.has(cell):
				continue
			var local: Vector2 = ArenaRouteValidator._cell_to_local(cell)
			if absf(local.x) > safe.x * 0.88 or absf(local.y) > safe.y * 0.88:
				continue
			if _cell_near_spawn(cell, spawn_p, 4) or _cell_near_spawn(cell, spawn_e, 4):
				continue
			out.append(cell)
	return out


static func _cell_near_spawn(cell: Vector2i, spawn: Vector2i, radius: int) -> bool:
	return absi(cell.x - spawn.x) <= radius and absi(cell.y - spawn.y) <= radius


static func _zone_at(local: Vector2, template: ArenaTemplate, safe: Vector2) -> ZoneKind:
	var spawn_p: Vector2 = Vector2(template.player_spawn_local.x, template.player_spawn_local.z)
	var spawn_e: Vector2 = Vector2(template.enemy_spawn_local.x, template.enemy_spawn_local.z)
	if local.distance_to(spawn_p) < 5.0 or local.distance_to(spawn_e) < 5.0:
		return ZoneKind.SPAWN_APPROACH
	if absf(local.x) > safe.x * 0.72 or absf(local.y) > safe.y * 0.72:
		return ZoneKind.EDGE_DANGER
	if absf(local.x) > safe.x * 0.38 and absf(local.y) > safe.y * 0.38:
		return ZoneKind.FLANK
	if absf(local.x) > safe.x * 0.42 or absf(local.y) > safe.y * 0.42:
		return ZoneKind.SIDE_LANE
	return ZoneKind.CENTER


static func _profile_allows_zone(profile: WallSetProfile, zone: ZoneKind) -> bool:
	match profile:
		WallSetProfile.OPEN_CENTER:
			return zone != ZoneKind.CENTER
		WallSetProfile.CENTER_BLOCKER:
			return zone == ZoneKind.CENTER or zone == ZoneKind.FLANK
		WallSetProfile.SIDE_HEAVY:
			return zone == ZoneKind.SIDE_LANE or zone == ZoneKind.FLANK or zone == ZoneKind.EDGE_DANGER
		WallSetProfile.DIAGONAL_BARRIERS:
			return zone == ZoneKind.FLANK or zone == ZoneKind.CENTER
		WallSetProfile.LONG_SIGHT:
			return zone == ZoneKind.SIDE_LANE or zone == ZoneKind.EDGE_DANGER
		WallSetProfile.CLOSE_QUARTERS:
			return zone != ZoneKind.SPAWN_APPROACH and zone != ZoneKind.EDGE_DANGER
		_:
			return true


static func _pick_archetype_for_zone(
	zone: ZoneKind, profile: WallSetProfile, rng: RandomNumberGenerator
) -> Archetype:
	var pool: Array[int] = []
	match zone:
		ZoneKind.CENTER:
			pool = [Archetype.PILLAR, Archetype.SPLIT_BARRIER, Archetype.RUINED_COLUMN, Archetype.HALF_WALL]
		ZoneKind.SIDE_LANE:
			pool = [Archetype.THIN_SLAB, Archetype.HALF_WALL, Archetype.COVER_CLUSTER, Archetype.ANGLED_COVER]
		ZoneKind.FLANK:
			pool = [Archetype.ANGLED_COVER, Archetype.BROKEN_WALL, Archetype.DESTROYED_SEGMENT, Archetype.PILLAR]
		ZoneKind.EDGE_DANGER:
			pool = [Archetype.THIN_SLAB, Archetype.BROKEN_WALL, Archetype.DESTROYED_SEGMENT]
		ZoneKind.SPAWN_APPROACH:
			pool = [Archetype.HALF_WALL, Archetype.DESTROYED_SEGMENT, Archetype.BROKEN_WALL]
		_:
			pool = [Archetype.HALF_WALL, Archetype.PILLAR]

	if profile == WallSetProfile.LONG_SIGHT:
		pool = [Archetype.THIN_SLAB, Archetype.HALF_WALL, Archetype.DESTROYED_SEGMENT]
	elif profile == WallSetProfile.CLOSE_QUARTERS:
		pool = [Archetype.HALF_WALL, Archetype.COVER_CLUSTER, Archetype.SPLIT_BARRIER, Archetype.PILLAR]

	return pool[rng.randi_range(0, pool.size() - 1)] as Archetype


static func _build_archetype(
	arch: Archetype, cx: float, cz: float, rng: RandomNumberGenerator
) -> Array[ArenaTemplate.WallPiece]:
	match arch:
		Archetype.THIN_SLAB:
			var along_x: bool = rng.randf() > 0.5
			if along_x:
				return [ArenaTemplate.wall(0.25, 2.2, 3.5, cx, 1.1, cz)]
			return [ArenaTemplate.wall(3.5, 2.2, 0.25, cx, 1.1, cz)]
		Archetype.HALF_WALL:
			if rng.randf() > 0.5:
				return [ArenaTemplate.wall(2.8, 1.15, 0.25, cx, 0.58, cz)]
			return [ArenaTemplate.wall(0.25, 1.15, 2.8, cx, 0.58, cz)]
		Archetype.PILLAR:
			return [ArenaTemplate.wall(1.0, 2.6, 1.0, cx, 1.3, cz)]
		Archetype.BROKEN_WALL:
			return [ArenaTemplate.wall(2.2, 1.45, 0.25, cx, 0.72, cz)]
		Archetype.COVER_CLUSTER:
			var off: float = 1.1
			return [
				ArenaTemplate.wall(1.0, 1.1, 0.25, cx - off, 0.55, cz),
				ArenaTemplate.wall(1.0, 2.0, 1.0, cx + off * 0.5, 1.0, cz + off * 0.35),
			]
		Archetype.SPLIT_BARRIER:
			return [
				ArenaTemplate.wall(0.25, 2.3, 2.5, cx - 1.2, 1.15, cz),
				ArenaTemplate.wall(0.25, 2.3, 2.5, cx + 1.2, 1.15, cz),
			]
		Archetype.RUINED_COLUMN:
			return [
				ArenaTemplate.wall(0.9, 2.5, 0.9, cx, 1.25, cz),
				ArenaTemplate.wall(1.4, 0.9, 0.25, cx + 0.7, 0.45, cz),
			]
		Archetype.ANGLED_COVER:
			return [
				ArenaTemplate.wall(2.4, 1.2, 0.25, cx - 1.0, 0.6, cz - 1.0),
				ArenaTemplate.wall(0.25, 1.2, 2.4, cx + 1.0, 0.6, cz + 1.0),
			]
		Archetype.DESTROYED_SEGMENT:
			return [ArenaTemplate.wall(1.8, 0.85, 0.25, cx, 0.42, cz)]
		_:
			return []


static func _overlaps_existing(template: ArenaTemplate, piece: ArenaTemplate.WallPiece) -> bool:
	for other in template.wall_pieces:
		if _aabb_overlap(piece.position, piece.size, other.position, other.size):
			return true
	return false


static func _aabb_overlap(a_pos: Vector3, a_size: Vector3, b_pos: Vector3, b_size: Vector3) -> bool:
	var a_min: Vector3 = a_pos - a_size * 0.5
	var a_max: Vector3 = a_pos + a_size * 0.5
	var b_min: Vector3 = b_pos - b_size * 0.5
	var b_max: Vector3 = b_pos + b_size * 0.5
	return (
		a_min.x < b_max.x and a_max.x > b_min.x
		and a_min.z < b_max.z and a_max.z > b_min.z
	)


static func _is_on_spawn_lane(local: Vector2, template: ArenaTemplate) -> bool:
	var a: Vector2 = Vector2(template.player_spawn_local.x, template.player_spawn_local.z)
	var b: Vector2 = Vector2(template.enemy_spawn_local.x, template.enemy_spawn_local.z)
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.01:
		return false
	var t: float = clampf(local.dot(ab) / len_sq, 0.12, 0.88)
	var closest: Vector2 = a + ab * t
	return closest.distance_to(local) < SPAWN_LANE_CLEARANCE
