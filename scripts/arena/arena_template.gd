## Data for one procedurally built compact combat arena.
class_name ArenaTemplate
extends RefCounted


class FloorPiece:
	var size: Vector3 = Vector3.ONE
	var position: Vector3 = Vector3.ZERO  ## Slab center in arena-local space (deck top at y=0).


class WallPiece:
	var size: Vector3 = Vector3(2.0, 2.2, 0.25)
	var position: Vector3 = Vector3.ZERO  ## Wall center in arena-local space.


class AiBounds:
	var safe_half_x: float = 3.0
	var danger_half_x: float = 3.8
	var safe_half_z: float = 3.0
	var danger_half_z: float = 4.2


## Outer ruined enclosure (~60–80% walls, openings only on listed sides).
class PerimeterConfig:
	var enabled: bool = true
	var half_extents: Vector2 = Vector2(8.0, 8.0)
	var outward_margin: float = 2.5
	var coverage: float = 0.72
	var destructible_ratio: float = 0.28
	var decor_silhouettes: bool = true
	## Side indices 0=+Z,1=-Z,2=+X,3=-X — middle slots stay open for ring-outs.
	var ringout_open_sides: Array[int] = []


class FallZoneMarker:
	var position: Vector3 = Vector3.ZERO
	var size: Vector3 = Vector3(3.0, 0.08, 0.35)
	var rotation_y: float = 0.0


var template_id: int = 0
var arena_name: String = "Arena"
var center_position: Vector3 = Vector3.ZERO
var floor_pieces: Array[FloorPiece] = []
var wall_pieces: Array[WallPiece] = []
var player_spawn_local: Vector3 = Vector3(0.0, 1.0, 5.0)
var enemy_spawn_local: Vector3 = Vector3(0.0, 1.0, -5.0)
var debris_bounds: Dictionary = {
	"x_min": -3.0, "x_max": 3.0, "z_min": -3.0, "z_max": 3.0,
}
var ai_bounds: AiBounds = AiBounds.new()
var void_y: float = -32.0
var fall_warning_y: float = -18.0
## Inner spawn/debris rectangle (local X/Z half extents from center).
var spawn_safe_half: Vector2 = Vector2(6.0, 6.0)
var fall_zones: Array[FallZoneMarker] = []
var floor_albedo: Color = Color(0.11, 0.105, 0.12)
var wall_albedo: Color = Color(0.07, 0.075, 0.085)
var perimeter: PerimeterConfig = PerimeterConfig.new()


static func perimeter_from_bounds(bounds: AiBounds, margin: float = 2.0, coverage: float = 0.55) -> PerimeterConfig:
	var cfg := PerimeterConfig.new()
	cfg.half_extents = Vector2(bounds.danger_half_x + margin, bounds.danger_half_z + margin)
	cfg.outward_margin = margin
	cfg.coverage = coverage
	return cfg


static func make_floor(size: Vector3, center: Vector3) -> FloorPiece:
	var piece := FloorPiece.new()
	piece.size = size
	piece.position = center
	return piece


static func make_wall(size: Vector3, center: Vector3) -> WallPiece:
	var piece := WallPiece.new()
	piece.size = size
	piece.position = center
	return piece


## Slab with deck surface at y=0.
static func slab(sx: float, sy: float, sz: float, cx: float, cy_offset: float, cz: float) -> FloorPiece:
	return make_floor(Vector3(sx, sy, sz), Vector3(cx, cy_offset, cz))


## Wall centered at local position (full height ~2.2 unless size.y is lower).
static func wall(wx: float, wy: float, wz: float, cx: float, cy: float, cz: float) -> WallPiece:
	return make_wall(Vector3(wx, wy, wz), Vector3(cx, cy, cz))
