## Toxic void abyss — layered gas, depth collapse, Quake-style industrial pit.
extends Node3D

const OBSERVER_SCENE: PackedScene = preload("res://scenes/environment/void_observer.tscn")

@export var void_y: float = -20.0
@export var observer_count: int = 4

@onready var _fog_upper: MeshInstance3D = $AbyssLayers/FogLayerUpper
@onready var _fog_layer_a: MeshInstance3D = $AbyssLayers/FogLayerA
@onready var _fog_layer_b: MeshInstance3D = $AbyssLayers/FogLayerB
@onready var _fog_deep: MeshInstance3D = $AbyssLayers/FogLayerDeep
@onready var _corruption_haze: MeshInstance3D = $AbyssLayers/CorruptionHaze
@onready var _gas_sea: MeshInstance3D = $AbyssLayers/ToxicGasSea
@onready var _gas_swirl: MeshInstance3D = $AbyssLayers/ToxicGasSwirl
@onready var _abyss_particles: CPUParticles3D = $AbyssDriftParticles
@onready var _toxic_motes: CPUParticles3D = $ToxicMotes
@onready var _deep_ash: CPUParticles3D = $DeepAshParticles
@onready var _depth_light: OmniLight3D = $DepthPulseLight
@onready var _toxic_glow: OmniLight3D = $ToxicGlowLight
@onready var _observers_root: Node3D = $Observers

var _time: float = 0.0
var _ambient_timer: float = 0.0
var _depth_t: float = 0.0
var _fall_anchor: Vector3 = Vector3.ZERO
var _base_particle_amount: int = 96
var _base_mote_amount: int = 48
var _base_ash_amount: int = 0

var _mat_upper: StandardMaterial3D
var _mat_a: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _mat_deep: StandardMaterial3D
var _mat_haze: StandardMaterial3D
var _mat_sea: StandardMaterial3D


func _ready() -> void:
	add_to_group("void_atmosphere")
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("get_void_y"):
		void_y = gm.get_void_y()
	_cache_materials()
	if _abyss_particles:
		_base_particle_amount = _abyss_particles.amount
		_abyss_particles.emitting = true
	if _toxic_motes:
		_base_mote_amount = _toxic_motes.amount
		_toxic_motes.emitting = true
	if _deep_ash:
		_base_ash_amount = _deep_ash.amount
		_deep_ash.emitting = true
	_style_hanging_debris()
	_spawn_observers()
	VoidAudio.play_void_drone()


func apply_depth_sample(depth_t: float, world_y: float, anchor: Vector3) -> void:
	_depth_t = depth_t
	_fall_anchor = anchor
	_apply_layer_density(depth_t, world_y)
	_apply_particle_density(depth_t)
	if _observers_root:
		_observers_root.visible = depth_t < 0.55


func _cache_materials() -> void:
	if _fog_upper and _fog_upper.material_override is StandardMaterial3D:
		_mat_upper = (_fog_upper.material_override as StandardMaterial3D).duplicate()
		_fog_upper.material_override = _mat_upper
	if _fog_layer_a and _fog_layer_a.material_override is StandardMaterial3D:
		_mat_a = (_fog_layer_a.material_override as StandardMaterial3D).duplicate()
		_fog_layer_a.material_override = _mat_a
	if _fog_layer_b and _fog_layer_b.material_override is StandardMaterial3D:
		_mat_b = (_fog_layer_b.material_override as StandardMaterial3D).duplicate()
		_fog_layer_b.material_override = _mat_b
	if _fog_deep and _fog_deep.material_override is StandardMaterial3D:
		_mat_deep = (_fog_deep.material_override as StandardMaterial3D).duplicate()
		_fog_deep.material_override = _mat_deep
	if _corruption_haze and _corruption_haze.material_override is StandardMaterial3D:
		_mat_haze = (_corruption_haze.material_override as StandardMaterial3D).duplicate()
		_corruption_haze.material_override = _mat_haze
	if _gas_sea and _gas_sea.material_override is StandardMaterial3D:
		_mat_sea = (_gas_sea.material_override as StandardMaterial3D).duplicate()
		_gas_sea.material_override = _mat_sea


