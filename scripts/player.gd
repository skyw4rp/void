## First-person CharacterBody3D — VOID gladiator arena locomotion (Quake/UT-inspired).
extends CharacterBody3D

signal movement_dodged(direction: Vector3)
signal movement_landed(impact_speed: float)
signal movement_high_speed(speed: float)
signal movement_heavy_impact(impact_speed: float)
signal movement_air_accel()

const JUMP_VELOCITY: float = 5.2
const MOUSE_SENSITIVITY: float = 0.002

const LOOK_PITCH_MIN: float = -1.4
const LOOK_PITCH_MAX: float = 1.4

@export_group("Gladiator Locomotion")
@export var ground_acceleration: float = 46.0
@export var air_acceleration: float = 17.0
@export var friction: float = 5.5
@export var air_control: float = 0.48
@export var max_ground_speed: float = 7.6
@export var max_air_speed: float = 9.0
@export var strafe_boost: float = 1.08
@export var landing_damp: float = 0.5
@export var movement_tilt_strength: float = 0.03
@export var base_fov: float = 78.0
@export var speed_fov_boost: float = 4.0
@export var speed_fov_ground_extra: float = 0.4
@export var landing_shake_strength: float = 0.14
@export var weapon_fov_pulse: float = 1.25

@export_group("Dodge")
@export var dodge_distance: float = 2.05
@export var dodge_duration: float = 0.15
@export var dodge_cooldown: float = 1.4

@export_group("Aim")
@export var crosshair_stabilized: bool = true
@export var camera_bob_affects_aim: bool = false
@export var weapon_bob_affects_aim: bool = false

@export_group("Debug")
@export var debug_movement: bool = false

@onready var combat_stats: CombatStats = $CombatStats

var _aim_pivot: Node3D
var _camera_feel_pivot: Node3D
var camera: Camera3D

var _dodge: CombatDodge = CombatDodge.new()
var _camera_feel: GladiatorCameraFeel = GladiatorCameraFeel.new()
var _fov: GladiatorFov = GladiatorFov.new()
var _was_on_floor: bool = true
var _knockback_blend: float = 0.0

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
var _obliteration_shake: float = 0.0
var _void_dying: bool = false
var _void_fall_shake: float = 0.0
var _void_fall_time: float = 0.0
var _void_instability_time: float = 0.0
var _void_fall_proxy: MeshInstance3D

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
	_dodge.dodge_distance = dodge_distance
	_dodge.dodge_duration = dodge_duration
	_dodge.dodge_cooldown = dodge_cooldown
	_setup_aim_camera_hierarchy()
	_fov.configure_base(base_fov)
	_fov.reset_round(camera, true)
	_camera_feel.reset(camera, _camera_feel_pivot)
	_apply_crosshair_stabilization()
	combat_stats.died.connect(_on_combat_died)
	_bind_game_flow()


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
	var dismember: bool = combat_stats.is_dismemberment_death()
	var world: Node = get_tree().current_scene
	if dismember:
		var shake: float = 1.45
		if combat_stats.last_damage_source in ["shotgun", "bazooka_direct", "bazooka_explosion"]:
			shake = 1.75
		_begin_obliteration_shake(shake)
		DismembermentSpawner.play_from_stats(
			world,
			get_death_gib_position(),
			combat_stats,
			Color(0.24, 0.08, 0.1),
			Color(0.14, 0.38, 0.48),
			false
		)
	else:
		_spawn_death_corpse()
	_hide_live_fighter()
	_enter_death_hidden_state()
	if _game_manager and _game_manager.has_method("on_health_death"):
		_game_manager.on_health_death(true, dismember, combat_stats)


func get_death_gib_position() -> Vector3:
	return global_position + Vector3(0.0, 0.85, 0.0)


func _begin_obliteration_shake(intensity: float = 1.0) -> void:
	_obliteration_shake = intensity


