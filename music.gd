class_name Music
extends RefCounted
# MUSIC (2026-11-10): two loops built by tools/make_music.gd, "menu" (calm) and "battle"
# (driving). One player lives under the tree's root, so the music carries across screens; asking
# for the track that is already playing does nothing, a different one fades over about a second.
# PLACEHOLDER until a real soundtrack exists. Save "music_on" (Settings), default on; it sits
# well under the sound effects (BASE_DB).
#   Music.play("menu") / Music.play("battle") / Music.apply_from(save) / Music.set_on(bool)

const BASE_DB := -15.0
static var enabled := true
static var _player: AudioStreamPlayer = null
static var _track := ""

static func apply_from(save: Dictionary) -> void:
	set_on(bool(save.get("music_on", true)))

static func set_on(on: bool) -> void:
	enabled = on
	if not on and _player != null and is_instance_valid(_player):
		_player.stop()
		_track = ""

static func _ensure() -> bool:
	if _player != null and is_instance_valid(_player):
		return _player.is_inside_tree()
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree) or (loop as SceneTree).root == null:
		return false
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	(loop as SceneTree).root.add_child.call_deferred(_player)
	return false

static func play(track: String) -> void:
	if not enabled:
		return
	var ready := _ensure()
	if track == _track and ready and _player.playing:
		return
	var path := "res://music/%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	var st: AudioStreamWAV = load(path)
	if st == null:
		return
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = st.data.size() / 2 if st.format == AudioStreamWAV.FORMAT_16_BITS else int(st.get_length() * st.mix_rate)
	_track = track
	if not ready:   # the player joins the tree at the end of this frame: start it then
		_player.stream = st
		_player.volume_db = BASE_DB
		_player.ready.connect(func(): _player.play(), CONNECT_ONE_SHOT)
		return
	if _player.playing:   # fade the old one down, swap, fade up
		var tw := _player.create_tween()
		tw.tween_property(_player, "volume_db", -50.0, 0.5)
		tw.tween_callback(func():
			_player.stream = st
			_player.play())
		tw.tween_property(_player, "volume_db", BASE_DB, 0.7)
	else:
		_player.stream = st
		_player.volume_db = BASE_DB
		_player.play()
