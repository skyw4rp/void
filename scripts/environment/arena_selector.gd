## Picks a random combat arena each round and shows only that zone.
class_name ArenaSelector
extends Node3D

var _arenas: Array[ArenaZone] = []
var _current: ArenaZone
var _last_display_name: String = ""


func _ready() -> void:
	add_to_group("arena_selector")
	_collect_arenas()
	for arena in _arenas:
		arena.set_arena_visible(false)
	if _arenas.is_empty():
		push_warning("ArenaSelector: no ArenaZone children found.")


func get_current_arena() -> ArenaZone:
	return _current


func pick_arena_for_round() -> ArenaZone:
	if _arenas.is_empty():
		return null

	var candidates: Array[ArenaZone] = []
	for arena in _arenas:
		if arena.display_name != _last_display_name or _arenas.size() <= 2:
			candidates.append(arena)

	if candidates.is_empty():
		candidates = _arenas.duplicate()

	var pick: ArenaZone = candidates.pick_random()
	_activate_arena(pick)
	_last_display_name = pick.display_name
	print("Round arena selected: %s" % pick.display_name)
	return pick


func _collect_arenas() -> void:
	_arenas.clear()
	for child in get_children():
		if child is ArenaZone:
			_arenas.append(child as ArenaZone)


func _activate_arena(active: ArenaZone) -> void:
	_current = active
	for arena in _arenas:
		arena.set_arena_visible(arena == active)
