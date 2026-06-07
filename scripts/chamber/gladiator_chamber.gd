## Builds brutalist Gladiator Chamber (~32×26 m) — functional zones only.
extends Node3D

const VOID_ARCH: PackedScene = preload("res://scenes/world/void_distant_architecture.tscn")

const FLOOR_SIZE: Vector2 = Vector2(32.0, 26.0)
const SPAWN_POS: Vector3 = Vector3(0.0, 0.05, 2.0)
const CEILING_Y: float = 4.5
const WALL_HEIGHT: float = 4.4
const NORTH_Z: float = -FLOOR_SIZE.y * 0.5 + 0.35
const VOID_WINDOW_WIDTH: float = 11.0
const VOID_WINDOW_HEIGHT: float = 2.85

const LOADOUT_BAY_CENTER: Vector3 = Vector3(-9.5, 0.0, 0.0)
const LOADOUT_WEAPON_X: float = -11.0
const LOADOUT_ARMOR_X: float = -9.5
const LOADOUT_HELMET_X: float = -8.0
const WEAPON_STATION_BASE: Vector3 = Vector3(1.2, 0.18, 1.2)
const ARMOR_STATION_BASE: Vector3 = Vector3(1.2, 0.18, 1.2)
const HELMET_STATION_BASE: Vector3 = Vector3(1.0, 0.16, 1.0)
const STATION_SUPPORT: Vector3 = Vector3(0.12, 0.5, 0.12)
const WEAPON_MOUNT_SIZE: Vector3 = Vector3(0.35, 0.08, 0.25)
const CHAMBER_LOCAL_MAX_XZ: float = 1.5
const CHAMBER_INTERIOR_MAX_SPAN: float = 6.0
const CHAMBER_CLUTTER_MAX_SPAN: float = 6.0
const CHAMBER_CLUTTER_Y_MIN: float = 0.4
const CHAMBER_CLUTTER_Y_MAX: float = 2.5
const CHAMBER_MESH_DEBUG: bool = false
const CHAMBER_CLEANUP_ENABLED: bool = true

const COMMAND_ZONE_CENTER: Vector3 = Vector3(0.0, 0.0, 6.2)
const TERMINAL_POS: Vector3 = Vector3(0.0, 0.35, 9.0)
const PROGRESSION_WALL_X: float = 14.2
const CHAMBER_DISTANT_MAX_WIDTH: float = 12.0
const CHAMBER_DISTANT_KEEP_NAMES: Array[StringName] = [
	&"BrokenBridgeFar",
	&"FloatingPlatformA",
	&"FloatingPlatformB",
	&"PillarClusterN",
	&"PillarClusterE",
	&"PillarClusterW",
	&"RuinSilhouette",
	&"DistantBlock",
]

static func get_loadout_weapon_z() -> Array[float]:
	return [5.0, 0.0, -5.0]


static func get_loadout_armor_z() -> Array[float]:
	return [4.0, 0.0, -4.0]


static func get_loadout_helmet_z() -> Array[float]:
	return [4.5, 0.0, -4.5]


var _world_env: WorldEnvironment
var _key_light: DirectionalLight3D
var _terminal_light: OmniLight3D
var _observatory_omni: OmniLight3D
var _mood_timer: float = 0.0
var _mood_state: int = 0
var _base_fog_density: float = 0.016
var _base_key_energy: float = 0.82
var _void_floor_glow: OmniLight3D

var _zone_parent: Node3D
var _arch_pieces: int = 0
var _loadout_pieces: int = 0
var _command_pieces: int = 0
var _clutter_removed: int = 0


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
	_arch_pieces = 0
	_loadout_pieces = 0
	_command_pieces = 0
	_clutter_removed = 0

	var chamber_root := Node3D.new()
	chamber_root.name = "ChamberRoot"
	add_child(chamber_root)

	var architecture := Node3D.new()
	architecture.name = "Architecture"
	chamber_root.add_child(architecture)

	var loadout_bay := Node3D.new()
	loadout_bay.name = "LoadoutBay"
	chamber_root.add_child(loadout_bay)

	var command_area := Node3D.new()
	command_area.name = "CommandArea"
	chamber_root.add_child(command_area)

	var progression_wall := Node3D.new()
	progression_wall.name = "ProgressionWall"
	chamber_root.add_child(progression_wall)

	var void_window := Node3D.new()
	void_window.name = "VoidWindow"
	chamber_root.add_child(void_window)

	var lighting := Node3D.new()
	lighting.name = "Lighting"
	chamber_root.add_child(lighting)

	var atmosphere := Node3D.new()
	atmosphere.name = "Atmosphere"
	chamber_root.add_child(atmosphere)

	_build_world_environment()
	_build_key_light()

	_build_architecture(architecture)
	_build_loadout_bay_zone(loadout_bay)
	_build_command_area_zone(command_area)
	_build_progression_wall_zone(progression_wall)
	_build_void_window_zone(void_window)
	_build_zone_lighting(lighting)
	_build_atmosphere(atmosphere)

	_build_chamber_distant_architecture(chamber_root)

	_build_interactables(loadout_bay, command_area)

	if CHAMBER_CLEANUP_ENABLED:
		_cleanup_chamber_visual_clutter(chamber_root)
	if CHAMBER_MESH_DEBUG:
		_debug_scan_all_meshes(chamber_root)
	_print_chamber_build_summary()

	GladiatorLoadout.loadout_changed.emit()


func _build_chamber_distant_architecture(chamber_root: Node3D) -> void:
	var arch: Node3D = VOID_ARCH.instantiate() as Node3D
	arch.name = "DistantArchitecture"
	arch.position = Vector3(0.0, -8.0, -42.0)
	arch.scale = Vector3(1.15, 1.15, 1.15)
	chamber_root.add_child(arch)
	_sanitize_chamber_distant_architecture(arch)


