class_name Orte extends Node
# Orte zum Handeln und die Aufgaben der Stunde (Fassung 2.0):
#   Feuerschalen  mit dem Funken des Re entzünden: Licht, etwas Heilung; brennen alle, ist der Hüter geschwächt
#   Schreine      Segen eines Gottes für eine Weile (Schaden, Erfahrung, Heilung, Tempo, Fundchance)
#   Seelenkrüge   ein gefangenes Herz freilassen (Maat) oder den Krug plündern (Isfet)
#   Figur         erzählt am Eingang ihren Teil der Geschichte und bittet um das Fundstück der Stunde
#   Fundstück     wer es findet, entscheidet, was damit geschieht (Geschichte.H › wahl)
# Dazu das Questbuch (quests) für die Anzeige oben links und die Herzwaage (Spiel.herz).

const GOETTER := [
	{"id": "sachmet", "name": "Sachmet", "col": Color(1.0, 0.36, 0.25), "txt": "Schaden +30 %", "dur": 60.0},
	{"id": "seschat", "name": "Seschat", "col": Color(0.55, 0.75, 1.0), "txt": "Erfahrung +50 %", "dur": 90.0},   # bis 3.2 Thot; der hat seit 3.3 seinen eigenen Schrein zum Umlernen
	{"id": "isis", "name": "Isis", "col": Color(0.5, 1.0, 0.7), "txt": "geheilt, Leben kehrt zurück", "dur": 45.0},
	{"id": "bastet", "name": "Bastet", "col": Color(1.0, 0.85, 0.4), "txt": "Lauftempo +25 %", "dur": 60.0},
	{"id": "hathor", "name": "Hathor", "col": Color(1.0, 0.6, 0.85), "txt": "Fundchance +60 %", "dur": 90.0},
]
const NAME := {"feuer": "Feuerschale", "schrein": "Schrein", "krug": "Seelenkrug", "relikt": "Fundstück", "figur": "", "helfer": "", "such": "", "werkstatt": "Werkstatt des Ptah", "thot": "Schrein des Thot"}

var game: Node
var thot: Dictionary = {}    # Schrein des Thot (3.3): hier wird umgelernt
var G: Dictionary            # Geschichte dieser Stunde
var sites: Array = []        # {kind, pos, v, done, vis, label, asked}
var quests: Array = []       # {id, titel, text, done}
var dirty := true            # die Anzeige soll das Questbuch neu zeichnen
var buffs := {}              # Gott → Restzeit in Sekunden
var talked := false
var relikt_done := false
var boss_weak := 0           # so oft wurde der Hüter schon geschwächt
var t := 0.0
var ba_done := {}
var npc := {}
var L: Dictionary            # der Mensch mit der Sorge in dieser Stunde (Geschichte.LEUTE)
var helfer := {}
var helfer_talked := false
var helfer_paid := false
var auto := true             # Tests schalten das Auslösen bei Berührung zeitweise ab
var werk := {}               # die Werkstatt des Ptah dieser Stunde
var marken: Array = []       # schwebende Anch-Zeichen über Figuren, die etwas zu sagen haben
var nl := {}                 # der Ba ohne Namen (2.9), falls er in dieser Stunde erscheint
var stueck := {}             # das fehlende Stück seiner Kartusche
var kartusche_bei_dir := false
var nl_schleier: MeshInstance3D

# Was die heimgeführten Ba sagen, einer nach dem anderen. Es ergibt ein Bild, aber nie das ganze.
const BA_WORTE := ["Wir sind nicht verloren. Man hat uns verlegt.",
	"Wer uns die Namen nahm, hat sie nicht verbrannt. Er hat sie aufgeschrieben.",
	"Es gibt ein Buch, das keine Waage kennt.",
	"Frag den Schreiber, warum seine Binse trocken ist.",
	"Auf der letzten Seite ist noch Platz."]
const BA_SILBEN := ["Mer…", "Nebet…", "…hotep", "Sat…", "…mose", "Ta…", "…nefer"]

func _ready() -> void:
	G = Geschichte.def(Spiel.fall)
	L = Geschichte.leute(Spiel.fall)
	Spiel.segen = {}
	Spiel.calc()

