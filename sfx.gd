class_name Sfx
extends RefCounted
# Sound effects (dev168 fun pass; there was no sound at all). No sound pack exists yet, so
# every sound is SYNTHESIZED in code the first time it is needed: a short wave built from a
# few layers (sine / square / saw / noise, a pitch sweep, attack and decay), cached as an
# AudioStreamWAV and played from a small pool of AudioStreamPlayers under the scene root.
# Drop a real file at res://sfx/<name>.ogg or .wav and it is used instead of the synth, so
# DEFS below is also the shopping list for a sound pack.
# Save "sound_on" (pause menu, Settings): apply_from(save) at start, set_on() on a toggle.

const RATE := 22050
const POOL := 12
static var enabled := true
static var _cache := {}      # name -> AudioStream
static var _players: Array = []
static var _pool: Node = null
static var _last := {}       # name -> msec of its last play (per-sound throttle)
static var _streak := {}     # name -> [count, msec] for rising pitch on quick repeats (gems)

# layers: wave sine|square|saw|noise, f (Hz) sweeping to f2 over t seconds, a attack (s),
# vol 0-1, delay (s). "gap" = the least ms between two plays of this sound.
const DEFS := {
	"tap":      {"gap": 40, "layers": [{"wave": "sine", "f": 1400, "f2": 900, "t": 0.035, "a": 0.002, "vol": 0.35}]},
	"shot":     {"gap": 55, "layers": [{"wave": "square", "f": 920, "f2": 300, "t": 0.06, "a": 0.002, "vol": 0.16},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.03, "a": 0.0, "vol": 0.08}]},
	"turret":   {"gap": 70, "layers": [{"wave": "saw", "f": 520, "f2": 180, "t": 0.08, "a": 0.003, "vol": 0.14}]},
	"hit":      {"gap": 35, "layers": [{"wave": "square", "f": 260, "f2": 120, "t": 0.045, "a": 0.001, "vol": 0.22},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.025, "a": 0.0, "vol": 0.12}]},
	"kill":     {"gap": 30, "layers": [{"wave": "noise", "f": 0, "f2": 0, "t": 0.14, "a": 0.002, "vol": 0.35},
		{"wave": "sine", "f": 180, "f2": 60, "t": 0.16, "a": 0.002, "vol": 0.5},
		{"wave": "square", "f": 700, "f2": 1400, "t": 0.05, "a": 0.0, "vol": 0.1, "delay": 0.02}]},
	"boss_hit": {"gap": 60, "layers": [{"wave": "square", "f": 140, "f2": 70, "t": 0.1, "a": 0.002, "vol": 0.35},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.06, "a": 0.0, "vol": 0.2}]},
	"boss_kill": {"gap": 0, "layers": [{"wave": "noise", "f": 0, "f2": 0, "t": 0.6, "a": 0.01, "vol": 0.4},
		{"wave": "sine", "f": 120, "f2": 35, "t": 0.7, "a": 0.005, "vol": 0.55},
		{"wave": "saw", "f": 400, "f2": 90, "t": 0.35, "a": 0.0, "vol": 0.25, "delay": 0.05}]},
	"gem":      {"gap": 25, "layers": [{"wave": "sine", "f": 1320, "f2": 1760, "t": 0.07, "a": 0.002, "vol": 0.3}]},
	"coin":     {"gap": 25, "layers": [{"wave": "sine", "f": 1980, "f2": 2640, "t": 0.06, "a": 0.002, "vol": 0.22},
		{"wave": "sine", "f": 2640, "f2": 2640, "t": 0.08, "a": 0.0, "vol": 0.18, "delay": 0.05}]},
	"card_open": {"gap": 0, "layers": [{"wave": "sine", "f": 660, "f2": 880, "t": 0.12, "a": 0.01, "vol": 0.3},
		{"wave": "sine", "f": 990, "f2": 1320, "t": 0.18, "a": 0.01, "vol": 0.25, "delay": 0.1}]},
	"card":     {"gap": 0, "layers": [{"wave": "sine", "f": 880, "f2": 880, "t": 0.08, "a": 0.005, "vol": 0.3},
		{"wave": "sine", "f": 1320, "f2": 1320, "t": 0.14, "a": 0.005, "vol": 0.3, "delay": 0.07},
		{"wave": "sine", "f": 1760, "f2": 1760, "t": 0.24, "a": 0.005, "vol": 0.28, "delay": 0.14}]},
	"level":    {"gap": 0, "layers": [{"wave": "square", "f": 523, "f2": 523, "t": 0.1, "a": 0.005, "vol": 0.18},
		{"wave": "square", "f": 784, "f2": 784, "t": 0.18, "a": 0.005, "vol": 0.18, "delay": 0.09}]},
	"shield":   {"gap": 60, "layers": [{"wave": "sine", "f": 330, "f2": 220, "t": 0.12, "a": 0.004, "vol": 0.3},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.05, "a": 0.0, "vol": 0.1}]},
	"hull":     {"gap": 60, "layers": [{"wave": "sine", "f": 110, "f2": 50, "t": 0.22, "a": 0.003, "vol": 0.55},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.12, "a": 0.0, "vol": 0.3}]},
	"hurt":     {"gap": 0, "layers": [{"wave": "saw", "f": 420, "f2": 140, "t": 0.2, "a": 0.003, "vol": 0.35},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.1, "a": 0.0, "vol": 0.25}]},
	"wave":     {"gap": 0, "layers": [{"wave": "sine", "f": 440, "f2": 660, "t": 0.16, "a": 0.02, "vol": 0.22},
		{"wave": "sine", "f": 660, "f2": 880, "t": 0.2, "a": 0.02, "vol": 0.2, "delay": 0.12}]},
	"boss":     {"gap": 0, "layers": [{"wave": "saw", "f": 90, "f2": 60, "t": 0.9, "a": 0.05, "vol": 0.45},
		{"wave": "square", "f": 45, "f2": 45, "t": 0.9, "a": 0.1, "vol": 0.25}]},
	"win":      {"gap": 0, "layers": [{"wave": "sine", "f": 523, "f2": 523, "t": 0.14, "a": 0.005, "vol": 0.3},
		{"wave": "sine", "f": 659, "f2": 659, "t": 0.14, "a": 0.005, "vol": 0.3, "delay": 0.12},
		{"wave": "sine", "f": 784, "f2": 784, "t": 0.14, "a": 0.005, "vol": 0.3, "delay": 0.24},
		{"wave": "sine", "f": 1047, "f2": 1047, "t": 0.5, "a": 0.005, "vol": 0.35, "delay": 0.36}]},
	"lose":     {"gap": 0, "layers": [{"wave": "saw", "f": 330, "f2": 330, "t": 0.25, "a": 0.01, "vol": 0.25},
		{"wave": "saw", "f": 262, "f2": 262, "t": 0.3, "a": 0.01, "vol": 0.25, "delay": 0.22},
		{"wave": "saw", "f": 196, "f2": 150, "t": 0.6, "a": 0.01, "vol": 0.28, "delay": 0.46}]},
	"upgrade":  {"gap": 0, "layers": [{"wave": "sine", "f": 500, "f2": 1500, "t": 0.18, "a": 0.005, "vol": 0.3},
		{"wave": "sine", "f": 1500, "f2": 1500, "t": 0.2, "a": 0.0, "vol": 0.22, "delay": 0.16}]},
	"merge":    {"gap": 0, "layers": [{"wave": "noise", "f": 0, "f2": 0, "t": 0.35, "a": 0.1, "vol": 0.2},
		{"wave": "sine", "f": 300, "f2": 1200, "t": 0.4, "a": 0.05, "vol": 0.25},
		{"wave": "sine", "f": 1760, "f2": 1760, "t": 0.3, "a": 0.005, "vol": 0.3, "delay": 0.4}]},
	"buy":      {"gap": 0, "layers": [{"wave": "sine", "f": 1047, "f2": 1047, "t": 0.08, "a": 0.003, "vol": 0.3},
		{"wave": "sine", "f": 1568, "f2": 1568, "t": 0.2, "a": 0.003, "vol": 0.3, "delay": 0.08}]},
	"claim":    {"gap": 0, "layers": [{"wave": "sine", "f": 784, "f2": 784, "t": 0.08, "a": 0.003, "vol": 0.3},
		{"wave": "sine", "f": 1175, "f2": 1175, "t": 0.22, "a": 0.003, "vol": 0.3, "delay": 0.08}]},
	"spit":     {"gap": 120, "layers": [{"wave": "saw", "f": 300, "f2": 760, "t": 0.22, "a": 0.02, "vol": 0.16},
		{"wave": "noise", "f": 0, "f2": 0, "t": 0.12, "a": 0.02, "vol": 0.06, "delay": 0.1}]},
	"locked":   {"gap": 0, "layers": [{"wave": "square", "f": 200, "f2": 180, "t": 0.12, "a": 0.003, "vol": 0.2},
		{"wave": "square", "f": 200, "f2": 180, "t": 0.12, "a": 0.003, "vol": 0.2, "delay": 0.15}]},
}

