class_name Sfx extends Node
# Ton (4.3, von Grund auf überarbeitet). Geräusche von ElevenLabs (audio/*.ogg), Musik aus eigenen Instrumenttönen
# komponiert (tools/ton/musik.py). Lautstärken stehen hier an einer Stelle.
# Geräusche des Helden spielen ohne Ort, Geräusche von Gegnern, Fackeln und Welt mit Ort im Raum.
#
# Musik in Schichten (vertikales Mischen): Jeder Akt hat ein eigenes Thema aus vier gleich langen Schleifen, die
# übereinander laufen: grund (Bordun, immer), melodie (beim Erkunden), spannung (Gegner wach), kampf (Trommeln).
# lage() sagt, welche Schichten hörbar sind; sie blenden ein und aus, ohne dass der Takt springt. Der Hüter hat ein
# eigenes Stück, das mit jeder Phase eine Schicht dazunimmt. Nach dem Kampf spielt einmal ein kurzer Nachklang.

const VOL := {
	# Held (4.3: je Klasse eigene Hiebe und Treffer; die alten Namen bleiben als Ersatz)
	"swing": -9.0, "hit": -6.0, "hurt": -8.0, "whirl": -5.0, "dash": -6.0, "oath": -6.0, "udjat": -4.0,
	"beam": -7.0, "potion": -6.0, "bolt": -8.0, "hero_die": -3.0, "ausweichen": -6.0,
	"hieb": -8.0, "klinge": -5.0, "faust": -9.0, "faustschlag": -5.0, "armbrust": -8.0, "bolzen": -6.0,
	"sternfunke": -8.0, "sterntreffer": -6.0, "meteor": -4.0, "windstoss": -6.0,
	"schmerz_m": -7.0, "schmerz_w": -7.0, "tod_w": -4.0,
	# Schritte (2.3/4.2, vom Auftraggeber für gut befunden): unverändert
	"step_sand": -22.0, "step_stein": -26.0, "step_erde": -23.0, "step_glas": -25.0,
	# Welt
	"aufstieg": -7.0, "feuer_an": -4.0, "feuer_brennt": -13.0, "segen": -5.0, "herz_frei": -5.0, "krug_bricht": -3.0,
	"truhe": -2.0, "papyrus": -7.0, "aufheben": -6.0, "schaf": -10.0, "ziege": -10.0, "esel": -11.0, "katze": -11.0,
	"skorpion": -6.0, "irrlicht": -12.0, "torch": -14.0, "gate": -5.0, "victory": -6.0,
	"koerper_fall": -8.0, "scherben": -5.0,
	# Gegner
	"skel_wake": -6.0, "skel_die": -3.0, "skel_attack": -9.0,
	"krieger_wach": -8.0, "krieger_tod": -7.0, "priesterin_wach": -8.0, "priesterin_tod": -7.0,
	"koloss_wach": -5.0, "koloss_tod": -5.0, "erloschen_wach": -8.0, "erloschen_tod": -7.0, "hohl_wach": -7.0, "hohl_tod": -7.0,
	# Champions (affixe.gd)
	"aff_auftritt": -6.0, "aff_glut": -10.0, "aff_sturm": -12.0, "aff_feder": -8.0, "aff_feder_bruch": -4.0, "aff_ruf": -6.0,
	"aff_sprung": -6.0, "aff_klage": -7.0, "aff_fessel": -5.0, "aff_spalt": -5.0, "aff_kette": -9.0,
	# Hüter
	"boss_appear": -4.0, "boss_stern": -4.0, "boss_phase": -2.0, "hueter_ansage": -5.0, "hueter_schlag": -3.0,
	"tor_auf": -3.0, "akt_ende": -4.0, "rueckkehr": -6.0, "thot": -6.0,
	# Oberfläche
	"ui": -12.0, "knopf": -14.0, "fenster_auf": -12.0, "fenster_zu": -13.0, "belohnung": -8.0, "stufe": -6.0,
	"anlegen": -9.0, "legendary": -5.0, "pickup": -9.0, "knopf_gold": -16.0, "herzschlag": -10.0,
	# Klangkulisse: Grund leise, Ereignisse aus der Ferne, Quellen mit Ort
	"amb_wind": -24.0, "amb_drone": -40.0,
	"amb_freiland": -21.0, "amb_felder": -21.0, "amb_grab": -22.0, "amb_rosetau": -22.0, "amb_hoehle": -21.0,
	"amb_nun": -20.0, "amb_feuergrube": -20.0, "amb_morgen": -21.0, "amb_tief": -22.0,
	"ev_schakal": -14.0, "ev_falke": -15.0, "ev_fluegel": -14.0, "ev_sand": -15.0, "ev_kaefer": -14.0, "ev_maus": -13.0,
	"ev_esel": -16.0, "ev_tropfen": -13.0, "ev_stein": -12.0, "ev_tor_fern": -14.0, "ev_fledermaus": -13.0,
	"ev_seufzer": -15.0, "ev_glas": -14.0, "ev_fisch": -13.0, "ev_flamme": -13.0, "ev_platsch": -13.0, "ev_boe": -15.0,
	"ev_vogel": -16.0, "ev_knochen": -13.0, "ev_gong": -16.0, "ev_fluestern": -17.0,
	"src_wasser": -10.0, "src_werkstatt": -12.0, "src_schrein": -14.0, "src_reigen": -12.0, "src_herz": -10.0,
	# Stimmen (stimme.py gleicht sie auf −17 LUFS an)
	"vo_chapter": -1.0, "vo_boss": -1.0, "vo_epi": -1.0, "vo_death": -1.0,
	# Musik: Pegel je Stück (tools/ton/musik.py: Grund und Melodie zusammen bei −19 LUFS)
	"mus_titel": -9.0, "mus_a1": -10.0, "mus_a2": -10.0, "mus_a3": -10.0, "mus_hueter": -8.0, "nachklang": -9.0,
}
# Mehrere Aufnahmen je Klang: Name1 … NameN, eine davon zufällig
const VARIANTS := {
	"hit": 3, "step_sand": 4, "step_stein": 4, "step_erde": 4, "step_glas": 4,
	"hieb": 3, "klinge": 3, "faust": 3, "faustschlag": 3, "armbrust": 2, "bolzen": 3, "sternfunke": 3, "sterntreffer": 3,
	"schmerz_m": 3, "schmerz_w": 3, "koerper_fall": 3, "scherben": 2, "windstoss": 2,
	"krieger_wach": 2, "krieger_tod": 2, "priesterin_wach": 2, "priesterin_tod": 2, "koloss_wach": 2, "koloss_tod": 2,
	"erloschen_wach": 2, "erloschen_tod": 2, "hohl_wach": 2, "hohl_tod": 2, "knopf_gold": 2,
}
# Jede Klasse klingt anders: Der Held ruft die alten Namen, hier wird daraus der Klang seiner Waffe (fehlt die Datei,
# bleibt der alte). Eidträger: Zweihänder; Priester des Schu: Fäuste und Wind; Wüstenjägerin: Armbrust;
# Sternleserin: Heka aus Sternenlicht.
const KLASSE := {
	"ermittler": {"swing": "hieb", "hit": "klinge", "hurt": "schmerz_m"},
	"moench": {"swing": "faust", "hit": "faustschlag", "whirl": "windstoss", "beam": "windstoss", "hurt": "schmerz_m"},
	"jaegerin": {"swing": "armbrust", "bolt": "armbrust", "hit": "bolzen", "hurt": "schmerz_w", "hero_die": "tod_w"},
	"forensiker": {"bolt": "sternfunke", "hit": "sterntreffer", "hurt": "schmerz_w", "hero_die": "tod_w"},
}
# Gegnerlaute je Art (foe.gd › kind): Erwachen und Tod. Fehlt eine Art, klingen die Knochen der Ruhelosen.
const GEGNER := {"lance": "krieger", "seer": "priesterin", "haut": "koloss", "fahl": "erloschen", "hohl": "hohl"}

