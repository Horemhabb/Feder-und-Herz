class_name Tiere extends RefCounted
# Gestalt der Kleintiere und Vögel (4.3). Jede Art wird einmal gebaut (Netz und Stoff) und von allen Tieren der Art
# geteilt. Bewegt werden sie von tiere.gdshader; was ein einzelnes Tier tut, steht in tier.gd.
# Alle Arten teilen eine Farbtafel (models/tiere/tiere_tafel.webp, gemalt von tools/figurenfabrik/kleintiere_tafel.py).
# Maße in Metern, so wie das Tier im Spiel steht (etwas größer als in Natur, damit man es aus der Höhe erkennt).

const TAFEL := "res://models/tiere/tiere_tafel.webp"
# Felder der Tafel (wie FELDER in kleintiere_tafel.py, geteilt durch 1024)
const FELD := {
	"eidechse": Rect2(0, 0, 0.25, 0.5),
	"kaefer": Rect2(0.25, 0, 0.25, 0.25),
	"kugel": Rect2(0.5, 0, 0.125, 0.125),
	"schwarzkaefer": Rect2(0.625, 0, 0.125, 0.125),
	"maus": Rect2(0.25, 0.25, 0.25, 0.25),
	"falke_flug": Rect2(0.5, 0.125, 0.5, 0.25),
	"falke_sitz": Rect2(0.75, 0, 0.25, 0.125),
	"ibis_flug": Rect2(0.5, 0.375, 0.5, 0.25),
	"ibis_steh": Rect2(0, 0.5, 0.25, 0.25),
	"wiedehopf": Rect2(0.25, 0.5, 0.25, 0.25),
	"fisch": Rect2(0.5, 0.625, 0.25, 0.125),
	"fledermaus": Rect2(0.75, 0.625, 0.25, 0.125),
	"esel": Rect2(0, 0.75, 0.25, 0.25),
	"schaf": Rect2(0.25, 0.75, 0.25, 0.125),
	"ziege": Rect2(0.25, 0.875, 0.25, 0.125),
	"katze": Rect2(0.5, 0.75, 0.25, 0.25),
}
# feste Stellen der Tafel: Augen (dunkel, mit Glanzpunkt), Horn/Krallen, Schnabelgelb
const AUGE := Vector2(784.0 / 1024.0, 784.0 / 1024.0)
const HORN := Vector2(816.0 / 1024.0, 784.0 / 1024.0)
const GELB := Vector2(848.0 / 1024.0, 784.0 / 1024.0)
const SCHWARZ := Vector2(880.0 / 1024.0, 784.0 / 1024.0)
const WEISS := Vector2(912.0 / 1024.0, 784.0 / 1024.0)
const ROSA := Vector2(944.0 / 1024.0, 784.0 / 1024.0)

# Teile (wie im Shader)
const LEIB := 0
const KOPF := 7
const SCHWANZ := 8
const FLUEGEL := 9
const FUEHLER := 10
const HALS := 11
const FLOSSE := 12

static var _netz := {}
static var _stoff := {}
static var _shader: Shader
static var _tafel: Texture2D

static func tafel() -> Texture2D:
	if _tafel == null:
		_tafel = load(TAFEL)
	return _tafel

