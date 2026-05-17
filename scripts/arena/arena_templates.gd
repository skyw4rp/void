## Large combat arenas with intentional fall zones over deep toxic void.
class_name ArenaTemplates
extends RefCounted

enum Id {
	BROKEN_REACTOR,
	TOXIC_BRIDGE,
	SPLIT_PLATFORMS,
	RUINED_COURTYARD,
	HANGING_CORRIDORS,
}


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


static func _toxic_bridge() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Toxic Bridge", Id.TOXIC_BRIDGE)
	var th: float = 0.28
	var hy: float = -th * 0.5
	t.player_spawn_local = Vector3(-9.0, 1.0, 0.0)
	t.enemy_spawn_local = Vector3(9.0, 1.0, 0.0)
	t.spawn_safe_half = Vector2(10.0, 5.5)
	t.debris_bounds = {"x_min": -4.5, "x_max": 4.5, "z_min": -3.5, "z_max": 3.5}
	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.safe_half_x = 6.5
	t.ai_bounds.danger_half_x = 7.8
	t.ai_bounds.safe_half_z = 5.5
	t.ai_bounds.danger_half_z = 6.8
	t.floor_pieces = [
		ArenaTemplate.slab(14.0, th, 14.0, -9.0, hy, 0.0),
		ArenaTemplate.slab(14.0, th, 14.0, 9.0, hy, 0.0),
		ArenaTemplate.slab(6.0, th, 10.0, 0.0, hy, 0.0),
	]
	t.wall_pieces = [
		ArenaTemplate.wall(8.0, 1.2, 0.25, -9.0, 0.6, 6.2),
		ArenaTemplate.wall(8.0, 1.2, 0.25, 9.0, 0.6, -6.2),
		ArenaTemplate.wall(0.25, 2.4, 5.0, -3.5, 1.2, 0.0),
		ArenaTemplate.wall(0.25, 2.4, 5.0, 3.5, 1.2, 0.0),
	]
	t.fall_zones = [
		_marker(-9.0, 7.2, 12.0, 0.35, 0.0),
		_marker(9.0, -7.2, 12.0, 0.35, 0.0),
	]
	_finalize_perimeter(t, 0.74, 2.8, [0, 1])
	return t


static func _split_platforms() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Split Platforms", Id.SPLIT_PLATFORMS)
	var th: float = 0.28
	var hy: float = -th * 0.5
	t.player_spawn_local = Vector3(-10.0, 1.0, 0.0)
	t.enemy_spawn_local = Vector3(10.0, 1.0, 0.0)
	t.spawn_safe_half = Vector2(11.0, 8.5)
	t.debris_bounds = {"x_min": -5.5, "x_max": 5.5, "z_min": -5.0, "z_max": 5.0}
	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.safe_half_x = 9.5
	t.ai_bounds.danger_half_x = 11.0
	t.ai_bounds.safe_half_z = 7.5
	t.ai_bounds.danger_half_z = 8.8
	t.floor_pieces = [
		ArenaTemplate.slab(13.0, th, 20.0, -10.0, hy, 0.0),
		ArenaTemplate.slab(13.0, th, 20.0, 10.0, hy, 0.0),
		ArenaTemplate.slab(8.0, th, 6.0, 0.0, hy, 0.0),
		ArenaTemplate.slab(6.0, th, 4.0, -10.0, hy, 8.5),
		ArenaTemplate.slab(6.0, th, 4.0, 10.0, hy, 8.5),
		ArenaTemplate.slab(6.0, th, 4.0, -10.0, hy, -8.5),
		ArenaTemplate.slab(6.0, th, 4.0, 10.0, hy, -8.5),
	]
	t.wall_pieces = [
		ArenaTemplate.wall(0.28, 2.5, 8.0, -6.5, 1.25, 0.0),
		ArenaTemplate.wall(0.28, 2.5, 8.0, 6.5, 1.25, 0.0),
		ArenaTemplate.wall(4.0, 1.15, 0.28, -10.0, 0.58, 5.5),
		ArenaTemplate.wall(4.0, 1.15, 0.28, 10.0, 0.58, -5.5),
	]
	t.fall_zones = [
		_marker(-10.0, 10.5, 11.0, 0.35, 0.0),
		_marker(10.0, -10.5, 11.0, 0.35, 0.0),
	]
	_finalize_perimeter(t, 0.76, 3.0, [2, 3])
	return t


static func _broken_reactor() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Broken Reactor", Id.BROKEN_REACTOR)
	var th: float = 0.28
	var hy: float = -th * 0.5
	t.player_spawn_local = Vector3(-11.0, 1.0, 0.0)
	t.enemy_spawn_local = Vector3(11.0, 1.0, 0.0)
	t.spawn_safe_half = Vector2(12.0, 8.5)
	t.debris_bounds = {"x_min": -4.0, "x_max": 4.0, "z_min": -4.5, "z_max": 4.5}
	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.safe_half_x = 10.5
	t.ai_bounds.danger_half_x = 12.0
	t.ai_bounds.safe_half_z = 8.5
	t.ai_bounds.danger_half_z = 9.8
	# C-shaped walkway around central void pit (12×12) — single intentional hole.
	t.floor_pieces = [
		ArenaTemplate.slab(28.0, th, 6.0, 0.0, hy, -9.5),
		ArenaTemplate.slab(28.0, th, 6.0, 0.0, hy, 9.5),
		ArenaTemplate.slab(6.0, th, 16.0, -11.0, hy, 0.0),
		ArenaTemplate.slab(6.0, th, 16.0, 11.0, hy, 0.0),
	]
	t.wall_pieces = [
		ArenaTemplate.wall(4.0, 2.4, 0.28, 0.0, 1.2, -6.2),
		ArenaTemplate.wall(4.0, 2.4, 0.28, 0.0, 1.2, 6.2),
		ArenaTemplate.wall(0.28, 2.6, 4.0, -6.5, 1.3, -9.5),
		ArenaTemplate.wall(0.28, 2.6, 4.0, 6.5, 1.3, -9.5),
		ArenaTemplate.wall(1.0, 2.8, 1.0, -11.0, 1.4, 0.0),
		ArenaTemplate.wall(1.0, 2.8, 1.0, 11.0, 1.4, 0.0),
	]
	t.fall_zones = [
		_marker(0.0, -6.2, 10.0, 0.35, 0.0),
		_marker(0.0, 6.2, 10.0, 0.35, 0.0),
		_marker(-6.2, 0.0, 0.35, 10.0, PI * 0.5),
		_marker(6.2, 0.0, 0.35, 10.0, PI * 0.5),
	]
	_finalize_perimeter(t, 0.78, 3.2, [])
	return t