const POOL := 12
const GLEICH_MAX := 3        # höchstens so viele gleiche Klänge zugleich (sonst wird es Brei)
const ABSTAND_MS := 40       # derselbe Klang nicht öfter als alle 40 ms (sonst verstärken sich Kopien zu einem Knall)

var streams := {}
var pool: Array = []
var pool3: Array = []
var loops := {}
var voice: AudioStreamPlayer
var muted := false
var zuletzt := {}
# eigener Zufall für Tonhöhe, Variante und Kulisse: Klänge verändern so nie den Zufall des Spiels (Tests mit festem Seed)
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	einst_anwenden()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for i in POOL:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 12.0
		p3.max_db = 0.0
		p3.max_distance = 45.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.attenuation_filter_cutoff_hz = 6000.0   # was weit weg ist, klingt dumpfer
		p3.attenuation_filter_db = -18.0
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
	return "%s%d" % [name, rng.randi_range(1, VARIANTS[name])] if VARIANTS.has(name) else name

# Klang der Klasse des Helden (siehe KLASSE)
func _klasse(name: String) -> String:
	var m: Dictionary = KLASSE.get(Spiel.cls, {})
	var n: String = m.get(name, name)
	return n if n == name or _stream(_pick(n)) != null else name

# Name des Treffers, den der Held gerade austeilt (main.gd › _impact, Geschosse)
func treffer(pos: Vector3, pitch_var := 0.1, vol_add := 0.0) -> void:
	play_at(_klasse("hit"), pos, pitch_var, vol_add)