# ---------------------------------------------------------------- Aufbau
func add(kind: String, pos: Vector3, v: int) -> void:
	var s := {"kind": kind, "pos": pos, "v": v, "done": false, "asked": false}
	var size := Vector3(1.0, 1.4, 1.0)
	var text: String = NAME[kind]
	var col := Color(0.98, 0.78, 0.35)
	match kind:
		"feuer":
			s["vis"] = Deko.feuerschale(game, pos)
			text = "Erloschene Feuerschale"
		"schrein":
			var god: Dictionary = GOETTER[(v + Spiel.fall) % GOETTER.size()]
			s["gott"] = god
			s["vis"] = Deko.schrein(game, pos, god.col)
			# der Gott ist da: Licht fällt auf den Schrein, um ihn glüht ein Kreis seiner Zeichen
			game.stimmung.append(Stimmung.lichtstrahl(game, pos, 7.5, 1.9, god.col.lerp(Color(1.0, 0.9, 0.7), 0.45), 0.34, 0.22, 0.6))
			game.stimmung.append(Stimmung.runenkreis(game, pos, 2.0, god.col, 0.55))
			text = "Schrein der %s" % god.name
			col = god.col
			size = Vector3(1.3, 2.2, 1.3)
		"krug":
			s["vis"] = Deko.krug(game, pos)
			game.stimmung.append(Stimmung.nebel(game, pos, 5.5, Color(0.55, 0.75, 0.9), 0.32, 0.3))
			size = Vector3(0.8, 1.4, 0.8)
			col = Color(1.0, 0.5, 0.45)
		"relikt":
			s["vis"] = Deko.relikt(game, pos)
			game.stimmung.append(Stimmung.lichtstrahl(game, pos, 6.0, 1.0, Color(1.0, 0.84, 0.55), 0.3, 0.18, 0.3))
			text = G.relikt
		"figur":
			s["vis"] = _build_npc(pos, G.model, G.tint, true, 1.0)
			text = G.wer
			col = Color(0.56, 0.89, 0.88)
			size = Vector3(0.9, 2.0, 0.9)
			npc = s
		"helfer":
			s["vis"] = _build_npc(pos, L.model, Color.WHITE, false, 0.72 if L.get("klein", false) else 1.0)
			text = L.wer
			col = Color(0.85, 0.95, 0.7)
			size = Vector3(0.9, 2.0, 0.9)
			helfer = s
		"such":
			s["vis"] = Deko.such(game, pos, L.ding)
			text = L.eins
			col = Color(0.95, 0.95, 0.85)
		"thot":
			# Thot, der Schreiber der Götter: Hier wischt er die Tafel glatt, und man lernt neu (3.3)
			s["vis"] = Deko.schrein(game, pos, Color(0.55, 0.75, 1.0))
			game.stimmung.append(Stimmung.lichtstrahl(game, pos, 7.0, 1.6, Color(0.6, 0.78, 1.0), 0.3, 0.2, 0.5))
			game.stimmung.append(Stimmung.runenkreis(game, pos, 1.8, Color(0.55, 0.75, 1.0), 0.5))
			col = Color(0.62, 0.8, 1.0)
			size = Vector3(1.3, 2.2, 1.3)
			thot = s
		"werkstatt":
			# zum Eingang hin offen; der Goldschmied steht zwischen Ofen und Amboss
			var zu: Vector3 = game.start_pos - pos
			var rot := atan2(zu.x, zu.z)
			s["vis"] = Deko.werkstatt(game, pos, rot)
			var schmied := _build_npc(pos + Vector3(0, 0, -0.35).rotated(Vector3.UP, rot), "Alter", Color.WHITE, false, 1.0)
			schmied.mark.visible = false
			s["schmied"] = schmied
			size = Vector3(2.9, 1.6, 2.3)
			werk = s
	if kind != "such":
		game._box(pos, size)
		game.mark_solid(pos, size)
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 40
	l.outline_size = 10
	l.modulate = col
	l.pixel_size = 0.0055
	l.visible = false
	game.add_child(l)
	l.global_position = pos + Vector3(0, 3.0 if kind == "figur" or kind == "schrein" or kind == "helfer" or kind == "werkstatt" else (1.7 if kind == "such" else 2.3), 0)
	s["label"] = l
	# Namensschild (3.0): unter dem Namen steht in kleiner Schrift, wer das ist
	var wer := ""
	match kind:
		"figur": wer = G.get("titel", "")
		"helfer": wer = L.get("titel", "")
		"werkstatt": wer = "Goldschmied · antippen" if game.touch else "Goldschmied · Taste E"
		"schrein": wer = "Segen für eine Weile"
		"thot": wer = "umlernen · antippen" if game.touch else "umlernen · Taste E"
		"krug": wer = "ein gefangenes Herz"
		"feuer": wer = "entzünden"
	if wer != "":
		var l2 := Label3D.new()
		l2.text = wer
		l2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l2.font_size = 26
		l2.outline_size = 8
		l2.modulate = Color(0.93, 0.89, 0.8)
		l2.pixel_size = 0.0055
		l2.visible = false
		game.add_child(l2)
		l2.global_position = l.global_position - Vector3(0, 0.3, 0)
		s["label2"] = l2
	if kind == "figur" or kind == "helfer":
		# ein leiser Kreis am Boden: Hier steht jemand, mit dem man reden kann
		game.stimmung.append(Stimmung.runenkreis(game, pos, 1.25, col, 0.42))
	sites.append(s)

func _build_npc(pos: Vector3, model: String, tint: Color, geist: bool, scl: float) -> Dictionary:
	# Die Geschichte nennt noch die alten Rollen; seit 2.5 stehen dafür Figuren aus der Figurenfabrik
	var rolle := {"Knight": "Mann", "Barbarian": "Mann", "Rogue": "Frau", "Mage": "Alter", "Skeleton_Warrior": "Krieger", "Skeleton_Mage": "Erloschener",
		"Skeleton_Rogue": "Ruheloser", "Skeleton_Minion": "Ruheloser"}
	var n: Node3D = load("res://models/chars/%s.glb" % rolle.get(model, model)).instantiate()
	game.add_child(n)
	n.global_position = pos
	n.scale = Vector3.ONE * scl
	var to: Vector3 = game.start_pos - pos
	n.rotation.y = atan2(to.x, to.z)
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	if ap:
		for a in ["Idle", "Unarmed_Idle"]:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
				ap.play(a)
				break
	# Waffen ablegen, in der Farbe der Stunde tönen und leicht leuchten lassen: eine Gestalt der Duat, kein Gegner
	for w in Klassen.WEAPONS:
		var c := n.find_child(w, true, false)
		if c:
			c.visible = false
	# Gestalten der Duat leuchten in ihrer Farbe; gewöhnliche Leute sehen aus wie Leute
	if geist:
		_tint(n, tint)
	var l := OmniLight3D.new()
	l.light_color = tint if geist else Color(1.0, 0.85, 0.6)
	l.light_energy = 1.4 if geist else 0.9
	l.omni_range = 6.0 if geist else 4.5
	n.add_child(l)
	l.position = Vector3(0, 2.2, 0)
	# statt eines Ausrufezeichens: ein schwebendes Anch, golden bei Gestalten der Duat, grün bei Leuten mit einer Sorge
	var mark := Deko.marke(n, 3.85 / scl, Color(1.0, 0.78, 0.3) if geist else Color(0.62, 0.95, 0.5))
	marken.append(mark)
	return {"n": n, "mark": mark}

