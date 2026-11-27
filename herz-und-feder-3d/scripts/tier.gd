class_name Tier extends RefCounted
# Ein einzelnes Tier (4.3): wo es ist, was es gerade tut, wie es auf den Helden und auf Kampf reagiert. Jede Art hat
# eine kleine Zustandsmaschine mit wenigen Zahlen; die Gestalt kommt aus tiere.gd, die Bewegung der Glieder aus
# tiere.gdshader. Dem Shader wird je Bild nur gesagt: Schrittphase, Tempo und vier Posenwerte.
#
#   Eidechse     sonnt sich (Kopf hoch, ab und zu Liegestütze), huscht in Schüben, verharrt; flieht in Mauerritzen
#                und lugt nach einer Weile wieder hervor.
#   Skarabäus    krabbelt im Dreifuß, hält an, dreht um; manche schieben rückwärts ihre Kugel. Schwarzkäfer
#                (in Gräbern) krabbeln nur. Kommt der Held, erstarren sie und krabbeln dann davon.
#   Maus         schnüffelt, huscht in Sprüngen, richtet sich auf und sichert; flieht in Ritzen.
#   Falke        kreist hoch über der Stunde mit Gleiten und Schlagphasen (Schatten am Boden), stößt ab und zu
#                herab, landet, sitzt und schaut; fliegt auf, wenn der Held kommt oder gekämpft wird.
#   Ibis         schreitet am Becken und stochert mit dem Schnabel im Schlamm; fliegt auf und landet am anderen Ufer.
#   Fisch        im Schwarm: alle folgen einem wandernden Ziel im Becken, wenden gemeinsam, stieben auseinander.
#   Fledermaus   flattert unregelmäßig unter der Decke.
#   Esel, Schaf, Ziege, Katze  grasen (Kopf unten, kauen), heben den Kopf, schauen dem Helden nach, weichen aus.
#                Die Tiere der Aufträge (orte.gd) stehen fest an ihrem Platz.

var game                       # das Spiel (main.gd); untypisiert wie überall
var art := ""
var n: Node3D                  # Wurzel: Ort und Blickrichtung
var mi: MeshInstance3D         # der Körper
var heim := Vector3.ZERO
var ziel := Vector3.ZERO
var zustand := ""
var zeit := 0.0                # wie lange der Zustand noch dauert
var v := 0.0                   # Tempo über Grund (m/s); negativ = rückwärts
var gang := 0.0                # Schrittphase für den Shader
var tempo := 0.0               # 0 … 1, geglättet
var pose := Vector4.ZERO
var pose_soll := Vector4.ZERO
var schatten := 0.35           # Halbmesser des Schattenflecks am Boden (0 = keiner)
var schatten_form := Vector2(1, 1)   # Streckung quer und längs
var schatten_versatz := 0.0          # Mitte des Flecks vor (+) oder hinter (−) dem Tier
var sichtbar := true
var u := randf() * 100.0       # eigene Uhr
var gross := 1.0
var schritt_laenge := 0.12     # Weg je Schrittzyklus (m, in Modellmaß)
var krumm := 0.0               # Ruhe-S-Form (Eidechse)
var fest := false              # Tier eines Auftrags: bleibt, wo es ist (orte.gd bewegt es)
var flug := false              # Vogel in der Luft (andere Gestalt)
var flatter := 0.0             # Flügelschlag-Phase (Vögel, Fledermaus)
var kugel: MeshInstance3D      # Mistkugel des Skarabäus
var kugel_dreh := 0.0
var bild_flug: MeshInstance3D  # Schatten des Vogels im Flug (eigener Stoff, auf den Boden gelegt)
var schwarm := {}              # Fische: gemeinsames Ziel; Ibis: Becken
var versatz := Vector3.ZERO    # Fische: eigener Platz im Schwarm
var hoehe := 0.0
var r_kreis := 10.0
var w_kreis := 0.0
var alt_pos := Vector3.ZERO

const SCHEU := {"eidechse": 2.6, "skarabaeus": 1.0, "schwarzkaefer": 1.0, "maus": 3.0, "ibis": 4.5, "falke": 5.0, "esel": 1.7, "schaf": 2.0, "ziege": 2.0, "katze": 2.4}
const NETZ := {"skarabaeus": "kaefer", "falke": "falke_flug", "ibis": "ibis_steh"}

