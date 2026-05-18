## Enemy horizontal locomotion — mirrors GladiatorLocomotion rules (player parity).
## See docs/PROTOTYPE.md "Movement parity" table.
class_name EnemyGladiatorLocomotion
extends RefCounted


class StepResult:
	var horizontal_velocity: Vector3 = Vector3.ZERO
	var horizontal_speed: float = 0.0
	var wish_direction: Vector3 = Vector3.ZERO
	var high_speed: bool = false


## Defaults copied from player.gd @export_group Gladiator Locomotion (do not change player).
static func player_parity_config() -> Dictionary:
	return {
		"ground_acceleration": 46.0,
		"air_acceleration": 17.0,
		"friction": 5.5,
		"air_control": 0.48,
		"max_ground_speed": 7.6,
		"max_air_speed": 9.0,
		"strafe_boost": 1.08,
	}


static func integrate_horizontal(
	velocity_horizontal: Vector3,
	delta: float,
	wish_dir: Vector3,
	on_floor: bool,
	config: Dictionary,
	dodge_boost: Vector3,
	speed_multiplier: float = 1.0
) -> StepResult:
	var result := StepResult.new()
	var wish: Vector3 = wish_dir
	wish.y = 0.0
	if wish.length_squared() > 0.001:
		wish = wish.normalized()
	result.wish_direction = wish

	var vel_h: Vector3 = velocity_horizontal
	var mult: float = maxf(speed_multiplier, 0.25)
	var max_speed: float = (
		float(config.get("max_ground_speed", 7.6)) * mult
		if on_floor
		else float(config.get("max_air_speed", 9.0)) * mult
	)
	var accel: float = (
		float(config.get("ground_acceleration", 46.0)) * mult
		if on_floor
		else float(config.get("air_acceleration", 17.0)) * mult
	)
	var friction: float = float(config.get("friction", 5.5))
	var air_control: float = float(config.get("air_control", 0.48))
	var strafe_boost: float = float(config.get("strafe_boost", 1.08))

	if on_floor and wish.is_zero_approx():
		vel_h = _apply_friction(vel_h, friction, delta)
	elif not wish.is_zero_approx():
		if on_floor:
			vel_h = _accelerate(vel_h, wish, max_speed, accel, delta)
			vel_h = _apply_strafe_boost(vel_h, wish, strafe_boost)
		else:
			var control: float = clampf(air_control, 0.05, 1.0)
			vel_h = _accelerate(vel_h, wish, max_speed, accel * control, delta)

	if dodge_boost.length_squared() > 0.001:
		vel_h += dodge_boost * delta

	if vel_h.length() > max_speed:
		vel_h = vel_h.normalized() * max_speed

	result.horizontal_velocity = vel_h
	result.horizontal_speed = vel_h.length()
	result.high_speed = result.horizontal_speed >= max_speed * 0.82
	return result


static func apply_to_body(
	body: RigidBody3D,
	wish_dir: Vector3,
	delta: float,
	on_floor: bool,
	config: Dictionary,
	dodge_boost: Vector3,
	speed_multiplier: float = 1.0
) -> StepResult:
	var vel: Vector3 = body.linear_velocity
	var vel_h: Vector3 = Vector3(vel.x, 0.0, vel.z)
	var step: StepResult = integrate_horizontal(
		vel_h, delta, wish_dir, on_floor, config, dodge_boost, speed_multiplier
	)
	body.linear_velocity = Vector3(step.horizontal_velocity.x, vel.y, step.horizontal_velocity.z)
	return step


static func _accelerate(
	velocity: Vector3, wish_dir: Vector3, wish_speed: float, accel: float, delta: float
) -> Vector3:
	var current_speed: float = velocity.dot(wish_dir)
	var add_speed: float = wish_speed - current_speed
	if add_speed <= 0.0:
		return velocity
	var accel_speed: float = minf(accel * delta * wish_speed, add_speed)
	return velocity + wish_dir * accel_speed


static func _apply_friction(velocity: Vector3, friction: float, delta: float) -> Vector3:
	var speed: float = velocity.length()
	if speed < 0.05:
		return Vector3.ZERO
	var drop: float = speed * friction * delta
	var new_speed: float = maxf(speed - drop, 0.0)
	return velocity * (new_speed / speed)


static func _apply_strafe_boost(velocity: Vector3, wish_dir: Vector3, boost: float) -> Vector3:
	if velocity.length_squared() < 0.25 or wish_dir.length_squared() < 0.01:
		return velocity
	var vel_n: Vector3 = velocity.normalized()
	var perp: float = 1.0 - absf(vel_n.dot(wish_dir))
	if perp < 0.35:
		return velocity
	return velocity + wish_dir * (velocity.length() * (boost - 1.0) * perp * 0.35)
