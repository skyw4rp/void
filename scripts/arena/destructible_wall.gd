## Static arena wall — staged fracture, damage visuals, proportional rubble.
class_name DestructibleWall
extends StaticBody3D

enum WallKind { HALF, FULL, PILLAR, THIN_SLAB, OUTER_HEAVY }

const HEALTH: Dictionary = {
	WallKind.HALF: 80,
	WallKind.FULL: 140,
	WallKind.PILLAR: 120,
	WallKind.THIN_SLAB: 70,
	WallKind.OUTER_HEAVY: 200,
}

const WALL_GROUP: String = "arena_wall"
const DESTRUCTIBLE_GROUP: String = "destructible_wall"
const PERFORABLE_GROUP: String = "perforable_wall"

var is_perforable: bool = false
var railgun_holes: Array = []

var _kind: WallKind = WallKind.FULL
var _max_health: int = 140
var _health: int = 140
var _broken: bool = false
var _destroying: bool = false
var _mesh: MeshInstance3D
var _piece_size: Vector3 = Vector3.ONE
var _base_material: StandardMaterial3D

var _last_hit_world: Vector3 = Vector3.ZERO
var _last_hit_direction: Vector3 = Vector3.ZERO
var _last_damage_source: String = ""


func _ready() -> void:
	add_to_group(WALL_GROUP)
	add_to_group(DESTRUCTIBLE_GROUP)
	if is_perforable:
		add_to_group(PERFORABLE_GROUP)


func setup_wall(
	kind: WallKind,
	mesh: MeshInstance3D,
	piece_size: Vector3 = Vector3.ONE,
	add_perimeter_group: bool = false,
	name_suffix: String = ""
) -> void:
	_kind = kind
	_mesh = mesh
	_piece_size = piece_size
	_max_health = HEALTH.get(kind, 140)
	_health = _max_health
	_broken = false
	_destroying = false
	is_perforable = false
	if mesh and mesh.material_override is StandardMaterial3D:
		_base_material = mesh.material_override as StandardMaterial3D
	if name_suffix != "":
		name = "DestructibleWall_%s_%s" % [kind_display_name(kind), name_suffix]
	ensure_named()
	add_to_group(DESTRUCTIBLE_GROUP)
	if add_perimeter_group:
		add_to_group("arena_perimeter")


func get_wall_kind() -> WallKind:
	return _kind


func is_destructible_wall() -> bool:
	return true


func get_piece_size() -> Vector3:
	return _piece_size


func add_railgun_perforation(
	_hit_world: Vector3, _beam_dir: Vector3, _surface_normal: Vector3
) -> bool:
	return false


func clear_railgun_perforations() -> void:
	railgun_holes.clear()


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

	ensure_named()
	_record_hit(hit_origin, direction, source)

	var damage: int = resolve_weapon_damage(
		source, amount, hit_origin, global_position, blast_radius
	)
	_health = maxi(0, _health - damage)
	_update_damage_stage()

	print("Wall damaged: %s health %d/%d" % [name, _health, _max_health])

	if _health <= 0:
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
	if _max_health <= 0:
		return
	var ratio: float = float(_health) / float(_max_health)
	if _base_material:
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
	payload.kind = _kind
	payload.material = _base_material.duplicate() if _base_material else null
	payload.hit_world = _last_hit_world
	payload.hit_direction = _last_hit_direction
	payload.damage_source = _last_damage_source

	WallDestruction.start_staged_break(self, payload)


func ensure_named() -> void:
	if not _has_anonymous_name():
		return
	var suffix: String = "%d" % (get_instance_id() % 100000)
	name = "DestructibleWall_%s_%s" % [kind_display_name(_kind), suffix]
	print("WARNING: Anonymous destructible wall auto-renamed to %s" % name)


func _has_anonymous_name() -> bool:
	return name.is_empty() or name.begins_with("@") or name == "StaticBody3D" or name == "DestructibleWall"


static func fragment_count_for_size(piece_size: Vector3) -> int:
	return WallDestruction.chunk_count_for(WallKind.FULL, piece_size)


static func resolve_weapon_damage(
	source: String,
	passed_amount: int,
	hit_origin: Vector3 = Vector3.ZERO,
	target_position: Vector3 = Vector3.ZERO,
	blast_radius: float = 0.0
) -> int:
	match source:
		"railgun":
			return WeaponDefs.WALL_DAMAGE_RAILGUN
		"shotgun":
			return WeaponDefs.WALL_DAMAGE_SHOTGUN_PELLET
		"bazooka_direct":
			return WeaponDefs.WALL_DAMAGE_BAZOOKA_DIRECT
		"bazooka_explosion":
			if blast_radius > 0.0:
				return WeaponDefs.wall_explosion_damage_at_distance(
					WeaponDefs.WALL_DAMAGE_BAZOOKA_EXPLOSION_MAX,
					hit_origin,
					target_position,
					blast_radius
				)
			return mini(passed_amount, WeaponDefs.WALL_DAMAGE_BAZOOKA_EXPLOSION_MAX)
		_:
			return passed_amount


static func infer_kind_from_size(size: Vector3) -> WallKind:
	var thin: float = minf(size.x, minf(size.y, size.z))
	if thin < 0.35:
		return WallKind.THIN_SLAB
	if size.y < 1.6:
		return WallKind.HALF
	var footprint: float = maxf(size.x, size.z)
	if size.y > 2.0 and footprint < 1.5:
		return WallKind.PILLAR
	return WallKind.FULL


static func kind_from_perimeter_piece(piece_kind: int) -> WallKind:
	match piece_kind:
		0:
			return WallKind.FULL
		1:
			return WallKind.HALF
		2:
			return WallKind.THIN_SLAB
		3:
			return WallKind.PILLAR
		4:
			return WallKind.THIN_SLAB
		5:
			return WallKind.THIN_SLAB
		6:
			return WallKind.HALF
		_:
			return WallKind.OUTER_HEAVY


static func spawn_break_fragments(
	parent: Node,
	origin: Vector3,
	piece_size: Vector3,
	material: StandardMaterial3D,
	hit_direction: Vector3 = Vector3.ZERO
) -> void:
	var payload := BreakPayload.new()
	payload.parent = parent
	payload.piece_size = piece_size
	payload.kind = infer_kind_from_size(piece_size)
	payload.material = material
	payload.hit_world = origin
	payload.hit_direction = hit_direction
	var plans: Array[Dictionary] = WallDestruction.build_fragment_plans(payload)
	DebrisFragment.spawn_fragment_plans(parent, plans, "Wall")


static func kind_display_name(kind: WallKind) -> String:
	match kind:
		WallKind.HALF:
			return "Half"
		WallKind.PILLAR:
			return "Pillar"
		WallKind.THIN_SLAB:
			return "ThinSlab"
		WallKind.OUTER_HEAVY:
			return "Outer"
	return "Full"
