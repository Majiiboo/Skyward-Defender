class_name Campaign
extends RefCounted
# CAMPAIGN (2026-11-10, Rudy: "the stage map becomes the Campaign mode: story, a trail"). The trail
# of sixty stages (stage_map.gd, opened from Modes > Campaign and from the stage name on Home) with
# two things laid over it:
#   STORY: three short comms notes per planet (arriving, after its fifth stage, after its boss),
#   told by the commander. A note opens with progress and is read on the trail; save
#   "campaign".read = [ "planet/note" ].
#   STAR CHESTS: every planet holds 30 stars (three a stage). 10, 20 and 30 stars each open a
#   chest, so going back for the stars you missed pays. Save "campaign".chests = {planet: taken}.
# Elite has no stars of its own; the Elite trail only picks and plays stages.

const STAR_MARKS := [10, 20, 30]
const CHEST_CRYSTALS := [10, 20, 40]

# "at" = how many of the planet's ten stages must be cleared before the note opens
const STORY := [
	[{"at": 0, "title": "First contact", "text": "Pilot, the swarms that hit our colonies come from this planet. You are all we could get down there. Hold the base, thin them out, and find what is breeding them."},
	 {"at": 5, "title": "Something bigger", "text": "That was a young one. The scans show the same shape far below, ten times the size. The swarm is guarding its mother."},
	 {"at": 10, "title": "The Hive Mother falls", "text": "She is down, and the swarm did not scatter. It turned, all at once, toward the Scrap Belt. Bugs do not do that on their own. Follow them."}],
	[{"at": 0, "title": "The Scrap Belt", "text": "A ring of dead ships, ours and older. The bugs came here for a reason: something in the wreckage is building machines, and it builds fast."},
	 {"at": 5, "title": "Made, not born", "text": "We opened one up. No pilot, no nest: it was put together from our own wrecks. Somebody is using the junk as a factory."},
	 {"at": 10, "title": "The Queen is scrap", "text": "The Salvage Queen is in pieces. Her last signal went one way, and it was not a cry for help. It was a report. It went to the Magma World."}],
	[{"at": 0, "title": "Under the ash", "text": "The crust here is cracking. Heat haze, ash, and creatures that swim in it. Whatever took the Queen's report is under all that."},
	 {"at": 5, "title": "The signal again", "text": "Same signal as the Belt, stronger. These creatures are not sending it. They are being steered by it, like the bugs were."},
	 {"at": 10, "title": "Cooling down", "text": "The planet is quiet. The signal is not: it jumped the moment the big one fell. Next stop is the ice. Bring a coat."}],
	[{"at": 0, "title": "Crystal World", "text": "Frozen seas and spires taller than our ships. Beautiful. The spires hum on the same note as the signal, so do not get attached."},
	 {"at": 5, "title": "A relay", "text": "The crystals are not the source. They pass the signal on, planet to planet. Break enough of them and it has to shout."},
	 {"at": 10, "title": "It shouted", "text": "We heard it clearly for the first time. It is a voice, and it is counting. The count leads into the storm."}],
	[{"at": 0, "title": "Plasma Storm", "text": "A gas giant wrapped in lightning. The things living in it feed on the charge. The voice is close now, and it knows your name, pilot."},
	 {"at": 5, "title": "The count", "text": "It counts every one of them you put down. We think it is learning from each fight. Stop being predictable."},
	 {"at": 10, "title": "Through the storm", "text": "The storm is behind you. Ahead is a planet with no life on it at all, and every signal we have followed ends there."}],
	[{"at": 0, "title": "Sentinel World", "text": "A dead machine planet. It woke the bugs, built the machines, steered the rest, all to see what we would send. We sent you."},
	 {"at": 5, "title": "It answers", "text": "It spoke to us. One word: 'Continue.' It wants this fight. Give it one it does not expect."},
	 {"at": 10, "title": "Silence", "text": "The signal has stopped. Every planet behind you is quiet for the first time in years. Come home, pilot. We will keep the lights on."}],
]

