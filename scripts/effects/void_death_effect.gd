## Void pit death VFX — style selected via GameBalance.VOID_DEATH_STYLE.
extends Node3D

const LIFETIME_SEC: float = 1.6
const SCENE: PackedScene = preload("res://scenes/effects/void_death_effect.tscn")

@onready var _disintegrate_root: Node3D = $DisintegrateRoot
@onready var _flash: MeshInstance3D = $DisintegrateRoot/FlashSphere
@onready var _ring: MeshInstance3D = $DisintegrateRoot/VoidRing
@onready var _burst: CPUParticles3D = $BurstParticles
@onready var _fragments: Node3D = $DisintegrateRoot/FragmentRoot

var _elapsed: float = 0.0
var _playing: bool = false
var _style: int = GameBalance.VoidDeathStyle.DISINTEGRATE


static func play_at(
	parent: Node, position: Vector3, style: int = GameBalance.VOID_DEATH_STYLE
) -> void:
	var effect: Node3D = SCENE.instantiate() as Node3D
	parent.add_child(effect)
	if effect.has_method("play"):
		effect.call("play", position, style)


func _ready() -> void:
	add_to_group("void_effect")
	visible = false
	_init_fragment_drifts()


func play(position: Vector3, style: int = GameBalance.VOID_DEATH_STYLE) -> void:
	global_position = position
	_style = style
	visible = true
	_elapsed = 0.0
	_playing = true

	var style_name: String = GameBalance.void_death_style_name(style as GameBalance.VoidDeathStyle)
	print("Void death style: %s at %s" % [style_name, position])

	match style:
		GameBalance.VoidDeathStyle.EXPLODE:
			_play_explode()
		GameBalance.VoidDeathStyle.GORE_PLACEHOLDER:
			_play_gore()
		_:
			_play_disintegrate()


func _play_disintegrate() -> void:
	if _disintegrate_root:
		_disintegrate_root.visible = true
	if _burst:
		_burst.color = Color(0.4, 1.0, 0.65, 1.0)
		_burst.emitting = true


func _play_explode() -> void:
	if _disintegrate_root:
		_disintegrate_root.visible = true
	if _flash:
		var mat: StandardMaterial3D = _flash.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1.0, 0.75, 0.35, 0.9)
			mat.emission = Color(1.0, 0.5, 0.15, 1.0)
	if _burst:
		_burst.color = Color(1.0, 0.6, 0.2, 1.0)
		_burst.emitting = true
	VoidFragment.spawn_burst(
		get_parent(),
		global_position,
		10,
		Color(0.55, 0.58, 0.62, 1.0),
		14.0,
		Color(0.9, 0.55, 0.2, 1.0)
	)


func _play_gore() -> void:
	if _disintegrate_root:
		_disintegrate_root.visible = false
	VoidFragment.spawn_burst(
		get_parent(),
		global_position,
		12,
		Color(0.55, 0.08, 0.1, 1.0),
		12.0,
		Color(0.25, 0.02, 0.05, 1.0)
	)
	if _burst:
		_burst.color = Color(0.9, 0.15, 0.2, 1.0)
		_burst.emitting = true


func _init_fragment_drifts() -> void:
	if _fragments == null:
		return
	for child in _fragments.get_children():
		if child is MeshInstance3D:
			var drift: Vector3 = Vector3(
				randf_range(-1.0, 1.0), randf_range(0.3, 1.0), randf_range(-1.0, 1.0)
			).normalized()
			child.set_meta("drift", drift)


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	if _style != GameBalance.VoidDeathStyle.DISINTEGRATE:
		if _elapsed >= LIFETIME_SEC:
			_playing = false
			queue_free()
		return

	var t: float = clampf(_elapsed / LIFETIME_SEC, 0.0, 1.0)
	if _flash:
		_flash.scale = Vector3.ONE * lerpf(0.4, 5.0, t)
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
