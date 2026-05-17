## Stylized corrupted-flesh chunk for VOID_GORE breakup.
class_name GoreChunk
extends RigidBody3D

const SCENE: PackedScene = preload("res://scenes/effects/gore_chunk.tscn")
const LIFETIME_MIN_SEC: float = 5.0
const LIFETIME_MAX_SEC: float = 7.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("gore_chunk")
	collision_layer = 8
	collision_mask = 1
	var body_mat: PhysicsMaterial = PhysicsMaterial.new()
	body_mat.friction = 0.5
	body_mat.bounce = 0.08
	physics_material_override = body_mat
	_randomize_shape()
	var lifetime: float = randf_range(LIFETIME_MIN_SEC, LIFETIME_MAX_SEC)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _randomize_shape() -> void:
	var use_capsule: bool = randf() > 0.45
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.32 + randf() * 0.08, 0.02, 0.04, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.0, 0.05, 1.0)
	mat.emission_energy_multiplier = 0.25
	mat.roughness = 0.85
	_mesh.material_override = mat
	if use_capsule:
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = randf_range(0.08, 0.16)
		capsule.height = randf_range(0.18, 0.32)
		_mesh.mesh = capsule
		var col: CapsuleShape3D = CapsuleShape3D.new()
		col.radius = capsule.radius
		col.height = capsule.height
		_shape.shape = col
	else:
		var box: BoxMesh = BoxMesh.new()
		var s: float = randf_range(0.1, 0.22)
		box.size = Vector3.ONE * s
		_mesh.mesh = box
		var box_col: BoxShape3D = BoxShape3D.new()
		box_col.size = box.size
		_shape.shape = box_col


func launch_impulse(direction: Vector3, strength: float) -> void:
	var dir: Vector3 = direction
	if dir.length_squared() < 0.001:
		dir = Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.0), randf_range(-1.0, 1.0))
	dir = dir.normalized()
	var flat: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() > 0.001:
		flat = flat.normalized()
	else:
		flat = Vector3.FORWARD
	var up: float = clampf(dir.y * strength * 0.35 + randf_range(2.0, 7.0), 0.0, 12.0)
	linear_velocity = flat * strength * randf_range(0.7, 1.1) + Vector3.UP * up
	var spin: Vector3 = flat.cross(Vector3.UP)
	if spin.length_squared() < 0.01:
		spin = Vector3.RIGHT
	apply_torque_impulse(spin.normalized() * strength * randf_range(0.15, 0.45))


static func spawn_burst(parent: Node, origin: Vector3, count: int, strength: float = 11.0) -> void:
	for _i in count:
		var chunk: RigidBody3D = SCENE.instantiate() as RigidBody3D
		parent.add_child(chunk)
		var offset: Vector3 = Vector3(
			randf_range(-0.4, 0.4), randf_range(-0.2, 0.55), randf_range(-0.4, 0.4)
		)
		chunk.global_position = origin + offset
		var dir: Vector3 = Vector3(
			randf_range(-1.0, 1.0), randf_range(0.1, 1.0), randf_range(-1.0, 1.0)
		).normalized()
		if chunk.has_method("launch_impulse"):
			chunk.call("launch_impulse", dir, strength * randf_range(0.85, 1.2))
