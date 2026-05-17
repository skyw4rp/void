## Builds and validates one arena per round from template data.
class_name ArenaGenerator
extends Node3D

const MAX_GENERATION_ATTEMPTS: int = 6
const SPAWN_RAY_START_HEIGHT: float = 24.0
const SPAWN_STAND_HEIGHT: float = 1.0
const FLOOR_RAY_MASK: int = 1

@export var debug_show_markers: bool = true

@onready var _active_arena: Node3D = $ActiveArena
@onready var _debug_markers: Node3D = $DebugMarkers

var _template: ArenaTemplate
var _last_arena_name: String = ""
var _player_spawn_transform: Transform3D = Transform3D.IDENTITY
var _enemy_spawn_transform: Transform3D = Transform3D.IDENTITY
var _player_spawn_position: Vector3 = Vector3.ZERO
var _enemy_spawn_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("arena_generator")
	_clear_active_arena()
	_clear_debug_markers()


func get_void_y() -> float:
	if _template:
		return _template.void_y
	return -20.0


func get_arena_name() -> String:
	if _template:
		return _template.arena_name
	return ""


func get_current_arena_center() -> Vector3:
	if _template:
		return _template.center_position
	return Vector3.ZERO


func get_current_arena_bounds() -> Dictionary:
	if _template == null:
		return {}
	var b: ArenaTemplate.AiBounds = _template.ai_bounds
	return {
		"center": get_current_arena_center(),
		"safe_half_x": b.safe_half_x,
		"danger_half_x": b.danger_half_x,
		"safe_half_z": b.safe_half_z,
		"danger_half_z": b.danger_half_z,
	}


func get_debris_bounds() -> Dictionary:
	if _template:
		return _template.debris_bounds.duplicate()
	return {}


func get_player_spawn_transform() -> Transform3D:
	return _player_spawn_transform


func get_enemy_spawn_transform() -> Transform3D:
	return _enemy_spawn_transform


func get_player_spawn_position() -> Vector3:
	return _player_spawn_position


func get_enemy_spawn_position() -> Vector3:
	return _enemy_spawn_position


func generate_round_arena_async() -> bool:
	_clear_active_arena()
	_clear_debug_markers()

	var playable: Array[int] = ArenaTemplates.get_playable_ids()
	if playable.is_empty():
		push_error("ArenaGenerator: no playable templates.")
		return false

	for attempt in MAX_GENERATION_ATTEMPTS:
		var template_id: int = _pick_template_id(playable)
		_template = ArenaTemplates.get_template(template_id as ArenaTemplates.Id)
		ArenaStructureBuilder.build(_active_arena, _template)
		await get_tree().physics_frame

		if _validate_and_finalize_spawns():
			print("Spawn validation passed")
			print("Round arena selected: %s" % _template.arena_name)
			_last_arena_name = _template.arena_name
			_update_debug_markers()
			return true

		print("Spawn invalid, regenerating arena")
		_clear_active_arena()

	# Last resort: force toxic bridge.
	_template = ArenaTemplates.get_template(ArenaTemplates.Id.TOXIC_BRIDGE)
	ArenaStructureBuilder.build(_active_arena, _template)
	await get_tree().physics_frame
	if _validate_and_finalize_spawns():
		print("Spawn validation passed (fallback Toxic Bridge)")
		print("Round arena selected: %s" % _template.arena_name)
		_last_arena_name = _template.arena_name
		_update_debug_markers()
		return true

	push_error("ArenaGenerator: failed to build a valid arena.")
	return false


func clear_active_arena() -> void:
	_clear_active_arena()
	_clear_debug_markers()
	_template = null


func raycast_floor_at(world_x: float, world_z: float) -> Variant:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return null
	var from := Vector3(world_x, SPAWN_RAY_START_HEIGHT, world_z)
	var to := Vector3(world_x, get_void_y() - 5.0, world_z)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = FLOOR_RAY_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit


func has_floor_at(world_x: float, world_z: float) -> bool:
	return raycast_floor_at(world_x, world_z) != null


func is_floor_ahead(from: Vector3, direction: Vector3, distance: float = 2.2) -> bool:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.01:
		return true
	var probe: Vector3 = from + flat.normalized() * distance
	return has_floor_at(probe.x, probe.z)


func is_on_floor(world_pos: Vector3) -> bool:
	var hit: Variant = raycast_floor_at(world_pos.x, world_pos.z)
	if hit == null or not hit is Dictionary:
		return false
	var hit_dict: Dictionary = hit as Dictionary
	var floor_y: float = (hit_dict.position as Vector3).y
	return absf(world_pos.y - floor_y) < 2.5


