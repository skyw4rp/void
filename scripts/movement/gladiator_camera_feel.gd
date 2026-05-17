## Subtle arena FPS camera feedback — tilt, FOV, landing, air sway.
class_name GladiatorCameraFeel
extends RefCounted

var _base_fov: float = 90.0
var _landing_shake: float = 0.0
var _dodge_sway: float = 0.0


func reset(camera: Camera3D) -> void:
	_base_fov = camera.fov
	_landing_shake = 0.0
	_dodge_sway = 0.0
	camera.rotation.z = 0.0


func update(
	camera: Camera3D,
	delta: float,
	loco: GladiatorLocomotion.StepResult,
	input_dir: Vector2,
	config: Dictionary,
	dodge_active: bool
) -> void:
	var tilt_strength: float = float(config.get("movement_tilt_strength", 0.035))
	var fov_boost: float = float(config.get("speed_fov_boost", 8.0))
	var max_speed: float = float(config.get("max_ground_speed", 9.5))

	var target_roll: float = -input_dir.x * tilt_strength
	if dodge_active:
		target_roll *= 1.35
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, 1.0 - exp(-14.0 * delta))

	var speed_t: float = clampf(loco.horizontal_speed / maxf(max_speed, 0.01), 0.0, 1.25)
	var target_fov: float = _base_fov + fov_boost * speed_t
	if not loco.was_airborne:
		target_fov += 1.5 * speed_t
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-8.0 * delta))

	if loco.just_landed:
		var impact: float = clampf(loco.land_impact / 12.0, 0.15, 1.0)
		_landing_shake = impact * float(config.get("landing_shake_strength", 0.12))

	if _landing_shake > 0.0:
		_landing_shake = maxf(0.0, _landing_shake - delta * 2.8)
		var shake: float = _landing_shake * 0.08
		camera.rotation.x += randf_range(-shake, shake)

	if loco.was_airborne and not loco.just_landed:
		var sway: float = sin(Time.get_ticks_msec() * 0.006) * 0.008
		camera.rotation.z += sway

	if dodge_active:
		_dodge_sway = lerpf(_dodge_sway, 0.02, 1.0 - exp(-10.0 * delta))
	else:
		_dodge_sway = lerpf(_dodge_sway, 0.0, 1.0 - exp(-12.0 * delta))
	camera.rotation.x -= _dodge_sway
