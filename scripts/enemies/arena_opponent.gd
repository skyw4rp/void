## 1v1 arena AI — movement, range-based weapons, full shared weapon kit.
extends RigidBody3D

@export var move_force: float = 10.0
@export var strafe_force: float = 7.0
@export var retreat_force: float = 12.0
@export var max_speed: float = 5.0
@export var void_y: float = -20.0
@export var aim_height_offset: float = 1.2

@export var close_range: float = 5.0
@export var medium_range: float = 12.0
@export var ideal_distance_min: float = 4.0
@export var ideal_distance_max: float = 9.0

@export var weapon_shuffle_min: float = 4.0
@export var weapon_shuffle_max: float = 6.0
@export var fire_attempt_interval_min: float = 0.4
@export var fire_attempt_interval_max: float = 0.9

@onready var _weapon_pivot: Node3D = $WeaponPivot
@onready var _weapons: Node3D = $WeaponPivot/EnemyWeaponManager

var _player: Node3D
var _spawn_position: Vector3 = Vector3.ZERO
var _void_reported: bool = false
var _game_manager: Node
var _weapon_shuffle_timer: float = 5.0
var _fire_attempt_timer: float = 0.5


func _ready() -> void:
	add_to_group("arena_opponent")
	_spawn_position = global_position
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_weapon_shuffle_timer = randf_range(weapon_shuffle_min, weapon_shuffle_max)
	_fire_attempt_timer = randf_range(fire_attempt_interval_min, fire_attempt_interval_max)


func _physics_process(delta: float) -> void:
	if global_position.y < void_y:
		_report_void_fall()
		return

	if _game_manager and not _game_manager.is_round_active():
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return

	var to_player := _player.global_position - global_position
	var horizontal := Vector3(to_player.x, 0.0, to_player.z)
	var distance := horizontal.length()

	_aim_at_player()
	_update_movement(horizontal, distance)
	_update_weapon_ai(delta, distance)


func arena_respawn(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	global_position = spawn_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_void_reported = false
	_weapon_shuffle_timer = randf_range(weapon_shuffle_min, weapon_shuffle_max)
	_fire_attempt_timer = randf_range(fire_attempt_interval_min, fire_attempt_interval_max)


func _report_void_fall() -> void:
	if _void_reported:
		return
	_void_reported = true
	if _game_manager and _game_manager.has_method("report_enemy_fell"):
		_game_manager.report_enemy_fell()


func _aim_at_player() -> void:
	var target := _player.global_position + Vector3(0.0, aim_height_offset * 0.5, 0.0)
	var pivot_pos := _weapon_pivot.global_position
	var flat_dir := Vector3(target.x - pivot_pos.x, 0.0, target.z - pivot_pos.z)
	if flat_dir.length_squared() < 0.01:
		return
	_weapon_pivot.look_at(pivot_pos + flat_dir.normalized(), Vector3.UP)


func _update_movement(horizontal_to_player: Vector3, distance: float) -> void:
	if horizontal_to_player.length_squared() < 0.05:
		return

	var dir := horizontal_to_player.normalized()

	if distance < ideal_distance_min:
		apply_central_force(-dir * retreat_force)
	elif distance > ideal_distance_max:
		apply_central_force(dir * move_force)
	else:
		var strafe := dir.cross(Vector3.UP).normalized()
		if randf() > 0.5:
			strafe = -strafe
		apply_central_force(strafe * strafe_force)

	_clamp_horizontal_speed()


func _clamp_horizontal_speed() -> void:
	var vel := linear_velocity
	var horizontal := Vector3(vel.x, 0.0, vel.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		linear_velocity = Vector3(horizontal.x, vel.y, horizontal.z)


func _update_weapon_ai(delta: float, distance: float) -> void:
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

	var preferred := _weapon_for_distance(distance)
	_weapons.switch_weapon(preferred)
	_try_shot()


func _weapon_for_distance(distance: float) -> WeaponDefs.Id:
	if distance < close_range:
		return WeaponDefs.Id.SHOTGUN
	if distance < medium_range:
		return WeaponDefs.Id.BAZOOKA
	return WeaponDefs.Id.PISTOL


func _try_shot() -> void:
	var aim_point := _player.global_position + Vector3(0.0, aim_height_offset, 0.0)
	var origin := _weapon_pivot.global_position
	var direction := (aim_point - origin).normalized()
	if direction.length_squared() < 0.01:
		return

	_weapons.try_fire(origin, direction, _weapon_pivot.global_transform.basis)
