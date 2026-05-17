## Procedural humanoid motion — visual only, no root motion.
class_name ProceduralEnemyAnimator
extends Node3D

enum VisualState {
	IDLE,
	RUNNING,
	STRAFING,
	SHOOTING,
	AIRBORNE,
	RECOVERING,
	DEATH,
}

const STATE_NAMES: PackedStringArray = [
	"IDLE", "RUNNING", "STRAFING", "SHOOTING", "AIRBORNE", "RECOVERING", "DEATH",
]

const COMBAT_STATE_RECOVERING: int = 3
const GROUND_GROUPS: PackedStringArray = [
	"structural_geometry", "arena_floor", "arena_wall", "destructible_wall",
]

@export var debug_show_anim_state: bool = false
@export var breath_amplitude: float = 0.024
@export var breath_speed: float = 1.5
@export var shot_state_duration: float = 0.2
@export var move_speed_threshold: float = 0.4
@export var airborne_vertical_speed: float = 0.8
@export var airborne_clearance: float = 0.55
@export var ground_hit_max_distance: float = 1.15

var _visual_root: Node3D
var _body: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _weapon_mount: Node3D
var _weapon_manager: EnemyWeaponManager
var _ground_check: RayCast3D
var _fighter: RigidBody3D

var _rest: Dictionary = {}
var _breath_phase: float = 0.0
var _leg_phase: float = 0.0
var _hit_flinch: float = 0.0
var _shooting_timer: float = 0.0
var _shot_weapon_name: String = ""
var _death_blend: float = 0.0
var _death_active: bool = false
var _combat_state: int = 0
var _strafe_sign: float = 1.0

var _grounded: bool = true
var _ground_hit_distance: float = 99.0
var _ground_floor_y: float = 0.0
var _last_h_speed: float = 0.0

var _visual_state: VisualState = VisualState.IDLE
var _displayed_state: VisualState = VisualState.IDLE
var _debug_label: Label3D


func _ready() -> void:
	process_priority = 0
	_fighter = _find_fighter()
	_visual_root = get_parent() as Node3D
	if _visual_root == null:
		return
	_body = _visual_root.get_node_or_null("Torso") as Node3D
	if _body == null:
		_body = _visual_root.get_node_or_null("Body") as Node3D
	_head = _visual_root.get_node_or_null("Head") as Node3D
	_left_arm = _visual_root.get_node_or_null("LeftArm") as Node3D
	_right_arm = _visual_root.get_node_or_null("RightArm") as Node3D
	_left_leg = _visual_root.get_node_or_null("LeftLeg") as Node3D
	_right_leg = _visual_root.get_node_or_null("RightLeg") as Node3D
	_weapon_mount = _visual_root.get_node_or_null("WeaponMount") as Node3D
	_weapon_manager = _visual_root.get_node_or_null("WeaponMount/EnemyWeaponManager") as EnemyWeaponManager
	if _fighter:
		_ground_check = _fighter.get_node_or_null("GroundCheck") as RayCast3D
		_ground_floor_y = _fighter.global_position.y
	_cache_rest_transforms()
	_connect_weapon_signals()
	_breath_phase = randf() * TAU
	if debug_show_anim_state:
		_setup_debug_label()


func set_combat_state(state: int) -> void:
	_combat_state = state


func set_strafe_sign(sign: float) -> void:
	_strafe_sign = sign


func notify_hit() -> void:
	_hit_flinch = 1.0


func is_shooting() -> bool:
	return _shooting_timer > 0.0


func notify_shot_fired(weapon_name: String) -> void:
	_shot_weapon_name = weapon_name
	_shooting_timer = clampf(shot_state_duration, 0.15, 0.25)
	if weapon_name.to_lower().contains("bazooka"):
		_shooting_timer = 0.25
	elif weapon_name.to_lower().contains("shotgun"):
		_shooting_timer = 0.22


func begin_death() -> void:
	_death_active = true
	_death_blend = 0.0
	_set_visual_state(VisualState.DEATH)


func reset_pose() -> void:
	_death_active = false
	_death_blend = 0.0
	_hit_flinch = 0.0
	_shooting_timer = 0.0
	_combat_state = 0
	_visual_state = VisualState.IDLE
	_displayed_state = VisualState.IDLE
	_restore_all_rest()
	if _debug_label:
		_debug_label.text = "IDLE"


