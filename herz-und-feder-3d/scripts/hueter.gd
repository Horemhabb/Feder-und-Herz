class_name Hueter extends RefCounted
# Kampfmuster der Hüter (4.1). Jeder Hüter der Stunden 1 bis 5 (und über seine Gestalt die geliehenen der Stunden 6 bis 12)
# kämpft nach einem eigenen Muster, das aus seiner Geschichte kommt:
#   Mahaf, das Leitlicht    nimmt dir das Licht der Laterne und führt dich mit Trugbildern im Kreis
#   Die Mutter der Häute    streift Häute ab, die aufstehen, wenn man sie nicht zerschlägt; wird mit jeder Haut schneller
#   Der König ohne Namen    ist unverwundbar, bis sein Name an den Kartuschen wieder brennt; dann schlägt er ihn aus
#   Der Sammler             lässt Krüge mit Herzen aufsteigen, die ihn heilen, wenn man sie nicht zerschlägt
#   Der Stumme Türhüter     behält seinen eigenen Ablauf in foe.gd (drei Phasen, der Maßstab)
#
# Angriffsfolge: Jeder Angriff ist ein Eintrag mit Ansage (Bodenmarke, Ton, bei starken Angriffen Ansage auf der Leiste),
# Ausführung und Erholung. Nach einer langen Erholung ist der Hüter „offen“ und nimmt mehr Schaden: das Fenster zum
# Bestrafen. Die Folge ist eine kleine Zustandsmaschine: wahl → ansage → los → erholung → wahl.
# Ein Angriff „x“ ruft _ansage_x (Marke zeigen) und _los_x (Wirkung); beides sind Methoden dieser Klasse.
# Eigene Modelle später: Die Gestalt steht in Foe.BOSS_LOOK („neu“ ist der Dateiname in models/chars/).

const OFFEN_MUL := 1.3      # so viel mehr Schaden nimmt ein Hüter, während er sich erholt
const SPD := 6.4 / 205.0

const MUSTER := {
	"wisp": {"beiname": "Fährmann ohne Fähre", "phasen": [0.65, 0.3],
		"pnamen": ["Der Fährmann", "Er nimmt dein Licht", "Das letzte Übersetzen"],
		"ptexte": ["", "Mahaf greift nach deiner Laterne, und ihr Licht wird schwach. Zwei Trugbilder führen dich im Kreis. Nur das echte Licht schaut zurück: golden.",
			"Er hält sein Ruder wieder. Ein letztes Mal will er übersetzen, und du sollst mit."],
		"angriffe": [
			{"id": "reigen", "name": "Lichtreigen", "ansage": 0.8, "erholung": 0.6, "cd": 6.0, "ph": [1, 2, 3]},
			{"id": "ueberfahrt", "name": "Überfahrt", "ansage": 1.1, "erholung": 1.6, "cd": 9.0, "ph": [1, 2, 3], "stark": true, "d0": 3.0},
			{"id": "irrlichter", "name": "Seelen ohne Fähre", "ansage": 1.0, "erholung": 0.5, "cd": 16.0, "ph": [1, 3]},
			{"id": "kreis", "name": "Er führt im Kreis", "ansage": 1.2, "erholung": 0.4, "cd": 18.0, "ph": [2, 3], "stark": true},
			{"id": "ruder", "name": "Ruderschlag", "ansage": 0.9, "erholung": 1.4, "cd": 8.0, "ph": [3], "stark": true, "dauer": 2.2},
		]},
	"mutter": {"beiname": "die zwölfte Haut", "phasen": [0.75, 0.5, 0.25],
		"pnamen": ["Die zwölfte Haut", "Gehäutet", "Zweimal gehäutet", "Ohne Haut"],
		"ptexte": ["", "Sie streift die Haut ab. Die leere Hülle liegt im Sand und füllt sich. Zerschlag sie, bevor sie aufsteht.",
			"Noch eine Haut. Sie wird kleiner, und sie wird schneller.", "Unter der letzten Haut ist nur noch Sand und Wut."],
		"angriffe": [
			{"id": "stampfer", "name": "Stampfer", "ansage": 1.1, "erholung": 0.9, "cd": 7.0, "ph": [1, 2, 3, 4], "d1": 6.5},
			{"id": "faecher", "name": "Sandfächer", "ansage": 0.8, "erholung": 0.5, "cd": 5.0, "ph": [1, 2, 3, 4], "d0": 2.0},
			{"id": "ansturm", "name": "Ansturm", "ansage": 0.9, "erholung": 1.5, "cd": 8.0, "ph": [1, 2, 3, 4], "stark": true, "d0": 4.0, "d1": 22.0, "dauer": 0.9},
			{"id": "brut", "name": "Brut der Tefen", "ansage": 1.0, "erholung": 0.5, "cd": 18.0, "ph": [2, 3, 4]},
		]},
	"koenig": {"beiname": "der seinen Namen verkaufte", "phasen": [0.6, 0.25],
		"pnamen": ["Namenlos", "Die Grabwache", "Der Name hält"],
		"ptexte": ["", "Er ruft seine Grabwache. An der Wand glimmt eine weitere Kartusche.",
			"Sein Name steht wieder an den Wänden, und er kann ihn nicht mehr ausschlagen."],
		"angriffe": [
			{"id": "goldschwert", "name": "Goldschwert", "ansage": 1.0, "erholung": 1.3, "cd": 6.0, "ph": [1, 2, 3], "stark": true, "d1": 7.0},
			{"id": "welle", "name": "Schwertwelle", "ansage": 1.1, "erholung": 0.8, "cd": 8.0, "ph": [1, 2, 3], "d0": 3.0},
			{"id": "ansturm", "name": "Ansturm", "ansage": 0.9, "erholung": 1.4, "cd": 10.0, "ph": [1, 2, 3], "stark": true, "d0": 5.0, "d1": 22.0, "dauer": 0.9},
			{"id": "grabwache", "name": "Grabwache", "ansage": 1.0, "erholung": 0.5, "cd": 22.0, "ph": [2, 3]},
		]},
	"sammler": {"beiname": "einer der Zweiundvierzig", "phasen": [0.6, 0.3],
		"pnamen": ["Der Richter", "Das Verzeichnis", "Sein eigenes Herz"],
		"ptexte": ["", "Er schlägt sein Verzeichnis auf. Mehr Krüge steigen aus dem Boden, und sie leeren sich schneller in ihn.",
			"Er hält einen Krug an die Brust. Es ist sein eigener, und er ist schwer."],
		"angriffe": [
			{"id": "kruege", "name": "Die Krüge", "ansage": 1.2, "erholung": 0.8, "cd": 15.0, "ph": [1, 2, 3], "stark": true},
			{"id": "waage", "name": "Waagbalken", "ansage": 1.0, "erholung": 1.3, "cd": 7.0, "ph": [1, 2, 3], "stark": true},
			{"id": "urteil", "name": "Urteil", "ansage": 1.2, "erholung": 0.6, "cd": 6.0, "ph": [1, 2, 3]},
			{"id": "herzschlag", "name": "Herzschlag", "ansage": 0.7, "erholung": 0.6, "cd": 7.5, "ph": [1, 2, 3]},
			{"id": "verzeichnis", "name": "Die Erloschenen", "ansage": 1.0, "erholung": 0.5, "cd": 20.0, "ph": [2, 3]},
		]},
	# Der Hüter ohne Stimme (Stunde 8) trägt die Gestalt des Türhüters, ist aber kein Endgegner eines Aktes
	"grey": {"beiname": "aus dessen Gruft kein Laut kommt", "phasen": [0.5],
		"pnamen": ["Stumm", "Stille"],
		"ptexte": ["", "Es wird still. Er ruft, ohne einen Laut."],
		"angriffe": [
			{"id": "herzschlag", "name": "Geschossring", "ansage": 0.8, "erholung": 0.6, "cd": 5.0, "ph": [1, 2]},
			{"id": "stampfer", "name": "Stampfer", "ansage": 1.1, "erholung": 1.2, "cd": 7.0, "ph": [1, 2], "stark": true, "d1": 7.0},
			{"id": "ansturm", "name": "Ansturm", "ansage": 0.9, "erholung": 1.4, "cd": 9.0, "ph": [1, 2], "stark": true, "d0": 4.0, "d1": 22.0, "dauer": 0.9},
			{"id": "verzeichnis", "name": "Die Erloschenen", "ansage": 1.0, "erholung": 0.5, "cd": 18.0, "ph": [2]},
		]},
}
# nur für die Leiste: der Türhüter kämpft nach seinem eigenen Ablauf in foe.gd
const TUERHUETER := {"beiname": "der nach dem Namen fragt", "phasen": [0.66, 0.33],
	"pnamen": ["Am Tor", "Er ruft die Erloschenen", "Das Tor zerbricht"]}

