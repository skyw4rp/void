## Builds brutalist Gladiator Chamber (~32×26 m) and return mood (MVP).
extends Node3D

const VOID_ARCH: PackedScene = preload("res://scenes/world/void_distant_architecture.tscn")

const FLOOR_SIZE: Vector2 = Vector2(32.0, 26.0)
const SPAWN_POS: Vector3 = Vector3(0.0, 0.05, 2.0)

var _world_env: WorldEnvironment
var _key_light: DirectionalLight3D
var _terminal_light: OmniLight3D
var _observatory_omni: OmniLight3D
var _mood_timer: float = 0.0
var _mood_state: int = 0
var _base_fog_density: float = 0.055
var _base_key_energy: float = 0.85


func _ready() -> void:
	add_to_group("gladiator_chamber")
	GameFlow.transitioning = false
	_build_chamber()
	_place_player()
	var mood: int = GameFlow.consume_return_mood()
	if mood != 0:
		_apply_return_mood(mood)
	else:
		_apply_neutral_mood()


func _process(delta: float) -> void:
	if _mood_timer > 0.0:
		_mood_timer -= delta
		if _mood_timer <= 0.0:
			_apply_neutral_mood()


func _place_player() -> void:
	var player: Node3D = get_node_or_null("ChamberPlayer") as Node3D
	if player:
		player.global_position = SPAWN_POS + Vector3(0.0, 1.0, 0.0)
		player.rotation.y = PI


func _build_chamber() -> void:
	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.018, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.05, 0.055)
	env.ambient_light_energy = 0.12
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.1, 0.09)
	env.fog_density = _base_fog_density
	env.fog_sky_affect = 0.0
	_world_env.environment = env
	add_child(_world_env)

	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	_key_light.light_color = Color(0.65, 0.72, 0.78)
	_key_light.light_energy = _base_key_energy
	_key_light.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	_key_light.shadow_enabled = true
	add_child(_key_light)

	_build_floor_and_walls()
	_build_observatory_void()

	var arch: Node3D = VOID_ARCH.instantiate() as Node3D
	arch.name = "DistantArchitecture"
	arch.position = Vector3(0.0, -8.0, -42.0)
	arch.scale = Vector3(1.15, 1.15, 1.15)
	add_child(arch)

	_build_interactables()
	GladiatorLoadout.loadout_changed.emit()


func _concrete_mat(bright: float = 0.1) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(bright, bright * 0.95, bright * 0.92)
	m.roughness = 0.92
	m.metallic = 0.08
	return m


func _steel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.14, 0.15, 0.17)
	m.metallic = 0.55
	m.roughness = 0.78
	return m


func _build_floor_and_walls() -> void:
	var floor_body := _static_box(
		"Floor",
		Vector3(0.0, -0.25, 0.0),
		Vector3(FLOOR_SIZE.x, 0.5, FLOOR_SIZE.y),
		_concrete_mat(0.09)
	)
	add_child(floor_body)

	_static_box(
		"WallWest",
		Vector3(-FLOOR_SIZE.x * 0.5 + 0.4, 2.2, 0.0),
		Vector3(0.8, 4.4, FLOOR_SIZE.y),
		_concrete_mat(0.07)
	)
	_static_box(
		"WallEast",
		Vector3(FLOOR_SIZE.x * 0.5 - 0.4, 2.2, 0.0),
		Vector3(0.8, 4.4, FLOOR_SIZE.y),
		_concrete_mat(0.07)
	)
	_static_box(
		"WallSouth",
		Vector3(0.0, 2.2, FLOOR_SIZE.y * 0.5 - 0.4),
		Vector3(FLOOR_SIZE.x, 4.4, 0.8),
		_concrete_mat(0.06)
	)

	_static_box(
		"ReturnPlatform",
		Vector3(0.0, 0.02, 2.0),
		Vector3(6.0, 0.12, 6.0),
		_concrete_mat(0.12)
	)

	_static_box(
		"TerminalDais",
		Vector3(0.0, -0.15, 9.0),
		Vector3(5.0, 0.35, 4.0),
		_concrete_mat(0.08)
	)