func _apply_layer_density(depth_t: float, world_y: float) -> void:
	var gas_green := Color(0.05, 0.16, 0.1, lerpf(0.12, 0.72, depth_t))
	var gas_blue := Color(0.03, 0.09, 0.18, lerpf(0.18, 0.82, depth_t))
	var gas_purple := Color(0.08, 0.04, 0.14, lerpf(0.15, 0.88, depth_t))
	var gas_black := Color(0.02, 0.04, 0.06, lerpf(0.25, 0.95, depth_t))

	if _mat_upper:
		_mat_upper.albedo_color = gas_green
	if _mat_a:
		_mat_a.albedo_color = gas_green.lerp(gas_blue, depth_t)
	if _mat_b:
		_mat_b.albedo_color = gas_blue.lerp(gas_purple, depth_t)
	if _mat_deep:
		_mat_deep.albedo_color = gas_purple.lerp(gas_black, depth_t)
	if _mat_haze:
		_mat_haze.albedo_color = Color(0.1, 0.05, 0.12, lerpf(0.2, 0.9, depth_t))
	if _mat_sea:
		_mat_sea.albedo_color = Color(0.03, 0.12, 0.08, lerpf(0.42, 0.92, depth_t))

	var follow: Vector3 = _fall_anchor if depth_t > 0.05 else Vector3.ZERO
	var breathe: float = sin(_time * 0.32) * 0.1 + 1.0

	if _fog_upper:
		_fog_upper.position = Vector3(follow.x, lerpf(-14.0, follow.y - 2.0, depth_t), follow.z)
		_fog_upper.scale = Vector3(lerpf(48.0, 20.0, depth_t) * breathe, 1.0, lerpf(52.0, 22.0, depth_t))
		_fog_upper.visible = depth_t > 0.12 or world_y < GameBalance.VOID_FOG_Y_LIGHT
	if _fog_layer_a:
		_fog_layer_a.position = Vector3(follow.x, lerpf(-20.0, follow.y - 5.0, depth_t), follow.z)
		_fog_layer_a.scale = Vector3(lerpf(50.0, 16.0, depth_t) * breathe, 1.0, lerpf(54.0, 18.0, depth_t))
		_fog_layer_a.visible = depth_t > 0.1 or world_y < GameBalance.VOID_FOG_Y_LIGHT
	if _fog_layer_b:
		_fog_layer_b.position = Vector3(follow.x, lerpf(-26.0, follow.y - 9.0, depth_t), follow.z)
		_fog_layer_b.scale = Vector3(lerpf(56.0, 14.0, depth_t) * breathe, 1.0, lerpf(60.0, 16.0, depth_t))
		_fog_layer_b.visible = depth_t > 0.15 or world_y < GameBalance.VOID_FOG_Y_MEDIUM
	if _fog_deep:
		_fog_deep.position = Vector3(follow.x, lerpf(-32.0, follow.y - 3.0, depth_t), follow.z)
		_fog_deep.scale = Vector3(lerpf(52.0, 10.0, depth_t), 1.0, lerpf(56.0, 12.0, depth_t))
		_fog_deep.visible = depth_t > 0.2 or world_y < GameBalance.VOID_FOG_Y_MEDIUM
	if _corruption_haze:
		_corruption_haze.position = Vector3(follow.x, lerpf(-38.0, follow.y - 1.5, depth_t), follow.z)
		_corruption_haze.visible = depth_t > 0.3 or world_y < GameBalance.VOID_FOG_Y_DENSE
	if _gas_sea:
		_gas_sea.position = Vector3(follow.x, lerpf(-24.0, follow.y - 4.0, depth_t), follow.z)
		_gas_sea.scale = Vector3(lerpf(72.0, 12.0, depth_t) * breathe, 1.0, lerpf(78.0, 14.0, depth_t))
	if _gas_swirl:
		_gas_swirl.position = Vector3(follow.x, lerpf(-18.0, follow.y - 6.0, depth_t), follow.z)