# ---------------------------------------------------------------- Stoff (ein Material je Art)
static func stoff(art: String) -> ShaderMaterial:
	if _stoff.has(art):
		return _stoff[art]
	if _shader == null:
		_shader = load("res://scripts/tiere.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("tafel", tafel())
	var p := {}
	match art:
		"eidechse":
			p = {"art": 1, "bauch": Color(0.86, 0.8, 0.66), "bauch_an": 0.7, "rauh": 0.62, "spiegel": 0.4, "schritt": 0.55, "hub": 0.018,
				"welle": 0.022, "wellen_k": 11.0, "leib_z": 0.0, "schwanz_z": -0.12}
		"kaefer":
			p = {"art": 2, "bauch": Color(0.08, 0.07, 0.06), "bauch_an": 0.6, "rauh": 0.3, "spiegel": 0.75, "schimmer": Color(0.1, 0.32, 0.3), "schritt": 0.55, "hub": 0.012}
		"schwarzkaefer":
			p = {"art": 2, "bauch": Color(0.06, 0.05, 0.05), "bauch_an": 0.6, "rauh": 0.7, "spiegel": 0.3, "schritt": 0.6, "hub": 0.014}
		"kugel":
			p = {"art": 0, "rauh": 0.95, "spiegel": 0.1}
		"falke_flug":
			p = {"art": 4, "bauch": Color(0.86, 0.8, 0.7), "bauch_an": 0.55, "rauh": 0.8, "spiegel": 0.3}
		"falke_sitz":
			p = {"art": 5, "bauch": Color(0.86, 0.8, 0.7), "bauch_an": 0.0, "rauh": 0.8, "spiegel": 0.3, "schritt": 0.4, "hub": 0.0}
		"maus":
			p = {"art": 3, "bauch": Color(0.92, 0.88, 0.8), "bauch_an": 0.8, "rauh": 0.9, "spiegel": 0.2, "schritt": 0.7, "kopf_piv": Vector3(0, 0.033, 0.03)}
		"ibis_steh":
			p = {"art": 5, "rauh": 0.85, "spiegel": 0.25, "schritt": 0.45}
		"ibis_flug":
			p = {"art": 4, "bauch": Color(0.9, 0.9, 0.88), "bauch_an": 0.3, "rauh": 0.85, "spiegel": 0.25}
		"fisch":
			p = {"art": 6, "bauch": Color(0.85, 0.8, 0.7), "bauch_an": 0.5, "rauh": 0.35, "spiegel": 0.7, "schimmer": Color(0.05, 0.12, 0.12),
				"welle": 0.025, "wellen_k": 22.0, "leib_z": 0.06}
		"fledermaus":
			p = {"art": 7, "bauch": Color(0.32, 0.26, 0.22), "bauch_an": 0.4, "rauh": 0.9, "spiegel": 0.15}
		"esel", "schaf", "ziege", "katze":
			p = {"art": 8, "bauch": Color(0.85, 0.82, 0.76), "bauch_an": 0.35 if art == "esel" else 0.0, "rauh": 0.95, "spiegel": 0.15,
				"schritt": 0.38 if art != "katze" else 0.5, "hub": 0.05 if art == "esel" else 0.035, "kopf_piv": _hals_fuss(art)}
	for k in p:
		m.set_shader_parameter(k, p[k])
	_stoff[art] = m
	return m

# Schatten der fliegenden Vögel: derselbe Shader, flach auf den Boden gelegt, durchscheinend dunkel
static var _schatten: ShaderMaterial
static func schatten_stoff() -> ShaderMaterial:
	if _schatten:
		return _schatten
	if _shader == null:
		_shader = load("res://scripts/tiere.gdshader")
	var sh := Shader.new()
	sh.code = _shader.code.replace("render_mode cull_back, depth_draw_opaque;", "render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;\n#define SCHATTEN")
	_schatten = ShaderMaterial.new()
	_schatten.shader = sh
	_schatten.set_shader_parameter("art", 4)
	return _schatten

# ---------------------------------------------------------------- Netze
static func netz(art: String) -> ArrayMesh:
	if _netz.has(art):
		return _netz[art]
	var m: ArrayMesh
	match art:
		"eidechse":
			m = _eidechse()
		"kaefer":
			m = _kaefer(false)
		"schwarzkaefer":
			m = _kaefer(true)
		"kugel":
			m = _kugel()
		"falke_flug":
			m = _falke_flug()
		"falke_sitz":
			m = _falke_sitz()
		"maus":
			m = _maus()
		"ibis_steh":
			m = _ibis_steh()
		"ibis_flug":
			m = _ibis_flug()
		"fisch":
			m = _fisch()
		"fledermaus":
			m = _fledermaus()
		"esel", "schaf", "ziege", "katze":
			m = _vierbeiner(art)
	_netz[art] = m
	return m

static func dreiecke(art: String) -> int:
	var m := netz(art)
	var n := 0
	for i in m.get_surface_count():
		var a := m.surface_get_arrays(i)
		n += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n

# Dornschwanzagame (Uromastyx aegyptia), die große Agame der ägyptischen Wüste: breiter, flacher Leib, kurzer runder
# Kopf, kräftige gespreizte Beine mit Krallen, ein dicker Schwanz mit Ringen aus Dornen. Liegt flach am Boden, hebt
# zum Sonnen die Brust (Liegestütz) und flieht in Mauerritzen.
const EID_LEIB := [
	# z, halbe Breite, halbe Höhe, Mitte über dem Boden
	[0.125, 0.03, 0.022, 0.032], [0.1, 0.045, 0.03, 0.036], [0.065, 0.062, 0.036, 0.04], [0.025, 0.073, 0.04, 0.042],
	[-0.025, 0.076, 0.04, 0.042], [-0.075, 0.069, 0.036, 0.04], [-0.115, 0.055, 0.03, 0.036], [-0.145, 0.042, 0.025, 0.032],
]
static func _eidechse() -> ArrayMesh:
	var f := Former.new(FELD.eidechse, AABB(Vector3(-0.16, 0, -0.5), Vector3(0.32, 0.1, 0.72)))
	var hals := Vector3(0, 0.036, 0.115)
	# Kopf: kurz und rund, Schnauze stumpf
	var kz := [0.206, 0.201, 0.19, 0.17, 0.15, 0.13, 0.112]
	var kr := [Vector2(0.011, 0.008), Vector2(0.02, 0.015), Vector2(0.026, 0.019), Vector2(0.034, 0.024), Vector2(0.039, 0.027), Vector2(0.04, 0.027), Vector2(0.035, 0.025)]
	var ky := [0.03, 0.031, 0.033, 0.036, 0.038, 0.038, 0.037]
	var kw := []
	for i in kz.size():
		kw.append(Vector3(0, ky[i], kz[i]))
	f.roehre(kw, kr, KOPF, 0.0, hals, 10, [true, false])
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.028, 0.05, 0.165), Vector3(0.0075, 0.007, 0.0085), KOPF, hals, 6, 4, AUGE)
	# Leib, danach der Schwanz mit Dornenringen (Wülste: Ringe abwechselnd dicker und dünner)
	var lw := []
	var lrr := []
	var lt := []
	for r in EID_LEIB:
		lw.append(Vector3(0, r[3], r[0]))
		lrr.append(Vector2(r[1], r[2]))
		lt.append(LEIB)
	var z := -0.165
	var i := 0
	while z > -0.49:
		var t := (-0.145 - z) / 0.345         # 0 Ansatz … 1 Spitze
		var r0 := lerpf(0.04, 0.004, pow(t, 0.9))
		var wulst := 1.18 if i % 2 == 0 else 0.92
		lw.append(Vector3(0, lerpf(0.03, 0.01, t), z))
		lrr.append(Vector2(r0 * wulst, r0 * 0.62 * wulst))
		lt.append(SCHWANZ)
		z -= 0.0215
		i += 1
	lw.append(Vector3(0, 0.008, -0.5))
	lrr.append(Vector2(0.002, 0.002))
	lt.append(SCHWANZ)
	f.roehre(lw, lrr, lt, 0.0, Vector3.ZERO, 10, [false, true])
	# Beine: kräftig, Oberarm nach außen, Unterarm nach unten, Fuß mit drei Krallenzehen
	var beine := [
		[1, Vector3(0.05, 0.03, 0.06), Vector3(0.1, 0.04, 0.072), Vector3(0.118, 0.006, 0.092), 1.0, 0.016],
		[2, Vector3(-0.05, 0.03, 0.06), Vector3(-0.1, 0.04, 0.072), Vector3(-0.118, 0.006, 0.092), 1.0, 0.016],
		[3, Vector3(0.048, 0.03, -0.1), Vector3(0.105, 0.042, -0.085), Vector3(0.128, 0.006, -0.125), -1.0, 0.019],
		[4, Vector3(-0.048, 0.03, -0.1), Vector3(-0.105, 0.042, -0.085), Vector3(-0.128, 0.006, -0.125), -1.0, 0.019],
	]
	for b in beine:
		var teil: int = b[0]
		var sch: Vector3 = b[1]
		var ell: Vector3 = b[2]
		var fu: Vector3 = b[3]
		var vor: float = b[4]
		var d: float = b[5]
		f.roehre([sch, ell], [Vector2(d * 1.2, d), Vector2(d * 0.8, d * 0.75)], teil, [0.0, 0.45], sch, 6, [false, true], sch)
		f.roehre([ell, fu], [Vector2(d * 0.8, d * 0.75), Vector2(d * 0.6, d * 0.42)], teil, [0.45, 0.8], sch, 6, [false, false], sch)
		var sx := signf(sch.x)
		for k in 3:
			var w := -0.55 + 0.55 * k
			var richt := Vector3(sx * sin(0.55 + w), 0, cos(0.55 + w)) if vor > 0 else Vector3(sx * sin(1.0 + w), 0, -cos(1.0 + w))
			var spitze := fu + richt * (0.024 if vor > 0 else 0.03)
			spitze.y = 0.002
			f.roehre([fu, spitze], [Vector2(d * 0.42, d * 0.3), Vector2(0.0015, 0.0015)], teil, [0.85, 1.0], sch, 3, [false, true], HORN)
	return f.fertig()

