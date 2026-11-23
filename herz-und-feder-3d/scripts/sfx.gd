class_name Sfx extends Node
# Ton: Geräusche von ElevenLabs (audio/*.ogg), Musik von Gomo Sounds (audio/mus_*.ogg). Lautstärken stehen hier an einer Stelle.
# Neu in 4.1: Schritte, Hiebe, Treffer und Skelette sind ElevenLabs-Aufnahmen, auf 0 ms geschnitten und nach LUFS angeglichen (tools/ton/klang_bauen.py).
# Geräusche des Helden spielen ohne Ort, Geräusche von Gegnern und Fackeln mit Ort im Raum.

const VOL := {
	"step": -13.0, "swing": -9.0, "hit": -1.0, "hurt": -0.5, "whirl": -5.0, "dash": -6.0, "oath": -6.0, "udjat": -4.0,
	"beam": -7.0, "potion": -6.0, "boss_appear": -3.0, "gate": -4.0, "ui": -10.0, "bolt": -8.0, "hero_die": -3.0,
	"victory": -5.0, "skel_wake": -6.0, "skel_die": -2.0, "skel_attack": -1.0, "torch": -14.0,
	# Geräusche von Gomo (Fassung 2.3), nach Messung eingepegelt
	"step_sand_geh": -23.0, "step_stein_geh": -24.0, "step_sand_lauf": -20.0, "step_stein_lauf": -21.0, "ausweichen": -6.0, "aufstieg": -7.0, "feuer_an": -4.0, "feuer_brennt": -13.0, "segen": -5.0,
	"herz_frei": -5.0, "krug_bricht": -3.0, "truhe": -2.0, "papyrus": -7.0, "aufheben": -6.0, "schaf": -8.0, "ziege": -8.0, "esel": -9.0,
	"katze": -9.0, "skorpion": -6.0, "irrlicht": -12.0,
	"amb_wind": -15.0, "amb_drone": -17.0,
	# Musik nach Messung: im Spiel etwa 25 dB unter Vollaussteuerung, hinter den Geräuschen
	"mus_titel": -11.0, "mus_wueste": -9.0, "mus_duat": -11.0, "mus_kampf": -6.0,
	"mus_felder": -9.0, "mus_grab": -3.0, "mus_rosetau": -14.0, "mus_hoehle": -9.0,
	"vo_chapter": -1.0, "vo_boss": -1.0, "vo_epi": -1.0, "vo_death": -1.0,
	# Klangkulisse (3.1, ElevenLabs): Grund leise, Ereignisse aus der Ferne, Quellen mit Ort
	"amb_freiland": -21.0, "amb_felder": -21.0, "amb_grab": -20.0, "amb_rosetau": -21.0, "amb_hoehle": -20.0,
	"ev_schakal": -14.0, "ev_falke": -15.0, "ev_fluegel": -14.0, "ev_sand": -15.0, "ev_kaefer": -14.0, "ev_maus": -13.0,
	"ev_esel": -16.0, "ev_tropfen": -12.0, "ev_stein": -12.0, "ev_tor_fern": -14.0, "ev_fledermaus": -13.0,
	"ev_seufzer": -15.0, "ev_glas": -14.0, "ev_fisch": -12.0,
	"src_wasser": -10.0, "src_werkstatt": -12.0, "src_schrein": -14.0, "src_reigen": -12.0, "src_herz": -10.0,
	"tor_auf": -3.0, "akt_ende": -4.0, "boss_stern": -4.0, "boss_phase": -2.0, "rueckkehr": -6.0, "thot": -6.0,
}
const VARIANTS := {"step": 3, "swing": 3, "hit": 3, "hurt": 3, "skel_die": 3, "skel_attack": 3,
	"step_sand_geh": 4, "step_stein_geh": 4, "step_sand_lauf": 4, "step_stein_lauf": 4}

var streams := {}
var pool: Array = []
var pool3: Array = []
var loops := {}
var voice: AudioStreamPlayer
var muted := false
var mus: Array = []        # zwei Spieler für die Musik: [0] spielt, [1] ist frei oder blendet aus
var mus_name := ""
var mus_list: Array = []   # Stücke der Stunde: wechseln sich alle anderthalb Minuten ab, damit sich 30 Sekunden nicht endlos wiederholen
var mus_i := 0
var mus_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	einst_anwenden()
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
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = -80.0
		add_child(m)
		mus.append(m)

func _stream(key: String) -> AudioStream:
	if not streams.has(key):
		var path := "res://audio/%s.ogg" % key
		streams[key] = load(path) if ResourceLoader.exists(path) else null
	return streams[key]

# Schritt je Untergrund und Gangart: Laufen klingt härter und kürzer als Gehen (eigene Aufnahmen, nicht dieselben schneller abgespielt)
static func schritt_name(stein: bool, lauf: bool) -> String:
	return "step_%s_%s" % ["stein" if stein else "sand", "lauf" if lauf else "geh"]

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

# Schleifen mit Ort im Raum (Fackeln, Becken, Schreine …): Im Browser entpackt jede laufende Ogg-Schleife ihren Klang
# auf dem einzigen Faden des Spiels. Darum spielen nur die nächsten, die man hören kann; die anderen ruhen (4.0.1).
const SCHLEIFEN_MAX := 6
var raum_schleifen: Array = []
var schleifen_aktiv := 0