static func muster_von(f) -> Dictionary:
	if f.kampf:
		return f.kampf.M
	if f.kind == "boss" and f.ist_aktende():
		return TUERHUETER
	return {}

static func fuer(foe) -> Hueter:
	var look: String = foe.hour.get("boss", {}).get("look", "")
	look = {"apophis": "mutter"}.get(look, look)   # eigene Gestalt, geliehenes Kampfmuster
	if foe.ist_aktende() or not MUSTER.has(look):
		return null
	var k := Hueter.new()
	k.f = foe
	k.g = foe.game
	k.art = look
	k.M = MUSTER[look]
	return k

var f            # der Hüter (Foe)
var g            # das Spiel (main.gd)
var art := ""
var M: Dictionary
var phase := 1
var zustand := "wahl"
var cur: Dictionary = {}
var t := 1.0
var cd := {}
var gen := 0             # zählt Neuanfänge: was nach einer Niederlage noch nachklingt, wirkt nicht mehr
var objekte: Array = []  # Kartuschen, Krüge, Trugbilder (Foe mit rolle)
var offen_t := 0.0
var tempo := 1.0         # Abklingzeiten und Erholung (Mutter: schneller mit jeder Haut)
var kampf_t := 0.0
var gestartet := false
var vorbei := false
var status := ""         # Zeile unter der Leiste
var licht_gedimmt := false
# Mahaf
var schau_t := 2.5
var trug_erzeugt := 0
var schaden_seit_trug := 0.0
var orbit := 0.0
var ruder: Node3D
var spirale_t := 0.0
var spirale_a := 0.0
# König
var schild := false
var schild_vis: Node3D
var fenster_t := 0.0
var schlag_t := -1.0
# Sammler
var eigenkrug: Node3D
# Mutter
var huellen: Array = []

func gen_ok(n: int) -> bool:
	return n == gen and not vorbei and is_instance_valid(f) and f.state != Foe.St.DEAD

func spaeter(sek: float, cb: Callable) -> void:
	var n := gen
	f.get_tree().create_timer(sek, false).timeout.connect(func():
		if gen_ok(n):
			cb.call())

func h() -> Hero:
	return g.hero

# ---------------------------------------------------------------- Gestalt (ohne neue Modelle)
# Jeder Hüter bekommt einen Bannkreis am Boden in seiner Farbe und Zeichen seiner Geschichte aus einfachen Formen.
# Kommt später ein eigenes Modell (Agent A, Figurenfabrik), genügt in Foe.BOSS_LOOK der neue Dateiname unter „neu“;
# die Zeichen hier hängen an Knochen mit Namen (head, chest) und wandern mit.
var bannkreis: Node3D
var hautplatten: Array = []
var sammlung: Node3D
var schein: Node3D

