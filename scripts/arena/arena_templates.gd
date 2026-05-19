## Large continuous brutalist decks — void danger only at exterior perimeter.
class_name ArenaTemplates
extends RefCounted

enum Id {
	BROKEN_REACTOR,
	TOXIC_BRIDGE,
	SPLIT_PLATFORMS,
	RUINED_COURTYARD,
	HANGING_CORRIDORS,
}

const DECK_THICKNESS: float = 0.32
const EDGE_VOID_MARGIN: float = 2.6


static func get_playable_ids() -> Array[int]:
	return [
		Id.BROKEN_REACTOR,
		Id.TOXIC_BRIDGE,
		Id.SPLIT_PLATFORMS,
		Id.RUINED_COURTYARD,
		Id.HANGING_CORRIDORS,
	]


static func get_template(template_id: Id) -> ArenaTemplate:
	match template_id:
		Id.BROKEN_REACTOR:
			return _broken_reactor()
		Id.TOXIC_BRIDGE:
			return _toxic_bridge()
		Id.SPLIT_PLATFORMS:
			return _split_platforms()
		Id.RUINED_COURTYARD:
			return _ruined_courtyard()
		Id.HANGING_CORRIDORS:
			return _hanging_corridors()
		_:
			return _toxic_bridge()


static func _apply_common(t: ArenaTemplate, name: String, id: int) -> void:
	t.template_id = id
	t.arena_name = name
	t.center_position = Vector3.ZERO
	t.floor_albedo = Color(0.1, 0.098, 0.11)
	t.wall_albedo = Color(0.065, 0.07, 0.08)
	t.void_y = GameBalance.VOID_DEATH_Y
	t.fall_warning_y = GameBalance.VOID_FALL_WARNING_Y


static func _finalize_perimeter(
	t: ArenaTemplate, coverage: float, margin: float, open_sides: Array[int]
) -> void:
	t.perimeter = ArenaTemplate.perimeter_from_bounds(t.ai_bounds, margin, coverage)
	t.perimeter.ringout_open_sides = open_sides


static func _marker(x: float, z: float, sx: float, sz: float, rot: float = 0.0) -> ArenaTemplate.FallZoneMarker:
	var m := ArenaTemplate.FallZoneMarker.new()
	m.position = Vector3(x, 0.0, z)
	m.size = Vector3(sx, 0.08, sz)
	m.rotation_y = rot
	return m


static func _configure_continuous_deck(
	t: ArenaTemplate,
	deck_half_x: float,
	deck_half_z: float,
	spawn_along_x: bool,
	spawn_frac: float = 0.4
) -> void:
	var th: float = DECK_THICKNESS
	var hy: float = -th * 0.5
	t.floor_pieces = [
		ArenaTemplate.slab(deck_half_x * 2.0, th, deck_half_z * 2.0, 0.0, hy, 0.0),
	]

	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.danger_half_x = deck_half_x - EDGE_VOID_MARGIN
	t.ai_bounds.danger_half_z = deck_half_z - EDGE_VOID_MARGIN
	t.ai_bounds.safe_half_x = t.ai_bounds.danger_half_x - 2.2
	t.ai_bounds.safe_half_z = t.ai_bounds.danger_half_z - 2.2

	t.spawn_safe_half = Vector2(deck_half_x - 1.2, deck_half_z - 1.2)
	t.debris_bounds = {
		"x_min": -deck_half_x * 0.58,
		"x_max": deck_half_x * 0.58,
		"z_min": -deck_half_z * 0.58,
		"z_max": deck_half_z * 0.58,
	}
	t.fall_zones = _perimeter_fall_markers(
		t.ai_bounds.danger_half_x, t.ai_bounds.danger_half_z
	)

	var spawn_dist: float = deck_half_x * spawn_frac if spawn_along_x else deck_half_z * spawn_frac
	if spawn_along_x:
		t.player_spawn_local = Vector3(-spawn_dist, 1.0, 0.0)
		t.enemy_spawn_local = Vector3(spawn_dist, 1.0, 0.0)
	else:
		t.player_spawn_local = Vector3(0.0, 1.0, -spawn_dist)
		t.enemy_spawn_local = Vector3(0.0, 1.0, spawn_dist)


static func _perimeter_fall_markers(danger_hx: float, danger_hz: float) -> Array:
	var markers: Array = [
		_marker(0.0, danger_hz * 0.96, danger_hx * 1.75, 0.35, 0.0),
		_marker(0.0, -danger_hz * 0.96, danger_hx * 1.75, 0.35, 0.0),
		_marker(danger_hx * 0.96, 0.0, 0.35, danger_hz * 1.75, PI * 0.5),
		_marker(-danger_hx * 0.96, 0.0, 0.35, danger_hz * 1.75, PI * 0.5),
	]
	return markers