func pick_valid_debris_position(
	player_spawn: Vector3, enemy_spawn: Vector3, placed_xz: Array[Vector2]
) -> Vector3:
	if _template == null:
		return Vector3.INF

	var center: Vector3 = _template.center_position
	var rect: Dictionary = _template.debris_bounds
	var exclude: float = 4.5
	var safe: Vector2 = _template.spawn_safe_half

	for _attempt in 24:
		var local_x: float = randf_range(rect.x_min, rect.x_max)
		var local_z: float = randf_range(rect.z_min, rect.z_max)
		if absf(local_x) > safe.x * 0.95 or absf(local_z) > safe.y * 0.95:
			continue
		var world_x: float = center.x + local_x
		var world_z: float = center.z + local_z
		var xz := Vector2(world_x, world_z)

		if _is_near_fall_opening(local_x, local_z):
			continue

		if xz.distance_to(Vector2(player_spawn.x, player_spawn.z)) < exclude:
			continue
		if xz.distance_to(Vector2(enemy_spawn.x, enemy_spawn.z)) < exclude:
			continue

		var too_close: bool = false
		for other in placed_xz:
			if xz.distance_to(other) < 2.2:
				too_close = true
				break
		if too_close:
			continue

		var hit: Variant = raycast_floor_at(world_x, world_z)
		if hit == null:
			continue
		var hit_pos: Vector3 = (hit as Dictionary).position
		return Vector3(world_x, hit_pos.y + 1.2, world_z)

	return Vector3.INF


func _pick_template_id(playable: Array[int]) -> int:
	var candidates: Array[int] = []
	for id in playable:
		var t: ArenaTemplate = ArenaTemplates.get_template(id as ArenaTemplates.Id)
		if t.arena_name != _last_arena_name or playable.size() <= 1:
			candidates.append(id)
	if candidates.is_empty():
		candidates = playable.duplicate()
	return candidates.pick_random()


func _validate_and_finalize_spawns() -> bool:
	var center: Vector3 = _template.center_position
	var player_local: Vector3 = _template.player_spawn_local
	var enemy_local: Vector3 = _template.enemy_spawn_local

	var player_world_xz := Vector2(center.x + player_local.x, center.z + player_local.z)
	var enemy_world_xz := Vector2(center.x + enemy_local.x, center.z + enemy_local.z)

	if not _spawn_in_safe_zone(player_local) or not _spawn_in_safe_zone(enemy_local):
		return false

	var player_pos: Variant = _resolve_spawn_on_floor(player_world_xz)
	var enemy_pos: Variant = _resolve_spawn_on_floor(enemy_world_xz)
	if player_pos == null or enemy_pos == null:
		return false

	_player_spawn_position = player_pos as Vector3
	_enemy_spawn_position = enemy_pos as Vector3
	_player_spawn_transform = _spawn_transform_facing(
		_player_spawn_position, _enemy_spawn_position
	)
	_enemy_spawn_transform = _spawn_transform_facing(
		_enemy_spawn_position, _player_spawn_position
	)
	return true


func _spawn_in_safe_zone(spawn_local: Vector3) -> bool:
	if _template == null:
		return true
	var safe: Vector2 = _template.spawn_safe_half
	return absf(spawn_local.x) <= safe.x and absf(spawn_local.z) <= safe.y


func _is_near_fall_opening(local_x: float, local_z: float) -> bool:
	if _template == null:
		return false
	var edge_x: float = _template.ai_bounds.danger_half_x - 1.2
	var edge_z: float = _template.ai_bounds.danger_half_z - 1.2
	return absf(local_x) > edge_x or absf(local_z) > edge_z


func _resolve_spawn_on_floor(world_xz: Vector2) -> Variant:
	var hit: Variant = raycast_floor_at(world_xz.x, world_xz.y)
	if hit == null:
		return null
	var hit_dict: Dictionary = hit as Dictionary
	var floor_point: Vector3 = hit_dict.position as Vector3
	return Vector3(world_xz.x, floor_point.y + SPAWN_STAND_HEIGHT, world_xz.y)


func _spawn_transform_facing(from_pos: Vector3, look_target: Vector3) -> Transform3D:
	var flat_dir: Vector3 = Vector3(look_target.x - from_pos.x, 0.0, look_target.z - from_pos.z)
	if flat_dir.length_squared() < 0.001:
		return Transform3D(Basis.IDENTITY, from_pos)
	return Transform3D(Basis.looking_at(flat_dir.normalized(), Vector3.UP), from_pos)


func _clear_active_arena() -> void:
	if _active_arena == null:
		return
	for child in _active_arena.get_children():
		child.queue_free()


func _clear_debug_markers() -> void:
	if _debug_markers == null:
		return
	for child in _debug_markers.get_children():
		child.queue_free()


func _update_debug_markers() -> void:
	_clear_debug_markers()
	if not debug_show_markers or _template == null:
		return

	_add_debug_sphere(_player_spawn_position, Color(0.2, 0.95, 0.35), 0.35)
	_add_debug_sphere(_enemy_spawn_position, Color(0.95, 0.25, 0.2), 0.35)
	_draw_bounds_markers()


func _add_debug_sphere(position: Vector3, color: Color, radius: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.global_position = position
	_debug_markers.add_child(mesh_inst)


func _draw_bounds_markers() -> void:
	var b: ArenaTemplate.AiBounds = _template.ai_bounds
	var c: Vector3 = _template.center_position
	var y: float = 0.15
	var corners: Array[Vector3] = [
		Vector3(c.x - b.danger_half_x, y, c.z - b.danger_half_z),
		Vector3(c.x + b.danger_half_x, y, c.z - b.danger_half_z),
		Vector3(c.x + b.danger_half_x, y, c.z + b.danger_half_z),
		Vector3(c.x - b.danger_half_x, y, c.z + b.danger_half_z),
	]
	for corner in corners:
		_add_debug_sphere(corner, Color(0.25, 0.45, 0.95), 0.2)
