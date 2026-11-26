class_name Klang extends Node
# Klangkulisse (3.1, überarbeitet in 4.3): Schichten je Ort, dazu Musik, die auf die Lage reagiert.
#   Grund     ein leiser Teppich je Landschaft (Wüste, Felder, Grab, Glas, Höhle), nahtlos geschleift
#   Stunde    in manchen Stunden ein zweiter Teppich: die Sandbank des Apophis, der Fluss Nun, die Feuergruben,
#             der Morgen vor dem Tor des Ostens
#   Ereignis  einzelne Geräusche in zufälligen Abständen aus zufälliger Richtung (Schakal, Tropfen, fallender Stein …);
#             jeder Akt bringt eigene dazu (Akt 2: Flüstern, Knochen, ein ferner Gong; Akt 3 je nach Stunde)
#   Quelle    Geräusche mit Ort im Raum: Becken, Werkstatt, Schrein, Seelenkrug, Reigen der Irrlichter
# Musik: Ruhe = Erkunden (Grund und Melodie), Gegner wach in der Nähe = Spannung, mehrere im Kampf = Kampf,
# danach Stille mit einem kurzen Nachklang (Sfx.lage). Die Aufnahmen stammen von ElevenLabs; Lautstärken in Sfx.VOL.

const GRUND := {"": "amb_freiland", "ruin": "amb_felder", "tomb": "amb_grab", "glass": "amb_rosetau", "vault": "amb_hoehle"}
const STUNDE := {7: "amb_sandbank", 10: "amb_nun", 11: "amb_feuergrube", 12: "amb_morgen"}
const EREIGNIS := {
	"": ["ev_schakal", "ev_falke", "ev_fluegel", "ev_sand", "ev_kaefer", "ev_maus", "ev_esel", "ev_boe"],
	"ruin": ["ev_falke", "ev_fluegel", "ev_maus", "ev_kaefer", "ev_esel", "ev_schakal"],
	"tomb": ["ev_tropfen", "ev_stein", "ev_tor_fern", "ev_fledermaus", "ev_seufzer", "ev_sand", "ev_kaefer"],
	"glass": ["ev_glas", "ev_seufzer", "ev_sand", "ev_stein", "ev_tor_fern"],
	"vault": ["ev_tropfen", "ev_seufzer", "ev_stein", "ev_tor_fern", "ev_fledermaus"],
}
const EREIGNIS_AKT := {1: ["ev_fluestern", "ev_knochen", "ev_gong"], 2: ["ev_gong"]}
const EREIGNIS_STUNDE := {10: ["ev_platsch", "ev_fisch", "ev_platsch"], 11: ["ev_flamme", "ev_flamme", "ev_knochen"],
	12: ["ev_vogel", "ev_vogel", "ev_boe"], 7: ["ev_boe", "ev_boe"]}

var game: Node
var art := ""
var grund: AudioStreamPlayer
var stunde: AudioStreamPlayer
var ereignisse: Array = []
var naechstes := 6.0
var kampf := false
var spannung := false
var ruhe_t := 0.0
var zuletzt := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func starten(kind: String) -> void:
	art = kind if GRUND.has(kind) else ""
	var h: int = Stunden.hour_of(Spiel.fall)
	ereignisse = EREIGNIS[art].duplicate()
	ereignisse.append_array(EREIGNIS_AKT.get(Stunden.akt(Spiel.fall), []))
	ereignisse.append_array(EREIGNIS_STUNDE.get(h, []))
	ereignisse = ereignisse.filter(func(n): return game.sfx._stream(n) != null)
	grund = _teppich(GRUND[art])
	if STUNDE.has(h):
		stunde = _teppich(STUNDE[h])
	naechstes = randf_range(4.0, 9.0)
	kampf = false
	spannung = false
	_quellen()

func _teppich(name: String) -> AudioStreamPlayer:
	var s: AudioStream = game.sfx._stream(name)
	if s == null:
		return null
	if s is AudioStreamOggVorbis:
		s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = -60.0
	add_child(p)
	p.play(randf() * 10.0)
	p.set_meta("klang", name)
	create_tween().tween_property(p, "volume_db", Sfx.VOL.get(name, -20.0), 4.0)
	return p

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
		var liste: Array = ereignisse.filter(func(n): return n != zuletzt)
		if not liste.is_empty():
			var n: String = liste.pick_random()
			zuletzt = n
			var w := randf() * TAU
			var p: Vector3 = game.hero.global_position + Vector3(cos(w), 0, sin(w)) * randf_range(7.0, 18.0)
			game.sfx.play_at(n, p, 0.1)
	# Musik nach Lage. Im Hüterkampf entscheidet main.gd (Sfx.lage("hueter", Phase)).
	if game.boss_awake:
		return
	var im_kampf := 0
	var wach := 0
	var hp: Vector3 = game.hero.global_position
	for f in game.live_foes():
		if f.kind == "boss" or f.kind == "objekt":
			continue
		var d2: float = f.global_position.distance_squared_to(hp)
		if f.state == Foe.St.FIGHT and d2 < 16.0 * 16.0:
			im_kampf += 1
		elif f.state != Foe.St.SLEEP and d2 < 24.0 * 24.0:
			wach += 1
	if not kampf and im_kampf >= 2:
		kampf = true
		spannung = false
		ruhe_t = 0.0
		game.sfx.lage("kampf", 1, 1.2)
		_teppich_ducken(-8.0)
	elif kampf:
		ruhe_t = ruhe_t + delta if im_kampf == 0 else 0.0
		if ruhe_t > 6.0:
			kampf = false
			game.sfx.lage("stille", 1, 4.0)   # einmal der Nachklang, dann von selbst wieder Erkunden
			_teppich_ducken(0.0)
	elif not spannung and im_kampf + wach >= 1:
		spannung = true
		ruhe_t = 0.0
		game.sfx.lage("spannung", 1, 3.0)
	elif spannung:
		ruhe_t = ruhe_t + delta if im_kampf + wach == 0 else 0.0
		if ruhe_t > 5.0:
			spannung = false
			game.sfx.lage("erkunden", 1, 5.0)

func _teppich_ducken(db: float) -> void:
	for p in [grund, stunde]:
		if p:
			create_tween().tween_property(p, "volume_db", Sfx.VOL.get(p.get_meta("klang", ""), -20.0) + db, 2.0)