func _sanitize_chamber_distant_architecture(arch: Node3D) -> void:
	var to_remove: Array[Node] = []
	for child in arch.get_children():
		if not child is MeshInstance3D:
			continue
		var mesh_inst := child as MeshInstance3D
		var sz: Vector3 = _mesh_instance_size(mesh_inst)
		if mesh_inst.name == "HangingSpan":
			print("Removed chamber HangingSpan")
			to_remove.append(mesh_inst)
			continue
		if mesh_inst.name in CHAMBER_DISTANT_KEEP_NAMES:
			continue
		if sz.x > CHAMBER_DISTANT_MAX_WIDTH:
			push_warning(
				"Chamber distant piece skipped (width %.1f): %s"
				% [sz.x, mesh_inst.name if mesh_inst.name != "" else "<extra>"]
			)
			to_remove.append(mesh_inst)
	for node in to_remove:
		node.queue_free()


func _build_world_environment() -> void:
	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.018, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.05, 0.055)
	env.ambient_light_energy = 0.11
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.98
	_apply_chamber_fog(env, 1.0)
	_world_env.environment = env
	add_child(_world_env)


func _build_key_light() -> void:
	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	_key_light.light_color = Color(0.65, 0.72, 0.78)
	_key_light.light_energy = _base_key_energy
	_key_light.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	_key_light.shadow_enabled = true
	add_child(_key_light)


func _build_architecture(parent: Node3D) -> void:
	_zone_parent = parent
	_static_box(
		"Floor",
		Vector3(0.0, -0.25, 0.0),
		Vector3(FLOOR_SIZE.x, 0.5, FLOOR_SIZE.y),
		_concrete_mat(0.09),
		"architecture"
	)
	_static_box(
		"Ceiling",
		Vector3(0.0, CEILING_Y, 0.0),
		Vector3(FLOOR_SIZE.x, 0.55, FLOOR_SIZE.y),
		_concrete_mat(0.055),
		"architecture"
	)
	_static_box(
		"WallWest",
		Vector3(-FLOOR_SIZE.x * 0.5 + 0.4, WALL_HEIGHT * 0.5, 0.0),
		Vector3(0.8, WALL_HEIGHT, FLOOR_SIZE.y),
		_concrete_mat(0.07),
		"architecture"
	)
	_static_box(
		"WallEast",
		Vector3(FLOOR_SIZE.x * 0.5 - 0.4, WALL_HEIGHT * 0.5, 0.0),
		Vector3(0.8, WALL_HEIGHT, FLOOR_SIZE.y),
		_concrete_mat(0.07),
		"architecture"
	)
	_static_box(
		"WallSouth",
		Vector3(0.0, WALL_HEIGHT * 0.5, FLOOR_SIZE.y * 0.5 - 0.4),
		Vector3(FLOOR_SIZE.x, WALL_HEIGHT, 0.8),
		_concrete_mat(0.06),
		"architecture"
	)

	var half_w: float = VOID_WINDOW_WIDTH * 0.5
	var lintel_y: float = 1.35 + VOID_WINDOW_HEIGHT * 0.5 + 0.35
	_static_box(
		"WallNorthWest",
		Vector3(-half_w - 4.5, WALL_HEIGHT * 0.5, NORTH_Z),
		Vector3(FLOOR_SIZE.x * 0.5 - half_w - 1.0, WALL_HEIGHT, 0.75),
		_concrete_mat(0.065),
		"architecture"
	)
	_static_box(
		"WallNorthEast",
		Vector3(half_w + 4.5, WALL_HEIGHT * 0.5, NORTH_Z),
		Vector3(FLOOR_SIZE.x * 0.5 - half_w - 1.0, WALL_HEIGHT, 0.75),
		_concrete_mat(0.065),
		"architecture"
	)
	_static_box(
		"WallNorthLintel",
		Vector3(0.0, lintel_y + 0.35, NORTH_Z),
		Vector3(VOID_WINDOW_WIDTH + 1.6, 0.7, 0.75),
		_concrete_mat(0.07),
		"architecture"
	)


func _build_loadout_bay_zone(parent: Node3D) -> void:
	_zone_parent = parent
	_static_box(
		"LoadoutBackWall",
		Vector3(-15.0, 2.0, 0.0),
		Vector3(0.65, 3.8, 14.5),
		_concrete_mat(0.065),
		"loadout"
	)
	_build_loadout_alcove_architecture(parent)
	var bay_light := OmniLight3D.new()
	bay_light.name = "LoadoutBayLight"
	bay_light.position = LOADOUT_BAY_CENTER + Vector3(0.5, 3.0, 0.0)
	bay_light.light_color = Color(0.32, 0.72, 0.88)
	bay_light.light_energy = 0.92
	bay_light.omni_range = 14.0
	bay_light.shadow_enabled = false
	parent.add_child(bay_light)


