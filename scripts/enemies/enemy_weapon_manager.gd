## Enemy weapon viewmodels and firing — same stats/cooldowns as the player.
extends Node3D

@export var spawn_forward_offset: float = 0.7

@onready var _pistol_view: Node3D = $PistolView
@onready var _shotgun_view: Node3D = $ShotgunView
@onready var _bazooka_view: Node3D = $BazookaView

var _current: WeaponDefs.Id = WeaponDefs.Id.PISTOL
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	switch_weapon(WeaponDefs.Id.PISTOL)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func get_weapon() -> WeaponDefs.Id:
	return _current


func get_weapon_name() -> String:
	return WeaponDefs.get_weapon_name(_current)


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0


func switch_weapon(weapon: WeaponDefs.Id) -> void:
	if _current == weapon:
		return
	_current = weapon
	_update_viewmodels()
	print("Enemy switched to %s" % WeaponDefs.get_weapon_name(weapon))


func try_fire(origin: Vector3, direction: Vector3, aim_basis: Basis) -> bool:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("is_fighting") and not game_manager.is_fighting():
		return false
	if _cooldown_remaining > 0.0:
		return false

	var shooter := get_parent().get_parent() as Node
	_cooldown_remaining = WeaponFiring.fire(
		_current,
		origin,
		direction,
		aim_basis,
		get_tree().current_scene,
		spawn_forward_offset,
		shooter
	)
	print("Enemy fired %s" % WeaponDefs.get_weapon_name(_current))
	return true


func _update_viewmodels() -> void:
	_pistol_view.visible = _current == WeaponDefs.Id.PISTOL
	_shotgun_view.visible = _current == WeaponDefs.Id.SHOTGUN
	_bazooka_view.visible = _current == WeaponDefs.Id.BAZOOKA