func _hide_live_fighter() -> void:
	_hide_void_fall_proxy()


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
	_void_fall_time = 0.0
	_void_fall_shake = 0.0
	_void_instability_time = 0.0
	collision_layer = 0
	collision_mask = 0
	VoidGasController.notify_fall_started(self)
	if GameBalance.uses_void_gore_cinematic():
		_ensure_void_fall_proxy()
		if _void_fall_proxy:
			_void_fall_proxy.visible = true


func begin_void_instability() -> void:
	_void_instability_time = GameBalance.VOID_GORE_INSTABILITY_SEC


func end_void_dying() -> void:
	_void_dying = false
	VoidGasController.notify_fall_ended()
	_hide_void_fall_proxy()
	_enter_death_hidden_state()


func get_void_breakup_position() -> Vector3:
	return global_position + Vector3(0.0, 0.85, 0.0)


func hide_for_void_breakup() -> void:
	_hide_void_fall_proxy()


func _ensure_void_fall_proxy() -> void:
	if _void_fall_proxy != null:
		return
	_void_fall_proxy = MeshInstance3D.new()
	_void_fall_proxy.name = "VoidFallProxy"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.45
	_void_fall_proxy.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.82, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.45, 0.75, 1.0)
	mat.emission_energy_multiplier = 0.3
	_void_fall_proxy.material_override = mat
	_void_fall_proxy.position = Vector3(0.0, 0.85, 0.0)
	add_child(_void_fall_proxy)


func _hide_void_fall_proxy() -> void:
	if _void_fall_proxy:
		_void_fall_proxy.visible = false


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

	_knockback_blend = 0.35
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

	_knockback_blend = 0.4
	_clamp_knockback_velocity(airborne)


## Rocket jump — bazooka self-blast with higher vertical cap than normal explosions.
func apply_rocket_jump_knockback(
	horizontal_direction: Vector3, horizontal_force: float, vertical_force: float
) -> void:
	var airborne: bool = not is_on_floor()
	var h_dir: Vector3 = Vector3(horizontal_direction.x, 0.0, horizontal_direction.z)
	if h_dir.length_squared() > 0.001:
		h_dir = h_dir.normalized()
		# Rocket jump forces are pre-scaled in WeaponDefs — no player knockback multiplier.
		velocity.x += h_dir.x * horizontal_force
		velocity.z += h_dir.z * horizontal_force

	velocity.y += vertical_force
	_knockback_blend = 0.55
	_clamp_rocket_jump_velocity(airborne)


func _clamp_rocket_jump_velocity(airborne: bool) -> void:
	var max_h: float = WeaponDefs.MAX_ROCKET_JUMP_HORIZONTAL_VELOCITY
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() > max_h:
		horizontal = horizontal.normalized() * max_h
		velocity.x = horizontal.x
		velocity.z = horizontal.z

	velocity.y = clampf(
		velocity.y,
		max_downward_velocity,
		WeaponDefs.MAX_ROCKET_JUMP_UPWARD_VELOCITY
	)
	var horiz_speed: float = horizontal.length()
	print(
		"Rocket jump applied: velocity=%s (horizontal=%.1f vertical=%.1f)"
		% [velocity, horiz_speed, velocity.y]
	)


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
	if _game_manager and _game_manager.has_method("get_void_y"):
		_void_y = _game_manager.get_void_y()
	velocity = Vector3.ZERO
	_void_reported = false
	_void_dying = false
	_death_handled = false
	_obliteration_shake = 0.0
	_void_fall_shake = 0.0
	_void_fall_time = 0.0
	_last_vertical_lift_time_sec = -1.0
	_knockback_blend = 0.0
	_dodge.reset()
	_was_on_floor = true
	_hide_void_fall_proxy()
	_exit_death_hidden_state()
	_fov.configure_base(base_fov)
	_fov.reset_round(camera, false)
	_fov.clear_gameplay_offsets()
	_camera_feel.reset(camera, _camera_feel_pivot)
	if _aim_pivot:
		_aim_pivot.rotation = Vector3.ZERO
	VoidGasController.notify_fall_ended()
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
		if _aim_pivot:
			_aim_pivot.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
			_aim_pivot.rotation.x = clampf(_aim_pivot.rotation.x, LOOK_PITCH_MIN, LOOK_PITCH_MAX)