static func _mat(col: Color, glanz := 0.0, add := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if add:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	if glanz > 0.0:
		m.emission_enabled = true
		m.emission = Color(col.r, col.g, col.b)
		m.emission_energy_multiplier = glanz
	return m

static func _teil(mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func gestalt() -> void:
	var col: Color = f.K.get("bcol", Color(1.0, 0.85, 0.5))
	bannkreis = Node3D.new()
	var r: float = f.radius * 2.4
	var tm := TorusMesh.new()
	tm.inner_radius = r
	tm.outer_radius = r + 0.12
	tm.rings = 40
	tm.ring_segments = 3
	bannkreis.add_child(_teil(tm, _mat(Color(col, 0.75), 0.0, true)))
	var tm2 := TorusMesh.new()
	tm2.inner_radius = r * 0.78
	tm2.outer_radius = r * 0.78 + 0.06
	tm2.rings = 8
	tm2.ring_segments = 3
	bannkreis.add_child(_teil(tm2, _mat(Color(1.0, 0.85, 0.5, 0.6), 0.0, true)))
	for i in 12:
		var a := TAU * i / 12.0
		var z := BoxMesh.new()
		z.size = Vector3(0.12, 0.02, 0.45 if i % 3 == 0 else 0.25)
		var zi := _teil(z, _mat(Color(col, 0.8), 0.0, true), Vector3(sin(a), 0, cos(a)) * (r * 0.89))
		zi.rotation.y = a
		bannkreis.add_child(zi)
	bannkreis.position.y = 0.06
	f.add_child(bannkreis)
	match art:
		"wisp":
			schein = _heiligenschein(col)
			if f.model:
				f.model.add_child(schein)
		"koenig":
			var k := _koenigskrone()
			if f.skel and f.skel.find_bone("head") >= 0:
				f.attach("head", k)
			else:
				k.position.y = 2.6 * f.sc
				f.add_child(k)
			f.glut(0.6, Color(1.0, 0.75, 0.3))
		"mutter":
			# drei Hautplatten an Schultern und Rücken: mit jeder Häutung fällt eine
			var hm := _mat(Color(0.72, 0.6, 0.42), 0.15)
			var orte := [Vector3(0.42, 0.25, -0.05), Vector3(-0.42, 0.25, -0.05), Vector3(0, 0.15, -0.42)]
			for i in (3 if f.skel and f.skel.find_bone("chest") >= 0 else 0):
				var pl := BoxMesh.new()
				pl.size = Vector3(0.55, 0.12, 0.5) if i < 2 else Vector3(0.75, 0.6, 0.12)
				var pi := _teil(pl, hm, orte[i])
				pi.rotation.z = [0.4, -0.4, 0.0][i]
				if f.skel and f.skel.find_bone("chest") >= 0:
					f.attach("chest", pi)
				else:
					pi.position.y += 1.6 * f.sc
					f.add_child(pi)
				hautplatten.append(pi)
		"sammler":
			# seine Sammlung: drei kleine Krüge kreisen um ihn
			sammlung = Node3D.new()
			for i in 3:
				var kj := SphereMesh.new()
				kj.radius = 0.22
				kj.height = 0.5
				kj.radial_segments = 8
				kj.rings = 4
				var a := TAU * i / 3.0
				sammlung.add_child(_teil(kj, _mat(Color(0.62, 0.42, 0.3), 0.0), Vector3(sin(a) * 1.5, 1.6, cos(a) * 1.5)))
				var hz := SphereMesh.new()
				hz.radius = 0.09
				hz.height = 0.18
				sammlung.add_child(_teil(hz, _mat(Color(1.0, 0.3, 0.3, 0.9), 0.0, true), Vector3(sin(a) * 1.62, 1.6, cos(a) * 1.62)))
			f.add_child(sammlung)

# Mahafs Lichtscheibe hinter dem Kopf: Trugbilder tragen sie auch, nur das echte Licht wirft Licht
func _heiligenschein(col: Color) -> Node3D:
	var n := Node3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.68
	tm.rings = 28
	tm.ring_segments = 4
	var ti := _teil(tm, _mat(Color(col, 0.85), 0.0, true))
	ti.rotation.x = PI / 2
	n.add_child(ti)
	var dm := CylinderMesh.new()
	dm.top_radius = 0.55
	dm.bottom_radius = 0.55
	dm.height = 0.01
	dm.radial_segments = 20
	var di := _teil(dm, _mat(Color(col, 0.18), 0.0, true))
	di.rotation.x = PI / 2
	n.add_child(di)
	n.position = Vector3(0, 1.15, -0.35)
	return n

func _koenigskrone() -> Node3D:
	# hohe Krone wie die weiße Krone Oberägyptens, aus dem Gold der Tagesbarke
	var k := Node3D.new()
	var gold := _mat(Color(0.9, 0.7, 0.28), 0.8)
	gold.metallic = 0.8
	gold.roughness = 0.3
	var band := CylinderMesh.new()
	band.top_radius = 0.3
	band.bottom_radius = 0.28
	band.height = 0.16
	band.radial_segments = 12
	k.add_child(_teil(band, gold, Vector3(0, 0.62, 0)))
	var hoch := CylinderMesh.new()
	hoch.top_radius = 0.1
	hoch.bottom_radius = 0.27
	hoch.height = 0.8
	hoch.radial_segments = 12
	k.add_child(_teil(hoch, gold, Vector3(0, 1.1, 0)))
	var knauf := SphereMesh.new()
	knauf.radius = 0.13
	knauf.height = 0.26
	k.add_child(_teil(knauf, gold, Vector3(0, 1.52, 0)))
	# die Kartusche auf der Stirn ist leer
	var leer := TorusMesh.new()
	leer.inner_radius = 0.07
	leer.outer_radius = 0.1
	var li := _teil(leer, _mat(Color(0.1, 0.07, 0.04)), Vector3(0, 0.9, 0.24))
	li.rotation.x = PI / 2
	li.scale = Vector3(1, 1, 1.7)
	k.add_child(li)
	k.set_meta("gold", gold)
	return k

# ---------------------------------------------------------------- Ablauf
func start() -> void:
	if gestartet:
		return
	gestartet = true
	if has_method("_" + art + "_start"):
		call("_" + art + "_start")
	# nach einer Niederlage beginnt der Kampf in der Phase, in der er war: deren Licht kehrt zurück
	if art == "wisp" and phase >= 2:
		_laterne(true)
		if phase >= 3:
			_ruder_zeigen()
	elif art == "sammler" and phase >= 2:
		g.boss_licht(0.6)
	_status()

func tick(delta: float, hero: Hero, d: float, dirn: Vector3, gelaehmt: bool) -> void:
	if vorbei or not gestartet:
		return
	kampf_t += delta
	offen_t -= delta
	if bannkreis:
		bannkreis.rotation.y += delta * (0.5 if offen_t <= 0.0 else 2.0)
	if sammlung:
		sammlung.rotation.y += delta * 0.9
	for k in cd.keys():
		cd[k] -= delta
	if has_method("_" + art + "_tick"):
		call("_" + art + "_tick", delta, hero, d)
	if hero.dead:
		return
	match zustand:
		"wahl":
			t -= delta
			if t <= 0.0 and not gelaehmt and f.schild_t <= 0.0:
				_waehlen(d)
		"ansage":
			t -= delta
			if t <= 0.0:
				zustand = "los"
				t = float(cur.get("dauer", 0.0))
				if has_method("_los_" + cur.id):
					call("_los_" + cur.id, hero, d, dirn)
		"los":
			t -= delta
			if has_method("_halt_" + cur.id):
				call("_halt_" + cur.id, delta, hero)
			if t <= 0.0:
				zustand = "erholung"
				t = float(cur.erholung) * tempo
				if float(cur.erholung) >= 1.2:
					offen_t = t
					f.act_t = maxf(f.act_t, t)
					g.ring_fx(f.global_position, f.radius + 1.2, Color(1.0, 0.85, 0.4))
		"erholung":
			t -= delta
			if offen_t > 0.0 and f.charge_t <= 0.0 and f.stun <= 0.0:
				f.play(f.bew("boss/Lauern", Foe.ANIM.idle), 0.8)   # erschöpft: lauernd, offen für Treffer
			if t <= 0.0:
				zustand = "wahl"
				t = randf_range(0.35, 0.8) * tempo

func _waehlen(d: float) -> void:
	var kand := []
	for a in M.angriffe:
		if not a.ph.has(phase) or cd.get(a.id, 0.0) > 0.0:
			continue
		if d < float(a.get("d0", 0.0)) or d > float(a.get("d1", 99.0)):
			continue
		if has_method("_ok_" + a.id) and not call("_ok_" + a.id, d):
			continue
		kand.append(a)
	if kand.is_empty():
		t = 0.3
		return
	cur = kand.pick_random()
	cd[cur.id] = float(cur.cd) * tempo * randf_range(0.9, 1.15)
	zustand = "ansage"
	t = float(cur.ansage)
	f.act_t = t + 0.25   # hält die Ausholbewegung, statt sie mit Stehen zu überschreiben
	if cur.get("stark", false):
		g.hud.boss_ansage(cur.name)
	f.look_to(h().global_position)
	if has_method("_ansage_" + cur.id):
		call("_ansage_" + cur.id, h(), d)

# steht der Hüter gerade still (Ansage, Ausführung, Erholung)?
func steht() -> bool:
	return zustand == "ansage" or (zustand == "los" and f.charge_t <= 0.0) or (zustand == "erholung" and offen_t > 0.0) or f.schild_t > 0.0

# Bewegung zwischen den Angriffen: die meisten rücken heran, Mahaf kreist, der Sammler hält Abstand
func bewegung(hero: Hero, d: float, dirn: Vector3, delta: float) -> Vector3:
	match art:
		"wisp":
			var rad := 6.5 if phase == 1 else 6.0
			var tang := Vector3(-dirn.z, 0, dirn.x)
			return (tang * 1.0 + dirn * clampf((d - rad) * 0.5, -1.0, 1.0)).normalized()
		"sammler":
			if d < 5.5:
				return -dirn
			if d > 9.0:
				return f._toward(hero.global_position, dirn, delta)
			return Vector3(-dirn.z, 0, dirn.x) * 0.5
		_:
			if d > 3.2 + f.radius:
				return f._toward(hero.global_position, dirn, delta)
	return Vector3.ZERO

# Schaden am Hüter: Schild, offenes Fenster, Trugbild-Phase
func schaden(amount: float) -> float:
	if schild:
		return 0.0
	if offen_t > 0.0:
		amount *= OFFEN_MUL
	if art == "wisp" and _trugbilder().size() > 0:
		schaden_seit_trug += amount
	return amount

func schild_text() -> String:
	return "namenlos: unverwundbar"

# nach jedem Treffer: Schwelle der nächsten Phase erreicht?
func nach_treffer() -> void:
	if vorbei or f.hp <= 0.0:
		return
	var ph: Array = M.phasen
	while phase <= ph.size() and f.hp < f.max_hp * float(ph[phase - 1]):
		phase += 1
		if has_method("_" + art + "_phase"):
			call("_" + art + "_phase", phase)
		g.on_boss_phase(f, phase)
	if art == "wisp" and phase >= 2 and schaden_seit_trug > f.max_hp * 0.07 and _trugbilder().size() > 0:
		_trug_zerreissen()

func phasen_name() -> String:
	return M.pnamen[clampi(phase - 1, 0, M.pnamen.size() - 1)]

func phasen_text() -> String:
	return M.ptexte[clampi(phase - 1, 0, M.ptexte.size() - 1)]

func _status() -> void:
	match art:
		"koenig":
			var an := objekte.filter(func(o): return o.rolle == "kartusche" and o.state == Foe.St.DEAD).size()
			var alle := objekte.filter(func(o): return o.rolle == "kartusche").size()
			if schild:
				status = "Unverwundbar · entzünde seinen Namen an den Kartuschen (%d/%d)" % [an, alle]
			elif phase >= 3:
				status = "Sein Name hält"
			else:
				status = "Er hört seinen Namen · verwundbar"
		"sammler":
			var n := objekte.filter(func(o): return o.rolle == "krug" and o.state != Foe.St.DEAD).size()
			status = ("Zerschlag die Krüge, sonst heilen sie ihn (%d)" % n) if n > 0 else ""
		"wisp":
			status = "Trugbilder: das echte Licht schaut golden zurück" if _trugbilder().size() > 0 else ("Deine Laterne brennt schwach" if licht_gedimmt else "")
		"mutter":
			var n2 := huellen.filter(func(x): return is_instance_valid(x) and x.state != Foe.St.DEAD and x.huelle_t > 0.0).size()
			status = ("Zerschlag die Hülle, bevor sie aufsteht (%d)" % n2) if n2 > 0 else ""
		_:
			status = ""

# Der Hüter fällt: Licht zurück, was er gerufen und aufgestellt hat, vergeht
func ende() -> void:
	vorbei = true
	_aufraeumen()
	if art == "wisp" and licht_gedimmt:
		g.float_text(h().global_position + Vector3(0, 2.6, 0), "sein Licht geht in deine Laterne", Color(1.0, 0.85, 0.5), 1.2)
	_laterne(false)
	status = ""

# Niederlage des Helden: der Kampf beginnt beim nächsten Erwachen wieder in dieser Phase, aber ohne Altlasten
func zuruecksetzen() -> void:
	gen += 1
	zustand = "wahl"
	t = 1.5
	offen_t = 0.0
	gestartet = false
	_aufraeumen()
	_laterne(false)
	if art == "koenig":
		_schild_an(phase < 3)

func _aufraeumen() -> void:
	for o in objekte:
		if is_instance_valid(o):
			if o.state != Foe.St.DEAD:
				o.state = Foe.St.DEAD
				o.collision_layer = 0
			_objekt_weg(o)
	objekte.clear()
	for x in huellen:
		if is_instance_valid(x) and x.state != Foe.St.DEAD:
			x.die()
	huellen.clear()
	if ruder:
		ruder.visible = false

func _objekt_weg(o) -> void:
	if not is_instance_valid(o) or o.proc == null:
		return
	var tw: Tween = o.create_tween()
	tw.tween_property(o.proc, "scale", Vector3.ONE * 0.05, 0.4)
	tw.tween_callback(func():
		o.visible = false
		o.process_mode = Node.PROCESS_MODE_DISABLED)

# ---------------------------------------------------------------- Bausteine: Ansagen und Treffer
func _kreis(c: Vector3, r: float, sek: float, mul: float, col: Color) -> void:
	c.y = 0.0
	g.warn_fx(c, r, sek)
	spaeter(sek, func():
		g.ring_fx(c, r, col)
		g.shake = maxf(g.shake, 0.4)
		g.sfx.play_at("hit", c, 0.1, -3.0)
		var hero := h()
		if not hero.dead and f.flat(hero.global_position - c).length() < r + hero.radius * 0.5:
			hero.hurt(f.dmg * mul, c, f))

func _bahn(c: Vector3, dir: Vector3, lang: float, breite: float, sek: float, mul: float, col: Color) -> void:
	g.stripe_fx(c, dir, lang, breite, sek)
	spaeter(sek, func():
		_blitzbahn(c, dir, lang, breite, col)
		var hero := h()
		var rel: Vector3 = f.flat(hero.global_position - c)
		var l := rel.dot(dir)
		if not hero.dead and l > -0.3 and l < lang and (rel - dir * l).length() < breite * 0.5 + hero.radius * 0.5:
			hero.hurt(f.dmg * mul, hero.global_position - dir, f))

func _blitzbahn(c: Vector3, dir: Vector3, lang: float, breite: float, col: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(breite, 0.12, lang)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(col, 0.8)
	m.material_override = mat
	g.add_child(m)
	m.global_position = c + dir * (lang / 2.0) + Vector3(0, 0.2, 0)
	m.rotation.y = atan2(dir.x, dir.z)
	g.shake = maxf(g.shake, 0.35)
	g.sfx.play_at("beam" if g.sfx._stream("beam") else "hit", c + dir * lang * 0.5, 0.1, -2.0)
	var tw := m.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(m.queue_free)

func _kegel(r: float, half: float, sek: float, mul: float) -> void:
	var c: Vector3 = f.global_position
	var fa: float = f.face
	g.cone_fx(c, fa, r, half, sek)
	spaeter(sek, func():
		var hero := h()
		var rel: Vector3 = f.flat(hero.global_position - c)
		var vor := Vector3(sin(fa), 0, cos(fa))
		g.ring_fx(c + vor * r * 0.5, r * 0.5, Color(1.0, 0.85, 0.45))
		g.shake = maxf(g.shake, 0.45)
		g.sfx.play_at("hit", c, 0.1, -2.0)
		if not hero.dead and rel.length() < r + hero.radius * 0.5 and (rel.length() < 1.0 or vor.angle_to(rel.normalized()) < half):
			hero.hurt(f.dmg * mul, c, f))

func _ring(n: int, mul: float, speed_px: float, col: Color, off := -1.0) -> void:
	var o := randf() * TAU if off < 0.0 else off
	g.sfx.play_at("bolt", f.global_position, 0.05, 2.0)
	for k in n:
		var a := o + TAU * k / n
		g.spawn_bolt(f.global_position + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), f.dmg * mul, speed_px / Daten.PX, col, 3.4)

func _ansturm_ansage(hero: Hero) -> void:
	var dir: Vector3 = f.flat(hero.global_position - f.global_position).normalized()
	f.charge_dir = dir
	f.face = atan2(dir.x, dir.z)
	g.stripe_fx(f.global_position, dir, 21.6, f.radius * 2.0, float(cur.ansage))
	g.sfx.play_at("boss_appear", f.global_position, 0.05, -6.0)
	f.play(Foe.ANIM.idle, 1.0)

func _ansturm_los() -> void:
	f.charge_t = 0.85
	f.charge_hit = false

func _rufen(arten: Array) -> void:
	g.boss_summon(f, arten)
	f.play(Foe.ANIM.summon if f.ap and f.ap.has_animation(Foe.ANIM.summon) else Foe.ANIM.cast, 1.4, 0.1, true)

func _ruf_ansage() -> void:
	g.ring_fx(f.global_position, 3.0, Color(0.75, 0.45, 0.95))
	f.play(Foe.ANIM.cast, 0.8, 0.1, true)
	g.sfx.play_at("boss_appear", f.global_position, 0.1, -10.0)

func _laterne(dunkel: bool) -> void:
	if dunkel == licht_gedimmt:
		return
	licht_gedimmt = dunkel
	var hero := h()
	if hero == null or hero.lantern == null:
		return
	hero.laterne_dimmen(0.42 if dunkel else 1.0, 1.5 if dunkel else 0.8)
	g.boss_licht(0.35 if dunkel else 1.0)

# ---------------------------------------------------------------- Objekte (Kartuschen, Krüge, Trugbilder)
func _objekt(rolle: String, pos: Vector3, leben: float, rad: float, bild: Node3D, name: String, fest := true) -> Foe:
	# erst eine vergangene Hülle derselben Art wiederverwenden: so wächst die Liste der Gegner im langen Kampf nicht
	for o in g.foes:
		if o.kind == "objekt" and o.rolle == rolle and o.state == Foe.St.DEAD and o.besitzer == self and not objekte.has(o) and o.process_mode == Node.PROCESS_MODE_DISABLED:
			o.objekt_neu(pos, leben, bild)
			objekte.append(o)
			return o
	var o := Foe.new()
	o.game = g
	o.init_objekt(rolle, pos, leben, rad, bild, name, self, fest)
	o.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	g.add_child(o)
	g.foes.append(o)
	objekte.append(o)
	return o

func objekt_treffbar(o) -> bool:
	return not vorbei

func objekt_tick(o, delta: float) -> void:
	match o.rolle:
		"trugbild":
			_trug_tick(o, delta)
		"krug":
			_krug_tick(o, delta)
		"kartusche":
			# dunkle Kartusche: Ring und Zeichen glimmen im Takt, damit man sie im Dunkel findet
			var puls := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
			var boden: MeshInstance3D = o.proc.get_meta("boden")
			boden.material_override.albedo_color.a = 0.1 + 0.22 * puls
			var gold: StandardMaterial3D = o.proc.get_meta("gold")
			gold.emission_energy_multiplier = 0.2 + 0.35 * puls

func objekt_tot(o) -> void:
	if vorbei:
		_objekt_weg(o)
		return
	match o.rolle:
		"kartusche":
			_kartusche_an(o)
		"krug":
			_krug_zerschlagen(o)
		"trugbild":
			_trug_platzt(o)
	_status()

# ================================================================ Mahaf, das Leitlicht
# Er führte die Seelen im Kreis, seit er niemanden mehr übersetzen darf. Phase 1 kreist er um dich und schießt Reigen aus
# Licht; die Überfahrt ist ein Ansturm, der Glut im Kielwasser lässt. Phase 2 nimmt er dir das Licht der Laterne und teilt
# sich in drei: Das echte Licht schaut alle paar Sekunden golden zurück. Phase 3 hält er sein Ruder und schlägt Spiralen.
func _wisp_start() -> void:
	orbit = randf() * TAU
	_leuchten(f, f.K.bcol, 0.8)

func _wisp_tick(delta: float, hero: Hero, d: float) -> void:
	_status()
	# das echte Licht schaut zurück
	if _trugbilder().size() > 0:
		schau_t -= delta
		if schau_t <= 0.0:
			schau_t = 2.6
			_zurueckschauen(f)
	if ruder and ruder.visible:
		ruder.rotation.y += delta * 2.5

# Leuchten in einer Farbe: selbst gebaute Lichter über ihre Farbe, Figuren über die Glut in ihren Rissen
func _leuchten(o, col: Color, stark: float) -> void:
	if o.proc and not o.meshes.is_empty():
		var mi: MeshInstance3D = o.meshes[0]
		if mi.material_override is StandardMaterial3D:
			mi.material_override.albedo_color = col
	else:
		o.glut(stark, col)

func _zurueckschauen(wer) -> void:
	var gold := Color(1.0, 0.82, 0.35)
	_leuchten(wer, gold, 3.5)
	g.spark(wer.global_position + Vector3(0, 1.6, 0), gold)
	g.ring_fx(wer.global_position, 1.4, gold)
	g.sfx.play_at("irrlicht", wer.global_position, 0.05, 4.0)
	var n := gen
	f.get_tree().create_timer(0.9, false).timeout.connect(func():
		if n == gen and is_instance_valid(wer):
			_leuchten(wer, f.K.get("bcol", Color(0.56, 0.89, 0.88)), 0.8))

# Trugbild: dieselbe Gestalt wie Mahaf (gleiche Figur, gleiche Größe und Farbe), aber ohne Licht
func _trug_bild() -> Node3D:
	if f.proc or not f.K.has("neu"):
		return null
	var m: Node3D = load("res://models/chars/%s.glb" % f.K.neu).instantiate()
	m.scale = f.model.scale
	var quelle: Array = f.meshes
	var ziel: Array = m.find_children("*", "MeshInstance3D", true, false)
	for i in mini(quelle.size(), ziel.size()):
		var a: MeshInstance3D = quelle[i]
		var b: MeshInstance3D = ziel[i]
		if a.mesh == null:
			continue
		for j in a.mesh.get_surface_count():
			var mat = a.get_active_material(j)
			if mat:
				b.set_surface_override_material(j, mat.duplicate())
	if schein:
		m.add_child(_heiligenschein(f.K.get("bcol", Color(0.56, 0.89, 0.88))))
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(Foe.ANIM.idle):
		ap.get_animation(Foe.ANIM.idle).loop_mode = Animation.LOOP_LINEAR
		ap.play(Foe.ANIM.idle)
	return m

func _ansage_reigen(hero: Hero, d: float) -> void:
	g.ring_fx(f.global_position, 1.8, f.K.bcol)
	g.sfx.play_at("irrlicht", f.global_position, 0.05, 2.0)
	var koerper: Node3D = f.proc if f.proc else f.model
	if koerper:
		var s0: Vector3 = koerper.scale
		var tw: Tween = f.create_tween()
		tw.tween_property(koerper, "scale", s0 * 1.3, float(cur.ansage) * 0.8)
		tw.tween_property(koerper, "scale", s0, 0.2)
	_leuchten(f, Color(0.75, 1.0, 1.0), 2.5)
	spaeter(float(cur.ansage), func(): _leuchten(f, f.K.bcol, 0.8))

func _los_reigen(hero: Hero, d: float, dirn: Vector3) -> void:
	var n := 10 + mini(8, Spiel.fall)
	var off := randf() * TAU
	_ring(n, 0.75, 150.0, f.K.bcol, off)
	spaeter(0.45, func(): _ring(n, 0.75, 150.0, f.K.bcol, off + PI / n))

func _ansage_ueberfahrt(hero: Hero, d: float) -> void:
	_ansturm_ansage(hero)

func _los_ueberfahrt(hero: Hero, d: float, dirn: Vector3) -> void:
	# Kielwasser: Lichter auf der Bahn, die kurz danach aufbrechen
	var c: Vector3 = f.global_position
	var dir: Vector3 = f.charge_dir
	_ansturm_los()
	for i in 4:
		var p: Vector3 = c + dir * (3.0 + i * 4.0)
		if g.walkable(c, p):
			spaeter(0.6 + i * 0.12, func(): _kreis(p, 1.6, 0.9, 0.8, f.K.bcol))

func _ansage_irrlichter(hero: Hero, d: float) -> void:
	_ruf_ansage()

func _los_irrlichter(hero: Hero, d: float, dirn: Vector3) -> void:
	_rufen(["wisp", "wisp", "wisp"])

func _ok_kreis(d: float) -> bool:
	return _trugbilder().is_empty()

func _ansage_kreis(hero: Hero, d: float) -> void:
	g.ring_fx(f.global_position, 3.5, f.K.bcol)
	g.sfx.play_at("boss_phase", f.global_position, 0.05, -6.0)
	f.schild_t = maxf(f.schild_t, float(cur.ansage))

func _los_kreis(hero: Hero, d: float, dirn: Vector3) -> void:
	schaden_seit_trug = 0.0
	schau_t = 1.6
	for i in 2:
		var a := orbit + TAU * (i + 1) / 3.0
		var p: Vector3 = hero.global_position + Vector3(sin(a), 0, cos(a)) * 6.0
		if not g.walkable(hero.global_position, p):
			p = f.global_position
		# hält ein paar Treffer aus: wer blind auf das Nächste schlägt, löst erst ihren Reigen aus
		var o := _objekt("trugbild", p, maxf(20.0, Spiel.S.dmg * 1.6), f.radius, _trug_bild(), f.K.name, false)
		trug_erzeugt += 1
		o.set_meta("ort", i + 1)
		g.spark(p + Vector3(0, 1.4, 0), f.K.bcol)
	g.float_text(f.global_position + Vector3(0, 3.0, 0), "Welches Licht ist echt?", f.K.bcol, 1.2)
	_status()

func _trugbilder() -> Array:
	return objekte.filter(func(o): return o.rolle == "trugbild" and o.state != Foe.St.DEAD)

func _trug_tick(o, delta: float) -> void:
	# kreist mit dem echten Licht um den Helden, um ein Drittel versetzt, und schießt dann und wann
	var hero := h()
	var to: Vector3 = f.flat(hero.global_position - f.global_position)
	var a := atan2(-to.x, -to.z) + TAU * float(o.get_meta("ort", 1)) / 3.0
	var r := maxf(4.5, to.length())
	var ziel: Vector3 = hero.global_position + Vector3(sin(a), 0, cos(a)) * r
	if g.walkable(hero.global_position, ziel):
		o.global_position = o.global_position.lerp(ziel, minf(1.0, delta * 2.5))
	if o.model and f.model:
		o.model.rotation.y = lerp_angle(o.model.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 6.0))
	o.set_meta("schuss", float(o.get_meta("schuss", randf_range(2.0, 4.0))) - delta)
	if float(o.get_meta("schuss")) <= 0.0 and not hero.dead:
		o.set_meta("schuss", randf_range(3.5, 5.0))
		var dir: Vector3 = f.flat(hero.global_position - o.global_position).normalized()
		g.spawn_bolt(o.global_position + Vector3(0, 1.4, 0), dir, f.dmg * 0.6, 170.0 / Daten.PX, f.K.bcol, 2.6)

func _trug_platzt(o) -> void:
	# ein Trugbild zerplatzt in einen kleinen Reigen, der dich daran erinnert, dass es nicht das echte war
	g.float_text(o.global_position + Vector3(0, 2.6, 0), "nur ein Trugbild", Color(0.7, 0.9, 0.95))
	var c: Vector3 = o.global_position
	for k in 6:
		var a := TAU * k / 6.0
		g.spawn_bolt(c + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), f.dmg * 0.5, 120.0 / Daten.PX, f.K.bcol, 2.0)
	g.spark(c + Vector3(0, 1.4, 0), f.K.bcol)
	_objekt_weg(o)
	objekte.erase(o)

