## Player weapon switching, viewmodels, and firing (uses shared WeaponDefs / WeaponFiring).
extends Node3D

signal weapon_changed(weapon_name: String)
signal weapon_switched(weapon: WeaponDefs.Id)
signal shot_fired

@export var spawn_forward_offset: float = 0.6
@export var weapon_bob_affects_aim: bool = false

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _railgun_view: Node3D = $RailgunView
@onready var _shotgun_view: Node3D = $ShotgunView
@onready var _bazooka_view: Node3D = $BazookaView

var _current: WeaponDefs.Id = WeaponDefs.Id.RAILGUN
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("weapon_manager")
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and "weapon_bob_affects_aim" in player:
		weapon_bob_affects_aim = player.weapon_bob_affects_aim
	switch_weapon(WeaponDefs.Id.RAILGUN)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("is_fighting") and not game_manager.is_fighting():
		return

	if event.is_action_pressed("weapon_1"):
		switch_weapon(WeaponDefs.Id.RAILGUN)
	elif event.is_action_pressed("weapon_2"):
		switch_weapon(WeaponDefs.Id.SHOTGUN)
	elif event.is_action_pressed("weapon_3"):
		switch_weapon(WeaponDefs.Id.BAZOOKA)
	elif event.is_action_pressed("shoot"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		try_fire()


func get_weapon_name() -> String:
	return WeaponDefs.get_weapon_name(_current)


func switch_weapon(weapon: WeaponDefs.Id) -> void:
	if _current == weapon:
		return
	_current = weapon
	_railgun_view.visible = weapon == WeaponDefs.Id.RAILGUN
	_shotgun_view.visible = weapon == WeaponDefs.Id.SHOTGUN
	_bazooka_view.visible = weapon == WeaponDefs.Id.BAZOOKA
	print("Weapon: %s" % WeaponDefs.get_weapon_name(weapon))
	weapon_changed.emit(WeaponDefs.get_weapon_name(weapon))
	weapon_switched.emit(weapon)


func try_fire() -> bool:
	if _cooldown_remaining > 0.0:
		return false

	var aim_xform: Transform3D = _get_aim_transform()
	var base_dir: Vector3 = -aim_xform.basis.z
	if base_dir.length_squared() < 0.0001:
		base_dir = Vector3.FORWARD
	else:
		base_dir = base_dir.normalized()
	var origin: Vector3 = _camera.global_position
	var aim_basis: Basis = aim_xform.basis

	_cooldown_remaining = WeaponFiring.fire(
		_current,
		origin,
		base_dir,
		aim_basis,
		get_tree().current_scene,
		spawn_forward_offset,
		_get_shooter_body()
	)
	if _current == WeaponDefs.Id.RAILGUN:
		print("Railgun")
	CombatAudio.play_weapon_fire(_current, origin + base_dir * 0.35, false)
	CombatVfxDirector.spawn_muzzle_fire(_current, origin, base_dir, false)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("notify_weapon_fov_pulse"):
		player.call("notify_weapon_fov_pulse")
	shot_fired.emit()
	return true


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0


func _get_aim_transform() -> Transform3D:
	if weapon_bob_affects_aim:
		return _camera.global_transform
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_aim_global_transform"):
		return player.call("get_aim_global_transform") as Transform3D
	var pivot: Node3D = _resolve_aim_pivot()
	if pivot:
		return pivot.global_transform
	return _camera.global_transform


func _resolve_aim_pivot() -> Node3D:
	var node: Node = _camera
	while node:
		if node.name == "AimPivot" and node is Node3D:
			return node as Node3D
		node = node.get_parent()
	return null


func _get_shooter_body() -> Node:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		return player
	return _camera.get_parent()
