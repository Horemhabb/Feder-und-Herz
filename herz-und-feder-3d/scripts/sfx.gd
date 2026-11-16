class_name Sfx extends Node
# Ton: Geräusche von ElevenLabs (audio/*.ogg). Lautstärken stehen hier an einer Stelle.
# Geräusche des Helden spielen ohne Ort, Geräusche von Gegnern und Fackeln mit Ort im Raum.

const VOL := {
	"step": -13.0, "swing": -9.0, "hit": -4.0, "hurt": -5.0, "whirl": -5.0, "dash": -6.0, "oath": -6.0, "udjat": -4.0,
	"beam": -7.0, "potion": -6.0, "boss_appear": -3.0, "gate": -4.0, "ui": -10.0, "bolt": -8.0, "hero_die": -3.0,
	"victory": -5.0, "skel_wake": -6.0, "skel_die": -5.0, "skel_attack": -9.0, "torch": -14.0,
	"amb_wind": -15.0, "amb_drone": -17.0, "vo_chapter": -1.0, "vo_boss": -1.0, "vo_epi": -1.0, "vo_death": -1.0,
}
const VARIANTS := {"step": 3, "swing": 3, "hit": 3, "hurt": 3}

var streams := {}
var pool: Array = []
var pool3: Array = []
var loops := {}
var voice: AudioStreamPlayer
var muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for i in 10:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 12.0
		p3.max_db = 0.0
		p3.max_distance = 45.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3)
		pool3.append(p3)
	voice = AudioStreamPlayer.new()
	add_child(voice)

func _stream(key: String) -> AudioStream:
	if not streams.has(key):
		var path := "res://audio/%s.ogg" % key
		streams[key] = load(path) if ResourceLoader.exists(path) else null
	return streams[key]

func _pick(name: String) -> String:
	return "%s%d" % [name, randi_range(1, VARIANTS[name])] if VARIANTS.has(name) else name

func play(name: String, pitch_var := 0.06, vol_add := 0.0) -> void:
	var s := _stream(_pick(name))
	if s == null or muted:
		return
	for p in pool:
		if not p.playing:
			p.stream = s
			p.volume_db = VOL.get(name, -6.0) + vol_add
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

func play_at(name: String, pos: Vector3, pitch_var := 0.08, vol_add := 0.0) -> void:
	var s := _stream(_pick(name))
	if s == null or muted:
		return
	for p in pool3:
		if not p.playing:
			p.stream = s
			p.global_position = pos
			p.volume_db = VOL.get(name, -6.0) + vol_add
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

func loop(name: String) -> void:
	var s := _stream(name)
	if s == null or loops.has(name):
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = VOL.get(name, -12.0)
	add_child(p)
	p.play()
	loops[name] = p

func loop_at(name: String, parent: Node3D) -> void:
	var s := _stream(name)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.unit_size = 5.0
	p.max_db = 0.0
	p.max_distance = 22.0
	p.volume_db = VOL.get(name, -12.0) + 4.0
	parent.add_child(p)
	p.play(randf() * 6.0)

func say(name: String) -> void:
	var s := _stream(name)
	if s == null or muted:
		return
	voice.stream = s
	voice.volume_db = VOL.get(name, -2.0)
	voice.play()

func hush() -> void:
	voice.stop()

func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
