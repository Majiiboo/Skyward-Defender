extends SceneTree
# Builds the game's two music loops from scratch (no samples, no outside files) into
# res://music/menu.wav and res://music/battle.wav: 22.05 kHz, 16-bit, mono, made to loop without
# a seam (every note ends inside the loop; echoes wrap round to the start).
#   menu   - SPACE: a deep drone, wide open chords, a far beacon, single high notes with long echoes, a wavering voice (D, 60 bpm, 64 s)
#   battle - SPACE CHASE: a pumping synth bass in octaves, a fast repeating sequence, a soaring voice, risers and sweeps (D minor, 120 bpm, 32 s)
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

# ---- SPACE THEME (Rudy, dev265: "nice, but not on theme: more galactic, more of a space theme") ----
# What makes it read as space: a deep drone that never stops, wide open chords (no plain major or
# minor thirds in the pad: fifths, seconds and sevenths), slow swells, a quiet "signal" that
# repeats like a beacon, single high notes far apart with long echoes (stars), slow glides in
# pitch, and a voice-like lead that wavers (vibrato).

# a tone that wavers: vibrato grows in after `vib_in` seconds (a theremin-like voice)
func _voice(start_s: float, dur_s: float, freq: float, amp: float, vib_hz: float, vib_depth: float, attack: float, release: float, f_end: float = -1.0) -> void:
	var i0 := int(start_s * RATE)
	var len := int(dur_s * RATE)
	var phase := 0.0
	for i in len:
		var t := float(i) / RATE
		var f := freq if f_end < 0.0 else lerpf(freq, f_end, smoothstep(0.0, 1.0, float(i) / len))
		f *= 1.0 + vib_depth * minf(1.0, t / 0.8) * sin(TAU * vib_hz * t)
		phase += TAU * f / RATE
		var s := 0.8 * sin(phase) + 0.14 * sin(2.0 * phase) + 0.05 * sin(3.0 * phase)
		var env := minf(1.0, t / maxf(attack, 0.001)) * minf(1.0, (dur_s - t) / maxf(release, 0.001))
		buf[(i0 + i) % n] += s * amp * env

# a bright, buzzy tone (the first six harmonics): synth bass and sequencer
func _saw(start_s: float, dur_s: float, freq: float, amp: float, attack: float, release: float, bright: float = 1.0) -> void:
	var i0 := int(start_s * RATE)
	var len := int(dur_s * RATE)
	var phase := 0.0
	for i in len:
		var t := float(i) / RATE
		phase += TAU * freq / RATE
		var k := bright * (1.0 - 0.6 * float(i) / len)   # it closes as it rings, like a filter
		var s := sin(phase) + k * (0.5 * sin(2.0 * phase) + 0.33 * sin(3.0 * phase) + 0.25 * sin(4.0 * phase) + 0.2 * sin(5.0 * phase) + 0.16 * sin(6.0 * phase))
		var env := minf(1.0, t / maxf(attack, 0.001)) * minf(1.0, (dur_s - t) / maxf(release, 0.001))
		buf[(i0 + i) % n] += s * 0.5 * amp * env

# soft filtered noise that swells and falls: a wind between the stars, a riser before a change
func _whoosh(start_s: float, dur_s: float, amp: float, rng: RandomNumberGenerator, peak_at: float = 0.5) -> void:
	var i0 := int(start_s * RATE)
	var len := int(dur_s * RATE)
	var lp := 0.0
	for i in len:
		var u := float(i) / len
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.04 + 0.1 * u)   # the filter opens as it goes
		var env := (u / peak_at) if u < peak_at else (1.0 - u) / (1.0 - peak_at)
		buf[(i0 + i) % n] += lp * amp * env * env

# the drums and bass breathe with the beat: everything in `src` dips on each beat and comes back
func _pump(src: PackedFloat32Array, beat_s: float, depth: float) -> void:
	var per := beat_s * RATE
	for i in n:
		var u := fmod(float(i), per) / per
		src[i] *= 1.0 - depth * (1.0 - smoothstep(0.0, 0.55, u))

# a tone that fills the whole loop with no start or end: its pitch is nudged so a whole number of
# waves fits the loop, and it joins itself without a click
func _drone(freq: float, amp: float, rich: float) -> void:
	var dur := float(n) / RATE
	var f := roundf(freq * dur) / dur
	for i in n:
		var ph := TAU * f * float(i) / RATE
		var swell := 0.8 + 0.2 * sin(TAU * float(i) / n * 3.0)   # it breathes three times a loop
		buf[i] += (sin(ph) + rich * (0.3 * sin(2.0 * ph) + 0.12 * sin(3.0 * ph))) * amp * swell