# Skarabäus (Scarabaeus sacer): Kopfschild wie ein Halbrund mit sechs Zacken (die Strahlen der Sonne), breiter
# Halsschild, gewölbte Flügeldecken; vorn kräftige Grabbeine, hinten lange Schiebebeine. Schwarzkäfer (Pimelia):
# kleiner Kopf, kugelig gewölbte matte Decken, lange dünne Beine. Beide schreiten im Dreifuß.
static func _kaefer(schwarz: bool) -> ArrayMesh:
	var f := Former.new(FELD.schwarzkaefer if schwarz else FELD.kaefer, AABB(Vector3(-0.1, 0, -0.11), Vector3(0.2, 0.08, 0.22)))
	var hoch := 0.012 if not schwarz else 0.02     # Bauch über dem Boden
	if schwarz:
		f.kuppel(Vector3(0, hoch, 0.058), func(p): return 0.017 if cos(p) > -0.2 else 0.012, 0.01, 0.006, KOPF, 12, 2, Vector3(0, hoch, 0.045))
		f.kuppel(Vector3(0, hoch + 0.002, 0.032), func(p): return _ellipse(p, 0.03, 0.02), 0.018, 0.008, LEIB, 16, 3)
		f.kuppel(Vector3(0, hoch, -0.03), func(p): return _ellipse(p, 0.046, 0.058), 0.045, 0.01, LEIB, 20, 5)
	else:
		# Kopfschild: vorn sechs Zacken
		var zacken := func(p: float) -> float:
			var r := 0.031
			var w := wrapf(p, -PI, PI)
			if absf(w) < 1.35:
				r *= 1.0 + 0.2 * pow(maxf(0.0, cos(w * 6.0 * 1.0)), 6.0) * (1.0 - absf(w) / 1.6)
			elif absf(w) > 1.9:
				r = 0.02
			return r
		f.kuppel(Vector3(0, hoch + 0.004, 0.062), zacken, 0.009, 0.004, KOPF, 36, 2, Vector3(0, hoch, 0.05))
		var hals := func(p: float) -> float:
			var r := _ellipse(p, 0.05, 0.03)
			var w := absf(wrapf(p, -PI, PI))
			if w < 0.75:
				r *= 0.72 + 0.28 * (w / 0.75)
			return r
		f.kuppel(Vector3(0, hoch + 0.003, 0.026), hals, 0.024, 0.01, LEIB, 20, 3)
		f.kuppel(Vector3(0, hoch + 0.002, -0.034), func(p): return _ellipse(p, 0.045, 0.056) * (1.0 - 0.06 * maxf(0.0, -cos(p))), 0.03, 0.01, LEIB, 20, 4)
	# Beine: Hüfte, Schenkel, Schiene (vorn breit mit Zähnen), Fuß
	var beine := [
		[1, Vector3(0.022, hoch, 0.04), Vector3(0.05, hoch + 0.004, 0.058), Vector3(0.068, 0.002, 0.092)],
		[3, Vector3(0.026, hoch, 0.0), Vector3(0.066, hoch + 0.012, -0.004), Vector3(0.09, 0.002, -0.03)],
		[5, Vector3(0.022, hoch, -0.024), Vector3(0.062, hoch + 0.014, -0.046), Vector3(0.078, 0.002, -0.1)],
	]
	if schwarz:
		beine = [
			[1, Vector3(0.018, hoch, 0.036), Vector3(0.055, hoch + 0.012, 0.05), Vector3(0.072, 0.002, 0.085)],
			[3, Vector3(0.022, hoch, 0.0), Vector3(0.07, hoch + 0.016, -0.004), Vector3(0.095, 0.002, -0.03)],
			[5, Vector3(0.02, hoch, -0.026), Vector3(0.065, hoch + 0.018, -0.05), Vector3(0.085, 0.002, -0.11)],
		]
	for b in beine:
		for sx in [1.0, -1.0]:
			var teil: int = b[0] + (0 if sx > 0 else 1)
			var h: Vector3 = b[1] * Vector3(sx, 1, 1)
			var k: Vector3 = b[2] * Vector3(sx, 1, 1)
			var fu: Vector3 = b[3] * Vector3(sx, 1, 1)
			var dick := 0.0065 if b[0] == 1 and not schwarz else 0.0045
			f.roehre([h, k], [Vector2(0.006, 0.005), Vector2(0.005, 0.004)], teil, [0.0, 0.4], h, 4, [false, true], SCHWARZ)
			f.roehre([k, fu], [Vector2(dick, 0.003), Vector2(dick * 0.6, 0.002)], teil, [0.4, 0.95], h, 4, [true, true], HORN if schwarz else SCHWARZ)
	# Fühler mit Keule
	for sx in [1.0, -1.0]:
		var a := Vector3(sx * 0.012, hoch + 0.004, 0.07)
		var e := Vector3(sx * 0.026, hoch + 0.008, 0.085)
		f.roehre([a, e], [Vector2(0.0018, 0.0018), Vector2(0.004, 0.004)], FUEHLER, [0.0, 1.0], a, 3, [false, true], HORN)
	return f.fertig()

static func _ellipse(p: float, a: float, b: float) -> float:
	var s := sin(p)
	var c := cos(p)
	return 1.0 / sqrt(s * s / (a * a) + c * c / (b * b))

# die Mistkugel des Skarabäus: rund, aber nicht glatt
static func _kugel() -> ArrayMesh:
	var f := Former.new(FELD.kugel, AABB(Vector3(-0.06, -0.06, -0.06), Vector3(0.12, 0.12, 0.12)))
	f.kugel(Vector3.ZERO, Vector3(0.045, 0.045, 0.045), LEIB, Vector3.ZERO, 10, 7)
	return f.fertig()

