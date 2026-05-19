## Megastructure Pass — layered distant VOID ruins, sparse lights, ambient void events.
class_name ArenaMegastructurePass
extends RefCounted

const GROUP: String = "arena_megastructure"
const GROUP_LIGHT: String = "arena_megastructure_light"

enum MegaKind {
	SUSPENDED_BRIDGE,
	BRUTALIST_TOWER,
	BROKEN_RING,
	VERTICAL_SHAFT,
	INDUSTRIAL_PILLAR,
	FRACTURED_WALL,
	COLLAPSED_DECK,
	IMPOSSIBLE_ARCH,
}

enum DepthLayer { NEAR = 1, MID = 2, FAR = 3 }

const LAYER_ALPHA: Dictionary = {
	DepthLayer.NEAR: 0.82,
	DepthLayer.MID: 0.56,
	DepthLayer.FAR: 0.34,
}

const LAYER_RADIUS: Dictionary = {
	DepthLayer.NEAR: Vector2(52.0, 72.0),
	DepthLayer.MID: Vector2(78.0, 108.0),
	DepthLayer.FAR: Vector2(115.0, 168.0),
}

const LAYER_HEIGHT: Dictionary = {
	DepthLayer.NEAR: Vector2(30.0, 58.0),
	DepthLayer.MID: Vector2(42.0, 78.0),
	DepthLayer.FAR: Vector2(58.0, 120.0),
}


static func build(parent: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator) -> void:
	if parent == null or template == null:
		return

	var root := Node3D.new()
	root.name = "ArenaMegastructurePass"
	parent.add_child(root)

	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var play_radius: float = maxf(bounds.danger_half_x, bounds.danger_half_z) + 22.0

	var layer_roots: Dictionary = {
		DepthLayer.NEAR: _make_layer_root(root, "Layer1_NearSilhouettes"),
		DepthLayer.MID: _make_layer_root(root, "Layer2_MidStructures"),
		DepthLayer.FAR: _make_layer_root(root, "Layer3_GiantDistant"),
	}

	var total: int = rng.randi_range(3, 8)
	var layer_plan: Array[DepthLayer] = _plan_layers(total, rng)
	var anchors: Array[Vector3] = []
	var built: int = 0

	for layer in layer_plan:
		var anchor: Vector3 = _pick_anchor(play_radius, layer, rng, anchors)
		if anchor == Vector3.INF:
			continue
		anchors.append(anchor)
		var kind: MegaKind = _pick_kind(rng, layer)
		var cluster: Node3D = _spawn_cluster(layer_roots[layer], anchor, kind, layer, template, rng)
		if cluster != null:
			built += 1

	if built < 3:
		for _i in 3 - built:
			var layer: DepthLayer = DepthLayer.FAR if rng.randf() > 0.5 else DepthLayer.MID
			var anchor: Vector3 = _pick_anchor(play_radius, layer, rng, anchors)
			if anchor == Vector3.INF:
				continue
			anchors.append(anchor)
			_spawn_cluster(
				layer_roots[layer],
				anchor,
				_pick_kind(rng, layer),
				layer,
				template,
				rng
			)

	_spawn_sparse_lights(root, rng, anchors)
	_attach_void_events(root, template, rng, play_radius)

	print("Megastructure Pass: %d distant clusters (3 depth layers)" % built)


static func kind_names() -> PackedStringArray:
	return PackedStringArray([
		"SuspendedBridge",
		"BrutalistTower",
		"BrokenRing",
		"VerticalShaft",
		"IndustrialPillar",
		"FracturedWall",
		"CollapsedDeck",
		"ImpossibleArch",
	])


static func _make_layer_root(parent: Node3D, layer_name: String) -> Node3D:
	var layer := Node3D.new()
	layer.name = layer_name
	parent.add_child(layer)
	return layer


static func _plan_layers(total: int, rng: RandomNumberGenerator) -> Array[DepthLayer]:
	var plan: Array[DepthLayer] = []
	var near_n: int = clampi(rng.randi_range(1, 2), 0, total)
	var mid_n: int = clampi(rng.randi_range(1, maxi(1, total - near_n)), 0, total - near_n)
	var far_n: int = maxi(0, total - near_n - mid_n)
	for _i in near_n:
		plan.append(DepthLayer.NEAR)
	for _i in mid_n:
		plan.append(DepthLayer.MID)
	for _i in far_n:
		plan.append(DepthLayer.FAR)
	plan.shuffle()
	return plan