static func apply_from(save: Dictionary) -> void:
	volume = clampf(float(save.get("sfx_vol", 1.0)), 0.0, 1.0)
	enabled = bool(save.get("sound_on", true))

static var volume := 1.0   # Settings > Volume (save "sfx_vol"): 0.3 quiet, 0.6 medium, 1.0 full

static func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)

static func set_on(on: bool) -> void:
	enabled = on

# Play a sound. pitch 1.0 = as built; vol_db on top of the sound's own level.
static func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not enabled or not DEFS.has(name):
		return
	var now := Time.get_ticks_msec()
	var gap := int(DEFS[name].get("gap", 0))
	if gap > 0 and now - int(_last.get(name, -100000)) < gap:
		return
	_last[name] = now
	if not _ready():
		return
	var st := _stream(name)
	if st == null:
		return
	var p := _free_player()
	if p == null:
		return
	p.stream = st
	p.pitch_scale = clampf(pitch, 0.5, 2.0)
	p.volume_db = vol_db + linear_to_db(maxf(volume, 0.01))
	p.play()

# gems and coins: each quick pickup a little higher than the last (resets after a pause)
static func play_rising(name: String, step: float = 0.04, reset_ms: int = 700, max_steps: int = 12) -> void:
	var now := Time.get_ticks_msec()
	var s: Array = _streak.get(name, [0, 0])
	var n: int = 0 if now - int(s[1]) > reset_ms else mini(int(s[0]) + 1, max_steps)
	_streak[name] = [n, now]
	play(name, 1.0 + step * n)