# Wanderfalke/Lannerfalke, der Vogel des Horus. Im Flug: kompakter Leib, lange spitze, nach hinten gezogene Flügel,
# schmaler Schwanz. Flügel und Schwanz sind dünne Häute mit Ober- und Unterseite; die Unterseite färbt der Shader hell.
static func _falke_flug() -> ArrayMesh:
	var f := Former.new(FELD.falke_flug, AABB(Vector3(-0.52, -0.05, -0.31), Vector3(1.04, 0.1, 0.52)))
	var kopf := Vector3(0, 0.0, 0.12)
	var ringe := [
		# z, halbe Breite, halbe Höhe, y
		[0.198, 0.006, 0.006, -0.002], [0.188, 0.016, 0.016, 0.0], [0.168, 0.03, 0.03, 0.004], [0.142, 0.035, 0.034, 0.004],
		[0.115, 0.036, 0.036, 0.0], [0.075, 0.054, 0.05, -0.006], [0.025, 0.058, 0.052, -0.006], [-0.035, 0.048, 0.042, -0.002],
		[-0.085, 0.032, 0.026, 0.004], [-0.115, 0.018, 0.012, 0.006],
	]
	var weg := []
	var rr := []
	var tt := []
	for r in ringe:
		weg.append(Vector3(0, r[3], r[0]))
		rr.append(Vector2(r[1], r[2]))
		tt.append(KOPF if r[0] > 0.12 else LEIB)
	f.roehre(weg, rr, tt, 0.0, kopf, 10, [true, true])
	# Hakenschnabel: gelbe Wachshaut, dunkle Spitze
	f.roehre([Vector3(0, 0.0, 0.19), Vector3(0, -0.006, 0.206), Vector3(0, -0.016, 0.208)], [Vector2(0.009, 0.008), Vector2(0.005, 0.005), Vector2(0.001, 0.001)], KOPF, 0.0, kopf, 5, [false, true], SCHWARZ)
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.024, 0.012, 0.165), Vector3(0.008, 0.008, 0.008), KOPF, kopf, 6, 4, AUGE)
	# Schwanz: schmal, am Ende gerade
	f.haut([[Vector3(0.024, 0.006, -0.1), Vector3(-0.024, 0.006, -0.1)], [Vector3(0.038, 0.006, -0.19), Vector3(-0.038, 0.006, -0.19)],
		[Vector3(0.05, 0.004, -0.27), Vector3(-0.05, 0.004, -0.27)]], SCHWANZ, Vector3(0, 0.006, -0.1), 0.006)
	# Flügel: Vorderkante bis zum Handgelenk vorgewölbt, dann spitz nach hinten; Hinterkante mit Federspitzen
	for sx in [1.0, -1.0]:
		f.haut(_fluegel(sx, 0.52, 0.035, func(t): return _falke_vorn(t), func(t): return _falke_hinten(t), 13, 0.016), FLUEGEL, Vector3(sx * 0.04, 0.016, 0.0), 0.012)
	return f.fertig()

static func _falke_vorn(t: float) -> float:
	return lerpf(0.07, 0.1, t / 0.42) if t < 0.42 else lerpf(0.1, -0.072, pow((t - 0.42) / 0.58, 1.35))

static func _falke_hinten(t: float) -> float:
	return lerpf(-0.07, -0.088, minf(t / 0.6, 1.0)) if t < 0.85 else lerpf(-0.092, -0.078, (t - 0.85) / 0.15)

# Flügel als Streifen für Former.haut: von der Schulter (x0) bis zur Spitze (x1), Vorder- und Hinterkante als Funktion
# der Spannweite t (0 … 1). Hinterkante mit Federspitzen (jede zweite Station ein Stück weiter hinten).
static func _fluegel(sx: float, x1: float, x0: float, vorn: Callable, hinten: Callable, n: int, y0: float, zacke := 0.007) -> Array:
	var st := []
	for i in n:
		var t := float(i) / (n - 1)
		var x := lerpf(x0, x1, t)
		var y := y0 * (1.0 - t)
		var hz: float = hinten.call(t)
		if i % 2 == 1 and t > 0.15 and t < 0.97:
			hz -= zacke
		st.append([Vector3(sx * x, y, vorn.call(t)), Vector3(sx * x, y - 0.004 * (1.0 - t), hz)])
	return st

# Falke sitzend: aufrecht, Flügel angelegt, Schwanz hängt; Kopf mit dunkler Kappe und „Bart“ (dem Horusauge).
static func _falke_sitz() -> ArrayMesh:
	var feld: Rect2 = FELD.falke_sitz
	var f := Former.new(Rect2(feld.position, Vector2(feld.size.x * 0.5, feld.size.y)), AABB(Vector3(-0.1, 0, -0.18), Vector3(0.2, 0.48, 0.28)), true)
	var nacken := Vector3(0, 0.345, 0.01)
	# Leib: vom Bürzel schräg hinauf zur Brust und zum Nacken
	f.roehre([Vector3(0, 0.06, -0.055), Vector3(0, 0.12, -0.02), Vector3(0, 0.21, 0.02), Vector3(0, 0.29, 0.024), Vector3(0, 0.34, 0.014)],
		[Vector2(0.032, 0.03), Vector2(0.06, 0.054), Vector2(0.07, 0.066), Vector2(0.06, 0.054), Vector2(0.04, 0.036)], LEIB, 0.0, Vector3.ZERO, 10, [true, false])
	# Kopf: rund, groß
	f.roehre([Vector3(0, 0.33, 0.0), Vector3(0, 0.355, 0.01), Vector3(0, 0.385, 0.02), Vector3(0, 0.413, 0.022), Vector3(0, 0.43, 0.02)],
		[Vector2(0.038, 0.036), Vector2(0.044, 0.044), Vector2(0.045, 0.045), Vector2(0.036, 0.036), Vector2(0.012, 0.012)], KOPF, 0.0, nacken, 10, [false, true], null, Vector3.BACK)
	f.roehre([Vector3(0, 0.39, 0.06), Vector3(0, 0.385, 0.075), Vector3(0, 0.371, 0.078)], [Vector2(0.01, 0.009), Vector2(0.006, 0.006), Vector2(0.001, 0.001)], KOPF, 0.0, nacken, 5, [false, true], SCHWARZ)
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.029, 0.395, 0.045), Vector3(0.0095, 0.0095, 0.009), KOPF, nacken, 6, 4, AUGE)
	# Schwanz: hängt hinter den Füßen
	f.haut([[Vector3(0.026, 0.08, -0.06), Vector3(-0.026, 0.08, -0.06)], [Vector3(0.034, 0.03, -0.12), Vector3(-0.034, 0.03, -0.12)],
		[Vector3(0.038, -0.005, -0.17), Vector3(-0.038, -0.005, -0.17)]], SCHWANZ, Vector3(0, 0.08, -0.06), 0.006, true, Vector3(0, 0.6, -0.8).normalized())
	# Beine: kurz, gelb, mit Zehen
	for sx in [1.0, -1.0]:
		var h := Vector3(sx * 0.024, 0.07, 0.0)
		var fu := Vector3(sx * 0.026, 0.01, 0.02)
		f.roehre([h, fu], [Vector2(0.01, 0.01), Vector2(0.006, 0.006)], 1 if sx > 0 else 2, [0.3, 0.9], h, 5, [false, false], GELB)
		for w in [-0.5, 0.0, 0.5]:
			f.roehre([fu, fu + Vector3(sin(w) * 0.03, -0.01, cos(w) * 0.03)], [Vector2(0.004, 0.004), Vector2(0.0015, 0.0015)], 1 if sx > 0 else 2, [0.9, 1.0], h, 3, [false, true], GELB)
	# angelegte Flügel: breite flache Wülste an den Seiten, Spitzen kreuzen über dem Schwanz (eigenes Feld)
	f.feld = Rect2(feld.position + Vector2(feld.size.x * 0.5, 0), Vector2(feld.size.x * 0.5, feld.size.y))
	for sx in [1.0, -1.0]:
		f.roehre([Vector3(sx * 0.047, 0.315, 0.02), Vector3(sx * 0.062, 0.24, 0.0), Vector3(sx * 0.054, 0.15, -0.045), Vector3(sx * 0.032, 0.07, -0.095), Vector3(sx * 0.008, 0.02, -0.13)],
			[Vector2(0.02, 0.045), Vector2(0.024, 0.05), Vector2(0.02, 0.042), Vector2(0.013, 0.028), Vector2(0.003, 0.008)], LEIB, 0.0, Vector3.ZERO, 8, [true, true], null, Vector3.LEFT if sx > 0 else Vector3.RIGHT)
	return f.fertig()

