## Reusable shield / health pool — damage hits shield first, overflow hits health.
class_name CombatStats
extends Node

signal stats_changed(shield: int, health: int)
signal died(attacker: Node)
signal shield_broken(source: String)

const HEAVY_OVERKILL_THRESHOLD: int = 25
const HEAVY_DAMAGE_THRESHOLD: int = 40

@export var max_health: int = 100
@export var max_shield: int = 100
@export var debug_name: String = "Fighter"

var health: int = 100
var shield: int = 100

var last_hit_direction: Vector3 = Vector3.FORWARD
var last_hit_force: float = 24.0
var last_attacker: Node = null
var last_damage_source: String = ""
var last_damage_amount: int = 0
var overkill_amount: int = 0
var last_explosion_origin: Vector3 = Vector3.ZERO
var has_last_explosion_origin: bool = false
var last_hit_world_position: Vector3 = Vector3.ZERO
var has_last_hit_world_position: bool = false


func _ready() -> void:
	reset_combat_stats()


func reset_combat_stats() -> void:
	health = max_health
	shield = max_shield
	last_hit_direction = Vector3.FORWARD
	last_hit_force = 24.0
	last_attacker = null
	last_damage_source = ""
	last_damage_amount = 0
	overkill_amount = 0
	last_explosion_origin = Vector3.ZERO
	has_last_explosion_origin = false
	last_hit_world_position = Vector3.ZERO
	has_last_hit_world_position = false
	stats_changed.emit(shield, health)
	_log_stats()


func record_hit(
	direction: Vector3,
	force: float,
	attacker: Node = null,
	source: String = "",
	explosion_origin: Vector3 = Vector3(INF, INF, INF),
	hit_world: Vector3 = Vector3(INF, INF, INF)
) -> void:
	if direction.length_squared() > 0.001:
		last_hit_direction = direction.normalized()
	if force > 0.0:
		last_hit_force = force
	if attacker != null:
		last_attacker = attacker
	if source != "":
		last_damage_source = source
	if explosion_origin.x < INF * 0.5:
		last_explosion_origin = explosion_origin
		has_last_explosion_origin = true
	if hit_world.x < INF * 0.5:
		last_hit_world_position = hit_world
		has_last_hit_world_position = true


func get_corpse_launch_force() -> float:
	return clampf(last_hit_force, 12.0, 85.0)


func get_corpse_upward_boost() -> float:
	match last_damage_source:
		"bazooka_explosion":
			return 8.0
		"bazooka_direct":
			return 6.0
		"shotgun":
			return 4.0
		"railgun":
			return 2.5
		_:
			return 3.0


func is_heavy_death() -> bool:
	if last_damage_source == "bazooka_direct" or last_damage_source == "bazooka_explosion":
		return true
	if overkill_amount >= HEAVY_OVERKILL_THRESHOLD:
		return true
	if last_damage_amount >= HEAVY_DAMAGE_THRESHOLD:
		return true
	return false


func is_dismemberment_death() -> bool:
	if is_heavy_death():
		return true
	if last_damage_source == "shotgun" and last_damage_amount >= 28:
		return true
	if last_damage_source == "railgun" and overkill_amount >= 8:
		return true
	return false


func get_dismemberment_profile() -> String:
	match last_damage_source:
		"bazooka_explosion":
			return "explosion"
		"bazooka_direct":
			return "rocket_direct"
		"shotgun":
			return "shotgun"
		"railgun":
			return "railgun"
		_:
			return "heavy"


func get_player_death_message() -> String:
	match last_damage_source:
		"shotgun":
			return "YOU WERE TORN APART"
		"bazooka_direct", "bazooka_explosion":
			return "YOU WERE OBLITERATED"
		"railgun":
			if overkill_amount >= HEAVY_OVERKILL_THRESHOLD or last_damage_amount >= HEAVY_DAMAGE_THRESHOLD:
				return "YOU WERE OBLITERATED"
			return "YOU WERE TORN APART"
	if is_heavy_death():
		return "YOU WERE OBLITERATED"
	return "You were eliminated!"


func apply_damage(amount: int, attacker: Node = null) -> void:
	if is_dead() or amount <= 0:
		return

	last_damage_amount = amount
	overkill_amount = 0

	var shield_before: int = shield
	var remaining: int = amount
	if shield > 0:
		var absorbed: int = mini(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0:
		health -= remaining
		if health < 0:
			overkill_amount = absi(health)
			health = 0

	if shield_before > 0 and shield <= 0:
		shield_broken.emit(last_damage_source)
		CombatFeedback.on_shield_broken(self)

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