# ----------------------------------------------------------------- the pool

static func _ready() -> bool:
	if _pool != null and is_instance_valid(_pool):
		return _pool.is_inside_tree()
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return false
	var root: Node = (loop as SceneTree).root
	if root == null:
		return false
	_pool = Pool.new()
	_pool.name = "SfxPool"
	_players = []
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		_pool.add_child(p)
		_players.append(p)
	root.add_child.call_deferred(_pool)
	return false   # the first call only builds the pool; the next sound plays

static func _free_player() -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = null
	var oldest_pos := -1.0
	for p in _players:
		if not p.playing:
			return p
		var pos: float = p.get_playback_position()
		if pos > oldest_pos:
			oldest_pos = pos
			oldest = p
	return oldest   # all busy: steal the one furthest along

# ----------------------------------------------------------------- synthesis

static func _stream(name: String) -> AudioStream:
	# the cache lives on the pool node (freed with the scene tree); a static Dictionary of
	# streams would outlive shutdown and print "ObjectDB instances leaked"
	if _pool == null or not is_instance_valid(_pool):
		return null
	_cache = _pool.get_meta("cache", {})
	if _cache.is_empty():
		_pool.set_meta("cache", _cache)
	if _cache.has(name):
		return _cache[name]
	var st: AudioStream = null
	for ext in ["ogg", "wav"]:
		var path := "res://sfx/%s.%s" % [name, ext]
		if ResourceLoader.exists(path):
			st = load(path)
			break
	if st == null:
		st = _synth(DEFS[name].layers)
	_cache[name] = st
	return st

static func _synth(layers: Array) -> AudioStreamWAV:
	var total := 0.0
	for l in layers:
		total = maxf(total, float(l.get("delay", 0.0)) + float(l.t))
	var n := int(ceil(total * RATE)) + 1
	var mix := PackedFloat32Array()
	mix.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for l in layers:
		var start := int(float(l.get("delay", 0.0)) * RATE)
		var len := int(float(l.t) * RATE)
		var att := maxf(1.0, float(l.get("a", 0.003)) * RATE)
		var f0 := float(l.f)
		var f1 := float(l.f2)
		var vol := float(l.vol)
		var wave: String = l.wave
		var ph := 0.0
		var last := 0.0
		for i in len:
			var u := float(i) / float(len)
			var env := minf(float(i) / att, 1.0) * (1.0 - u) * (1.0 - u)   # linear attack, square decay
			var v := 0.0
			if wave == "noise":
				last = last * 0.6 + rng.randf_range(-1.0, 1.0) * 0.4   # a touch of low-pass: less hiss
				v = last
			else:
				var f := lerpf(f0, f1, u)
				ph += TAU * f / RATE
				match wave:
					"sine": v = sin(ph)
					"square": v = 1.0 if fmod(ph, TAU) < PI else -1.0
					"saw": v = 2.0 * (fmod(ph, TAU) / TAU) - 1.0
			var k := start + i
			if k < n:
				mix[k] += v * env * vol
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := int(clampf(mix[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav

# The node that holds the players. On shutdown it stops them and drops the streams, or a
# headless run reports the playbacks as leaked at exit.
class Pool extends Node:
	func _exit_tree() -> void:
		_drop()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			_drop()
	func _drop() -> void:
		for p in get_children():
			if p is AudioStreamPlayer:
				p.stop()
				p.stream = null
		set_meta("cache", {})
		Sfx._cache = {}