func _trug_zerreissen() -> void:
	for o in _trugbilder():
		o.state = Foe.St.DEAD
		o.collision_layer = 0
		g.spark(o.global_position + Vector3(0, 1.4, 0), Color(1.0, 0.85, 0.45))
		_objekt_weg(o)
		objekte.erase(o)
	g.hud.boss_ansage("Das Trugbild zerreißt")
	g.ring_fx(f.global_position, 3.0, Color(1.0, 0.85, 0.45))
	f.stun = maxf(f.stun, 1.5)
	offen_t = 2.5
	_status()

func _wisp_phase(n: int) -> void:
	if n == 2:
		_laterne(true)
		# sofort im Kreis führen
		cd["kreis"] = 0.0
		zustand = "wahl"
		t = 1.2
	elif n == 3:
		_ruder_zeigen()
		tempo = 0.85
	_status()

func _ruder_zeigen() -> void:
	if ruder == null:
		ruder = Node3D.new()
		var holz := StandardMaterial3D.new()
		holz.albedo_color = Color(0.55, 0.38, 0.2)
		holz.emission_enabled = true
		holz.emission = Color(0.56, 0.89, 0.88)
		holz.emission_energy_multiplier = 0.6
		var stange := BoxMesh.new()
		stange.size = Vector3(0.12, 0.12, 3.2)
		var si := MeshInstance3D.new()
		si.mesh = stange
		si.material_override = holz
		si.position = Vector3(0, 1.6, 1.0)
		ruder.add_child(si)
		var blatt := BoxMesh.new()
		blatt.size = Vector3(0.5, 0.06, 0.9)
		var bi := MeshInstance3D.new()
		bi.mesh = blatt
		bi.material_override = holz
		bi.position = Vector3(0, 1.6, 2.8)
		ruder.add_child(bi)
		f.add_child(ruder)
	ruder.visible = true
	g.spark(f.global_position + Vector3(0, 1.6, 0), Color(0.56, 0.89, 0.88))