# Wüstenrennmaus (Gerbil): Eikörper, großer Kopf mit dunklen Knopfaugen, runde Ohren, lange Hinterfüße, langer Schwanz
# mit Quaste. Hüpft, richtet sich auf, putzt sich.
static func _maus() -> ArrayMesh:
	var f := Former.new(FELD.maus, AABB(Vector3(-0.06, 0, -0.21), Vector3(0.12, 0.08, 0.3)))
	var nacken := Vector3(0, 0.033, 0.03)
	var ringe := [
		[0.088, 0.004, 0.004, 0.024], [0.079, 0.011, 0.01, 0.026], [0.063, 0.019, 0.018, 0.029], [0.045, 0.024, 0.023, 0.032],
		[0.028, 0.026, 0.025, 0.034], [0.005, 0.033, 0.032, 0.036], [-0.025, 0.039, 0.036, 0.037], [-0.052, 0.037, 0.034, 0.034],
		[-0.072, 0.028, 0.026, 0.03], [-0.084, 0.013, 0.013, 0.027],
	]
	var weg := []
	var rr := []
	var tt := []
	for r in ringe:
		weg.append(Vector3(0, r[3], r[0]))
		rr.append(Vector2(r[1], r[2]))
		tt.append(KOPF if r[0] > 0.035 else LEIB)
	f.roehre(weg, rr, tt, 0.0, nacken, 10, [true, true])
	f.kugel(Vector3(0, 0.026, 0.09), Vector3(0.004, 0.0035, 0.003), KOPF, nacken, 5, 3, ROSA)
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.016, 0.039, 0.06), Vector3(0.0065, 0.0065, 0.0065), KOPF, nacken, 6, 4, AUGE)
		# Ohren: rund, innen rosa
		var ob := Vector3(sx * 0.014, 0.052, 0.04)
		f.haut([[ob + Vector3(0, 0, 0.007), ob + Vector3(0, 0, -0.007)], [ob + Vector3(sx * 0.005, 0.012, 0.009), ob + Vector3(sx * 0.005, 0.012, -0.007)],
			[ob + Vector3(sx * 0.008, 0.02, 0.002), ob + Vector3(sx * 0.008, 0.02, -0.002)]], FUEHLER, ob, 0.002, true, Vector3(0, 0, 1))
		# Vorderpfoten
		var vs := Vector3(sx * 0.014, 0.022, 0.03)
		f.roehre([vs, Vector3(sx * 0.016, 0.003, 0.042)], [Vector2(0.005, 0.005), Vector2(0.003, 0.003)], 1 if sx > 0 else 2, [0.2, 1.0], vs, 4, [false, true], ROSA)
		# Hinterbeine: Schenkel im Leib, lange Füße nach vorn
		var hs := Vector3(sx * 0.025, 0.022, -0.05)
		f.roehre([hs, Vector3(sx * 0.027, 0.006, -0.06), Vector3(sx * 0.026, 0.003, -0.02)], [Vector2(0.01, 0.01), Vector2(0.005, 0.004), Vector2(0.003, 0.002)], 3 if sx > 0 else 4, [0.0, 0.5, 1.0], hs, 4, [false, true])
	# Schwanz mit dunkler Quaste
	var sw := []
	var sr := []
	var sg := []
	for i in 7:
		var t := i / 6.0
		sw.append(Vector3(0, lerpf(0.028, 0.008, t) + 0.01 * sin(t * PI), lerpf(-0.08, -0.205, t)))
		sr.append(Vector2.ONE * (lerpf(0.005, 0.0025, t) + (0.004 if t > 0.75 else 0.0)))
		sg.append(t)
	f.roehre(sw, sr, SCHWANZ, sg, Vector3(0, 0.028, -0.08), 4, [false, true])
	return f.fertig()

# Heiliger Ibis, der Vogel des Thot: weißer Leib, nackter schwarzer Hals und Kopf, langer gebogener Schnabel,
# schwarze Schmuckfedern über dem Schwanz, lange schwarze Beine. Schreitet am Wasser und stochert im Schlamm.
static func _ibis_steh() -> ArrayMesh:
	var f := Former.new(FELD.ibis_steh, AABB(Vector3(-0.1, 0, -0.27), Vector3(0.2, 0.64, 0.6)), true)
	var halsfuss := Vector3(0, 0.38, 0.1)
	f.roehre([Vector3(0, 0.33, -0.17), Vector3(0, 0.33, -0.12), Vector3(0, 0.35, -0.03), Vector3(0, 0.37, 0.05), Vector3(0, 0.385, 0.1)],
		[Vector2(0.025, 0.022), Vector2(0.062, 0.056), Vector2(0.078, 0.072), Vector2(0.066, 0.064), Vector2(0.042, 0.042)], LEIB, 0.0, Vector3.ZERO, 10, [true, false])
	# Hals: S-Bogen nach oben, Kopf klein, Schnabel lang und nach unten gebogen
	var hw := [halsfuss, Vector3(0, 0.43, 0.13), Vector3(0, 0.48, 0.125), Vector3(0, 0.53, 0.115), Vector3(0, 0.565, 0.13)]
	f.roehre(hw, [Vector2(0.03, 0.03), Vector2(0.021, 0.021), Vector2(0.018, 0.018), Vector2(0.018, 0.018), Vector2(0.02, 0.02)], HALS, [0.0, 0.3, 0.6, 0.85, 1.0], halsfuss, 6, [false, false])
	f.roehre([Vector3(0, 0.565, 0.115), Vector3(0, 0.578, 0.14), Vector3(0, 0.575, 0.165)], [Vector2(0.018, 0.018), Vector2(0.024, 0.024), Vector2(0.014, 0.013)], KOPF, 1.0, halsfuss, 8, [true, false])
	f.roehre([Vector3(0, 0.573, 0.163), Vector3(0, 0.566, 0.21), Vector3(0, 0.548, 0.255), Vector3(0, 0.52, 0.29), Vector3(0, 0.49, 0.305)],
		[Vector2(0.009, 0.01), Vector2(0.007, 0.007), Vector2(0.0055, 0.0055), Vector2(0.004, 0.004), Vector2(0.0015, 0.0015)], KOPF, 1.0, halsfuss, 5, [false, true], SCHWARZ)
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.016, 0.582, 0.15), Vector3(0.0045, 0.0045, 0.0045), KOPF, halsfuss, 5, 3, AUGE)
	# Schmuckfedern: schwarz, hängen über den Schwanz
	f.haut([[Vector3(0.05, 0.37, -0.08), Vector3(-0.05, 0.37, -0.08)], [Vector3(0.058, 0.33, -0.18), Vector3(-0.058, 0.33, -0.18)],
		[Vector3(0.04, 0.27, -0.25), Vector3(-0.04, 0.27, -0.25)]], SCHWANZ, Vector3(0, 0.36, -0.08), 0.01, true, Vector3(0, 0.9, -0.4).normalized())
	# Beine
	for sx in [1.0, -1.0]:
		var h := Vector3(sx * 0.03, 0.31, -0.01)
		var k := Vector3(sx * 0.03, 0.17, -0.03)
		var fu := Vector3(sx * 0.03, 0.012, 0.0)
		var teil := 1 if sx > 0 else 2
		f.roehre([h, k, fu], [Vector2(0.011, 0.011), Vector2(0.007, 0.007), Vector2(0.006, 0.006)], teil, [0.0, 0.5, 0.95], h, 5, [false, false], SCHWARZ)
		for w in [-0.6, 0.0, 0.6, PI]:
			var l := 0.05 if w != PI else 0.025
			f.roehre([fu, fu + Vector3(sin(w) * l, -0.01, cos(w) * l)], [Vector2(0.004, 0.003), Vector2(0.0015, 0.0015)], teil, [0.95, 1.0], h, 3, [false, true], SCHWARZ)
	return f.fertig()

