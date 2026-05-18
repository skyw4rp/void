## Combined FOV offsets — smooth apply, separate sources, clamped gameplay range.
class_name GladiatorFov
extends RefCounted

const DEFAULT_BASE_FOV: float = 78.0
const MAX_GAMEPLAY_ADD: float = 6.0
const MIN_GAMEPLAY_SUB: float = 2.0
const VOID_MAX_ADD: float = 24.0
const SMOOTH_RATE: float = 7.5


var base_fov: float = DEFAULT_BASE_FOV

var _movement_add: float = 0.0
var _impact_add: float = 0.0
var _void_add: float = 0.0
var _weapon_add: float = 0.0


func configure_base(fov: float) -> void:
	base_fov = clampf(fov, 60.0, 100.0)


func reset_round(camera: Camera3D, snap_to_base: bool = false) -> void:
	_movement_add = 0.0
	_impact_add = 0.0
	_void_add = 0.0
	_weapon_add = 0.0
	if snap_to_base and camera:
		camera.fov = base_fov


func clear_gameplay_offsets() -> void:
	_movement_add = 0.0
	_impact_add = 0.0
	_weapon_add = 0.0


func set_movement_from_speed(
	horizontal_speed: float,
	max_speed: float,
	boost_max: float,
	ground_extra: float,
	airborne: bool
) -> void:
	var speed_t: float = clampf(horizontal_speed / maxf(max_speed, 0.01), 0.0, 1.0)
	_movement_add = boost_max * speed_t
	if not airborne:
		_movement_add += ground_extra * speed_t


func add_impact(amount: float) -> void:
	_impact_add = clampf(_impact_add + amount, 0.0, 2.5)


func set_void_offset(amount: float) -> void:
	_void_add = maxf(0.0, amount)


func trigger_weapon_pulse(amount: float = 1.25) -> void:
	_weapon_add = clampf(amount, 0.0, 2.0)


func compute_target(void_fall: bool) -> float:
	var total_add: float = _movement_add + _impact_add + _void_add + _weapon_add
	if void_fall:
		return clampf(base_fov + total_add, base_fov, base_fov + VOID_MAX_ADD)
	return clampf(
		base_fov + total_add,
		base_fov - MIN_GAMEPLAY_SUB,
		base_fov + MAX_GAMEPLAY_ADD
	)


func apply(camera: Camera3D, delta: float, void_fall: bool = false) -> void:
	if camera == null:
		return
	_weapon_add = move_toward(_weapon_add, 0.0, delta * 16.0)
	_impact_add = move_toward(_impact_add, 0.0, delta * 5.5)
	var target: float = compute_target(void_fall)
	var blend: float = 1.0 - exp(-SMOOTH_RATE * delta)
	camera.fov = lerpf(camera.fov, target, blend)
