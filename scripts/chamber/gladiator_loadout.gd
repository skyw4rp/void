## Local gladiator loadout persistence (MVP — no backend).
extends Node

enum WeaponChoice { RAILGUN, SHOTGUN, BAZOOKA }
enum ArmorChoice { LIGHT, MEDIUM, HEAVY }
enum HelmetChoice { CUSTODIAN, OBSERVER, FACELESS, BROKEN, CORRUPTED }

const SAVE_PATH: String = "user://gladiator_loadout.cfg"

signal loadout_changed

var weapon: int = WeaponChoice.RAILGUN
var armor: int = ArmorChoice.MEDIUM
var helmet: int = HelmetChoice.FACELESS


func _ready() -> void:
	load_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	if err != OK:
		return
	weapon = int(cfg.get_value("loadout", "weapon", WeaponChoice.RAILGUN))
	armor = int(cfg.get_value("loadout", "armor", ArmorChoice.MEDIUM))
	helmet = int(cfg.get_value("loadout", "helmet", HelmetChoice.FACELESS))
	loadout_changed.emit()


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("loadout", "weapon", weapon)
	cfg.set_value("loadout", "armor", armor)
	cfg.set_value("loadout", "helmet", helmet)
	cfg.save(SAVE_PATH)
	loadout_changed.emit()


func set_weapon(choice: int) -> void:
	weapon = choice
	save_data()


func set_armor(choice: int) -> void:
	armor = choice
	save_data()


func set_helmet(choice: int) -> void:
	helmet = choice
	save_data()


func get_weapon_defs_id() -> WeaponDefs.Id:
	match weapon:
		WeaponChoice.SHOTGUN:
			return WeaponDefs.Id.SHOTGUN
		WeaponChoice.BAZOOKA:
			return WeaponDefs.Id.BAZOOKA
		_:
			return WeaponDefs.Id.RAILGUN


func weapon_display_name() -> String:
	match weapon:
		WeaponChoice.SHOTGUN:
			return "Shotgun"
		WeaponChoice.BAZOOKA:
			return "Bazooka"
		_:
			return "Railgun"


func armor_display_name() -> String:
	match armor:
		ArmorChoice.LIGHT:
			return "Light Armor"
		ArmorChoice.HEAVY:
			return "Heavy Armor"
		_:
			return "Medium Armor"


func helmet_display_name() -> String:
	match helmet:
		HelmetChoice.CUSTODIAN:
			return "Custodian"
		HelmetChoice.OBSERVER:
			return "Observer"
		HelmetChoice.BROKEN:
			return "Broken"
		HelmetChoice.CORRUPTED:
			return "Corrupted"
		_:
			return "Faceless"
