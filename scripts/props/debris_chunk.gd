## Large destructible cover piece — blocks shots until destroyed.
class_name DebrisChunk
extends RigidBody3D

enum CoverType { BLOCK, WALL_SLAB, BROKEN_PILLAR, FALLEN_BEAM }

const VOID_Y: float = GameBalance.VOID_DEATH_Y
const DECK_TOP_Y: float = 0.14

const COVER_HEALTH: Dictionary = {
	CoverType.BLOCK: 60,
	CoverType.WALL_SLAB: 100,
	CoverType.BROKEN_PILLAR: 80,
	CoverType.FALLEN_BEAM: 70,
}

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D

var _cover_type: CoverType = CoverType.BLOCK
var _max_health: int = 60
var _cover_health: int = 60
var _broken: bool = false


func _ready() -> void:
	add_to_group("round_debris")
	collision_layer = 1
	collision_mask = 1
	var body_mat := PhysicsMaterial.new()
	body_mat.friction = 0.88
	body_mat.bounce = 0.08
	physics_material_override = body_mat
	linear_damp = randf_range(0.4, 0.8)
	angular_damp = randf_range(0.5, 1.0)


func setup_cover(cover_type: CoverType) -> void:
	_cover_type = cover_type
	_max_health = COVER_HEALTH.get(cover_type, 60)
	_cover_health = _max_health

	var scale_vec: Vector3 = _scale_for_type(cover_type)
	_mesh.scale = scale_vec
	if _shape.shape is BoxShape3D:
		(_shape.shape as BoxShape3D).size = scale_vec

	mass = _mass_for_type(cover_type)
	_mesh.material_override = _material_for_type(cover_type)
	rotation = _rotation_for_type(cover_type)

	global_position.y = DECK_TOP_Y + scale_vec.y * 0.5

	angular_velocity = _spin_for_type(cover_type)


func damage_cover(
	amount: int,
	_attacker: Node = null,
	direction: Vector3 = Vector3.ZERO,
	force: float = 0.0,
	source: String = ""
) -> void:
	if _broken or amount <= 0:
		return

	var damage_mult: float = 1.0
	match source:
		"bazooka_explosion":
			damage_mult = 1.65
		"bazooka_direct":
			damage_mult = 1.3
		"shotgun":
			damage_mult = 0.85

	_cover_health = maxi(0, _cover_health - int(round(float(amount) * damage_mult)))
	print(
		"Cover health: %d / %d (%s, hit by %s)"
		% [_cover_health, _max_health, _type_label(), source if source != "" else "weapon"]
	)

	if force > 0.0 and direction.length_squared() > 0.001:
		var offset: Vector3 = direction.normalized() * 0.2
		apply_impulse(
			PushHitResolver.compute_rigidbody_impulse(direction, force * 0.35, mass), offset
		)

	if _cover_health <= 0:
		_break_apart()


func _break_apart() -> void:
	if _broken:
		return
	_broken = true
	var parent: Node = get_parent()
	if parent == null:
		parent = get_tree().current_scene
	var mat: StandardMaterial3D = _mesh.material_override as StandardMaterial3D
	var count: int = randi_range(4, 8)
	DebrisFragment.spawn_burst(parent, global_position, count, mat)
	print("Cover destroyed: %s" % _type_label())
	queue_free()


func _physics_process(_delta: float) -> void:
	if global_position.y < VOID_Y - 2.0:
		queue_free()


func _type_label() -> String:
	match _cover_type:
		CoverType.WALL_SLAB:
			return "WALL_SLAB"
		CoverType.BROKEN_PILLAR:
			return "BROKEN_PILLAR"
		CoverType.FALLEN_BEAM:
			return "FALLEN_BEAM"
	return "BLOCK"


func _scale_for_type(cover_type: CoverType) -> Vector3:
	match cover_type:
		CoverType.WALL_SLAB:
			return Vector3(
				randf_range(2.0, 3.5), randf_range(1.6, 2.8), randf_range(0.25, 0.5)
			)
		CoverType.BROKEN_PILLAR:
			return Vector3(
				randf_range(0.7, 1.1), randf_range(1.8, 3.0), randf_range(0.7, 1.1)
			)
		CoverType.FALLEN_BEAM:
			return Vector3(
				randf_range(2.5, 4.5), randf_range(0.3, 0.6), randf_range(0.4, 0.8)
			)
	return Vector3(
		randf_range(0.8, 1.5), randf_range(0.8, 1.6), randf_range(0.4, 1.2)
	)


func _mass_for_type(cover_type: CoverType) -> float:
	match cover_type:
		CoverType.WALL_SLAB:
			return randf_range(8.0, 14.0)
		CoverType.BROKEN_PILLAR:
			return randf_range(6.0, 10.0)
		CoverType.FALLEN_BEAM:
			return randf_range(5.0, 9.0)
	return randf_range(4.0, 6.0)


func _rotation_for_type(cover_type: CoverType) -> Vector3:
	match cover_type:
		CoverType.WALL_SLAB:
			return Vector3(
				randf_range(-0.12, 0.12), randf_range(0.0, TAU), randf_range(-0.18, 0.18)
			)
		CoverType.BROKEN_PILLAR:
			return Vector3(
				randf_range(-0.08, 0.08), randf_range(0.0, TAU), randf_range(-0.08, 0.08)
			)
		CoverType.FALLEN_BEAM:
			return Vector3(
				randf_range(-0.25, 0.25), randf_range(0.0, TAU), randf_range(0.0, PI * 0.5)
			)
	return Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))


func _spin_for_type(cover_type: CoverType) -> Vector3:
	var strength: float
	match cover_type:
		CoverType.WALL_SLAB, CoverType.BROKEN_PILLAR:
			strength = randf_range(0.15, 0.6)
		CoverType.FALLEN_BEAM:
			strength = randf_range(0.4, 1.2)
		_:
			strength = randf_range(0.5, 1.5)
	return Vector3(
		randf_range(-1.0, 1.0), randf_range(-0.4, 0.4), randf_range(-1.0, 1.0)
	) * strength


func _material_for_type(cover_type: CoverType) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = randf_range(0.84, 0.96)
	match cover_type:
		CoverType.WALL_SLAB:
			mat.albedo_color = Color(
				randf_range(0.1, 0.16), randf_range(0.1, 0.15), randf_range(0.11, 0.17)
			)
		CoverType.BROKEN_PILLAR:
			mat.albedo_color = Color(
				randf_range(0.15, 0.22), randf_range(0.14, 0.2), randf_range(0.16, 0.22)
			)
		CoverType.FALLEN_BEAM:
			mat.albedo_color = Color(
				randf_range(0.2, 0.3), randf_range(0.12, 0.18), randf_range(0.08, 0.14)
			)
			mat.metallic = randf_range(0.5, 0.8)
		_:
			mat.albedo_color = Color(
				randf_range(0.12, 0.18), randf_range(0.11, 0.16), randf_range(0.12, 0.17)
			)
	return mat
