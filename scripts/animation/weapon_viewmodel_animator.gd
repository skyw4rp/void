## Visual-only viewmodel motion — sway, bob, recoil, switch dip.
class_name WeaponViewmodelAnimator
extends Node3D

@export var sway_strength: float = 0.02
@export var bob_strength: float = 0.016
@export var bob_speed: float = 10.0
@export var sprint_bob_mult: float = 1.25

var _weapon_manager: Node3D
var _player: CharacterBody3D
var _views: Dictionary = {}
var _base_transforms: Dictionary = {}
var _recoil_offset: Vector3 = Vector3.ZERO
var _recoil_kick: float = 0.0
var _switch_blend: float = 1.0
var _bob_phase: float = 0.0
var _current_weapon: WeaponDefs.Id = WeaponDefs.Id.RAILGUN
var _signals_connected: bool = false


func _ready() -> void:
	_weapon_manager = get_parent() as Node3D
	if _weapon_manager == null:
		return
	var camera: Camera3D = _weapon_manager.get_parent() as Camera3D
	if camera:
		_player = camera.get_parent() as CharacterBody3D
	_cache_views()
	call_deferred("_connect_weapon_signals")


func _connect_weapon_signals() -> void:
	if _weapon_manager == null or _signals_connected:
		return
	if _weapon_manager.has_signal("shot_fired"):
		if not _weapon_manager.shot_fired.is_connected(_on_shot_fired):
			_weapon_manager.shot_fired.connect(_on_shot_fired)
	if _weapon_manager.has_signal("weapon_switched"):
		if not _weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
			_weapon_manager.weapon_switched.connect(_on_weapon_switched)
	_signals_connected = true
	_sync_current_weapon()


func _sync_current_weapon() -> void:
	if _weapon_manager == null:
		return
	for view_name in _views:
		var view: Node3D = _views[view_name] as Node3D
		if view and view.visible:
			match view_name:
				"RailgunView":
					_current_weapon = WeaponDefs.Id.RAILGUN
				"ShotgunView":
					_current_weapon = WeaponDefs.Id.SHOTGUN
				"BazookaView":
					_current_weapon = WeaponDefs.Id.BAZOOKA
			return


func _process(delta: float) -> void:
	if not _signals_connected:
		_connect_weapon_signals()
	if _views.is_empty():
		return

	_recoil_kick = move_toward(_recoil_kick, 0.0, delta * _recoil_decay_rate())
	_switch_blend = move_toward(_switch_blend, 1.0, delta * 6.0)
	_recoil_offset = _recoil_offset.lerp(Vector3.ZERO, 1.0 - exp(-14.0 * delta))

	var bob: Vector3 = Vector3.ZERO
	var sway: Vector3 = Vector3.ZERO
	if _player and is_instance_valid(_player):
		var vel: Vector3 = _player.velocity
		var h_speed: float = Vector3(vel.x, 0.0, vel.z).length()
		var on_floor: bool = _player.is_on_floor()
		if on_floor and h_speed > 0.35:
			_bob_phase += delta * bob_speed * clampf(h_speed / 6.0, 0.5, 1.6)
			var bob_scale: float = bob_strength
			if h_speed > 7.0:
				bob_scale *= sprint_bob_mult
			bob.y = sin(_bob_phase) * bob_scale
			bob.x = cos(_bob_phase * 0.5) * bob_scale * 0.4
		var camera: Camera3D = _weapon_manager.get_parent() as Camera3D
		if camera:
			var right: Vector3 = camera.global_transform.basis.x
			var flat_vel: Vector3 = Vector3(vel.x, 0.0, vel.z)
			sway = right * flat_vel.dot(right) * sway_strength

	var view: Node3D = _get_active_view()
	if view == null:
		return
	var base: Transform3D = _base_transforms.get(view.name, view.transform)
	var kick_back: Vector3 = Vector3(0.0, 0.0, _recoil_kick)
	var switch_dip: Vector3 = Vector3(0.0, -0.06 * (1.0 - _switch_blend), 0.04 * (1.0 - _switch_blend))
	view.transform = Transform3D(
		base.basis,
		base.origin + bob + sway + _recoil_offset + kick_back + switch_dip
	)


func _cache_views() -> void:
	for child in _weapon_manager.get_children():
		if child == self:
			continue
		if child is Node3D and child.name.ends_with("View"):
			_views[child.name] = child
			_base_transforms[child.name] = (child as Node3D).transform


func _get_active_view() -> Node3D:
	match _current_weapon:
		WeaponDefs.Id.RAILGUN:
			return _views.get("RailgunView") as Node3D
		WeaponDefs.Id.SHOTGUN:
			return _views.get("ShotgunView") as Node3D
		WeaponDefs.Id.BAZOOKA:
			return _views.get("BazookaView") as Node3D
	return null


func _on_shot_fired() -> void:
	match _current_weapon:
		WeaponDefs.Id.RAILGUN:
			_recoil_kick = 0.09
			_recoil_offset.z = 0.11
		WeaponDefs.Id.SHOTGUN:
			_recoil_kick = 0.13
			_recoil_offset.z = 0.16
			_recoil_offset.y = -0.03
		WeaponDefs.Id.BAZOOKA:
			_recoil_kick = 0.18
			_recoil_offset.z = 0.2
			_recoil_offset.y = -0.05
		_:
			_recoil_kick = 0.08


func _on_weapon_switched(weapon: WeaponDefs.Id) -> void:
	_current_weapon = weapon
	_switch_blend = 0.0
	_recoil_kick = 0.0
	_recoil_offset = Vector3.ZERO


func _recoil_decay_rate() -> float:
	match _current_weapon:
		WeaponDefs.Id.RAILGUN:
			return 16.0
		WeaponDefs.Id.SHOTGUN:
			return 10.0
		WeaponDefs.Id.BAZOOKA:
			return 6.0
		_:
			return 12.0
