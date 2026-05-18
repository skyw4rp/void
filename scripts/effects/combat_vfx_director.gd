## Minimal brutalist combat VFX — muzzle, hits, edge tension (visual only).
extends Node

const GROUP_VFX: String = "combat_vfx"

@export var vfx_intensity: float = 1.0
@export var muzzle_flash_scale: float = 1.0
@export var shield_hit_scale: float = 1.0
@export var shield_break_scale: float = 1.0
@export var shield_break_player_flash_alpha: float = 0.11
@export var health_hit_scale: float = 1.0
@export var void_edge_strength: float = 0.85
@export var enemy_vfx_multiplier: float = 0.72
@export var view_flash_max_alpha: float = 0.07

static var _instance: Node


func _ready() -> void:
	_instance = self
	add_to_group("combat_vfx_director")


static func spawn_muzzle_fire(
	weapon: WeaponDefs.Id,
	origin: Vector3,
	direction: Vector3,
	from_enemy: bool = false
) -> void:
	if _instance == null:
		return
	_instance._spawn_muzzle_fire_impl(weapon, origin, direction, from_enemy)


static func spawn_fighter_hit(
	world_position: Vector3,
	surface_normal: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int,
	hit_direction: Vector3 = Vector3.ZERO
) -> void:
	if _instance == null:
		return
	_instance._spawn_fighter_hit_impl(
		world_position, surface_normal, shield_before, shield_after,
		health_before, health_after, hit_direction
	)


static func play_shield_break_event(
	world_position: Vector3,
	surface_normal: Vector3,
	is_local_player: bool,
	_is_enemy: bool = false
) -> void:
	if _instance == null:
		return
	_instance._play_shield_break_event_impl(
		world_position, surface_normal, is_local_player, _is_enemy
	)


## Legacy alias — prefer `play_shield_break_event`.
static func spawn_shield_break(world_position: Vector3, surface_normal: Vector3) -> void:
	play_shield_break_event(world_position, surface_normal, false, true)


static func spawn_wall_hit(
	world_position: Vector3,
	surface_normal: Vector3,
	metallic: bool = true
) -> void:
	if _instance == null:
		return
	_instance._spawn_wall_hit_impl(world_position, surface_normal, metallic)


static func apply_edge_tension(edge_t: float, void_falling: bool) -> void:
	if _instance == null:
		return
	_instance._apply_edge_tension_impl(edge_t, void_falling)


func _spawn_muzzle_fire_impl(
	weapon: WeaponDefs.Id, origin: Vector3, direction: Vector3, from_enemy: bool
) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		return

	var mult: float = _s(muzzle_flash_scale) * (enemy_vfx_multiplier if from_enemy else 1.0)
	var dir: Vector3 = direction.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	var pos: Vector3 = origin + dir * 0.12

	match weapon:
		WeaponDefs.Id.RAILGUN:
			_spawn_muzzle_railgun(root, pos, dir, mult)
			_trigger_view_flash(Color(0.75, 0.88, 1.0), 0.55 * mult, 0.06)
		WeaponDefs.Id.SHOTGUN:
			_spawn_muzzle_shotgun(root, pos, dir, mult)
			_trigger_view_flash(Color(0.95, 0.55, 0.28), 0.45 * mult, 0.05)
		WeaponDefs.Id.BAZOOKA:
			_spawn_muzzle_bazooka(root, pos, dir, mult)
			_trigger_view_flash(Color(1.0, 0.42, 0.18), 0.5 * mult, 0.07)


func _spawn_muzzle_railgun(root: Node, pos: Vector3, dir: Vector3, mult: float) -> void:
	var holder := _make_holder(root, pos, dir)
	var core := _add_glow_sphere(holder, Color(0.82, 0.92, 1.0), 0.14 * mult, 4.5)
	core.scale = Vector3.ONE * (0.35 + 0.25 * mult)
	_add_brief_light(holder, Color(0.55, 0.82, 1.0), 1.8 * mult, 2.2, 0.08)
	var parts := _make_particles(holder, 6, 0.22)
	parts.direction = dir
	parts.spread = 18.0
	parts.initial_velocity_min = 1.5
	parts.initial_velocity_max = 4.0
	parts.color = Color(0.7, 0.88, 1.0, 0.55)
	parts.gravity = Vector3.ZERO
	_schedule_free(holder, 0.2)


func _spawn_muzzle_shotgun(root: Node, pos: Vector3, dir: Vector3, mult: float) -> void:
	var holder := _make_holder(root, pos, dir)
	_add_glow_sphere(holder, Color(0.95, 0.62, 0.32), 0.2 * mult, 3.2)
	var smoke := _make_particles(holder, 14, 0.35)
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.12 * mult
	smoke.direction = dir
	smoke.spread = 42.0
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 2.2
	smoke.gravity = Vector3(0, -0.6, 0)
	smoke.color = Color(0.35, 0.28, 0.22, 0.45)
	_add_brief_light(holder, Color(0.9, 0.5, 0.22), 1.4 * mult, 1.8, 0.1)
	_schedule_free(holder, 0.28)


