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

## Void pit — score / death trigger (below dense gas layer).
const VOID_DEATH_Y: float = -32.0
## Fall feels dangerous; gas becomes obvious (visual only until deeper).
const VOID_FALL_WARNING_Y: float = -18.0

## Toxic gas ocean — visibility collapse by world Y (arena deck stays clear at Y >= 0).
const VOID_FOG_ARENA_CLEAR_Y: float = 1.0
const VOID_FOG_Y_LIGHT: float = -18.0
const VOID_FOG_Y_MEDIUM: float = -25.0
const VOID_FOG_Y_DENSE: float = -30.0
const VOID_FOG_Y_BLACKOUT: float = -40.0

const VOID_FOG_DENSITY_ARENA: float = 0.042
const VOID_FOG_DENSITY_LIGHT: float = 0.12
const VOID_FOG_DENSITY_MEDIUM: float = 0.32
const VOID_FOG_DENSITY_DENSE: float = 0.68
const VOID_FOG_DENSITY_BLACKOUT: float = 1.35

const VOID_FOG_DEPTH_END_ARENA: float = 120.0
const VOID_FOG_DEPTH_END_BLACKOUT: float = 2.0

const VOID_GAS_VISIBILITY_BODY_LENGTH: float = 1.8


static func void_fog_depth_t(world_y: float) -> float:
	if world_y >= VOID_FOG_ARENA_CLEAR_Y:
		return 0.0
	if world_y >= VOID_FOG_Y_LIGHT:
		return 0.0
	if world_y >= VOID_FOG_Y_MEDIUM:
		return lerpf(0.05, 0.35, inverse_lerp(VOID_FOG_Y_LIGHT, VOID_FOG_Y_MEDIUM, world_y))
	if world_y >= VOID_FOG_Y_DENSE:
		return lerpf(0.42, 0.72, inverse_lerp(VOID_FOG_Y_MEDIUM, VOID_FOG_Y_DENSE, world_y))
	if world_y >= VOID_FOG_Y_BLACKOUT:
		return lerpf(0.72, 1.0, inverse_lerp(VOID_FOG_Y_DENSE, VOID_FOG_Y_BLACKOUT, world_y))
	return 1.0


static func void_fog_density(world_y: float) -> float:
	var t: float = void_fog_depth_t(world_y)
	if t <= 0.0:
		return VOID_FOG_DENSITY_ARENA
	if t < 0.2:
		return lerpf(VOID_FOG_DENSITY_ARENA, VOID_FOG_DENSITY_LIGHT, t / 0.2)
	if t < 0.45:
		return lerpf(VOID_FOG_DENSITY_LIGHT, VOID_FOG_DENSITY_MEDIUM, inverse_lerp(0.2, 0.45, t))
	if t < 0.75:
		return lerpf(VOID_FOG_DENSITY_MEDIUM, VOID_FOG_DENSITY_DENSE, inverse_lerp(0.45, 0.75, t))
	return lerpf(VOID_FOG_DENSITY_DENSE, VOID_FOG_DENSITY_BLACKOUT, inverse_lerp(0.75, 1.0, t))


static func void_fog_color(world_y: float) -> Color:
	var t: float = void_fog_depth_t(world_y)
	var base := Color(0.06, 0.14, 0.11)
	var deep := Color(0.04, 0.1, 0.14)
	var blackout := Color(0.06, 0.04, 0.1)
	if t < 0.5:
		return base.lerp(deep, t * 2.0)
	return deep.lerp(blackout, (t - 0.5) * 2.0).lerp(Color(0.12, 0.03, 0.05, 1.0), t * 0.25)


static func void_fog_depth_end(world_y: float) -> float:
	var t: float = void_fog_depth_t(world_y)
	return lerpf(VOID_FOG_DEPTH_END_ARENA, VOID_FOG_DEPTH_END_BLACKOUT, t)


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
