extends CanvasLayer

@onready var _prompt: Label = $PromptLabel
@onready var _loadout: Label = $LoadoutLabel
@onready var _title: Label = $TitleLabel


func _ready() -> void:
	add_to_group("chamber_hud")
	_refresh_loadout()
	GladiatorLoadout.loadout_changed.connect(_refresh_loadout)


func set_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""


func clear_prompt() -> void:
	_prompt.visible = false


func _refresh_loadout() -> void:
	_loadout.text = "Weapon: %s  |  %s  |  %s" % [
		GladiatorLoadout.weapon_display_name(),
		GladiatorLoadout.armor_display_name(),
		GladiatorLoadout.helmet_display_name(),
	]
