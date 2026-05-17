## Player weapon switching, viewmodels, and firing (uses shared WeaponDefs / WeaponFiring).
extends Node3D

signal weapon_changed(weapon_name: String)

@export var spawn_forward_offset: float = 0.6

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _pistol_view: Node3D = $PistolView
@onready var _shotgun_view: Node3D = $ShotgunView
@onready var _bazooka_view: Node3D = $BazookaView

var _current: WeaponDefs.Id = WeaponDefs.Id.PISTOL
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("weapon_manager")
	switch_weapon(WeaponDefs.Id.PISTOL)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and not game_manager.is_round_active():
		return

	if event.is_action_pressed("weapon_1"):
		switch_weapon(WeaponDefs.Id.PISTOL)
	elif event.is_action_pressed("weapon_2"):
		switch_weapon(WeaponDefs.Id.SHOTGUN)
	elif event.is_action_pressed("weapon_3"):
		switch_weapon(WeaponDefs.Id.BAZOOKA)
	elif event.is_action_pressed("shoot"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		try_fire()


func get_weapon_name() -> String:
	return WeaponDefs.get_name(_current)


func switch_weapon(weapon: WeaponDefs.Id) -> void:
	if _current == weapon:
		return
	_current = weapon
	_pistol_view.visible = weapon == WeaponDefs.Id.PISTOL
	_shotgun_view.visible = weapon == WeaponDefs.Id.SHOTGUN
	_bazooka_view.visible = weapon == WeaponDefs.Id.BAZOOKA
	print("Weapon: %s" % WeaponDefs.get_name(weapon))
	weapon_changed.emit(WeaponDefs.get_name(weapon))


func try_fire() -> bool:
	if _cooldown_remaining > 0.0:
		return false

	var base_dir := -_camera.global_transform.basis.z.normalized()
	var origin := _camera.global_position
	var aim_basis := _camera.global_transform.basis

	_cooldown_remaining = WeaponFiring.fire(
		_current, origin, base_dir, aim_basis, get_tree().current_scene, spawn_forward_offset
	)
	return true


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0
