class_name Klang extends Node
# Klangkulisse (3.1): drei Schichten je Ort, dazu Musik, die auf die Lage reagiert.
#   Grund     ein leiser Teppich je Landschaft (Wüste, Felder, Grab, Glas, Höhle), nahtlos geschleift
#   Ereignis  einzelne Geräusche in zufälligen Abständen aus zufälliger Richtung (Schakal, Tropfen, fallender Stein …)
#   Quelle    Geräusche mit Ort im Raum: Becken, Werkstatt, Schrein, Seelenkrug, Reigen der Irrlichter
# Die Aufnahmen stammen von ElevenLabs (Sound Effects v2); Lautstärken stehen in Sfx.VOL.

const GRUND := {"": "amb_freiland", "ruin": "amb_felder", "tomb": "amb_grab", "glass": "amb_rosetau", "vault": "amb_hoehle"}
const EREIGNIS := {
	"": ["ev_schakal", "ev_falke", "ev_fluegel", "ev_sand", "ev_kaefer", "ev_maus", "ev_esel"],
	"ruin": ["ev_falke", "ev_fluegel", "ev_maus", "ev_kaefer", "ev_esel", "ev_schakal"],
	"tomb": ["ev_tropfen", "ev_stein", "ev_tor_fern", "ev_fledermaus", "ev_seufzer", "ev_sand", "ev_kaefer"],
	"glass": ["ev_glas", "ev_seufzer", "ev_sand", "ev_stein", "ev_tor_fern"],
	"vault": ["ev_tropfen", "ev_seufzer", "ev_stein", "ev_tor_fern", "ev_fledermaus"],
}

var game: Node
var art := ""
var grund: AudioStreamPlayer
var naechstes := 6.0
var kampf := false
var ruhe_t := 0.0
var zuletzt := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func starten(kind: String) -> void:
	art = kind if GRUND.has(kind) else ""
	var s: AudioStream = game.sfx._stream(GRUND[art])
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	grund = AudioStreamPlayer.new()
	grund.stream = s
	grund.volume_db = -60.0
	add_child(grund)
	grund.play(randf() * 10.0)
	create_tween().tween_property(grund, "volume_db", Sfx.VOL.get(GRUND[art], -20.0), 4.0)
	naechstes = randf_range(4.0, 9.0)
	_quellen()

# Quellen der Stunde: Wasserbecken, Schreine, Seelenkrüge, die Werkstatt und die Mitte jedes Reigens
func _quellen() -> void:
	for p in game.karte.pools:
		quelle_bei("src_wasser", Welt.cell_pos(p.p), 12.0)
	for st in game.orte.sites:
		match st.kind:
			"schrein":
				quelle("src_schrein", st.vis.n, 10.0, 1.2)
			"krug":
				if not st.done:
					st["herz_klang"] = quelle("src_herz", st.vis.n, 8.0, 1.0)
			"werkstatt":
				quelle("src_werkstatt", st.vis.n, 13.0, 1.0)
	var mitten := {}
	for f in game.foes:
		if f.style == "reigen" and not mitten.has(f.reigen_c):
			mitten[f.reigen_c] = true
			quelle_bei("src_reigen", f.reigen_c + Vector3(0, 1.5, 0), 16.0)

# Geräusch mit Ort, dauerhaft (Becken, Werkstatt …). Gibt den Spieler zurück, damit man ihn abschalten kann.
func quelle(name: String, an: Node3D, weite := 14.0, hoehe := 1.0) -> AudioStreamPlayer3D:
	var s: AudioStream = game.sfx._stream(name)
	if s == null or an == null:
		return null
	if s is AudioStreamOggVorbis:
		s.loop = true
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.unit_size = 3.0
	p.max_distance = weite
	p.max_db = -2.0
	p.volume_db = Sfx.VOL.get(name, -12.0)
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	an.add_child(p)
	p.position = Vector3(0, hoehe, 0)
	p.play(randf() * 4.0)
	game.sfx.schleife_merken(p)
	return p

func quelle_bei(name: String, pos: Vector3, weite := 14.0) -> AudioStreamPlayer3D:
	var n := Node3D.new()
	game.add_child(n)
	n.global_position = pos
	return quelle(name, n, weite, 0.5)

func _process(delta: float) -> void:
	var _u := Time.get_ticks_usec()
	_process_innen(delta)
	Protokoll.zeit("klang", _u)

func _process_innen(delta: float) -> void:
	if game == null or game.hero == null or not game.started:
		return
	# einzelne Geräusche: alle sechs bis fünfzehn Sekunden eines, nie zweimal dasselbe hintereinander
	naechstes -= delta
	if naechstes <= 0.0:
		naechstes = randf_range(6.0, 15.0)
		var liste: Array = EREIGNIS[art].filter(func(n): return n != zuletzt)
		if not liste.is_empty():
			var n: String = liste.pick_random()
			zuletzt = n
			var w := randf() * TAU
			var p: Vector3 = game.hero.global_position + Vector3(cos(w), 0, sin(w)) * randf_range(7.0, 18.0)
			game.sfx.play_at(n, p, 0.1)
	# Musik nach Lage: drei wache Gegner in der Nähe sind ein Kampf, sechs Sekunden Ruhe beenden ihn
	if game.boss_awake:
		return
	var nah := 0
	for f in game.live_foes():
		if f.state == Foe.St.FIGHT and f.kind != "boss" and f.global_position.distance_squared_to(game.hero.global_position) < 16.0 * 16.0:
			nah += 1
	if not kampf and nah >= 3:
		kampf = true
		ruhe_t = 0.0
		game.sfx.music("mus_kampf", 1.5)
		_grund_ducken(-8.0)
	elif kampf:
		ruhe_t = ruhe_t + delta if nah == 0 else 0.0
		if ruhe_t > 6.0:
			kampf = false
			game.sfx.music_set(game.area_music(), 4.0)
			_grund_ducken(0.0)

func _grund_ducken(db: float) -> void:
	if grund:
		create_tween().tween_property(grund, "volume_db", Sfx.VOL.get(GRUND[art], -20.0) + db, 2.0)
