## Arena Chamber Pass — suspended combat deck, void abyss, perimeter read, landmark, atmosphere.
class_name ArenaChamberPass
extends RefCounted

const GROUP_DECOR: String = "arena_chamber_decor"
const GROUP_LIGHT: String = "arena_chamber_light"

enum LandmarkKind {
	BROKEN_BRIDGE,
	MASSIVE_PILLAR,
	FRACTURED_ARCH,
	SUSPENDED_RING,
	COLLAPSED_TOWER,
}


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	if parent == null or template == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(template.arena_name, template.template_id, Time.get_ticks_usec()))

	var root := Node3D.new()
	root.name = "ArenaChamberPass"
	parent.add_child(root)
	root.global_position = template.center_position

	_build_void_abyss(root, template, rng)
	_build_deck_zones(root, template)
	_build_verticality_visual(root, template, rng)
	var landmark: String = _build_landmark(root, template, rng)
	ArenaMegastructurePass.build(root, template, rng)
	_build_atmosphere(root, template, rng)
	_build_lighting(root, template)

	print("Arena Chamber Pass: landmark=%s" % landmark)


static func landmark_names() -> PackedStringArray:
	return PackedStringArray([
		"BrokenBridge",
		"MassivePillar",
		"FracturedArch",
		"SuspendedRing",
		"CollapsedTower",
	])


static func _build_void_abyss(root: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator) -> void:
	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var hx: float = bounds.danger_half_x + 4.0
	var hz: float = bounds.danger_half_z + 4.0

	var void_root := Node3D.new()
	void_root.name = "VoidAbyss"
	root.add_child(void_root)

	var gas_mat := StandardMaterial3D.new()
	gas_mat.albedo_color = Color(0.01, 0.025, 0.02, 0.92)
	gas_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gas_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	gas_mat.emission_enabled = true
	gas_mat.emission = Color(0.04, 0.12, 0.08)
	gas_mat.emission_energy_multiplier = 0.35

	var cloud := MeshInstance3D.new()
	cloud.name = "VoidGasCloud"
	var box := BoxMesh.new()
	box.size = Vector3(hx * 2.6, 14.0, hz * 2.6)
	cloud.mesh = box
	cloud.material_override = gas_mat
	cloud.position = Vector3(0.0, -10.0, 0.0)
	void_root.add_child(cloud)

	var deep := MeshInstance3D.new()
	deep.name = "VoidDeep"
	var deep_mat := StandardMaterial3D.new()
	deep_mat.albedo_color = Color(0.002, 0.004, 0.008)
	deep_mat.emission_enabled = true
	deep_mat.emission = Color(0.01, 0.02, 0.05)
	deep_mat.emission_energy_multiplier = 0.2
	var deep_box := BoxMesh.new()
	deep_box.size = Vector3(hx * 3.2, 40.0, hz * 3.2)
	deep.mesh = deep_box
	deep.material_override = deep_mat
	deep.position = Vector3(0.0, -28.0, 0.0)
	void_root.add_child(deep)

	var particles := CPUParticles3D.new()
	particles.name = "VoidRiseParticles"
	particles.emitting = true
	particles.amount = 48
	particles.lifetime = 4.5
	particles.preprocess = 1.0
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(hx * 0.95, 0.2, hz * 0.95)
	particles.direction = Vector3(0.0, 1.0, 0.0)
	particles.spread = 18.0
	particles.gravity = Vector3(0.0, -0.15, 0.0)
	particles.initial_velocity_min = 0.4
	particles.initial_velocity_max = 1.2
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 1.1
	particles.color = Color(0.15, 0.4, 0.28, 0.35)
	particles.position = Vector3(0.0, -2.2, 0.0)
	void_root.add_child(particles)

	var void_glow := OmniLight3D.new()
	void_glow.name = "VoidUnderGlow"
	void_glow.light_color = Color(0.2, 0.55, 0.38)
	void_glow.light_energy = 0.85
	void_glow.omni_range = maxf(hx, hz) * 2.2
	void_glow.position = Vector3(0.0, -6.0, 0.0)
	void_glow.add_to_group(GROUP_LIGHT)
	void_root.add_child(void_glow)


