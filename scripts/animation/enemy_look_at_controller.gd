## Visual aim — consumes world positions from ArenaOpponent only (no target lookup).
class_name EnemyLookAtController
extends Node3D

const COMBAT_RECOVERING: int = 3
const COMBAT_EVADING: int = 2

@export var body_turn_speed: float = 9.0
@export var aim_weight: float = 0.78
@export var movement_weight: float = 0.22
@export var head_turn_speed: float = 16.0
@export var torso_turn_speed: float = 11.0
@export var weapon_turn_speed: float = 18.0
@export var weapon_turn_speed_shooting: float = 32.0
@export var aim_lock_turn_mult: float = 3.5
@export var max_head_yaw_deg: float = 72.0
@export var max_head_pitch_deg: float = 38.0
@export var max_torso_yaw_deg: float = 32.0
@export var max_torso_pitch_deg: float = 22.0
@export var max_arm_pitch_deg: float = 42.0
@export var debug_show_aim_ray: bool = false
@export var debug_show_enemy_forward: bool = false
@export var muzzle_forward_offset: float = 0.45

var _fighter: RigidBody3D
var _visual_root: Node3D
var _body: Node3D
var _head: Node3D
var _eye_left: Node3D
var _eye_right: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _weapon_mount: Node3D
var _weapon_manager: EnemyWeaponManager

var _weapon_aim_world: Vector3 = Vector3.ZERO
var _head_aim_world: Vector3 = Vector3.ZERO
var _locked_shot_direction: Vector3 = Vector3.ZERO
var _move_direction: Vector3 = Vector3.ZERO
var _combat_state: int = 0
var _shooting: bool = false
var _aim_direction: Vector3 = Vector3.FORWARD
var _body_yaw: float = 0.0
var _head_euler: Vector3 = Vector3.ZERO
var _torso_euler: Vector3 = Vector3.ZERO
var _arm_pitch: float = 0.0
var _hit_flinch: float = 0.0
var _aim_lock_timer: float = 0.0
var _warned_no_eyes: bool = false
var _warned_round_no_aim: bool = false
var _received_aim_this_round: bool = false

var _debug_muzzle_mesh: MeshInstance3D
var _debug_head_mesh: MeshInstance3D
var _debug_forward_mesh: MeshInstance3D


func _ready() -> void:
	process_priority = 10
	_fighter = _find_fighter()
	_visual_root = get_parent() as Node3D
	if _visual_root == null:
		return
	_body = _visual_root.get_node_or_null("Torso") as Node3D
	if _body == null:
		_body = _visual_root.get_node_or_null("Body") as Node3D
	_head = _visual_root.get_node_or_null("Head") as Node3D
	_eye_left = _find_eye("EyeLeft", "LeftEye")
	_eye_right = _find_eye("EyeRight", "RightEye")
	_left_arm = _visual_root.get_node_or_null("LeftArm") as Node3D
	_right_arm = _visual_root.get_node_or_null("RightArm") as Node3D
	if _visual_root:
		_weapon_mount = _visual_root.get_node_or_null("WeaponMount") as Node3D
		_weapon_manager = _visual_root.get_node_or_null("WeaponMount/EnemyWeaponManager") as EnemyWeaponManager
	_warn_missing_eyes()
	_connect_weapon_signals()
	if debug_show_aim_ray:
		_debug_muzzle_mesh = _make_debug_line(Color(1.0, 0.4, 0.12))
		_debug_head_mesh = _make_debug_line(Color(0.35, 0.9, 1.0))
	if debug_show_enemy_forward:
		_debug_forward_mesh = _make_debug_line(Color(0.35, 0.85, 1.0))


func begin_round() -> void:
	_warned_round_no_aim = false
	_received_aim_this_round = false


func warn_no_target_this_round_once() -> void:
	if _received_aim_this_round or _warned_round_no_aim:
		return
	_warned_round_no_aim = true
	print("Enemy visual aim: no target received this round")


func feed(
	weapon_aim_world: Vector3,
	head_aim_world: Vector3,
	move_direction: Vector3,
	combat_state: int,
	shooting: bool
) -> void:
	if weapon_aim_world != Vector3.ZERO:
		_weapon_aim_world = weapon_aim_world
		_received_aim_this_round = true
	if head_aim_world != Vector3.ZERO:
		_head_aim_world = head_aim_world
		_received_aim_this_round = true
	_move_direction = move_direction
	_combat_state = combat_state
	_shooting = shooting