func _build_observatory_void() -> void:
	var rail_mat := _steel_mat()
	_static_box("ObservatoryRailL", Vector3(-4.5, 0.9, -11.5), Vector3(0.15, 1.2, 3.0), rail_mat)
	_static_box("ObservatoryRailR", Vector3(4.5, 0.9, -11.5), Vector3(0.15, 1.2, 3.0), rail_mat)

	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.002, 0.006, 0.012)
	void_mat.emission_enabled = true
	void_mat.emission = Color(0.02, 0.04, 0.08)
	void_mat.emission_energy_multiplier = 0.12

	var void_mesh := MeshInstance3D.new()
	void_mesh.name = "VoidDropVisual"
	void_mesh.mesh = BoxMesh.new()
	(void_mesh.mesh as BoxMesh).size = Vector3(28.0, 1.0, 14.0)
	void_mesh.material_override = void_mat
	void_mesh.position = Vector3(0.0, -6.0, -18.0)
	add_child(void_mesh)

	_observatory_omni = OmniLight3D.new()
	_observatory_omni.name = "ObservatoryVoidLight"
	_observatory_omni.position = Vector3(0.0, 1.5, -12.0)
	_observatory_omni.light_color = Color(0.25, 0.45, 0.5)
	_observatory_omni.light_energy = 0.35
	_observatory_omni.omni_range = 22.0
	add_child(_observatory_omni)


func _build_interactables() -> void:
	_add_weapon_rack(
		Vector3(-10.0, 0.0, -2.0), GladiatorLoadout.WeaponChoice.RAILGUN, Vector3(0.35, 1.4, 0.35)
	)
	_add_weapon_rack(
		Vector3(-10.0, 0.0, 2.0), GladiatorLoadout.WeaponChoice.SHOTGUN, Vector3(0.5, 1.2, 0.4)
	)
	_add_weapon_rack(
		Vector3(-10.0, 0.0, 6.0), GladiatorLoadout.WeaponChoice.BAZOOKA, Vector3(0.45, 1.5, 0.45)
	)

	_add_armor_pedestal(Vector3(10.0, 0.0, -2.0), GladiatorLoadout.ArmorChoice.LIGHT, 0.85)
	_add_armor_pedestal(Vector3(10.0, 0.0, 2.5), GladiatorLoadout.ArmorChoice.MEDIUM, 1.0)
	_add_armor_pedestal(Vector3(10.0, 0.0, 7.0), GladiatorLoadout.ArmorChoice.HEAVY, 1.2)

	_add_helmet_stand(Vector3(12.5, 0.0, -5.0), GladiatorLoadout.HelmetChoice.CUSTODIAN)
	_add_helmet_stand(Vector3(12.5, 0.0, -1.5), GladiatorLoadout.HelmetChoice.OBSERVER)
	_add_helmet_stand(Vector3(12.5, 0.0, 2.0), GladiatorLoadout.HelmetChoice.FACELESS)

	_add_arena_terminal(Vector3(0.0, 0.35, 9.0))


func _static_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _add_interact_area(parent: Node3D, size: Vector3) -> Area3D:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	parent.add_child(area)
	return area


