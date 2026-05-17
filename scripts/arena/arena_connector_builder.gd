## Adds non-destructible floor bridge data when spawn route validation fails.
class_name ArenaConnectorBuilder
extends RefCounted

const MIN_BRIDGE_WIDTH: float = 4.0


static func append_connector_floor(template: ArenaTemplate) -> ArenaTemplate.FloorPiece:
	var player: Vector3 = template.player_spawn_local
	var enemy: Vector3 = template.enemy_spawn_local
	var delta: Vector3 = enemy - player
	var span_xz: Vector2 = Vector2(delta.x, delta.z)
	var distance: float = span_xz.length()

	var th: float = 0.28
	var hy: float = -th * 0.5
	var mid: Vector3 = Vector3(
		(player.x + enemy.x) * 0.5,
		hy,
		(player.z + enemy.z) * 0.5
	)

	var size: Vector3
	if distance < 1.5:
		size = Vector3(MIN_BRIDGE_WIDTH, th, MIN_BRIDGE_WIDTH)
	else:
		if absf(delta.x) >= absf(delta.z):
			size = Vector3(distance + 3.0, th, MIN_BRIDGE_WIDTH)
		else:
			size = Vector3(MIN_BRIDGE_WIDTH, th, distance + 3.0)

	var piece: ArenaTemplate.FloorPiece = ArenaTemplate.make_floor(size, mid)
	piece.is_connector = true
	template.floor_pieces.append(piece)
	print("Route invalid, adding connector")
	return piece
