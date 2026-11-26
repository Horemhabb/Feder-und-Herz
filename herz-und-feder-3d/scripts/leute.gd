class_name Leute extends RefCounted
# Leute des Dorfes und der Aufträge (4.3): Was sie in der Hand und auf dem Kopf tragen, und dass sie atmen, sich
# umsehen und dem Helden nachschauen. Die Figuren selbst sind Mann, Frau und Alter aus der Figurenfabrik; erkennbar
# werden die zwölf Leute der Aufträge an ihrem Zubehör, das zu ihrem Porträt passt (ui/portraits/P06 … P24):
# der Hirte mit dem Krummstab, die Bäckerin mit dem Brotkorb auf dem Kopf, die Wasserträgerin mit dem Krug, das Kind
# klein und mit der Jugendlocke. Die Dinge sind aus Grundformen gebaut und hängen an den Knochen (Hand, Kopf, Brust).
# Leben wird ihnen über die Körperschicht (koerper.gd) eingehaucht: LeuteKoerper setzt den Blick auf den Helden.

# Zubehör je Porträt der Aufträge (geschichte.gd › LEUTE, Schlüssel „bild“)
const NACH_BILD := {
	"P06": ["stab_krumm", "tuch_weiss"],     # Djau, Schafhirte
	"P07": ["sichel", "tuch_ocker"],          # Ipi, Bäuerin
	"P08": ["schlegel", "kappe"],             # Hori, Steinmetz
	"P09": ["krug_kopf"],                     # Tia, Wasserträgerin
	"P10": ["locke"],                         # Nefru, ein Kind
	"P18": ["stock", "tuch_weiss"],           # Chui, Eseltreiber
	"P19": ["reuse", "kappe"],                # Meni, Fischer
	"P20": ["korb_kopf", "tuch_weiss"],       # Baket, Bäckerin
	"P21": ["dechsel"],                       # Senbi, Zimmermann der Barke
	"P22": ["waeschekorb", "tuch_blau"],      # Iti, Wäscherin
	"P23": ["stock", "locke"],                # Pepi, Ziegenjunge
	"P24": ["tuch_ocker", "kette"],           # Henut, Nachbarin
}
# Zubehör der kleinen Bitten (leben.gd › AUFTRAEGE, Schlüssel „art“) und ein paar für Leute ohne Bitte
const NACH_BITTE := {"kamm": ["waeschekorb", "tuch_blau"], "kelle": ["krug_kopf"], "udjat": ["stock", "tuch_weiss"],
	"pinsel": ["palette"], "sistrum": ["sistrum", "kette"], "samen": ["korb_arm", "kappe"]}
const ALLTAG := [[], ["korb_kopf"], ["krug_kopf"], ["tuch_weiss"], ["stock"], ["korb_arm"], ["tuch_ocker", "kette"], []]

# Dinge in der Hand: die Handknochen zeigen mit y nach vorn, die Dinge sind entlang y gebaut
const HAND := Vector3(90, 0, 0)

static var _netz := {}

static func _stoff(name: String) -> StandardMaterial3D:
	var f := {"leinen": Color(0.86, 0.82, 0.72), "ocker": Color(0.66, 0.48, 0.26), "blau": Color(0.26, 0.38, 0.52),
		"holz": Color(0.42, 0.3, 0.18), "korb": Color(0.64, 0.5, 0.28), "ton": Color(0.62, 0.36, 0.22), "bronze": Color(0.62, 0.44, 0.2),
		"haar": Color(0.08, 0.06, 0.05), "brot": Color(0.72, 0.5, 0.26), "tuerkis": Color(0.2, 0.55, 0.55), "binse": Color(0.55, 0.52, 0.3)}
	var m := Deko.mat("leute_" + name, f[name], 0.85 if name != "bronze" else 0.45, Color.BLACK, 0.0, 0.6 if name == "bronze" else 0.0)
	return m

