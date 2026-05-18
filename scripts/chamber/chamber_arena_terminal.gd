extends ChamberInteractable

@onready var _screen_light: OmniLight3D = (
	get_parent().get_node_or_null("ScreenLight") as OmniLight3D
)


func _ready() -> void:
	super._ready()
	add_to_group("chamber_interactable")
	prompt_text = "START MATCH [E]"


func _on_interact(_player: Node3D) -> bool:
	if GameFlow.transitioning:
		return false
	print("Arena Terminal: starting match...")
	if _screen_light:
		_screen_light.light_energy = 2.2
	GameFlow.start_arena_match()
	return true
