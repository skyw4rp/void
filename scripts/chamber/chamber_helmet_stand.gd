extends ChamberInteractable

@export var helmet_choice: int = GladiatorLoadout.HelmetChoice.FACELESS

@onready var _helmet_mesh: MeshInstance3D = (
	get_parent().get_node_or_null("HelmetMesh") as MeshInstance3D
)


func _ready() -> void:
	super._ready()
	add_to_group("chamber_interactable")
	_update_prompt()
	GladiatorLoadout.loadout_changed.connect(_on_loadout_changed)
	_refresh_visual()


func _update_prompt() -> void:
	prompt_text = "Equip %s helmet [E]" % _helmet_name()


func _helmet_name() -> String:
	match helmet_choice:
		GladiatorLoadout.HelmetChoice.CUSTODIAN:
			return "Custodian"
		GladiatorLoadout.HelmetChoice.OBSERVER:
			return "Observer"
		GladiatorLoadout.HelmetChoice.BROKEN:
			return "Broken"
		GladiatorLoadout.HelmetChoice.CORRUPTED:
			return "Corrupted"
		_:
			return "Faceless"


func _on_interact(_player: Node3D) -> bool:
	GladiatorLoadout.set_helmet(helmet_choice)
	print("Chamber: equipped %s helmet" % _helmet_name())
	return true


func _on_loadout_changed() -> void:
	_refresh_visual()


func _refresh_visual() -> void:
	if _helmet_mesh == null:
		return
	var mat: StandardMaterial3D = _helmet_mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	var active: bool = GladiatorLoadout.helmet == helmet_choice
	mat.emission_enabled = active
	mat.emission = _helmet_emission_color() if active else Color(0, 0, 0)
	mat.emission_energy_multiplier = 0.5 if active else 0.0


func _helmet_emission_color() -> Color:
	match helmet_choice:
		GladiatorLoadout.HelmetChoice.CUSTODIAN:
			return Color(0.55, 0.45, 0.2)
		GladiatorLoadout.HelmetChoice.OBSERVER:
			return Color(0.35, 0.65, 0.85)
		GladiatorLoadout.HelmetChoice.BROKEN:
			return Color(0.5, 0.2, 0.15)
		GladiatorLoadout.HelmetChoice.CORRUPTED:
			return Color(0.2, 0.55, 0.35)
		_:
			return Color(0.25, 0.3, 0.35)