func _build_loadout_alcove_architecture(parent: Node3D) -> void:
	var steel := _black_steel_mat()
	var cyan := _emissive_accent(Color(0.1, 0.5, 0.62), 0.42)
	var wall_x: float = -14.35

	# Weapons alcove (+Z when facing west)
	_add_decor(
		parent, "WeaponsBackPanel", Vector3(wall_x, 1.45, 0.0),
		Vector3(0.14, 2.6, 5.6), _concrete_mat(0.07), "loadout"
	)
	_add_decor(
		parent, "WeaponsSupportL", Vector3(wall_x + 0.35, 1.0, 2.85),
		Vector3(0.18, 2.0, 0.18), steel, "loadout"
	)
	_add_decor(
		parent, "WeaponsSupportR", Vector3(wall_x + 0.35, 1.0, -2.85),
		Vector3(0.18, 2.0, 0.18), steel, "loadout"
	)
	_add_decor(
		parent, "WeaponsOverheadBeam", Vector3(wall_x + 0.2, 3.35, 0.0),
		Vector3(5.6, 0.22, 0.35), steel, "loadout"
	)

	# Armor recessed bay + raised platforms (visual only; pedestal positions unchanged)
	_add_decor(
		parent, "ArmorBayBack", Vector3(wall_x + 0.45, 1.15, 0.0),
		Vector3(0.14, 2.1, 4.6), _concrete_mat(0.065), "loadout"
	)
	_add_decor(
		parent, "ArmorBaySideL", Vector3(wall_x + 0.95, 0.55, 2.35),
		Vector3(0.12, 1.15, 0.12), steel, "loadout"
	)
	_add_decor(
		parent, "ArmorBaySideR", Vector3(wall_x + 0.95, 0.55, -2.35),
		Vector3(0.12, 1.15, 0.12), steel, "loadout"
	)
	for z in get_loadout_armor_z():
		_add_decor(
			parent, "ArmorRaisedPlatform",
			Vector3(LOADOUT_ARMOR_X, 0.1, z), Vector3(1.35, 0.08, 1.35), _stone_mat(), "loadout"
		)

	# Helmet narrow display wall + vertical strips
	_add_decor(
		parent, "HelmetDisplayWall", Vector3(-13.9, 1.35, 0.0),
		Vector3(0.1, 2.0, 4.6), _concrete_mat(0.06), "loadout"
	)
	for z in get_loadout_helmet_z():
		_add_decor(
			parent, "HelmetLightStrip_%d" % int(z),
			Vector3(-13.78, 1.05, z), Vector3(0.04, 1.55, 0.06), cyan, "loadout"
		)


func _build_command_area_zone(parent: Node3D) -> void:
	_zone_parent = parent
	var zone := Node3D.new()
	zone.name = "MapTable"
	zone.position = COMMAND_ZONE_CENTER
	parent.add_child(zone)

	var steel := _black_steel_mat()
	var core_glow := _emissive_accent(Color(0.1, 0.45, 0.55), 0.65)
	var table_y: float = 1.02
	_add_decor(zone, "TableBase", Vector3(0.0, 0.48, 0.0), Vector3(2.8, 0.9, 1.6), steel, "command")
	_add_decor(zone, "TableTop", Vector3(0.0, table_y, 0.0), Vector3(3.4, 0.12, 2.2), _stone_mat(), "command")
	_add_decor(zone, "MapSurface", Vector3(0.0, table_y + 0.1, 0.0), Vector3(2.6, 0.04, 1.5), core_glow, "command")
	var frame_mat := _black_steel_mat()
	_add_decor(zone, "TableFrameN", Vector3(0.0, table_y + 0.06, 1.12), Vector3(3.5, 0.08, 0.08), frame_mat, "command")
	_add_decor(zone, "TableFrameS", Vector3(0.0, table_y + 0.06, -1.12), Vector3(3.5, 0.08, 0.08), frame_mat, "command")
	_add_decor(zone, "TableFrameE", Vector3(1.72, table_y + 0.06, 0.0), Vector3(0.08, 0.08, 2.2), frame_mat, "command")
	_add_decor(zone, "TableFrameW", Vector3(-1.72, table_y + 0.06, 0.0), Vector3(0.08, 0.08, 2.2), frame_mat, "command")

	var holo_mat := _emissive_accent(Color(0.18, 0.58, 0.68), 0.9)
	holo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo_mat.albedo_color = Color(0.04, 0.18, 0.22, 0.4)
	var holo := _create_mesh(
		zone, "ArenaHologram", Vector3(0.0, 1.75, 0.0), Vector3(1.6, 0.85, 0.02), holo_mat
	)
	holo.rotation.x = -0.22
	_command_pieces += 1

	_build_command_center_decor(parent)

	var core_light := OmniLight3D.new()
	core_light.name = "MapTableLight"
	core_light.position = COMMAND_ZONE_CENTER + Vector3(0.0, 1.9, 0.0)
	core_light.light_color = Color(0.62, 0.66, 0.7)
	core_light.light_energy = 0.78
	core_light.omni_range = 8.0
	core_light.shadow_enabled = false
	parent.add_child(core_light)


func _build_command_center_decor(parent: Node3D) -> void:
	var steel := _black_steel_mat()
	var white_glow := _emissive_accent(Color(0.55, 0.58, 0.62), 0.28)
	var tpos: Vector3 = TERMINAL_POS

	_add_decor(
		parent, "CommandRearPanel", tpos + Vector3(0.0, 1.25, 1.15),
		Vector3(3.8, 2.5, 0.12), _concrete_mat(0.08), "command"
	)
	_add_decor(
		parent, "CommandConsoleL", tpos + Vector3(-2.15, 0.85, 0.0),
		Vector3(0.85, 1.15, 0.65), steel, "command"
	)
	_add_decor(
		parent, "CommandConsoleR", tpos + Vector3(2.15, 0.85, 0.0),
		Vector3(0.85, 1.15, 0.65), steel, "command"
	)
	_add_decor(
		parent, "CommandPendantHousing",
		tpos + Vector3(0.0, CEILING_Y - 4.15, 0.0),
		Vector3(1.4, 0.18, 1.4), steel, "command"
	)
	var pendant := OmniLight3D.new()
	pendant.name = "CommandPendantLight"
	pendant.position = tpos + Vector3(0.0, CEILING_Y - 4.35, 0.0)
	pendant.light_color = Color(0.72, 0.74, 0.78)
	pendant.light_energy = 1.05
	pendant.omni_range = 7.0
	pendant.shadow_enabled = false
	parent.add_child(pendant)
	_add_decor(
		parent, "CommandFloorOutline",
		COMMAND_ZONE_CENTER + Vector3(0.0, 0.04, 0.2),
		Vector3(5.8, 0.02, 5.8), white_glow, "command"
	)


