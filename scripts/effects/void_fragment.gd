## Small physics chunk for EXPLODE / GORE void death styles.
class_name VoidFragment
extends RigidBody3D

const SCENE: PackedScene = preload("res://scenes/effects/void_fragment.tscn")
const LIFETIME_SEC: float = 3.5

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("void_fragment")
	collision_layer = 8
	collision_mask = 1
	linear_damp = 0.15
	angular_damp = 0.25
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.friction = 0.55
	mat.bounce = 0.1
	physics_material_override = mat
	get_tree().create_timer(LIFETIME_SEC).timeout.connect(queue_free)


func configure_color(albedo: Color, emission: Color = Color.BLACK) -> void:
	if _mesh == null:
		return
	var std: StandardMaterial3D = _mesh.material_override.duplicate() as StandardMaterial3D
	std.albedo_color = albedo
	if emission != Color.BLACK:
		std.emission_enabled = true
		std.emission = emission
		std.emission_energy_multiplier = 0.3
	_mesh.material_override = std


func launch(direction: Vector3, strength: float) -> void:
	var dir: Vector3 = direction
	if dir.length_squared() < 0.001:
		dir = Vector3(randf_range(-1.0, 1.0), randf_range(0.3, 1.0), randf_range(-1.0, 1.0))
	dir = dir.normalized()
	var flat: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() > 0.001:
		flat = flat.normalized()
	else:
		flat = Vector3.FORWARD
	var up: float = clampf(dir.y * strength * 0.25, 0.0, 10.0)
	linear_velocity = flat * strength + Vector3.UP * up
	var spin: Vector3 = flat.cross(Vector3.UP)
	if spin.length_squared() < 0.01:
		spin = Vector3.RIGHT
	apply_torque_impulse(spin.normalized() * strength * 0.2)


static func spawn_burst(
	parent: Node,
	origin: Vector3,
	count: int,
	albedo: Color,
	strength: float,
	emission: Color = Color.BLACK
) -> void:
	for _i in count:
		var fragment: RigidBody3D = SCENE.instantiate() as RigidBody3D
		parent.add_child(fragment)
		var offset: Vector3 = Vector3(
			randf_range(-0.35, 0.35), randf_range(-0.15, 0.45), randf_range(-0.35, 0.35)
		)
		fragment.global_position = origin + offset
		if fragment.has_method("configure_color"):
			fragment.call("configure_color", albedo, emission)
		var dir: Vector3 = Vector3(
			randf_range(-1.0, 1.0), randf_range(0.15, 1.0), randf_range(-1.0, 1.0)
		).normalized()
		if fragment.has_method("launch"):
			fragment.call("launch", dir, strength * randf_range(0.75, 1.15))
