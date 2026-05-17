## Reusable shield / health pool — damage hits shield first, overflow hits health.
class_name CombatStats
extends Node

signal stats_changed(shield: int, health: int)
signal died(attacker: Node)

@export var max_health: int = 100
@export var max_shield: int = 100
@export var debug_name: String = "Fighter"

var health: int = 100
var shield: int = 100

var last_hit_direction: Vector3 = Vector3.FORWARD
var last_hit_force: float = 24.0
var last_attacker: Node = null
var last_damage_source: String = ""


func _ready() -> void:
	reset_combat_stats()


func reset_combat_stats() -> void:
	health = max_health
	shield = max_shield
	last_hit_direction = Vector3.FORWARD
	last_hit_force = 24.0
	last_attacker = null
	last_damage_source = ""
	stats_changed.emit(shield, health)
	_log_stats()


func record_hit(
	direction: Vector3, force: float, attacker: Node = null, source: String = ""
) -> void:
	if direction.length_squared() > 0.001:
		last_hit_direction = direction.normalized()
	if force > 0.0:
		last_hit_force = force
	if attacker != null:
		last_attacker = attacker
	if source != "":
		last_damage_source = source


func get_corpse_launch_force() -> float:
	var mult: float = 1.0
	match last_damage_source:
		"bazooka_explosion":
			mult = 2.4
		"bazooka_direct":
			mult = 1.9
		"shotgun":
			mult = 1.25
		_:
			mult = 1.1
	return clampf(last_hit_force * mult, 28.0, 110.0)


func get_corpse_upward_boost() -> float:
	if last_damage_source == "bazooka_explosion":
		return 12.0
	if last_damage_source == "bazooka_direct":
		return 9.0
	return 6.0


func apply_damage(amount: int, attacker: Node = null) -> void:
	if is_dead() or amount <= 0:
		return

	var remaining: int = amount
	if shield > 0:
		var absorbed: int = mini(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0:
		health = maxi(0, health - remaining)

	_log_stats()
	stats_changed.emit(shield, health)
	if is_dead():
		died.emit(attacker)


func is_dead() -> bool:
	return health <= 0


func is_low() -> bool:
	return shield <= 30 or health <= 40


func _log_stats() -> void:
	print("%s shield: %d health: %d" % [debug_name, shield, health])
