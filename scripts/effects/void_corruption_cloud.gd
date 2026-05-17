## Expanding void corruption gas cloud for VOID_GORE cinematic.
class_name VoidCorruptionCloud
extends Node3D

const SCENE: PackedScene = preload("res://scenes/effects/void_corruption_cloud.tscn")
const LIFETIME_SEC: float = 3.0

@onready var _fog_mesh: MeshInstance3D = $FogVolume
@onready var _drift: CPUParticles3D = $DriftParticles
@onready var _mist: CPUParticles3D = $MistParticles
@onready var _light: OmniLight3D = $PulseLight

var _elapsed: float = 0.0


static func spawn(parent: Node, position: Vector3) -> Node3D:
	var cloud: Node3D = SCENE.instantiate() as Node3D
	parent.add_child(cloud)
	if cloud.has_method("activate"):
		cloud.call("activate", position)
	return cloud


func _ready() -> void:
	add_to_group("void_effect")
	visible = false


func activate(position: Vector3) -> void:
	global_position = position
	visible = true
	_elapsed = 0.0
	if _drift:
		_drift.emitting = true
	if _mist:
		_mist.emitting = true
	get_tree().create_timer(LIFETIME_SEC).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	var grow: float = lerpf(0.85, 2.4, clampf(_elapsed / 1.8, 0.0, 1.0))
	if _fog_mesh:
		_fog_mesh.scale = Vector3.ONE * grow
	if _light:
		_light.light_energy = 1.2 + sin(_elapsed * 5.5) * 0.55