func _process(delta: float) -> void:
	if _obliteration_shake > 0.0 and _camera_feel_pivot:
		_obliteration_shake = maxf(0.0, _obliteration_shake - delta * 0.35)
		_camera_feel.apply_impulse_shake(_camera_feel_pivot, _obliteration_shake)


func _physics_process(delta: float) -> void:
	if _death_handled and not _void_dying:
		if _obliteration_shake > 0.0:
			velocity = Vector3.ZERO
			move_and_slide()
		return

	if _void_dying:
		if _void_instability_time > 0.0:
			_void_instability_time -= delta
			velocity.x += randf_range(-1.0, 1.0) * 4.0 * delta
			velocity.z += randf_range(-1.0, 1.0) * 4.0 * delta
			velocity.y -= _gravity * delta * 0.35
			if _camera_feel_pivot:
				_camera_feel_pivot.rotation.z += randf_range(-0.03, 0.03)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 2.0)
			velocity.z = move_toward(velocity.z, 0.0, 2.0)
			velocity.y -= _gravity * delta
		_void_fall_time += delta
		_void_fall_shake = minf(_void_fall_shake + delta * 2.5, 1.0)
		if _camera_feel_pivot:
			_camera_feel.apply_impulse_shake(_camera_feel_pivot, _void_fall_shake * 0.35)
		if GameBalance.uses_void_gore_cinematic():
			var fall_t: float = clampf(
				_void_fall_time / GameBalance.VOID_GORE_BURST_AT, 0.0, 1.0
			)
			_fov.set_void_offset(lerpf(0.0, GameBalance.VOID_FALL_FOV_MAX_ADD, fall_t))
		if camera:
			_fov.apply(camera, delta, true)
		move_and_slide()
		return

	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		velocity = Vector3.ZERO
		_fov.clear_gameplay_offsets()
		_fov.set_void_offset(0.0)
		if camera:
			_fov.apply(camera, delta, false)
		move_and_slide()
		return

	_dodge.tick(delta)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _dodge.is_active():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length_squared() > 0.01:
		_dodge.register_move_input(input_dir)
		var dodge_try: Dictionary = {}
		if Input.is_action_just_pressed("sprint"):
			dodge_try = _dodge.try_player_dodge(input_dir, transform.basis, true)
		elif _dodge.consume_double_tap_if_ready(input_dir):
			dodge_try = _dodge.try_player_dodge(input_dir, transform.basis, true)
		if dodge_try.get("triggered", false):
			movement_dodged.emit(dodge_try.direction as Vector3)

	var dodge_boost: Vector3 = _dodge.get_active_velocity_boost()
	var loco_config: Dictionary = _locomotion_config()
	var step: GladiatorLocomotion.StepResult = GladiatorLocomotion.step(
		self,
		delta,
		input_dir,
		transform.basis,
		_gravity,
		loco_config,
		dodge_boost,
		_was_on_floor
	)
	_was_on_floor = is_on_floor()

	if step.just_landed:
		movement_landed.emit(step.land_impact)
		if step.land_impact > 4.5:
			movement_heavy_impact.emit(step.land_impact)
	if step.high_speed:
		movement_high_speed.emit(step.horizontal_speed)
	if step.air_accel_event:
		movement_air_accel.emit()

	_knockback_blend = maxf(0.0, _knockback_blend - delta * 2.2)
	_camera_feel.update(
		camera,
		_camera_feel_pivot,
		delta,
		step,
		input_dir,
		loco_config,
		_dodge.is_active(),
		_fov
	)
	_fov.set_void_offset(0.0)
	if camera:
		_fov.apply(camera, delta, false)

	if debug_movement:
		print(
			"Move spd=%.1f floor=%s dodge_cd=%.2f"
			% [step.horizontal_speed, is_on_floor(), _dodge.get_cooldown_remaining()]
		)

	move_and_slide()

	if global_position.y < _void_y:
		_report_void_fall()