func _tint(n: Node, c: Color) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var m = n.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = d.albedo_color * c
				d.emission_enabled = true
				d.emission = c
				d.emission_energy_multiplier = 0.22
				n.set_surface_override_material(i, d)
	for ch in n.get_children():
		_tint(ch, c)

# nach dem Bau der Welt: das Questbuch der Stunde
func setup() -> void:
	quests = [{"id": "hueter", "titel": "Der Hüter", "text": "", "done": false}]
	if not helfer.is_empty():
		quests.append({"id": "leute", "titel": "%ss %s" % [L.wer, L.was], "text": "Sprich mit %s am Eingang." % L.wer, "done": false})
	if not npc.is_empty():
		quests.append({"id": "relikt", "titel": G.quest, "text": "Sprich mit %s." % G.get("mit", G.wer), "done": false})
	if count("feuer") > 0:
		quests.append({"id": "feuer", "titel": "Feuerschalen", "text": "", "done": false})
	if count("krug") > 0:
		quests.append({"id": "krug", "titel": "Seelenkrüge", "text": "", "done": false})
	_update_quests()

func count(kind: String, only_done := false) -> int:
	var n := 0
	for s in sites:
		if s.kind == kind and (s.done or not only_done):
			n += 1
	return n

func quest(id: String) -> Dictionary:
	for q in quests:
		if q.id == id:
			return q
	return {}

func _update_quests() -> void:
	var q := quest("feuer")
	if not q.is_empty():
		q.done = count("feuer", true) >= count("feuer")
		q["kurz"] = "%d/%d" % [count("feuer", true), count("feuer")]
		q.text = "Alle brennen. Der Hüter ist geschwächt." if q.done else "Entzünde sie: %d von %d. Brennen alle, ist der Hüter schwächer." % [count("feuer", true), count("feuer")]
	q = quest("krug")
	if not q.is_empty():
		q.done = count("krug", true) >= count("krug")
		q["kurz"] = "%d/%d" % [count("krug", true), count("krug")]
		q.text = "Alle Krüge sind geöffnet." if q.done else "Freilassen oder plündern: %d von %d." % [count("krug", true), count("krug")]
	q = quest("leute")
	if not q.is_empty():
		var n := count("such", true)
		q["kurz"] = "%d/%d" % [n, count("such")]
		q.done = n >= count("such")
		if q.done:
			q.text = "Alle gefunden. %s wartet am Eingang." % L.wer if not helfer_paid else "%s ist glücklich." % L.wer
		elif helfer_talked or n > 0:
			q.text = "Finde die %s: %d von %d." % [L.was, n, count("such")]
	dirty = true

func hueter_text() -> String:
	var p: float = float(game.kills) / maxf(1.0, game.total)
	if game.gate:
		return "Die Pforte steht offen. Tritt hinein, wenn du so weit bist."
	if game.boss_awake:
		return "%s ist hier." % game.boss.K.name
	if p >= 0.6:
		return "%s wartet auf dich." % game.boss.K.name
	return "Besiege Gegner (%d %%), dann zeigt sich der Hüter." % int(p * 100.0)

# ---------------------------------------------------------------- Ablauf
func tick(delta: float) -> void:
	t += delta
	var h: Hero = game.hero
	var frei: bool = auto and not h.dead and game.hud.overlay == null and not get_tree().paused
	for m in marken:
		if m.visible:
			m.rotation.y = t * 1.6
			m.position.y = float(m.get_meta("y")) + sin(t * 2.2) * 0.07
	if _namenlos_tick(h, frei):
		return
	for s in sites:
		var d: Vector3 = s.pos - h.global_position
		d.y = 0.0
		var dist := d.length()
		s.label.visible = dist < 11.0 and (not s.done or s.kind == "figur")
		if s.kind == "werkstatt" or s.kind == "thot":
			s.label.visible = dist < 14.0
		if s.has("label2"):
			s.label2.visible = s.label.visible and dist < 7.0
		if dist > 5.0:
			s.asked = false
		match s.kind:
			"krug":
				if not s.done:
					var beat := pow(maxf(0.0, sin(t * 4.2 + s.v)), 6.0)
					s.vis.glow.emission_energy_multiplier = 0.35 + beat * 1.6
					s.vis.light.light_energy = 0.6 + beat * 1.2
			"relikt":
				if not s.done:
					s.vis.item.rotation.y = t * 1.6
					s.vis.item.position.y = 1.35 + sin(t * 2.0) * 0.08
		if s.kind == "such" and not s.done and s.vis.tier:
			# Tiere stehen nicht still
			s.vis.n.position.y = absf(sin(t * 2.4 + s.v * 1.7)) * 0.06
			s.vis.n.rotation.y += sin(t * 0.7 + s.v) * 0.004
		if not frei or s.done and s.kind != "figur" and s.kind != "helfer":
			continue
		if s.kind == "werkstatt" or s.kind == "thot":
			continue   # öffnet sich nicht im Vorbeigehen: E drücken oder antippen
		if s.kind == "helfer":
			if not helfer_talked and dist < 3.2 and not s.asked:
				s.asked = true
				talk_helfer()
				return
			continue
		if s.kind == "figur":
			if not talked and dist < 3.2 and not s.asked:
				s.asked = true
				talk()
				return
			continue
		if dist < 1.9 and not s.asked:
			match s.kind:
				"such":
					_found(s)
				"feuer":
					_light(s)
				"schrein":
					_bless(s)
				"krug":
					s.asked = true
					_ask_jar(s)
					return
				"relikt":
					s.asked = true
					_ask_relic(s)
					return
	# Segen laufen ab
	for id in buffs.keys():
		buffs[id] -= delta
		if id == "isis" and not h.dead:
			h.hp = minf(h.max_hp, h.hp + h.max_hp * 0.02 * delta)
		if buffs[id] <= 0.0:
			buffs.erase(id)
			Spiel.segen.erase(id)
			Spiel.calc()
			h.apply_stats()
			dirty = true
	# dein Ba meldet sich kurz nach dem Eintreten
	if t > 6.0 and not ba_done.has("start") and frei:
		ba("start", G.ba)
	var q := quest("hueter")
	var txt := hueter_text()
	if q.text != txt:
		q.text = txt
		q["kurz"] = "Pforte offen" if game.gate else ("im Kampf" if game.boss_awake else "%d %%" % int(100.0 * game.kills / maxf(1.0, game.total)))
		q.done = game.gate != null
		dirty = true