func _process(delta: float) -> void:
	if _rest.is_empty():
		return

	_breath_phase += delta * breath_speed
	_hit_flinch = move_toward(_hit_flinch, 0.0, delta * 10.0)
	_shooting_timer = maxf(_shooting_timer - delta, 0.0)
	if _death_active:
		_death_blend = move_toward(_death_blend, 1.0, delta * 4.5)

	_update_ground_state()
	_select_visual_state()

	var vel: Vector3 = _fighter.linear_velocity if _fighter else Vector3.ZERO
	_last_h_speed = Vector3(vel.x, 0.0, vel.z).length()
	if _grounded and _last_h_speed > move_speed_threshold:
		_leg_phase += delta * (8.0 + _last_h_speed * 0.45)

	_restore_all_rest()
	_apply_visual_state()

	if _debug_label:
		_debug_label.text = "%s\nG=%s v=%.1f" % [
			STATE_NAMES[_visual_state], _grounded, _last_h_speed,
		]


func _restore_all_rest() -> void:
	for node_name in _rest:
		var node: Node3D = _get_part_by_name(node_name)
		if node:
			node.transform = _rest[node_name]


func _apply_visual_state() -> void:
	var breath: float = sin(_breath_phase) * breath_amplitude
	var flinch_z: float = 0.12 * _hit_flinch

	match _visual_state:
		VisualState.IDLE:
			_set_part(_body, Vector3(0.0, breath, 0.0), Vector3.ZERO)
			_set_part(_head, Vector3(0.0, breath * 0.5, 0.0), Vector3.ZERO)
			_set_part(_left_arm, Vector3.ZERO, Vector3.ZERO)
			_set_part(_right_arm, Vector3.ZERO, Vector3.ZERO)
		VisualState.RUNNING:
			var swing: float = sin(_leg_phase) * 0.32
			_set_part(_body, Vector3(0.0, breath * 0.3, 0.12), Vector3(0.18, 0.0, 0.0))
			_set_part(_head, Vector3(0.0, breath * 0.2, 0.04), Vector3(0.1, 0.0, 0.0))
			_set_part(_left_arm, Vector3.ZERO, Vector3(-0.08, 0.0, 0.0))
			_set_part(_right_arm, Vector3.ZERO, Vector3(-0.1, 0.0, 0.0))
			_set_part(_left_leg, Vector3(0.0, 0.0, 0.03), Vector3(swing, 0.0, 0.0))
			_set_part(_right_leg, Vector3(0.0, 0.0, -0.03), Vector3(-swing, 0.0, 0.0))
		VisualState.STRAFING:
			var side: float = _strafe_sign
			var swing_s: float = sin(_leg_phase) * 0.22 * side
			_set_part(_body, Vector3(side * 0.08, breath * 0.25, 0.0), Vector3(0.0, 0.0, side * 0.2))
			_set_part(_head, Vector3(side * 0.03, 0.0, 0.0), Vector3(0.0, side * 0.12, 0.0))
			_set_part(_left_leg, Vector3(swing_s * 0.06, 0.0, 0.0), Vector3(0.0, 0.0, swing_s))
			_set_part(_right_leg, Vector3(-swing_s * 0.06, 0.0, 0.0), Vector3(0.0, 0.0, -swing_s))
		VisualState.SHOOTING:
			var recoil: Vector3 = _shot_recoil_euler()
			_set_part(_body, Vector3(0.0, 0.0, flinch_z * 0.4), recoil * 0.5)
			_set_part(_head, Vector3.ZERO, recoil * 0.2)
			_set_part(_left_arm, Vector3.ZERO, Vector3(recoil.x * 1.4, 0.0, recoil.z))
			_set_part(_right_arm, Vector3(0.0, 0.0, -0.04), Vector3(recoil.x * 1.8, 0.0, recoil.z * 1.2))
			_apply_mount_recoil()
		VisualState.AIRBORNE:
			_set_part(_body, Vector3(0.0, -0.04, 0.0), Vector3(-0.12, 0.0, 0.0))
			_set_part(_head, Vector3(0.0, 0.03, 0.0), Vector3(0.08, 0.0, 0.0))
			_set_part(_left_arm, Vector3.ZERO, Vector3(-0.14, 0.0, -0.05))
			_set_part(_right_arm, Vector3.ZERO, Vector3(-0.16, 0.0, -0.06))
			_set_part(_left_leg, Vector3(0.0, 0.1, 0.06), Vector3(0.48, 0.0, 0.0))
			_set_part(_right_leg, Vector3(0.0, 0.1, 0.06), Vector3(0.48, 0.0, 0.0))
		VisualState.RECOVERING:
			var wobble: float = sin(_breath_phase * 2.8) * 0.08
			_set_part(_body, Vector3(wobble, -0.1, -0.08), Vector3(0.32, wobble * 2.5, 0.0))
			_set_part(_head, Vector3(0.0, -0.05, 0.0), Vector3(0.22, 0.0, 0.0))
			_set_part(_left_arm, Vector3.ZERO, Vector3(0.22, 0.0, 0.12))
			_set_part(_right_arm, Vector3.ZERO, Vector3(0.26, 0.0, 0.16))
		VisualState.DEATH:
			var slump: float = _death_blend
			_set_part(_body, Vector3(0.0, -0.24 * slump, 0.12 * slump), Vector3(0.55 * slump, 0.0, 0.0))
			_set_part(_head, Vector3(0.0, -0.14 * slump, 0.08 * slump), Vector3(0.65 * slump, 0.0, 0.0))
			_set_part(_left_arm, Vector3.ZERO, Vector3(0.35 * slump, 0.0, 0.2 * slump))
			_set_part(_right_arm, Vector3.ZERO, Vector3(0.4 * slump, 0.0, 0.25 * slump))

