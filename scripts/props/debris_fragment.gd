## Wall rubble chunk — spawned from WallDestruction plans; heavy local collapse.
class_name DebrisFragment
extends RigidBody3D

const FRAGMENT_SCENE: PackedScene = preload("res://scenes/props/debris_fragment.tscn")

const GROUP_ROUND: String = "round_debris_fragment"
const GROUP_LOW_IMPULSE: String = "low_impulse_fragment"

const VOID_Y: float = GameBalance.VOID_DEATH_Y
const LIFETIME_MIN_SEC: float = 6.0
const LIFETIME_MAX_SEC: float = 10.0
const SPAWN_PROTECTION_SEC: float = 0.25
const MAX_ACTIVE_FRAGMENTS: int = 140

var _knockback_immune_until_sec: float = 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group(GROUP_ROUND)
	add_to_group(GROUP_LOW_IMPULSE)
	collision_layer = 1
	collision_mask = 1
	linear_damp = randf_range(1.8, 3.0)
	angular_damp = randf_range(2.0, 4.0)
	var body_mat := PhysicsMaterial.new()
	body_mat.friction = randf_range(0.7, 1.0)
	body_mat.bounce = randf_range(0.02, 0.08)
	physics_material_override = body_mat
	get_tree().create_timer(randf_range(LIFETIME_MIN_SEC, LIFETIME_MAX_SEC)).timeout.connect(queue_free)


func is_fragment_knockback_immune() -> bool:
	return _time_sec() < _knockback_immune_until_sec


static func spawn_fragment_plans(
	parent: Node,
	plans: Array[Dictionary],
	parent_wall_name: String
) -> void:
	if parent == null:
		return
	_trim_excess_fragments(parent.get_tree())
	for i in plans.size():
		var plan: Dictionary = plans[i]
		var frag: RigidBody3D = FRAGMENT_SCENE.instantiate() as RigidBody3D
		parent.add_child(frag)
		frag.name = "WallFragment_%s_%03d" % [parent_wall_name, i + 1]
		frag.global_transform = plan.get("transform", Transform3D.IDENTITY)
		if frag.has_method("setup_from_plan"):
			frag.call("setup_from_plan", plan)


func setup_from_plan(plan: Dictionary) -> void:
	_knockback_immune_until_sec = _time_sec() + SPAWN_PROTECTION_SEC

	var size: Vector3 = plan.get("size", Vector3(0.2, 0.15, 0.2))
	var volume: float = size.x * size.y * size.z
	mass = clampf(volume * 20.0, 3.0, 8.0)

	_mesh.scale = size
	if _shape.shape is BoxShape3D:
		(_shape.shape as BoxShape3D).size = size

	var material: StandardMaterial3D = plan.get("material") as StandardMaterial3D
	if material:
		_mesh.material_override = material.duplicate()

	var impulse: Vector3 = plan.get("impulse", Vector3.DOWN)
	apply_impulse(impulse)

	var torque: Vector3 = plan.get("torque", Vector3.ZERO)
	if torque.length_squared() > 0.001:
		apply_torque_impulse(torque)


func _physics_process(_delta: float) -> void:
	if global_position.y < VOID_Y - 2.0:
		queue_free()


static func _trim_excess_fragments(tree: SceneTree) -> void:
	var frags: Array[Node] = tree.get_nodes_in_group(GROUP_ROUND)
	while frags.size() > MAX_ACTIVE_FRAGMENTS:
		var oldest: Node = frags[0]
		if is_instance_valid(oldest):
			oldest.queue_free()
		frags.remove_at(0)


func _time_sec() -> float:
	return Time.get_ticks_msec() / 1000.0