# Gegnerlaut: art ist „wach“ oder „tod“; fehlt die Art, die Laute der Ruhelosen
func gegner(kind: String, art: String) -> String:
	var g: String = GEGNER.get(kind, "")
	if g != "" and _stream(_pick(g + "_" + art)) != null:
		return g + "_" + art
	return "skel_wake" if art == "wach" else "skel_die"

func _darf(name: String) -> bool:
	var t := Time.get_ticks_msec()
	if t - int(zuletzt.get(name, -100000)) < ABSTAND_MS:
		return false
	zuletzt[name] = t
	return true

# freier Spieler, sonst der älteste; null, wenn schon zu viele denselben Klang spielen
func _spieler(liste: Array, name: String) -> Node:
	var gleich := 0
	var frei: Node = null
	var alt: Node = null
	var alt_pos := -1.0
	for p in liste:
		if not p.playing:
			if frei == null:
				frei = p
			continue
		if p.get_meta("klang", "") == name:
			gleich += 1
		var pos: float = p.get_playback_position()
		if pos > alt_pos:
			alt_pos = pos
			alt = p
	if gleich >= GLEICH_MAX:
		return null
	return frei if frei != null else alt

# Für Oberflächen-Bausteine ohne Verweis auf das Spiel (zier.gd, kugel.gd): findet den Ton der laufenden Szene
static func spiele(von: Node, name: String, vol_add := 0.0) -> void:
	if von == null or not von.is_inside_tree():
		return
	var s = von.get_tree().current_scene.get("sfx") if von.get_tree().current_scene else null
	if s is Sfx:
		s.play(name, 0.04, vol_add)

func play(name: String, pitch_var := 0.06, vol_add := 0.0) -> void:
	name = _klasse(name)
	# Goldknopf statt des allgemeinen Klicks: wer zuerst kommt, der andere schweigt
	if name == "ui" and Time.get_ticks_msec() - int(zuletzt.get("knopf_gold", -100000)) < 150:
		return
	if name == "knopf_gold":
		for p in pool:
			if p.playing and p.get_meta("klang", "") == "ui" and p.get_playback_position() < 0.15:
				p.stop()
	var s := _stream(_pick(name))
	if s == null or muted or not _darf(name):
		return
	var p: AudioStreamPlayer = _spieler(pool, name)
	if p == null:
		return
	p.stream = s
	p.set_meta("klang", name)
	p.volume_db = VOL.get(name, -6.0) + vol_add
	p.pitch_scale = 1.0 + rng.randf_range(-pitch_var, pitch_var)
	p.play()

# verzoegert: Sekunden bis zum Klang (z. B. ein fallender Körper, der erst später aufschlägt)
func play_at(name: String, pos: Vector3, pitch_var := 0.08, vol_add := 0.0, verzoegert := 0.0) -> void:
	if verzoegert > 0.0:
		get_tree().create_timer(verzoegert).timeout.connect(func(): play_at(name, pos, pitch_var, vol_add))
		return
	var s := _stream(_pick(name))
	if s == null or muted or not _darf(name + str(Vector3i(pos))):
		return
	var p: AudioStreamPlayer3D = _spieler(pool3, name)
	if p == null:
		return
	p.stream = s
	p.set_meta("klang", name)
	p.global_position = pos
	p.volume_db = VOL.get(name, -6.0) + vol_add
	p.pitch_scale = 1.0 + rng.randf_range(-pitch_var, pitch_var)
	p.play()

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
	if p.is_inside_tree():
		p.play(rng.randf() * 6.0)
	else:
		p.autoplay = true   # Träger noch nicht in der Welt (Champion beim Entstehen): spielt, sobald er dort ist
	schleife_merken(p)