static func _build_deck_zones(root: Node3D, template: ArenaTemplate) -> void:
	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var zones := Node3D.new()
	zones.name = "DeckZones"
	root.add_child(zones)

	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = template.floor_albedo.lightened(0.04)
	center_mat.roughness = 0.9
	center_mat.metallic = 0.12

	var center := MeshInstance3D.new()
	center.name = "CentralCombatPlatform"
	var cbox := BoxMesh.new()
	cbox.size = Vector3(
		bounds.safe_half_x * 1.85,
		0.04,
		bounds.safe_half_z * 1.85
	)
	center.mesh = cbox
	center.material_override = center_mat
	center.position = Vector3(0.0, 0.02, 0.0)
	center.add_to_group(GROUP_DECOR)
	zones.add_child(center)

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.08, 0.1, 0.09)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.12, 0.32, 0.22)
	ring_mat.emission_energy_multiplier = 0.28
	ring_mat.roughness = 0.95

	_add_danger_ring_strip(zones, bounds.safe_half_x, bounds.safe_half_z, ring_mat, Vector3(0.0, 0.0, 1.0))
	_add_danger_ring_strip(zones, bounds.safe_half_x, bounds.safe_half_z, ring_mat, Vector3(0.0, 0.0, -1.0))
	_add_danger_ring_strip(zones, bounds.safe_half_x, bounds.safe_half_z, ring_mat, Vector3(1.0, 0.0, 0.0))
	_add_danger_ring_strip(zones, bounds.safe_half_x, bounds.safe_half_z, ring_mat, Vector3(-1.0, 0.0, 0.0))


static func _add_danger_ring_strip(
	parent: Node3D,
	safe_hx: float,
	safe_hz: float,
	mat: Material,
	axis: Vector3
) -> void:
	var strip := MeshInstance3D.new()
	var box := BoxMesh.new()
	if absf(axis.z) > 0.5:
		box.size = Vector3(safe_hx * 2.05, 0.06, 0.45)
		strip.position = Vector3(0.0, 0.03, signf(axis.z) * safe_hz)
	else:
		box.size = Vector3(0.45, 0.06, safe_hz * 2.05)
		strip.position = Vector3(signf(axis.x) * safe_hx, 0.03, 0.0)
	strip.mesh = box
	strip.material_override = mat
	strip.add_to_group(GROUP_DECOR)
	parent.add_child(strip)


static func _build_verticality_visual(
	root: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator
) -> void:
	var vert := Node3D.new()
	vert.name = "VerticalityDecor"
	root.add_child(vert)

	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var count: int = rng.randi_range(2, 4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = template.wall_albedo.darkened(0.08)
	mat.roughness = 0.93
	mat.metallic = 0.18

	for i in count:
		var lx: float = rng.randf_range(-bounds.safe_half_x * 0.55, bounds.safe_half_x * 0.55)
		var lz: float = rng.randf_range(-bounds.safe_half_z * 0.55, bounds.safe_half_z * 0.55)
		if Vector2(lx, lz).length() < 4.5:
			continue
		var kind: int = rng.randi_range(0, 2)
		if kind == 0:
			_add_ramp_visual(vert, Vector3(lx, 0.0, lz), rng, mat)
		elif kind == 1:
			_add_micro_platform(vert, Vector3(lx, 0.0, lz), rng, mat)
		else:
			_add_elevated_chunk(vert, Vector3(lx, 0.0, lz), rng, mat)


static func _add_ramp_visual(
	parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, mat: Material
) -> void:
	var ramp := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(2.8, 4.2), 0.22, rng.randf_range(1.2, 1.8))
	ramp.mesh = box
	ramp.material_override = mat
	ramp.position = pos + Vector3(0.0, 0.12, 0.0)
	ramp.rotation.x = rng.randf_range(-0.22, -0.12)
	ramp.rotation.y = rng.randf() * TAU
	ramp.add_to_group(GROUP_DECOR)
	parent.add_child(ramp)


static func _add_micro_platform(
	parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, mat: Material
) -> void:
	var plat := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(2.0, 3.5), 0.35, rng.randf_range(2.0, 3.5))
	plat.mesh = box
	plat.material_override = mat
	plat.position = pos + Vector3(0.0, 0.2, 0.0)
	plat.add_to_group(GROUP_DECOR)
	parent.add_child(plat)


static func _add_elevated_chunk(
	parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, mat: Material
) -> void:
	var chunk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(1.5, 2.8), rng.randf_range(0.5, 1.1), rng.randf_range(1.5, 2.8))
	chunk.mesh = box
	chunk.material_override = mat
	chunk.position = pos + Vector3(0.0, 0.35, 0.0)
	chunk.rotation.y = rng.randf() * TAU
	chunk.add_to_group(GROUP_DECOR)
	parent.add_child(chunk)