func _ansage_ruder(hero: Hero, d: float) -> void:
	g.ring_fx(f.global_position, 2.5, Color(0.56, 0.89, 0.88))
	g.warn_fx(f.global_position, 2.2, float(cur.ansage))
	spirale_a = randf() * TAU
	spirale_t = 0.0

func _los_ruder(hero: Hero, d: float, dirn: Vector3) -> void:
	_kreis(f.global_position, 2.2, 0.01, 1.0, Color(0.56, 0.89, 0.88))

func _halt_ruder(delta: float, hero: Hero) -> void:
	# zwei Arme einer Spirale, wie Ruderschläge im Kreis
	spirale_t -= delta
	if spirale_t <= 0.0:
		spirale_t = 0.11
		spirale_a += 0.42
		for arm in 2:
			var a := spirale_a + PI * arm
			g.spawn_bolt(f.global_position + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), f.dmg * 0.7, 160.0 / Daten.PX, Color(0.75, 0.95, 0.9), 3.0)

# ================================================================ Die Mutter der Häute
# Mit jeder Haut, die sie abstreift, wird sie kleiner, röter und schneller. Die Haut bleibt als blasse Hülle liegen und
# steht nach vier Sekunden als Koloss auf; zerschlägt man sie vorher, nimmt die Hülle dreifachen Schaden.
func _mutter_start() -> void:
	f.glut(0.3, Color(1.0, 0.4, 0.2))

