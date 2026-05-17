## Placeholder void disintegration burst — architecture ready for alternate styles later.
extends Node3D

const VOID_DEATH_STYLE: String = "disintegrate"
const LIFETIME_SEC: float = 1.5

const SCENE: PackedScene = preload("res://scenes/effects/void_death_effect.tscn")

@onready var _flash: MeshInstance3D = $FlashSphere
@onready var _ring: MeshInstance3D = $VoidRing
@onready var _burst: CPUParticles3D = $BurstParticles
@onready var _fragments: Node3D = $FragmentRoot

var _elapsed: float = 0.0
var _playing: bool = false


static func play_at(parent: Node, position: Vector3) -> void:
	var effect: Node3D = SCENE.instantiate() as Node3D
	parent.add_child(effect)
	if effect.has_method("play"):
		effect.call("play", position)


func _ready() -> void:
	add_to_group("void_effect")
	visible = false
	_init_fragment_drifts()


func _init_fragment_drifts() -> void:
	if _fragments == null:
		return
	for child in _fragments.get_children():
		if child is MeshInstance3D:
			var drift: Vector3 = Vector3(
				randf_range(-1.0, 1.0), randf_range(0.3, 1.0), randf_range(-1.0, 1.0)
			).normalized()
			child.set_meta("drift", drift)


func play(position: Vector3) -> void:
	global_position = position
	visible = true
	_elapsed = 0.0
	_playing = true
	if _burst:
		_burst.emitting = true
	print("Void death effect (%s) at %s" % [VOID_DEATH_STYLE, position])


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	var t: float = clampf(_elapsed / LIFETIME_SEC, 0.0, 1.0)

	if _flash:
		var flash_scale: float = lerpf(0.4, 5.0, t)
		_flash.scale = Vector3.ONE * flash_scale
	if _ring:
		var ring_scale: float = lerpf(0.6, 6.5, t)
		_ring.scale = Vector3(ring_scale, 0.15 + t * 0.5, ring_scale)
		_ring.rotation.y += delta * 4.0

	if _fragments:
		for child in _fragments.get_children():
			if child is MeshInstance3D:
				var mesh: MeshInstance3D = child as MeshInstance3D
				mesh.position += mesh.get_meta("drift", Vector3.UP) * delta * 3.5
				mesh.scale = Vector3.ONE * lerpf(1.0, 0.05, t)

	if _elapsed >= LIFETIME_SEC:
		_playing = false
		queue_free()
