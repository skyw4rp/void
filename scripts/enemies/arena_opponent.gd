## 1v1 arena AI — compact arenas, cover, hole avoidance, ring-out tactics.
extends RigidBody3D

enum AiState { ATTACKING, RECOVERING, IN_COVER }

@export var move_force: float = 10.0
@export var strafe_force: float = 8.0
@export var retreat_force: float = 12.0
@export var max_speed: float = 5.0
@export var void_y: float = -20.0
@export var aim_height_offset: float = 1.2

@export var close_range: float = 4.5
@export var medium_range: float = 10.0
@export var ideal_distance_min: float = 3.5
@export var ideal_distance_max: float = 8.5
@export var cover_seek_force: float = 11.0
@export var hole_avoid_force: float = 22.0

## Per-arena safe/danger half-extents (set from ArenaGenerator each round).
@export var safe_half_x: float = 3.2
@export var danger_half_x: float = 3.8
@export var safe_half_z: float = 12.0
@export var danger_half_z: float = 13.5
@export var edge_avoid_force: float = 18.0
@export var arena_center: Vector3 = Vector3.ZERO

@export var weapon_shuffle_min: float = 4.0
@export var weapon_shuffle_max: float = 6.0
@export var fire_attempt_interval_min: float = 0.4
@export var fire_attempt_interval_max: float = 0.9
@export var railgun_fire_interval_min: float = 0.55
@export var railgun_fire_interval_max: float = 0.95
@export var railgun_aim_error: float = 0.65
@export var bazooka_fire_interval_min: float = 0.7
@export var bazooka_fire_interval_max: float = 1.2
@export var bazooka_pick_chance_aggressive: float = 0.4
@export var bazooka_pick_chance_medium: float = 0.26
@export var knockback_recovery_speed: float = 7.5
@export var recovery_duration_min: float = 0.8
@export var recovery_duration_max: float = 1.2

@onready var _weapon_pivot: Node3D = $WeaponPivot
@onready var _weapons: Node3D = $WeaponPivot/EnemyWeaponManager
@onready var combat_stats: CombatStats = $CombatStats

var _player: Node3D
var _spawn_position: Vector3 = Vector3.ZERO
var _void_reported: bool = false
var _game_manager: Node

var _state: AiState = AiState.ATTACKING
var _recovery_timer: float = 0.0
var _strafe_sign: float = 1.0
var _direction_change_timer: float = 1.5
var _weapon_shuffle_timer: float = 5.0
var _fire_attempt_timer: float = 0.5
var _avoiding_edge_logged: bool = false
var _prev_horizontal_speed: float = 0.0
var _death_handled: bool = false
var _void_dying: bool = false
var _void_instability_time: float = 0.0
var _arena_generator: ArenaGenerator
var _arena_walls: Array[Node3D] = []
var _cover_timer: float = 0.0
var _cover_duration: float = 0.0

const CORPSE_ALBEDO: Color = Color(0.85, 0.15, 0.2)
const WALL_GROUP: String = "arena_wall"
const CORPSE_EMISSION: Color = Color(0.45, 0.05, 0.12)


func _ready() -> void:
	add_to_group("arena_opponent")
	_spawn_position = global_position
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_reset_timers()
	_set_state(AiState.ATTACKING)
	combat_stats.died.connect(_on_combat_died)


func take_damage(
	amount: int,
	attacker: Node = null,
	direction: Vector3 = Vector3.ZERO,
	force: float = 0.0,
	source: String = ""
) -> void:
	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		return
	combat_stats.record_hit(direction, force, attacker, source)
	combat_stats.apply_damage(amount, attacker)


func _on_combat_died(_attacker: Node) -> void:
	if _death_handled:
		return
	_death_handled = true
	var heavy: bool = combat_stats.is_heavy_death()
	var world: Node = get_tree().current_scene
	if heavy:
		print("Enemy gibbed by rocket")
		GibSpawner.play_heavy_death(
			world,
			get_death_gib_position(),
			combat_stats.last_hit_direction,
			combat_stats.get_corpse_launch_force(),
			combat_stats.last_damage_source
		)
	else:
		print("Enemy corpse spawned")
		_spawn_death_corpse()
	_hide_live_fighter()
	_enter_death_hidden_state()
	if _game_manager and _game_manager.has_method("on_health_death"):
		_game_manager.on_health_death(false, heavy)