# ein Ding: Liste von [Netz, Knochen, Versatz, Drehung (Grad)]
static func _ding(art: String) -> Array:
	if _netz.has(art):
		return _netz[art]
	var teile := []
	var st := Deko._begin()
	var st2 := Deko._begin()
	match art:
		"stab_krumm", "stock":
			# Hirtenstab: lang, oben ein Haken; Stock: kürzer, gerade
			var l := 2.1 if art == "stab_krumm" else 1.5
			Deko._dreh(st, [[0.03, 0.03, l]], Vector3(0, -l * 0.55, 0), 1.0, 6)
			if art == "stab_krumm":
				for i in 5:
					var w := i / 4.0 * PI
					_ei(st, Vector3(0.1 - cos(w) * 0.1, l * 0.45 + sin(w) * 0.12, 0), Vector3(0.035, 0.035, 0.035), 5, 3)
			teile.append([Deko._commit([[st, _stoff("holz")]]), "handslot.r", Vector3.ZERO, HAND])
		"sichel":
			Deko._dreh(st, [[0.03, 0.03, 0.3]], Vector3(0, -0.1, 0), 1.0, 6)
			for i in 6:
				var w := i / 5.0 * 2.4
				_ei(st2, Vector3(sin(w) * 0.2, 0.2 + cos(w) * 0.2 - 0.0, 0), Vector3(0.03, 0.015, 0.008), 4, 3)
			teile.append([Deko._commit([[st, _stoff("holz")], [st2, _stoff("bronze")]]), "handslot.r", Vector3.ZERO, HAND])
		"schlegel":
			Deko._dreh(st, [[0.03, 0.03, 0.4]], Vector3(0, -0.1, 0), 1.0, 6)
			_ei(st, Vector3(0, 0.35, 0), Vector3(0.11, 0.09, 0.09), 8, 5)
			teile.append([Deko._commit([[st, _stoff("holz")]]), "handslot.r", Vector3.ZERO, HAND])
		"dechsel":
			Deko._dreh(st, [[0.03, 0.03, 0.55]], Vector3(0, -0.15, 0), 1.0, 6)
			Deko.box(st2, Vector3(0.05, 0.05, 0.22), Vector3(0, 0.36, 0.08))
			teile.append([Deko._commit([[st, _stoff("holz")], [st2, _stoff("bronze")]]), "handslot.r", Vector3.ZERO, HAND])
		"sistrum":
			Deko._dreh(st, [[0.025, 0.025, 0.3]], Vector3(0, -0.05, 0), 1.0, 6)
			for i in 7:
				var w := i / 6.0 * PI
				_ei(st, Vector3(cos(w) * 0.09, 0.33 + sin(w) * 0.14, 0), Vector3(0.02, 0.02, 0.02), 4, 3)
			teile.append([Deko._commit([[st, _stoff("bronze")]]), "handslot.r", Vector3.ZERO, HAND])
		"palette":
			Deko.box(st, Vector3(0.08, 0.32, 0.03), Vector3(0, -0.05, 0))
			Deko.box(st2, Vector3(0.012, 0.3, 0.012), Vector3(0.06, -0.05, 0.02))
			teile.append([Deko._commit([[st, _stoff("holz")], [st2, _stoff("binse")]]), "handslot.l", Vector3.ZERO, HAND])
		"korb_kopf", "korb_arm", "waeschekorb":
			# flacher Korb aus Binsen, auf dem Kopf mit Broten, am Arm mit Samen, die Wäsche auf der Hüfte
			var r := 0.22 if art != "korb_arm" else 0.16
			Deko._dreh(st, [[r * 0.7, r * 0.7, 0.02], [r, r, 0.16]], Vector3.ZERO, 1.0, 12)
			if art == "korb_kopf":
				for i in 4:
					_ei(st2, Vector3(cos(i * 1.6) * 0.09, 0.15, sin(i * 1.6) * 0.09), Vector3(0.065, 0.04, 0.065), 6, 4)
				teile.append([Deko._commit([[st, _stoff("korb")], [st2, _stoff("brot")]]), "head", Vector3(0, 0.4, 0), Vector3.ZERO])
			elif art == "waeschekorb":
				_ei(st2, Vector3(0, 0.16, 0), Vector3(r * 0.85, 0.09, r * 0.85), 8, 4)
				teile.append([Deko._commit([[st, _stoff("korb")], [st2, _stoff("leinen")]]), "head", Vector3(0, 0.4, 0), Vector3.ZERO])
			else:
				teile.append([Deko._commit([[st, _stoff("korb")]]), "handslot.l", Vector3(0, -0.15, 0), HAND])
		"krug_kopf":
			_ei(st, Vector3(0, 0.16, 0), Vector3(0.13, 0.16, 0.13), 10, 6)
			Deko._dreh(st, [[0.05, 0.065, 0.09]], Vector3(0, 0.3, 0), 1.0, 8)
			Deko._dreh(st2, [[0.1, 0.1, 0.03]], Vector3(0, -0.01, 0), 1.0, 10)
			teile.append([Deko._commit([[st, _stoff("ton")], [st2, _stoff("leinen")]]), "head", Vector3(0, 0.38, 0), Vector3.ZERO])
		"reuse":
			Deko._dreh(st, [[0.04, 0.2, 0.7]], Vector3(0, -0.35, 0), 1.0, 10)
			teile.append([Deko._commit([[st, _stoff("binse")]]), "chest", Vector3(0.15, 0.1, -0.32), Vector3(0, 0, 25)])
		"tuch_weiss", "tuch_ocker", "tuch_blau":
			# Kopftuch: liegt über dem Schädel und fällt hinten in den Nacken
			_ei(st, Vector3(0, 0.31, -0.03), Vector3(0.205, 0.2, 0.22), 12, 6)
			Deko.taper(st, Vector2(0.36, 0.07), Vector2(0.3, 0.05), 0.34, Vector3(0, -0.02, -0.16))
			var farbe: String = {"tuch_weiss": "leinen", "tuch_ocker": "ocker", "tuch_blau": "blau"}[art]
			teile.append([Deko._commit([[st, _stoff(farbe)]]), "head", Vector3(0, 0.0, 0), Vector3.ZERO])
		"kappe":
			_ei(st, Vector3(0, 0.31, -0.02), Vector3(0.19, 0.1, 0.2), 10, 5)
			teile.append([Deko._commit([[st, _stoff("leinen")]]), "head", Vector3.ZERO, Vector3.ZERO])
		"locke":
			# Jugendlocke: ein dicker Zopf an der rechten Kopfseite, der Kopf sonst kahl geschoren
			for i in 5:
				_ei(st, Vector3(-0.17, 0.2 - i * 0.065, -0.01), Vector3(0.042, 0.045, 0.042), 6, 4)
			teile.append([Deko._commit([[st, _stoff("haar")]]), "head", Vector3.ZERO, Vector3.ZERO])
		"kette":
			for i in 11:
				var w := PI * (0.15 + 0.7 * i / 10.0)
				_ei(st, Vector3(cos(w) * 0.17, 0.3 - sin(w) * 0.08, sin(w) * 0.15), Vector3(0.028, 0.028, 0.028), 5, 3)
			teile.append([Deko._commit([[st, _stoff("tuerkis")]]), "chest", Vector3.ZERO, Vector3.ZERO])
	_netz[art] = teile
	return teile

