## Stylized gib chunk for rocket / overkill collapse deaths.
class_name GibChunk
extends RigidBody3D

const SCENE: PackedScene = preload("res://scenes/effects/gib_chunk.tscn")

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("gib_chunk")
	collision_layer = 8
	collision_mask = 1
	linear_damp = GameBalance.GIB_LINEAR_DAMP
	angular_damp = GameBalance.GIB_ANGULAR_DAMP
	var body_mat: PhysicsMaterial = PhysicsMaterial.new()
	body_mat.friction = 0.65
	body_mat.bounce = 0.04
	physics_material_override = body_mat
	_randomize_shape()
	get_tree().create_timer(
		randf_range(GameBalance.GIB_LIFETIME_MIN_SEC, GameBalance.GIB_LIFETIME_MAX_SEC)
	).timeout.connect(queue_free)


func _randomize_shape() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.28 + randf() * 0.1, 0.02, 0.03, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.12, 0.0, 0.04, 1.0)
	mat.emission_energy_multiplier = 0.2
	mat.roughness = 0.88
	_mesh.material_override = mat
	if randf() > 0.4:
		var box: BoxMesh = BoxMesh.new()
		var s: float = randf_range(0.08, 0.2)
		box.size = Vector3.ONE * s
		_mesh.mesh = box
		var box_col: BoxShape3D = BoxShape3D.new()
		box_col.size = box.size
		_shape.shape = box_col
	else:
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = randf_range(0.07, 0.13)
		capsule.height = randf_range(0.14, 0.26)
		_mesh.mesh = capsule
		var col: CapsuleShape3D = CapsuleShape3D.new()
		col.radius = capsule.radius
		col.height = capsule.height
		_shape.shape = col


func launch_collapse(direction: Vector3, pop_upward: bool) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.001:
		flat = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	flat = flat.normalized()

	var scatter: Vector3 = Vector3(
		randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)
	).normalized()
	var out_dir: Vector3 = (flat * 0.35 + scatter * 0.65).normalized()

	var horizontal_speed: float = randf_range(
		GameBalance.GIB_HORIZONTAL_FORCE_MIN, GameBalance.GIB_HORIZONTAL_FORCE_MAX
	)
	var vertical_speed: float
	if pop_upward:
		vertical_speed = randf_range(
			GameBalance.GIB_UPWARD_FORCE_MIN, GameBalance.GIB_UPWARD_FORCE_MAX
		)
	else:
		vertical_speed = randf_range(-2.5, 0.6)

	linear_velocity = out_dir * horizontal_speed + Vector3.UP * vertical_speed

	var spin_axis: Vector3 = out_dir.cross(Vector3.UP)
	if spin_axis.length_squared() < 0.01:
		spin_axis = Vector3.RIGHT
	apply_torque_impulse(
		spin_axis.normalized() * GameBalance.GIB_TORQUE_FORCE * randf_range(0.6, 1.1)
	)