func _menu() -> void:
	# D, 60 bpm, 16 bars of four slow beats: a minute-long loop
	var beat := 1.0
	var bar := beat * 4.0
	n = int(bar * 16.0 * RATE)
	buf = PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	# the drone: a low D with a fifth, two voices a hair apart so it slowly beats
	_drone(_note(-43), 0.20, 1.0)        # D2
	_drone(_note(-43) * 1.003, 0.14, 0.0)
	_drone(_note(-36), 0.08, 0.0)        # A2
	# open chords, four bars each, swelling in and out: D sus2, Bb maj7 (no third), F add9, C sus4
	# (semitones from A4)
	var chords := [[-31, -24, -22, -17, -12], [-35, -28, -23, -18, -11], [-28, -21, -19, -16, -9], [-33, -26, -21, -19, -14]]
	for c in 4:
		var t0 := fposmod(c * bar * 4.0 - 0.6, bar * 16.0)   # each chord starts swelling just before its bar (the first wraps round the end)
		for k in chords[c].size():
			var f: float = _note(int(chords[c][k]))
			var a: float = 0.085 - 0.008 * k
			_tone(t0, bar * 4.0 + 1.2, f, a, 0, 2.6, 3.0)
			_tone(t0, bar * 4.0 + 1.2, f * 1.005, a * 0.7, 0, 3.2, 3.0)
			_tone(t0, bar * 4.0 + 1.2, f * 0.996, a * 0.5, 3, 3.6, 3.2)
	# the wind: one long breath across each half of the loop
	_whoosh(bar * 2.0, bar * 5.0, 0.05, rng, 0.6)
	_whoosh(bar * 10.0, bar * 5.0, 0.05, rng, 0.6)
	# the beacon: a quiet two-note signal, the same every two bars, like something far away calling
	var sig := PackedFloat32Array()
	sig.resize(n)
	var keep := buf
	buf = sig
	for b in 16:
		if b % 2 == 1 or b == 6 or b == 14:
			continue
		var t0 := b * bar
		_tone(t0 + 0.0, 0.16, _note(5), 0.05, 1, 0.004, 0.12)      # D5
		_tone(t0 + 0.25, 0.16, _note(5), 0.035, 1, 0.004, 0.12)
		_tone(t0 + 0.5, 0.22, _note(12), 0.045, 1, 0.004, 0.16)    # A5
	# the stars: single high notes from a five-note scale, far apart, each with a long tail
	var scale := [5, 7, 12, 14, 17, 19, 24]   # D E A B D E A (no thirds: open, weightless)
	var t := 1.5
	while t < bar * 16.0 - 2.0:
		var note: int = scale[rng.randi() % scale.size()] + (12 if rng.randf() < 0.3 else 0)
		_tone(t, 2.4, _note(note), 0.06 + 0.03 * rng.randf(), 0, 0.01, 2.2)
		_tone(t, 1.2, _note(note + 12), 0.015, 0, 0.01, 1.0)   # a glint an octave up
		t += 2.0 + rng.randf() * 3.5
	sig = buf
	buf = keep
	for i in n:
		buf[i] += sig[i]
	_echo(0.75, 0.5, sig)
	_echo(1.5, 0.32, sig)
	_echo(2.25, 0.2, sig)
	_echo(3.0, 0.1, sig)
	# the voice: one slow line that glides between notes and wavers, twice in the loop
	var line := [[4.0, 6.0, 5, 12], [10.5, 5.0, 12, 10], [16.0, 7.0, 10, 5], [36.0, 6.0, 5, 14], [42.5, 5.0, 14, 12], [48.0, 8.0, 12, 5]]
	for l in line:
		_voice(float(l[0]), float(l[1]), _note(int(l[2])), 0.05, 4.6, 0.006, 1.6, 2.2, _note(int(l[3])))
	# two slow glides far below, rising an octave: a ship passing
	_voice(bar * 7.0, bar * 2.0, _note(-31), 0.05, 0.0, 0.0, 3.0, 3.0, _note(-19))
	_voice(bar * 15.0, bar * 1.0, _note(-24), 0.04, 0.0, 0.0, 1.6, 1.8, _note(-31))
	_save("res://music/menu.wav")