func _select_visual_state() -> void:
	if _death_active:
		_set_visual_state(VisualState.DEATH)
		return
	if _shooting_timer > 0.0:
		_set_visual_state(VisualState.SHOOTING)
		return
	if _combat_state == COMBAT_STATE_RECOVERING:
		_set_visual_state(VisualState.RECOVERING)
		return
	if _is_airborne():
		_set_visual_state(VisualState.AIRBORNE)
		return

	var vel: Vector3 = _fighter.linear_velocity if _fighter else Vector3.ZERO
	var h_speed: float = Vector3(vel.x, 0.0, vel.z).length()
	if h_speed < move_speed_threshold:
		_set_visual_state(VisualState.IDLE)
		return

	if _is_strafing(vel, h_speed):
		_set_visual_state(VisualState.STRAFING)
	else:
		_set_visual_state(VisualState.RUNNING)


func _is_strafing(vel: Vector3, h_speed: float) -> bool:
	if _fighter == null or h_speed < move_speed_threshold:
		return false
	var flat_vel: Vector3 = Vector3(vel.x, 0.0, vel.z)
	if flat_vel.length_squared() < 0.01:
		return false
	var basis: Basis = _fighter.global_transform.basis
	var forward: Vector3 = -basis.z
	var right: Vector3 = basis.x
	forward.y = 0.0
	right.y = 0.0
	if forward.length_squared() < 0.01 or right.length_squared() < 0.01:
		return false
	forward = forward.normalized()
	right = right.normalized()
	var fwd_amount: float = absf(flat_vel.normalized().dot(forward))
	var lat_amount: float = absf(flat_vel.normalized().dot(right))
	return lat_amount > fwd_amount * 1.08


func _is_airborne() -> bool:
	if _fighter == null:
		return false
	if _grounded:
		return false
	var vy: float = absf(_fighter.linear_velocity.y)
	var above_floor: bool = _fighter.global_position.y > _ground_floor_y + airborne_clearance
	if vy > airborne_vertical_speed:
		return true
	if above_floor and vy > 0.15:
		return true
	return false


func _update_ground_state() -> void:
	_grounded = false
	_ground_hit_distance = 99.0
	if _fighter == null:
		_grounded = true
		return

	if _ground_check:
		_ground_check.force_raycast_update()
		if _ground_check.is_colliding():
			var collider: Object = _ground_check.get_collider()
			if _is_valid_ground_collider(collider):
				_grounded = true
				_ground_hit_distance = _ground_check.get_collision_point().distance_to(
					_ground_check.global_position
				)
				_ground_floor_y = _ground_check.get_collision_point().y
				return

	_grounded = _physics_ray_grounded()