func _mutter_tick(delta: float, hero: Hero, d: float) -> void:
	_status()

func _mutter_phase(n: int) -> void:
	# Häutung: kurz unverwundbar, die Hülle fällt hinter ihr in den Sand
	f.schild_t = maxf(f.schild_t, 1.4)
	f.charge_t = 0.0
	zustand = "erholung"
	t = 1.6
	offen_t = 0.0
	var hinter: Vector3 = f.global_position - f.forward() * 2.2
	if not g.walkable(f.global_position, hinter):
		hinter = f.global_position
	g.ring_fx(f.global_position, 3.4, Color(0.85, 0.7, 0.45))
	g.spark(f.global_position + Vector3(0, 1.6, 0), Color(0.9, 0.75, 0.5))
	g.sfx.play_at("skel_wake", f.global_position, 0.05, 2.0)
	var vorher: int = g.foes.size()
	g.boss_summon(f, ["haut"])
	for i in range(vorher, g.foes.size()):
		var x = g.foes[i]
		x.global_position = hinter
		x.zur_huelle(4.5)
		huellen.append(x)
	if f.model:
		var tw: Tween = f.create_tween()
		tw.tween_property(f.model, "scale", f.model.scale * 0.88, 0.6).set_trans(Tween.TRANS_BACK)
	# eine Hautplatte fällt ab und zerstäubt
	if not hautplatten.is_empty():
		var pl: Node3D = hautplatten.pop_back()
		if is_instance_valid(pl):
			g.spark(pl.global_position, Color(0.85, 0.7, 0.45))
			var tw2: Tween = pl.create_tween()
			tw2.tween_property(pl, "scale", Vector3.ONE * 0.05, 0.5)
			tw2.tween_callback(pl.hide)
	f.spd *= 1.16
	f.dmg *= 1.06
	tempo *= 0.86
	f.glut(0.3 + 0.9 * (n - 1), Color(1.0, 0.32, 0.16))
	_status()

func _ansage_stampfer(hero: Hero, d: float) -> void:
	f.play(Foe.ANIM.slam if f.ap and f.ap.has_animation(Foe.ANIM.slam) else Foe.ANIM.cast, 0.9, 0.1, true)
	_kreis(f.global_position, 4.2, float(cur.ansage), 1.5, Color(0.85, 0.6, 0.3))

func _los_stampfer(hero: Hero, d: float, dirn: Vector3) -> void:
	g.shake = maxf(g.shake, 0.6)

func _ansage_faecher(hero: Hero, d: float) -> void:
	f.play(f.bew("boss/Wurf", Foe.ANIM.cast), 1.0, 0.1, true)
	g.cone_fx(f.global_position, f.face, 9.0, 0.55, float(cur.ansage))

func _los_faecher(hero: Hero, d: float, dirn: Vector3) -> void:
	var n := 7
	for k in n:
		var a: float = f.face - 0.5 + 1.0 * k / (n - 1)
		g.spawn_bolt(f.global_position + Vector3(0, 1.2, 0), Vector3(sin(a), 0, cos(a)), f.dmg * 0.8, 215.0 / Daten.PX, Color(0.9, 0.75, 0.45), 2.4)
	g.sfx.play_at("bolt", f.global_position, 0.05, -1.0)

func _ansage_ansturm(hero: Hero, d: float) -> void:
	_ansturm_ansage(hero)

func _los_ansturm(hero: Hero, d: float, dirn: Vector3) -> void:
	_ansturm_los()
	# ab der dritten Haut stürmt sie zweimal
	if art == "mutter" and phase >= 3:
		spaeter(1.3, func():
			var hero2 := h()
			if hero2.dead:
				return
			_ansturm_ansage(hero2)
			g.hud.boss_ansage("Noch einmal")
			spaeter(0.9, _ansturm_los))

func _ansage_brut(hero: Hero, d: float) -> void:
	_ruf_ansage()

func _los_brut(hero: Hero, d: float, dirn: Vector3) -> void:
	_rufen(["skorp", "skorp"])

# ================================================================ Der König ohne Namen
# Er hat seinen Namen verkauft. Wer keinen Namen hat, den trifft nichts: Solange sein Name nicht an den Kartuschen der
# Arena brennt, prallt jeder Hieb ab. Brennen alle, hört er ihn, sinkt auf die Knie und ist verwundbar, bis er ihn wieder
# ausschlägt. Ab einem Viertel Leben hält der Name, und er kann ihn nicht mehr tilgen.
func _koenig_start() -> void:
	if objekte.is_empty():
		_kartuschen(3 if phase < 2 else 4)
	if phase >= 3:
		for o in objekte:
			if o.rolle == "kartusche" and o.state != Foe.St.DEAD:
				o.state = Foe.St.DEAD
				o.collision_layer = 0
				_kartusche_an(o)
	_schild_an(phase < 3)

func _kartuschen(n: int) -> void:
	var c: Vector3 = f.home
	var basis := randf() * TAU
	var vorhanden := objekte.filter(func(o): return o.rolle == "kartusche").size()
	for i in range(vorhanden, n):
		var a := basis + TAU * i / float(n) + (0.3 if i >= 3 else 0.0)
		var p := c
		for weite in [9.0, 7.5, 10.5, 6.0, 12.0]:
			for dreh in [0.0, 0.4, -0.4, 0.8]:
				var q: Vector3 = c + Vector3(sin(a + dreh), 0, cos(a + dreh)) * weite
				if g.astar.is_in_boundsv(g._sub(q)) and not g.astar.is_point_solid(g._sub(q)) and g.walkable(c, q):
					p = q
					break
			if p != c:
				break
		if p == c:
			p = c + Vector3(sin(a), 0, cos(a)) * 4.0
		var o := _objekt("kartusche", p, maxf(30.0, Spiel.S.dmg * 2.6), 0.6, _kartusche_bild(), "Kartusche")
		o.face = atan2(c.x - p.x, c.z - p.z)
		o.proc.rotation.y = o.face
	_status()

func _kartusche_bild() -> Node3D:
	var n := Node3D.new()
	var stein := StandardMaterial3D.new()
	stein.albedo_color = Color(0.32, 0.29, 0.26)
	stein.roughness = 0.9
	var st := BoxMesh.new()
	st.size = Vector3(1.0, 2.3, 0.4)
	var si := MeshInstance3D.new()
	si.mesh = st
	si.material_override = stein
	si.position.y = 1.15
	n.add_child(si)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.38
	ring.rings = 20
	ring.ring_segments = 5
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.3, 0.24, 0.16)
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.75, 0.3)
	gold.emission_energy_multiplier = 0.0
	var ri := MeshInstance3D.new()
	ri.mesh = ring
	ri.material_override = gold
	ri.position = Vector3(0, 1.3, 0.22)
	ri.rotation.x = PI / 2
	ri.scale = Vector3(1.0, 1.0, 1.9)   # hochkant: eine Kartusche, oval wie der Ring um einen Königsnamen
	n.add_child(ri)
	# drei Zeichen im Ring, ausgeschlagen
	for i in 3:
		var z := BoxMesh.new()
		z.size = Vector3(0.22, 0.12, 0.05)
		var zi := MeshInstance3D.new()
		zi.mesh = z
		zi.material_override = gold
		zi.position = Vector3(0, 1.05 + i * 0.25, 0.22)
		n.add_child(zi)
	# ein goldener Ring am Boden, der pulsiert, solange die Kartusche dunkel ist: hier gibt es etwas zu tun
	var bm := CylinderMesh.new()
	bm.top_radius = 1.1
	bm.bottom_radius = 1.1
	bm.height = 0.01
	bm.radial_segments = 20
	var boden := _teil(bm, _mat(Color(1.0, 0.78, 0.3, 0.22), 0.0, true), Vector3(0, 0.05, 0.4))
	n.add_child(boden)
	n.set_meta("boden", boden)
	n.set_meta("gold", gold)
	return n