func _build_progression_wall_zone(parent: Node3D) -> void:
	_zone_parent = parent
	var px: float = PROGRESSION_WALL_X
	var orange := _emissive_accent(Color(0.62, 0.32, 0.12), 0.32)
	var dim := _concrete_mat(0.055)

	_static_box(
		"ProgressionWall",
		Vector3(px, 2.0, 0.0),
		Vector3(0.55, 3.6, 14.0),
		_concrete_mat(0.06),
		"architecture"
	)
	_add_decor(
		parent, "ProgressionSealedPanel",
		Vector3(px + 0.26, 2.1, 0.0), Vector3(0.12, 3.2, 5.5), dim, "architecture"
	)
	_add_decor(
		parent, "ProgressionSealedGlow",
		Vector3(px + 0.3, 2.1, 0.0), Vector3(0.04, 2.8, 4.8), orange, "architecture"
	)
	for i in 3:
		var z_armor: float = -4.0 + float(i) * 4.0
		_add_decor(
			parent, "ProgressionArmorSilhouette_%d" % i,
			Vector3(px + 0.22, 1.35, z_armor),
			Vector3(0.1, 1.55, 0.55), dim, "architecture"
		)
	var slot_steel := _black_steel_mat()
	for i in 2:
		var z_weapon: float = 3.0 - float(i) * 6.0
		_add_decor(
			parent, "ProgressionWeaponSlot_%d" % i,
			Vector3(px + 0.2, 1.0, z_weapon),
			Vector3(0.14, 0.85, 1.2), slot_steel, "architecture"
		)
		_add_decor(
			parent, "ProgressionWeaponSlotGlow_%d" % i,
			Vector3(px + 0.24, 1.0, z_weapon),
			Vector3(0.05, 0.7, 0.9), orange, "architecture"
		)

	var prog_light := OmniLight3D.new()
	prog_light.name = "ProgressionWallAccent"
	prog_light.position = Vector3(px - 1.2, 2.4, 0.0)
	prog_light.light_color = Color(0.85, 0.48, 0.22)
	prog_light.light_energy = 0.55
	prog_light.omni_range = 9.0
	prog_light.shadow_enabled = false
	parent.add_child(prog_light)


func _build_void_window_zone(parent: Node3D) -> void:
	_zone_parent = parent
	var steel := _steel_mat()
	var frame_z: float = NORTH_Z + 0.15
	var sill_y: float = 1.15
	var half_w: float = VOID_WINDOW_WIDTH * 0.5

	_static_box(
		"VoidFrameL",
		Vector3(-half_w - 0.45, sill_y + VOID_WINDOW_HEIGHT * 0.5, frame_z),
		Vector3(0.58, VOID_WINDOW_HEIGHT + 0.28, 0.72),
		_black_steel_mat(),
		"architecture"
	)
	_static_box(
		"VoidFrameR",
		Vector3(half_w + 0.45, sill_y + VOID_WINDOW_HEIGHT * 0.5, frame_z),
		Vector3(0.58, VOID_WINDOW_HEIGHT + 0.28, 0.72),
		_black_steel_mat(),
		"architecture"
	)
	for i in 4:
		var seg_x: float = -VOID_WINDOW_WIDTH * 0.5 + 1.4 + float(i) * 2.8
		_static_box(
			"VoidFrameSill_%d" % i,
			Vector3(seg_x, sill_y - 0.08, frame_z),
			Vector3(2.6, 0.28, 0.65),
			steel,
			"architecture"
		)
	_static_box(
		"VoidFrameHeader",
		Vector3(0.0, sill_y + VOID_WINDOW_HEIGHT + 0.22, frame_z),
		Vector3(5.8, 0.38, 0.65),
		steel,
		"architecture"
	)

	_create_mesh(
		parent,
		"VoidWindowGlass",
		Vector3(0.0, sill_y + VOID_WINDOW_HEIGHT * 0.5, frame_z + 0.2),
		Vector3(VOID_WINDOW_WIDTH, VOID_WINDOW_HEIGHT, 0.08),
		_void_glass_mat()
	)
	_arch_pieces += 1

	_build_void_observatory_decor(parent, frame_z, sill_y, half_w)

	_observatory_omni = OmniLight3D.new()
	_observatory_omni.name = "VoidWindowLight"
	_observatory_omni.position = Vector3(0.0, 2.2, frame_z - 3.5)
	_observatory_omni.light_color = Color(0.28, 0.55, 0.72)
	_observatory_omni.light_energy = 0.52
	_observatory_omni.omni_range = 14.0
	_observatory_omni.shadow_enabled = false
	parent.add_child(_observatory_omni)

	_void_floor_glow = OmniLight3D.new()
	_void_floor_glow.name = "VoidFloorUplight"
	_void_floor_glow.position = Vector3(0.0, 0.15, frame_z + 1.2)
	_void_floor_glow.light_color = Color(0.2, 0.48, 0.68)
	_void_floor_glow.light_energy = 0.48
	_void_floor_glow.omni_range = 8.0
	_void_floor_glow.shadow_enabled = false
	parent.add_child(_void_floor_glow)