# ---------------------------------------------------------------- Der Ba ohne Namen (2.9)
# Mitten im Reigen der Irrlichter schwebt ein Ba, aus dessen goldener Kartusche ein Stück fehlt. Er sieht nicht den
# Helden an, sondern dorthin, wo das Stück liegt. Wer es trägt, dem weicht der Reigen aus. Legt man es zurück,
# kehrt der Ba heim und flüstert einen Satz; die Sätze aller Stunden ergeben ein Rätsel, das sich nie ganz löst.
func hat_namenlos() -> bool:
	return not nl.is_empty()

func traegt_kartusche() -> bool:
	return kartusche_bei_dir

# Der Reigen lässt dich durch, solange du das Stück trägst; ist sein Ba heimgekehrt, tanzt er nur noch
func reigen_friedlich(pack: int) -> bool:
	return kartusche_bei_dir or (not nl.is_empty() and nl.fertig and nl.get("heim", false) and pack == nl.pack)

func _gold_mat(kraft: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.86, 0.66, 0.3)
	m.metallic = 0.75
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = Color(1.0, 0.75, 0.35)
	m.emission_energy_multiplier = kraft
	return m

# Kartusche: hochkantes Oval aus Goldgliedern mit Querbalken unten. luecke: diese Glieder fehlen
func _kartusche(luecke: Array, nur: Array = []) -> Node3D:
	var r := Node3D.new()
	var mat := _gold_mat(0.35)
	var n := 14
	for i in n:
		if i in luecke or (not nur.is_empty() and not i in nur):
			continue
		var a := TAU * (i + 0.5) / n
		var gl := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.05, 0.3, 0.05)
		gl.mesh = b
		gl.material_override = mat
		gl.position = Vector3(cos(a) * 0.5, sin(a) * 0.85, 0)
		gl.rotation.z = atan2(sin(a) * 0.85, cos(a) * 0.5)
		r.add_child(gl)
	if nur.is_empty():
		var bar := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.62, 0.05, 0.05)
		bar.mesh = bb
		bar.material_override = mat
		bar.position = Vector3(0, -0.98, 0)
		r.add_child(bar)
	r.set_meta("mat", mat)
	return r

func namenlos(pos: Vector3, stueck_pos: Vector3, pack: int) -> void:
	var n: Node3D = load("res://models/chars/Ba.glb").instantiate()
	game.add_child(n)
	n.global_position = pos
	n.scale = Vector3.ONE * 1.15
	_tint(n, Color(0.82, 0.92, 1.0))
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation("Idle_Combat"):
		ap.get_animation("Idle_Combat").loop_mode = Animation.LOOP_LINEAR
		ap.play("Idle_Combat", -1, 0.6)
	_schleier(n)
	var ring := _kartusche([3, 4])
	game.add_child(ring)
	ring.global_position = pos + Vector3(0, 1.55, 0)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.95, 0.9)
	l.light_energy = 0.8
	l.omni_range = 5.0
	n.add_child(l)
	l.position = Vector3(0, 1.6, 0)
	var lab := Label3D.new()
	lab.text = "?"
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 40
	lab.outline_size = 10
	lab.modulate = Color(0.7, 0.92, 0.9)
	lab.pixel_size = 0.0055
	lab.visible = false
	game.add_child(lab)
	lab.global_position = pos + Vector3(0, 3.1, 0)
	game.stimmung.append(Stimmung.nebel(game, pos, 7.0, Color(0.55, 0.8, 0.85), 0.3, 0.25))
	nl = {"pos": pos, "n": n, "ring": ring, "label": lab, "light": l, "pack": pack, "gesehen": false, "fertig": false, "asked": false}
	# das Stück: zwei Glieder der Kartusche, weit weg, in einem schwachen Lichtschein
	var st := _kartusche([], [3, 4])
	game.add_child(st)
	st.global_position = stueck_pos + Vector3(0, 1.0, 0)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.8, 0.45)
	sl.light_energy = 0.7
	sl.omni_range = 3.5
	st.add_child(sl)
	game.stimmung.append(Stimmung.lichtstrahl(game, stueck_pos, 5.0, 0.8, Color(1.0, 0.82, 0.5), 0.22, 0.1, 0.0))
	stueck = {"pos": stueck_pos, "n": st, "light": sl}

# Wo ein Gesicht sein sollte, flimmert nur Luft: ein Schleier am Kopfknochen, der jede Bewegung mitmacht
func _schleier(n: Node3D) -> void:
	var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var v := MeshInstance3D.new()
	Stimmung.schleier(v)
	var gesicht := Vector3(0, 1.56, 0.17)   # Augenhöhe, ein Stück vor dem Gesicht (Modellmaß, vor der Skalierung)
	var k := sk.find_bone("kopf") if sk else -1
	if k < 0:
		n.add_child(v)
		v.position = gesicht
		return
	var b := BoneAttachment3D.new()
	b.bone_name = "kopf"
	sk.add_child(b)
	b.add_child(v)
	v.transform = sk.get_bone_global_rest(k).affine_inverse() * Transform3D(Basis(), gesicht)
	nl_schleier = v