static func _ibis_flug() -> ArrayMesh:
	var f := Former.new(FELD.ibis_flug, AABB(Vector3(-0.56, -0.05, -0.36), Vector3(1.12, 0.1, 0.86)))
	var kopf := Vector3(0, 0, 0.12)
	f.roehre([Vector3(0, 0.005, -0.17), Vector3(0, 0.0, -0.12), Vector3(0, -0.005, -0.03), Vector3(0, -0.004, 0.05), Vector3(0, 0.0, 0.1)],
		[Vector2(0.022, 0.02), Vector2(0.055, 0.05), Vector2(0.07, 0.062), Vector2(0.058, 0.052), Vector2(0.032, 0.03)], LEIB, 0.0, Vector3.ZERO, 10, [true, false])
	f.roehre([Vector3(0, 0.0, 0.1), Vector3(0, 0.004, 0.2), Vector3(0, 0.006, 0.3), Vector3(0, 0.008, 0.33)], [Vector2(0.024, 0.024), Vector2(0.017, 0.017), Vector2(0.019, 0.019), Vector2(0.012, 0.012)], KOPF, 0.0, kopf, 6, [false, false])
	f.roehre([Vector3(0, 0.006, 0.33), Vector3(0, 0.0, 0.38), Vector3(0, -0.018, 0.43), Vector3(0, -0.045, 0.46)], [Vector2(0.008, 0.008), Vector2(0.006, 0.006), Vector2(0.004, 0.004), Vector2(0.0015, 0.0015)], KOPF, 0.0, kopf, 5, [false, true], SCHWARZ)
	# Beine nach hinten gestreckt
	for sx in [1.0, -1.0]:
		f.roehre([Vector3(sx * 0.02, -0.02, -0.1), Vector3(sx * 0.022, -0.03, -0.25), Vector3(sx * 0.024, -0.034, -0.35)], [Vector2(0.008, 0.008), Vector2(0.005, 0.005), Vector2(0.004, 0.004)], SCHWANZ, 0.0, Vector3(0, 0, -0.1), 4, [false, true], SCHWARZ)
	f.haut([[Vector3(0.03, 0.006, -0.14), Vector3(-0.03, 0.006, -0.14)], [Vector3(0.05, 0.004, -0.22), Vector3(-0.05, 0.004, -0.22)]], SCHWANZ, Vector3(0, 0.006, -0.12), 0.006)
	# Flügel: breit und rund, gefingerte schwarze Spitzen
	for sx in [1.0, -1.0]:
		f.haut(_fluegel(sx, 0.56, 0.04, func(t): return _ibis_vorn(t), func(t): return _ibis_hinten(t), 13, 0.012, 0.014), FLUEGEL, Vector3(sx * 0.04, 0.012, 0.0), 0.01)
	return f.fertig()

static func _ibis_vorn(t: float) -> float:
	return lerpf(0.07, 0.095, t / 0.4) if t < 0.4 else lerpf(0.095, 0.0, pow((t - 0.4) / 0.6, 1.6))

static func _ibis_hinten(t: float) -> float:
	return lerpf(-0.09, -0.125, minf(t / 0.55, 1.0)) if t < 0.8 else lerpf(-0.125, -0.05, (t - 0.8) / 0.2)

# Buntbarsch des Nils (Tilapia): hochrückig, seitlich flach, stachlige Rückenflosse, Schwanzflosse gerade.
static func _fisch() -> ArrayMesh:
	var f := Former.new(FELD.fisch, AABB(Vector3(-0.03, -0.08, -0.15), Vector3(0.06, 0.16, 0.27)), true)
	var ringe := [[0.118, 0.004, 0.006, -0.004], [0.106, 0.011, 0.02, 0.0], [0.08, 0.018, 0.04, 0.004], [0.04, 0.022, 0.052, 0.006],
		[0.0, 0.021, 0.052, 0.004], [-0.04, 0.016, 0.04, 0.002], [-0.07, 0.009, 0.022, 0.0], [-0.09, 0.005, 0.013, 0.0]]
	var weg := []
	var rr := []
	for r in ringe:
		weg.append(Vector3(0, r[3], r[0]))
		rr.append(Vector2(r[1], r[2]))
	f.roehre(weg, rr, LEIB, 0.0, Vector3.ZERO, 8, [true, true])
	for sx in [-1.0, 1.0]:
		f.kugel(Vector3(sx * 0.012, 0.012, 0.088), Vector3(0.004, 0.0055, 0.0055), LEIB, Vector3.ZERO, 5, 3, AUGE)
		var b := Vector3(sx * 0.016, -0.01, 0.06)
		f.haut([[b, b + Vector3(0, 0.0, -0.012)], [b + Vector3(sx * 0.02, -0.01, -0.01), b + Vector3(sx * 0.02, -0.012, -0.03)]], FLOSSE, b, 0.001, true, Vector3(0, 1, 0))
	# Schwanzflosse und Rückenflosse (senkrecht)
	f.haut([[Vector3(0, 0.012, -0.088), Vector3(0, -0.012, -0.088)], [Vector3(0, 0.032, -0.14), Vector3(0, -0.032, -0.14)]], LEIB, Vector3.ZERO, 0.001, true, Vector3.RIGHT)
	f.haut([[Vector3(0, 0.05, 0.06), Vector3(0, 0.05, 0.06)], [Vector3(0, 0.074, 0.02), Vector3(0, 0.054, 0.02)], [Vector3(0, 0.07, -0.04), Vector3(0, 0.042, -0.04)], [Vector3(0, 0.04, -0.085), Vector3(0, 0.014, -0.085)]], LEIB, Vector3.ZERO, 0.001, true, Vector3.RIGHT)
	f.haut([[Vector3(0, -0.045, 0.0), Vector3(0, -0.045, 0.0)], [Vector3(0, -0.06, -0.04), Vector3(0, -0.04, -0.04)], [Vector3(0, -0.026, -0.08), Vector3(0, -0.012, -0.08)]], LEIB, Vector3.ZERO, 0.001, true, Vector3.RIGHT)
	return f.fertig()