static func _build_landmark(root: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator) -> String:
	var kind: LandmarkKind = rng.randi_range(0, landmark_names().size() - 1) as LandmarkKind
	var landmark := Node3D.new()
	landmark.name = "ArenaLandmark"
	root.add_child(landmark)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = template.wall_albedo.darkened(0.15)
	mat.roughness = 0.9
	mat.metallic = 0.25
	mat.emission_enabled = true
	mat.emission = Color(0.06, 0.1, 0.12)
	mat.emission_energy_multiplier = 0.22

	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var offset := Vector3(
		rng.randf_range(-bounds.safe_half_x * 0.35, bounds.safe_half_x * 0.35),
		0.0,
		rng.randf_range(-bounds.safe_half_z * 0.35, bounds.safe_half_z * 0.35)
	)

	match kind:
		LandmarkKind.BROKEN_BRIDGE:
			_landmark_broken_bridge(landmark, offset, mat, bounds, rng)
		LandmarkKind.MASSIVE_PILLAR:
			_landmark_massive_pillar(landmark, offset, mat)
		LandmarkKind.FRACTURED_ARCH:
			_landmark_fractured_arch(landmark, offset, mat, rng)
		LandmarkKind.SUSPENDED_RING:
			_landmark_suspended_ring(landmark, offset, mat)
		LandmarkKind.COLLAPSED_TOWER:
			_landmark_collapsed_tower(landmark, offset, mat, rng)
		_:
			pass

	return landmark_names()[kind]


static func _landmark_broken_bridge(
	parent: Node3D,
	offset: Vector3,
	mat: Material,
	bounds: ArenaTemplate.AiBounds,
	rng: RandomNumberGenerator
) -> void:
	var span: float = minf(bounds.safe_half_x, bounds.safe_half_z) * 1.1
	var deck := _decor_box(Vector3(span, 0.35, 2.2), mat)
	deck.position = offset + Vector3(0.0, 2.0, 0.0)
	deck.rotation.y = rng.randf_range(-0.4, 0.4)
	parent.add_child(deck)
	var pier_l := _decor_box(Vector3(0.9, 5.5, 0.9), mat)
	pier_l.position = offset + Vector3(-span * 0.42, 2.75, 0.0)
	parent.add_child(pier_l)
	var pier_r := _decor_box(Vector3(0.75, 3.2, 0.75), mat)
	pier_r.position = offset + Vector3(span * 0.38, 1.6, 0.3)
	pier_r.rotation.z = 0.25
	parent.add_child(pier_r)
	var break_chunk := _decor_box(Vector3(2.5, 0.8, 1.8), mat)
	break_chunk.position = offset + Vector3(span * 0.15, 0.5, 1.2)
	break_chunk.rotation.x = -0.35
	parent.add_child(break_chunk)


static func _landmark_massive_pillar(parent: Node3D, offset: Vector3, mat: Material) -> void:
	var pillar := _decor_box(Vector3(2.8, 11.0, 2.8), mat)
	pillar.position = offset + Vector3(0.0, 5.5, 0.0)
	parent.add_child(pillar)
	var cap := _decor_box(Vector3(3.6, 0.5, 3.6), mat)
	cap.position = offset + Vector3(0.0, 11.2, 0.0)
	parent.add_child(cap)


static func _landmark_fractured_arch(
	parent: Node3D, offset: Vector3, mat: Material, rng: RandomNumberGenerator
) -> void:
	var leg_l := _decor_box(Vector3(1.2, 7.0, 1.2), mat)
	leg_l.position = offset + Vector3(-2.2, 3.5, 0.0)
	parent.add_child(leg_l)
	var leg_r := _decor_box(Vector3(1.0, 5.0, 1.0), mat)
	leg_r.position = offset + Vector3(2.0, 2.5, 0.0)
	leg_r.rotation.z = -0.18
	parent.add_child(leg_r)
	var lintel := _decor_box(Vector3(5.5, 0.9, 1.4), mat)
	lintel.position = offset + Vector3(0.0, 6.8, 0.0)
	lintel.rotation.z = rng.randf_range(-0.12, 0.12)
	parent.add_child(lintel)
	var fracture := _decor_box(Vector3(1.8, 0.5, 1.2), mat)
	fracture.position = offset + Vector3(1.2, 5.2, 0.8)
	fracture.rotation = Vector3(-0.5, 0.3, 0.4)
	parent.add_child(fracture)


static func _landmark_suspended_ring(parent: Node3D, offset: Vector3, mat: Material) -> void:
	var outer := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.2
	torus.outer_radius = 4.0
	outer.mesh = torus
	outer.material_override = mat
	outer.position = offset + Vector3(0.0, 6.5, 0.0)
	outer.rotation.x = PI * 0.5
	parent.add_child(outer)
	var strut := _decor_box(Vector3(0.35, 6.5, 0.35), mat)
	strut.position = offset + Vector3(0.0, 3.25, 0.0)
	parent.add_child(strut)


static func _landmark_collapsed_tower(
	parent: Node3D, offset: Vector3, mat: Material, rng: RandomNumberGenerator
) -> void:
	var base := _decor_box(Vector3(3.5, 4.0, 3.5), mat)
	base.position = offset + Vector3(0.0, 2.0, 0.0)
	parent.add_child(base)
	var fall := _decor_box(Vector3(2.8, 8.0, 2.2), mat)
	fall.position = offset + Vector3(2.5, 2.5, 1.5)
	fall.rotation = Vector3(rng.randf_range(-0.5, -0.25), rng.randf_range(-0.3, 0.3), 0.35)
	parent.add_child(fall)


