## Broken outer enclosure — partial walls framing arenas over the toxic void.
class_name ArenaPerimeterBuilder
extends RefCounted

enum PieceKind {
	FULL_RUINED,
	HALF,
	COLLAPSED,
	CRACKED_PILLAR,
	HANGING_PANEL,
	BREACH_GAP,
	FRACTURE_STUB,
}

const WALL_GROUP: String = "arena_wall"
const PERIMETER_GROUP: String = "arena_perimeter"
const DECOR_GROUP: String = "arena_perimeter_decor"

const THICKNESS: float = 0.38


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	if template.perimeter == null or not template.perimeter.enabled:
		return

	var cfg: ArenaTemplate.PerimeterConfig = template.perimeter
	_perimeter_wall_index = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(template.arena_name) + template.template_id * 7919

	var decor_root := Node3D.new()
	decor_root.name = "PerimeterDecor"
	parent.add_child(decor_root)
	decor_root.global_position = template.center_position

	_build_side(parent, template, cfg, rng, 0, decor_root)   # +Z
	_build_side(parent, template, cfg, rng, 1, decor_root)   # -Z
	_build_side(parent, template, cfg, rng, 2, decor_root)   # +X
	_build_side(parent, template, cfg, rng, 3, decor_root)   # -X

	if cfg.decor_silhouettes:
		_build_corner_silhouettes(decor_root, cfg, rng)
		_build_distant_breakwalls(decor_root, cfg, rng)

	print("Perimeter enclosure built for %s (%.0f%% coverage target)" % [template.arena_name, cfg.coverage * 100.0])


static var _perimeter_wall_index: int = 0


static func _next_perimeter_wall_index() -> String:
	_perimeter_wall_index += 1
	return "%03d" % _perimeter_wall_index


static func _build_side(
	parent: Node3D,
	template: ArenaTemplate,
	cfg: ArenaTemplate.PerimeterConfig,
	rng: RandomNumberGenerator,
	side_index: int,
	decor_root: Node3D
) -> void:
	var hx: float = cfg.half_extents.x
	var hz: float = cfg.half_extents.y
	var margin: float = cfg.outward_margin
	var slot_count: int = rng.randi_range(4, 6)
	var along_length: float
	var outward_axis: Vector3
	var tangent_axis: Vector3
	var outward_sign: float

	match side_index:
		0:  # +Z
			along_length = hx * 2.0
			outward_axis = Vector3(0.0, 0.0, 1.0)
			tangent_axis = Vector3(1.0, 0.0, 0.0)
			outward_sign = 1.0
		1:  # -Z
			along_length = hx * 2.0
			outward_axis = Vector3(0.0, 0.0, -1.0)
			tangent_axis = Vector3(1.0, 0.0, 0.0)
			outward_sign = -1.0
		2:  # +X
			along_length = hz * 2.0
			outward_axis = Vector3(1.0, 0.0, 0.0)
			tangent_axis = Vector3(0.0, 0.0, 1.0)
			outward_sign = 1.0
		_:
			along_length = hz * 2.0
			outward_axis = Vector3(-1.0, 0.0, 0.0)
			tangent_axis = Vector3(0.0, 0.0, 1.0)
			outward_sign = -1.0

	var slot_width: float = along_length / float(slot_count)
	var start_along: float = -along_length * 0.5 + slot_width * 0.5

	var side_is_open: bool = cfg.ringout_open_sides.has(side_index)

	for slot_i in slot_count:
		var is_corner: bool = slot_i == 0 or slot_i == slot_count - 1
		var is_middle: bool = not is_corner
		var along_t: float = start_along + float(slot_i) * slot_width
		var outward_dist: float = _outward_distance(side_index, hx, hz, margin)
		var local_pos: Vector3 = tangent_axis * along_t + outward_axis * outward_dist

		if side_is_open and is_middle:
			continue

		var place_chance: float = cfg.coverage
		if is_corner:
			place_chance = minf(0.92, place_chance + 0.18)
		elif side_is_open:
			place_chance *= 0.5
		if rng.randf() > place_chance:
			continue

		var kind: PieceKind = _pick_kind(rng, is_corner)
		if kind == PieceKind.BREACH_GAP:
			_place_breach_gap(parent, template, local_pos, side_index, rng, tangent_axis)
			continue
		_place_piece(parent, template, local_pos, kind, side_index, rng)
		if rng.randf() < 0.32:
			_place_fracture_shard(parent, template, local_pos, side_index, rng)

		if is_corner and rng.randf() > 0.5:
			_place_decor_panel(
				decor_root, local_pos + outward_axis * 0.6, kind, rng, side_index
			)


static func _outward_distance(side_index: int, hx: float, hz: float, margin: float) -> float:
	match side_index:
		0:
			return hz + margin
		1:
			return -(hz + margin)
		2:
			return hx + margin
		_:
			return -(hx + margin)