func _build_void_observatory_decor(
	parent: Node3D, frame_z: float, sill_y: float, half_w: float
) -> void:
	var steel := _steel_mat()
	var blue_glow := _emissive_accent(Color(0.12, 0.42, 0.58), 0.38)

	_static_box(
		"VoidObservatoryStep",
		Vector3(0.0, 0.06, frame_z + 1.35),
		Vector3(5.5, 0.12, 1.4),
		_stone_mat(),
		"architecture"
	)
	_add_decor(
		parent, "VoidObsUnderglow",
		Vector3(0.0, 0.04, frame_z + 0.85),
		Vector3(5.2, 0.03, 0.35), blue_glow, "architecture"
	)
	_static_box(
		"VoidObsPillarL",
		Vector3(-half_w - 0.15, sill_y + 0.35, frame_z + 1.1),
		Vector3(0.35, 2.2, 0.35),
		_black_steel_mat(),
		"architecture"
	)
	_static_box(
		"VoidObsPillarR",
		Vector3(half_w + 0.15, sill_y + 0.35, frame_z + 1.1),
		Vector3(0.35, 2.2, 0.35),
		_black_steel_mat(),
		"architecture"
	)
	for side in [-1.0, 1.0]:
		_add_decor(
			parent, "VoidObsRail_%d" % int(side),
			Vector3(side * (half_w - 0.6), sill_y + 0.12, frame_z + 1.55),
			Vector3(0.1, 0.75, 2.8), steel, "architecture"
		)


func _build_zone_lighting(parent: Node3D) -> void:
	_add_overhead_spot(
		parent, LOADOUT_BAY_CENTER + Vector3(0.0, CEILING_Y - 0.35, 0.0),
		Color(0.45, 0.78, 0.92), 1.05, 14.0
	)
	_add_overhead_spot(
		parent, COMMAND_ZONE_CENTER + Vector3(0.0, CEILING_Y - 0.35, 0.0),
		Color(0.78, 0.8, 0.84), 0.95, 11.0
	)
	_add_overhead_spot(
		parent, TERMINAL_POS + Vector3(0.0, CEILING_Y - 0.35, 0.0),
		Color(0.75, 0.78, 0.82), 1.0, 9.0
	)
	_add_overhead_spot(
		parent, Vector3(0.0, CEILING_Y - 0.28, NORTH_Z + 1.5),
		Color(0.35, 0.58, 0.78), 0.72, 11.0
	)
	_add_overhead_spot(
		parent, Vector3(PROGRESSION_WALL_X - 2.0, CEILING_Y - 0.35, 0.0),
		Color(0.88, 0.52, 0.22), 0.65, 10.0
	)


func _build_atmosphere(parent: Node3D) -> void:
	var dust := CPUParticles3D.new()
	dust.name = "ChamberDust"
	dust.emitting = true
	dust.amount = 18
	dust.lifetime = 7.0
	dust.preprocess = 2.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(5.0, 1.0, 4.0)
	dust.direction = Vector3(0.05, 0.02, -0.08)
	dust.spread = 18.0
	dust.gravity = Vector3(0.0, -0.01, 0.0)
	dust.initial_velocity_min = 0.04
	dust.initial_velocity_max = 0.18
	dust.scale_amount_min = 0.1
	dust.scale_amount_max = 0.3
	dust.color = Color(0.4, 0.42, 0.45, 0.1)
	dust.position = Vector3(0.0, 2.0, 0.0)
	parent.add_child(dust)


func _cleanup_chamber_visual_clutter(root: Node3D) -> void:
	_cleanup_node_recursive(root)


func _cleanup_node_recursive(node: Node) -> void:
	if node.name == "DistantArchitecture":
		return
	var children: Array[Node] = []
	for child in node.get_children():
		children.append(child)
	for child in children:
		_cleanup_node_recursive(child)
	if node is MeshInstance3D and _should_remove_clutter_mesh(node as MeshInstance3D):
		_clutter_removed += 1
		(node as MeshInstance3D).queue_free()


func _should_remove_clutter_mesh(mesh_inst: MeshInstance3D) -> bool:
	if _is_essential_chamber_mesh(mesh_inst):
		return false
	var box_mesh: BoxMesh = mesh_inst.mesh as BoxMesh
	if box_mesh == null:
		return false
	var sz: Vector3 = box_mesh.size
	var wp: Vector3 = mesh_inst.global_position
	var span_xz: float = maxf(sz.x, sz.z)
	if wp.y < CHAMBER_CLUTTER_Y_MIN or wp.y > CHAMBER_CLUTTER_Y_MAX:
		return false
	if span_xz <= CHAMBER_INTERIOR_MAX_SPAN:
		return false
	return true


func _is_essential_chamber_mesh(mesh_inst: MeshInstance3D) -> bool:
	var n: String = mesh_inst.name
	if n == "Floor" or n == "Ceiling":
		return true
	if n.begins_with("Wall") or n.begins_with("VoidFrame") or n.begins_with("VoidObs"):
		return true
	if n == "LoadoutBackWall" or n == "ProgressionWall":
		return true
	if n.begins_with("Progression") or n.begins_with("Weapons") or n.begins_with("Armor") or n.begins_with("Helmet"):
		return true
	if n.begins_with("Command") or n.begins_with("Table"):
		return true
	if n == "VoidWindowGlass":
		return true
	if n in ["TableTop", "TableBase", "MapSurface", "ArenaHologram", "Console", "Screen"]:
		return true
	if n in ["StationBase", "VerticalSupport", "WeaponMount", "WeaponMesh", "Mannequin", "HelmetMesh"]:
		return true
	if n == "Highlight":
		return true
	return _has_pedestal_or_terminal_ancestor(mesh_inst)