func _locomotion_config() -> Dictionary:
	return {
		"ground_acceleration": ground_acceleration,
		"air_acceleration": air_acceleration,
		"friction": friction * (0.65 if _knockback_blend > 0.05 else 1.0),
		"air_control": air_control,
		"max_ground_speed": max_ground_speed,
		"max_air_speed": max_air_speed,
		"strafe_boost": strafe_boost,
		"landing_damp": landing_damp,
		"movement_tilt_strength": movement_tilt_strength,
		"speed_fov_boost": speed_fov_boost,
		"speed_fov_ground_extra": speed_fov_ground_extra,
		"landing_shake_strength": landing_shake_strength,
	}


func get_aim_global_transform() -> Transform3D:
	if _aim_pivot:
		return _aim_pivot.global_transform
	if camera:
		return camera.global_transform
	return global_transform


func get_aim_forward() -> Vector3:
	var basis: Basis = get_aim_global_transform().basis
	var fwd: Vector3 = -basis.z
	if fwd.length_squared() < 0.0001:
		return Vector3.FORWARD
	return fwd.normalized()


func _setup_aim_camera_hierarchy() -> void:
	if has_node("AimPivot/CameraFeelPivot/Camera3D"):
		_aim_pivot = $AimPivot
		_camera_feel_pivot = $AimPivot/CameraFeelPivot
		camera = $AimPivot/CameraFeelPivot/Camera3D
		_aim_pivot.add_to_group("player_aim")
		return

	var old_camera: Camera3D = get_node_or_null("Camera3D") as Camera3D
	if old_camera == null:
		push_error("Player: missing Camera3D")
		return

	var eye_height: Vector3 = old_camera.position
	var saved_pitch: float = old_camera.rotation.x
	var saved_fov: float = base_fov

	_aim_pivot = Node3D.new()
	_aim_pivot.name = "AimPivot"
	add_child(_aim_pivot)
	_aim_pivot.position = eye_height
	_aim_pivot.rotation.x = saved_pitch
	_aim_pivot.add_to_group("player_aim")

	_camera_feel_pivot = Node3D.new()
	_camera_feel_pivot.name = "CameraFeelPivot"
	_aim_pivot.add_child(_camera_feel_pivot)

	for child in old_camera.get_children():
		old_camera.remove_child(child)
		_camera_feel_pivot.add_child(child)

	remove_child(old_camera)
	_camera_feel_pivot.add_child(old_camera)
	old_camera.position = Vector3.ZERO
	old_camera.rotation = Vector3.ZERO
	old_camera.fov = saved_fov
	camera = old_camera


func notify_weapon_fov_pulse() -> void:
	_fov.trigger_weapon_pulse(weapon_fov_pulse)


func _bind_game_flow() -> void:
	if _game_manager == null:
		return
	if _game_manager.has_signal("countdown_hidden"):
		if not _game_manager.countdown_hidden.is_connected(_on_round_countdown_hidden):
			_game_manager.countdown_hidden.connect(_on_round_countdown_hidden)


func _on_round_countdown_hidden() -> void:
	_fov.configure_base(base_fov)
	_fov.clear_gameplay_offsets()
	_fov.set_void_offset(0.0)


func _apply_crosshair_stabilization() -> void:
	var cross: Control = Crosshair.get_instance(get_tree())
	if cross and cross.has_method("configure_aim_stability"):
		cross.call("configure_aim_stability", crosshair_stabilized, crosshair_stabilized)


func _report_void_fall() -> void:
	if _void_reported or _death_handled:
		return
	if _game_manager and _game_manager.has_method("is_fighting") and not _game_manager.is_fighting():
		return
	_void_reported = true
	if _game_manager and _game_manager.has_method("report_player_void_fall"):
		_game_manager.report_player_void_fall()
