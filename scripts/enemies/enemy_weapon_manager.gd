## Enemy weapon viewmodels — visible barrels on WeaponMount; fire from Muzzle along -Z.
class_name EnemyWeaponManager
extends Node3D

signal shot_fired(weapon_name: String)

@export var spawn_forward_offset: float = 0.0

@onready var _railgun_view: Node3D = $RailgunView
@onready var _shotgun_view: Node3D = $ShotgunView
@onready var _bazooka_view: Node3D = $BazookaView
@onready var _railgun_muzzle: Node3D = $RailgunView/Muzzle
@onready var _shotgun_muzzle: Node3D = $ShotgunView/Muzzle
@onready var _bazooka_muzzle: Node3D = $BazookaView/Muzzle

var _current: WeaponDefs.Id = WeaponDefs.Id.RAILGUN
var _cooldown_remaining: float = 0.0
var _rest_views: Dictionary = {}


func _ready() -> void:
	_cache_rest_views()
	switch_weapon(WeaponDefs.Id.RAILGUN)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func get_weapon() -> WeaponDefs.Id:
	return _current


func get_weapon_name() -> String:
	return WeaponDefs.get_weapon_name(_current)


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0


func get_muzzle_global_position() -> Vector3:
	var muzzle: Node3D = _get_active_muzzle()
	if muzzle:
		return muzzle.global_position
	return global_position


func get_weapon_forward() -> Vector3:
	var mount: Node3D = get_parent() as Node3D
	if mount and mount.has_method("get_weapon_forward"):
		return mount.call("get_weapon_forward")
	return -global_transform.basis.z.normalized()


func switch_weapon(weapon: WeaponDefs.Id) -> void:
	if _current == weapon:
		return
	_current = weapon
	_update_viewmodels()
	print("Enemy switched to %s" % WeaponDefs.get_weapon_name(weapon))


func reset_weapon_visuals() -> void:
	for view_name in _rest_views:
		var view: Node3D = get_node_or_null(NodePath(str(view_name))) as Node3D
		if view:
			view.transform = _rest_views[view_name]
	_update_viewmodels()


func try_fire(origin: Vector3, direction: Vector3, aim_basis: Basis) -> bool:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("is_fighting") and not game_manager.is_fighting():
		return false
	if _cooldown_remaining > 0.0:
		return false

	var shooter: Node = _find_arena_opponent()
	var fire_dir: Vector3 = get_weapon_forward()
	if fire_dir.length_squared() < 0.0001:
		fire_dir = direction.normalized()
	var fire_origin: Vector3 = get_muzzle_global_position()
	var fire_basis: Basis = Basis.looking_at(fire_dir, Vector3.UP)

	_cooldown_remaining = WeaponFiring.fire(
		_current,
		fire_origin,
		fire_dir,
		fire_basis,
		get_tree().current_scene,
		spawn_forward_offset,
		shooter
	)
	print("Enemy fired %s" % WeaponDefs.get_weapon_name(_current))
	shot_fired.emit(get_weapon_name())
	var mount: Node = get_parent()
	if mount and mount.has_method("notify_weapon_synced"):
		mount.call("notify_weapon_synced")
	return true


func _get_active_muzzle() -> Node3D:
	match _current:
		WeaponDefs.Id.RAILGUN:
			return _railgun_muzzle
		WeaponDefs.Id.SHOTGUN:
			return _shotgun_muzzle
		WeaponDefs.Id.BAZOOKA:
			return _bazooka_muzzle
	return _railgun_muzzle


func _update_viewmodels() -> void:
	_railgun_view.visible = _current == WeaponDefs.Id.RAILGUN
	_shotgun_view.visible = _current == WeaponDefs.Id.SHOTGUN
	_bazooka_view.visible = _current == WeaponDefs.Id.BAZOOKA


func _cache_rest_views() -> void:
	for child in get_children():
		if child is Node3D and child.name.ends_with("View"):
			_rest_views[child.name] = (child as Node3D).transform


func _find_arena_opponent() -> Node:
	var node: Node = self
	while node:
		if node.is_in_group("arena_opponent"):
			return node
		node = node.get_parent()
	return null
