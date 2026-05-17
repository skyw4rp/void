## Uncanny silhouette — hides when the player looks directly at it.
extends Node3D

@export var hide_dot_threshold: float = 0.88
@export var fade_speed: float = 6.0

@onready var _mesh: MeshInstance3D = $ObserverMesh

var _target_alpha: float = 1.0
var _player: Node3D


func _ready() -> void:
	add_to_group("void_observer")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _mesh and _mesh.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _mesh.material_override as StandardMaterial3D
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.0
		_target_alpha = 0.85


func _process(delta: float) -> void:
	if _mesh == null or _player == null:
		return
	var camera: Camera3D = _player.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return

	var to_observer: Vector3 = (global_position - camera.global_position).normalized()
	var look_dir: Vector3 = -camera.global_transform.basis.z
	var dot: float = look_dir.dot(to_observer)

	_target_alpha = 0.08 if dot > hide_dot_threshold else 0.82

	var mat: StandardMaterial3D = _mesh.material_override as StandardMaterial3D
	if mat:
		var a: float = lerpf(mat.albedo_color.a, _target_alpha, delta * fade_speed)
		mat.albedo_color.a = a