static func neu(g, a: String, wo: Vector3) -> Tier:
	var e := Tier.new()
	e.game = g
	e.art = a
	e.heim = wo
	e.ziel = wo
	e.alt_pos = wo
	e.n = Node3D.new()
	g.add_child(e.n)
	e.n.global_position = wo
	e.n.rotation.y = randf() * TAU
	e.mi = MeshInstance3D.new()
	e.n.add_child(e.mi)
	e._gestalt(NETZ.get(a, a))
	e.mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.mi.extra_cull_margin = 0.8
	e.mi.set_instance_shader_parameter("zeit0", randf() * 50.0)
	match a:
		"eidechse":
			e.gross = randf_range(1.25, 1.45)
			e.schatten = 0.24
			e.schatten_form = Vector2(0.55, 1.3)
			e.schatten_versatz = -0.05
			e.schritt_laenge = 0.13
			e.krumm = randf_range(-1.0, 1.0)
			e.zustand = "sonnt"
		"skarabaeus", "schwarzkaefer":
			e.gross = randf_range(1.5, 1.8)
			e.schatten = 0.1
			e.schritt_laenge = 0.05
			e.zustand = "krabbelt"
			if a == "skarabaeus" and randf() < 0.4:
				e.kugel = MeshInstance3D.new()
				e.kugel.mesh = Tiere.netz("kugel")
				e.kugel.material_override = Tiere.stoff("kugel")
				e.kugel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				g.add_child(e.kugel)
				e.zustand = "schiebt"
		"maus":
			e.gross = randf_range(1.5, 1.7)
			e.schatten = 0.11
			e.schatten_form = Vector2(0.7, 1.3)
			e.schritt_laenge = 0.07
			e.zustand = "schnueffelt"
		"falke":
			e.gross = randf_range(1.1, 1.25)
			e.schatten = 0.0
			e.flug = true
			e.hoehe = randf_range(9.0, 13.0)
			e.r_kreis = randf_range(7.0, 13.0)
			e.w_kreis = randf() * TAU
			e.zustand = "kreist"
			e.n.global_position = wo + Vector3(0, e.hoehe, 0)
			e._flugschatten()
		"ibis":
			e.gross = randf_range(1.0, 1.1)
			e.schatten = 0.2
			e.schatten_form = Vector2(0.7, 1.2)
			e.schritt_laenge = 0.22
			e.zustand = "stochert"
		"fisch":
			e.gross = randf_range(0.9, 1.2)
			e.schatten = 0.0
			e.zustand = "schwimmt"
		"fledermaus":
			e.gross = randf_range(1.3, 1.6)
			e.schatten = 0.0
			e.flug = true
			e.hoehe = randf_range(2.4, 3.3)
			e.zustand = "flattert"
			e.n.global_position = wo + Vector3(0, e.hoehe, 0)
		"esel", "schaf", "ziege", "katze":
			e.gross = {"esel": 1.0, "schaf": 1.05, "ziege": 1.05, "katze": 1.2}[a] * randf_range(0.93, 1.05)
			e.schatten = {"esel": 0.55, "schaf": 0.45, "ziege": 0.4, "katze": 0.22}[a]
			e.schatten_form = Vector2(0.75, 1.3)
			e.schritt_laenge = {"esel": 0.55, "schaf": 0.4, "ziege": 0.42, "katze": 0.22}[a]
			e.zustand = "grast" if a != "katze" else "sitzt"
			e.mi.set_instance_shader_parameter("farbe", Color.from_hsv(randf_range(0.05, 0.1), randf_range(0.0, 0.15), randf_range(0.82, 1.05)))
	e.zeit = randf_range(0.5, 5.0)
	e.n.scale = Vector3.ONE * e.gross
	return e

func _gestalt(netz: String) -> void:
	mi.mesh = Tiere.netz(netz)
	mi.material_override = Tiere.stoff(netz)

# Schatten des fliegenden Vogels: dasselbe Netz mit einem Stoff, der es flach auf den Boden legt (tiere.gdshader mit
# SCHATTEN). Die Flügel schlagen auch im Schatten.
func _flugschatten() -> void:
	bild_flug = MeshInstance3D.new()
	bild_flug.mesh = mi.mesh
	bild_flug.material_override = Tiere.schatten_stoff()
	bild_flug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bild_flug.extra_cull_margin = 40.0
	n.add_child(bild_flug)