func _spawn_muzzle_bazooka(root: Node, pos: Vector3, dir: Vector3, mult: float) -> void:
	var holder := _make_holder(root, pos, dir)
	_add_glow_sphere(holder, Color(1.0, 0.48, 0.15), 0.26 * mult, 3.8)
	var flame := _make_particles(holder, 10, 0.3)
	flame.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.1 * mult
	flame.direction = dir
	flame.spread = 28.0
	flame.initial_velocity_min = 1.0
	flame.initial_velocity_max = 3.5
	flame.color = Color(0.95, 0.38, 0.12, 0.65)
	var trail := _make_particles(holder, 8, 0.45)
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.08
	trail.direction = dir
	trail.spread = 12.0
	trail.initial_velocity_min = 2.0
	trail.initial_velocity_max = 5.0
	trail.gravity = Vector3(0, -0.2, 0)
	trail.color = Color(0.25, 0.22, 0.2, 0.35)
	_add_brief_light(holder, Color(1.0, 0.4, 0.1), 2.2 * mult, 2.8, 0.12)
	_schedule_free(holder, 0.32)


func _spawn_fighter_hit_impl(
	world_position: Vector3,
	surface_normal: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int,
	hit_direction: Vector3
) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		return

	var n: Vector3 = _safe_normal(surface_normal, hit_direction)
	var pos: Vector3 = world_position + n * 0.04

	if shield_after < shield_before and not (shield_before > 0 and shield_after <= 0):
		_spawn_shield_hit(root, pos, n)
	if health_after < health_before:
		_spawn_health_hit(root, pos, n)


func _spawn_shield_hit(root: Node, pos: Vector3, normal: Vector3) -> void:
	var holder := _make_holder(root, pos, normal)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.08 * _s(shield_hit_scale)
	torus.outer_radius = 0.22 * _s(shield_hit_scale)
	ring.mesh = torus
	ring.material_override = _unshaded_mat(Color(0.35, 0.82, 1.0, 0.85), Color(0.4, 0.9, 1.0), 2.2)
	holder.add_child(ring)
	ring.rotation.x = PI * 0.5
	var crack := _make_particles(holder, 8, 0.18)
	crack.direction = normal
	crack.spread = 55.0
	crack.initial_velocity_min = 0.6
	crack.initial_velocity_max = 2.0
	crack.color = Color(0.45, 0.78, 1.0, 0.5)
	_add_brief_light(holder, Color(0.4, 0.85, 1.0), 0.9 * _s(shield_hit_scale), 1.6, 0.07)
	_schedule_free(holder, 0.22)


func _spawn_health_hit(root: Node, pos: Vector3, normal: Vector3) -> void:
	var holder := _make_holder(root, pos, normal)
	var burst := _make_particles(holder, 12, 0.24)
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.08 * _s(health_hit_scale)
	burst.direction = normal
	burst.spread = 160.0
	burst.initial_velocity_min = 0.8
	burst.initial_velocity_max = 3.2
	burst.color = Color(0.55, 0.08, 0.06, 0.7)
	_add_glow_sphere(holder, Color(0.72, 0.12, 0.08), 0.12 * _s(health_hit_scale), 2.8)
	_add_brief_light(holder, Color(0.85, 0.2, 0.12), 1.1 * _s(health_hit_scale), 1.4, 0.09)
	_schedule_free(holder, 0.26)


func _play_shield_break_event_impl(
	world_position: Vector3,
	surface_normal: Vector3,
	is_local_player: bool,
	_is_enemy: bool
) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		return

	var mult: float = _s(shield_break_scale)
	if _is_enemy and not is_local_player:
		mult *= maxf(enemy_vfx_multiplier, 0.85)
	if is_local_player:
		mult *= 1.12

	var n: Vector3 = _safe_normal(surface_normal, Vector3.ZERO)
	var pos: Vector3 = world_position + n * 0.05
	var holder := _make_holder(root, pos, n)

	# Core crack flash.
	_add_glow_sphere(holder, Color(0.55, 0.92, 1.0), 0.2 * mult, 4.2)

	# Expanding rupture rings.
	var ring_inner := _add_shield_break_ring(holder, 0.12 * mult, 0.28 * mult, 3.8)
	var ring_outer := _add_shield_break_ring(holder, 0.22 * mult, 0.55 * mult, 3.2)
	_animate_shield_break_ring(ring_inner, 1.0, 2.2, 0.22)
	_animate_shield_break_ring(ring_outer, 1.0, 2.8, 0.32)

	# Radial energy fragments.
	var burst := _make_particles(holder, 20, 0.34)
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.14 * mult
	burst.direction = n
	burst.spread = 180.0
	burst.initial_velocity_min = 1.5
	burst.initial_velocity_max = 5.5
	burst.gravity = Vector3(0, -0.35, 0)
	burst.color = Color(0.45, 0.88, 1.0, 0.62)

	var crack := _make_particles(holder, 10, 0.2)
	crack.direction = n
	crack.spread = 70.0
	crack.initial_velocity_min = 0.8
	crack.initial_velocity_max = 2.8
	crack.color = Color(0.65, 0.95, 1.0, 0.48)

	_add_brief_light(holder, Color(0.42, 0.92, 1.0), 2.2 * mult, 3.2, 0.16)
	_schedule_free(holder, 0.42)

	if is_local_player:
		_trigger_view_flash(
			Color(0.38, 0.88, 1.0),
			shield_break_player_flash_alpha * vfx_intensity,
			0.14
		)


