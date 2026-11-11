class_name Codex
extends RefCounted
# THE COLLECTION BOOK (2026-11-10; REVIEW-2026-11-10.md): everything you have met or own, on one
# page, with a small crystal reward each time a quarter of a category is filled. Four categories:
#   enemies  every bug and machine you have fought (save "seen_enemies", written by the battle)
#   heroes   the heroes you own
#   turrets  the turrets you own
#   cards    every power card you have ever picked (save "cards_seen", written by the battle)
# An entry you do not have yet shows as a dark shape with a question mark: something to find.
# Save "codex_claimed": {category: rewards taken (0-4)}.

const CATS := ["enemies", "heroes", "turrets", "cards"]
const NAMES := {"enemies": "Enemies", "heroes": "Heroes", "turrets": "Base", "cards": "Cards"}
const STEPS := [0.25, 0.5, 0.75, 1.0]      # the share of a category that pays
const CRYSTALS := [10, 15, 25, 50]

static func _tex(path: String) -> Texture2D:
	return load(path) if path != "" and ResourceLoader.exists(path) else null

static func hero_tex(id: String) -> Texture2D:
	var p := _tex("res://heroes/%s/portrait.png" % id)
	if p != null:
		return p
	var tf := _tex("res://pilot_turn/commander_3.png")   # Rook: head and shoulders from his turn frame
	if tf == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = tf
	var s := tf.get_size()
	at.region = Rect2(s.x * 0.18, 0.0, s.x * 0.64, s.y * 0.42)
	return at

static func card_tex(id: String) -> Texture2D:
	var p := _tex("res://cards/pic_%s.png" % id)
	return p if p != null else _tex(String(Cards.CARDS[id].get("pic", "")))

static func enemy_tex(id: String) -> Texture2D:
	var def: Dictionary = StageData.ENEMIES[id]
	var p := _tex(String(def.get("tex", "")))
	return p if p != null else _tex("res://enemies/%s/%s_whole.png" % [String(def.get("family", "scrap")), id])

# [{id, name, tex, have}] in a fixed order
static func entries(save: Dictionary, cat: String) -> Array:
	var out: Array = []
	match cat:
		"enemies":
			var seen: Array = save.get("seen_enemies", [])
			for id in StageData.ENEMIES:
				var def: Dictionary = StageData.ENEMIES[id]
				if String(def.get("intro", "")) == "":
					continue   # spore pods and junk bolts are part of another bug
				out.append({"id": id, "name": String(def.get("name", String(id).capitalize())), "tex": enemy_tex(id), "have": seen.has(id)})
		"heroes":
			var h := Heroes.read(save)
			for id in Heroes.ORDER:
				out.append({"id": id, "name": String(Heroes.ROSTER[id].name), "tex": hero_tex(String(id)), "have": Heroes.owned(h, String(id))})
		"turrets":
			# the buildings of the base since 2026-11-10 (the turrets are gone; the key keeps its old name for saves)
			var bb := Base.read(save)
			for id in Base.ORDER:
				out.append({"id": id, "name": String(Base.BUILDINGS[id].name), "tex": Base.pic(String(id)), "have": Base.owned(bb, String(id))})
		"cards":
			var seen: Array = save.get("cards_seen", [])
			for id in Cards.CARDS:
				out.append({"id": id, "name": String(Cards.CARDS[id].name), "tex": card_tex(id), "have": seen.has(id)})
	return out

static func count(save: Dictionary, cat: String) -> Array:   # [have, total]
	var have := 0
	var es := entries(save, cat)
	for e in es:
		if e.have:
			have += 1
	return [have, es.size()]

# how many of the four rewards this category has reached
static func reached(save: Dictionary, cat: String) -> int:
	var c := count(save, cat)
	var n := 0
	for f in STEPS:
		if int(c[0]) >= ceili(float(c[1]) * float(f)):
			n += 1
	return n

static func claimed(save: Dictionary, cat: String) -> int:
	var cl = save.get("codex_claimed", {})
	return clampi(int(cl.get(cat, 0)), 0, STEPS.size()) if typeof(cl) == TYPE_DICTIONARY else 0

static func claimable(save: Dictionary, cat: String = "") -> bool:
	if cat == "":
		for c in CATS:
			if claimable(save, c):
				return true
		return false
	return claimed(save, cat) < reached(save, cat)

# how many you need for the next reward (0 = all four taken), and what it pays
static func next_goal(save: Dictionary, cat: String) -> Dictionary:
	var k := claimed(save, cat)
	if k >= STEPS.size():
		return {"need": 0, "crystals": 0}
	return {"need": ceili(float(count(save, cat)[1]) * float(STEPS[k])), "crystals": int(CRYSTALS[k])}

# take the next reward of a category; returns the crystals paid (0 = nothing to take)
static func claim(save: Dictionary, cat: String) -> int:
	if not claimable(save, cat):
		return 0
	var k := claimed(save, cat)
	var cl = save.get("codex_claimed", {})
	if typeof(cl) != TYPE_DICTIONARY:
		cl = {}
	cl[cat] = k + 1
	save["codex_claimed"] = cl
	Progress.grant(save, {"crystals": int(CRYSTALS[k])})
	return int(CRYSTALS[k])

# the battle calls this when a card is picked: true when it is new to the book
static func note_card(save: Dictionary, id: String) -> bool:
	if not Cards.CARDS.has(id):
		return false
	var seen: Array = save.get("cards_seen", [])
	if seen.has(id):
		return false
	seen.append(id)
	save["cards_seen"] = seen
	return true