func entfernen() -> void:
	if is_instance_valid(n):
		n.queue_free()
	if kugel and is_instance_valid(kugel):
		kugel.queue_free()

# ---------------------------------------------------------------- jeden Physik-Schritt
func tick(d: float, hp: Vector3) -> void:
	if fest and n.scale.x < gross * 0.3:
		sichtbar = false   # gefunden und heimgelaufen (orte.gd lässt es schrumpfen)
	u += d
	zeit -= d
	match art:
		"eidechse":
			_eidechse(d, hp)
		"skarabaeus", "schwarzkaefer":
			_kaefer(d, hp)
		"maus":
			_maus(d, hp)
		"falke":
			_falke(d, hp)
		"ibis":
			_ibis(d, hp)
		"fisch":
			_fisch(d, hp)
		"fledermaus":
			_fledermaus(d)
		"esel", "schaf", "ziege", "katze":
			_vierbeiner(d, hp)
	if fest:
		# vom Auftrag bewegt (heimlaufen): Tempo aus dem Weg ablesen
		var weg := n.global_position - alt_pos
		weg.y = 0.0
		v = weg.length() / maxf(d, 0.001)
	alt_pos = n.global_position
	var ziel_tempo := clampf(absf(v) / maxf(0.01, schritt_laenge * gross * 2.5), 0.0, 1.0) if absf(v) > 0.01 else 0.0
	tempo = move_toward(tempo, ziel_tempo, d * 8.0)
	if flug:
		gang = flatter
	else:
		gang = fmod(gang + v * d / (schritt_laenge * gross) * TAU, TAU * 64.0)
	pose = pose.lerp(pose_soll, 1.0 - exp(-d * 7.0))
	mi.set_instance_shader_parameter("gang", gang)
	mi.set_instance_shader_parameter("tempo", tempo)
	mi.set_instance_shader_parameter("pose", pose)
	if bild_flug and bild_flug.visible:
		bild_flug.set_instance_shader_parameter("gang", gang)
		bild_flug.set_instance_shader_parameter("pose", pose)

# ---------------------------------------------------------------- Hilfen
func _frei(p: Vector3) -> bool:
	return not game.astar.is_point_solid(game._sub(p))

# Gefahr: Held zu nah oder Kampf in der Nähe. Gibt den Punkt zurück, vor dem es flieht (oder INF).
func _gefahr(hp: Vector3, scheu: float) -> Vector3:
	var pos := n.global_position
	if Vector2(pos.x - hp.x, pos.z - hp.z).length() < scheu:
		return hp
	if game.leben:
		var k: Vector3 = game.leben._gefahr(pos)
		if k != Vector3.INF and k.distance_to(pos) < 7.0:
			return k
	return Vector3.INF

# schrittweise zum Ziel; dreht sich dabei zum Ziel hin. Gibt true, wenn angekommen oder blockiert.
func _gehe(d: float, zu_tempo: float, wende := 12.0) -> bool:
	var pos := n.global_position
	var zu := ziel - pos
	zu.y = 0.0
	var l := zu.length()
	if l < 0.06:
		v = 0.0
		return true
	var soll_dreh := atan2(zu.x, zu.z)
	n.rotation.y = lerp_angle(n.rotation.y, soll_dreh, 1.0 - exp(-d * wende))
	# erst drehen, dann laufen: wer quer zum Ziel steht, läuft langsam
	var quer := absf(wrapf(soll_dreh - n.rotation.y, -PI, PI))
	v = move_toward(v, zu_tempo * clampf(1.4 - quer, 0.15, 1.0), d * zu_tempo * 10.0)
	var schritt := minf(l, v * d)
	var vor := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
	var neu := pos + vor * schritt
	if not _frei(neu):
		v = 0.0
		return true
	n.global_position = neu
	return false

func _punkt_bei(mitte: Vector3, r_min: float, r_max: float) -> Vector3:
	for i in 8:
		var w := randf() * TAU
		var q := mitte + Vector3(cos(w), 0, sin(w)) * randf_range(r_min, r_max)
		q.y = 0.0
		if _frei(q):
			return q
	return Vector3(mitte.x, 0, mitte.z)