static func _ruined_courtyard() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Ruined Courtyard", Id.RUINED_COURTYARD)
	var th: float = 0.26
	var hy: float = -th * 0.5
	t.player_spawn_local = Vector3(0.0, 1.0, 9.5)
	t.enemy_spawn_local = Vector3(0.0, 1.0, -9.5)
	t.spawn_safe_half = Vector2(6.5, 11.0)
	t.debris_bounds = {"x_min": -4.5, "x_max": 4.5, "z_min": -3.0, "z_max": 3.0}
	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.safe_half_x = 10.0
	t.ai_bounds.danger_half_x = 11.5
	t.ai_bounds.safe_half_z = 10.0
	t.ai_bounds.danger_half_z = 11.2
	# Ring walkway (4u wide) around 14×14 inner pit.
	t.floor_pieces = [
		ArenaTemplate.slab(28.0, th, 4.0, 0.0, hy, -10.0),
		ArenaTemplate.slab(28.0, th, 4.0, 0.0, hy, 10.0),
		ArenaTemplate.slab(4.0, th, 16.0, -12.0, hy, 0.0),
		ArenaTemplate.slab(4.0, th, 16.0, 12.0, hy, 0.0),
		ArenaTemplate.slab(8.0, th, 8.0, -12.0, hy, -12.0),
		ArenaTemplate.slab(8.0, th, 8.0, 12.0, hy, -12.0),
		ArenaTemplate.slab(8.0, th, 8.0, -12.0, hy, 12.0),
		ArenaTemplate.slab(8.0, th, 8.0, 12.0, hy, 12.0),
	]
	t.wall_pieces = [
		ArenaTemplate.wall(1.0, 2.6, 1.0, -5.0, 1.3, -5.0),
		ArenaTemplate.wall(1.0, 2.6, 1.0, 5.0, 1.3, -5.0),
		ArenaTemplate.wall(2.5, 1.1, 0.25, 0.0, 0.55, -7.2),
		ArenaTemplate.wall(2.5, 1.1, 0.25, 0.0, 0.55, 7.2),
	]
	t.fall_zones = [
		_marker(0.0, -7.0, 8.0, 0.35, 0.0),
		_marker(0.0, 7.0, 8.0, 0.35, 0.0),
		_marker(-7.0, 0.0, 0.35, 8.0, PI * 0.5),
		_marker(7.0, 0.0, 0.35, 8.0, PI * 0.5),
	]
	_finalize_perimeter(t, 0.8, 3.0, [0, 1])
	return t


static func _hanging_corridors() -> ArenaTemplate:
	var t := ArenaTemplate.new()
	_apply_common(t, "Hanging Corridors", Id.HANGING_CORRIDORS)
	var th: float = 0.26
	var hy: float = -th * 0.5
	t.player_spawn_local = Vector3(-9.0, 1.0, -10.0)
	t.enemy_spawn_local = Vector3(9.0, 1.0, 10.0)
	t.spawn_safe_half = Vector2(10.0, 12.0)
	t.debris_bounds = {"x_min": -1.8, "x_max": 1.8, "z_min": -7.0, "z_max": 7.0}
	t.ai_bounds = ArenaTemplate.AiBounds.new()
	t.ai_bounds.safe_half_x = 10.5
	t.ai_bounds.danger_half_x = 12.0
	t.ai_bounds.safe_half_z = 12.5
	t.ai_bounds.danger_half_z = 14.0
	t.floor_pieces = [
		ArenaTemplate.slab(6.0, th, 28.0, -9.0, hy, 0.0),
		ArenaTemplate.slab(6.0, th, 28.0, 9.0, hy, 0.0),
		ArenaTemplate.slab(6.0, th, 4.0, 0.0, hy, -12.5),
		ArenaTemplate.slab(6.0, th, 4.0, 0.0, hy, 12.5),
	]
	t.wall_pieces = [
		ArenaTemplate.wall(0.25, 1.1, 22.0, -12.2, 0.55, 0.0),
		ArenaTemplate.wall(0.25, 1.1, 22.0, 12.2, 0.55, 0.0),
		ArenaTemplate.wall(3.5, 2.2, 0.28, 0.0, 1.1, -12.5),
	]
	t.fall_zones = [
		_marker(-9.0, 14.5, 5.0, 0.35, 0.0),
		_marker(9.0, -14.5, 5.0, 0.35, 0.0),
	]
	_finalize_perimeter(t, 0.75, 3.0, [2, 3])
	return t