func say(name: String) -> void:
	var s := _stream(name)
	if s == null or muted:
		return
	voice.stream = s
	voice.volume_db = VOL.get(name, -2.0) if not name.begins_with("vo_h") else 0.0
	voice.play()

func hush() -> void:
	voice.stop()

# ---------------------------------------------------------------- Musik
const MUS_TRIM := -7.0      # alle Stücke gemeinsam (die Musik liegt hinter den Geräuschen)
const MUS_DUCK := -8.0      # zusätzlich, solange die Erzählstimme spricht
const MELODIE_PAUSE := 3    # jede dritte Runde schweigt die Melodie (Bordun und Raum bleiben): sie nutzt sich nicht ab
const STILLE_DAUER := 18.0  # so lange nach einem Kampf nur Grund und Nachklang
# Welche Schichten in welcher Lage hörbar sind (0 bis 1)
const LAGEN := {
	"erkunden": {"grund": 1.0, "melodie": 1.0},
	"spannung": {"grund": 1.0, "spannung": 1.0},
	"kampf": {"grund": 0.8, "spannung": 0.6, "kampf": 1.0},
	"stille": {"grund": 1.0},
	"titel": {"voll": 1.0},
}
# Namen der Musik bis 4.2 (Zwischensequenzen rufen sie noch): das passende neue Stück
const ALTE_NAMEN := {"mus_duat": "mus_a2", "mus_hoehle": "mus_a2", "mus_grab": "mus_a2", "mus_wueste": "mus_a1",
	"mus_felder": "mus_a1", "mus_rosetau": "mus_a1"}
const SATZ_SCHICHTEN :={"mus_hueter": ["grund", "p1", "p2", "p3"], "mus_titel": ["voll"]}

var satz := ""              # laufendes Stück: mus_a1 … mus_a3, mus_hueter, mus_titel
var lage_name := ""
var phase := 0
var schichten := {}         # Schicht → {"p": Spieler, "g": Blende 0–1, "w": Ziel, "r": Blendtempo}
var ausklang: Array = []    # Spieler eines vorigen Stücks, die gerade ausblenden
var nachklang: AudioStreamPlayer
var mus_duck := 0.0
var zyklus := 0
var grund_pos := 0.0
var stille_t := 0.0
# ältere Namen (playtest, klang.gd)
var mus_name := ""
var mus_list: Array = []

func _datei(schicht: String) -> String:
	return satz if schicht == "voll" else "%s_%s" % [satz, schicht]

# Stück wechseln (Akt, Hüter, Titel). Das alte blendet aus, das neue beginnt mit dem Grund.
func satz_setzen(name: String, fade := 3.0) -> void:
	if name == satz:
		return
	for k in schichten:
		var e: Dictionary = schichten[k]
		if e.p.playing:
			e.w = 0.0
			e.r = 1.0 / maxf(0.1, fade)
			ausklang.append(e)
	schichten = {}
	satz = name
	mus_name = name
	zyklus = 0
	grund_pos = 0.0
	if name == "":
		return
	for k in SATZ_SCHICHTEN.get(name, ["grund", "melodie", "spannung", "kampf"]):
		var s := _stream(_datei(k))
		if s == null:
			continue
		if s is AudioStreamOggVorbis:
			s.loop = true
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.volume_db = -80.0
		add_child(p)
		schichten[k] = {"p": p, "g": 0.0, "w": 0.0, "r": 1.0 / maxf(0.1, fade), "v": float(VOL.get(name, -10.0))}