static func _state(save: Dictionary) -> Dictionary:
	var s = save.get("campaign", {})
	if typeof(s) != TYPE_DICTIONARY:
		s = {}
	var chests = s.get("chests", {})
	var read = s.get("read", [])
	return {"chests": chests if typeof(chests) == TYPE_DICTIONARY else {}, "read": read if typeof(read) == TYPE_ARRAY else []}

# ------------------------------------------------------------------ stars and chests

# stars earned on planet a (0..30)
static func planet_stars(save: Dictionary, a: int) -> int:
	var st = save.get("stars", {})
	if typeof(st) != TYPE_DICTIONARY:
		return 0
	var n := 0
	for s in range(a * 10 + 1, a * 10 + 11):
		n += clampi(int(st.get(str(s), 0)), 0, 3)
	return n

static func total_stars(save: Dictionary) -> int:
	var n := 0
	for a in StageData.AREAS.size():
		n += planet_stars(save, a)
	return n

# how many of planet a's three chests were taken
static func chests_taken(save: Dictionary, a: int) -> int:
	return clampi(int(_state(save).chests.get(str(a), 0)), 0, STAR_MARKS.size())

# how many it has earned
static func chests_earned(save: Dictionary, a: int) -> int:
	var st := planet_stars(save, a)
	var n := 0
	for m in STAR_MARKS:
		if st >= int(m):
			n += 1
	return n

static func chest_ready(save: Dictionary, a: int) -> bool:
	return chests_earned(save, a) > chests_taken(save, a)

# chest k (0..2) of planet a: bigger on later planets; keys in the second and third
static func chest_reward(a: int, k: int) -> Dictionary:
	var r := {"coins": 400 * (a + 1) * (k + 1), "crystals": int(CHEST_CRYSTALS[clampi(k, 0, 2)])}
	if k == 1:
		r["key_u"] = 2
	elif k >= 2:
		r["key_e"] = 1
	return r

# the next star mark of planet a (0 when all three are taken)
static func next_mark(save: Dictionary, a: int) -> int:
	var t := chests_taken(save, a)
	return int(STAR_MARKS[t]) if t < STAR_MARKS.size() else 0

# take the next earned chest of planet a; {} when none is waiting
static func claim(save: Dictionary, a: int) -> Dictionary:
	if not chest_ready(save, a):
		return {}
	var s := _state(save)
	var k := chests_taken(save, a)
	var r := chest_reward(a, k)
	Progress.grant(save, r)
	s.chests[str(a)] = k + 1
	save["campaign"] = s
	return r

# ------------------------------------------------------------------ story

static func note_open(save: Dictionary, a: int, i: int) -> bool:
	var top := StageData.MAX_STAGE + 1 if DevTools.on else int(save.get("stage_unlocked", 1))
	return top > a * 10 + int(STORY[a][i].at)

static func note_read(save: Dictionary, a: int, i: int) -> bool:
	return _state(save).read.has("%d/%d" % [a, i])

static func mark_read(save: Dictionary, a: int, i: int) -> void:
	var s := _state(save)
	var key := "%d/%d" % [a, i]
	if not s.read.has(key):
		s.read.append(key)
	save["campaign"] = s

# the newest open note nobody has read: [planet, note], or [] when there is none
static func unread(save: Dictionary) -> Array:
	for a in range(STORY.size() - 1, -1, -1):
		for i in range(STORY[a].size() - 1, -1, -1):
			if note_open(save, a, i) and not note_read(save, a, i):
				return [a, i]
	return []

# the stage a note sits beside on the trail (the planet's 1st, 5th or 10th)
static func note_stage(a: int, i: int) -> int:
	return a * 10 + maxi(int(STORY[a][i].at), 1)

# something on the Campaign page is waiting: a chest, or a note
static func waiting(save: Dictionary) -> bool:
	for a in StageData.AREAS.size():
		if chest_ready(save, a):
			return true
	return not unread(save).is_empty()