func _has_pedestal_or_terminal_ancestor(node: Node) -> bool:
	var p: Node = node
	while p:
		var nm: String = p.name
		if (
			nm.begins_with("WeaponPedestal")
			or nm.begins_with("ArmorPedestal")
			or nm.begins_with("HelmetStand")
			or nm == "ArenaTerminal"
		):
			return true
		p = p.get_parent()
	return false


func _debug_scan_all_meshes(root: Node3D) -> void:
	print("--- Chamber post-build mesh scan (world space) ---")
	_debug_scan_meshes_recursive(root)
	print("--- end mesh scan ---")


func _debug_scan_meshes_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		var sz: Vector3 = _mesh_instance_size(mesh_inst)
		if sz != Vector3.ZERO:
			var wp: Vector3 = mesh_inst.global_position
			var path: String = str(mesh_inst.get_path())
			print("CHAMBER OBJ:", mesh_inst.name, "size=", sz, "pos=", wp, "path=", path)
			if sz.x > 4.0 or sz.z > 4.0:
				push_warning("LARGE CHAMBER OBJECT (scan) -> %s" % mesh_inst.name)
	for child in node.get_children():
		_debug_scan_meshes_recursive(child)


func _mesh_instance_size(mesh_inst: MeshInstance3D) -> Vector3:
	var scale: Vector3 = mesh_inst.global_transform.basis.get_scale()
	var box_mesh: BoxMesh = mesh_inst.mesh as BoxMesh
	if box_mesh != null:
		return Vector3(
			box_mesh.size.x * scale.x,
			box_mesh.size.y * scale.y,
			box_mesh.size.z * scale.z
		)
	var sphere: SphereMesh = mesh_inst.mesh as SphereMesh
	if sphere != null:
		var d: float = sphere.radius * 2.0
		return Vector3(
			d * scale.x,
			sphere.height * scale.y,
			d * scale.z
		)
	return Vector3.ZERO


func _print_chamber_build_summary() -> void:
	print("Chamber zones built:")
	print("  - Architecture (shell)")
	print("  - LoadoutBay (alcoves + stations)")
	print("  - CommandArea (map table + command center)")
	print("  - ProgressionWall (upgrade placeholders)")
	print("  - VoidWindow (observatory)")
	print("  - Lighting / Atmosphere")
	print("  - DistantArchitecture (sanitized)")
	print("Chamber build summary:")
	print("- architecture pieces: ", _arch_pieces)
	print("- loadout pieces: ", _loadout_pieces)
	print("- command pieces: ", _command_pieces)
	if CHAMBER_CLEANUP_ENABLED:
		print("- interior spans > %.1f removed: %d" % [CHAMBER_INTERIOR_MAX_SPAN, _clutter_removed])
	else:
		print("- interior cleanup: disabled")


func _count_zone(zone: String) -> void:
	match zone:
		"architecture":
			_arch_pieces += 1
		"loadout":
			_loadout_pieces += 1
		"command":
			_command_pieces += 1


func _concrete_mat(bright: float = 0.1) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var b: float = bright * 0.82
	m.albedo_color = Color(b * 0.94, b * 0.92, b * 0.9)
	m.roughness = 0.94
	m.metallic = 0.06
	return m


func _stone_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.07, 0.068, 0.065)
	m.roughness = 0.97
	m.metallic = 0.02
	return m


func _steel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.11, 0.115, 0.12)
	m.metallic = 0.62
	m.roughness = 0.82
	return m


func _black_steel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.052, 0.058)
	m.metallic = 0.78
	m.roughness = 0.7
	return m


func _emissive_accent(color: Color, strength: float = 0.35) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color.darkened(0.65)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = strength
	m.roughness = 0.88
	return m


func _void_glass_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.04, 0.1, 0.12, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	m.metallic = 0.35
	m.emission_enabled = true
	m.emission = Color(0.08, 0.2, 0.24)
	m.emission_energy_multiplier = 0.18
	return m


func _apply_chamber_fog(env: Environment, density_scale: float) -> void:
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.1, 0.09)
	env.fog_light_energy = 1.0
	env.fog_density = _base_fog_density * density_scale
	env.fog_sky_affect = 0.0


func _build_interactables(loadout_parent: Node3D, command_parent: Node3D) -> void:
	_build_loadout_stations(loadout_parent)
	_add_arena_terminal(command_parent, TERMINAL_POS)


func _build_loadout_stations(parent: Node3D) -> void:
	var weapon_choices: Array[int] = [
		GladiatorLoadout.WeaponChoice.RAILGUN,
		GladiatorLoadout.WeaponChoice.SHOTGUN,
		GladiatorLoadout.WeaponChoice.BAZOOKA,
	]
	for i in 3:
		_add_weapon_pedestal(
			parent,
			Vector3(LOADOUT_WEAPON_X, 0.0, get_loadout_weapon_z()[i]),
			weapon_choices[i]
		)
	var armor_choices: Array[int] = [
		GladiatorLoadout.ArmorChoice.LIGHT,
		GladiatorLoadout.ArmorChoice.MEDIUM,
		GladiatorLoadout.ArmorChoice.HEAVY,
	]
	var armor_scales: Array[float] = [0.85, 1.0, 1.2]
	for i in 3:
		_add_armor_pedestal(
			parent,
			Vector3(LOADOUT_ARMOR_X, 0.0, get_loadout_armor_z()[i]),
			armor_choices[i],
			armor_scales[i]
		)
	var helmet_choices: Array[int] = [
		GladiatorLoadout.HelmetChoice.CUSTODIAN,
		GladiatorLoadout.HelmetChoice.OBSERVER,
		GladiatorLoadout.HelmetChoice.FACELESS,
	]
	for i in 3:
		_add_helmet_stand(
			parent,
			Vector3(LOADOUT_HELMET_X, 0.0, get_loadout_helmet_z()[i]),
			helmet_choices[i]
		)


