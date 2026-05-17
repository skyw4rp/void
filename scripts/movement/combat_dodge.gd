## Short burst dodge — player (Shift+direction / double-tap) and AI bursts.
class_name CombatDodge
extends RefCounted

@export var dodge_distance: float = 2.05
@export var dodge_duration: float = 0.15
@export var dodge_cooldown: float = 1.4
@export var double_tap_window: float = 0.22

var cooldown_remaining: float = 0.0
var active_remaining: float = 0.0
var active_direction: Vector3 = Vector3.ZERO

var _tap_times: Dictionary = {}


func reset() -> void:
	cooldown_remaining = 0.0
	active_remaining = 0.0
	active_direction = Vector3.ZERO
	_tap_times.clear()


func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if active_remaining > 0.0:
		active_remaining = maxf(0.0, active_remaining - delta)
		if active_remaining <= 0.0:
			active_direction = Vector3.ZERO


func is_active() -> bool:
	return active_remaining > 0.0


func get_cooldown_remaining() -> float:
	return cooldown_remaining


func try_player_dodge(
	input_dir: Vector2,
	body_basis: Basis,
	force: bool = false
) -> Dictionary:
	if cooldown_remaining > 0.0 or active_remaining > 0.0:
		return {"triggered": false}

	var flat: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)
	if flat.length_squared() < 0.01:
		return {"triggered": false}

	var world_dir: Vector3 = (body_basis * flat).normalized()
	world_dir.y = 0.0
	if world_dir.length_squared() < 0.01:
		return {"triggered": false}
	world_dir = world_dir.normalized()

	if not force:
		return {"triggered": false}

	return _start_dodge(world_dir)


func register_move_input(input_dir: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if input_dir.length_squared() < 0.01:
		return
	var key: String = _input_key(input_dir)
	var last: float = float(_tap_times.get(key, -999.0))
	if now - last <= double_tap_window:
		_tap_times["%s_ready" % key] = now
	_tap_times[key] = now


func consume_double_tap_if_ready(input_dir: Vector2) -> bool:
	var key: String = _input_key(input_dir)
	var ready_key: String = "%s_ready" % key
	if not _tap_times.has(ready_key):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_tap_times[ready_key]) > double_tap_window:
		_tap_times.erase(ready_key)
		return false
	_tap_times.erase(ready_key)
	return true


func try_ai_dodge(direction: Vector3, chance: float, rng: RandomNumberGenerator) -> Dictionary:
	if cooldown_remaining > 0.0 or active_remaining > 0.0:
		return {"triggered": false}
	if rng.randf() > chance:
		return {"triggered": false}
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.01:
		return {"triggered": false}
	return _start_dodge(flat.normalized())


func get_active_velocity_boost() -> Vector3:
	if not is_active() or dodge_duration <= 0.0:
		return Vector3.ZERO
	var speed: float = dodge_distance / dodge_duration
	return active_direction * speed


func _start_dodge(world_dir: Vector3) -> Dictionary:
	active_direction = world_dir
	active_remaining = dodge_duration
	cooldown_remaining = dodge_cooldown
	return {"triggered": true, "direction": world_dir}


func _check_double_tap(input_dir: Vector2) -> bool:
	return consume_double_tap_if_ready(input_dir)


func _input_key(input_dir: Vector2) -> String:
	if absf(input_dir.x) >= absf(input_dir.y):
		return "x_pos" if input_dir.x > 0.0 else "x_neg"
	return "z_pos" if input_dir.y > 0.0 else "z_neg"