# Grabfledermaus (Taphozous): kleiner Leib, große Ohren, Flughaut zwischen langen Fingern
static func _fledermaus() -> ArrayMesh:
	var f := Former.new(FELD.fledermaus, AABB(Vector3(-0.2, -0.03, -0.08), Vector3(0.4, 0.06, 0.16)))
	f.roehre([Vector3(0, 0, -0.05), Vector3(0, 0.002, -0.02), Vector3(0, 0.004, 0.015), Vector3(0, 0.005, 0.035), Vector3(0, 0.003, 0.05)],
		[Vector2(0.008, 0.008), Vector2(0.018, 0.016), Vector2(0.02, 0.018), Vector2(0.016, 0.015), Vector2(0.006, 0.006)], LEIB, 0.0, Vector3.ZERO, 8, [true, true])
	for sx in [-1.0, 1.0]:
		var ob := Vector3(sx * 0.008, 0.014, 0.035)
		f.haut([[ob, ob + Vector3(0, 0, -0.01)], [ob + Vector3(sx * 0.008, 0.02, 0.0), ob + Vector3(sx * 0.008, 0.02, -0.004)]], FUEHLER, ob, 0.001, true, Vector3(0, 0, 1))
		f.haut(_fluegel(sx, 0.19, 0.012, func(t): return _fm_vorn(t), func(t): return _fm_hinten(t), 11, 0.004, 0.016), FLUEGEL, Vector3(sx * 0.012, 0.004, 0.01), 0.002)
	return f.fertig()

static func _fm_vorn(t: float) -> float:
	return lerpf(0.02, 0.032, t / 0.35) if t < 0.35 else lerpf(0.032, -0.03, (t - 0.35) / 0.65)

static func _fm_hinten(t: float) -> float:
	return -0.045 - 0.02 * sin(t * PI) + 0.012 * absf(sin(t * PI * 3.0))

# Vierbeiner der Höfe und Aufträge: Esel, Schaf, Ziege, Katze aus einem Bauplan.
# Maße: Rumpf (Länge, Breite, Höhe), Beinlänge, Hals und Kopf, Ohren, Schwanz, Hörner.
const VIER := {
	"esel": {"rumpf": [0.44, 0.2, 0.23], "bein": 0.58, "dick": 0.055, "hals": [0.38, 0.14, 0.5], "kopf": [0.38, 0.09, 0.12], "ohr": [0.2, 0.04], "schwanz": [0.42, 0.018, true], "feld": "esel", "maul": 0.06},
	"schaf": {"rumpf": [0.36, 0.22, 0.22], "bein": 0.42, "dick": 0.034, "hals": [0.24, 0.1, 0.32], "kopf": [0.24, 0.06, 0.075], "ohr": [0.09, 0.03], "schwanz": [0.2, 0.05, false], "feld": "schaf", "horn": "schnecke", "maul": 0.04},
	"ziege": {"rumpf": [0.33, 0.15, 0.17], "bein": 0.46, "dick": 0.03, "hals": [0.26, 0.08, 0.4], "kopf": [0.24, 0.055, 0.07], "ohr": [0.13, 0.03], "schwanz": [0.09, 0.02, false], "feld": "ziege", "horn": "saebel", "bart": true, "maul": 0.035},
	"katze": {"rumpf": [0.22, 0.08, 0.09], "bein": 0.24, "dick": 0.024, "hals": [0.1, 0.05, 0.3], "kopf": [0.11, 0.065, 0.058], "ohr": [0.075, 0.03], "schwanz": [0.34, 0.016, false], "feld": "katze", "katze": true, "maul": 0.02},
}
static func _hals_fuss(art: String) -> Vector3:
	var V: Dictionary = VIER[art]
	var y0: float = V.bein + V.rumpf[2] * 0.55
	return Vector3(0, y0 + V.rumpf[2] * 0.35, V.rumpf[0] * 0.85)