func _add_shield_break_ring(
	parent: Node3D, inner_r: float, outer_r: float, emission_mult: float
) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner_r
	torus.outer_radius = outer_r
	ring.mesh = torus
	ring.material_override = _unshaded_mat(
		Color(0.48, 0.9, 1.0, 0.92), Color(0.55, 1.0, 1.0), emission_mult
	)
	parent.add_child(ring)
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3.ONE * 0.35
	return ring


func _animate_shield_break_ring(ring: MeshInstance3D, from_scale: float, to_scale: float, duration: float) -> void:
	if ring == null:
		return
	ring.scale = Vector3.ONE * from_scale
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * to_scale, duration).set_ease(Tween.EASE_OUT)
	if ring.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = ring.material_override as StandardMaterial3D
		var start_a: float = mat.albedo_color.a
		var fade_alpha := func(a: float) -> void:
			if is_instance_valid(mat):
				mat.albedo_color.a = a
		tween.tween_method(fade_alpha, start_a, 0.0, duration).set_ease(Tween.EASE_IN)


func _spawn_wall_hit_impl(world_position: Vector3, surface_normal: Vector3, metallic: bool) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		return
	var n: Vector3 = _safe_normal(surface_normal, Vector3.UP)
	var pos: Vector3 = world_position + n * 0.03
	var holder := _make_holder(root, pos, n)
	var dust := _make_particles(holder, 10, 0.3)
	dust.direction = n
	dust.spread = 70.0
	dust.initial_velocity_min = 0.3
	dust.initial_velocity_max = 1.8
	dust.gravity = Vector3(0, -1.2, 0)
	dust.color = Color(0.28, 0.24, 0.22, 0.55)
	if metallic:
		var sparks := _make_particles(holder, 6, 0.2)
		sparks.direction = n
		sparks.spread = 90.0
		sparks.initial_velocity_min = 1.0
		sparks.initial_velocity_max = 3.5
		sparks.gravity = Vector3(0, -2.0, 0)
		sparks.color = Color(0.75, 0.78, 0.82, 0.65)
		_add_brief_light(holder, Color(0.7, 0.75, 0.8), 0.35, 1.2, 0.06)
	_schedule_free(holder, 0.32)


func _apply_edge_tension_impl(edge_t: float, void_falling: bool) -> void:
	var ui: Node = get_tree().get_first_node_in_group("arena_ui")
	if ui and ui.has_method("apply_edge_tension"):
		ui.call("apply_edge_tension", edge_t, void_falling, void_edge_strength * vfx_intensity)


func _trigger_view_flash(color: Color, strength: float, duration: float) -> void:
	var ui: Node = get_tree().get_first_node_in_group("arena_ui")
	if ui and ui.has_method("trigger_combat_view_flash"):
		ui.call(
			"trigger_combat_view_flash",
			color,
			clampf(strength * view_flash_max_alpha, 0.0, view_flash_max_alpha),
			duration
		)


func _s(scale: float) -> float:
	return scale * vfx_intensity


func _make_holder(root: Node, pos: Vector3, forward: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.add_to_group(GROUP_VFX)
	root.add_child(holder)
	holder.global_position = pos
	if forward.length_squared() > 0.0001:
		holder.look_at(pos + forward, Vector3.UP)
	return holder


func _add_glow_sphere(
	parent: Node3D, color: Color, radius: float, emission_mult: float
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_inst.mesh = sphere
	mesh_inst.material_override = _unshaded_mat(color, color, emission_mult)
	parent.add_child(mesh_inst)
	return mesh_inst


func _add_brief_light(
	parent: Node3D, color: Color, energy: float, range_v: float, duration: float
) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_v
	light.shadow_enabled = false
	parent.add_child(light)
	var tween: Tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)


func _make_particles(parent: Node3D, amount: int, lifetime: float) -> CPUParticles3D:
	var parts := CPUParticles3D.new()
	parts.amount = amount
	parts.lifetime = lifetime
	parts.one_shot = true
	parts.explosiveness = 0.92
	parts.emitting = true
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	parent.add_child(parts)
	return parts


func _unshaded_mat(albedo: Color, emission: Color, emission_mult: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = emission_mult
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return mat


func _safe_normal(surface_normal: Vector3, hit_direction: Vector3) -> Vector3:
	if surface_normal.length_squared() > 0.0001:
		return surface_normal.normalized()
	if hit_direction.length_squared() > 0.0001:
		return (-hit_direction).normalized()
	return Vector3.UP


func _schedule_free(node: Node, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(
		func() -> void:
			if is_instance_valid(node):
				node.queue_free()
	)