static func _pick_kind(rng: RandomNumberGenerator, is_corner: bool) -> PieceKind:
	var roll: float = rng.randf()
	if is_corner:
		if roll < 0.28:
			return PieceKind.CRACKED_PILLAR
		if roll < 0.48:
			return PieceKind.COLLAPSED
		if roll < 0.58:
			return PieceKind.FRACTURE_STUB
		return PieceKind.FULL_RUINED
	if roll < 0.12:
		return PieceKind.BREACH_GAP
	if roll < 0.28:
		return PieceKind.HALF
	if roll < 0.44:
		return PieceKind.COLLAPSED
	if roll < 0.58:
		return PieceKind.HANGING_PANEL
	if roll < 0.72:
		return PieceKind.CRACKED_PILLAR
	if roll < 0.84:
		return PieceKind.FRACTURE_STUB
	return PieceKind.FULL_RUINED


static func _piece_size(kind: PieceKind, rng: RandomNumberGenerator) -> Vector3:
	match kind:
		PieceKind.HALF:
			return Vector3(
				rng.randf_range(2.8, 5.0), rng.randf_range(3.2, 5.8), THICKNESS
			)
		PieceKind.COLLAPSED:
			return Vector3(
				rng.randf_range(2.5, 4.5), rng.randf_range(4.0, 7.5), THICKNESS
			)
		PieceKind.CRACKED_PILLAR:
			return Vector3(
				rng.randf_range(0.85, 1.35), rng.randf_range(6.5, 11.0), rng.randf_range(0.85, 1.35)
			)
		PieceKind.HANGING_PANEL:
			return Vector3(
				rng.randf_range(2.2, 4.0), rng.randf_range(2.8, 4.2), rng.randf_range(0.12, 0.22)
			)
		PieceKind.FRACTURE_STUB:
			return Vector3(
				rng.randf_range(1.2, 2.4), rng.randf_range(2.5, 4.5), THICKNESS * 0.9
			)
		PieceKind.BREACH_GAP:
			return Vector3(
				rng.randf_range(1.4, 2.2), rng.randf_range(3.5, 6.0), THICKNESS
			)
		_:
			return Vector3(
				rng.randf_range(3.0, 5.5), rng.randf_range(6.5, 11.0), THICKNESS
			)


static func _orient_size_for_side(size: Vector3, side_index: int) -> Vector3:
	if side_index >= 2:
		return Vector3(size.z, size.y, size.x)
	return size


static func rng_free_y_hanging(panel_h: float) -> float:
	return 2.2 + panel_h * 0.35


static func _piece_rotation(kind: PieceKind, rng: RandomNumberGenerator, side_index: int) -> Vector3:
	var rot := Vector3.ZERO
	if kind == PieceKind.COLLAPSED:
		rot.x = rng.randf_range(-0.35, 0.25)
		rot.z = rng.randf_range(-0.2, 0.2)
	elif kind == PieceKind.HANGING_PANEL:
		rot.x = rng.randf_range(0.15, 0.45)
	return rot


static func _place_breach_gap(
	parent: Node3D,
	template: ArenaTemplate,
	local_pos: Vector3,
	side_index: int,
	rng: RandomNumberGenerator,
	tangent_axis: Vector3
) -> void:
	var stub_kind: PieceKind = PieceKind.FRACTURE_STUB if rng.randf() > 0.5 else PieceKind.COLLAPSED
	var gap: float = rng.randf_range(2.8, 4.5)
	for sign in [-1.0, 1.0]:
		var offset: Vector3 = local_pos + tangent_axis * sign * gap
		_place_piece(parent, template, offset, stub_kind, side_index, rng)


static func _place_fracture_shard(
	parent: Node3D,
	template: ArenaTemplate,
	local_pos: Vector3,
	side_index: int,
	rng: RandomNumberGenerator
) -> void:
	var size: Vector3 = _orient_size_for_side(
		Vector3(
			rng.randf_range(0.35, 0.85),
			rng.randf_range(0.5, 1.2),
			rng.randf_range(0.25, 0.55)
		),
		side_index
	)
	local_pos.y = size.y * 0.5 + rng.randf_range(-0.2, 0.8)
	var mat: StandardMaterial3D = _pick_material(rng)
	mat.albedo_color = mat.albedo_color.darkened(0.12)
	var rot := Vector3(rng.randf_range(-0.4, 0.2), rng.randf_range(-0.3, 0.3), rng.randf_range(-0.25, 0.25))
	_place_destructible_panel(
		parent, template.center_position, local_pos, size, mat, rot, PieceKind.FRACTURE_STUB
	)


static func _place_piece(
	parent: Node3D,
	template: ArenaTemplate,
	local_pos: Vector3,
	kind: PieceKind,
	side_index: int,
	rng: RandomNumberGenerator
) -> void:
	var size: Vector3 = _orient_size_for_side(_piece_size(kind, rng), side_index)
	var center_y: float
	match kind:
		PieceKind.HANGING_PANEL:
			center_y = rng_free_y_hanging(size.y) + 2.5
		PieceKind.FRACTURE_STUB:
			center_y = size.y * 0.45
		_:
			center_y = size.y * 0.5
	local_pos.y = center_y

	var mat: StandardMaterial3D = _pick_material(rng)
	var rot: Vector3 = _piece_rotation(kind, rng, side_index)

	_place_destructible_panel(parent, template.center_position, local_pos, size, mat, rot, kind)