func _battle() -> void:
	# D minor, 120 bpm, 16 bars: a space chase. A pumping synth bass in octaves, a fast repeating
	# sequence on top, a slow soaring voice over it, risers and falling "laser" sweeps at the turns.
	var beat := 0.5
	var bar := beat * 4.0
	n = int(bar * 16.0 * RATE)
	buf = PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Dm  Bb  F  C | Dm  Bb  Gm  A: [bass root, then the sequence's notes]
	var chords := [[-31, -7, 0, 5, 8], [-35, -11, -4, 1, 5], [-28, -4, 3, 8, 12], [-33, -9, -2, 3, 7],
		[-31, -7, 0, 5, 8], [-35, -11, -4, 1, 5], [-26, -2, 5, 10, 13], [-36, -12, -5, -1, 4]]
	var low := PackedFloat32Array()
	low.resize(n)
	var keep := buf
	buf = low
	for b in 16:
		var ch: Array = chords[b % 8]
		var t0 := b * bar
		# the pad: root, fifth and octave, wide and quiet
		for semi in [ch[0] + 12, ch[0] + 19, ch[0] + 24]:
			_tone(t0, bar, _note(semi), 0.06, 0, 0.25, 0.4)
			_tone(t0, bar, _note(semi) * 1.006, 0.04, 3, 0.3, 0.4)
		# the bass: eighth notes jumping between the root and its octave
		for e in 8:
			var oct: int = 12 if e % 2 == 1 else 0
			if b % 4 == 3 and e >= 6:
				oct = 12 + (7 if e == 7 else 0)   # a little run up into the next bar
			_saw(t0 + e * beat * 0.5, beat * 0.46, _note(ch[0] + oct), 0.3 if e % 2 == 0 else 0.2, 0.004, 0.14, 0.9)
	low = buf
	_pump(low, beat, 0.55)
	buf = keep
	for i in n:
		buf[i] += low[i]
	# drums: a round kick on every beat, a tick between, a clap of noise on beats 2 and 4
	for b in 16:
		var t0 := b * bar
		if b == 8:
			continue   # one bar with no drums: the floor drops out before it all comes back
		for q in 4:
			_tone(t0 + q * beat, 0.16, 130.0, 0.5, 0, 0.002, 0.11, 40.0)
			_noise(t0 + q * beat + beat * 0.5, 0.03, 0.06, rng)
			if q % 2 == 1:
				_noise(t0 + q * beat, 0.09, 0.09, rng)
	# the sequence: sixteenth notes running up the chord, the pattern that says "synth and stars"
	var seq := PackedFloat32Array()
	seq.resize(n)
	keep = buf
	buf = seq
	for b in 16:
		var ch: Array = chords[b % 8]
		var order := [1, 2, 3, 2, 4, 2, 3, 2, 1, 2, 3, 4, 3, 2, 3, 2]
		var soft: bool = b < 2 or b == 8
		for s in 16:
			if b % 4 == 3 and s >= 14:
				continue
			_saw(b * bar + s * beat * 0.25, beat * 0.22, _note(ch[order[s]] + (12 if b >= 12 else 0)), (0.05 if soft else 0.085) * (1.0 if s % 4 == 0 else 0.7), 0.003, 0.1, 0.5 if soft else 0.8)
	seq = buf
	buf = keep
	for i in n:
		buf[i] += seq[i]
	_echo(beat * 0.75, 0.32, seq)
	_echo(beat * 1.5, 0.14, seq)
	# the voice: long notes high above, wavering: the tune you would hum
	var tune := [[2, 2.0, 17, -1], [3, 1.0, 15, 13], [4, 2.0, 12, -1], [6, 2.0, 13, 17], [10, 2.0, 20, -1], [11, 1.0, 17, 15], [12, 2.0, 17, -1], [14, 1.0, 22, -1], [15, 1.0, 20, 16]]
	for tn in tune:
		_voice(float(tn[0]) * bar, float(tn[1]) * bar, _note(int(tn[2])), 0.075, 5.2, 0.007, 0.12, 0.5, _note(int(tn[3])) if int(tn[3]) >= 0 else -1.0)
	# risers into the turns, and a falling sweep on the turn itself
	_whoosh(bar * 7.0, bar, 0.1, rng, 0.95)
	_whoosh(bar * 15.0, bar, 0.1, rng, 0.95)
	_voice(bar * 8.0, 0.9, 2400.0, 0.05, 0.0, 0.0, 0.004, 0.6, 180.0)
	_voice(0.0, 0.9, 2400.0, 0.05, 0.0, 0.0, 0.004, 0.6, 180.0)
	_save("res://music/battle.wav")

func _initialize() -> void:
	_menu()
	_battle()
	quit(0)