func schleife_merken(p: AudioStreamPlayer3D) -> void:
	raum_schleifen.append(p)

func schleifen_sparen(hp: Vector3) -> void:
	raum_schleifen = raum_schleifen.filter(func(p): return is_instance_valid(p) and p.is_inside_tree())
	var nah := []
	for p in raum_schleifen:
		var d: float = (p as AudioStreamPlayer3D).global_position.distance_to(hp)
		if d < p.max_distance + 1.5 and p.playing:
			nah.append([d, p])
		elif not p.stream_paused:
			p.stream_paused = true
	nah.sort_custom(func(a, b): return a[0] < b[0])
	schleifen_aktiv = 0
	for i in nah.size():
		var an: bool = i < SCHLEIFEN_MAX
		if nah[i][1].stream_paused == an:
			nah[i][1].stream_paused = not an
		if an:
			schleifen_aktiv += 1

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
	schleife_merken(p)

func say(name: String) -> void:
	var s := _stream(name)
	if s == null or muted:
		return
	voice.stream = s
	voice.volume_db = VOL.get(name, -2.0) if not name.begins_with("vo_h") else 0.0
	voice.play()

# ---------------------------------------------------------------- Musik
# Die Musik liegt hinter allem anderen: gut 7 dB unter den Geräuschen, und sobald die Erzählstimme spricht, weicht sie
# weitere 9 dB zurück. Sie spielt auch nicht pausenlos: Nach einem Stück bleibt es eine Weile still (nur Wind und Raum),
# dann setzt das nächste ein. Im Hüterkampf läuft sie durch.
const MUS_TRIM := -7.0     # alle Stücke gemeinsam leiser
const MUS_DUCK := -9.0     # zusätzlich, solange die Stimme spricht
const MUS_PLAY := 75.0     # so lange spielt ein Stück der Stunde
const MUS_REST := 40.0     # so lange ist danach Ruhe

var mus_gain := [0.0, 0.0]       # Blende je Spieler, 0 bis 1
var mus_want := [0.0, 0.0]
var mus_rate := [0.5, 0.5]       # Blendgeschwindigkeit je Sekunde
var mus_key := ["", ""]          # Name des Stücks je Spieler (für die Lautstärke)
var mus_duck := 0.0
var mus_rest := false

func music_set(names: Array, fade := 2.0) -> void:
	mus_list = names.filter(func(n): return _stream(n) != null)
	mus_i = 0
	mus_t = 0.0
	mus_rest = false
	music(mus_list[0] if not mus_list.is_empty() else "", fade)

# Musik wechseln: das neue Stück blendet ein, das alte aus. Leerer Name: nur ausblenden. Fehlt die Datei, bleibt es still.
func music(name: String, fade := 2.0) -> void:
	if name == mus_name:
		return
	mus_name = name
	var s := _stream(name) if name != "" else null
	# Spieler 0 ist der laufende, Spieler 1 der freie; danach tauschen sie die Rollen
	mus_want[0] = 0.0
	mus_rate[0] = 1.0 / maxf(0.1, fade)
	if s == null:
		return
	mus.reverse()
	mus_gain.reverse()
	mus_want.reverse()
	mus_rate.reverse()
	mus_key.reverse()
	if s is AudioStreamOggVorbis:
		s.loop = true
	var p: AudioStreamPlayer = mus[0]
	p.stream = s
	p.volume_db = -60.0
	p.play()
	mus_gain[0] = 0.0
	mus_want[0] = 1.0
	mus_rate[0] = 1.0 / maxf(0.1, fade)
	mus_key[0] = name

func _process(delta: float) -> void:
	# Blenden und Zurückweichen vor der Stimme
	mus_duck = move_toward(mus_duck, MUS_DUCK if voice.playing else 0.0, delta * 18.0)
	for i in 2:
		var p: AudioStreamPlayer = mus[i]
		if not p.playing:
			continue
		mus_gain[i] = move_toward(mus_gain[i], mus_want[i], delta * mus_rate[i])
		if mus_gain[i] <= 0.0 and mus_want[i] <= 0.0:
			p.stop()
			continue
		p.volume_db = VOL.get(mus_key[i], -12.0) + MUS_TRIM + mus_duck + linear_to_db(maxf(0.001, mus_gain[i] * float(Spiel.einst.musik)))
	# Wechsel der Stücke einer Stunde mit Pausen dazwischen
	if mus_list.is_empty() or (mus_name != "" and not mus_list.has(mus_name)):
		return
	mus_t += delta
	if not mus_rest and mus_t > MUS_PLAY:
		mus_t = 0.0
		mus_rest = true
		music("", 6.0)
	elif mus_rest and mus_t > MUS_REST:
		mus_t = 0.0
		mus_rest = false
		mus_i = (mus_i + 1) % mus_list.size()
		music(mus_list[mus_i], 6.0)

func hush() -> void:
	voice.stop()

# Lautstärke aus den Einstellungen (Spielmenü): gesamt über den Hauptkanal, Musik zusätzlich für sich
func einst_anwenden() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(Spiel.einst.laut))))

func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