static func _place_destructible_panel(
	parent: Node3D,
	arena_center: Vector3,
	local_pos: Vector3,
	size: Vector3,
	mat: StandardMaterial3D,
	rot: Vector3,
	piece_kind: PieceKind
) -> void:
	var wall_kind: DestructibleWall.WallKind = DestructibleWall.kind_from_perimeter_piece(piece_kind)
	if piece_kind == PieceKind.FULL_RUINED:
		wall_kind = DestructibleWall.WallKind.OUTER_HEAVY
	var index_suffix: String = _next_perimeter_wall_index()
	var body := DestructibleWall.new()
	body.collision_layer = 1
	body.collision_mask = 1

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape

	body.add_child(mesh_inst)
	body.add_child(col)
	parent.add_child(body)
	body.global_position = arena_center + local_pos
	body.rotation = rot
	body.setup_wall(wall_kind, mesh_inst, size, true, index_suffix)


static func _place_decor_panel(
	decor_root: Node3D,
	local_pos: Vector3,
	kind: PieceKind,
	rng: RandomNumberGenerator,
	side_index: int
) -> void:
	var size: Vector3 = _orient_size_for_side(_piece_size(kind, rng), side_index) * Vector3(1.05, 1.15, 1.0)
	local_pos.y = rng.randf_range(4.0, 5.8)
	var mat: StandardMaterial3D = _pick_material(rng)
	mat.albedo_color = mat.albedo_color.darkened(0.25)
	var rot: Vector3 = _piece_rotation(kind, rng, side_index)
	_add_decor_mesh(decor_root, local_pos, size, mat, rot)


static func _build_corner_silhouettes(
	decor_root: Node3D, cfg: ArenaTemplate.PerimeterConfig, rng: RandomNumberGenerator
) -> void:
	var hx: float = cfg.half_extents.x + cfg.outward_margin * 0.6
	var hz: float = cfg.half_extents.y + cfg.outward_margin * 0.6
	var corners: Array[Vector3] = [
		Vector3(hx, 0.0, hz),
		Vector3(-hx, 0.0, hz),
		Vector3(hx, 0.0, -hz),
		Vector3(-hx, 0.0, -hz),
	]
	for corner in corners:
		if rng.randf() > 0.35:
			continue
		var mat: StandardMaterial3D = _mat_stone()
		mat.albedo_color = mat.albedo_color.darkened(0.35)
		var size := Vector3(
			rng.randf_range(1.0, 1.8), rng.randf_range(4.5, 6.2), rng.randf_range(1.0, 1.8)
		)
		var pos: Vector3 = corner + Vector3(
			signf(corner.x) * 0.8, size.y * 0.5, signf(corner.z) * 0.8
		)
		_add_decor_mesh(decor_root, pos, size, mat, Vector3.ZERO)


static func _build_distant_breakwalls(
	decor_root: Node3D, cfg: ArenaTemplate.PerimeterConfig, rng: RandomNumberGenerator
) -> void:
	var hx: float = cfg.half_extents.x + cfg.outward_margin + 3.5
	var hz: float = cfg.half_extents.y + cfg.outward_margin + 3.5
	var placements: Array[Dictionary] = [
		{"pos": Vector3(0.0, 2.8, hz + 2.5), "size": Vector3(14.0, 5.5, 0.35)},
		{"pos": Vector3(-(hx + 2.0), 2.2, 0.0), "size": Vector3(0.35, 4.8, 10.0)},
		{"pos": Vector3(hx + 2.0, 3.0, -hz * 0.4), "size": Vector3(0.4, 5.0, 8.0)},
	]
	for data in placements:
		if rng.randf() > 0.55:
			continue
		var mat: StandardMaterial3D = _mat_concrete()
		mat.albedo_color = mat.albedo_color.darkened(0.4)
		_add_decor_mesh(
			decor_root,
			data.pos,
			data.size,
			mat,
			Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.06, 0.06))
		)


static func _add_decor_mesh(
	parent: Node3D,
	local_pos: Vector3,
	size: Vector3,
	mat: StandardMaterial3D,
	rot: Vector3
) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = local_pos
	mesh_inst.rotation = rot
	mesh_inst.add_to_group(DECOR_GROUP)
	parent.add_child(mesh_inst)


static func _pick_material(rng: RandomNumberGenerator) -> StandardMaterial3D:
	var roll: float = rng.randf()
	if roll < 0.4:
		return _mat_concrete()
	if roll < 0.7:
		return _mat_metal()
	return _mat_stone()


static func _mat_concrete() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.092, 0.1)
	mat.roughness = 0.94
	mat.metallic = 0.08
	return mat


static func _mat_metal() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.11)
	mat.roughness = 0.82
	mat.metallic = 0.55
	return mat


static func _mat_stone() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.052, 0.06)
	mat.roughness = 0.97
	mat.metallic = 0.12
	return mat