func _weg_von(g: Vector3, weite: float) -> Vector3:
	var weg := n.global_position - g
	weg.y = 0.0
	if weg.length() < 0.05:
		weg = Vector3(1, 0, 0)
	for i in 5:
		var w := (i - 2) * 0.5
		var q := n.global_position + weg.normalized().rotated(Vector3.UP, w) * weite
		q.y = 0.0
		if _frei(q):
			return q
	return _punkt_bei(n.global_position, weite * 0.5, weite)

# Versteck: die nächste Mauer oder der nächste Fels in Fluchtrichtung (Rand einer festen Zelle)
func _versteck(weg_von: Vector3) -> Vector3:
	var pos := n.global_position
	var flucht := pos - weg_von
	flucht.y = 0.0
	var basis := atan2(flucht.x, flucht.z) if flucht.length() > 0.01 else randf() * TAU
	var best := Vector3.INF
	var best_d := 99.0
	for i in 9:
		var w := basis + (i - 4) * 0.35
		var dir := Vector3(sin(w), 0, cos(w))
		var p := pos
		for s in 16:
			var q := p + dir * 0.35
			if not _frei(q):
				var dd := pos.distance_to(p)
				if dd < best_d and dd > 0.3:
					best_d = dd
					best = p
				break
			p = q
	return best

# Kopf zum Helden drehen (Winkel gegen die Körperrichtung, begrenzt)
func _blick(hp: Vector3, weit := 6.0, grenze := 0.9) -> float:
	var zu := hp - n.global_position
	if zu.length() > weit:
		return 0.0
	return clampf(wrapf(atan2(zu.x, zu.z) - n.rotation.y, -PI, PI), -grenze, grenze)

func _verstecken(g: Vector3) -> void:
	var vs := _versteck(g)
	ziel = vs if vs != Vector3.INF else _weg_von(g, 4.0)
	zustand = "flieht"
	game.sfx.play_at("ev_maus", n.global_position, 0.15, -8.0)   # Rascheln, wenn Eidechse oder Maus flieht
	zeit = 3.0

func _aus_versteck(hp: Vector3) -> void:
	v = 0.0
	if zeit <= 0.0 and n.global_position.distance_to(hp) > 4.0:
		zustand = "ruht"
		zeit = randf_range(3.0, 7.0)
		heim = n.global_position
		sichtbar = true

# ---------------------------------------------------------------- Eidechse
func _eidechse(d: float, hp: Vector3) -> void:
	var g := _gefahr(hp, SCHEU.eidechse)
	if g != Vector3.INF and zustand != "flieht" and zustand != "versteckt":
		_verstecken(g)
		pose_soll = Vector4.ZERO
	match zustand:
		"sonnt", "ruht":
			# still, den Kopf etwas erhoben; ab und zu den Kopf drehen oder drei Liegestütze zeigen
			v = 0.0
			var stuetz := 0.0
			var ph := fmod(u, 9.0)
			if ph > 6.5 and ph < 8.3:
				stuetz = maxf(0.0, sin((ph - 6.5) * TAU * 1.6))
			pose_soll = Vector4(0.12, 0.35 * sin(u * 0.5) * float(fmod(u, 5.0) < 2.5), stuetz, krumm)
			if zeit <= 0.0:
				zustand = "lauscht"
				zeit = randf_range(0.3, 1.2)
		"lauscht":
			v = 0.0
			pose_soll = Vector4(0.0, 0.5 * sin(u * 3.0), 0.0, krumm * 0.5)
			if zeit <= 0.0:
				ziel = _punkt_bei(heim, 0.6, 2.6)
				zustand = "huscht"
				zeit = 1.6
		"huscht":
			pose_soll = Vector4.ZERO
			var da := _gehe(d, 2.4, 22.0)
			# in Schüben: mitten im Weg kurz anhalten
			if not da and randf() < d * 1.2:
				zustand = "verharrt"
				zeit = randf_range(0.25, 0.8)
			elif da or zeit <= 0.0:
				zustand = "sonnt"
				zeit = randf_range(2.5, 8.0)
				krumm = randf_range(-1.0, 1.0)
		"verharrt":
			v = 0.0
			pose_soll = Vector4(-0.05, 0.0, 0.0, krumm * 0.4)
			if zeit <= 0.0:
				zustand = "huscht"
				zeit = 1.5
		"flieht":
			if _gehe(d, 3.8, 30.0) or zeit <= 0.0:
				zustand = "versteckt"
				zeit = randf_range(4.0, 9.0)
				sichtbar = false
		"versteckt":
			_aus_versteck(hp)

