## Central gameplay tuning — change void death style and balance here.
class_name GameBalance
extends RefCounted

enum VoidDeathStyle { DISINTEGRATE, EXPLODE, GORE_PLACEHOLDER }

## Active void death VFX when a fighter is lost to the pit.
const VOID_DEATH_STYLE: VoidDeathStyle = VoidDeathStyle.DISINTEGRATE


static func void_death_style_name(style: VoidDeathStyle) -> String:
	match style:
		VoidDeathStyle.DISINTEGRATE:
			return "DISINTEGRATE"
		VoidDeathStyle.EXPLODE:
			return "EXPLODE"
		VoidDeathStyle.GORE_PLACEHOLDER:
			return "GORE_PLACEHOLDER"
	return "UNKNOWN"
