## Living abyss — fog layers, drift particles, observers, distant flashes.
extends Node3D

const OBSERVER_SCENE: PackedScene = preload("res://scenes/environment/void_observer.tscn")

@export var void_y: float = -20.0
@export var observer_count: int = 4

@onready var _fog_layer_a: MeshInstance3D = $AbyssLayers/FogLayerA
@onready var _fog_layer_b: MeshInstance3D = $AbyssLayers/FogLayerB
@onready var _abyss_particles: CPUParticles3D = $AbyssDriftParticles
@onready var _depth_light: OmniLight3D = $DepthPulseLight
@onready var _observers_root: Node3D = $Observers

var _time: float = 0.0
var _ambient_timer: float = 0.0


func _ready() -> void:
	add_to_group("void_atmosphere")
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("get_void_y"):
		void_y = gm.get_void_y()
	if _abyss_particles:
		_abyss_particles.emitting = true
	_style_hanging_debris()
	_spawn_observers()
	VoidAudio.play_void_drone()


func _style_hanging_debris() -> void:
	var debris_mat := StandardMaterial3D.new()
	debris_mat.albedo_color = Color(0.08, 0.085, 0.1, 1.0)
	debris_mat.metallic = 0.4
	debris_mat.roughness = 0.9
	var root: Node3D = get_node_or_null("HangingDebris") as Node3D
	if root == null:
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = debris_mat


func _process(delta: float) -> void:
	_time += delta
	_ambient_timer += delta
	_animate_fog_layers(delta)
	_pulse_depth_light()
	if _ambient_timer >= randf_range(8.0, 18.0):
		_ambient_timer = 0.0
		VoidAudio.maybe_play_random_abyss_ambience()


func trigger_distant_flash(position: Vector3) -> void:
	var flash: OmniLight3D = OmniLight3D.new()
	add_child(flash)
	flash.global_position = position
	flash.light_color = Color(0.35, 0.55, 0.75, 1.0)
	flash.light_energy = 0.0
	flash.omni_range = 80.0
	var tween: Tween = create_tween()
	tween.tween_property(flash, "light_energy", 1.8, 0.08)
	tween.tween_property(flash, "light_energy", 0.0, 1.2)
	tween.tween_callback(flash.queue_free)
	print("[Void] Distant abyss flash — did something move down there?")


func _animate_fog_layers(_delta: float) -> void:
	var breathe: float = sin(_time * 0.35) * 0.08 + 1.0
	if _fog_layer_a:
		_fog_layer_a.position.y = -8.0 + sin(_time * 0.22) * 1.2
		_fog_layer_a.scale = Vector3(55.0 * breathe, 1.0, 65.0 * breathe)
	if _fog_layer_b:
		_fog_layer_b.position.y = -14.0 + sin(_time * 0.17 + 1.0) * 0.9
		_fog_layer_b.scale = Vector3(70.0 * breathe, 1.0, 80.0 * breathe)


func _pulse_depth_light() -> void:
	if _depth_light:
		_depth_light.light_energy = 0.25 + sin(_time * 0.9) * 0.12


func _spawn_observers() -> void:
	if _observers_root == null:
		return
	var positions: Array[Vector3] = [
		Vector3(-12.0, -6.0, 8.0),
		Vector3(14.0, -9.0, -4.0),
		Vector3(6.0, -11.0, -18.0),
		Vector3(-8.0, -7.0, 16.0),
	]
	for i in mini(observer_count, positions.size()):
		var observer: Node3D = OBSERVER_SCENE.instantiate() as Node3D
		_observers_root.add_child(observer)
		observer.global_position = positions[i]
		observer.rotate_y(randf() * TAU)
