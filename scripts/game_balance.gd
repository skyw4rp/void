## Central gameplay tuning — change void death style and balance here.
class_name GameBalance
extends RefCounted

enum VoidDeathStyle { DISINTEGRATE, EXPLODE, GORE_PLACEHOLDER, VOID_GORE }

## Active void death VFX when a fighter is lost to the pit.
const VOID_DEATH_STYLE: VoidDeathStyle = VoidDeathStyle.VOID_GORE

## Health kill — corpse tumble before score (normal deaths).
const KILL_DEATH_VIEW_SEC: float = 2.5

## Heavy kill — fast gib collapse before score.
const GIB_COLLAPSE_SPAWN_DELAY_SEC: float = 0.1
const GIB_COLLAPSE_SCORE_MIN_SEC: float = 1.8
const GIB_COLLAPSE_SCORE_MAX_SEC: float = 2.2

const GIB_HORIZONTAL_FORCE_MIN: float = 1.5
const GIB_HORIZONTAL_FORCE_MAX: float = 5.0
const GIB_UPWARD_FORCE_MIN: float = 1.0
const GIB_UPWARD_FORCE_MAX: float = 4.0
const GIB_TORQUE_FORCE: float = 3.0
const GIB_LINEAR_DAMP: float = 1.8
const GIB_ANGULAR_DAMP: float = 2.2
const GIB_LIFETIME_MIN_SEC: float = 3.0
const GIB_LIFETIME_MAX_SEC: float = 4.0
const GIB_CLUSTER_RADIUS: float = 0.45
const GIB_COUNT_MIN: int = 10
const GIB_COUNT_MAX: int = 18

## VOID_GORE cinematic timeline (seconds from fall start).
const VOID_GORE_INSTABILITY_SEC: float = 0.35
const VOID_GORE_AMBIENT_AT: float = 0.7
const VOID_GORE_CORRUPTION_AT: float = 1.5
const VOID_GORE_BREAKUP_AT: float = 2.2
const VOID_GORE_BURST_AT: float = 3.2

## Post-absorption horror — delayed audio / distant abyss flash.
const VOID_IMPACT_SOUND_DELAY_MIN: float = 3.5
const VOID_IMPACT_SOUND_DELAY_MAX: float = 6.0
const VOID_SILENT_ABSORPTION_CHANCE: float = 0.38
const VOID_DISTANT_FLASH_CHANCE: float = 0.42
const VOID_DISTANT_FLASH_DELAY_MIN: float = 4.0
const VOID_DISTANT_FLASH_DELAY_MAX: float = 7.0

const VOID_FALL_FOV_START: float = 90.0
const VOID_FALL_FOV_END: float = 102.0


static func void_death_style_name(style: VoidDeathStyle) -> String:
	match style:
		VoidDeathStyle.DISINTEGRATE:
			return "DISINTEGRATE"
		VoidDeathStyle.EXPLODE:
			return "EXPLODE"
		VoidDeathStyle.GORE_PLACEHOLDER:
			return "GORE_PLACEHOLDER"
		VoidDeathStyle.VOID_GORE:
			return "VOID_GORE"
	return "UNKNOWN"


static func uses_void_gore_cinematic() -> bool:
	return VOID_DEATH_STYLE == VoidDeathStyle.VOID_GORE


static func gib_collapse_score_sec() -> float:
	return randf_range(GIB_COLLAPSE_SCORE_MIN_SEC, GIB_COLLAPSE_SCORE_MAX_SEC)