func _namenlos_tick(h: Hero, frei: bool) -> bool:
	if nl.is_empty():
		return false
	nl.ring.rotation.y = t * 0.35
	if not stueck.is_empty() and not kartusche_bei_dir and not nl.fertig:
		stueck.n.rotation.y = t * 1.2
		stueck.n.position.y = 1.0 + sin(t * 1.7) * 0.1
	if nl.fertig:
		return false
	var d: Vector3 = nl.pos - h.global_position
	d.y = 0.0
	var dist := d.length()
	nl.label.visible = dist < 11.0
	# er sieht nicht dich an, sondern dorthin, wo sein Stück liegt (oder dich, wenn du es trägst)
	var blick: Vector3 = (h.global_position if kartusche_bei_dir else stueck.pos) - nl.pos
	nl.n.rotation.y = lerp_angle(nl.n.rotation.y, atan2(blick.x, blick.z), 0.03)
	if not frei:
		return false
	if not nl.gesehen and dist < 9.0 and game.sees(h.global_position, nl.pos):
		nl.gesehen = true
		nl.label.text = "Ein Ba ohne Namen"
		game.hud.whisper("Ein Ba ohne Gesicht. Er dreht sich nicht nach dir um. Er sieht in die Ferne.")
		_namenlos_quest("Du trägst etwas, das zu ihm gehört." if kartusche_bei_dir else "Er sieht unverwandt in eine Richtung.")
	if not stueck.is_empty() and not kartusche_bei_dir:
		var ds: Vector3 = stueck.pos - h.global_position
		ds.y = 0.0
		if ds.length() < 1.9:
			_stueck_finden()
	if kartusche_bei_dir and dist < 3.4 and not nl.asked:
		nl.asked = true
		_namenlos_frage()
		return true
	if dist > 6.0:
		nl.asked = false
	return false

func _namenlos_quest(text: String) -> void:
	var q := quest("namenlos")
	if q.is_empty():
		q = {"id": "namenlos", "titel": "Ein Ba ohne Namen", "text": "", "done": false, "kurz": "?"}
		quests.append(q)
	q.text = text
	dirty = true

func _stueck_finden() -> void:
	kartusche_bei_dir = true
	game.sfx.play("aufheben", 0.1)
	var tw: Tween = stueck.n.create_tween()
	tw.tween_property(stueck.n, "scale", Vector3.ONE * 0.05, 0.5)
	tw.tween_callback(func(): stueck.n.visible = false)
	game.float_text(stueck.pos + Vector3(0, 1.4, 0), "Ein Stück Gold", Color(1.0, 0.82, 0.45), 1.1)
	game.hud.toast("Zwei Glieder einer Kartusche. Die Zeichen darauf sind warm. Lesen kannst du sie nicht.", 5.0)
	_namenlos_quest("Du trägst etwas, das zu ihm gehört.")
	ba("kartusche", "Die Lichter werden dir jetzt ausweichen. Sie wissen, was du trägst.")

func _namenlos_frage() -> void:
	if game.hero.dead or game.hud.overlay != null:
		nl.asked = false
		return
	get_tree().paused = true
	game.sfx.play("ui")
	var txt := ["Der Reigen der Lichter stockt. Der Ba schwebt dir entgegen, und die goldene Kartusche um ihn öffnet sich dort, wo zwei Glieder fehlen.",
		"Wo ein Gesicht sein sollte, ist nur ein Flimmern, wie Luft über heißem Stein. Das Gold in deiner Hand ist schwer und warm. Es würde sich gut verkaufen."]
	game.hud.show_dialog("EIN BA OHNE NAMEN", "Er hält still", "", txt, [
		["Das Stück in die Kartusche legen", func(): _heimkehr()],
		["Das Gold behalten", func(): _behalten()],
		["Noch nicht", func(): get_tree().paused = false]])

