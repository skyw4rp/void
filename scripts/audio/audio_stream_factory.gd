## Procedural placeholder AudioStreams — replace with real assets under res://audio/ (see audio/README_REPLACE_ASSETS.md).
class_name AudioStreamFactory
extends RefCounted

const SAMPLE_RATE: int = 22050


static func try_load_asset(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is AudioStream:
		return res as AudioStream
	return null


static func void_drone_loop() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_drone_loop.ogg")
	if cached:
		return cached
	return _make_loop(_mix_layers([
		_layer_tone(42.0, 0.35, 1.0, 0.08),
		_layer_tone(63.0, 0.22, 1.0, 0.06),
		_layer_tone(84.0, 0.12, 1.0, 0.04),
	]), 3.5)


static func void_proximity_loop() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_proximity_loop.ogg")
	if cached:
		return cached
	return _make_loop(_noise_layer(2.8, 0.55, 180.0, 420.0), 2.2)


static func void_wind_gust() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_wind.ogg")
	if cached:
		return cached
	return _make_one_shot(_noise_layer(1.4, 0.7, 120.0, 900.0))


static func void_rumble() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_rumble.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_layer_tone(55.0, 0.5, 0.08, 0.35),
		_noise_layer(0.9, 0.35, 40.0, 160.0),
	]))


static func void_danger_pulse() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_danger_pulse.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_layer_tone(38.0, 0.65, 0.02, 0.4),
		_layer_tone(76.0, 0.2, 0.03, 0.25),
	]))


static func void_fall_rush() -> AudioStream:
	var cached := try_load_asset("res://audio/void/void_fall_rush.ogg")
	if cached:
		return cached
	return _make_one_shot(_noise_layer(1.8, 0.45, 200.0, 2400.0, true))


static func void_body_rupture() -> AudioStream:
	var cached := try_load_asset("res://audio/void/body_rupture.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_noise_layer(0.35, 0.8, 80.0, 2200.0),
		_layer_tone(120.0, 0.35, 0.01, 0.12),
	]))


static func void_disintegration_burst() -> AudioStream:
	var cached := try_load_asset("res://audio/void/disintegration_burst.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_noise_layer(0.55, 0.9, 60.0, 1800.0),
		_layer_tone(48.0, 0.55, 0.02, 0.5),
	]))


static func void_distant_impact() -> AudioStream:
	var cached := try_load_asset("res://audio/void/distant_impact.ogg")
	if cached:
		return cached
	return _make_one_shot(_layer_tone(32.0, 0.4, 0.05, 1.2))


static func void_metallic_resonance() -> AudioStream:
	var cached := try_load_asset("res://audio/void/metallic_resonance.ogg")
	if cached:
		return cached
	return _make_one_shot(_layer_tone(220.0, 0.28, 0.02, 0.9))


static func weapon_fire(weapon: WeaponDefs.Id) -> AudioStream:
	var name: String = WeaponDefs.get_weapon_name(weapon).to_lower()
	var cached := try_load_asset("res://audio/combat/%s_fire.ogg" % name)
	if cached:
		return cached
	match weapon:
		WeaponDefs.Id.RAILGUN:
			return _make_one_shot(_mix_layers([
				_layer_tone(880.0, 0.35, 0.002, 0.06),
				_noise_layer(0.12, 0.5, 400.0, 5000.0),
			]))
		WeaponDefs.Id.SHOTGUN:
			return _make_one_shot(_noise_layer(0.22, 0.85, 90.0, 2800.0))
		WeaponDefs.Id.BAZOOKA:
			return _make_one_shot(_mix_layers([
				_layer_tone(95.0, 0.55, 0.01, 0.28),
				_noise_layer(0.35, 0.5, 50.0, 400.0),
			]))
	return _make_one_shot(_noise_layer(0.15, 0.5, 200.0, 2000.0))


