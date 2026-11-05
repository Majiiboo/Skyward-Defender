class_name Energy
extends RefCounted
# Power tokens (Rudy, dev137): playing a stage and collecting Patrol cost tokens. They refill
# by themselves, one every REGEN_S up to MAX; rewards and refills can take you above MAX.
# Every way into a battle (Home, Modes, Stage Map, Quests, the end screen's Next / Retry)
# calls try_play() first; Patrol's Collect calls try_spend(PATROL_COST).
# Save: "energy": tokens, "energy_t": unix time the next token started counting from.

const MAX := 60
const REGEN_S := 360.0          # one token every 6 minutes (empty to full in 6 hours)
const STAGE_COST := 5
const ELITE_COST := 8
const PATROL_COST := 5
const FREE_STAGES := 5          # the tutorial stages 1-5 cost nothing in Normal mode (Rudy, dev138)
const REFILL := 30              # tokens a crystal refill gives
const REFILL_PRICE := 50        # crystals

# what a stage costs: Elite always pays; Normal stages 1-5 are free (stage 0 = unknown, full price)
static func cost(elite: bool, stage: int = 0) -> int:
	if elite:
		return ELITE_COST
	return 0 if stage >= 1 and stage <= FREE_STAGES else STAGE_COST

# Tokens now, with the refill since last time counted in (changes `save`).
static func update(save: Dictionary) -> int:
	var now := Time.get_unix_time_from_system()
	var e := int(save.get("energy", MAX))
	var t := float(save.get("energy_t", now))
	if e < MAX:
		var gained := int((now - t) / REGEN_S)
		if gained > 0:
			e = mini(MAX, e + gained)
			t += gained * REGEN_S
	if e >= MAX:
		t = now
	save["energy"] = e
	save["energy_t"] = t
	return e

# seconds until the next token (0 when full)
static func next_in(save: Dictionary) -> int:
	var e := update(save)
	if e >= MAX:
		return 0
	return int(ceil(REGEN_S - (Time.get_unix_time_from_system() - float(save.energy_t))))

static func try_spend(save: Dictionary, n: int) -> bool:
	var e := update(save)
	if e < n:
		return false
	var was_full := e >= MAX
	save["energy"] = e - n
	if was_full:
		save["energy_t"] = Time.get_unix_time_from_system()   # the refill clock starts now
	return true

# Pay for a stage from the saved file; true = go ahead. Shows the "not enough" box on
# `parent` otherwise.
static func try_play(parent: Control, elite: bool, stage: int = 0) -> bool:
	var c := cost(elite, stage)
	if DevTools.on:
		return true   # dev mode: power tokens never gate a fight
	if c <= 0:
		return true
	var s := Progress.read()
	if try_spend(s, c):
		Progress.write(s)
		return true
	show_short(parent, c)
	return false

static func refill(save: Dictionary) -> bool:
	if int(save.get("crystals", 0)) < REFILL_PRICE:
		return false
	save["crystals"] = int(save.get("crystals", 0)) - REFILL_PRICE
	save["energy"] = update(save) + REFILL
	return true

static func clock(seconds: int) -> String:
	return "%d:%02d" % [seconds / 60, seconds % 60]

# The "not enough power" box: what you have, when the next one comes, a crystal refill.
static func show_short(parent: Control, need: int) -> void:
	var s := Progress.read()
	var have := update(s)
	var layer := ColorRect.new()
	layer.color = Color(0, 0.01, 0.04, 0.78)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(layer)
	var p := UIKit.panel(14)
	var w := minf(parent.size.x - 40.0, 360.0)
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((parent.size.x - w) * 0.5, parent.size.y * 0.3)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIKit.label("NOT ENOUGH POWER", 17, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("Need %d  ·  you have %d" % [need, have], 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UIKit.label("+1 every 6 min  ·  next in %s" % clock(next_in(s)), 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var buy := UIKit.teal_button("+%d power  ·  %d crystals" % [REFILL, REFILL_PRICE], 14)
	buy.custom_minimum_size = Vector2(0, 42)
	buy.disabled = int(s.get("crystals", 0)) < REFILL_PRICE
	buy.pressed.connect(func():
		var s2 := Progress.read()
		if refill(s2):
			Progress.write(s2)
			parent.propagate_call("_on_energy_changed")
		layer.queue_free())
	v.add_child(buy)
	var ok := UIKit.ghost_button("OK", 14)
	ok.custom_minimum_size = Vector2(0, 38)
	ok.pressed.connect(layer.queue_free)
	v.add_child(ok)
	p.add_child(v)
	layer.add_child(p)