func _heimkehr() -> void:
	get_tree().paused = false
	nl.fertig = true
	nl["heim"] = true
	kartusche_bei_dir = false
	Spiel.ba_heim += 1
	var i: int = Spiel.ba_heim - 1
	var satz: String = BA_WORTE[i] if i < BA_WORTE.size() else "Er lächelt. Mehr sagt er nicht."
	# das Stück fliegt in den Ring, das Gold glüht auf, unter ihm leuchten die Zeichen
	stueck.n.visible = true
	stueck.n.scale = Vector3.ONE
	stueck.n.global_position = game.hero.global_position + Vector3(0, 1.4, 0)
	stueck.n.rotation = Vector3.ZERO
	var tw: Tween = stueck.n.create_tween()
	tw.tween_property(stueck.n, "global_position", nl.ring.global_position, 0.9).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(stueck.n, "rotation:y", nl.ring.rotation.y, 0.9)
	tw.tween_callback(func():
		stueck.n.reparent(nl.ring)
		stueck.n.position = Vector3.ZERO
		stueck.n.rotation = Vector3.ZERO
		for m in [nl.ring.get_meta("mat"), stueck.n.get_meta("mat")]:
			var mm: StandardMaterial3D = m
			game.create_tween().tween_property(mm, "emission_energy_multiplier", 2.4, 0.6)
		game.sfx.play_at("herz_frei", nl.pos, 0.1)
		game.stimmung.append(Stimmung.runenkreis(game, nl.pos, 2.2, Color(1.0, 0.8, 0.4), 0.7))
		game.hud.toast("Für einen Herzschlag kannst du die Zeichen lesen: „%s“ Dann sind sie fort." % BA_SILBEN[randi() % BA_SILBEN.size()], 5.5))
	tw.tween_interval(1.6)
	tw.tween_callback(func():
		game.hud.banner("„%s“" % satz, "DER BA KEHRT HEIM", 7.0)
		_soul(nl.pos + Vector3(0, 0.6, 0)))
	var auf: Tween = nl.n.create_tween()
	auf.tween_interval(2.5)
	auf.tween_property(nl.n, "global_position:y", nl.pos.y + 7.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	auf.parallel().tween_property(nl.ring, "global_position:y", nl.pos.y + 8.5, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	auf.parallel().tween_property(nl.n, "scale", Vector3.ONE * 0.2, 3.0)
	auf.parallel().tween_property(nl.ring, "scale", Vector3.ONE * 0.2, 3.0)
	auf.parallel().tween_property(nl.light, "light_energy", 0.0, 3.0)
	auf.tween_callback(func():
		nl.n.visible = false
		nl.ring.visible = false)
	nl.label.visible = false
	_weigh(3.5)
	if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.2):
		game._level_up()
	if game.karte_ui:
		game.karte_ui.reveal_around(nl.pos, 16)   # er zeigt dir, was er gesehen hat
	var q := quest("namenlos")
	q.done = true
	q.kurz = ""
	q.text = "Heimgekehrt. Seinen Namen hat er mitgenommen."
	dirty = true

func _behalten() -> void:
	get_tree().paused = false
	nl.fertig = true
	kartusche_bei_dir = false
	game.drop("shard", game.hero.global_position, 25 + 10 * Spiel.fall)
	_weigh(-4.0)
	var mat: StandardMaterial3D = nl.ring.get_meta("mat")
	game.create_tween().tween_property(mat, "emission_energy_multiplier", 0.0, 1.5)
	var ab: Tween = nl.n.create_tween()
	ab.tween_property(nl.n, "global_position:y", nl.pos.y - 2.0, 2.5).set_ease(Tween.EASE_IN)
	ab.parallel().tween_property(nl.light, "light_energy", 0.0, 2.0)
	ab.tween_callback(func():
		nl.n.visible = false
		nl.ring.visible = false)
	nl.label.visible = false
	ba("behalten", "Er hat nicht gefragt, warum. Er hat nur aufgehört, sich umzudrehen.")
	game.wake_pack(nl.pack)   # der Reigen zerfällt
	var q := quest("namenlos")
	q.done = true
	q.kurz = ""
	q.text = "Verstummt."
	dirty = true

func ba(key: String, text: String) -> void:
	if ba_done.has(key):
		return
	ba_done[key] = true
	# beim allerersten Mal steht dabei, was ein Ba ist; danach kennt man ihn
	if Spiel.gesehen("ba_stimme"):
		game.hud.whisper("Dein Ba flüstert: „%s“" % text)
	else:
		Spiel.merke("ba_stimme")
		game.hud.whisper("Dein Ba, der Seelenvogel, der dich begleitet, flüstert: „%s“" % text)

# ---------------------------------------------------------------- Leute und ihre Sorgen
func _found(s: Dictionary) -> void:
	s.done = true
	s.vis.light.light_energy = 0.0
	# Tiere melden sich, Dinge werden aufgehoben
	game.sfx.play(L.ding if L.ding in ["schaf", "ziege", "esel", "katze"] else "aufheben", 0.1)
	game.float_text(s.pos + Vector3(0, 1.4, 0), L.eins, Color(0.85, 0.95, 0.7), 1.1)
	game.hud.toast(L.fund, 4.5)
	# Tiere laufen heim, Dinge werden aufgehoben: beides verschwindet
	var n: Node3D = s.vis.n
	var tw := n.create_tween()
	if s.vis.tier and not helfer.is_empty():
		var to: Vector3 = (helfer.pos - s.pos).normalized() * 5.0
		n.rotation.y = atan2(to.x, to.z)
		tw.tween_property(n, "global_position", s.pos + to, 1.4)
		tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.05, 1.4).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(n, "scale", Vector3.ONE * 0.05, 0.4)
	tw.tween_callback(func(): n.visible = false)
	_update_quests()
	if quest("leute").done:
		game.hud.banner("%s wartet am Eingang auf dich." % L.wer, "ALLE %s GEFUNDEN" % L.was.to_upper(), 4.5)
		_weigh(3.0)
		if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.2):
			game._level_up()
		if not helfer.is_empty():
			helfer.vis.mark.visible = true

# ---------------------------------------------------------------- Werkstatt des Ptah
func near_werkstatt() -> bool:
	return not werk.is_empty() and (werk.pos - game.hero.global_position).length() < 4.2

func werkstatt_oeffnen() -> void:
	if werk.is_empty() or game.hero.dead or game.hud.overlay != null or get_tree().paused:
		return
	get_tree().paused = true
	game.sfx.play("ui")
	game.hud.show_werkstatt()
	if not Spiel.gesehen("werkstatt"):
		Spiel.merke("werkstatt")

# ---------------------------------------------------------------- Schrein des Thot (3.3)
func near_thot() -> bool:
	return not thot.is_empty() and game.hero != null and (thot.pos - game.hero.global_position).length() < 3.6

func thot_reden() -> void:
	if thot.is_empty() or game.hero.dead or game.hud.overlay != null:
		return
	get_tree().paused = true
	game.sfx.play("thot" if game.sfx._stream("thot") else "ui")
	var zu := func(): get_tree().paused = false
	var baum := func():
		get_tree().paused = false
		game.toggle_tree()
	if Spiel.tree_spent() == 0:
		game.hud.show_dialog("SCHREIN DES THOT", "Thot, Schreiber der Götter", "", ["Die Tafel vor dem Ibis ist leer. „Was du noch nicht geschrieben hast, muss ich nicht löschen.“"], [["Zum Fähigkeitenbaum", baum], ["Gehen", zu]])
		return
	var neu := func():
		Spiel.respec()
		game.hero.apply_stats()
		game.sfx.play("thot" if game.sfx._stream("thot") else "ui")
		game.hud.toast("Thot wischt die Tafel glatt: %d Punkte sind frei." % Spiel.tree_points(), 3.5)
		get_tree().paused = false
		game.toggle_tree()   # gleich neu verteilen: ohne Gelerntes stünde man sonst mit leeren Händen da
	game.hud.show_dialog("SCHREIN DES THOT", "Thot, Schreiber der Götter", "", ["Der Ibis neigt den Kopf und hält dir die Tafel hin, auf der steht, was du gelernt hast. „Ich kann es glatt wischen. Dann schreibst du neu, Wort für Wort, mit allen Punkten, die du hattest. Es kostet nichts als die Mühe.“"],
		[["Umlernen: alle Punkte zurück", neu], ["Lieber nicht", zu]])