static func _vierbeiner(art: String) -> ArrayMesh:
	var V: Dictionary = VIER[art]
	var rl: float = V.rumpf[0]
	var rb: float = V.rumpf[1]
	var rh: float = V.rumpf[2]
	var bl: float = V.bein
	var y0 := bl + rh * 0.55                     # Mitte des Rumpfes über dem Boden
	var hl: float = V.hals[0]
	var hd: float = V.hals[1]
	var hz := rl * 0.85                          # Halsansatz vorn am Rumpf
	var lang := rl + hl * 0.8 + float(V.kopf[0])
	var schw_l: float = V.schwanz[0]
	var f := Former.new(FELD[V.feld], AABB(Vector3(-0.3, 0, -rl - schw_l * 0.9), Vector3(0.6, y0 + rh + hl * 1.3, lang + rl + schw_l * 0.9)), true)
	var wollig := art == "schaf"
	# Rumpf: Schulter und Kruppe etwas höher, Bauch rund
	var rz := [-rl * 1.02, -rl * 0.9, -rl * 0.5, 0.0, rl * 0.45, rl * 0.82, rl * 1.0]
	var rs := [0.25, 0.72, 0.95, 1.0, 0.97, 0.8, 0.45]
	var weg := []
	var rr := []
	for i in rz.size():
		var w: float = rs[i] * (1.06 if wollig and i % 2 == 1 else 1.0)
		weg.append(Vector3(0, y0 + (0.02 if i == 1 or i == 5 else 0.0), rz[i]))
		rr.append(Vector2(rb * w, rh * w))
	f.roehre(weg, rr, LEIB, 0.0, Vector3.ZERO, 14, [true, true])
	# Hals: schräg nach vorn oben; Kopf am Ende
	var hals_fuss := Vector3(0, y0 + rh * 0.35, hz)
	var hneig: float = V.hals[2]
	var hals_ende := hals_fuss + Vector3(0, sin(hneig + 0.55) * hl, cos(hneig + 0.55) * hl)
	f.roehre([hals_fuss, hals_fuss.lerp(hals_ende, 0.5), hals_ende], [Vector2(hd, hd * 1.2), Vector2(hd * 0.85, hd), Vector2(hd * 0.75, hd * 0.85)], HALS, [0.0, 0.5, 1.0], hals_fuss, 8, [false, false])
	var kl: float = V.kopf[0]
	var kb: float = V.kopf[1]
	var kh: float = V.kopf[2]
	var katze: bool = V.get("katze", false)
	var kr := Vector3(0, -sin(0.5), cos(0.5)) if not katze else Vector3(0, -0.15, 1).normalized()   # Blickrichtung (Nase leicht nach unten)
	var k0 := hals_ende + Vector3(0, kh * 0.4, -kb * 0.2)
	var kp := [k0, k0 + kr * kl * 0.3, k0 + kr * kl * 0.7, k0 + kr * kl]
	var ks := [Vector2(kb * 0.95, kh * 1.0), Vector2(kb, kh * 1.05), Vector2(kb * 0.7, kh * 0.8), Vector2(float(V.maul), float(V.maul) * 1.1)]
	if katze:
		ks = [Vector2(kb * 0.9, kh * 0.95), Vector2(kb, kh), Vector2(kb * 0.6, kh * 0.6), Vector2(0.012, 0.012)]
	f.roehre(kp, ks, KOPF, 1.0, hals_fuss, 10, [true, true])
	var auge_z := 0.32
	for sx in [-1.0, 1.0]:
		var ap: Vector3 = k0 + kr * kl * auge_z + Vector3(sx * kb * 0.88, kh * 0.45, 0)
		f.kugel(ap, Vector3.ONE * kb * (0.16 if not katze else 0.2), KOPF, hals_fuss, 6, 4, AUGE)
	# Ohren
	var ol: float = V.ohr[0]
	var ob: float = V.ohr[1]
	for sx in [-1.0, 1.0]:
		var o := k0 + Vector3(sx * kb * 0.6, kh * 0.85, 0)
		var aus := Vector3(sx * 0.55, 0.85, -0.2).normalized() if art != "ziege" else Vector3(sx * 0.9, -0.5, 0.1).normalized()
		if art == "schaf":
			aus = Vector3(sx * 1.0, 0.0, -0.1).normalized()
		f.haut([[o + Vector3(0, 0, ob), o + Vector3(0, 0, -ob)], [o + aus * ol * 0.5 + Vector3(0, 0, ob * 0.9), o + aus * ol * 0.5 + Vector3(0, 0, -ob * 0.9)], [o + aus * ol, o + aus * ol]],
			FUEHLER, o, 0.004, true, Vector3(0, 0, 1))
	# Hörner
	if V.has("horn"):
		for sx in [-1.0, 1.0]:
			var hb := k0 + Vector3(sx * kb * 0.45, kh * 0.95, kb * 0.2)
			var pts := []
			var rs2 := []
			if V.horn == "saebel":
				for i in 5:
					var t := i / 4.0
					pts.append(hb + Vector3(sx * 0.02 * t, 0.09 * t * (1.0 - 0.3 * t), -0.11 * t * t))
					rs2.append(Vector2.ONE * lerpf(0.014, 0.003, t))
			else:
				for i in 8:
					var t := i / 7.0
					var w := t * TAU * 0.85
					pts.append(hb + Vector3(sx * (0.012 + 0.04 * t), 0.035 * sin(w) + 0.01, -0.035 * (1.0 - cos(w)) + 0.01 * t))
					rs2.append(Vector2.ONE * lerpf(0.016, 0.005, t))
			f.roehre(pts, rs2, KOPF, 1.0, hals_fuss, 5, [false, true], HORN)
	if V.get("bart", false):
		var bb := k0 + kr * kl * 0.75 + Vector3(0, -kh * 0.7, 0)
		f.roehre([bb, bb + Vector3(0, -0.06, -0.01)], [Vector2(0.012, 0.008), Vector2(0.003, 0.003)], KOPF, 1.0, hals_fuss, 4, [false, true], SCHWARZ)
	# Schwanz
	var sl: float = V.schwanz[0]
	var sd: float = V.schwanz[1]
	var sf := Vector3(0, y0 + rh * 0.5, -rl * 0.98)
	var sw := []
	var sr := []
	var sgw := []
	for i in 5:
		var t := i / 4.0
		var p: Vector3
		if katze:
			p = sf + Vector3(0, sin(t * 1.3) * sl * 0.45, -sin(t * 1.0) * sl * 0.6 - 0.01)
		elif art == "ziege":
			p = sf + Vector3(0, sl * 0.8 * t, -sl * 0.5 * t)
		else:
			p = sf + Vector3(0, -sl * t * 0.95, -0.03 - 0.06 * t)
		sw.append(p)
		var r := sd * (1.0 - 0.4 * t)
		if V.schwanz[2] and t > 0.7:
			r = sd * 2.4      # Quaste
		sr.append(Vector2(r, r))
		sgw.append(t)
	f.roehre(sw, sr, SCHWANZ, sgw, sf, 5, [false, true])
	# Beine: oben im Rumpf, Knie, Huf (Katze: Pfote)
	var dick: float = V.dick
	var pos := [[1, 1.0, rl * 0.7], [2, -1.0, rl * 0.7], [3, 1.0, -rl * 0.72], [4, -1.0, -rl * 0.72]]
	for b in pos:
		var teil: int = b[0]
		var sx: float = b[1]
		var z: float = b[2]
		var vorn := teil <= 2
		var top := Vector3(sx * rb * 0.55, y0, z)
		var knie := Vector3(sx * rb * 0.55, bl * 0.48, z + (0.0 if vorn else -0.04 * bl / 0.5))
		var fuss := Vector3(sx * rb * 0.55, 0.0, z + (0.01 if vorn else 0.0))
		var o := dick * (1.7 if not vorn else 1.45)
		var huf := Vector2(dick * 0.85, dick * 0.7) if not katze else Vector2(dick * 0.9, dick * 0.6)
		f.roehre([top, top.lerp(knie, 0.5), knie, knie.lerp(fuss, 0.6), fuss + Vector3(0, 0.03, 0), fuss],
			[Vector2(o * 1.1, o), Vector2(o * 0.9, o * 0.9), Vector2(dick * 0.75, dick * 0.75), Vector2(dick * 0.6, dick * 0.6), huf, huf],
			teil, [0.0, 0.25, 0.5, 0.75, 0.95, 1.0], top, 6, [false, true])
	return f.fertig()