func _kartusche_an(o) -> void:
	# entzündet: der Ring glüht, ein Funke steigt auf; das Bild bleibt stehen
	var gold: StandardMaterial3D = o.proc.get_meta("gold")
	gold.emission_energy_multiplier = 2.2
	gold.albedo_color = Color(0.9, 0.7, 0.3)
	var boden: MeshInstance3D = o.proc.get_meta("boden")
	boden.material_override.albedo_color.a = 0.45
	o.visible = true
	g.ring_fx(o.global_position, 1.6, Color(1.0, 0.8, 0.35))
	g.spark(o.global_position + Vector3(0, 1.4, 0), Color(1.0, 0.85, 0.4))
	g.sfx.play_at("feuer_an" if g.sfx._stream("feuer_an") else "ui", o.global_position, 0.05, -3.0)
	var alle := objekte.filter(func(x): return x.rolle == "kartusche")
	var an := alle.filter(func(x): return x.state == Foe.St.DEAD).size()
	g.float_text(o.global_position + Vector3(0, 2.8, 0), "sein Name: %d von %d" % [an, alle.size()], Color(1.0, 0.85, 0.45), 1.2)
	if an >= alle.size() and schild:
		_name_gerufen()

func _kartusche_aus(o) -> void:
	var gold: StandardMaterial3D = o.proc.get_meta("gold")
	gold.emission_energy_multiplier = 0.0
	gold.albedo_color = Color(0.3, 0.24, 0.16)
	o.state = Foe.St.FIGHT
	o.hp = o.max_hp
	o.collision_layer = 4
	o.visible = true
	g.spark(o.global_position + Vector3(0, 1.4, 0), Color(0.4, 0.35, 0.3))

func _schild_an(an: bool) -> void:
	schild = an
	if schild_vis == null:
		schild_vis = Node3D.new()
		var sm := SphereMesh.new()
		sm.radius = f.radius + 1.0
		sm.height = (f.radius + 1.0) * 2.0
		sm.radial_segments = 24
		sm.rings = 12
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(1.0, 0.75, 0.3, 0.16)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var si := MeshInstance3D.new()
		si.mesh = sm
		si.material_override = m
		schild_vis.add_child(si)
		# ein dunkles Band um die Kugel: der ausgeschlagene Name
		var tm := TorusMesh.new()
		tm.inner_radius = f.radius + 0.95
		tm.outer_radius = f.radius + 1.08
		tm.rings = 32
		tm.ring_segments = 4
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.albedo_color = Color(0.12, 0.08, 0.05, 0.9)
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var ti := MeshInstance3D.new()
		ti.mesh = tm
		ti.material_override = bm
		ti.rotation.x = 0.3
		schild_vis.add_child(ti)
		schild_vis.position.y = 1.5
		f.add_child(schild_vis)
	schild_vis.visible = an
	_status()

func _koenig_tick(delta: float, hero: Hero, d: float) -> void:
	if schild_vis and schild_vis.visible:
		schild_vis.rotation.y += delta * 0.8
	if fenster_t > 0.0:
		fenster_t -= delta
		status = "Er hört seinen Namen · verwundbar (%d s)" % int(ceil(fenster_t))
		if fenster_t <= 0.0 and phase < 3:
			_name_ausschlagen()
	if schlag_t > 0.0:
		schlag_t -= delta

func _name_gerufen() -> void:
	_schild_an(false)
	f.stun = 3.0   # er kniet drei Sekunden
	offen_t = 3.0
	fenster_t = 14.0 if phase < 2 else 12.0
	f.play(f.bew("boss/Schildbruch", Foe.ANIM.hit), 0.6, 0.1, true)
	g.hud.boss_ansage("Er hört seinen Namen")
	g.hud.banner("Sein Name brennt an den Wänden. Er sinkt auf die Knie, und jetzt trifft ihn, was ihn trifft.", "ER HÖRT SEINEN NAMEN", 4.0)
	g.ring_fx(f.global_position, 5.0, Color(1.0, 0.8, 0.35))
	g.shake = maxf(g.shake, 0.5)
	g.sfx.play("boss_phase" if g.sfx._stream("boss_phase") else "boss_appear")

func _name_ausschlagen() -> void:
	# angesagt: Er hebt das Schwert, eine Sekunde später erlöschen die Kartuschen
	g.hud.boss_ansage("Er schlägt seinen Namen aus")
	f.play(Foe.ANIM.slam if f.ap and f.ap.has_animation(Foe.ANIM.slam) else Foe.ANIM.cast, 0.8, 0.1, true)
	g.ring_fx(f.global_position, 3.5, Color(0.4, 0.3, 0.2))
	spaeter(1.0, func():
		if phase >= 3:
			return
		for o in objekte:
			if o.rolle == "kartusche":
				_kartusche_aus(o)
		_schild_an(true)
		g.sfx.play_at("hit", f.global_position, 0.05, -2.0)
		g.shake = maxf(g.shake, 0.4))

func _koenig_phase(n: int) -> void:
	if n == 2:
		_kartuschen(4)
		_rufen(["guard", "guard"])
		_status()
	elif n == 3:
		fenster_t = 0.0
		for o in objekte:
			if o.rolle == "kartusche" and o.state != Foe.St.DEAD:
				o.state = Foe.St.DEAD
				o.collision_layer = 0
				_kartusche_an(o)
		_schild_an(false)
		tempo = 0.8
		f.glut(1.8, Color(1.0, 0.75, 0.3))
	_status()

func _ansage_goldschwert(hero: Hero, d: float) -> void:
	f.play(f.bew("boss/Wuchthieb", Foe.ANIM.atk_big), 1.0, 0.1, true)
	_kegel(5.2, 1.05, float(cur.ansage), 1.5)

func _ansage_welle(hero: Hero, d: float) -> void:
	f.play(Foe.ANIM.atk_big, 0.75, 0.1, true)
	var dir: Vector3 = f.flat(hero.global_position - f.global_position).normalized()
	_bahn(f.global_position, dir, 15.0, 2.2, float(cur.ansage), 1.25, Color(1.0, 0.8, 0.35))

func _ansage_grabwache(hero: Hero, d: float) -> void:
	_ruf_ansage()

func _los_grabwache(hero: Hero, d: float, dirn: Vector3) -> void:
	_rufen(["guard", "guard"])

# ================================================================ Der Sammler
# Er bewahrt Herzen in Krügen. In seiner Höhle steigen Krüge aus dem Boden; ein violetter Faden führt von jedem zu ihm.
# Was nach neun Sekunden noch steht, leert sich in ihn und heilt ihn. Zerschlägt man einen Krug, findet das Herz heim
# und schenkt dir etwas Leben. Dazu Waagbalken (Bahnen durch ihn hindurch) und Urteile (Kreise auf dir).
func _ok_kruege(d: float) -> bool:
	return objekte.filter(func(o): return o.rolle == "krug" and o.state != Foe.St.DEAD).is_empty()

var krug_orte: Array = []

func _ansage_kruege(hero: Hero, d: float) -> void:
	krug_orte.clear()
	var n := 2 + phase
	var basis := randf() * TAU
	for i in n:
		var a := basis + TAU * i / float(n)
		var p := Vector3.INF
		for weite in [6.5, 5.0, 8.0, 3.5]:
			for dreh in [0.0, 0.3, -0.3, 0.6, -0.6]:
				var q: Vector3 = f.global_position + Vector3(sin(a + dreh), 0, cos(a + dreh)) * weite
				if p == Vector3.INF and g.walkable(f.global_position, q) and not g.astar.is_point_solid(g._sub(q)) and krug_orte.all(func(o): return o.distance_to(q) > 1.8):
					p = q
		if p == Vector3.INF:
			continue
		krug_orte.append(p)
		g.ring_fx(p, 1.4, Color(0.7, 0.42, 0.88))
		g.warn_fx(p, 0.9, float(cur.ansage))
	f.play(Foe.ANIM.summon if f.ap and f.ap.has_animation(Foe.ANIM.summon) else Foe.ANIM.cast, 0.9, 0.1, true)