func near_helfer() -> bool:
	return not helfer.is_empty() and (helfer.pos - game.hero.global_position).length() < 4.0

func talk_helfer() -> void:
	if helfer.is_empty() or game.hero.dead or game.hud.overlay != null:
		return
	get_tree().paused = true
	game.sfx.play("ui")
	helfer.vis.mark.visible = false
	var q := quest("leute")
	var ende := func():
		get_tree().paused = false
		helfer_talked = true
		_update_quests()
	if q.done and not helfer_paid:
		var lohn := func():
			get_tree().paused = false
			helfer_paid = true
			var n := Spiel.fall
			game.drop("shard", helfer.pos, 20 + 10 * n)
			game.drop_item(helfer.pos, Spiel.new_item(n + 1, 2))
			_update_quests()
		game.hud.show_dialog(L.titel.to_upper(), L.wer, "", ["„%s“" % L.dank], [["Danke.", lohn]], L.get("bild", ""))
	elif helfer_paid:
		game.hud.show_dialog(L.titel.to_upper(), L.wer, "", [Worte.zieh("helfer_wink") % L.wer], [["Gehen", ende]], L.get("bild", ""))
	else:
		game.hud.show_dialog(L.titel.to_upper(), L.wer, "", ["„%s“" % L.gruss], [["„Ich halte die Augen offen.“", ende]], L.get("bild", ""))

func near_npc() -> bool:
	return not npc.is_empty() and (npc.pos - game.hero.global_position).length() < 4.0

func _weigh(v: float) -> void:
	if Spiel.wiegen(v):
		game.hero.apply_stats()
		game.hud.banner(Geschichte.herz_wirkung(Spiel.herz), "DEIN HERZ IST JETZT " + Geschichte.herz_name(Spiel.herz).to_upper(), 5.0)
	dirty = true

func _weaken_boss(why: String) -> void:
	var b: Foe = game.boss
	if b == null or b.state == Foe.St.DEAD:
		return
	boss_weak += 1
	b.hp = minf(b.hp, b.max_hp * (1.0 - 0.2 * boss_weak))
	game.hud.banner(why, "DER HÜTER IST GESCHWÄCHT", 5.0)

# ---------------------------------------------------------------- Feuerschale
func _light(s: Dictionary) -> void:
	s.done = true
	Deko.entzuenden(game, s.vis)
	game.sfx.play_at("feuer_an", s.pos, 0.1)
	game.sfx.loop_at("feuer_brennt", s.vis.n)
	var h: Hero = game.hero
	h.hp = minf(h.max_hp, h.hp + h.max_hp * 0.12)
	game.float_text(s.pos + Vector3(0, 1.0, 0), "Feuer des Re", Color(1.0, 0.8, 0.4), 1.2)
	if game.karte_ui:
		game.karte_ui.reveal_around(s.pos, 9)
	_weigh(1.5)
	_update_quests()
	if count("feuer", true) % 2 == 1:
		ba("feuer%d" % count("feuer", true), Worte.zieh("ba_feuer"))   # nicht nach jeder Schale: Schweigen gehört dazu
	if quest("feuer").done:
		_weaken_boss("Alle Feuerschalen brennen. Der Hüter der Stunde scheut das Licht.")
		if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.25):
			game._level_up()

# ---------------------------------------------------------------- Schrein
func _bless(s: Dictionary) -> void:
	s.done = true
	var god: Dictionary = s.gott
	s.vis.glow.emission_energy_multiplier = 0.15
	s.vis.light.light_energy = 0.2
	buffs[god.id] = god.dur
	Spiel.segen[god.id] = true
	Spiel.calc()
	var h: Hero = game.hero
	h.apply_stats()
	if god.id == "isis":
		h.hp = h.max_hp
	game.sfx.play("segen", 0.05)
	game.hud.banner("%s (%d Sekunden)" % [god.txt, int(god.dur)], "SEGEN: %s" % god.name.to_upper(), 4.0)
	game.hud.erklaere(god.name)
	dirty = true

# ---------------------------------------------------------------- Seelenkrug
func _ask_jar(s: Dictionary) -> void:
	get_tree().paused = true
	game.sfx.play("ui")
	# jeder Krug ist ein anderer Mensch: anderes Bild, anderer Name; die Wahl steht jedes Mal klar da
	if not s.has("text"):
		s["text"] = [Worte.zieh("krug_bild"), "Auf dem Siegel steht ein Name aus Sandtor: %s. %s" % [Worte.zieh("krug_name"), Worte.zieh("krug_wahl")]]
	var txt: Array = s.text
	game.hud.show_dialog("SEELENKRUG", "Ein Herz schlägt darin", "", txt, [
		["Das Siegel lösen und das Herz freilassen", func(): _jar(s, true)],
		["Den Krug aufbrechen und plündern", func(): _jar(s, false)],
		["Stehen lassen", func(): get_tree().paused = false]])