func _log_chamber_obj(mesh_name: String, size: Vector3, pos: Vector3) -> void:
	if not CHAMBER_MESH_DEBUG:
		return
	print("CHAMBER OBJ:", mesh_name, "size=", size, "pos=", pos)
	if size.x > 4.0 or size.z > 4.0:
		push_warning("LARGE CHAMBER OBJECT -> " + mesh_name)


func _world_pos_for(parent: Node3D, local_pos: Vector3) -> Vector3:
	if parent == null:
		return local_pos
	if parent.is_inside_tree():
		return parent.to_global(local_pos)
	return parent.global_position + local_pos


func _create_mesh(
	parent: Node3D,
	mesh_name: String,
	pos: Vector3,
	size: Vector3,
	mat: Material = null
) -> MeshInstance3D:
	size = _clamp_interior_span(mesh_name, size)
	var world_pos: Vector3 = _world_pos_for(parent, pos)
	_log_chamber_obj(mesh_name, size, world_pos)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = mesh_name
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	if mat != null:
		mesh_inst.material_override = mat
	mesh_inst.position = pos
	parent.add_child(mesh_inst)
	return mesh_inst


func _clamp_interior_span(mesh_name: String, size: Vector3) -> Vector3:
	if _is_shell_mesh_name(mesh_name):
		return size
	return Vector3(
		minf(size.x, CHAMBER_INTERIOR_MAX_SPAN),
		size.y,
		minf(size.z, CHAMBER_INTERIOR_MAX_SPAN)
	)


func _is_shell_mesh_name(mesh_name: String) -> bool:
	if mesh_name in ["Floor", "Ceiling", "LoadoutBackWall", "ProgressionWall", "VoidWindowGlass"]:
		return true
	if mesh_name.begins_with("Wall") or mesh_name.begins_with("VoidFrame"):
		return true
	return false


func _static_box(
	name: String, pos: Vector3, size: Vector3, mat: Material, zone: String = "architecture"
) -> StaticBody3D:
	size = _clamp_interior_span(name, size)
	var world_pos: Vector3 = _world_pos_for(_zone_parent, pos)
	_log_chamber_obj(name, size, world_pos)
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
	_zone_parent.add_child(body)
	_count_zone(zone)
	return body


func _add_decor(
	parent: Node3D,
	node_name: String,
	pos: Vector3,
	size: Vector3,
	mat: Material,
	zone: String = "architecture"
) -> MeshInstance3D:
	var mesh_inst := _create_mesh(parent, node_name, pos, size, mat)
	_count_zone(zone)
	return mesh_inst


func _add_interact_area(parent: Node3D, size: Vector3) -> Area3D:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	parent.add_child(area)
	return area


func _add_station_base(parent: Node3D, base_size: Vector3) -> void:
	var clamped := Vector3(
		minf(base_size.x, CHAMBER_LOCAL_MAX_XZ),
		base_size.y,
		minf(base_size.z, CHAMBER_LOCAL_MAX_XZ)
	)
	_create_mesh(parent, "StationBase", Vector3(0.0, clamped.y * 0.5, 0.0), clamped, _stone_mat())
	_loadout_pieces += 1


func _weapon_visual_size(choice: int) -> Vector3:
	match choice:
		GladiatorLoadout.WeaponChoice.SHOTGUN:
			return Vector3(0.38, 0.14, 0.22)
		GladiatorLoadout.WeaponChoice.BAZOOKA:
			return Vector3(0.32, 0.18, 0.32)
		_:
			return Vector3(0.22, 0.12, 0.22)


