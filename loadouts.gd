class_name Loadouts
extends RefCounted
# Saved kits (Rudy, dev139): three named presets of the equipped gear, the turrets on the
# mounts and the drone's body and pod, switched in one tap on the Gear page. Upgrade
# levels are never part of a preset (they belong to the piece), only what is worn.
# Save: "loadouts": [slot or null, x3] with {name, gear {slot: id}, turrets [4], drone {body, pod}},
# "loadout_active": index of the one in use (-1 none).

const SLOTS := 3

static func default_name(i: int) -> String:
	return "Loadout %d" % (i + 1)

# the three slots: {name, set (bool), gear, turrets, drone}
static func read(save: Dictionary) -> Array:
	var out: Array = []
	var raw = save.get("loadouts", [])
	for i in SLOTS:
		var one = raw[i] if typeof(raw) == TYPE_ARRAY and i < raw.size() else null
		if typeof(one) == TYPE_DICTIONARY and one.has("gear"):
			var name := String(one.get("name", ""))
			out.append({"name": name if name != "" else default_name(i), "set": true,
				"gear": one.get("gear", {}), "turrets": one.get("turrets", []), "drone": one.get("drone", {})})
		else:
			out.append({"name": default_name(i), "set": false})
	return out

static func active(save: Dictionary) -> int:
	var a := int(save.get("loadout_active", -1))
	return a if a >= 0 and a < SLOTS and read(save)[a].set else -1

# Store what is worn right now into slot `i` (name "" keeps the old name). Makes it the active one.
static func save_slot(save: Dictionary, i: int, name: String = "") -> void:
	if i < 0 or i >= SLOTS:
		return
	var slots := read(save)
	var raw: Array = []
	for k in SLOTS:
		raw.append(_raw(slots[k]))
	var gear := GearData.read(save)
	var dr := DroneData.read(save)
	raw[i] = {"name": name if name != "" else (String(slots[i].name) if slots[i].set else default_name(i)),
		"gear": gear.equipped.duplicate(), "turrets": Turrets.read(save).loadout.duplicate(),
		"drone": {"body": dr.body, "pod": dr.pod}}
	save["loadouts"] = raw
	save["loadout_active"] = i

static func rename(save: Dictionary, i: int, name: String) -> void:
	var slots := read(save)
	if i < 0 or i >= SLOTS or not slots[i].set:
		return
	var raw: Array = []
	for k in SLOTS:
		raw.append(_raw(slots[k]))
	raw[i]["name"] = name.strip_edges().substr(0, 14) if name.strip_edges() != "" else default_name(i)
	save["loadouts"] = raw

# Wear slot `i`: gear, turrets and drone as saved (pieces you don't own stay as they are).
# Returns false when the slot is empty.
static func apply(save: Dictionary, i: int) -> bool:
	var slots := read(save)
	if i < 0 or i >= SLOTS or not slots[i].set:
		return false
	var one: Dictionary = slots[i]
	var gear := GearData.read(save)
	var eq = one.get("gear", {})
	if typeof(eq) == TYPE_DICTIONARY:
		for s in GearData.SLOTS:
			var id := String(eq.get(s, ""))
			if GearData.ITEMS.has(id) and GearData.ITEMS[id].slot == s and GearData.owned(gear, id):
				gear.equipped[s] = id
	save["gear"] = GearData.write(gear)
	save["thruster"] = GearData.SETS[GearData.ITEMS[gear.equipped["Jetpack"]].set].thruster
	var t: Dictionary = save.get("turrets", {}) if typeof(save.get("turrets", {})) == TYPE_DICTIONARY else {}
	var lo = one.get("turrets", [])
	if typeof(lo) == TYPE_ARRAY:
		t["loadout"] = lo.duplicate()
		save["turrets"] = t
	var dr: Dictionary = save.get("drone", {}) if typeof(save.get("drone", {})) == TYPE_DICTIONARY else {}
	var d = one.get("drone", {})
	if typeof(d) == TYPE_DICTIONARY:
		if DroneData.BODIES.has(String(d.get("body", ""))):
			dr["body"] = String(d.body)
		if DroneData.PODS.has(String(d.get("pod", ""))):
			dr["pod"] = String(d.pod)
		save["drone"] = dr
	save["loadout_active"] = i
	return true

static func _raw(slot: Dictionary):
	if not slot.set:
		return null
	return {"name": slot.name, "gear": slot.gear, "turrets": slot.turrets, "drone": slot.drone}
