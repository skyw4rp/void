extends ChamberInteractable

@export var armor_choice: int = GladiatorLoadout.ArmorChoice.MEDIUM

@onready var _mannequin: MeshInstance3D = (
	get_parent().get_node_or_null("Mannequin") as MeshInstance3D
)
@onready var _highlight: MeshInstance3D = (
	get_parent().get_node_or_null("Highlight") as MeshInstance3D
)


func _ready() -> void:
	super._ready()
	add_to_group("chamber_interactable")
	_update_prompt()
	GladiatorLoadout.loadout_changed.connect(_on_loadout_changed)
	_refresh_visual()


func _update_prompt() -> void:
	prompt_text = "Equip %s [E]" % _armor_name()


func _armor_name() -> String:
	match armor_choice:
		GladiatorLoadout.ArmorChoice.LIGHT:
			return "Light Armor"
		GladiatorLoadout.ArmorChoice.HEAVY:
			return "Heavy Armor"
		_:
			return "Medium Armor"


func _on_interact(_player: Node3D) -> bool:
	GladiatorLoadout.set_armor(armor_choice)
	print("Chamber: equipped %s" % _armor_name())
	return true


func _on_loadout_changed() -> void:
	_refresh_visual()


func _refresh_visual() -> void:
	if _mannequin == null:
		return
	var mat: StandardMaterial3D = _mannequin.material_override as StandardMaterial3D
	if mat == null:
		return
	var active: bool = GladiatorLoadout.armor == armor_choice
	mat.emission_enabled = active
	mat.emission = Color(0.15, 0.35, 0.42) if active else Color(0, 0, 0)
	mat.emission_energy_multiplier = 0.35 if active else 0.0
	if _highlight:
		_highlight.visible = active