func _add_weapon_rack(pos: Vector3, choice: int, mesh_size: Vector3) -> void:
	var root := Node3D.new()
	root.name = "WeaponRack_%d" % choice
	root.position = pos
	var rack := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = mesh_size
	rack.mesh = mesh
	rack.material_override = _steel_mat()
	root.add_child(rack)
	var highlight := MeshInstance3D.new()
	highlight.name = "Highlight"
	var hmesh := BoxMesh.new()
	hmesh.size = mesh_size * 1.08
	highlight.mesh = hmesh
	var hmat := StandardMaterial3D.new()
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = Color(0.2, 0.55, 0.65, 0.25)
	hmat.emission_enabled = true
	hmat.emission = Color(0.15, 0.5, 0.6)
	hmat.emission_energy_multiplier = 0.4
	highlight.material_override = hmat
	highlight.visible = false
	root.add_child(highlight)
	var area := _add_interact_area(root, mesh_size + Vector3(0.6, 0.4, 0.6))
	area.position = Vector3(0.0, mesh_size.y * 0.5, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_weapon_rack.gd") as Script
	area.set_script(script)
	area.set("weapon_choice", choice)
	add_child(root)


func _add_armor_pedestal(pos: Vector3, choice: int, scale_y: float) -> void:
	var root := Node3D.new()
	root.name = "ArmorPedestal_%d" % choice
	root.position = pos
	var base := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.2, 0.15, 1.2)
	base.mesh = bmesh
	base.material_override = _concrete_mat(0.11)
	root.add_child(base)
	var mannequin := MeshInstance3D.new()
	mannequin.name = "Mannequin"
	var mmesh := BoxMesh.new()
	mmesh.size = Vector3(0.9, 1.7 * scale_y, 0.55)
	mannequin.mesh = mmesh
	var mat := _concrete_mat(0.13)
	mat.emission_enabled = false
	mannequin.material_override = mat
	mannequin.position = Vector3(0.0, 0.95 * scale_y, 0.0)
	root.add_child(mannequin)
	var area := _add_interact_area(root, Vector3(1.8, 2.2, 1.8))
	area.position = Vector3(0.0, 1.0, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_armor_pedestal.gd") as Script
	area.set_script(script)
	area.set("armor_choice", choice)
	add_child(root)


func _add_helmet_stand(pos: Vector3, choice: int) -> void:
	var root := Node3D.new()
	root.name = "HelmetStand_%d" % choice
	root.position = pos
	var post := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.height = 1.1
	pmesh.top_radius = 0.06
	pmesh.bottom_radius = 0.08
	post.mesh = pmesh
	post.material_override = _steel_mat()
	post.position = Vector3(0.0, 0.55, 0.0)
	root.add_child(post)
	var helmet := MeshInstance3D.new()
	helmet.name = "HelmetMesh"
	var hmesh := SphereMesh.new()
	hmesh.radius = 0.28
	hmesh.height = 0.5
	helmet.mesh = hmesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.15)
	mat.roughness = 0.85
	helmet.material_override = mat
	helmet.position = Vector3(0.0, 1.15, 0.0)
	root.add_child(helmet)
	var area := _add_interact_area(root, Vector3(1.0, 2.0, 1.0))
	area.position = Vector3(0.0, 1.0, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_helmet_stand.gd") as Script
	area.set_script(script)
	area.set("helmet_choice", choice)
	add_child(root)


func _add_arena_terminal(pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "ArenaTerminal"
	root.position = pos
	var console := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 1.4, 0.8)
	console.mesh = mesh
	console.material_override = _steel_mat()
	console.position = Vector3(0.0, 0.9, 0.0)
	root.add_child(console)
	var screen := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(1.6, 0.7, 0.05)
	screen.mesh = smesh
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.05, 0.12, 0.14)
	smat.emission_enabled = true
	smat.emission = Color(0.1, 0.35, 0.4)
	smat.emission_energy_multiplier = 0.6
	screen.material_override = smat
	screen.position = Vector3(0.0, 1.05, 0.42)
	root.add_child(screen)
	var light := OmniLight3D.new()
	light.name = "ScreenLight"
	light.position = Vector3(0.0, 1.2, 0.5)
	light.light_color = Color(0.35, 0.75, 0.8)
	light.light_energy = 1.1
	light.omni_range = 5.0
	root.add_child(light)
	_terminal_light = light
	var area := _add_interact_area(root, Vector3(3.0, 2.5, 2.0))
	area.position = Vector3(0.0, 1.0, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_arena_terminal.gd") as Script
	area.set_script(script)
	add_child(root)


func _apply_return_mood(mood: int) -> void:
	_mood_state = mood
	if mood > 0:
		_apply_victory_mood()
	else:
		_apply_defeat_mood()


func _apply_victory_mood() -> void:
	print("Chamber: victory return — clarity")
	if _world_env and _world_env.environment:
		_world_env.environment.fog_density = _base_fog_density * 0.65
	if _key_light:
		_key_light.light_energy = _base_key_energy * 1.2
	if _observatory_omni:
		_observatory_omni.light_energy = 0.55
	_mood_timer = 55.0


func _apply_defeat_mood() -> void:
	print("Chamber: defeat return — weight")
	if _world_env and _world_env.environment:
		_world_env.environment.fog_density = _base_fog_density * 1.45
	if _key_light:
		_key_light.light_energy = _base_key_energy * 0.55
	if _observatory_omni:
		_observatory_omni.light_energy = 0.65
	_mood_timer = 28.0


func _apply_neutral_mood() -> void:
	_mood_state = 0
	if _world_env and _world_env.environment:
		_world_env.environment.fog_density = _base_fog_density
	if _key_light:
		_key_light.light_energy = _base_key_energy
	if _observatory_omni:
		_observatory_omni.light_energy = 0.35