func _add_weapon_pedestal(parent: Node3D, pos: Vector3, choice: int) -> void:
	var root := Node3D.new()
	root.name = "WeaponPedestal_%d" % choice
	root.position = pos

	var base_size: Vector3 = WEAPON_STATION_BASE
	var support_size: Vector3 = STATION_SUPPORT
	var mount_size: Vector3 = WEAPON_MOUNT_SIZE
	var visual_size: Vector3 = _weapon_visual_size(choice)

	var support_y: float = base_size.y + support_size.y * 0.5
	var mount_y: float = base_size.y + support_size.y + mount_size.y * 0.5
	var visual_y: float = base_size.y + support_size.y + mount_size.y + visual_size.y * 0.5
	var altar_top: float = base_size.y + support_size.y + mount_size.y + visual_size.y

	_add_station_base(root, base_size)

	_create_mesh(root, "VerticalSupport", Vector3(0.0, support_y, 0.0), support_size, _black_steel_mat())
	_loadout_pieces += 1

	_create_mesh(root, "WeaponMount", Vector3(0.0, mount_y, 0.0), mount_size, _steel_mat())
	_loadout_pieces += 1

	_create_mesh(root, "WeaponMesh", Vector3(0.0, visual_y, 0.0), visual_size, _black_steel_mat())
	_loadout_pieces += 1

	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.albedo_color = Color(0.2, 0.55, 0.65, 0.22)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(0.15, 0.5, 0.6)
	highlight_mat.emission_energy_multiplier = 0.5
	var highlight := _create_mesh(
		root,
		"Highlight",
		Vector3(0.0, altar_top * 0.5, 0.0),
		Vector3(1.15, altar_top + 0.12, 1.15),
		highlight_mat
	)
	highlight.visible = false

	var spot := OmniLight3D.new()
	spot.name = "PedestalLight"
	spot.position = Vector3(0.0, support_y, 0.0)
	spot.light_color = Color(0.4, 0.75, 0.88)
	spot.light_energy = 0.48
	spot.omni_range = 4.0
	spot.shadow_enabled = false
	root.add_child(spot)

	var interact_h: float = altar_top + 0.2
	var area := _add_interact_area(root, Vector3(1.15, interact_h, 1.15))
	area.position = Vector3(0.0, interact_h * 0.5, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_weapon_rack.gd") as Script
	area.set_script(script)
	area.set("weapon_choice", choice)
	parent.add_child(root)


func _add_armor_pedestal(parent: Node3D, pos: Vector3, choice: int, scale_y: float) -> void:
	var root := Node3D.new()
	root.name = "ArmorPedestal_%d" % choice
	root.position = pos
	var base_size: Vector3 = ARMOR_STATION_BASE
	_add_station_base(root, base_size)
	var mat := _concrete_mat(0.13)
	mat.emission_enabled = false
	var mannequin_pos := Vector3(0.0, base_size.y + 0.92 * scale_y, 0.0)
	_create_mesh(root, "Mannequin", mannequin_pos, Vector3(0.88, 1.65 * scale_y, 0.52), mat)
	_loadout_pieces += 1
	var hmat := StandardMaterial3D.new()
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = Color(0.45, 0.28, 0.15, 0.18)
	hmat.emission_enabled = true
	hmat.emission = Color(0.5, 0.32, 0.18)
	hmat.emission_energy_multiplier = 0.35
	var highlight := _create_mesh(
		root,
		"Highlight",
		mannequin_pos,
		Vector3(1.15, 1.85 * scale_y, 0.75),
		hmat
	)
	highlight.visible = false
	var area := _add_interact_area(root, Vector3(1.8, 2.2, 1.8))
	area.position = Vector3(0.0, 1.0, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_armor_pedestal.gd") as Script
	area.set_script(script)
	area.set("armor_choice", choice)
	parent.add_child(root)


func _add_helmet_stand(parent: Node3D, pos: Vector3, choice: int) -> void:
	var root := Node3D.new()
	root.name = "HelmetStand_%d" % choice
	root.position = pos
	var base_size: Vector3 = HELMET_STATION_BASE
	_add_station_base(root, base_size)
	var support_size: Vector3 = STATION_SUPPORT
	_create_mesh(
		root,
		"VerticalSupport",
		Vector3(0.0, base_size.y + support_size.y * 0.5, 0.0),
		support_size,
		_black_steel_mat()
	)
	_loadout_pieces += 1
	var helmet_pos := Vector3(0.0, base_size.y + support_size.y + 0.28, 0.0)
	_log_chamber_obj("HelmetMesh", Vector3(0.56, 0.5, 0.56), _world_pos_for(root, helmet_pos))
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
	helmet.position = helmet_pos
	root.add_child(helmet)
	_loadout_pieces += 1
	var area := _add_interact_area(root, Vector3(1.0, 2.0, 1.0))
	area.position = Vector3(0.0, 1.0, 0.0)
	var script: Script = load("res://scripts/chamber/chamber_helmet_stand.gd") as Script
	area.set_script(script)
	area.set("helmet_choice", choice)
	parent.add_child(root)


func _add_arena_terminal(parent: Node3D, pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "ArenaTerminal"
	root.position = pos
	_create_mesh(root, "Console", Vector3(0.0, 0.9, 0.0), Vector3(2.2, 1.4, 0.8), _black_steel_mat())
	_command_pieces += 1
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.05, 0.12, 0.14)
	smat.emission_enabled = true
	smat.emission = Color(0.1, 0.35, 0.4)
	smat.emission_energy_multiplier = 0.6
	_create_mesh(root, "Screen", Vector3(0.0, 1.05, 0.42), Vector3(1.6, 0.7, 0.05), smat)
	_command_pieces += 1
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
	parent.add_child(root)


func _add_overhead_spot(
	parent: Node3D, pos: Vector3, color: Color, energy: float, range: float
) -> void:
	var spot := SpotLight3D.new()
	spot.position = pos
	spot.rotation_degrees = Vector3(-88.0, 0.0, 0.0)
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = range
	spot.spot_angle = 48.0
	spot.spot_attenuation = 1.1
	spot.shadow_enabled = false
	parent.add_child(spot)


func _apply_return_mood(mood: int) -> void:
	_mood_state = mood
	if mood > 0:
		_apply_victory_mood()
	else:
		_apply_defeat_mood()


func _apply_victory_mood() -> void:
	print("Chamber: victory return — clarity")
	if _world_env and _world_env.environment:
		_apply_chamber_fog(_world_env.environment, 0.65)
	if _key_light:
		_key_light.light_energy = _base_key_energy * 1.2
	if _observatory_omni:
		_observatory_omni.light_energy = 0.55
	if _void_floor_glow:
		_void_floor_glow.light_energy = 0.52
	_mood_timer = 55.0


func _apply_defeat_mood() -> void:
	print("Chamber: defeat return — weight")
	if _world_env and _world_env.environment:
		_apply_chamber_fog(_world_env.environment, 1.45)
	if _key_light:
		_key_light.light_energy = _base_key_energy * 0.55
	if _observatory_omni:
		_observatory_omni.light_energy = 0.65
	if _void_floor_glow:
		_void_floor_glow.light_energy = 0.55
	_mood_timer = 28.0


func _apply_neutral_mood() -> void:
	_mood_state = 0
	if _world_env and _world_env.environment:
		_apply_chamber_fog(_world_env.environment, 1.0)
	if _key_light:
		_key_light.light_energy = _base_key_energy
	if _observatory_omni:
		_observatory_omni.light_energy = 0.35
	if _void_floor_glow:
		_void_floor_glow.light_energy = 0.38
