## First-person CharacterBody3D controller for the 1v1 arena prototype.
extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 9.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002

const LOOK_PITCH_MIN: float = -1.4
const LOOK_PITCH_MAX: float = 1.4

@onready var camera: Camera3D = $Camera3D
@onready var combat_stats: CombatStats = $CombatStats

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _spawn_position: Vector3 = Vector3.ZERO
var _void_y: float = -20.0
var _void_reported: bool = false
var _game_manager: Node

@export var knockback_multiplier: float = WeaponDefs.PLAYER_KNOCKBACK_MULTIPLIER
@export var grounded_upward_factor: float = WeaponDefs.GROUNDED_UPWARD_KNOCKBACK_FACTOR
@export var airborne_upward_factor: float = WeaponDefs.AIRBORNE_UPWARD_KNOCKBACK_FACTOR
@export var max_upward_velocity: float = WeaponDefs.PLAYER_MAX_UPWARD_VELOCITY
@export var max_downward_velocity: float = WeaponDefs.PLAYER_MAX_DOWNWARD_VELOCITY
@export var max_horizontal_knockback_speed_grounded: float = (
	WeaponDefs.PLAYER_MAX_HORIZONTAL_KNOCKBACK_GROUNDED
)
@export var max_horizontal_knockback_speed_airborne: float = (
	WeaponDefs.PLAYER_MAX_HORIZONTAL_KNOCKBACK_AIRBORNE
)

var _last_vertical_lift_time_sec: float = -1.0
var _death_handled: bool = false
var _void_dying: bool = false
var _void_fall_shake: float = 0.0

const CORPSE_ALBEDO: Color = Color(0.42, 0.82, 1.0)
const CORPSE_EMISSION: Color = Color(0.15, 0.45, 0.75)


func _ready() -> void:
	add_to_group("player")
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	if _game_manager:
		_void_y = _game_manager.get_void_y()
		_spawn_position = _game_manager.get_player_spawn()
	else:
		_spawn_position = global_position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
		_game_manager.on_health_death(true)


func _spawn_death_corpse() -> void:
	var corpse_pos: Vector3 = global_position + Vector3(0.0, 0.85, 0.0)
	var world: Node = get_tree().current_scene
	CorpseSpawner.spawn(
		world,
		corpse_pos,
		combat_stats.last_hit_direction,
		combat_stats.get_corpse_launch_force(),
		combat_stats.get_corpse_upward_boost(),
		CORPSE_ALBEDO,
		CORPSE_EMISSION,
		"player corpse",
		combat_stats.last_damage_source
	)


func _enter_death_hidden_state() -> void:
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO


func _exit_death_hidden_state() -> void:
	collision_layer = 1
	collision_mask = 1


func is_void_dying() -> bool:
	return _void_dying


func begin_void_dying() -> void:
	_void_dying = true
	_void_reported = true
	collision_layer = 0
	collision_mask = 0


func end_void_dying() -> void:
	_void_dying = false
	_enter_death_hidden_state()


## Returns horizontal knockback strength applied. Set allow_vertical_lift false for extra shotgun pellets.
func apply_knockback(direction: Vector3, force: float, allow_vertical_lift: bool = true) -> float:
	var airborne: bool = not is_on_floor()
	var applied: float = force * knockback_multiplier

	var flat_dir: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() > 0.001:
		flat_dir = flat_dir.normalized()
		velocity.x += flat_dir.x * applied
		velocity.z += flat_dir.z * applied
	else:
		var dir: Vector3 = direction.normalized()
		velocity.x += dir.x * applied
		velocity.z += dir.z * applied

	if allow_vertical_lift and _should_apply_vertical_lift():
		var up_factor: float = airborne_upward_factor if airborne else grounded_upward_factor
		velocity.y += force * up_factor
		_last_vertical_lift_time_sec = _time_sec()

	_clamp_knockback_velocity(airborne)
	return applied


## Explosion knockback — horizontal shove plus capped vertical.
func apply_explosion_knockback(
	horizontal_direction: Vector3, horizontal_force: float, vertical_force: float
) -> void:
	var airborne: bool = not is_on_floor()
	var h_dir: Vector3 = Vector3(horizontal_direction.x, 0.0, horizontal_direction.z)
	if h_dir.length_squared() > 0.001:
		h_dir = h_dir.normalized()
		var h_applied: float = horizontal_force * knockback_multiplier
		velocity.x += h_dir.x * h_applied
		velocity.z += h_dir.z * h_applied

	velocity.y += vertical_force

	_clamp_knockback_velocity(airborne)


func _should_apply_vertical_lift() -> bool:
	var now: float = _time_sec()
	if now - _last_vertical_lift_time_sec >= WeaponDefs.SHOTGUN_VERTICAL_LIFT_WINDOW_SEC:
		return true
	return false


func _time_sec() -> float:
	return Time.get_ticks_msec() / 1000.0


func _clamp_knockback_velocity(airborne: bool) -> void:
	var max_h: float = (
		max_horizontal_knockback_speed_airborne
		if airborne
		else max_horizontal_knockback_speed_grounded
	)
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() > max_h:
		horizontal = horizontal.normalized() * max_h
		velocity.x = horizontal.x
		velocity.z = horizontal.z

	velocity.y = clampf(velocity.y, max_downward_velocity, max_upward_velocity)

	var state_label: String = "airborne" if airborne else "grounded"
	print("Player knockback clamped: velocity=%s (%s)" % [velocity, state_label])


func arena_respawn(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	global_position = spawn_position
	velocity = Vector3.ZERO
	_void_reported = false
	_void_dying = false
	_death_handled = false
	_void_fall_shake = 0.0
	_last_vertical_lift_time_sec = -1.0
	_exit_death_hidden_state()
	camera.rotation.x = 0.0
	camera.rotation.z = 0.0
	# TODO: camera shake or screen flash on respawn.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event.is_action_pressed("shoot") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if _void_dying:
		return

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, LOOK_PITCH_MIN, LOOK_PITCH_MAX)


func _physics_process(delta: float) -> void:
	if _void_dying:
		velocity.x = move_toward(velocity.x, 0.0, 2.0)
		velocity.z = move_toward(velocity.z, 0.0, 2.0)
		velocity.y -= _gravity * delta
		_void_fall_shake = minf(_void_fall_shake + delta * 2.5, 1.0)
		var shake: float = _void_fall_shake * 0.04
		camera.rotation.x += randf_range(-shake, shake)
		camera.rotation.z = randf_range(-shake * 0.5, shake * 0.5)
		move_and_slide()
		return

	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if direction.is_zero_approx():
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	move_and_slide()

	if global_position.y < _void_y:
		_report_void_fall()


func _report_void_fall() -> void:
	if _void_reported or _death_handled:
		return
	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		return
	_void_reported = true
	if _game_manager and _game_manager.has_method("report_player_void_fall"):
		_game_manager.report_player_void_fall()
