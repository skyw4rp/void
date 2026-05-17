## Quake-style arena locomotion for CharacterBody3D — momentum, strafe, air control.
class_name GladiatorLocomotion
extends RefCounted


class StepResult:
	var horizontal_speed: float = 0.0
	var wish_direction: Vector3 = Vector3.ZERO
	var was_airborne: bool = false
	var just_landed: bool = false
	var land_impact: float = 0.0
	var high_speed: bool = false
	var air_accel_event: bool = false


static func step(
	body: CharacterBody3D,
	delta: float,
	input_dir: Vector2,
	wish_basis: Basis,
	gravity: float,
	config: Dictionary,
	dodge_boost: Vector3,
	was_on_floor: bool
) -> StepResult:
	var result := StepResult.new()
	var on_floor: bool = body.is_on_floor()
	result.was_airborne = not on_floor

	if not on_floor:
		body.velocity.y -= gravity * delta

	var wish: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)
	if wish_basis != Basis.IDENTITY:
		wish = wish_basis * wish
	wish.y = 0.0
	if wish.length_squared() > 0.001:
		wish = wish.normalized()
	result.wish_direction = wish

	var vel_h: Vector3 = Vector3(body.velocity.x, 0.0, body.velocity.z)
	var speed: float = vel_h.length()
	result.horizontal_speed = speed

	var max_speed: float = (
		float(config.get("max_ground_speed", 9.5))
		if on_floor
		else float(config.get("max_air_speed", 10.5))
	)
	var accel: float = (
		float(config.get("ground_acceleration", 52.0))
		if on_floor
		else float(config.get("air_acceleration", 18.0))
	)
	var friction: float = float(config.get("friction", 6.0))
	var air_control: float = float(config.get("air_control", 0.42))
	var strafe_boost: float = float(config.get("strafe_boost", 1.12))

	if on_floor and wish.is_zero_approx():
		vel_h = _apply_friction(vel_h, friction, delta)
	elif not wish.is_zero_approx():
		var wish_speed: float = max_speed
		if on_floor:
			vel_h = _accelerate(vel_h, wish, wish_speed, accel, delta)
			vel_h = _apply_strafe_boost(vel_h, wish, strafe_boost)
		else:
			var control: float = clampf(air_control, 0.05, 1.0)
			vel_h = _accelerate(vel_h, wish, wish_speed, accel * control, delta)
			if wish.length_squared() > 0.01:
				result.air_accel_event = true

	if dodge_boost.length_squared() > 0.001:
		vel_h += dodge_boost * delta

	if vel_h.length() > max_speed:
		vel_h = vel_h.normalized() * max_speed

	body.velocity.x = vel_h.x
	body.velocity.z = vel_h.z

	result.horizontal_speed = vel_h.length()
	result.high_speed = result.horizontal_speed >= max_speed * 0.82

	if on_floor and not was_on_floor:
		result.just_landed = true
		result.land_impact = absf(body.velocity.y)
		var damp: float = float(config.get("landing_damp", 0.55))
		body.velocity.y *= damp

	return result


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