# ---------------------------------------------------------------- Käfer
func _kaefer(d: float, hp: Vector3) -> void:
	var g := _gefahr(hp, SCHEU.skarabaeus)
	if g != Vector3.INF and zustand != "erstarrt" and zustand != "flieht":
		zustand = "erstarrt"
		zeit = randf_range(0.8, 1.6)
		ziel = _weg_von(g, 1.2)
	match zustand:
		"krabbelt":
			pose_soll = Vector4.ZERO
			if _gehe(d, 0.16, 4.0) or zeit <= 0.0:
				zustand = "haelt"
				zeit = randf_range(0.8, 3.5)
		"haelt":
			v = 0.0
			if zeit <= 0.0:
				ziel = _punkt_bei(heim, 0.3, 1.4)
				zustand = "krabbelt"
				zeit = randf_range(4.0, 9.0)
		"schiebt":
			# rückwärts, Kopf unten, die Kugel liegt hinter dem Käfer und rollt
			pose_soll = Vector4(0.42, 0, 0, 0)
			var hinter := -Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
			n.rotation.y += sin(u * 0.7) * d * 0.5
			v = -0.09
			var neu := n.global_position + hinter * 0.09 * d
			var kp := neu + hinter * 0.11 * gross
			if not _frei(kp) or neu.distance_to(heim) > 2.5:
				# Hindernis oder zu weit: drehen
				n.rotation.y += PI * 0.6 * d * 3.0
				v = 0.0
				if neu.distance_to(heim) > 2.5:
					heim = n.global_position
			else:
				n.global_position = neu
				kugel_dreh += 0.09 * d / (0.045 * gross)
		"erstarrt":
			v = 0.0
			if zeit <= 0.0:
				zustand = "flieht"
				zeit = 3.0
		"flieht":
			if _gehe(d, 0.3, 6.0) or zeit <= 0.0:
				heim = n.global_position
				zustand = "schiebt" if kugel else "haelt"
				zeit = 2.0
	if kugel:
		var hinter := -Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		kugel.global_position = n.global_position + hinter * 0.11 * gross + Vector3(0, 0.045 * gross, 0)
		kugel.scale = Vector3.ONE * gross
		kugel.rotation = Vector3(-kugel_dreh, n.rotation.y, 0)
		kugel.visible = n.visible

# ---------------------------------------------------------------- Maus
func _maus(d: float, hp: Vector3) -> void:
	var g := _gefahr(hp, SCHEU.maus)
	if g != Vector3.INF and zustand != "flieht" and zustand != "versteckt":
		_verstecken(g)
		pose_soll = Vector4.ZERO
	match zustand:
		"schnueffelt", "ruht":
			v = 0.0
			pose_soll = Vector4(0.25 + 0.15 * sin(u * 11.0), 0.3 * sin(u * 1.3), 0, 0)
			if zeit <= 0.0:
				if randf() < 0.35:
					zustand = "sichert"
					zeit = randf_range(1.2, 2.8)
				else:
					ziel = _punkt_bei(heim, 0.4, 2.0)
					zustand = "huscht"
					zeit = 2.0
		"sichert":
			v = 0.0
			pose_soll = Vector4(-0.1, 0.7 * sin(u * 2.2), 1.0, 0)
			if zeit <= 0.0:
				zustand = "schnueffelt"
				zeit = randf_range(1.0, 3.0)
		"huscht":
			pose_soll = Vector4(0.1, 0, 0, 0)
			if _gehe(d, 1.8, 18.0) or zeit <= 0.0:
				zustand = "schnueffelt"
				zeit = randf_range(0.8, 3.0)
		"flieht":
			if _gehe(d, 3.6, 28.0) or zeit <= 0.0:
				zustand = "versteckt"
				zeit = randf_range(5.0, 10.0)
				sichtbar = false
		"versteckt":
			_aus_versteck(hp)

