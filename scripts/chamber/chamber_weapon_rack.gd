extends ChamberInteractable

@export var weapon_choice: int = GladiatorLoadout.WeaponChoice.RAILGUN

@onready var _highlight: MeshInstance3D = (
	get_parent().get_node_or_null("Highlight") as MeshInstance3D
)


func _ready() -> void:
	super._ready()
	add_to_group("chamber_interactable")
	_update_prompt()
	GladiatorLoadout.loadout_changed.connect(_on_loadout_changed)
	_refresh_highlight()


func _update_prompt() -> void:
	prompt_text = "Equip %s [E]" % _weapon_name()


func _weapon_name() -> String:
	match weapon_choice:
		GladiatorLoadout.WeaponChoice.SHOTGUN:
			return "Shotgun"
		GladiatorLoadout.WeaponChoice.BAZOOKA:
			return "Bazooka"
		_:
			return "Railgun"


func _on_interact(_player: Node3D) -> bool:
	GladiatorLoadout.set_weapon(weapon_choice)
	print("Chamber: equipped %s" % _weapon_name())
	return true


func _on_loadout_changed() -> void:
	_refresh_highlight()


func _refresh_highlight() -> void:
	if _highlight:
		_highlight.visible = GladiatorLoadout.weapon == weapon_choice