# Zubehör anhängen. Waffen der Figur bleiben verborgen (das macht der Aufrufer).
static func ausstatten(n: Node3D, dinge: Array) -> void:
	var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
	if sk == null:
		return
	for d in dinge:
		for t in _ding(String(d)):
			if sk.find_bone(t[1]) < 0:
				continue
			var ba := BoneAttachment3D.new()
			ba.bone_name = t[1]
			sk.add_child(ba)
			var mi := MeshInstance3D.new()
			mi.mesh = t[0]
			mi.position = t[2]
			mi.rotation_degrees = t[3]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ba.add_child(mi)

# Körperschicht für Leute: atmen, Gewicht verlagern, dem Helden nachschauen. Gibt die Schicht zurück (oder null).
static func beleben(n: Node3D, game, profil := {}) -> LeuteKoerper:
	var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
	if sk == null:
		return null
	var k := LeuteKoerper.new()
	if not k.bereit(sk):
		return null
	k.game = game
	k.figur = n
	k.traeger.model = n
	n.add_child(k.traeger)
	k.akteur = k.traeger
	var p := {"vor": 0.06, "traeg": 0.006, "kurve": 0.008, "brust": 0.02, "kopf": 0.02, "atem": 0.022, "blick": 1.1, "treffer": 0.0}
	p.merge(profil, true)
	k.profil(p)
	sk.add_child(k)
	return k

# Ellipsoid in einen SurfaceTool (wie Leben._ei; hier eigen, damit leute.gd ohne das Spiel geladen werden kann)
static func _ei(st: SurfaceTool, c: Vector3, r: Vector3, seg := 8, ringe := 5) -> void:
	var pts := []
	for j in ringe + 1:
		var row := []
		var v := PI * j / ringe
		for i in seg + 1:
			var u := TAU * i / seg
			var nrm := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			row.append([c + nrm * r, (nrm / r).normalized()])
		pts.append(row)
	for j in ringe:
		for i in seg:
			var a: Array = pts[j][i]
			var b: Array = pts[j][i + 1]
			var cc: Array = pts[j + 1][i + 1]
			var dd: Array = pts[j + 1][i]
			for q in [a, cc, b, a, dd, cc]:
				st.set_normal(q[1])
				st.set_uv(Vector2.ZERO)
				st.add_vertex(q[0])