# ---------------------------------------------------------------- Falke
func _falke(d: float, hp: Vector3) -> void:
	var pos := n.global_position
	match zustand:
		"kreist":
			# Kreise um einen Punkt zwischen Held und Heim; lange Gleitphasen, dazwischen ein paar Schläge
			var mitte := Vector3(hp.x, 0, hp.z).lerp(Vector3(heim.x, 0, heim.z), 0.6)
			w_kreis += d * 5.5 / r_kreis
			var soll := mitte + Vector3(cos(w_kreis) * r_kreis, hoehe + sin(u * 0.3) * 1.2, sin(w_kreis) * r_kreis)
			_fliege(d, soll, 5.5, 0.9)
			var schlag := fmod(u, 9.0) < 1.6
			flatter += d * (11.0 if schlag else 0.0)
			pose_soll = Vector4(0, -0.35, 0.55 if schlag else 0.0, 0.12 if not schlag else 0.0)
			if zeit <= 0.0 and randf() < d * 0.05:
				# herabstoßen und landen, nicht zu nah am Helden
				var q := _punkt_bei(Vector3(hp.x, 0, hp.z), 7.0, 12.0)
				if q.distance_to(hp) > 6.0:
					ziel = q
					zustand = "stoesst"
		"stoesst":
			var soll := ziel + Vector3(0, 0.02, 0)
			var nah := pos.distance_to(soll)
			_fliege(d, soll, clampf(nah * 1.4, 3.0, 14.0), 3.0)
			pose_soll = Vector4(0.0, 0, 0.0 if nah > 3.0 else 0.8, -0.35 if nah > 3.0 else 0.2)
			flatter += d * (0.0 if nah > 3.0 else 16.0)
			if nah < 0.25:
				zustand = "sitzt"
				zeit = randf_range(6.0, 14.0)
				flug = false
				_gestalt("falke_sitz")
				bild_flug.visible = false
				schatten = 0.16
				n.global_position = Vector3(soll.x, 0, soll.z)
				n.rotation.x = 0.0
				n.rotation.z = 0.0
		"sitzt":
			v = 0.0
			pose_soll = Vector4(0.08 * sin(u * 0.9), _blick(hp, 12.0, 1.4) if fmod(u, 6.0) < 4.0 else 1.1 * sin(u * 0.6), 0, 0)
			var g := _gefahr(hp, SCHEU.falke)
			if g != Vector3.INF or zeit <= 0.0:
				zustand = "steigt"
				game.sfx.play_at("ev_fluegel", pos, 0.15, -6.0)
				zeit = 4.0
				flug = true
				_gestalt("falke_flug")
				bild_flug.mesh = mi.mesh
				bild_flug.visible = true
				schatten = 0.0
				var weg := pos - (g if g != Vector3.INF else hp)
				weg.y = 0.0
				ziel = pos + weg.normalized() * 10.0 + Vector3(0, hoehe, 0)
		"steigt":
			_fliege(d, ziel, 6.5, 2.5)
			flatter += d * 15.0
			pose_soll = Vector4(0, 0, 0.95, 0.1)
			if zeit <= 0.0 or pos.distance_to(ziel) < 1.0:
				zustand = "kreist"
				if game.sfx.rng.randf() < 0.35: game.sfx.play_at("ev_falke", pos, 0.1, -4.0)   # selten ein Schrei beim Kreisen
				zeit = randf_range(20.0, 45.0)
				heim = Vector3(pos.x, 0, pos.z)

# fliegt zum Punkt, neigt sich in die Kurve
func _fliege(d: float, soll: Vector3, tempo_m: float, wende: float) -> void:
	var pos := n.global_position
	var zu := soll - pos
	if zu.length() < 0.01:
		return
	var richt := atan2(zu.x, zu.z)
	var alt := n.rotation.y
	n.rotation.y = lerp_angle(n.rotation.y, richt, 1.0 - exp(-d * wende))
	var kurve := wrapf(n.rotation.y - alt, -PI, PI) / maxf(d, 0.001)
	n.rotation.z = lerpf(n.rotation.z, clampf(-kurve * 0.5, -0.7, 0.7), 1.0 - exp(-d * 3.0))
	n.rotation.x = lerpf(n.rotation.x, clampf(-zu.normalized().y * 0.8, -0.8, 0.8), 1.0 - exp(-d * 3.0))
	n.global_position = pos + zu.normalized() * minf(zu.length(), tempo_m * d)
	v = tempo_m

