## Placeholder void audio — prints until real assets are wired.
class_name VoidAudio
extends RefCounted


static func play_void_wind() -> void:
	print("[Void audio] Void wind — distant, sourceless")


static func play_void_drone() -> void:
	print("[Void audio] Deep void drone — low rumble")


static func play_body_rupture() -> void:
	print("[Void audio] Body rupture — wet metallic")


static func play_disintegration_burst() -> void:
	print("[Void audio] Disintegration burst — long reverb tail")


static func play_void_absorption(silent: bool) -> void:
	if silent:
		print("[Void audio] (silence — unknown destination)")
	else:
		print("[Void audio] Distant impact echo — never arrives")


static func play_metallic_resonance() -> void:
	print("[Void audio] Metallic resonance — bridge tremor")


static func maybe_play_random_abyss_ambience() -> void:
	if randf() > 0.72:
		return
	var roll: int = randi() % 3
	match roll:
		0:
			play_void_drone()
		1:
			play_void_wind()
		2:
			play_metallic_resonance()