func _physics_ray_grounded() -> bool:
	var space: PhysicsDirectSpaceState3D = _fighter.get_world_3d().direct_space_state
	var from: Vector3 = _fighter.global_position + Vector3(0.0, 0.2, 0.0)
	var to: Vector3 = from + Vector3.DOWN * 1.65
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [_fighter.get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit.get("collider")
	if not _is_valid_ground_collider(collider):
		return false
	var dist: float = hit.get("distance", 99.0)
	_ground_hit_distance = dist
	_ground_floor_y = (hit.get("position") as Vector3).y
	return dist <= ground_hit_max_distance


func _is_valid_ground_collider(collider: Object) -> bool:
	if collider == null:
		return false
	if collider is Node:
		var node: Node = collider as Node
		for group_name in GROUND_GROUPS:
			if node.is_in_group(group_name):
				return true
		if node is StaticBody3D:
			return true
	return false


func _set_visual_state(state: VisualState) -> void:
	if _visual_state == state:
		return
	_visual_state = state
	if _displayed_state != state:
		_displayed_state = state
		print("Enemy anim state: %s" % STATE_NAMES[state])
		if debug_show_anim_state:
			print(
				"Enemy grounded=%s speed=%.2f hit_dist=%.2f vy=%.2f"
				% [
					_grounded,
					_last_h_speed,
					_ground_hit_distance,
					_fighter.linear_velocity.y if _fighter else 0.0,
				]
			)


func _set_part(node: Node3D, pos_off: Vector3, rot_euler: Vector3) -> void:
	if node == null or not _rest.has(node.name):
		return
	var rest: Transform3D = _rest[node.name]
	node.transform = Transform3D(
		rest.basis * Basis.from_euler(rot_euler),
		rest.origin + pos_off
	)


func _apply_mount_recoil() -> void:
	if _weapon_mount == null or not _rest.has(_weapon_mount.name):
		return
	var kick: Vector3 = _shot_recoil_offset()
	var rest: Transform3D = _rest[_weapon_mount.name]
	_weapon_mount.transform = Transform3D(rest.basis, rest.origin + kick)


func _shot_recoil_euler() -> Vector3:
	var t: float = 1.0
	if shot_state_duration > 0.0:
		t = clampf(_shooting_timer / shot_state_duration, 0.0, 1.0)
	var n: String = _shot_weapon_name.to_lower()
	if n.contains("railgun"):
		return Vector3(-0.18 * t, 0.0, -0.08 * t)
	if n.contains("shotgun"):
		return Vector3(-0.28 * t, 0.0, -0.12 * t)
	if n.contains("bazooka"):
		return Vector3(-0.38 * t, 0.0, -0.16 * t)
	return Vector3(-0.2 * t, 0.0, -0.1 * t)


func _shot_recoil_offset() -> Vector3:
	var t: float = clampf(_shooting_timer / maxf(shot_state_duration, 0.01), 0.0, 1.0)
	var n: String = _shot_weapon_name.to_lower()
	if n.contains("railgun"):
		return Vector3(0.0, 0.0, 0.14 * t)
	if n.contains("shotgun"):
		return Vector3(0.0, -0.04 * t, 0.22 * t)
	if n.contains("bazooka"):
		return Vector3(0.0, -0.06 * t, 0.3 * t)
	return Vector3(0.0, 0.0, 0.16 * t)


func _connect_weapon_signals() -> void:
	if _weapon_manager == null:
		return
	if _weapon_manager.has_signal("shot_fired"):
		if not _weapon_manager.shot_fired.is_connected(_on_enemy_shot_fired):
			_weapon_manager.shot_fired.connect(_on_enemy_shot_fired)


func _on_enemy_shot_fired(weapon_name: String) -> void:
	notify_shot_fired(weapon_name)


func _cache_rest_transforms() -> void:
	for node in [_body, _head, _left_arm, _right_arm, _left_leg, _right_leg, _weapon_mount]:
		if node:
			_rest[node.name] = node.transform


func _get_part_by_name(node_name: String) -> Node3D:
	match node_name:
		"Body", "Torso":
			return _body
		"WeaponMount":
			return _weapon_mount
		"Head":
			return _head
		"LeftArm":
			return _left_arm
		"RightArm":
			return _right_arm
		"LeftLeg":
			return _left_leg
		"RightLeg":
			return _right_leg
	return null


func _setup_debug_label() -> void:
	_debug_label = Label3D.new()
	_debug_label.text = "IDLE"
	_debug_label.font_size = 20
	_debug_label.pixel_size = 0.01
	_debug_label.position = Vector3(0.0, 1.35, 0.0)
	_debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_debug_label)


func _find_fighter() -> RigidBody3D:
	var node: Node = get_parent()
	while node:
		if node is RigidBody3D:
			return node as RigidBody3D
		node = node.get_parent()
	return null