func apply_aim_positions(weapon_aim_world: Vector3, head_aim_world: Vector3, snap_yaw: bool = false) -> void:
	if weapon_aim_world != Vector3.ZERO:
		_weapon_aim_world = weapon_aim_world
		_received_aim_this_round = true
	if head_aim_world != Vector3.ZERO:
		_head_aim_world = head_aim_world
		_received_aim_this_round = true
	if snap_yaw and _weapon_aim_world != Vector3.ZERO and _fighter != null:
		var flat: Vector3 = _flat_direction_to_target(_weapon_aim_world)
		if flat.length_squared() > 0.0001:
			var local_facing: Vector3 = _fighter.global_transform.basis.inverse() * flat
			_body_yaw = atan2(local_facing.x, -local_facing.z)


func trigger_aim_lock(duration: float = 0.25) -> void:
	_aim_lock_timer = maxf(_aim_lock_timer, duration)
	var origin: Vector3 = get_muzzle_origin()
	if _weapon_aim_world != Vector3.ZERO and origin != Vector3.ZERO:
		var dir: Vector3 = _weapon_aim_world - origin
		if dir.length_squared() > 0.0001:
			_locked_shot_direction = dir.normalized()


func notify_hit_flinch() -> void:
	_hit_flinch = 1.0


func is_shooting_active() -> bool:
	return _shooting or _aim_lock_timer > 0.0


func get_aim_target() -> Vector3:
	return _weapon_aim_world


func get_chest_aim_point() -> Vector3:
	return _weapon_aim_world


func get_head_aim_point() -> Vector3:
	return _head_aim_world


func get_muzzle_origin() -> Vector3:
	if _weapon_mount and _weapon_mount.has_method("get_muzzle_global_position"):
		return _weapon_mount.get_muzzle_global_position()
	if _weapon_manager:
		return _weapon_manager.get_muzzle_global_position()
	return global_position


func get_aim_direction() -> Vector3:
	if _is_aim_locked() and _locked_shot_direction.length_squared() > 0.0001:
		return _locked_shot_direction
	var origin: Vector3 = get_muzzle_origin()
	if _weapon_aim_world == Vector3.ZERO:
		return _aim_direction
	var dir: Vector3 = _weapon_aim_world - origin
	if dir.length_squared() < 0.0001:
		return _aim_direction
	_aim_direction = dir.normalized()
	return _aim_direction


func reset_aim() -> void:
	_body_yaw = 0.0
	_head_euler = Vector3.ZERO
	_torso_euler = Vector3.ZERO
	_arm_pitch = 0.0
	_hit_flinch = 0.0
	_aim_lock_timer = 0.0
	_weapon_aim_world = Vector3.ZERO
	_head_aim_world = Vector3.ZERO
	_locked_shot_direction = Vector3.ZERO
	_aim_direction = Vector3.FORWARD
	_received_aim_this_round = false
	if _visual_root:
		_visual_root.rotation = Vector3.ZERO


