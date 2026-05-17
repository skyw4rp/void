## Simple RigidBody3D corpse launched on kill deaths — not a skeletal ragdoll.
extends RigidBody3D

const DESPAWN_MIN_SEC: float = 4.0
const DESPAWN_MAX_SEC: float = 6.0

@export var void_y: float = -20.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("corpse")
	collision_layer = 8
	collision_mask = 1
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("get_void_y"):
		void_y = gm.get_void_y()
	var despawn_sec: float = randf_range(DESPAWN_MIN_SEC, DESPAWN_MAX_SEC)
	get_tree().create_timer(despawn_sec).timeout.connect(queue_free)


func configure_appearance(albedo: Color, emission: Color = Color.BLACK) -> void:
	if _mesh == null:
		return
	var mat: StandardMaterial3D = _mesh.material_override.duplicate() as StandardMaterial3D
	mat.albedo_color = albedo
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 0.35
	_mesh.material_override = mat


func launch(position: Vector3, direction: Vector3, force: float, upward_boost: float = 6.0) -> void:
	global_position = position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	var launch_dir: Vector3 = direction
	if launch_dir.length_squared() < 0.001:
		launch_dir = Vector3.FORWARD
	else:
		launch_dir = launch_dir.normalized()

	var impulse: Vector3 = launch_dir * force + Vector3.UP * upward_boost
	apply_central_impulse(impulse * mass)

	var spin_axis: Vector3 = launch_dir.cross(Vector3.UP)
	if spin_axis.length_squared() < 0.01:
		spin_axis = Vector3.RIGHT
	apply_torque_impulse(spin_axis.normalized() * force * 0.35)

	print("Corpse launched with force %.1f" % force)


func _physics_process(_delta: float) -> void:
	if global_position.y < void_y:
		queue_free()