func _jar(s: Dictionary, free: bool) -> void:
	get_tree().paused = false
	s.done = true
	s.vis.light.light_energy = 0.0
	s.vis.glow.emission_energy_multiplier = 0.0
	s.vis.lid.visible = false
	if s.get("herz_klang"):
		s.herz_klang.stop()   # das Pochen hört auf
	var n := Spiel.fall
	if free:
		_weigh(4.0)
		game.sfx.play_at("herz_frei", s.pos, 0.1)
		game.float_text(s.pos + Vector3(0, 1.2, 0), Worte.zieh("herz_frei"), Color(0.56, 0.89, 0.88), 1.2)
		_soul(s.pos)
		if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.12):
			game._level_up()
		if randf() < 0.35:
			game.drop("blood", s.pos)
		ba("frei%d" % count("krug", true), Worte.zieh("ba_frei"))
	else:
		_weigh(-5.0)
		s.vis.body.visible = false
		game.sfx.play_at("krug_bricht", s.pos, 0.1)
		game.shake = maxf(game.shake, 0.25)
		game.drop("shard", s.pos, 12 + 6 * n)
		game.drop("mat", s.pos, randi_range(1, 2), "staub")
		if randf() < 0.6:
			game.drop_item(s.pos, Spiel.new_item(n, 1))
		ba("raub%d" % count("krug", true), Worte.zieh("ba_raub"))
	_update_quests()

func _soul(pos: Vector3) -> void:
	# ein Licht steigt auf und verschwindet
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 1.0, 0.97)
	m.material_override = mat
	game.add_child(m)
	m.global_position = pos + Vector3(0, 1.4, 0)
	var tw := m.create_tween()
	tw.tween_property(m, "global_position:y", 9.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(m, "scale", Vector3.ONE * 0.2, 2.4)
	tw.tween_callback(m.queue_free)

# ---------------------------------------------------------------- Fundstück
func _ask_relic(s: Dictionary) -> void:
	get_tree().paused = true
	game.sfx.play("ui")
	var opts := []
	for i in 2:
		var w: Array = G.wahl[i]
		opts.append([w[0], func(): _relic(s, w)])
	opts.append(["Noch liegen lassen", func(): get_tree().paused = false])
	game.hud.show_dialog("FUNDSTÜCK", G.relikt, "", [G.fund], opts)

func _relic(s: Dictionary, w: Array) -> void:
	s.done = true
	relikt_done = true
	s.vis.item.visible = false
	s.vis.light.light_energy = 0.0
	Spiel.wahl[str(Stunden.hour_of(Spiel.fall))] = "maat" if w[2] > 0 else "isfet"
	var n := Spiel.fall
	var lohn := ""
	match w[3]:
		"segen":
			lohn = "Der Hüter dieser Stunde ist geschwächt."
		"xp":
			lohn = "Du gewinnst Erfahrung."
		"trank":
			Spiel.pots = Daten.POTS
			game.hero.hp = game.hero.max_hp
			lohn = "Du bist geheilt, und dein Rotbier ist aufgefüllt."
		"scherben":
			var sh := 60 + 25 * n
			Spiel.shards += sh
			lohn = "Du erhältst %d Scherben." % sh
		"beute":
			game.drop_item(s.pos, Spiel.new_item(n + 1, 2))
			lohn = "Etwas Seltenes fällt dir vor die Füße."
		"legende":
			var lid: String = game.hdef.legs.pick_random()
			game.drop_item(s.pos, Spiel.new_item(n + 1, 3, {"slot": Daten.leg(lid).slot, "leg": lid}))
			lohn = "Etwas Legendäres fällt dir vor die Füße."
	var q := quest("relikt")
	q.done = true
	q.text = "Entschieden: %s." % w[0]
	var vor := Geschichte.herz_name(Spiel.herz)
	Spiel.wiegen(w[2])
	game.hero.apply_stats()
	Spiel.speichern()
	dirty = true
	var herz := "Dein Herz wird %s. Es ist jetzt: %s." % ["leichter" if w[2] > 0 else "schwerer", Geschichte.herz_name(Spiel.herz)]
	if Geschichte.herz_name(Spiel.herz) != vor:
		herz += " " + Geschichte.herz_wirkung(Spiel.herz)
	game.sfx.play("victory" if w[2] > 0 else "boss_appear", 0.0, -8.0)
	var weiter := func():
		get_tree().paused = false
		if w[3] == "segen":
			_weaken_boss("%s wird es spüren." % game.boss.K.name)
		elif w[3] == "xp" and Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.6):
			game._level_up()
	game.hud.show_dialog("ENTSCHIEDEN", G.relikt, "", [w[1], lohn, herz], [["Weiter", weiter]])
	if not npc.is_empty():
		npc.vis.mark.visible = true

# ---------------------------------------------------------------- Gespräch mit der Figur der Stunde
func talk() -> void:
	if npc.is_empty() or game.hero.dead or game.hud.overlay != null:
		return
	get_tree().paused = true
	game.sfx.play("papyrus", 0.08)
	npc.vis.mark.visible = false
	if relikt_done:
		var maat: bool = Spiel.wahl.get(str(Stunden.hour_of(Spiel.fall)), "") == "maat"
		var line := "%s neigt den Kopf. „Das werde ich nicht vergessen. Hier unten vergisst man wenig.“" % G.wer if maat \
			else "%s sieht auf deine Laterne und dann weg. „Jeder trägt, was er trägt.“" % G.wer
		_page([line], [0, 1, 2, 3])
	elif talked:
		_page(["„%s“" % G.auftrag], [])
	else:
		var paras := []
		for g in G.gruss:
			paras.append("„%s“" % g)
		_page(paras, [])

func _page(paras: Array, asked: Array) -> void:
	var opts := []
	for i in G.fragen.size():
		if asked.has(i):
			continue
		var f: Array = G.fragen[i]
		var idx: int = i
		opts.append(["„%s“" % f[0], func(): _page(["„%s“" % f[1]], asked + [idx])])
	opts.append(["Gehen" if talked else "„Ich sehe, was ich tun kann.“", func(): _end_talk()])
	game.hud.show_dialog(G.titel.to_upper(), G.wer, "", paras, opts, G.get("bild", ""))

func _end_talk() -> void:
	get_tree().paused = false
	if not talked:
		talked = true
		var q := quest("relikt")
		if not q.is_empty() and not q.done:
			q.text = G.auftrag
		dirty = true
		Spiel.speichern()
