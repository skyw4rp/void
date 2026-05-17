## Simple RigidBody3D corpse launched on kill deaths — not a skeletal ragdoll.
extends RigidBody3D

const DESPAWN_MIN_SEC: float = 4.0
const DESPAWN_MAX_SEC: float = 6.0
const MAX_DOWNWARD_SPEED: float = 22.0

@export var void_y: float = -20.0
@export var launch_force_multiplier: float = 0.7
@export var max_launch_speed: float = 35.0
@export var max_upward_speed: float = 16.0
@export var upward_boost_multiplier: float = 0.6
@export var torque_multiplier: float = 0.8

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("corpse")
	collision_layer = 8
	collision_mask = 1
	var body_mat: PhysicsMaterial = PhysicsMaterial.new()
	body_mat.friction = 0.55
	body_mat.bounce = 0.1
	physics_material_override = body_mat
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


func launch(
	position: Vector3,
	direction: Vector3,
	force: float,
	upward_boost: float = 6.0,
	damage_source: String = ""
) -> void:
	global_position = position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	var source_scale: float = _damage_source_scale(damage_source)
	var scaled_force: float = force * source_scale * launch_force_multiplier

	var flat_dir: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD
	else:
		flat_dir = flat_dir.normalized()

	var horizontal_speed: float = scaled_force
	var vertical_speed: float = minf(upward_boost * upward_boost_multiplier * source_scale, max_upward_speed)
	vertical_speed += clampf(direction.y * scaled_force * 0.12, -4.0, max_upward_speed * 0.35)

	linear_velocity = flat_dir * horizontal_speed + Vector3.UP * vertical_speed
	_clamp_launch_velocity()

	var spin_axis: Vector3 = flat_dir.cross(Vector3.UP)
	if spin_axis.length_squared() < 0.01:
		spin_axis = Vector3.RIGHT
	apply_torque_impulse(spin_axis.normalized() * scaled_force * torque_multiplier * 0.4)

	print("Corpse final launch velocity: %s (force=%.1f, source=%s)" % [linear_velocity, force, damage_source])


func _damage_source_scale(source: String) -> float:
	match source:
		"pistol":
			return 0.45
		"shotgun":
			return 0.65
		"bazooka_direct":
			return 1.0
		"bazooka_explosion":
			return 1.1
		_:
			return 0.55


func _clamp_launch_velocity() -> void:
	if linear_velocity.length() > max_launch_speed:
		linear_velocity = linear_velocity.normalized() * max_launch_speed
	if linear_velocity.y > max_upward_speed:
		linear_velocity.y = max_upward_speed
	if linear_velocity.y < -MAX_DOWNWARD_SPEED:
		linear_velocity.y = -MAX_DOWNWARD_SPEED


func _physics_process(_delta: float) -> void:
	if global_position.y < void_y:
		queue_free()
