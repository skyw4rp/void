## Manages weapon switching, viewmodels, and firing for pistol / shotgun / bazooka.
extends Node3D

signal weapon_changed(weapon_name: String)

enum Weapon { PISTOL, SHOTGUN, BAZOOKA }

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/push_projectile.tscn")
const BAZOOKA_PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/bazooka_projectile.tscn")

const WEAPON_NAMES: Array[String] = ["Pistol", "Shotgun", "Bazooka"]

@export var spawn_forward_offset: float = 0.6

@onready var _camera: Camera3D = get_parent() as Camera3D
@onready var _pistol_view: Node3D = $PistolView
@onready var _shotgun_view: Node3D = $ShotgunView
@onready var _bazooka_view: Node3D = $BazookaView

var _current: Weapon = Weapon.PISTOL
var _cooldown_remaining: float = 0.0

## Per-weapon tuning: cooldown, projectile stats, pellet count, spread (radians).
var _stats: Dictionary = {
	Weapon.PISTOL: {
		"cooldown": 0.15,
		"pellets": 1,
		"spread": 0.0,
		"projectile": {
			"speed": 50.0,
			"push_force": 8.0,
			"lifetime": 2.5,
			"mesh_scale": 0.08,
			"color": Color(0.75, 0.85, 1.0),
		},
	},
	Weapon.SHOTGUN: {
		"cooldown": 0.75,
		"pellets": 7,
		"spread": 0.14,
		"projectile": {
			"speed": 38.0,
			"push_force": 14.0,
			"lifetime": 1.8,
			"mesh_scale": 0.07,
			"color": Color(1.0, 0.75, 0.35),
		},
	},
	Weapon.BAZOOKA: {
		"cooldown": 1.25,
		"pellets": 1,
		"spread": 0.0,
		"use_bazooka_scene": true,
	},
}


func _ready() -> void:
	add_to_group("weapon_manager")
	_switch_weapon(Weapon.PISTOL)


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_1"):
		_switch_weapon(Weapon.PISTOL)
	elif event.is_action_pressed("weapon_2"):
		_switch_weapon(Weapon.SHOTGUN)
	elif event.is_action_pressed("weapon_3"):
		_switch_weapon(Weapon.BAZOOKA)
	elif event.is_action_pressed("shoot"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		if _cooldown_remaining > 0.0:
			return
		_fire_current_weapon()


func get_weapon_name() -> String:
	return WEAPON_NAMES[_current]


func _switch_weapon(weapon: Weapon) -> void:
	_current = weapon
	_pistol_view.visible = weapon == Weapon.PISTOL
	_shotgun_view.visible = weapon == Weapon.SHOTGUN
	_bazooka_view.visible = weapon == Weapon.BAZOOKA
	print("Weapon: %s" % WEAPON_NAMES[weapon])
	weapon_changed.emit(WEAPON_NAMES[weapon])


func _fire_current_weapon() -> void:
	var data: Dictionary = _stats[_current]
	_cooldown_remaining = data.cooldown

	var base_dir := -_camera.global_transform.basis.z.normalized()
	var spawn_pos := _camera.global_position + base_dir * spawn_forward_offset
	var pellets: int = data.pellets

	if data.get("use_bazooka_scene", false):
		_spawn_bazooka(spawn_pos, base_dir)
		return

	for i in pellets:
		var dir := _apply_spread(base_dir, data.spread)
		_spawn_standard_projectile(spawn_pos, dir, data.projectile)


func _apply_spread(direction: Vector3, spread: float) -> Vector3:
	if spread <= 0.0:
		return direction
	var cam_basis := _camera.global_transform.basis
	var offset := cam_basis.x * randf_range(-spread, spread)
	offset += cam_basis.y * randf_range(-spread, spread)
	return (direction + offset).normalized()


func _spawn_standard_projectile(from: Vector3, direction: Vector3, stats: Dictionary) -> void:
	var projectile: Area3D = PROJECTILE_SCENE.instantiate() as Area3D
	get_tree().current_scene.add_child(projectile)
	projectile.configure(stats)
	projectile.launch(from, direction)


func _spawn_bazooka(from: Vector3, direction: Vector3) -> void:
	var projectile: Area3D = BAZOOKA_PROJECTILE_SCENE.instantiate() as Area3D
	get_tree().current_scene.add_child(projectile)
	projectile.launch(from, direction)
