extends SceneTree
# Builds the game's two music loops from scratch (no samples, no outside files) into
# res://music/menu.wav and res://music/battle.wav: 22.05 kHz, 16-bit, mono, made to loop without
# a seam (every note ends inside the loop; echoes wrap round to the start).
#   menu   - calm: soft chords, a slow bass, a gentle rising pattern with an echo (A minor, 72 bpm)
#   battle - driving: a pulsing bass, a kick and a soft tick, a quick pattern on top (D minor, 124 bpm)
# PLACEHOLDER MUSIC until a real soundtrack exists: plain waves, safe chords, quiet in the mix.
# Run: godot --headless --path . --script res://tools/make_music.gd   then --import.

const RATE := 22050

var buf: PackedFloat32Array
var n := 0

func _note(semi_from_a4: int) -> float:
	return 440.0 * pow(2.0, semi_from_a4 / 12.0)

# one tone into the buffer (wrapping past the end back to the start)
# wave: 0 sine, 1 soft triangle-ish, 2 warm (sine + two harmonics), 3 hollow (odd harmonics)
func _tone(start_s: float, dur_s: float, freq: float, amp: float, wave: int, attack: float, release: float, f_end: float = -1.0) -> void:
	var i0 := int(start_s * RATE)
	var len := int(dur_s * RATE)
	var phase := 0.0
	for i in len:
		var t := float(i) / RATE
		var f := freq if f_end < 0.0 else lerpf(freq, f_end, float(i) / len)
		phase += TAU * f / RATE
		var s := sin(phase)
		match wave:
			1: s = 0.8 * sin(phase) - 0.09 * sin(3.0 * phase) + 0.032 * sin(5.0 * phase)
			2: s = 0.7 * sin(phase) + 0.25 * sin(2.0 * phase) + 0.12 * sin(3.0 * phase)
			3: s = 0.75 * sin(phase) + 0.2 * sin(3.0 * phase) + 0.08 * sin(5.0 * phase)
		var env := minf(1.0, t / maxf(attack, 0.001)) * minf(1.0, (dur_s - t) / maxf(release, 0.001))
		buf[(i0 + i) % n] += s * amp * env

func _noise(start_s: float, dur_s: float, amp: float, rng: RandomNumberGenerator) -> void:
	var i0 := int(start_s * RATE)
	var len := int(dur_s * RATE)
	var last := 0.0
	for i in len:
		var x := rng.randf_range(-1.0, 1.0)
		var hp := x - last   # a crude high-pass: a tick, not a hiss
		last = x
		buf[(i0 + i) % n] += hp * amp * (1.0 - float(i) / len)

# a copy of the whole loop, later and quieter, wrapped round: an echo
func _echo(delay_s: float, gain: float, src: PackedFloat32Array) -> void:
	var d := int(delay_s * RATE)
	for i in n:
		buf[(i + d) % n] += src[i] * gain

func _save(path: String) -> void:
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s := int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://music"))
	st.save_to_wav(ProjectSettings.globalize_path(path))
	print("%s  %.1f s" % [path, float(n) / RATE])

