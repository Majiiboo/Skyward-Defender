class_name Perf
extends RefCounted
# Performance modes (Rudy, dev159, queue 27): how hard the game drives the phone.
#   saver     30 fps cap, the engine rests between frames, lighter menu effects (fewer
#             stars and motes, still wallpaper, no button sheen), fewer battle shards
#   balanced  60 fps cap (the default)
#   full      no cap: 90 / 120 on phones with those screens (v-sync still on)
# Save: "perf": mode id. Applied at start (hub) and when changed (Settings page).
# show_fps (save "show_fps"): a small frame counter in battle and on the Settings page.

const MODES := ["saver", "balanced", "full"]
const INFO := {
	"saver":    {"name": "Battery saver", "desc": "30 fps, lighter effects, longest battery", "fps": 30},
	"balanced": {"name": "Balanced",      "desc": "60 fps, every effect on",               "fps": 60},
	"full":     {"name": "Full throttle", "desc": "No cap: 90 / 120 on fast screens",      "fps": 0},
}
static var mode := "balanced"
static var show_fps := false

static func read(save: Dictionary) -> String:
	var m := String(save.get("perf", "balanced"))
	return m if INFO.has(m) else "balanced"

static func apply_from(save: Dictionary) -> void:
	show_fps = bool(save.get("show_fps", false))
	apply(read(save))

static func apply(m: String) -> void:
	mode = m if INFO.has(m) else "balanced"
	Engine.max_fps = int(INFO[mode].fps)
	OS.low_processor_usage_mode = mode == "saver"

# lighter visuals on (battery saver)
static func lite() -> bool:
	return mode == "saver"

static func set_mode(save: Dictionary, m: String) -> void:
	save["perf"] = m
	apply(m)
