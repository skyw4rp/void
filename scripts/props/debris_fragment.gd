## Small break-off piece from destroyed cover.
class_name DebrisFragment
extends RigidBody3D

const FRAGMENT_SCENE: PackedScene = preload("res://scenes/props/debris_fragment.tscn")

const VOID_Y: float = GameBalance.VOID_DEATH_Y
const LIFETIME_MIN_SEC: float = 4.0
const LIFETIME_MAX_SEC: float = 6.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("round_debris_fragment")
	collision_layer = 1
	collision_mask = 1
	linear_damp = 0.55
	angular_damp = 0.7
	var body_mat := PhysicsMaterial.new()
	body_mat.friction = 0.8
	body_mat.bounce = 0.1
	physics_material_override = body_mat
	get_tree().create_timer(randf_range(LIFETIME_MIN_SEC, LIFETIME_MAX_SEC)).timeout.connect(queue_free)


static func spawn_burst(parent: Node, origin: Vector3, count: int, material: StandardMaterial3D) -> void:
	for _i in count:
		var frag: RigidBody3D = FRAGMENT_SCENE.instantiate() as RigidBody3D
		parent.add_child(frag)
		var offset := Vector3(
			randf_range(-0.8, 0.8), randf_range(-0.3, 0.6), randf_range(-0.8, 0.8)
		)
		frag.global_position = origin + offset
		if frag.has_method("setup_fragment"):
			frag.call("setup_fragment", material)


func setup_fragment(material: StandardMaterial3D) -> void:
	mass = randf_range(0.8, 2.2)
	var scale_vec := Vector3.ONE * randf_range(0.18, 0.42)
	_mesh.scale = scale_vec
	if _shape.shape is BoxShape3D:
		(_shape.shape as BoxShape3D).size = scale_vec
	if material:
		_mesh.material_override = material.duplicate()
	rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
	var blast := Vector3(
		randf_range(-1.0, 1.0), randf_range(0.2, 1.0), randf_range(-1.0, 1.0)
	).normalized()
	apply_impulse(blast * randf_range(2.0, 6.0))


func _physics_process(_delta: float) -> void:
	if global_position.y < VOID_Y - 2.0:
		queue_free()