# ---------------------------------------------------------------- Ibis
func _ibis(d: float, hp: Vector3) -> void:
	var pos := n.global_position
	if not flug:
		var g := _gefahr(hp, SCHEU.ibis)
		if g != Vector3.INF:
			# auffliegen: hinüber zum anderen Ufer
			flug = true
			_gestalt("ibis_flug")
			if bild_flug == null:
				_flugschatten()
			bild_flug.mesh = mi.mesh
			bild_flug.visible = true
			schatten = 0.0
			zustand = "fliegt"
			game.sfx.play_at("ev_fluegel", pos, 0.15, -5.0)
			var gegen: Vector3 = schwarm.get("mitte", heim) * 2.0 - pos
			gegen.y = 0.0
			ziel = gegen if gegen.distance_to(hp) > 6.0 and _frei(gegen) else _weg_von(g, 9.0)
			zeit = 8.0
	match zustand:
		"stochert":
			# langsam schreiten, alle paar Schritte den Schnabel in den Schlamm
			var ph := fmod(u, 2.6)
			if ph < 1.2:
				pose_soll = Vector4(-0.05, 0.2 * sin(u), 0, 0)
				if _gehe(d, 0.35, 3.0):
					ziel = _ufer()
			else:
				v = 0.0
				pose_soll = Vector4(1.25 + 0.12 * sin(u * 14.0), 0, 0, 0)
			if zeit <= 0.0:
				zustand = "steht"
				zeit = randf_range(2.0, 5.0)
		"steht":
			v = 0.0
			pose_soll = Vector4(-0.1, _blick(hp, 9.0, 1.2), 0, 0.3 * sin(u * 3.0))
			if zeit <= 0.0:
				zustand = "stochert"
				zeit = randf_range(6.0, 14.0)
				ziel = _ufer()
		"fliegt":
			var nah := Vector2(pos.x - ziel.x, pos.z - ziel.z).length()
			var hoch := clampf(nah * 0.5, 0.0, 3.5)
			_fliege(d, ziel + Vector3(0, hoch, 0), 4.5, 2.0)
			flatter += d * (9.0 if nah > 1.5 else 13.0)
			pose_soll = Vector4(0, 0, 0.8, 0.05)
			if nah < 0.3 or zeit <= 0.0:
				flug = false
				_gestalt("ibis_steh")
				bild_flug.visible = false
				schatten = 0.2
				n.global_position = Vector3(pos.x, 0, pos.z)
				n.rotation.x = 0.0
				n.rotation.z = 0.0
				heim = n.global_position
				zustand = "steht"
				zeit = randf_range(2.0, 4.0)

# ein Punkt am Ufer des Beckens (oder in der Nähe des Heims)
func _ufer() -> Vector3:
	if schwarm.has("mitte"):
		var w := randf() * TAU
		var q: Vector3 = schwarm.mitte + Vector3(cos(w), 0, sin(w)) * (float(schwarm.r) + randf_range(0.2, 0.6))
		q.y = 0.0
		if _frei(q):
			return q
	return _punkt_bei(heim, 0.5, 2.0)

