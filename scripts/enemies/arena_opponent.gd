## 1v1 bridge arena AI — rectangular bounds, edge recovery, ring-out tactics.
extends RigidBody3D

enum AiState { ATTACKING, RECOVERING }

@export var move_force: float = 10.0
@export var strafe_force: float = 8.0
@export var retreat_force: float = 12.0
@export var max_speed: float = 5.0
@export var void_y: float = -20.0
@export var aim_height_offset: float = 1.2

@export var close_range: float = 5.0
@export var medium_range: float = 12.0
@export var ideal_distance_min: float = 4.0
@export var ideal_distance_max: float = 11.0

## Bridge half-extents: deck is 8×28 (±4 on X, ±14 on Z).
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

const CORPSE_ALBEDO: Color = Color(0.85, 0.15, 0.2)
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
	_spawn_death_corpse()
	_enter_death_hidden_state()
	if _game_manager and _game_manager.has_method("on_health_death"):
		_game_manager.on_health_death(false)


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


func is_void_dying() -> bool:
	return _void_dying


func begin_void_dying() -> void:
	_void_dying = true
	_void_reported = true
	visible = true
	freeze = false
	gravity_scale = 1.0
	collision_layer = 0
	collision_mask = 0


func end_void_dying() -> void:
	_void_dying = false
	_enter_death_hidden_state()


func _physics_process(delta: float) -> void:
	if _death_handled:
		return

	if _void_dying:
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
		_move_toward_center(edge_avoid_force * 1.2)
		_clamp_horizontal_speed()
		_prev_horizontal_speed = _horizontal_speed()
		return

	if not _is_past_safe(offset):
		_avoiding_edge_logged = false

	_apply_edge_safety_forces(offset, false)
	_update_combat_movement(delta, horizontal_to_player, distance_to_player, offset)
	_update_weapon_ai(delta, distance_to_player, offset)

	_prev_horizontal_speed = _horizontal_speed()
	_clamp_horizontal_speed()


func arena_respawn(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	global_position = spawn_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_void_reported = false
	_void_dying = false
	_death_handled = false
	_avoiding_edge_logged = false
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
	var can_chase_forward: bool = not near_edge
	var evasive: bool = _is_low_combat()
	var retreat_scale: float = 1.35 if evasive else 1.0
	var strafe_scale: float = 1.2 if evasive else 1.0

	if distance < ideal_distance_min or evasive:
		apply_central_force(-to_player_dir * retreat_force * retreat_scale)
		apply_central_force(strafe_dir * strafe_force * 0.65 * strafe_scale)
	elif distance > ideal_distance_max:
		if can_chase_forward:
			apply_central_force(to_player_dir * move_force)
		_move_toward_center(edge_avoid_force * 0.35)
		apply_central_force(strafe_dir * strafe_force * 0.45 * strafe_scale)
	else:
		apply_central_force(strafe_dir * strafe_force * strafe_scale)
		apply_central_force(to_player_dir * move_force * 0.25)


func _apply_idle_strafe() -> void:
	var strafe_axis: Vector3 = Vector3.RIGHT * _strafe_sign
	apply_central_force(strafe_axis * strafe_force * 0.55)


func _update_weapon_ai(delta: float, distance: float, offset: Vector3) -> void:
	_weapon_shuffle_timer -= delta
	if _weapon_shuffle_timer <= 0.0:
		var options: Array[WeaponDefs.Id] = [
			WeaponDefs.Id.PISTOL,
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
	_try_shot()


func _choose_weapon(distance: float, enemy_offset: Vector3) -> WeaponDefs.Id:
	var player_offset: Vector3 = _player.global_position - arena_center
	player_offset.y = 0.0
	var player_near_edge: bool = _is_past_safe(player_offset)
	var ringout_shot: bool = _has_ringout_shot_angle()
	var aggressive: bool = player_near_edge or ringout_shot

	if distance < close_range:
		return WeaponDefs.Id.SHOTGUN

	if aggressive:
		if distance < medium_range and randf() > 0.38:
			return WeaponDefs.Id.BAZOOKA
		if distance < close_range + 2.5:
			return WeaponDefs.Id.SHOTGUN

	if distance < medium_range and not _is_past_safe(enemy_offset):
		if randf() > 0.55:
			return WeaponDefs.Id.BAZOOKA

	return WeaponDefs.Id.PISTOL


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
	var origin: Vector3 = _weapon_pivot.global_position
	var direction: Vector3 = (aim_point - origin).normalized()
	if direction.length_squared() < 0.01:
		return
	_weapons.try_fire(origin, direction, _weapon_pivot.global_transform.basis)


func _clamp_horizontal_speed() -> void:
	var vel: Vector3 = linear_velocity
	var horizontal: Vector3 = Vector3(vel.x, 0.0, vel.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		linear_velocity = Vector3(horizontal.x, vel.y, horizontal.z)