func align_weapon_for_shot(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	_locked_shot_direction = direction.normalized()
	if _weapon_mount and _weapon_mount.has_method("align_to_target"):
		var tip: Vector3 = _weapon_mount.global_position + _locked_shot_direction * 4.0
		_weapon_mount.align_to_target(tip, true, true)


func get_aim_basis(direction: Vector3) -> Basis:
	var dir: Vector3 = direction.normalized()
	if dir.length_squared() < 0.0001:
		return Basis.IDENTITY
	return Basis.looking_at(dir, Vector3.UP)


func _process(delta: float) -> void:
	if _fighter == null or _visual_root == null:
		return

	_aim_lock_timer = maxf(_aim_lock_timer - delta, 0.0)
	_hit_flinch = move_toward(_hit_flinch, 0.0, delta * 12.0)

	if _weapon_aim_world == Vector3.ZERO and _head_aim_world == Vector3.ZERO:
		return

	_stabilize_visual_root()
	_update_body_yaw(delta)
	_update_weapon_mount(delta)
	_apply_torso(delta)
	_apply_head(delta)
	_apply_hit_flinch_layers()
	_apply_arms(delta)
	_update_debug_lines()


func _is_aim_locked() -> bool:
	return _aim_lock_timer > 0.0 or (_shooting and _locked_shot_direction.length_squared() > 0.0001)


func _stabilize_visual_root() -> void:
	_visual_root.rotation = Vector3(0.0, _body_yaw, 0.0)


func _update_body_yaw(delta: float) -> void:
	var aim_flat: Vector3 = _flat_direction_to_target(_weapon_aim_world)
	if aim_flat.length_squared() < 0.0001:
		return

	var move_flat: Vector3 = Vector3(_move_direction.x, 0.0, _move_direction.z)
	var w_aim: float = aim_weight
	var w_move: float = movement_weight
	if _combat_state == COMBAT_EVADING:
		w_aim = 0.88
		w_move = 0.12
	elif _combat_state == COMBAT_RECOVERING:
		w_aim = 0.92
		w_move = 0.08
	if _is_aim_locked():
		w_aim = 1.0
		w_move = 0.0

	var facing: Vector3 = aim_flat
	if move_flat.length_squared() > 0.16 and not _is_aim_locked():
		facing = (aim_flat * w_aim + move_flat.normalized() * w_move).normalized()

	var fighter_basis_inv: Basis = _fighter.global_transform.basis.inverse()
	var local_facing: Vector3 = fighter_basis_inv * facing
	var desired_yaw: float = atan2(local_facing.x, -local_facing.z)

	var head_hint: Vector2 = _world_angles_to_visual_local(_head_aim_world, _head)
	var head_limit: float = deg_to_rad(max_head_yaw_deg) * 0.8
	if absf(head_hint.x) > head_limit:
		desired_yaw += clampf((head_hint.x - signf(head_hint.x) * head_limit) * 0.65, -0.55, 0.55)

	var turn_speed: float = body_turn_speed
	if _is_aim_locked():
		turn_speed *= aim_lock_turn_mult
	_body_yaw = lerp_angle(_body_yaw, desired_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func _update_weapon_mount(delta: float) -> void:
	if _weapon_mount == null or not _weapon_mount.has_method("align_to_target"):
		return
	if _weapon_aim_world == Vector3.ZERO:
		return
	var aim_point: Vector3 = _weapon_aim_world
	if _combat_state == COMBAT_RECOVERING and not _is_aim_locked():
		aim_point += Vector3(0.0, -0.15, 0.0)
	_weapon_mount.align_to_target(aim_point, false, _is_aim_locked(), delta)


func _apply_torso(delta: float) -> void:
	if _body == null:
		return
	var angles: Vector2 = _world_angles_to_visual_local(_weapon_aim_world, _body)
	var max_yaw: float = deg_to_rad(max_torso_yaw_deg)
	var max_pitch: float = deg_to_rad(max_torso_pitch_deg)
	var target: Vector3 = Vector3(
		clampf(angles.y, -max_pitch, max_pitch),
		clampf(angles.x, -max_yaw, max_yaw),
		0.0
	)
	if _combat_state == COMBAT_RECOVERING and not _is_aim_locked():
		target.x += 0.14
		target.y -= 0.06
	var speed: float = torso_turn_speed * (aim_lock_turn_mult if _is_aim_locked() else 1.0)
	_torso_euler = _torso_euler.lerp(target, clampf(speed * delta, 0.0, 1.0))
	var base: Transform3D = _body.transform
	_body.transform = Transform3D(base.basis * Basis.from_euler(_torso_euler), base.origin)


func _apply_head(delta: float) -> void:
	if _head == null:
		return
	var angles: Vector2 = _world_angles_to_visual_local(_head_aim_world, _head)
	var max_yaw: float = deg_to_rad(max_head_yaw_deg)
	var max_pitch: float = deg_to_rad(max_head_pitch_deg)
	var target: Vector3 = Vector3(
		clampf(angles.y, -max_pitch, max_pitch),
		clampf(angles.x, -max_yaw, max_yaw),
		0.0
	)
	var speed: float = head_turn_speed * (aim_lock_turn_mult if _is_aim_locked() else 1.0)
	var blend: float = 1.0 if _is_aim_locked() else clampf(speed * delta, 0.0, 1.0)
	_head_euler = _head_euler.lerp(target, blend)
	var base: Transform3D = _head.transform
	_head.transform = Transform3D(base.basis * Basis.from_euler(_head_euler), base.origin)


func _apply_hit_flinch_layers() -> void:
	if _hit_flinch < 0.02:
		return
	var t: float = _hit_flinch
	if _body:
		var base_b: Transform3D = _body.transform
		_body.transform = Transform3D(
			base_b.basis * Basis.from_euler(Vector3(-0.14 * t, 0.0, 0.0)),
			base_b.origin + Vector3(0.0, 0.0, -0.05 * t)
		)
	if _head:
		var base_h: Transform3D = _head.transform
		_head.transform = Transform3D(
			base_h.basis * Basis.from_euler(Vector3(-0.18 * t, 0.0, 0.0)),
			base_h.origin + Vector3(0.0, 0.0, -0.03 * t)
		)


func _apply_arms(_delta: float) -> void:
	if _weapon_mount == null:
		return
	var weapon_forward: Vector3 = _weapon_mount.global_transform.basis * Vector3(0.0, 0.0, -1.0)
	if _weapon_mount.has_method("get_weapon_forward"):
		weapon_forward = _weapon_mount.get_weapon_forward()
	var local_fwd: Vector3 = _visual_root.global_transform.basis.inverse() * weapon_forward
	if local_fwd.length_squared() < 0.0001:
		return
	local_fwd = local_fwd.normalized()
	var pitch: float = clampf(
		-asin(clampf(local_fwd.y, -1.0, 1.0)),
		-deg_to_rad(max_arm_pitch_deg),
		deg_to_rad(max_arm_pitch_deg)
	)
	_arm_pitch = lerp(_arm_pitch, pitch, 0.4)
	_apply_arm(_left_arm, _arm_pitch * 0.85, -0.08)
	_apply_arm(_right_arm, _arm_pitch, 0.05)


func _apply_arm(node: Node3D, pitch: float, roll: float) -> void:
	if node == null:
		return
	var base: Transform3D = node.transform
	node.transform = Transform3D(
		base.basis * Basis.from_euler(Vector3(pitch, 0.0, roll)),
		base.origin
	)


func _world_angles_to_visual_local(target_world: Vector3, from_node: Node3D) -> Vector2:
	if from_node == null or target_world == Vector3.ZERO:
		return Vector2.ZERO
	var local: Vector3 = from_node.global_transform.basis.inverse() * (target_world - from_node.global_position)
	if local.length_squared() < 0.0001:
		return Vector2.ZERO
	local = local.normalized()
	return Vector2(atan2(local.x, -local.z), -asin(clampf(local.y, -1.0, 1.0)))


func _flat_direction_to_target(target_world: Vector3) -> Vector3:
	var from: Vector3 = _fighter.global_position
	var flat: Vector3 = Vector3(target_world.x - from.x, 0.0, target_world.z - from.z)
	if flat.length_squared() < 0.0001:
		return Vector3.ZERO
	return flat.normalized()


func _connect_weapon_signals() -> void:
	if _weapon_manager == null:
		return
	if _weapon_manager.has_signal("shot_fired"):
		if not _weapon_manager.shot_fired.is_connected(_on_weapon_shot_fired):
			_weapon_manager.shot_fired.connect(_on_weapon_shot_fired)


func _on_weapon_shot_fired(_weapon_name: String) -> void:
	trigger_aim_lock(0.25)


func _find_eye(primary: String, fallback: String) -> Node3D:
	if _head == null:
		return null
	var node: Node3D = _head.get_node_or_null(primary) as Node3D
	if node == null:
		node = _head.get_node_or_null(fallback) as Node3D
	return node


func _warn_missing_eyes() -> void:
	if _eye_left != null and _eye_right != null:
		return
	if not _warned_no_eyes:
		_warned_no_eyes = true
		print("Enemy eyes not found")


func _make_debug_line(color: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mesh_node.material_override = mat
	if _fighter:
		_fighter.add_child(mesh_node)
	return mesh_node


func _get_eye_origin() -> Vector3:
	if _head == null:
		return global_position
	return _head.global_position + Vector3(0.0, 0.06, -0.12)


func _update_debug_lines() -> void:
	if debug_show_aim_ray:
		if _debug_head_mesh and _head_aim_world != Vector3.ZERO:
			_draw_line(_debug_head_mesh, _get_eye_origin(), _head_aim_world)
		if _debug_muzzle_mesh:
			var muzzle: Vector3 = get_muzzle_origin()
			var fwd: Vector3 = get_aim_direction()
			if _weapon_mount and _weapon_mount.has_method("get_weapon_forward"):
				fwd = _weapon_mount.get_weapon_forward()
			_draw_line(_debug_muzzle_mesh, muzzle, muzzle + fwd * 3.0)
	if debug_show_enemy_forward and _debug_forward_mesh and _head:
		var eye_origin: Vector3 = _get_eye_origin()
		var fwd: Vector3 = -_head.global_transform.basis.z
		_draw_line(_debug_forward_mesh, eye_origin, eye_origin + fwd * 1.2)


func _draw_line(mesh_node: MeshInstance3D, from_world: Vector3, to_world: Vector3) -> void:
	var mesh: ImmediateMesh = mesh_node.mesh as ImmediateMesh
	if mesh == null or _fighter == null:
		return
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(_fighter.to_local(from_world))
	mesh.surface_add_vertex(_fighter.to_local(to_world))
	mesh.surface_end()


func _find_fighter() -> RigidBody3D:
	var node: Node = get_parent()
	while node:
		if node is RigidBody3D:
			return node as RigidBody3D
		node = node.get_parent()
	return null