func _menu() -> void:
	var beat := 60.0 / 72.0
	var bar := beat * 4.0
	n = int(bar * 16.0 * RATE)   # sixteen bars: the second eight vary the pattern so the loop is not the same 15 seconds over and over
	buf = PackedFloat32Array()
	buf.resize(n)
	# Am  F  C  G, twice; each chord as semitones from A4: root (bass), then the three pad notes
	var chords := [[-24, -12, -9, -5], [-28, -16, -12, -9], [-21, -9, -5, -2], [-26, -14, -10, -7]]
	var arp := PackedFloat32Array()
	arp.resize(n)
	for b in 16:
		var ch: Array = chords[b % 4]
		var t0 := b * bar
		for k in range(1, 4):   # the pad: three soft notes, each doubled a hair apart, swelling in and out
			_tone(t0, bar, _note(ch[k]), 0.10, 0, 0.9, 1.1)
			_tone(t0, bar, _note(ch[k]) * 1.004, 0.07, 0, 1.1, 1.1)
		_tone(t0, beat * 1.8, _note(ch[0]), 0.22, 2, 0.02, 1.2)
		_tone(t0 + beat * 2.0, beat * 1.6, _note(ch[0]), 0.14, 2, 0.02, 1.0)
	var keep := buf
	buf = arp
	for b in 16:
		var ch: Array = chords[b % 4]
		var up := [ch[1] + 12, ch[2] + 12, ch[3] + 12, ch[2] + 12, ch[3] + 12, ch[2] + 24 - 12, ch[3] + 12, ch[2] + 12]
		if b == 8 or b == 9:
			continue   # two bars of chords alone, then the pattern comes back an octave down
		var oct := -12 if b >= 10 and b < 14 else 0
		for e in 8:   # the rising pattern: eighth notes, bell-like
			if b % 4 == 3 and e >= 6:
				continue   # a breath before the loop turns over
			_tone(b * bar + e * beat * 0.5, beat * 0.9, _note(up[e] + oct), 0.085 if e % 2 == 0 else 0.06, 1, 0.006, 0.7)
	arp = buf
	buf = keep
	for i in n:
		buf[i] += arp[i]
	_echo(beat * 0.75, 0.38, arp)
	_echo(beat * 1.5, 0.16, arp)
	_save("res://music/menu.wav")

func _battle() -> void:
	var beat := 60.0 / 124.0
	var bar := beat * 4.0
	n = int(bar * 16.0 * RATE)   # sixteen bars: the second eight vary the pattern so the loop is not the same 15 seconds over and over
	buf = PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Dm Dm Bb C | Dm Dm Bb A: root for the bass, then three notes
	var chords := [[-19, -7, -4, 0], [-19, -7, -4, 0], [-23, -11, -7, -4], [-21, -9, -5, -2], [-19, -7, -4, 0], [-19, -7, -4, 0], [-23, -11, -7, -4], [-24, -12, -8, -5]]
	var lead := PackedFloat32Array()
	lead.resize(n)
	for b in 16:
		var ch: Array = chords[b % 8]
		var t0 := b * bar
		for k in range(1, 4):   # a quiet pad under everything
			_tone(t0, bar, _note(ch[k]), 0.05, 0, 0.3, 0.5)
		for e in 8:   # the pulsing bass: eighth notes on the root, the octave on the off-beats of beat 4
			var up := 12 if (e == 6 or e == 7) and b % 2 == 1 else 0
			_tone(t0 + e * beat * 0.5, beat * 0.42, _note(ch[0] + up - 12), 0.26 if e % 2 == 0 else 0.17, 2, 0.004, 0.2)
		for q in 4:   # kick on every beat, a tick between
			_tone(t0 + q * beat, 0.13, 118.0, 0.42, 0, 0.002, 0.09, 44.0)
			_noise(t0 + q * beat + beat * 0.5, 0.035, 0.07, rng)
			if b % 2 == 1 and q == 3:
				_noise(t0 + q * beat + beat * 0.75, 0.03, 0.05, rng)
	var keep := buf
	buf = lead
	for b in 16:
		var ch: Array = chords[b % 8]
		var pat := [ch[1] + 12, ch[3] + 12, ch[2] + 12, ch[3] + 12, ch[1] + 24, ch[3] + 12, ch[2] + 12, ch[3] + 12]
		if b == 8 or b == 9:
			continue   # the drums and bass alone for two bars
		if b >= 12:
			pat.reverse()   # the last four bars run the pattern backwards
		for s in 16:   # sixteenths: the quick pattern, every other note softer, rests so it breathes
			if s % 8 == 7 or (b % 4 == 3 and s >= 12):
				continue
			_tone(b * bar + s * beat * 0.25, beat * 0.3, _note(pat[s % 8]), 0.075 if s % 2 == 0 else 0.045, 3, 0.004, 0.16)
	lead = buf
	buf = keep
	for i in n:
		buf[i] += lead[i]
	_echo(beat * 0.75, 0.3, lead)
	_save("res://music/battle.wav")

func _initialize() -> void:
	_menu()
	_battle()
	quit(0)