static func _decor_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.add_to_group(GROUP_DECOR)
	return mesh_inst


static func _build_atmosphere(root: Node3D, template: ArenaTemplate, rng: RandomNumberGenerator) -> void:
	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var hx: float = bounds.danger_half_x
	var hz: float = bounds.danger_half_z

	var dust := CPUParticles3D.new()
	dust.name = "ArenaDust"
	dust.emitting = true
	dust.amount = 36
	dust.lifetime = 6.0
	dust.preprocess = 2.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(hx * 0.9, 1.5, hz * 0.9)
	dust.direction = Vector3(0.2, 0.05, 0.1)
	dust.spread = 25.0
	dust.gravity = Vector3(0.0, -0.02, 0.0)
	dust.initial_velocity_min = 0.08
	dust.initial_velocity_max = 0.35
	dust.scale_amount_min = 0.15
	dust.scale_amount_max = 0.45
	dust.color = Color(0.35, 0.38, 0.4, 0.18)
	dust.position = Vector3(0.0, 1.8, 0.0)
	root.add_child(dust)

	var ash := CPUParticles3D.new()
	ash.name = "ArenaAsh"
	ash.emitting = true
	ash.amount = 22
	ash.lifetime = 5.0
	ash.preprocess = 1.5
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ash.emission_sphere_radius = minf(hx, hz) * 0.85
	ash.direction = Vector3(-0.15, -0.25, 0.05)
	ash.spread = 35.0
	ash.gravity = Vector3(0.0, -0.08, 0.0)
	ash.initial_velocity_min = 0.05
	ash.initial_velocity_max = 0.22
	ash.scale_amount_min = 0.08
	ash.scale_amount_max = 0.25
	ash.color = Color(0.25, 0.28, 0.3, 0.22)
	ash.position = Vector3(0.0, 2.5, 0.0)
	root.add_child(ash)

	var metal := CPUParticles3D.new()
	metal.name = "ArenaMetalSparks"
	metal.emitting = true
	metal.amount = 14
	metal.lifetime = 2.5
	metal.preprocess = 1.0
	metal.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	metal.emission_box_extents = Vector3(hx * 0.55, 0.8, hz * 0.55)
	metal.direction = Vector3(0.1, -0.4, 0.05)
	metal.spread = 22.0
	metal.gravity = Vector3(0.0, -0.35, 0.0)
	metal.initial_velocity_min = 0.2
	metal.initial_velocity_max = 0.9
	metal.scale_amount_min = 0.05
	metal.scale_amount_max = 0.14
	metal.color = Color(0.55, 0.62, 0.7, 0.45)
	metal.position = Vector3(0.0, 2.0, 0.0)
	root.add_child(metal)


static func _build_lighting(root: Node3D, template: ArenaTemplate) -> void:
	var lights := Node3D.new()
	lights.name = "ArenaChamberLights"
	root.add_child(lights)

	var bounds: ArenaTemplate.AiBounds = template.ai_bounds
	var span: float = maxf(bounds.danger_half_x, bounds.danger_half_z)

	var key := DirectionalLight3D.new()
	key.name = "ArenaKeyCold"
	key.light_color = Color(0.62, 0.72, 0.82)
	key.light_energy = 1.15
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	key.add_to_group(GROUP_LIGHT)
	lights.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.name = "ArenaFillDim"
	fill.light_color = Color(0.35, 0.4, 0.45)
	fill.light_energy = 0.22
	fill.rotation_degrees = Vector3(-25.0, -120.0, 0.0)
	fill.add_to_group(GROUP_LIGHT)
	lights.add_child(fill)

	var rim_n := OmniLight3D.new()
	rim_n.name = "ArenaRimNorth"
	rim_n.light_color = Color(0.45, 0.55, 0.65)
	rim_n.light_energy = 0.45
	rim_n.omni_range = span * 1.8
	rim_n.position = Vector3(0.0, 3.0, -bounds.danger_half_z * 0.85)
	rim_n.add_to_group(GROUP_LIGHT)
	lights.add_child(rim_n)

	var rim_s := OmniLight3D.new()
	rim_s.name = "ArenaRimSouth"
	rim_s.light_color = Color(0.4, 0.5, 0.58)
	rim_s.light_energy = 0.38
	rim_s.omni_range = span * 1.8
	rim_s.position = Vector3(0.0, 3.0, bounds.danger_half_z * 0.85)
	rim_s.add_to_group(GROUP_LIGHT)
	lights.add_child(rim_s)