func _apply_particle_density(depth_t: float) -> void:
	if _abyss_particles:
		_abyss_particles.amount = int(lerpf(float(_base_particle_amount), 32.0, depth_t))
		_abyss_particles.emission_box_extents = Vector3(
			lerpf(18.0, 4.0, depth_t), lerpf(6.0, 2.5, depth_t), lerpf(22.0, 4.0, depth_t)
		)
	if _toxic_motes:
		_toxic_motes.amount = int(lerpf(float(_base_mote_amount), 80.0, depth_t))
		_toxic_motes.emission_box_extents = Vector3(
			lerpf(24.0, 3.5, depth_t), lerpf(10.0, 2.0, depth_t), lerpf(28.0, 3.5, depth_t)
		)
	if _deep_ash:
		_deep_ash.amount = int(lerpf(0.0, 64.0, depth_t))
		var ash_on: bool = depth_t > 0.15
		_deep_ash.visible = ash_on
		_deep_ash.emitting = ash_on
		if ash_on:
			_deep_ash.global_position = Vector3(
				_fall_anchor.x, lerpf(-18.0, _fall_anchor.y, depth_t), _fall_anchor.z
			)


func _style_hanging_debris() -> void:
	var debris_mat := StandardMaterial3D.new()
	debris_mat.albedo_color = Color(0.06, 0.08, 0.1, 1.0)
	debris_mat.metallic = 0.35
	debris_mat.roughness = 0.92
	var root: Node3D = get_node_or_null("HangingDebris") as Node3D
	if root == null:
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = debris_mat


func _process(delta: float) -> void:
	_time += delta
	_ambient_timer += delta
	_animate_gas_layers(delta)
	_pulse_depth_lights()
	if _ambient_timer >= randf_range(8.0, 18.0):
		_ambient_timer = 0.0
		VoidAudio.maybe_play_random_abyss_ambience()


func trigger_distant_flash(position: Vector3) -> void:
	var flash: OmniLight3D = OmniLight3D.new()
	add_child(flash)
	flash.global_position = position
	flash.light_color = Color(0.25, 0.65, 0.45, 1.0)
	flash.light_energy = 0.0
	flash.omni_range = 80.0
	var tween: Tween = create_tween()
	tween.tween_property(flash, "light_energy", 1.6, 0.08)
	tween.tween_property(flash, "light_energy", 0.0, 1.2)
	tween.tween_callback(flash.queue_free)


func boost_corruption_at(position: Vector3) -> void:
	_fall_anchor = position
	_depth_t = maxf(_depth_t, 0.55)
	if _corruption_haze:
		_corruption_haze.global_position = position
		_corruption_haze.visible = true
	if _mat_haze:
		_mat_haze.albedo_color = Color(0.14, 0.06, 0.16, 0.92)


func _animate_gas_layers(_delta: float) -> void:
	if _depth_t > 0.2:
		return
	var breathe: float = sin(_time * 0.32) * 0.1 + 1.0
	var drift_x: float = sin(_time * 0.11) * 1.8
	var drift_z: float = cos(_time * 0.09) * 2.2
	if _gas_swirl:
		_gas_swirl.rotation.y = _time * 0.04
		_gas_swirl.position.x = drift_x
		_gas_swirl.position.z = drift_z


func _pulse_depth_lights() -> void:
	var pulse: float = 0.22 + sin(_time * 0.85) * 0.14
	pulse *= lerpf(1.0, 0.35, _depth_t)
	if _depth_light:
		_depth_light.light_energy = pulse
		_depth_light.light_color = Color(0.16, 0.4, 0.28).lerp(Color(0.08, 0.12, 0.2), _depth_t)
	if _toxic_glow:
		_toxic_glow.light_energy = (0.35 + sin(_time * 0.55 + 0.8) * 0.18) * lerpf(1.0, 0.25, _depth_t)


func _spawn_observers() -> void:
	if _observers_root == null:
		return
	var positions: Array[Vector3] = [
		Vector3(-14.0, -5.0, 10.0),
		Vector3(16.0, -8.0, -6.0),
		Vector3(8.0, -11.0, -20.0),
		Vector3(-10.0, -6.5, 18.0),
	]
	for i in mini(observer_count, positions.size()):
		var observer: Node3D = OBSERVER_SCENE.instantiate() as Node3D
		_observers_root.add_child(observer)
		observer.global_position = positions[i]
		observer.rotate_y(randf() * TAU)