static func _pick_anchor(
	play_radius: float,
	layer: DepthLayer,
	rng: RandomNumberGenerator,
	existing: Array[Vector3]
) -> Vector3:
	var rad_range: Vector2 = LAYER_RADIUS[layer]
	for _attempt in 14:
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(rad_range.x, rad_range.y)
		dist = maxf(dist, play_radius + 8.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var ok: bool = true
		for other in existing:
			if Vector2(pos.x - other.x, pos.z - other.z).length() < 18.0:
				ok = false
				break
		if ok:
			return pos
	return Vector3.INF


static func _pick_kind(rng: RandomNumberGenerator, layer: DepthLayer) -> MegaKind:
	var pool: Array[int] = []
	match layer:
		DepthLayer.NEAR:
			pool = [
				MegaKind.FRACTURED_WALL, MegaKind.INDUSTRIAL_PILLAR,
				MegaKind.COLLAPSED_DECK, MegaKind.VERTICAL_SHAFT,
			]
		DepthLayer.MID:
			pool = [
				MegaKind.SUSPENDED_BRIDGE, MegaKind.BRUTALIST_TOWER,
				MegaKind.IMPOSSIBLE_ARCH, MegaKind.BROKEN_RING,
			]
		_:
			pool = [
				MegaKind.BRUTALIST_TOWER, MegaKind.BROKEN_RING,
				MegaKind.VERTICAL_SHAFT, MegaKind.IMPOSSIBLE_ARCH,
				MegaKind.SUSPENDED_BRIDGE,
			]
	return pool[rng.randi_range(0, pool.size() - 1)] as MegaKind


static func _spawn_cluster(
	parent: Node3D,
	anchor: Vector3,
	kind: MegaKind,
	layer: DepthLayer,
	template: ArenaTemplate,
	rng: RandomNumberGenerator
) -> Node3D:
	var cluster := Node3D.new()
	cluster.name = "Mega_%s" % kind_names()[kind]
	cluster.position = anchor
	cluster.add_to_group(GROUP)
	parent.add_child(cluster)

	var height: float = rng.randf_range(LAYER_HEIGHT[layer].x, LAYER_HEIGHT[layer].y)
	var mat: StandardMaterial3D = _silhouette_material(layer, rng)

	match kind:
		MegaKind.SUSPENDED_BRIDGE:
			_build_suspended_bridge(cluster, height, mat, rng)
		MegaKind.BRUTALIST_TOWER:
			_build_brutalist_tower(cluster, height, mat, rng)
		MegaKind.BROKEN_RING:
			_build_broken_ring(cluster, height, mat, rng)
		MegaKind.VERTICAL_SHAFT:
			_build_vertical_shaft(cluster, height, mat, rng)
		MegaKind.INDUSTRIAL_PILLAR:
			_build_industrial_pillar(cluster, height, mat, rng)
		MegaKind.FRACTURED_WALL:
			_build_fractured_wall(cluster, height, mat, rng)
		MegaKind.COLLAPSED_DECK:
			_build_collapsed_deck(cluster, height, mat, rng)
		MegaKind.IMPOSSIBLE_ARCH:
			_build_impossible_arch(cluster, height, mat, rng)

	if rng.randf() < 0.55:
		_attach_chain(cluster, kind, height, layer, mat, rng)

	cluster.rotation.y = rng.randf() * TAU
	return cluster


static func _silhouette_material(layer: DepthLayer, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var alpha: float = float(LAYER_ALPHA[layer]) * rng.randf_range(0.92, 1.0)
	mat.albedo_color = Color(0.028, 0.032, 0.038, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.98
	mat.metallic = 0.08
	mat.emission_enabled = true
	mat.emission = Color(
		rng.randf_range(0.02, 0.06),
		rng.randf_range(0.04, 0.09),
		rng.randf_range(0.05, 0.11)
	)
	mat.emission_energy_multiplier = rng.randf_range(0.08, 0.22) * (1.0 - float(layer - 1) * 0.22)
	return mat


static func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.add_to_group(GROUP)
	return mesh_inst


static func _build_suspended_bridge(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var span: float = rng.randf_range(18.0, 36.0)
	var deck := _box(Vector3(span, height * 0.04, rng.randf_range(2.0, 3.5)), mat)
	deck.position = Vector3(0.0, height * 0.55, 0.0)
	parent.add_child(deck)
	var pier_a := _box(Vector3(2.2, height * 0.5, 2.2), mat)
	pier_a.position = Vector3(-span * 0.42, height * 0.25, 0.0)
	parent.add_child(pier_a)
	var pier_b := _box(Vector3(1.8, height * 0.35, 1.8), mat)
	pier_b.position = Vector3(span * 0.38, height * 0.18, rng.randf_range(-2.0, 2.0))
	pier_b.rotation.z = rng.randf_range(0.1, 0.28)
	parent.add_child(pier_b)


static func _build_brutalist_tower(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var w: float = rng.randf_range(4.0, 7.0)
	var tower := _box(Vector3(w, height, w), mat)
	tower.position = Vector3(0.0, height * 0.5, 0.0)
	parent.add_child(tower)
	var cap := _box(Vector3(w * 1.15, height * 0.06, w * 1.15), mat)
	cap.position = Vector3(0.0, height * 0.98, 0.0)
	parent.add_child(cap)


static func _build_broken_ring(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var segments: int = rng.randi_range(4, 7)
	var radius: float = rng.randf_range(8.0, 14.0)
	for i in segments:
		if rng.randf() < 0.28:
			continue
		var angle: float = (float(i) / float(segments)) * TAU
		var seg := _box(Vector3(2.5, height * 0.12, 1.2), mat)
		seg.position = Vector3(cos(angle) * radius, height * 0.45, sin(angle) * radius)
		seg.rotation.y = angle + PI * 0.5
		parent.add_child(seg)


static func _build_vertical_shaft(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var w: float = rng.randf_range(2.0, 3.5)
	var shaft := _box(Vector3(w, height * 1.05, w), mat)
	shaft.position = Vector3(0.0, height * 0.52, 0.0)
	parent.add_child(shaft)
	var vent := _box(Vector3(w * 1.4, height * 0.08, 0.4), mat)
	vent.position = Vector3(0.0, height * 0.2, 0.0)
	parent.add_child(vent)


static func _build_industrial_pillar(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var base := _box(Vector3(6.0, height * 0.15, 6.0), mat)
	base.position = Vector3(0.0, height * 0.08, 0.0)
	parent.add_child(base)
	var core := _box(Vector3(2.2, height * 0.75, 2.2), mat)
	core.position = Vector3(0.0, height * 0.42, 0.0)
	parent.add_child(core)


static func _build_fractured_wall(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var wall_w: float = rng.randf_range(14.0, 24.0)
	var wall := _box(Vector3(wall_w, height * 0.65, 1.2), mat)
	wall.position = Vector3(0.0, height * 0.32, 0.0)
	parent.add_child(wall)
	var shard := _box(Vector3(4.0, height * 0.2, 3.0), mat)
	shard.position = Vector3(wall_w * 0.22, height * 0.12, 2.5)
	shard.rotation = Vector3(rng.randf_range(-0.35, -0.1), rng.randf_range(-0.2, 0.2), 0.25)
	parent.add_child(shard)


static func _build_collapsed_deck(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var deck := _box(Vector3(rng.randf_range(12.0, 22.0), height * 0.12, rng.randf_range(8.0, 14.0)), mat)
	deck.position = Vector3(0.0, height * 0.35, 0.0)
	deck.rotation = Vector3(rng.randf_range(-0.45, -0.2), rng.randf_range(-0.3, 0.3), rng.randf_range(0.1, 0.35))
	parent.add_child(deck)


static func _build_impossible_arch(
	parent: Node3D, height: float, mat: Material, rng: RandomNumberGenerator
) -> void:
	var leg_l := _box(Vector3(2.0, height * 0.55, 2.0), mat)
	leg_l.position = Vector3(-height * 0.22, height * 0.28, 0.0)
	leg_l.rotation.z = rng.randf_range(-0.18, -0.05)
	parent.add_child(leg_l)
	var leg_r := _box(Vector3(1.6, height * 0.4, 1.6), mat)
	leg_r.position = Vector3(height * 0.2, height * 0.2, 0.0)
	leg_r.rotation.z = rng.randf_range(0.08, 0.22)
	parent.add_child(leg_r)
	var lintel := _box(Vector3(height * 0.5, height * 0.08, 2.5), mat)
	lintel.position = Vector3(0.0, height * 0.58, 0.0)
	lintel.rotation.z = rng.randf_range(-0.2, 0.2)
	parent.add_child(lintel)


static func _attach_chain(
	cluster: Node3D,
	kind: MegaKind,
	height: float,
	layer: DepthLayer,
	mat: Material,
	rng: RandomNumberGenerator
) -> void:
	var offset: Vector3 = Vector3(
		rng.randf_range(10.0, 22.0),
		rng.randf_range(-4.0, 8.0),
		rng.randf_range(10.0, 22.0)
	)
	var chain := Node3D.new()
	chain.name = "ChainLink"
	chain.position = offset
	cluster.add_child(chain)

	match kind:
		MegaKind.SUSPENDED_BRIDGE:
			_build_brutalist_tower(chain, height * rng.randf_range(0.85, 1.1), mat, rng)
		MegaKind.INDUSTRIAL_PILLAR:
			_build_collapsed_deck(chain, height * rng.randf_range(0.7, 0.95), mat, rng)
		MegaKind.IMPOSSIBLE_ARCH:
			var seg := _box(Vector3(8.0, height * 0.06, 2.0), mat)
			seg.position = Vector3(0.0, height * 0.35, 0.0)
			seg.rotation.x = rng.randf_range(-0.25, 0.15)
			chain.add_child(seg)
		MegaKind.BRUTALIST_TOWER:
			_build_fractured_wall(chain, height * 0.65, mat, rng)
		MegaKind.BROKEN_RING:
			_build_vertical_shaft(chain, height * 0.9, mat, rng)
		_:
			_build_industrial_pillar(chain, height * 0.75, mat, rng)


static func _spawn_sparse_lights(
	root: Node3D, rng: RandomNumberGenerator, anchors: Array[Vector3]
) -> void:
	var light_count: int = rng.randi_range(1, 3)
	if anchors.is_empty():
		return

	var lights_root := Node3D.new()
	lights_root.name = "MegastructureLights"
	root.add_child(lights_root)

	var palette: Array[Color] = [
		Color(0.9, 0.15, 0.12),
		Color(0.2, 0.75, 0.85),
		Color(0.85, 0.88, 0.92),
	]

	for _i in light_count:
		var anchor: Vector3 = anchors[rng.randi_range(0, anchors.size() - 1)]
		var pos: Vector3 = anchor + Vector3(
			rng.randf_range(-4.0, 4.0),
			rng.randf_range(12.0, 48.0),
			rng.randf_range(-4.0, 4.0)
		)
		var tint: Color = palette[rng.randi_range(0, palette.size() - 1)]
		var beacon := _make_beacon(pos, tint, rng)
		lights_root.add_child(beacon)


static func _make_beacon(pos: Vector3, tint: Color, rng: RandomNumberGenerator) -> Node3D:
	var beacon := Node3D.new()
	beacon.name = "MegaBeacon"
	beacon.position = pos
	beacon.add_to_group(GROUP_LIGHT)

	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = tint
	bulb_mat.emission_enabled = true
	bulb_mat.emission = tint
	bulb_mat.emission_energy_multiplier = rng.randf_range(0.6, 1.4)

	var bulb := _box(Vector3(0.35, 0.35, 0.35), bulb_mat)
	bulb.position = Vector3.ZERO
	beacon.add_child(bulb)

	var omni := OmniLight3D.new()
	omni.light_color = tint
	omni.light_energy = rng.randf_range(0.12, 0.35)
	omni.omni_range = rng.randf_range(6.0, 14.0)
	omni.shadow_enabled = false
	beacon.add_child(omni)

	var blink: float = rng.randf_range(1.8, 4.5)
	beacon.set_meta("blink_period", blink)
	beacon.set_meta("blink_phase", rng.randf() * blink)
	beacon.set_script(preload("res://scripts/arena/arena_megastructure_beacon.gd"))
	return beacon


static func _attach_void_events(
	root: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator, play_radius: float
) -> void:
	var controller := ArenaMegastructureVoidEvents.new()
	controller.name = "MegastructureVoidEvents"
	controller.setup(rng, play_radius)
	root.add_child(controller)
