## Large destructible cover piece — blocks shots until destroyed (RigidBody cover).
class_name DebrisChunk
extends RigidBody3D

enum CoverType { BLOCK, WALL_SLAB, BROKEN_PILLAR, FALLEN_BEAM }

const COVER_TO_WALL: Dictionary = {
	CoverType.BLOCK: DestructibleWall.WallKind.HALF,
	CoverType.WALL_SLAB: DestructibleWall.WallKind.THIN_SLAB,
	CoverType.BROKEN_PILLAR: DestructibleWall.WallKind.PILLAR,
	CoverType.FALLEN_BEAM: DestructibleWall.WallKind.THIN_SLAB,
}

const VOID_Y: float = GameBalance.VOID_DEATH_Y
const DECK_TOP_Y: float = 0.14

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _shape: CollisionShape3D = $CollisionShape3D

var _cover_type: CoverType = CoverType.BLOCK
var _wall_kind: DestructibleWall.WallKind = DestructibleWall.WallKind.HALF
var _max_health: int = 80
var _cover_health: int = 80
var _piece_size: Vector3 = Vector3.ONE
var _broken: bool = false
var _destroying: bool = false
var _base_material: StandardMaterial3D
var _last_hit_world: Vector3 = Vector3.ZERO
var _last_hit_direction: Vector3 = Vector3.ZERO
var _last_damage_source: String = ""

var is_perforable: bool = false
var railgun_holes: Array = []


func _ready() -> void:
	add_to_group("round_debris")
	add_to_group(DestructibleWall.DESTRUCTIBLE_GROUP)
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
	_wall_kind = COVER_TO_WALL.get(cover_type, DestructibleWall.WallKind.HALF)
	name = "DestructibleWall_%s" % DestructibleWall.kind_display_name(_wall_kind)
	_max_health = DestructibleWall.HEALTH.get(_wall_kind, 80)
	_cover_health = _max_health
	add_to_group(DestructibleWall.DESTRUCTIBLE_GROUP)
	var scale_vec: Vector3 = _scale_for_type(cover_type)
	_piece_size = scale_vec
	_mesh.scale = scale_vec
	if _shape.shape is BoxShape3D:
		(_shape.shape as BoxShape3D).size = scale_vec

	mass = _mass_for_type(cover_type)
	var mat: StandardMaterial3D = _material_for_type(cover_type)
	_mesh.material_override = mat
	_base_material = mat
	rotation = _rotation_for_type(cover_type)

	global_position.y = DECK_TOP_Y + scale_vec.y * 0.5

	angular_velocity = _spin_for_type(cover_type)


func is_destructible_wall() -> bool:
	return true


func get_piece_size() -> Vector3:
	return _piece_size


func add_railgun_perforation(
	_hit_world: Vector3, _beam_dir: Vector3, _surface_normal: Vector3
) -> bool:
	return false


func get_wall_kind() -> DestructibleWall.WallKind:
	return _wall_kind


func damage_cover(
	amount: int,
	_attacker: Node = null,
	direction: Vector3 = Vector3.ZERO,
	force: float = 0.0,
	source: String = "",
	hit_origin: Vector3 = Vector3.ZERO,
	blast_radius: float = 0.0
) -> void:
	if _broken or _destroying or amount <= 0:
		return

	_record_hit(hit_origin, direction, source)

	var damage: int = DestructibleWall.resolve_weapon_damage(
		source, amount, hit_origin, global_position, blast_radius
	)
	_cover_health = maxi(0, _cover_health - damage)
	_update_damage_stage()
	print("Wall damaged: %s health %d/%d" % [name, _cover_health, _max_health])

	if force > 0.0 and direction.length_squared() > 0.001:
		var offset: Vector3 = direction.normalized() * 0.2
		apply_impulse(
			PushHitResolver.compute_rigidbody_impulse(direction, force * 0.35, mass), offset
		)

	if _cover_health <= 0:
		break_apart(direction, force)


func _record_hit(hit_origin: Vector3, direction: Vector3, source: String) -> void:
	if hit_origin.length_squared() > 0.001:
		_last_hit_world = hit_origin
	elif direction.length_squared() > 0.001:
		_last_hit_world = global_position + direction.normalized() * 0.5
	else:
		_last_hit_world = global_position
	if direction.length_squared() > 0.001:
		_last_hit_direction = direction.normalized()
	_last_damage_source = source


func _update_damage_stage() -> void:
	if _max_health <= 0 or _base_material == null:
		return
	var ratio: float = float(_cover_health) / float(_max_health)
	WallDestruction.apply_damage_visual(self, _base_material, ratio)


func break_apart(hit_direction: Vector3 = Vector3.ZERO, _force: float = 0.0) -> void:
	if _broken or _destroying:
		return
	_broken = true
	_destroying = true

	if hit_direction.length_squared() > 0.001:
		_last_hit_direction = hit_direction.normalized()

	var parent: Node = get_parent()
	if parent == null:
		parent = get_tree().current_scene

	var payload := BreakPayload.new()
	payload.parent = parent
	payload.wall_node = self
	payload.wall_name = name
	payload.piece_size = _piece_size
	payload.kind = _wall_kind
	payload.material = _base_material.duplicate() if _base_material else null
	payload.hit_world = _last_hit_world
	payload.hit_direction = _last_hit_direction
	payload.damage_source = _last_damage_source

	WallDestruction.start_staged_break(self, payload)


func _physics_process(_delta: float) -> void:
	if global_position.y < VOID_Y - 2.0:
		queue_free()


func _type_label_for(cover_type: CoverType) -> String:
	match cover_type:
		CoverType.WALL_SLAB:
			return "WallSlab"
		CoverType.BROKEN_PILLAR:
			return "Pillar"
		CoverType.FALLEN_BEAM:
			return "Beam"
	return "Block"


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