static func _column(cx: float, cz: float, radius: float = 0.85) -> ArenaTemplate.WallPiece:
	return ArenaTemplate.wall(radius * 2.0, 3.5, radius * 2.0, cx, 1.75, cz)


static func _massive_slab(cx: float, cz: float, sx: float, sz: float) -> ArenaTemplate.WallPiece:
	return ArenaTemplate.wall(sx, 1.4, sz, cx, 0.7, cz)


static func _broken_wall(cx: float, cz: float, length: float = 5.0) -> ArenaTemplate.WallPiece:
	return ArenaTemplate.wall(0.32, 2.25, length, cx, 1.12, cz)


static func _half_cover(cx: float, cz: float) -> ArenaTemplate.WallPiece:
	return ArenaTemplate.wall(3.2, 1.65, 0.32, cx, 0.82, cz)


static func _toxic_bridge() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Toxic Bridge", Id.TOXIC_BRIDGE)
	_configure_continuous_deck(t, 24.0, 20.0, true, 0.38)
	t.wall_pieces = [
		_column(-10.0, 7.5),
		_column(10.0, -7.5),
		_massive_slab(-6.0, 5.5, 4.5, 2.2),
		_massive_slab(6.0, -5.5, 4.5, 2.2),
		_broken_wall(0.0, 9.0, 6.0),
		_half_cover(-12.0, 0.0),
		_half_cover(12.0, 0.0),
	]
	_finalize_perimeter(t, 0.80, 3.2, [0, 1])
	return t


static func _split_platforms() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Split Platforms", Id.SPLIT_PLATFORMS)
	_configure_continuous_deck(t, 26.0, 22.0, true, 0.4)
	t.wall_pieces = [
		_column(-14.0, 10.0),
		_column(14.0, -10.0),
		_column(-14.0, -10.0),
		_column(14.0, 10.0),
		_massive_slab(0.0, 11.0, 8.0, 2.4),
		_broken_wall(-8.0, 6.0, 5.5),
		_broken_wall(8.0, -6.0, 5.5),
		_half_cover(0.0, -11.5),
	]
	_finalize_perimeter(t, 0.82, 3.4, [2, 3])
	return t


static func _broken_reactor() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Broken Reactor", Id.BROKEN_REACTOR)
	_configure_continuous_deck(t, 25.0, 23.0, true, 0.39)
	t.wall_pieces = [
		_column(-11.0, 0.0, 1.05),
		_column(11.0, 0.0, 1.05),
		_massive_slab(0.0, 8.5, 6.5, 2.8),
		_massive_slab(0.0, -8.5, 6.5, 2.8),
		_broken_wall(-7.0, 7.0, 4.5),
		_broken_wall(7.0, -7.0, 4.5),
		_half_cover(-13.0, 5.0),
		_half_cover(13.0, -5.0),
	]
	_finalize_perimeter(t, 0.84, 3.4, [0, 1, 2, 3])
	return t


static func _ruined_courtyard() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Ruined Courtyard", Id.RUINED_COURTYARD)
	_configure_continuous_deck(t, 25.0, 25.0, false, 0.38)
	t.wall_pieces = [
		_column(-9.0, 9.0),
		_column(9.0, -9.0),
		_column(-9.0, -9.0),
		_column(9.0, 9.0),
		_massive_slab(-6.0, 0.0, 3.5, 7.0),
		_massive_slab(6.0, 0.0, 3.5, 7.0),
		_broken_wall(0.0, 10.5, 7.5),
		_half_cover(11.0, 0.0),
	]
	_finalize_perimeter(t, 0.86, 3.5, [0, 1])
	return t


static func _hanging_corridors() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Hanging Corridors", Id.HANGING_CORRIDORS)
	_configure_continuous_deck(t, 23.0, 27.0, false, 0.37)
	t.wall_pieces = [
		_column(-8.0, 12.0),
		_column(8.0, -12.0),
		_massive_slab(-11.0, 0.0, 2.8, 10.0),
		_massive_slab(11.0, 0.0, 2.8, 10.0),
		_broken_wall(-5.0, 11.0, 5.0),
		_broken_wall(5.0, -11.0, 5.0),
		_half_cover(0.0, 13.0),
		_half_cover(0.0, -13.0),
	]
	_finalize_perimeter(t, 0.81, 3.3, [2, 3])
	return t