# Lage der Musik: „erkunden“, „spannung“, „kampf“, „stille“ (nach dem Kampf), „hueter“ mit Phase 1 bis 3, „titel“.
# Für den Hüter: sfx.lage("hueter", phase) aus hueter.gd/main.gd; die Akte wählt area_music() in main.gd.
func lage(name: String, ph := 1, fade := 2.5) -> void:
	if name == "hueter":
		satz_setzen("mus_hueter", 1.5)
	elif name == "titel":
		satz_setzen("mus_titel", fade)
	if name == "stille" and lage_name == "kampf":
		_nachklang()
	lage_name = name
	phase = ph
	stille_t = STILLE_DAUER if name == "stille" else 0.0
	var ziel: Dictionary = {}
	if name == "hueter":
		ziel = {"grund": 1.0}
		for i in range(1, 4):
			if ph >= i:
				ziel["p%d" % i] = 1.0
	else:
		ziel = LAGEN.get(name, {"grund": 1.0})
	for k in schichten:
		var e: Dictionary = schichten[k]
		e.w = float(ziel.get(k, 0.0))
		e.r = 1.0 / maxf(0.1, fade if e.w > e.g else fade * 1.6)

func _nachklang() -> void:
	var s := _stream(satz + "_nachklang")
	if s == null or muted:
		return
	if nachklang == null:
		nachklang = AudioStreamPlayer.new()
		add_child(nachklang)
	nachklang.stream = s
	nachklang.volume_db = VOL.nachklang + MUS_TRIM + linear_to_db(maxf(0.001, float(Spiel.einst.musik)))
	nachklang.play()

# Ältere Schnittstelle: Musik nach Namen. "" blendet aus; mus_titel, mus_a1 … und mus_hueter wählen das Stück;
# mus_kampf schaltet das laufende Stück in den Kampf.
func music(name: String, fade := 2.0) -> void:
	if name == "":
		satz_setzen("", fade)
		lage_name = ""
		return
	if name == "mus_kampf":
		if satz.begins_with("mus_a"):
			lage("kampf", 1, fade)
		else:
			lage("hueter", 1, fade)
		return
	if name == "mus_titel":
		lage("titel", 1, fade)
		return
	if name == "mus_hueter":
		lage("hueter", 1, fade)
		return
	name = ALTE_NAMEN.get(name, name)
	satz_setzen(name, fade)
	lage("erkunden", 1, fade)

func music_set(names: Array, fade := 2.0) -> void:
	mus_list = names.duplicate()
	music(names[0] if not names.is_empty() else "", fade)

func schicht_spielt(k: String) -> bool:
	return schichten.has(k) and schichten[k].p.playing

func _process(delta: float) -> void:
	mus_duck = move_toward(mus_duck, MUS_DUCK if voice.playing else 0.0, delta * 18.0)
	var basis: float = float(VOL.get(satz, -10.0)) + MUS_TRIM + mus_duck
	var regler := float(Spiel.einst.musik)
	# Runden zählen: springt der Grund an den Anfang, beginnt eine neue Runde
	var g: Dictionary = schichten.get("grund", schichten.get("voll", {}))
	var gpos := 0.0
	if not g.is_empty() and g.p.playing:
		gpos = g.p.get_playback_position()
		if gpos + 1.0 < grund_pos:
			zyklus += 1
		grund_pos = gpos
	if stille_t > 0.0:
		stille_t -= delta
		if stille_t <= 0.0 and lage_name == "stille":
			lage("erkunden", 1, 6.0)
	for k in schichten:
		var e: Dictionary = schichten[k]
		var w: float = e.w
		if k == "melodie" and zyklus % MELODIE_PAUSE == MELODIE_PAUSE - 1:
			w = 0.0
		e.g = move_toward(e.g, w, delta * e.r)
		var p: AudioStreamPlayer = e.p
		if e.g > 0.0 and not p.playing:
			# eine Schicht setzt im Takt des Grundes ein (im Browser spart eine schweigende Schicht Rechenzeit)
			p.play(fmod(gpos, maxf(0.1, p.stream.get_length())) if k != "grund" and k != "voll" else 0.0)
		elif e.g <= 0.0 and w <= 0.0 and p.playing and k != "grund" and k != "voll":
			p.stop()
		if p.playing:
			p.volume_db = basis + linear_to_db(maxf(0.001, e.g * regler))
	for e in ausklang.duplicate():
		e.g = move_toward(e.g, 0.0, delta * e.r)
		if e.g <= 0.0:
			e.p.queue_free()
			ausklang.erase(e)
		else:
			e.p.volume_db = e.v + MUS_TRIM + mus_duck + linear_to_db(maxf(0.001, e.g * regler))

# Lautstärke aus den Einstellungen (Spielmenü): gesamt über den Hauptkanal, Musik zusätzlich für sich
func einst_anwenden() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(Spiel.einst.laut))))

func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