func get_death_gib_position() -> Vector3:
	return global_position + Vector3(0.0, 0.8, 0.0)


func _hide_live_fighter() -> void:
	_set_fighter_meshes_visible(false)


func _show_live_fighter() -> void:
	_set_fighter_meshes_visible(true)


func _set_fighter_meshes_visible(visible: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			(child as Node3D).visible = visible
		elif child is Node3D and child.name != "WeaponPivot":
			for sub in child.get_children():
				if sub is MeshInstance3D:
					(sub as MeshInstance3D).visible = visible


func _spawn_death_corpse() -> void:
	var corpse_pos: Vector3 = global_position + Vector3(0.0, 0.8, 0.0)
	var world: Node = get_tree().current_scene
	CorpseSpawner.spawn(
		world,
		corpse_pos,
		combat_stats.last_hit_direction,
		combat_stats.get_corpse_launch_force(),
		combat_stats.get_corpse_upward_boost(),
		CORPSE_ALBEDO,
		CORPSE_EMISSION,
		"enemy corpse",
		combat_stats.last_damage_source
	)


func _enter_death_hidden_state() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _exit_death_hidden_state() -> void:
	visible = true
	collision_layer = 1
	collision_mask = 1
	freeze = false
	gravity_scale = 1.0
	var body_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if body_mesh:
		body_mesh.visible = true
	var pivot: Node3D = get_node_or_null("WeaponPivot") as Node3D
	if pivot:
		pivot.visible = true


func is_void_dying() -> bool:
	return _void_dying


func begin_void_dying() -> void:
	_void_dying = true
	_void_reported = true
	_void_instability_time = 0.0
	visible = true
	freeze = false
	gravity_scale = 1.0
	collision_layer = 0
	collision_mask = 0


func begin_void_instability() -> void:
	_void_instability_time = GameBalance.VOID_GORE_INSTABILITY_SEC


func end_void_dying() -> void:
	_void_dying = false
	_enter_death_hidden_state()


func get_void_breakup_position() -> Vector3:
	return global_position + Vector3(0.0, 0.8, 0.0)


func hide_for_void_breakup() -> void:
	var body_mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if body_mesh:
		body_mesh.visible = false
	var pivot: Node3D = get_node_or_null("WeaponPivot") as Node3D
	if pivot:
		pivot.visible = false


func _physics_process(delta: float) -> void:
	if _death_handled:
		return

	if _void_dying:
		if _void_instability_time > 0.0:
			_void_instability_time -= delta
			var slide: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
			apply_central_force(slide.normalized() * 18.0 * mass)
			apply_torque_impulse(Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.2), randf_range(-0.4, 0.4)))
			apply_central_force(Vector3.DOWN * 6.0 * mass)
		else:
			apply_central_force(Vector3.DOWN * 14.0 * mass)
		_clamp_horizontal_speed()
		return

	if global_position.y < void_y:
		_report_void_fall()
		return

	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return

	_update_recovery(delta)
	_detect_knockback_recovery()

	var offset: Vector3 = _offset_from_center()
	var to_player: Vector3 = _player.global_position - global_position
	var horizontal_to_player: Vector3 = Vector3(to_player.x, 0.0, to_player.z)
	var distance_to_player: float = horizontal_to_player.length()

	if _is_past_danger(offset):
		_enter_recovery()

	_aim_at_player()

	if _state == AiState.RECOVERING:
		_apply_edge_safety_forces(offset, true)
		_apply_hole_avoidance()
		_move_toward_center(edge_avoid_force * 1.2)
		_clamp_horizontal_speed()
		_prev_horizontal_speed = _horizontal_speed()
		return

	if _state == AiState.IN_COVER:
		_apply_edge_safety_forces(offset, true)
		_apply_hole_avoidance()
		_apply_cover_seek_force()
		_apply_idle_strafe()
		_update_weapon_ai(delta, distance_to_player, offset)
		_update_cover_state(delta, offset)
		_clamp_horizontal_speed()
		_prev_horizontal_speed = _horizontal_speed()
		return

	if not _is_past_safe(offset):
		_avoiding_edge_logged = false

	_apply_edge_safety_forces(offset, false)
	_apply_hole_avoidance()
	_try_enter_cover(distance_to_player, offset)
	_update_combat_movement(delta, horizontal_to_player, distance_to_player, offset)
	_update_weapon_ai(delta, distance_to_player, offset)
	_update_cover_state(delta, offset)

	_prev_horizontal_speed = _horizontal_speed()
	_clamp_horizontal_speed()


