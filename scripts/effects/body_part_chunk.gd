## Large body-part or small gore chunk for directional dismemberment deaths.
class_name BodyPartChunk
extends RigidBody3D

enum PartKind { TORSO, HEAD, ARM, LEG, ARMOR_SHARD, SMALL_GIB }

const SCENE: PackedScene = preload("res://scenes/effects/body_part_chunk.tscn")

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	linear_damp = GameBalance.DISMEMBER_LINEAR_DAMP
	angular_damp = GameBalance.DISMEMBER_ANGULAR_DAMP
	var body_mat: PhysicsMaterial = PhysicsMaterial.new()
	body_mat.friction = 0.82
	body_mat.bounce = 0.03
	physics_material_override = body_mat
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("get_void_y"):
		_void_y = gm.get_void_y()
	get_tree().create_timer(
		randf_range(GameBalance.DISMEMBER_LIFETIME_MIN_SEC, GameBalance.DISMEMBER_LIFETIME_MAX_SEC)
	).timeout.connect(queue_free)


var _void_y: float = -32.0


func configure(kind: PartKind, flesh_color: Color, armor_color: Color) -> void:
	add_to_group("dismembered_body_part" if kind != PartKind.SMALL_GIB else "gib_chunk")
	match kind:
		PartKind.TORSO:
			_setup_capsule(0.32, 0.55, 2.2, flesh_color, armor_color, 0.35)
		PartKind.HEAD:
			_setup_sphere(0.22, 1.0, flesh_color, armor_color, 0.55)
		PartKind.ARM:
			_setup_capsule(0.1, 0.38, 0.65, flesh_color, armor_color, 0.2)
		PartKind.LEG:
			_setup_capsule(0.12, 0.42, 0.85, flesh_color, armor_color, 0.25)
		PartKind.ARMOR_SHARD:
			_setup_box(randf_range(0.12, 0.22), 1.4, armor_color, flesh_color, 0.15)
		PartKind.SMALL_GIB:
			_setup_small_gib(flesh_color)


func launch_impulse(
	primary_dir: Vector3,
	force_scale: float = 1.0,
	lateral_spread: float = 0.35,
	upward_bias: float = 0.0
) -> void:
	var flat: Vector3 = Vector3(primary_dir.x, 0.0, primary_dir.z)
	if flat.length_squared() < 0.001:
		flat = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	flat = flat.normalized()

	var lateral: Vector3 = Vector3(
		randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)
	).normalized()
	var out_dir: Vector3 = (flat * (1.0 - lateral_spread) + lateral * lateral_spread).normalized()

	var h_speed: float = randf_range(
		GameBalance.DISMEMBER_HORIZONTAL_FORCE_MIN,
		GameBalance.DISMEMBER_HORIZONTAL_FORCE_MAX
	) * force_scale
	var v_speed: float = randf_range(
		GameBalance.DISMEMBER_UPWARD_FORCE_MIN,
		GameBalance.DISMEMBER_UPWARD_FORCE_MAX
	) + upward_bias
	v_speed = clampf(v_speed, -2.0, GameBalance.DISMEMBER_MAX_UPWARD_SPEED)

	linear_velocity = out_dir * h_speed + Vector3.UP * v_speed
	_clamp_velocity()

	var spin_axis: Vector3 = out_dir.cross(Vector3.UP)
	if spin_axis.length_squared() < 0.01:
		spin_axis = Vector3.RIGHT
	var torque: float = randf_range(
		GameBalance.DISMEMBER_TORQUE_MIN, GameBalance.DISMEMBER_TORQUE_MAX
	)
	apply_torque_impulse(spin_axis.normalized() * torque * randf_range(0.7, 1.15))


func launch_radial(from_origin: Vector3, force_scale: float = 1.0) -> void:
	var away: Vector3 = global_position - from_origin
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	away = away.normalized()
	var dist: float = global_position.distance_to(from_origin)
	var falloff: float = clampf(1.0 - dist / 6.0, 0.35, 1.0)
	launch_impulse(away, force_scale * falloff, 0.22, randf_range(1.0, 4.0))


func _physics_process(_delta: float) -> void:
	if global_position.y < _void_y:
		queue_free()


func _clamp_velocity() -> void:
	var horiz: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horiz.length() > GameBalance.DISMEMBER_MAX_BODY_PART_SPEED:
		horiz = horiz.normalized() * GameBalance.DISMEMBER_MAX_BODY_PART_SPEED
		linear_velocity.x = horiz.x
		linear_velocity.z = horiz.z
	linear_velocity.y = clampf(
		linear_velocity.y,
		-18.0,
		GameBalance.DISMEMBER_MAX_UPWARD_SPEED
	)


func _setup_capsule(
	radius: float,
	height: float,
	part_mass: float,
	flesh: Color,
	armor: Color,
	armor_mix: float
) -> void:
	mass = part_mass
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	_mesh.mesh = cap
	var col := CapsuleShape3D.new()
	col.radius = radius
	col.height = height
	_shape.shape = col
	_apply_material(flesh, armor, armor_mix)


func _setup_sphere(
	radius: float,
	part_mass: float,
	flesh: Color,
	armor: Color,
	armor_mix: float
) -> void:
	mass = part_mass
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	_mesh.mesh = sph
	var col := SphereShape3D.new()
	col.radius = radius
	_shape.shape = col
	_apply_material(flesh, armor, armor_mix)


func _setup_box(size: float, part_mass: float, primary: Color, secondary: Color, mix: float) -> void:
	mass = part_mass
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	_mesh.mesh = box
	var col := BoxShape3D.new()
	col.size = box.size
	_shape.shape = col
	_apply_material(primary, secondary, mix)


func _setup_small_gib(flesh: Color) -> void:
	mass = 0.45
	if randf() > 0.45:
		var box := BoxMesh.new()
		var s: float = randf_range(0.07, 0.14)
		box.size = Vector3.ONE * s
		_mesh.mesh = box
		var col := BoxShape3D.new()
		col.size = box.size
		_shape.shape = col
	else:
		var cap := CapsuleMesh.new()
		cap.radius = randf_range(0.05, 0.09)
		cap.height = randf_range(0.1, 0.18)
		_mesh.mesh = cap
		var col := CapsuleShape3D.new()
		col.radius = cap.radius
		col.height = cap.height
		_shape.shape = col
	var mat := StandardMaterial3D.new()
	mat.albedo_color = flesh.darkened(0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.02, 0.04)
	mat.emission_energy_multiplier = 0.22
	mat.roughness = 0.9
	_mesh.material_override = mat


func _apply_material(flesh: Color, armor: Color, armor_mix: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = flesh.lerp(armor, armor_mix)
	mat.metallic = armor_mix * 0.55
	mat.roughness = lerpf(0.92, 0.72, armor_mix)
	if armor_mix < 0.5:
		mat.emission_enabled = true
		mat.emission = flesh * 0.35
		mat.emission_energy_multiplier = 0.18
	_mesh.material_override = mat
