## Visual weapon mount — single source for barrel orientation (-Z forward).
class_name EnemyWeaponMount
extends Node3D

@export var aim_speed: float = 22.0
@export var aim_lock_speed: float = 42.0
@export var debug_show_weapon_forward: bool = false
@export var debug_show_muzzle: bool = false

var _weapon_manager: EnemyWeaponManager
var _debug_forward_line: MeshInstance3D
var _debug_muzzle_line: MeshInstance3D
var _aim_locked: bool = false
var _sync_printed: bool = false


func _ready() -> void:
	_weapon_manager = get_node_or_null("EnemyWeaponManager") as EnemyWeaponManager
	if debug_show_weapon_forward:
		_debug_forward_line = _create_debug_line(Color(1.0, 0.45, 0.15))
	if debug_show_muzzle:
		_debug_muzzle_line = _create_debug_line(Color(0.4, 0.95, 1.0))


func get_weapon_forward() -> Vector3:
	var fwd: Vector3 = -global_transform.basis.z
	if fwd.length_squared() < 0.0001:
		return Vector3.FORWARD
	return fwd.normalized()


func get_muzzle_global_position() -> Vector3:
	if _weapon_manager:
		return _weapon_manager.get_muzzle_global_position()
	return global_position


func align_to_target(
	world_target: Vector3,
	snap: bool = false,
	aim_locked: bool = false,
	delta: float = -1.0
) -> void:
	_aim_locked = aim_locked
	if world_target == global_position:
		return
	var speed: float = aim_lock_speed if aim_locked else aim_speed
	if snap or aim_locked:
		look_at(world_target, Vector3.UP)
		return
	if delta < 0.0:
		delta = get_process_delta_time()
	var target_basis: Basis = _basis_looking_at_target(world_target)
	var blend: float = clampf(speed * delta, 0.0, 1.0)
	global_transform.basis = global_transform.basis.slerp(target_basis, blend)


func reset_mount() -> void:
	rotation = Vector3.ZERO
	_aim_locked = false
	_sync_printed = false
	if _weapon_manager:
		_weapon_manager.reset_weapon_visuals()


func _process(_delta: float) -> void:
	_update_debug_lines()


func _basis_looking_at_target(world_target: Vector3) -> Basis:
	var dir: Vector3 = (world_target - global_position).normalized()
	if dir.length_squared() < 0.0001:
		return global_transform.basis
	return Basis.looking_at(dir, Vector3.UP)


func _update_debug_lines() -> void:
	var muzzle: Vector3 = get_muzzle_global_position()
	var forward: Vector3 = get_weapon_forward()
	if debug_show_weapon_forward and _debug_forward_line:
		_draw_line(_debug_forward_line, global_position, global_position + forward * 2.5)
	if debug_show_muzzle and _debug_muzzle_line:
		_draw_line(_debug_muzzle_line, muzzle, muzzle + forward * 3.0)


func _create_debug_line(color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	node.material_override = mat
	var fighter := _find_fighter()
	if fighter:
		fighter.add_child(node)
	return node


func _draw_line(node: MeshInstance3D, from_world: Vector3, to_world: Vector3) -> void:
	var mesh: ImmediateMesh = node.mesh as ImmediateMesh
	var fighter := _find_fighter()
	if mesh == null or fighter == null:
		return
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(fighter.to_local(from_world))
	mesh.surface_add_vertex(fighter.to_local(to_world))
	mesh.surface_end()


func _find_fighter() -> Node3D:
	var node: Node = get_parent()
	while node:
		if node is RigidBody3D:
			return node as Node3D
		node = node.get_parent()
	return null


func notify_weapon_synced() -> void:
	if _sync_printed:
		return
	_sync_printed = true
	print("Enemy weapon forward synced")