func apply_arena_bounds_from_dict(bounds: Dictionary) -> void:
	arena_center = bounds.get("center", Vector3.ZERO)
	safe_half_x = bounds.get("safe_half_x", safe_half_x)
	danger_half_x = bounds.get("danger_half_x", danger_half_x)
	safe_half_z = bounds.get("safe_half_z", safe_half_z)
	danger_half_z = bounds.get("danger_half_z", danger_half_z)
	_arena_generator = get_tree().get_first_node_in_group("arena_generator") as ArenaGenerator
	_refresh_arena_walls()


func arena_respawn(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	global_position = spawn_position
	if _game_manager and _game_manager.has_method("get_void_y"):
		void_y = _game_manager.get_void_y()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_void_reported = false
	_void_dying = false
	_death_handled = false
	_avoiding_edge_logged = false
	_show_live_fighter()
	_exit_death_hidden_state()
	_reset_timers()
	_set_state(AiState.ATTACKING)


func _is_low_combat() -> bool:
	return combat_stats != null and combat_stats.is_low()


func _offset_from_center() -> Vector3:
	var o: Vector3 = global_position - arena_center
	o.y = 0.0
	return o


func _is_past_safe(offset: Vector3) -> bool:
	return absf(offset.x) >= safe_half_x or absf(offset.z) >= safe_half_z


func _is_past_danger(offset: Vector3) -> bool:
	return absf(offset.x) >= danger_half_x or absf(offset.z) >= danger_half_z


func _edge_risk_factor(offset: Vector3) -> float:
	var tx: float = inverse_lerp(safe_half_x, danger_half_x, absf(offset.x))
	var tz: float = inverse_lerp(safe_half_z, danger_half_z, absf(offset.z))
	return maxf(tx, tz)


func _outward_from_arena(pos_offset: Vector3) -> Vector3:
	var gap_x: float = danger_half_x - absf(pos_offset.x)
	var gap_z: float = danger_half_z - absf(pos_offset.z)
	if gap_x < gap_z:
		if absf(pos_offset.x) > 0.01:
			return Vector3(signf(pos_offset.x), 0.0, 0.0)
	elif absf(pos_offset.z) > 0.01:
		return Vector3(0.0, 0.0, signf(pos_offset.z))
	return Vector3(0.0, 0.0, 1.0)


func _reset_timers() -> void:
	_weapon_shuffle_timer = randf_range(weapon_shuffle_min, weapon_shuffle_max)
	_fire_attempt_timer = randf_range(fire_attempt_interval_min, fire_attempt_interval_max)
	_direction_change_timer = randf_range(1.0, 2.0)
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0


func _set_state(new_state: AiState) -> void:
	if _state == new_state:
		return
	_state = new_state
	match new_state:
		AiState.ATTACKING:
			print("Enemy state: ATTACKING")
		AiState.RECOVERING:
			print("Enemy state: RECOVERING")
		AiState.IN_COVER:
			print("Enemy state: IN_COVER")


func _enter_recovery() -> void:
	if _state == AiState.RECOVERING:
		return
	_recovery_timer = randf_range(recovery_duration_min, recovery_duration_max)
	_set_state(AiState.RECOVERING)


func _update_recovery(delta: float) -> void:
	if _state != AiState.RECOVERING:
		return
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		_set_state(AiState.ATTACKING)
		_avoiding_edge_logged = false


func _detect_knockback_recovery() -> void:
	var speed: float = _horizontal_speed()
	if speed - _prev_horizontal_speed > knockback_recovery_speed:
		_enter_recovery()


func _direction_to_center() -> Vector3:
	var to_center: Vector3 = arena_center - global_position
	to_center.y = 0.0
	if to_center.length_squared() < 0.01:
		return Vector3.ZERO
	return to_center.normalized()


func _horizontal_speed() -> float:
	var vel: Vector3 = linear_velocity
	return Vector3(vel.x, 0.0, vel.z).length()


func _apply_edge_safety_forces(offset: Vector3, recovery_mode: bool) -> void:
	var to_center: Vector3 = _direction_to_center()
	if to_center == Vector3.ZERO:
		return

	var strength_mult: float = 1.4 if recovery_mode else 1.0
	var risk: float = _edge_risk_factor(offset)

	if _is_past_danger(offset):
		if not _avoiding_edge_logged:
			print("Enemy avoiding edge")
			_avoiding_edge_logged = true
		apply_central_force(to_center * edge_avoid_force * strength_mult)
	elif _is_past_safe(offset):
		if not _avoiding_edge_logged:
			print("Enemy avoiding edge")
			_avoiding_edge_logged = true
		apply_central_force(to_center * edge_avoid_force * risk * strength_mult)

	var vel_h: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if _is_past_safe(offset) and vel_h.length_squared() > 0.5:
		var outward: Vector3 = _outward_from_arena(offset)
		if vel_h.dot(outward) > 0.5:
			apply_central_force(to_center * edge_avoid_force * 0.85)


func _move_toward_center(force_scale: float) -> void:
	var to_center: Vector3 = _direction_to_center()
	if to_center != Vector3.ZERO:
		apply_central_force(to_center * force_scale)


func _update_combat_movement(
	delta: float,
	horizontal_to_player: Vector3,
	distance: float,
	offset: Vector3
) -> void:
	_direction_change_timer -= delta
	if _direction_change_timer <= 0.0:
		_strafe_sign = -_strafe_sign if randf() > 0.25 else _strafe_sign
		_direction_change_timer = randf_range(1.0, 2.0)

	if horizontal_to_player.length_squared() < 0.05:
		_apply_idle_strafe()
		return

	var to_player_dir: Vector3 = horizontal_to_player.normalized()
	var strafe_dir: Vector3 = to_player_dir.cross(Vector3.UP).normalized() * _strafe_sign
	var near_edge: bool = _is_past_safe(offset)
	var can_chase_forward: bool = not near_edge and _floor_ahead(to_player_dir)
	var evasive: bool = _is_low_combat()
	var retreat_scale: float = 1.35 if evasive else 1.0
	var strafe_scale: float = 1.2 if evasive else 1.0

	if distance < ideal_distance_min or evasive:
		apply_central_force(-to_player_dir * retreat_force * retreat_scale)
		apply_central_force(strafe_dir * strafe_force * 0.65 * strafe_scale)
	elif distance > ideal_distance_max:
		if can_chase_forward and _floor_ahead(to_player_dir):
			apply_central_force(to_player_dir * move_force)
		elif not _has_line_of_sight_to_player():
			_apply_cover_seek_force()
		_move_toward_center(edge_avoid_force * 0.35)
		apply_central_force(strafe_dir * strafe_force * 0.45 * strafe_scale)
	else:
		if not _has_line_of_sight_to_player() and distance > close_range:
			_apply_cover_seek_force()
		apply_central_force(strafe_dir * strafe_force * strafe_scale)
		if _floor_ahead(to_player_dir):
			apply_central_force(to_player_dir * move_force * 0.25)


func _apply_idle_strafe() -> void:
	var strafe_axis: Vector3 = Vector3.RIGHT * _strafe_sign
	apply_central_force(strafe_axis * strafe_force * 0.55)


func _update_weapon_ai(delta: float, distance: float, offset: Vector3) -> void:
	_weapon_shuffle_timer -= delta
	if _weapon_shuffle_timer <= 0.0:
		var options: Array[WeaponDefs.Id] = [
			WeaponDefs.Id.RAILGUN,
			WeaponDefs.Id.SHOTGUN,
			WeaponDefs.Id.BAZOOKA,
		]
		_weapons.switch_weapon(options.pick_random())
		_weapon_shuffle_timer = randf_range(weapon_shuffle_min, weapon_shuffle_max)

	_fire_attempt_timer -= delta
	if _fire_attempt_timer > 0.0:
		return

	_fire_attempt_timer = randf_range(fire_attempt_interval_min, fire_attempt_interval_max)

	if not _weapons.can_fire():
		return

	var preferred: WeaponDefs.Id = _choose_weapon(distance, offset)
	_weapons.switch_weapon(preferred)
	if preferred == WeaponDefs.Id.RAILGUN:
		_fire_attempt_timer = maxf(
			_fire_attempt_timer, randf_range(railgun_fire_interval_min, railgun_fire_interval_max)
		)
	elif preferred == WeaponDefs.Id.BAZOOKA:
		_fire_attempt_timer = maxf(
			_fire_attempt_timer, randf_range(bazooka_fire_interval_min, bazooka_fire_interval_max)
		)
	_try_shot()


func _choose_weapon(distance: float, enemy_offset: Vector3) -> WeaponDefs.Id:
	var player_offset: Vector3 = _player.global_position - arena_center
	player_offset.y = 0.0
	var player_near_edge: bool = _is_past_safe(player_offset)
	var ringout_shot: bool = _has_ringout_shot_angle()
	var aggressive: bool = player_near_edge or ringout_shot
	var has_los: bool = _has_line_of_sight_to_player()

	if distance < close_range:
		return WeaponDefs.Id.SHOTGUN

	if not has_los and distance < medium_range:
		return WeaponDefs.Id.SHOTGUN

	if aggressive:
		if distance < medium_range and randf() < bazooka_pick_chance_aggressive:
			return WeaponDefs.Id.BAZOOKA
		if distance < close_range + 2.5:
			return WeaponDefs.Id.SHOTGUN

	if distance < medium_range and not _is_past_safe(enemy_offset):
		if randf() < bazooka_pick_chance_medium:
			return WeaponDefs.Id.BAZOOKA

	if distance > medium_range and has_los:
		if randf() > 0.32:
			return WeaponDefs.Id.RAILGUN
		return WeaponDefs.Id.BAZOOKA

	if distance > medium_range:
		return WeaponDefs.Id.BAZOOKA

	if has_los and randf() > 0.28:
		return WeaponDefs.Id.RAILGUN
	return WeaponDefs.Id.SHOTGUN


func _refresh_arena_walls() -> void:
	_arena_walls.clear()
	for group_name in [WALL_GROUP, "arena_perimeter"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is Node3D and not _arena_walls.has(node):
				_arena_walls.append(node as Node3D)


func _has_line_of_sight_to_player() -> bool:
	if _player == null:
		return false
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return true
	var origin: Vector3 = _weapon_pivot.global_position
	var target: Vector3 = _player.global_position + Vector3(0.0, aim_height_offset * 0.6, 0.0)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.collider as Object
	if collider == _player:
		return true
	if collider is Node and _player.is_ancestor_of(collider as Node):
		return true
	return false


func _floor_ahead(direction: Vector3, distance: float = 2.0) -> bool:
	if _arena_generator:
		return _arena_generator.is_floor_ahead(global_position, direction, distance)
	return true


func _is_over_gap() -> bool:
	if _arena_generator:
		return not _arena_generator.has_floor_at(global_position.x, global_position.z)
	return false


func _apply_hole_avoidance() -> void:
	if not _is_over_gap():
		return
	var to_center: Vector3 = _direction_to_center()
	if to_center != Vector3.ZERO:
		apply_central_force(to_center * hole_avoid_force)


func _apply_cover_seek_force() -> void:
	var flank: Vector3 = _pick_cover_direction()
	if flank != Vector3.ZERO:
		apply_central_force(flank * cover_seek_force)


func _pick_cover_direction() -> Vector3:
	if _arena_walls.is_empty() or _player == null:
		return Vector3.ZERO
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.05:
		return Vector3.ZERO
	to_player = to_player.normalized()

	var best_dir: Vector3 = Vector3.ZERO
	var best_score: float = -INF
	for wall in _arena_walls:
		if not is_instance_valid(wall):
			continue
		var to_wall: Vector3 = wall.global_position - global_position
		to_wall.y = 0.0
		var dist: float = to_wall.length()
		if dist < 1.2 or dist > 14.0:
			continue
		var dir: Vector3 = to_wall.normalized()
		var flank_score: float = 1.0 - absf(dir.dot(to_player))
		var score: float = flank_score * 12.0 - dist * 0.35
		if score > best_score:
			best_score = score
			best_dir = dir
	return best_dir


func _try_enter_cover(distance: float, offset: Vector3) -> void:
	if _state != AiState.ATTACKING:
		return
	if _is_past_safe(offset) or _is_low_combat():
		return
	if distance < close_range + 1.0:
		return
	if _has_line_of_sight_to_player():
		if distance > medium_range and randf() > 0.92:
			_enter_cover()
		return
	if randf() > 0.55:
		_enter_cover()


func _enter_cover() -> void:
	_cover_duration = randf_range(1.2, 2.4)
	_cover_timer = _cover_duration
	_set_state(AiState.IN_COVER)


func _update_cover_state(delta: float, offset: Vector3) -> void:
	if _state != AiState.IN_COVER:
		return
	_cover_timer -= delta
	if _cover_timer <= 0.0 or _is_past_danger(offset):
		_set_state(AiState.ATTACKING)
		return
	if _has_line_of_sight_to_player() and _cover_timer < _cover_duration * 0.35:
		if randf() > 0.6:
			_set_state(AiState.ATTACKING)


func _has_ringout_shot_angle() -> bool:
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.25:
		return false

	var shot_dir: Vector3 = to_player.normalized()
	var player_offset: Vector3 = _player.global_position - arena_center
	player_offset.y = 0.0
	var outward: Vector3 = _outward_from_arena(player_offset)
	return shot_dir.dot(outward) > 0.45


func _report_void_fall() -> void:
	if _void_reported or _death_handled:
		return
	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		return
	_void_reported = true
	if _game_manager and _game_manager.has_method("report_enemy_void_fall"):
		_game_manager.report_enemy_void_fall()


func _aim_at_player() -> void:
	var target: Vector3 = _player.global_position + Vector3(0.0, aim_height_offset * 0.5, 0.0)
	var pivot_pos: Vector3 = _weapon_pivot.global_position
	var flat_dir: Vector3 = Vector3(target.x - pivot_pos.x, 0.0, target.z - pivot_pos.z)
	if flat_dir.length_squared() < 0.01:
		return
	_weapon_pivot.look_at(pivot_pos + flat_dir.normalized(), Vector3.UP)


func _try_shot() -> void:
	var aim_point: Vector3 = _player.global_position + Vector3(0.0, aim_height_offset, 0.0)
	if _weapons.get_weapon() == WeaponDefs.Id.RAILGUN:
		aim_point += _sample_railgun_aim_error()
	var origin: Vector3 = _weapon_pivot.global_position
	var direction: Vector3 = (aim_point - origin).normalized()
	if direction.length_squared() < 0.01:
		return
	_weapons.try_fire(origin, direction, _weapon_pivot.global_transform.basis)


func _sample_railgun_aim_error() -> Vector3:
	var e: float = railgun_aim_error
	return Vector3(randf_range(-e, e), randf_range(-e * 0.45, e * 0.45), randf_range(-e, e))


func _clamp_horizontal_speed() -> void:
	var vel: Vector3 = linear_velocity
	var horizontal: Vector3 = Vector3(vel.x, 0.0, vel.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		linear_velocity = Vector3(horizontal.x, vel.y, horizontal.z)