func _los_kruege(hero: Hero, d: float, dirn: Vector3) -> void:
	var dauer: float = [9.0, 7.5, 6.5][clampi(phase - 1, 0, 2)]
	for p in krug_orte:
		var o := _objekt("krug", p, maxf(20.0, Spiel.S.dmg * 2.0), 0.55, _krug_bild(), "Herzkrug", false)
		o.set_meta("bis", g.clock + dauer)
		o.set_meta("dauer", dauer)
		g.sfx.play_at("krug_bricht" if g.sfx._stream("krug_bricht") else "ui", p, 0.2, -12.0)
	_status()

func _krug_bild() -> Node3D:
	var n := Node3D.new()
	var ton := StandardMaterial3D.new()
	ton.albedo_color = Color(0.62, 0.42, 0.3)
	ton.roughness = 0.8
	var bauch := SphereMesh.new()
	bauch.radius = 0.42
	bauch.height = 0.9
	bauch.radial_segments = 12
	bauch.rings = 6
	var bi := MeshInstance3D.new()
	bi.mesh = bauch
	bi.material_override = ton
	bi.position.y = 1.2
	n.add_child(bi)
	var hals := CylinderMesh.new()
	hals.top_radius = 0.2
	hals.bottom_radius = 0.16
	hals.height = 0.3
	hals.radial_segments = 10
	var hi := MeshInstance3D.new()
	hi.mesh = hals
	hi.material_override = ton
	hi.position.y = 1.75
	n.add_child(hi)
	# das Herz schimmert durch den Ton: ein rotes Licht, das schlägt
	var herz := SphereMesh.new()
	herz.radius = 0.2
	herz.height = 0.4
	herz.radial_segments = 8
	herz.rings = 4
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.albedo_color = Color(1.0, 0.25, 0.25, 0.85)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var he := MeshInstance3D.new()
	he.mesh = herz
	he.material_override = hm
	he.position = Vector3(0, 1.2, 0.3)
	n.add_child(he)
	n.set_meta("herz", he)
	# Faden zum Sammler
	var faden := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.03
	fm.bottom_radius = 0.03
	fm.height = 1.0
	fm.radial_segments = 4
	faden.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.albedo_color = Color(0.75, 0.45, 1.0, 0.55)
	faden.material_override = fmat
	faden.top_level = true
	n.add_child(faden)
	n.set_meta("faden", faden)
	return n

func _krug_tick(o, delta: float) -> void:
	var tt := Time.get_ticks_msec() * 0.001
	var rest: float = float(o.get_meta("bis", 0.0)) - g.clock
	var dauer: float = float(o.get_meta("dauer", 9.0))
	o.proc.position.y = sin(tt * 1.7 + o.global_position.x) * 0.12 + 0.2
	var herz: Node3D = o.proc.get_meta("herz")
	var takt := 2.0 + 4.0 * (1.0 - rest / dauer)   # schlägt schneller, je näher das Leeren rückt
	herz.scale = Vector3.ONE * (1.0 + 0.25 * maxf(0.0, sin(tt * takt * PI)))
	var faden: MeshInstance3D = o.proc.get_meta("faden")
	var a: Vector3 = o.global_position + Vector3(0, 1.3, 0)
	var b: Vector3 = f.global_position + Vector3(0, 1.6, 0)
	faden.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.1:
		faden.look_at_from_position(faden.global_position, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
		faden.rotate_object_local(Vector3.RIGHT, PI / 2)
	faden.scale = Vector3(1, maxf(0.05, a.distance_to(b)), 1)   # nach dem Ausrichten: look_at setzt die Größe zurück
	faden.material_override.albedo_color.a = 0.3 + 0.5 * (1.0 - rest / dauer)
	if rest <= 0.0:
		_krug_leeren(o)

func _krug_leeren(o) -> void:
	# der Krug leert sich in ihn: violetter Blitz, er heilt
	o.state = Foe.St.DEAD
	o.collision_layer = 0
	var heil: float = f.max_hp * (0.05 if phase < 3 else 0.065)
	f.hp = minf(f.max_hp, f.hp + heil)
	g.float_text(f.global_position + Vector3(0, 3.0, 0), "+%d" % int(heil), Color(0.75, 0.5, 1.0), 1.3)
	Affixe._kettenblitz(g, o.global_position + Vector3(0, 1.3, 0), f.global_position + Vector3(0, 1.6, 0), Color(0.75, 0.45, 1.0))
	g.spark(o.global_position + Vector3(0, 1.3, 0), Color(0.75, 0.45, 1.0))
	g.sfx.play_at("krug_bricht" if g.sfx._stream("krug_bricht") else "hit", o.global_position, 0.1, -4.0)
	_objekt_weg(o)
	objekte.erase(o)
	_status()

func _krug_zerschlagen(o) -> void:
	# das Herz findet heim und streift dich im Vorbeifliegen: etwas Leben
	var hero := h()
	var heil: float = hero.max_hp * 0.05
	if not hero.dead:
		hero.hp = minf(hero.max_hp, hero.hp + heil)
		g.float_text(hero.global_position + Vector3(0, 2.4, 0), "+%d" % int(heil), Color(0.5, 1.0, 0.6))
	g.float_text(o.global_position + Vector3(0, 2.6, 0), "ein Herz findet heim", Color(1.0, 0.6, 0.6))
	g.spark(o.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.3, 0.3))
	g.sfx.play_at("herz_frei" if g.sfx._stream("herz_frei") else "ui", o.global_position, 0.1, -4.0)
	_objekt_weg(o)
	objekte.erase(o)

func _ansage_waage(hero: Hero, d: float) -> void:
	f.play(Foe.ANIM.cast, 0.9, 0.1, true)
	var dir: Vector3 = f.flat(hero.global_position - f.global_position).normalized()
	var richtungen := [dir]
	if phase >= 2:
		richtungen.append(Vector3(-dir.z, 0, dir.x))
	for r in richtungen:
		_bahn(f.global_position - r * 9.0, r, 18.0, 2.0, float(cur.ansage), 1.3, Color(0.75, 0.5, 1.0))

func _ansage_urteil(hero: Hero, d: float) -> void:
	f.play(Foe.ANIM.cast, 1.1, 0.1, true)
	for i in (3 if phase < 3 else 4):
		var p: Vector3 = hero.global_position + (Vector3.ZERO if i == 0 else Vector3(randf_range(-4.0, 4.0), 0, randf_range(-4.0, 4.0)))
		_kreis(p, 2.2, float(cur.ansage), 1.3, Color(0.75, 0.5, 1.0))

func _ansage_herzschlag(hero: Hero, d: float) -> void:
	f.play(Foe.ANIM.cast, 1.2, 0.1, true)
	g.ring_fx(f.global_position, 1.6, f.K.get("bcol", Color(0.7, 0.42, 0.88)))
	g.sfx.play_at("src_herz" if g.sfx._stream("src_herz") else "bolt", f.global_position, 0.05, 0.0)

func _los_herzschlag(hero: Hero, d: float, dirn: Vector3) -> void:
	var n := 12 + mini(10, Spiel.fall)
	_ring(n, 0.8, 165.0, f.K.get("bcol", Color(0.7, 0.42, 0.88)))
	if phase >= 2:
		spaeter(0.5, func(): _ring(n, 0.8, 165.0, f.K.get("bcol", Color(0.7, 0.42, 0.88))))

func _ansage_verzeichnis(hero: Hero, d: float) -> void:
	_ruf_ansage()

func _los_verzeichnis(hero: Hero, d: float, dirn: Vector3) -> void:
	_rufen(["fahl", "fahl"])

func _sammler_start() -> void:
	f.glut(0.4, Color(0.75, 0.45, 1.0))
	cd["kruege"] = 4.0

func _sammler_tick(delta: float, hero: Hero, d: float) -> void:
	if eigenkrug and eigenkrug.visible:
		eigenkrug.rotation.y += delta
		eigenkrug.position.y = 3.4 + sin(kampf_t * 2.0) * 0.15

func _sammler_phase(n: int) -> void:
	f.glut(0.4 + 0.8 * (n - 1), Color(0.75, 0.45, 1.0))
	cd["kruege"] = 1.0
	if n == 3:
		tempo = 0.85
		if eigenkrug == null:
			eigenkrug = _krug_bild()
			var faden: Node3D = eigenkrug.get_meta("faden")
			faden.visible = false
			eigenkrug.scale = Vector3.ONE * 0.8
			f.add_child(eigenkrug)
		eigenkrug.visible = true
	if n >= 2:
		g.boss_licht(0.6)

# ================================================================ Der Hüter ohne Stimme (Stunde 8)
func _grey_phase(n: int) -> void:
	tempo = 0.85
	g.boss_licht(0.5)