# ---------------------------------------------------------------- Fische im Schwarm
func _fisch(d: float, hp: Vector3) -> void:
	var s := schwarm
	var mitte: Vector3 = s.mitte
	var r: float = s.r
	# das Ziel des Schwarms wandert; der erste Fisch des Schwarms führt es nach
	if s.fuehrer == self:
		s.zeit -= d
		var scheu := Vector2(hp.x - mitte.x, hp.z - mitte.z).length() < r + 1.6
		if s.zeit <= 0.0 or (scheu and not s.scheu):
			var w := randf() * TAU
			if scheu:
				var weg := mitte - hp
				w = atan2(weg.z, weg.x) + randf_range(-0.6, 0.6)
			s.ziel = mitte + Vector3(cos(w), 0, sin(w)) * randf_range(0.2, r * 0.75)
			s.zeit = randf_range(2.5, 6.0)
			s.tempo = 1.6 if scheu else randf_range(0.35, 0.6)
		s.scheu = scheu
		s.tempo = move_toward(float(s.tempo), 0.45, d * 0.4)
	var soll: Vector3 = s.ziel + versatz
	var off := soll - mitte
	off.y = 0.0
	if off.length() > r - 0.15:
		soll = mitte + off.normalized() * (r - 0.15)
	soll.y = mitte.y + 0.12 + versatz.y
	var pos := n.global_position
	var zu := soll - pos
	zu.y = 0.0
	var t: float = float(s.tempo) * (1.0 + 0.15 * sin(u * 1.7))
	if zu.length() > 0.08:
		var richt := atan2(zu.x, zu.z)
		var alt := n.rotation.y
		n.rotation.y = lerp_angle(n.rotation.y, richt, 1.0 - exp(-d * 4.0))
		pose_soll.y = clampf(wrapf(n.rotation.y - alt, -PI, PI) / maxf(d, 0.001) * 0.4, -1.0, 1.0)
		var vor := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		n.global_position = pos + vor * minf(zu.length(), t * d)
		v = t
	else:
		v = 0.1
	n.global_position.y = soll.y
	flatter += d * (5.0 + t * 14.0)
	flug = true

# ---------------------------------------------------------------- Fledermaus
func _fledermaus(d: float) -> void:
	if zeit <= 0.0 or n.global_position.distance_to(ziel) < 0.4:
		ziel = heim + Vector3(randf_range(-3.0, 3.0), hoehe + randf_range(-0.5, 0.6), randf_range(-3.0, 3.0))
		zeit = randf_range(0.4, 1.4)
		if game.sfx.rng.randf() < 0.04: game.sfx.play_at("ev_fledermaus", n.global_position, 0.15, -8.0)   # selten ein Fiepen
	_fliege(d, ziel, 3.2 + sin(u * 4.0), 7.0)
	flatter += d * (17.0 + 6.0 * sin(u * 3.3))
	pose_soll = Vector4(0, 0, 0.95, 0.05)

# ---------------------------------------------------------------- Esel, Schaf, Ziege, Katze
func _vierbeiner(d: float, hp: Vector3) -> void:
	var katze := art == "katze"
	if not fest:
		var g := _gefahr(hp, SCHEU[art])
		if g != Vector3.INF and zustand != "weicht":
			ziel = _weg_von(g, 2.5 if not katze else 4.0)
			zustand = "weicht"
			if art == "esel" and game.sfx.rng.randf() < 0.5: game.sfx.play_at("ev_esel", n.global_position, 0.1, -2.0)
			zeit = 3.0
	var blick := _blick(hp, 7.0, 1.0)
	match zustand:
		"grast":
			v = 0.0
			pose_soll = Vector4(1.0 if not katze else 0.5, 0.15 * sin(u * 0.4), 0, 0)
			if zeit <= 0.0 or (blick != 0.0 and randf() < d * 0.6):
				zustand = "schaut"
				zeit = randf_range(2.0, 5.0)
		"schaut", "sitzt":
			v = 0.0
			pose_soll = Vector4(-0.15, blick if blick != 0.0 else 0.6 * sin(u * 0.5), 0.6 if katze and zustand == "sitzt" else 0.0, 0.4 if katze else 0.0)
			if zeit <= 0.0:
				if fest or randf() < 0.55:
					zustand = "grast" if not katze else ("sitzt" if randf() < 0.5 else "schaut")
					zeit = randf_range(4.0, 10.0)
				else:
					ziel = _punkt_bei(heim, 1.0, 4.0)
					zustand = "geht"
					zeit = 8.0
		"geht":
			pose_soll = Vector4(0.15, 0, 0, 0.8 if katze else 0.0)
			if _gehe(d, 0.75 if not katze else 0.6, 3.0) or zeit <= 0.0:
				zustand = "grast" if not katze else "sitzt"
				zeit = randf_range(5.0, 12.0)
		"weicht":
			pose_soll = Vector4(-0.25, 0, 0, 0.9 if katze else 0.3)
			if _gehe(d, 1.6 if not katze else 2.6, 5.0) or zeit <= 0.0:
				heim = n.global_position
				zustand = "schaut"
				zeit = randf_range(2.0, 4.0)
