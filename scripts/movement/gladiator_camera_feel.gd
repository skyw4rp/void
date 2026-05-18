## Visual camera feedback — roll and positional kick (FOV handled by GladiatorFov).
class_name GladiatorCameraFeel
extends RefCounted

var _landing_shake: float = 0.0
var _dodge_kick: float = 0.0
var _feel_roll: float = 0.0
var _feel_offset: Vector3 = Vector3.ZERO


func reset(_camera: Camera3D, feel_pivot: Node3D) -> void:
	_landing_shake = 0.0
	_dodge_kick = 0.0
	_feel_roll = 0.0
	_feel_offset = Vector3.ZERO
	if feel_pivot:
		feel_pivot.rotation = Vector3.ZERO
		feel_pivot.position = Vector3.ZERO
	if _camera:
		_camera.rotation = Vector3.ZERO


func update(
	_camera: Camera3D,
	feel_pivot: Node3D,
	delta: float,
	loco: GladiatorLocomotion.StepResult,
	input_dir: Vector2,
	config: Dictionary,
	dodge_active: bool,
	fov: GladiatorFov
) -> void:
	if feel_pivot == null:
		return

	var tilt_strength: float = float(config.get("movement_tilt_strength", 0.035))
	var fov_boost: float = float(config.get("speed_fov_boost", 4.0))
	var ground_fov_extra: float = float(config.get("speed_fov_ground_extra", 0.4))
	var max_speed: float = float(config.get("max_ground_speed", 9.5))

	var target_roll: float = -input_dir.x * tilt_strength
	if dodge_active:
		target_roll *= 1.35
	_feel_roll = lerpf(_feel_roll, target_roll, 1.0 - exp(-14.0 * delta))
	feel_pivot.rotation = Vector3(0.0, 0.0, _feel_roll)

	if fov:
		fov.set_movement_from_speed(
			loco.horizontal_speed,
			max_speed,
			fov_boost,
			ground_fov_extra,
			loco.was_airborne
		)

	if loco.just_landed:
		var impact: float = clampf(loco.land_impact / 12.0, 0.15, 1.0)
		_landing_shake = impact * float(config.get("landing_shake_strength", 0.12))
		if fov:
			fov.add_impact(impact * 0.35)

	var target_offset := Vector3.ZERO
	if _landing_shake > 0.0:
		_landing_shake = maxf(0.0, _landing_shake - delta * 2.8)
		var shake: float = _landing_shake * 0.08
		target_offset.y = randf_range(-shake, shake) * 0.04
		target_offset.z = randf_range(-shake * 0.5, shake * 0.5) * 0.03

	if loco.was_airborne and not loco.just_landed:
		var sway: float = sin(Time.get_ticks_msec() * 0.006) * 0.008
		target_offset.x += sway * 0.35

	if dodge_active:
		_dodge_kick = lerpf(_dodge_kick, 0.035, 1.0 - exp(-10.0 * delta))
	else:
		_dodge_kick = lerpf(_dodge_kick, 0.0, 1.0 - exp(-12.0 * delta))
	target_offset.z -= _dodge_kick

	_feel_offset = _feel_offset.lerp(target_offset, 1.0 - exp(-12.0 * delta))
	feel_pivot.position = _feel_offset


func apply_impulse_shake(feel_pivot: Node3D, intensity: float) -> void:
	if feel_pivot == null:
		return
	_landing_shake = maxf(_landing_shake, clampf(intensity, 0.0, 1.0) * 0.35)