static func hit_confirm_shield() -> AudioStream:
	var cached := try_load_asset("res://audio/combat/hit_shield.ogg")
	if cached:
		return cached
	return _make_one_shot(_layer_tone(640.0, 0.32, 0.005, 0.08))


static func shield_break() -> AudioStream:
	var cached := try_load_asset("res://audio/combat/shield_break.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_layer_tone(920.0, 0.38, 0.001, 0.05),
		_layer_tone(460.0, 0.28, 0.002, 0.12),
		_noise_layer(0.18, 0.72, 280.0, 4200.0),
		_layer_tone(180.0, 0.22, 0.008, 0.22),
	]))


static func hit_confirm_health() -> AudioStream:
	var cached := try_load_asset("res://audio/combat/hit_health.ogg")
	if cached:
		return cached
	return _make_one_shot(_mix_layers([
		_layer_tone(180.0, 0.42, 0.01, 0.14),
		_noise_layer(0.08, 0.35, 200.0, 1200.0),
	]))


static func hit_confirm_wall() -> AudioStream:
	var cached := try_load_asset("res://audio/combat/hit_wall.ogg")
	if cached:
		return cached
	return _make_one_shot(_layer_tone(140.0, 0.38, 0.008, 0.1))


static func fighter_hurt() -> AudioStream:
	var cached := try_load_asset("res://audio/combat/fighter_hurt.ogg")
	if cached:
		return cached
	return _make_one_shot(_layer_tone(260.0, 0.36, 0.012, 0.16))


static func _make_one_shot(samples: PackedFloat32Array) -> AudioStreamWAV:
	return _pack_wav(samples, false)


static func _make_loop(samples: PackedFloat32Array, loop_sec: float) -> AudioStreamWAV:
	var stream := _pack_wav(samples, true)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(minf(float(samples.size()), loop_sec * SAMPLE_RATE))
	return stream


static func _pack_wav(samples: PackedFloat32Array, _loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var s16: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _layer_tone(
	freq: float, amp: float, attack: float, release: float, duration: float = -1.0
) -> PackedFloat32Array:
	if duration < 0.0:
		duration = attack + release + 0.02
	var count: int = maxi(1, int(duration * SAMPLE_RATE))
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in count:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = _envelope(t, attack, release, duration)
		phase += TAU * freq / SAMPLE_RATE
		out[i] = sin(phase) * amp * env
	return out


static func _noise_layer(
	duration: float,
	amp: float,
	hp: float,
	lp: float,
	rising: bool = false
) -> PackedFloat32Array:
	var count: int = maxi(1, int(duration * SAMPLE_RATE))
	var out := PackedFloat32Array()
	out.resize(count)
	var low: float = 0.0
	var high: float = 0.0
	for i in count:
		var t: float = float(i) / SAMPLE_RATE
		var n: float = randf_range(-1.0, 1.0)
		low += (n - low) * clampf(hp / SAMPLE_RATE, 0.0, 1.0)
		high = lerpf(high, low, clampf(lp / SAMPLE_RATE, 0.0, 1.0))
		var env: float = 1.0
		if rising:
			env = clampf(t / maxf(duration * 0.65, 0.01), 0.0, 1.0)
		else:
			env = _envelope(t, 0.01, duration * 0.45, duration)
		out[i] = high * amp * env
	return out


static func _mix_layers(layers: Array) -> PackedFloat32Array:
	var max_len: int = 0
	for layer in layers:
		if layer is PackedFloat32Array:
			max_len = maxi(max_len, (layer as PackedFloat32Array).size())
	var out := PackedFloat32Array()
	out.resize(max_len)
	for layer in layers:
		if layer is PackedFloat32Array:
			var src: PackedFloat32Array = layer
			for i in mini(max_len, src.size()):
				out[i] += src[i]
	return out


static func _envelope(t: float, attack: float, release: float, duration: float) -> float:
	if t < attack:
		return t / maxf(attack, 0.0001)
	var remain: float = duration - t
	if remain < release:
		return remain / maxf(release, 0.0001)
	return 1.0
