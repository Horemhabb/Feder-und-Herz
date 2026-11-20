class_name Leben extends Node
# Lebendige Welt (3.2): Leute, Kleintiere, Pflanzen und Fundstücke.
#   Leute    gehen Wege ab, bleiben stehen, setzen sich, sagen beim Vorbeigehen einen Satz. Sie sind unverwundbar und
#            fliehen, sobald in ihrer Nähe gekämpft wird; danach gehen sie ihrer Wege. Wer sie sind, bleibt offen,
#            bis die fünfte Stunde es auflöst. Etwa jede fünfte Person hat einen kleinen Auftrag.
#   Tiere    Skarabäen, Eidechsen, Wüstenmäuse, Falken am Himmel, Fische in den Becken, Esel und Fledermäuse in den
#            Gräbern. Sie sind aus Grundformen gebaut (je unter 400 Dreiecken), bewegen sich nach Formeln und weichen aus.
#   Pflanzen Papyrus und Lotos an den Becken, Grasbüschel im Freiland, Unkraut in Ruinen; als MultiMesh gezeichnet.
#   Funde    ab und zu ein typisches Stück aus dem alten Ägypten an einem stillen Ort; aufheben gibt Splitter und Erfahrung.
# Was weiter als 46 m vom Helden entfernt ist, steht still und wird nicht gezeichnet.

const WEIT := 46.0
const GEHEN := 1.25
const RENNEN := 3.6

# kleine Aufträge: jemand hat etwas verloren, der Held findet es an einem stillen Ort und bringt es zurück
const AUFTRAEGE := [
	{"wer": "Merit", "was": "Wäscherin", "ding": "Kamm aus Elfenbein", "akk": "den Kamm aus Elfenbein", "pron": "ihn", "art": "kamm",
		"bitte": "Mein Kamm. Er war von meiner Mutter. Ich hatte ihn eben noch, ich weiß es genau. Er muss hier irgendwo liegen.",
		"dank": "Du hast ihn! Sieh nur, die kleine Gazelle am Griff, die ist noch ganz. Ich danke dir."},
	{"wer": "Pentu", "was": "Wasserträger", "ding": "Schöpfkelle", "akk": "die Schöpfkelle", "pron": "sie", "art": "kelle",
		"bitte": "Ich bringe jeden Abend Wasser zum Tempel. Heute finde ich meine Kelle nicht, und der Weg ist so lang geworden.",
		"dank": "Meine Kelle. Jetzt kann ich wieder gehen. Ich weiß nicht mehr, wohin, aber ich kann gehen."},
	{"wer": "Henut", "was": "Großmutter", "ding": "Udjat-Amulett", "akk": "das Udjat-Amulett", "pron": "es", "art": "udjat",
		"bitte": "Das Auge des Horus, an einem Lederband. Mein Enkel hat es mir geschenkt. Ohne es fühle ich mich so nackt.",
		"dank": "Da ist es ja. Danke, Kind. Er sieht mich wieder an."},
	{"wer": "Ibi", "was": "Schreiberlehrling", "ding": "Binsenpinsel", "akk": "den Binsenpinsel", "pron": "ihn", "art": "pinsel",
		"bitte": "Mein Pinsel! Ohne ihn kann ich die Liste nicht fertig schreiben, und dann schlägt mich der Meister.",
		"dank": "Danke! Jetzt fehlt nur noch die Liste. Seltsam, ich weiß gar nicht mehr, was darauf stehen sollte."},
	{"wer": "Tabes", "was": "Sängerin", "ding": "Sistrum", "akk": "das Sistrum", "pron": "es", "art": "sistrum",
		"bitte": "Ich habe mein Sistrum verloren. Ohne seinen Klang finde ich die Lieder nicht mehr.",
		"dank": "Hörst du es? So klingt es, wenn die Göttin lächelt. Danke."},
	{"wer": "Nacht", "was": "Gärtner", "ding": "Beutel mit Lotossamen", "akk": "den Beutel mit Lotossamen", "pron": "ihn", "art": "samen",
		"bitte": "Ich wollte am Becken säen, aber der Beutel ist fort. Lotos braucht Zeit. Zeit habe ich ja jetzt.",
		"dank": "Die Samen. Wenn sie aufgehen, komm vorbei und sieh sie dir an."},
]

# Fundstücke: kleine Dinge, die man im alten Ägypten in Gräbern und Häusern fand
const FUNDE := [
	{"art": "uschebti", "name": "Uschebti", "text": "Eine kleine Dienerfigur aus blauer Fayence. Sie sollte im Jenseits die Feldarbeit tun."},
	{"art": "skarabaeus", "name": "Herzskarabäus", "text": "Ein Käfer aus grünem Stein. Auf der Unterseite steht der Spruch, der das Herz bittet, nicht gegen seinen Träger auszusagen."},
	{"art": "kanope", "name": "Kanopenkrug", "text": "Ein Krug mit dem Kopf eines Schakals als Deckel. Darin wurden Eingeweide bewahrt, damit der Leib vollständig bleibt."},
	{"art": "papyrus", "name": "Papyrusrolle", "text": "Eine versiegelte Rolle. Totenbuchsprüche, damit der Weg durch die Duat nicht vergessen wird."},
	{"art": "anch", "name": "Anch aus Bronze", "text": "Das Zeichen des Lebens. Götter tragen es, Menschen bekamen es als Segen mit."},
	{"art": "salbe", "name": "Salbgefäß", "text": "Ein kleines Gefäß aus Alabaster, der Duft ist nach all der Zeit noch zu ahnen."},
	{"art": "udjat", "name": "Udjat-Auge", "text": "Das heile Auge des Horus. Es schützt, heilt und macht ganz, was geteilt war."},
	{"art": "spiegel", "name": "Bronzespiegel", "text": "Rund wie die Sonne, mit einem Griff in Gestalt einer Papyrusdolde. Er zeigt dein Gesicht nur undeutlich."},
]

var game: Node
var leute: Array = []
var tiere: Array = []
var funde: Array = []
var frei: Array = []        # erreichbare Zellen fern vom Hüter (Vector2i)
var t := 0.0
var ruhig := 0.0            # Sprechblasen: nie zwei auf einmal
var stumm := false          # nur für Tests: Leute, Tiere und Funde ruhen und reagieren auf nichts

# ---------------------------------------------------------------- Aufbau
func bauen() -> void:
	var k: Karte = game.karte
	var reach := k.flood(int(k.start.x), int(k.start.y))
	var lair := Vector2(k.lair)
	for y in Karte.GH:
		for x in Karte.GW:
			var c := Vector2i(x, y)
			if reach[Karte.gi(x, y)] < 0 or game.astar.is_point_solid(c):
				continue
			if Vector2(x, y).distance_to(lair) < 9.0:
				continue
			frei.append(c)
	if frei.size() < 20:
		return
	var wenig: bool = game.low_gfx
	var stunde := Stunden.hour_of(Spiel.fall)
	var drinnen: bool = k.indoor
	# Leute: im Freiland mehr als in Gräbern
	var n_leute := randi_range(5, 8) if not drinnen else randi_range(3, 5)
	if wenig:
		n_leute = maxi(2, int(n_leute * 0.6))
	var auftraege := AUFTRAEGE.duplicate()
	auftraege.shuffle()
	for i in n_leute:
		var mit_auftrag := i % 5 == 2 and not auftraege.is_empty()
		_mensch(_zelle_fern(k.start, 4.0), auftraege.pop_back() if mit_auftrag else {})
	# Tiere je Landschaft (Skarabäen und Mäuse überall, Eidechsen wo es warm ist, Esel und Falken nur unter freiem Himmel,
	# Fledermäuse nur, wo ein Dach ist, Fische in jedem Becken)
	var art: String = k.kind if drinnen else ""
	var plan := {"skarabaeus": 6, "maus": 4}
	if art == "" or art == "ruin" or art == "glass":
		plan["eidechse"] = 4
	if not drinnen:
		plan["falke"] = 2
		plan["esel"] = 2 if stunde <= 4 else 1
	if drinnen:
		plan["fledermaus"] = 5
	for a in plan:
		var n: int = plan[a]
		if wenig:
			n = maxi(1, n / 2)
		for i in n:
			_tier(a, frei.pick_random())
	for p in k.pools:
		for i in (2 if wenig else 4):
			_fisch(Welt.cell_pos(p.p), float(p.r) * Karte.CELL)
	_pflanzen(k, drinnen, wenig)
	# Fundstücke an stillen Orten: weit vom Eingang, nicht neben einem Rudel
	var arten := FUNDE.duplicate()
	arten.shuffle()
	for i in (3 if drinnen else 4):
		var c := _zelle_still(k)
		if c != Vector2i(-1, -1):
			_fund(arten[i % arten.size()], Vector3(c.x * 2 + 1, 0, c.y * 2 + 1))

func _zelle_fern(von: Vector2, min_d: float) -> Vector2i:
	for i in 30:
		var c: Vector2i = frei.pick_random()
		if Vector2(c).distance_to(von) >= min_d:
			return c
	return frei.pick_random()

# eine stille Zelle: kein Rudel, kein Ort zum Handeln, nicht am Eingang
func _zelle_still(k: Karte) -> Vector2i:
	for i in 60:
		var c: Vector2i = frei.pick_random()
		var cv := Vector2(c) + Vector2(0.5, 0.5)
		if cv.distance_to(k.start) < 8.0:
			continue
		var ok := true
		for s in k.spots:
			if cv.distance_to(s.p) < 5.0:
				ok = false
				break
		for s in k.sites:
			if ok and cv.distance_to(s.p) < 3.0:
				ok = false
		for f in funde:
			if ok and Vector2(f.pos.x, f.pos.z).distance_to(cv * 2.0) < 16.0:
				ok = false
		if ok:
			return c
	return Vector2i(-1, -1)

static func _mitte(c: Vector2i) -> Vector3:
	return Vector3(c.x * 2 + 1, 0, c.y * 2 + 1)

# ---------------------------------------------------------------- Leute
func _mensch(c: Vector2i, auftrag: Dictionary) -> void:
	var modell: String = ["Mann", "Frau", "Alter", "Mann", "Frau"].pick_random()
	var n: Node3D = load("res://models/chars/%s.glb" % modell).instantiate()
	game.add_child(n)
	n.global_position = _mitte(c) + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	n.rotation.y = randf() * TAU
	n.scale = Vector3.ONE * randf_range(0.92, 1.04)
	for w in Klassen.WEAPONS:
		var wc := n.find_child(w, true, false)
		if wc:
			wc.visible = false
	# Tracht leicht abgetönt: nicht jeder trägt dasselbe Leinen
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # 4.0.1: Schatten der Leute kosteten zu viel
	_toenen(n, Color.from_hsv(randf_range(0.05, 0.13), randf_range(0.0, 0.25), randf_range(0.82, 1.0)))
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	if ap:
		for a in ["Idle", "Walking_A", "Running_A", "Sit_Floor_Idle", "Unarmed_Idle"]:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	var blase := Label3D.new()
	blase.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	blase.font_size = 34
	blase.outline_size = 9
	blase.outline_modulate = Color(0.05, 0.04, 0.03, 0.9)
	blase.modulate = Color(0.96, 0.92, 0.82)
	blase.pixel_size = 0.0055
	blase.width = 520
	blase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blase.visible = false
	blase.position = Vector3(0, 2.55, 0)
	n.add_child(blase)
	var p := {"n": n, "ap": ap, "zustand": "steht", "warte": randf_range(0.5, 6.0), "weg": PackedVector3Array(), "i": 0,
		"blase": blase, "blase_t": 0.0, "ruhe": randf_range(0.0, 4.0), "auftrag": auftrag, "tempo": GEHEN, "sitzt_gern": randf() < 0.35}
	if not auftrag.is_empty():
		# wer etwas verloren hat, wartet an einer Stelle und trägt ein grünes Anch über dem Kopf
		p.zustand = "wartet"
		auftrag = auftrag.duplicate()
		auftrag["stand"] = "neu"
		p.auftrag = auftrag
		p["mark"] = Deko.marke(n, 2.95, Color(0.62, 0.95, 0.5))
		game.orte.marken.append(p.mark)
		var nl := Label3D.new()
		nl.text = "%s, %s" % [auftrag.wer, auftrag.was]
		nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nl.font_size = 30
		nl.outline_size = 8
		nl.modulate = Color(0.75, 0.95, 0.65)
		nl.pixel_size = 0.0055
		nl.position = Vector3(0, 2.35, 0)
		nl.visible = false
		n.add_child(nl)
		p["schild"] = nl
		blase.position.y = 3.45   # über Name und Anch, nicht darauf
	_spiele(p, "Idle")
	leute.append(p)

func _toenen(n: Node, c: Color) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var m: Material = n.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = d.albedo_color * c
				n.set_surface_override_material(i, d)
	for ch in n.get_children():
		_toenen(ch, c)

func _spiele(p: Dictionary, a: String) -> void:
	var ap: AnimationPlayer = p.ap
	if ap and ap.has_animation(a) and ap.current_animation != a:
		ap.play(a, 0.3)

func _ziel(p: Dictionary, wohin: Vector3) -> bool:
	var n: Node3D = p.n
	var w: PackedVector3Array = game.find_path(n.global_position, wohin)
	if w.is_empty():
		return false
	p.weg = w
	p.i = 0
	return true

# Kampf in der Nähe: der nächste wache Gegner im Umkreis, sonst INF
func _gefahr(pos: Vector3) -> Vector3:
	var best := Vector3.INF
	var bd := 10.0
	for f in game.foes:
		if f.state != Foe.St.FIGHT:
			continue
		var d: float = f.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = f.global_position
	return best

func _leute_tick(d: float, hp: Vector3) -> void:
	ruhig -= d
	for p in leute:
		var n: Node3D = p.n
		var pos := n.global_position
		var dist := pos.distance_to(hp)
		var nah := dist < WEIT
		# gezeichnet nur bis 32 m: weiter weg sind sie nicht im Bild, kosten aber in den Schattenkarten
		n.visible = dist < 26.0
		var ap: AnimationPlayer = p.ap
		if ap:
			ap.active = nah
		if not nah:
			continue
		p.ruhe -= d
		var hat_auftrag: bool = not p.auftrag.is_empty()
		if p.has("schild"):
			p.schild.visible = dist < 11.0
		# Kampf in der Nähe: weg von hier, in eine Richtung, die vom Kampf wegführt
		var g := _gefahr(pos)
		if g != Vector3.INF and p.zustand != "flieht":
			var weg_von := (pos - g)
			weg_von.y = 0
			var ziel := pos + weg_von.normalized() * 14.0 if weg_von.length() > 0.1 else pos + Vector3(10, 0, 0)
			for versuch in 6:
				var c: Vector2i = frei.pick_random()
				var q := _mitte(c)
				if q.distance_to(g) > 14.0 and q.distance_to(pos) < 26.0:
					ziel = q
					break
			if _ziel(p, ziel):
				p.zustand = "flieht"
				p.tempo = RENNEN
				_spiele(p, "Running_A")
				p.blase.visible = false
		match p.zustand:
			"geht", "flieht":
				_folgen(p, d)
			"steht", "sitzt", "wartet":
				p.warte -= d
				# wer steht, schaut dem Helden nach, wenn er vorbeigeht
				if dist < 4.5:
					var zu := hp - pos
					n.rotation.y = lerp_angle(n.rotation.y, atan2(zu.x, zu.z), 1.0 - exp(-d * 4.0))
				if p.warte <= 0.0 and p.zustand != "wartet":
					if _ziel(p, _mitte(_zelle_fern(Vector2(pos.x, pos.z) / 2.0, 3.0))):
						p.zustand = "geht"
						p.tempo = GEHEN
						_spiele(p, "Walking_A")
					else:
						p.warte = 3.0
		# Ausweichen: läuft der Held in jemanden hinein, tritt der zur Seite
		if dist < 0.95 and p.zustand != "flieht":
			var weg := pos - hp
			weg.y = 0
			if weg.length() < 0.05:
				weg = Vector3(1, 0, 0)
			n.global_position += weg.normalized() * d * 2.6
		# ein Satz im Vorbeigehen (nie zwei Sprechblasen zugleich)
		var b: Label3D = p.blase
		if b.visible:
			p.blase_t -= d
			if p.blase_t <= 0.0 or dist > 9.0:
				b.visible = false
		elif dist < 4.2 and p.ruhe <= 0.0 and ruhig <= 0.0 and p.zustand != "flieht" and game.hud.overlay == null:
			if hat_auftrag and p.auftrag.stand != "fertig":
				var frage: String = "Hast du %s gefunden? %s?" % [p.auftrag.pron, String(p.auftrag.akk).substr(0, 1).to_upper() + String(p.auftrag.akk).substr(1)]
				if p.auftrag.stand == "gefunden":
					frage = "Du hältst etwas in der Hand … ist das meins?"
				elif p.auftrag.stand == "neu":
					frage = "Bitte … kannst du mir helfen?"
				b.text = "„%s“" % frage + ("" if game.touch else "\n[E]")
			else:
				b.text = "„%s“" % Worte.zieh("leute_satz")
			b.visible = true
			p.blase_t = 4.5
			p.ruhe = randf_range(16.0, 28.0)
			ruhig = 2.5

func _folgen(p: Dictionary, d: float) -> void:
	var n: Node3D = p.n
	var w: PackedVector3Array = p.weg
	if p.i >= w.size():
		_angekommen(p)
		return
	var ziel := w[p.i]
	var zu := ziel - n.global_position
	zu.y = 0
	if zu.length() < 0.35:
		p.i += 1
		# abkürzen, wo die Sicht frei ist: kein Zickzack von Zelle zu Zelle
		var sprung := 0
		while p.i + 1 < w.size() and sprung < 3 and game.walkable(n.global_position, w[p.i + 1]):
			p.i += 1
			sprung += 1
		return
	var schritt: float = minf(zu.length(), p.tempo * d)
	n.global_position += zu.normalized() * schritt
	n.rotation.y = lerp_angle(n.rotation.y, atan2(zu.x, zu.z), 1.0 - exp(-d * 8.0))

func _angekommen(p: Dictionary) -> void:
	if p.zustand == "flieht":
		# erst einmal Luft holen; ist es ruhig, geht es weiter wie zuvor
		p.zustand = "steht"
		p.warte = randf_range(4.0, 7.0)
		p.tempo = GEHEN
		_spiele(p, "Idle")
		if not p.auftrag.is_empty():
			p.zustand = "wartet"
		return
	if p.sitzt_gern and randf() < 0.5:
		p.zustand = "sitzt"
		p.warte = randf_range(10.0, 20.0)
		_spiele(p, "Sit_Floor_Idle")
	else:
		p.zustand = "steht"
		p.warte = randf_range(3.0, 9.0)
		_spiele(p, "Idle" if randf() < 0.7 else "Interact")

# ---------------------------------------------------------------- Aufträge
func naechster_auftrag() -> Dictionary:
	if stumm:
		return {}
	var hp: Vector3 = game.hero.global_position
	for p in leute:
		if not p.auftrag.is_empty() and p.auftrag.stand != "fertig" and p.n.global_position.distance_to(hp) < 3.6:
			return p
	return {}

func auftrag_reden(p: Dictionary) -> void:
	if p.is_empty() or game.hero.dead or game.hud.overlay != null:
		return
	var a: Dictionary = p.auftrag
	get_tree().paused = true
	game.sfx.play("ui")
	p.blase.visible = false
	var zu := func(): get_tree().paused = false
	var titel := "%s, %s" % [a.wer, a.was]
	match a.stand:
		"neu":
			var ja := func():
				get_tree().paused = false
				a.stand = "gefragt"
				var c := _zelle_still(game.karte)
				if c == Vector2i(-1, -1):
					c = frei.pick_random()
				_fund({"art": a.art, "name": a.ding, "text": "", "fuer": p}, _mitte(c))
				game.orte.quests.append({"id": "bitte_%s" % a.art, "titel": "%ss %s" % [a.wer, a.ding], "text": "Finde %s und bring %s %s." % [a.akk, a.pron, a.wer], "done": false})
				game.orte.dirty = true
			game.hud.show_dialog("EINE BITTE", titel, "", ["„%s“" % a.bitte], [["„Ich halte die Augen offen.“", ja], ["„Jetzt nicht.“", zu]])
		"gefragt":
			game.hud.show_dialog("EINE BITTE", titel, "", ["„Hast du %s gefunden? %s muss irgendwo hier sein, an einem stillen Ort.“" % [a.pron, {"ihn": "Er", "sie": "Sie", "es": "Es"}[a.pron]]], [["„Noch nicht.“", zu]])
		"gefunden":
			var lohn := func():
				get_tree().paused = false
				a.stand = "fertig"
				if p.has("mark"):
					p.mark.visible = false
				var q: Dictionary = game.orte.quest("bitte_%s" % a.art)
				if not q.is_empty():
					q.done = true
					q.text = "%s ist froh." % a.wer
				game.orte.dirty = true
				var fall := Spiel.fall
				game.drop("shard", p.n.global_position + Vector3(0.6, 0, 0.6), 12 + 6 * fall)
				if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.12):
					game._level_up()
				game.orte._weigh(1.5)
				game.sfx.play("victory")
				p.zustand = "steht"
				p.warte = 4.0
				_spiele(p, "Cheer")
			game.hud.show_dialog("EINE BITTE", titel, "", ["„%s“" % a.dank], [["Gern geschehen.", lohn]])
		_:
			game.hud.show_dialog("", titel, "", ["%s nickt dir zu." % a.wer], [["Gehen", zu]])

# ---------------------------------------------------------------- Fundstücke
func _fund(f: Dictionary, pos: Vector3) -> void:
	var n := Node3D.new()
	game.add_child(n)
	n.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	var mi := MeshInstance3D.new()
	mi.mesh = _fund_mesh(String(f.art))
	n.add_child(mi)
	mi.rotation.y = randf() * TAU
	# ein Glanz, der langsam pulsiert: so findet man es auch im Halbdunkel
	var glanz := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	glanz.mesh = q
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.albedo_texture = _stern_tex()
	gm.albedo_color = Color(1.0, 0.85, 0.5, 0.8)
	glanz.material_override = gm
	glanz.position = Vector3(0, 0.45, 0)
	n.add_child(glanz)
	var e := f.duplicate()
	e["n"] = n
	e["pos"] = n.global_position
	e["glanz"] = gm
	e["done"] = false
	e["v"] = randf() * TAU
	funde.append(e)

static var _stern: ImageTexture
static func _stern_tex() -> ImageTexture:
	if _stern:
		return _stern
	var im := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var dx := absf(x - 15.5) / 15.5
			var dy := absf(y - 15.5) / 15.5
			var a := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0)
			var strahl := maxf(clampf(1.0 - dx * 6.0, 0.0, 1.0) * (1.0 - dy), clampf(1.0 - dy * 6.0, 0.0, 1.0) * (1.0 - dx))
			im.set_pixel(x, y, Color(1, 1, 1, clampf(a * a * 0.9 + strahl * 0.8, 0.0, 1.0)))
	_stern = ImageTexture.create_from_image(im)
	return _stern

func _funde_tick(d: float, hp: Vector3) -> void:
	for f in funde:
		if f.done:
			continue
		var n: Node3D = f.n
		var dist := n.global_position.distance_to(hp)
		n.visible = dist < WEIT
		if not n.visible:
			continue
		var gm: StandardMaterial3D = f.glanz
		gm.albedo_color.a = 0.35 + 0.45 * pow(maxf(0.0, sin(t * 2.2 + f.v)), 3.0)
		if dist < 1.4 and not game.hero.dead:
			_aufheben(f)

func _aufheben(f: Dictionary) -> void:
	f.done = true
	var n: Node3D = f.n
	var tw := create_tween()
	tw.tween_property(n, "position:y", n.position.y + 0.8, 0.5)
	tw.tween_callback(n.queue_free)
	game.sfx.play("pickup" if game.sfx._stream("pickup") else "ui")
	if f.has("fuer"):
		# das verlorene Stück eines Auftrags
		var p: Dictionary = f.fuer
		p.auftrag.stand = "gefunden"
		var q: Dictionary = game.orte.quest("bitte_%s" % p.auftrag.art)
		if not q.is_empty():
			q.text = "Bring %s %s." % [p.auftrag.wer, p.auftrag.akk]
		game.orte.dirty = true
		game.hud.toast("%s gefunden. %s wartet darauf." % [f.name, p.auftrag.wer], 3.5)
		return
	var neu := not Spiel.gesehen("fund_" + String(f.art))
	Spiel.merke("fund_" + String(f.art))
	game.hud.toast_item(-1, f.name, f.text, Color(0.95, 0.82, 0.5), 6.0 if neu else 3.5)
	game.drop("shard", f.pos, 4 + 2 * Spiel.fall)
	if Spiel.xp_gain(Daten.xp_need(Spiel.lvl) * 0.04):
		game._level_up()

func _fund_mesh(art: String) -> ArrayMesh:
	var key := "fund_" + art
	if Deko.cache.has(key):
		return Deko.cache[key]
	var st := Deko._begin()
	var col := Color(0.78, 0.62, 0.32)
	var glanz := 0.3
	match art:
		"uschebti":
			_ei(st, Vector3(0, 0.16, 0), Vector3(0.06, 0.15, 0.05))
			_ei(st, Vector3(0, 0.33, 0), Vector3(0.05, 0.05, 0.05))
			col = Color(0.2, 0.5, 0.72)
		"skarabaeus", "udjat":
			_ei(st, Vector3(0, 0.05, 0), Vector3(0.11, 0.05, 0.14))
			col = Color(0.18, 0.52, 0.38) if art == "skarabaeus" else Color(0.15, 0.3, 0.75)
			glanz = 0.6
		"kanope":
			_ei(st, Vector3(0, 0.17, 0), Vector3(0.11, 0.17, 0.11))
			_ei(st, Vector3(0, 0.37, 0), Vector3(0.08, 0.06, 0.08))
			_ei(st, Vector3(0, 0.42, 0.06), Vector3(0.03, 0.03, 0.06))
			col = Color(0.88, 0.84, 0.74)
		"papyrus":
			_ei(st, Vector3(0, 0.06, 0), Vector3(0.22, 0.055, 0.055))
			col = Color(0.86, 0.78, 0.56)
		"anch", "kamm", "kelle", "pinsel", "sistrum":
			Deko.box(st, Vector3(0.06, 0.22, 0.04), Vector3(0, 0.02, 0))
			Deko.box(st, Vector3(0.2, 0.05, 0.04), Vector3(0, 0.2, 0))
			_ei(st, Vector3(0, 0.32, 0), Vector3(0.06, 0.08, 0.025))
			col = Color(0.72, 0.5, 0.24)
			glanz = 0.6
		"salbe", "samen":
			_ei(st, Vector3(0, 0.12, 0), Vector3(0.1, 0.12, 0.1))
			_ei(st, Vector3(0, 0.26, 0), Vector3(0.05, 0.03, 0.05))
			col = Color(0.92, 0.88, 0.8) if art == "salbe" else Color(0.6, 0.45, 0.28)
		"spiegel":
			_ei(st, Vector3(0, 0.26, 0), Vector3(0.13, 0.13, 0.02))
			Deko.box(st, Vector3(0.04, 0.16, 0.04), Vector3(0, 0.0, 0))
			col = Color(0.8, 0.6, 0.3)
			glanz = 0.8
		_:
			_ei(st, Vector3(0, 0.1, 0), Vector3(0.1, 0.1, 0.1))
	var m := Deko.mat("fundstoff_" + art, col, 0.45, col, 0.25, glanz)
	var am := Deko._commit([[st, m]])
	Deko.cache[key] = am
	return am

# Ellipsoid in einen SurfaceTool (Mittelpunkt, Halbachsen), mit Normalen
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

# ---------------------------------------------------------------- Tiere
func _tier_mesh(art: String) -> Array:
	# gibt [Körper, Flügel (oder null)] zurück, beide einmal gebaut und geteilt
	var key := "tier_" + art
	if Deko.cache.has(key):
		return Deko.cache[key]
	var st := Deko._begin()
	var fl: SurfaceTool = null
	var col := Color.WHITE
	var rough := 0.8
	var metal := 0.0
	match art:
		"skarabaeus":
			_ei(st, Vector3(0, 0.05, -0.01), Vector3(0.075, 0.05, 0.1))
			_ei(st, Vector3(0, 0.045, 0.09), Vector3(0.045, 0.03, 0.035), 6, 4)
			col = Color(0.08, 0.2, 0.22)
			rough = 0.3
			metal = 0.7
		"maus":
			_ei(st, Vector3(0, 0.06, 0), Vector3(0.06, 0.055, 0.1))
			_ei(st, Vector3(0, 0.07, 0.1), Vector3(0.035, 0.035, 0.05), 6, 4)
			for sx in [-1.0, 1.0]:
				_ei(st, Vector3(sx * 0.03, 0.11, 0.08), Vector3(0.022, 0.025, 0.008), 6, 3)
			_ei(st, Vector3(0, 0.03, -0.17), Vector3(0.008, 0.008, 0.09), 4, 3)
			col = Color(0.72, 0.58, 0.42)
		"eidechse":
			_ei(st, Vector3(0, 0.04, 0), Vector3(0.05, 0.03, 0.14))
			_ei(st, Vector3(0, 0.045, 0.16), Vector3(0.035, 0.025, 0.06), 6, 4)
			_ei(st, Vector3(0, 0.03, -0.24), Vector3(0.02, 0.015, 0.16), 6, 3)
			for sx in [-1.0, 1.0]:
				for sz in [-0.07, 0.08]:
					_ei(st, Vector3(sx * 0.07, 0.02, sz), Vector3(0.035, 0.012, 0.015), 4, 3)
			col = Color(0.55, 0.5, 0.3)
		"falke":
			_ei(st, Vector3(0, 0, 0), Vector3(0.12, 0.1, 0.3))
			_ei(st, Vector3(0, 0.04, 0.3), Vector3(0.07, 0.07, 0.08), 6, 4)
			Deko.box(st, Vector3(0.18, 0.02, 0.2), Vector3(0, -0.01, -0.38))
			fl = Deko._begin()
			Deko._quad(fl, Vector3(0, 0, 0.12), Vector3(0.7, 0, 0.0), Vector3(0.75, 0, -0.16), Vector3(0, 0, -0.16))
			Deko._quad(fl, Vector3(0, 0, -0.16), Vector3(0.75, 0, -0.16), Vector3(0.7, 0, 0.0), Vector3(0, 0, 0.12))
			col = Color(0.35, 0.26, 0.18)
		"fledermaus":
			_ei(st, Vector3(0, 0, 0), Vector3(0.05, 0.05, 0.08), 6, 4)
			for sx in [-1.0, 1.0]:
				_ei(st, Vector3(sx * 0.025, 0.05, 0.05), Vector3(0.012, 0.03, 0.01), 4, 3)
			fl = Deko._begin()
			Deko._quad(fl, Vector3(0, 0, 0.05), Vector3(0.28, 0, 0.02), Vector3(0.22, 0, -0.07), Vector3(0, 0, -0.04))
			Deko._quad(fl, Vector3(0, 0, -0.04), Vector3(0.22, 0, -0.07), Vector3(0.28, 0, 0.02), Vector3(0, 0, 0.05))
			col = Color(0.1, 0.08, 0.09)
		"fisch":
			_ei(st, Vector3(0, 0, 0), Vector3(0.05, 0.03, 0.15), 6, 4)
			Deko._quad(st, Vector3(0, 0, -0.13), Vector3(0, 0.05, -0.22), Vector3(0, -0.05, -0.22), Vector3(0, 0, -0.13))
			col = Color(0.85, 0.42, 0.15)
			rough = 0.4
		"esel":
			_ei(st, Vector3(0, 0.78, 0), Vector3(0.24, 0.24, 0.48), 10, 6)
			_ei(st, Vector3(0, 1.0, 0.45), Vector3(0.1, 0.22, 0.12), 8, 5)        # Hals
			_ei(st, Vector3(0, 1.12, 0.66), Vector3(0.1, 0.1, 0.2), 8, 5)          # Kopf
			for sx in [-1.0, 1.0]:
				_ei(st, Vector3(sx * 0.07, 1.33, 0.56), Vector3(0.03, 0.14, 0.04), 6, 4)   # Ohren
			_ei(st, Vector3(0, 0.82, -0.5), Vector3(0.025, 0.2, 0.025), 4, 3)      # Schwanz
			for sx in [-1.0, 1.0]:
				for sz in [-0.3, 0.3]:
					_ei(st, Vector3(sx * 0.13, 0.3, sz), Vector3(0.05, 0.32, 0.05), 6, 4)
			col = Color(0.42, 0.37, 0.33)
	var m := Deko.mat("tierstoff_" + art, col, rough, Color.BLACK, 0.0, metal)
	var koerper := Deko._commit([[st, m]])
	var fluegel: ArrayMesh = null
	if fl:
		fluegel = Deko._commit([[fl, m]])
	Deko.cache[key] = [koerper, fluegel]
	return Deko.cache[key]

func _tier(art: String, c: Vector2i) -> void:
	var n := Node3D.new()
	game.add_child(n)
	var ms := _tier_mesh(art)
	var body := MeshInstance3D.new()
	body.mesh = ms[0]
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if art != "esel" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	n.add_child(body)
	var fluegel := []
	if ms[1]:
		for sx in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			w.mesh = ms[1]
			w.scale = Vector3(sx, 1, 1)
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(w)
			fluegel.append(w)
	var heim := _mitte(c) + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
	n.global_position = heim
	n.rotation.y = randf() * TAU
	var e := {"n": n, "art": art, "heim": heim, "ziel": heim, "warte": randf_range(0.5, 4.0), "flieht": 0.0, "v": randf() * TAU,
		"fluegel": fluegel, "r": randf_range(8.0, 16.0), "h": randf_range(3.0, 4.2)}
	match art:
		"falke":
			e.h = randf_range(14.0, 20.0)
			e.r = randf_range(10.0, 20.0)
			n.scale = Vector3.ONE * 1.3
		"fledermaus":
			e.r = randf_range(2.0, 4.0)
		"maus", "eidechse", "skarabaeus":
			n.scale = Vector3.ONE * 1.45   # sonst sind sie aus der Höhe der Kamera kaum zu sehen
		"esel":
			n.scale = Vector3.ONE * 1.1
	tiere.append(e)

func _fisch(c: Vector3, r: float) -> void:
	var n := Node3D.new()
	game.add_child(n)
	var body := MeshInstance3D.new()
	body.mesh = _tier_mesh("fisch")[0]
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(body)
	n.global_position = c + Vector3(0, 0.1, 0)
	tiere.append({"n": n, "art": "fisch", "heim": c, "r": randf_range(0.4, maxf(0.5, r - 0.4)), "v": randf() * TAU,
		"tempo": randf_range(0.4, 0.8) * (1.0 if randf() < 0.5 else -1.0), "sprung": randf_range(6.0, 20.0), "fluegel": []})

func _tiere_tick(d: float, hp: Vector3) -> void:
	for e in tiere:
		var n: Node3D = e.n
		var art: String = e.art
		var heim: Vector3 = e.heim
		if art != "falke":
			var nah := heim.distance_to(hp) < WEIT
			n.visible = nah
			if not nah:
				continue
		e.v += d
		match art:
			"falke":
				# kreist hoch über der Stunde, mit langen Gleitphasen
				var a: float = e.v * (6.0 / e.r) * 0.35
				var mitte := Vector3(hp.x, 0, hp.z).lerp(heim, 0.6)
				n.global_position = mitte + Vector3(cos(a) * e.r, e.h + sin(e.v * 0.4) * 1.5, sin(a) * e.r)
				n.rotation = Vector3(0, -a, 0.35)
				_flattern(e, 0.15 if fmod(e.v, 7.0) < 5.0 else 9.0, 0.35)
			"fledermaus":
				# zickzack in Schleifen unter der Decke
				var a: float = e.v * 2.4
				var p: Vector3 = heim + Vector3(cos(a) * e.r + sin(e.v * 5.3) * 0.5, e.h + sin(e.v * 3.1) * 0.4, sin(a * 1.3) * e.r)
				var zu := p - n.global_position
				n.global_position = p
				if zu.length() > 0.001:
					n.rotation.y = atan2(zu.x, zu.z)
				_flattern(e, 20.0, 0.9)
			"fisch":
				var a: float = e.v * e.tempo
				var p: Vector3 = heim + Vector3(cos(a) * e.r, 0.1, sin(a) * e.r)
				e.sprung -= d
				if e.sprung < 0.0:
					# ab und zu springt einer
					p.y += sin(clampf(-e.sprung / 0.6, 0.0, 1.0) * PI) * 0.35
					if e.sprung < -0.6:
						e.sprung = randf_range(8.0, 24.0)
				var zu := Vector3(-sin(a), 0, cos(a)) * signf(e.tempo)
				n.global_position = p
				n.rotation.y = atan2(zu.x, zu.z)
			_:
				_laufen(e, d, hp)

func _flattern(e: Dictionary, f: float, w: float) -> void:
	var fl: Array = e.fluegel
	if fl.size() < 2:
		return
	var a := sin(e.v * f) * w
	fl[0].rotation.z = a
	fl[1].rotation.z = -a

# Bodentiere: kurze Wege um ihren Platz, Pausen dazwischen; kommt der Held zu nah, rennen sie davon
func _laufen(e: Dictionary, d: float, hp: Vector3) -> void:
	var n: Node3D = e.n
	var art: String = e.art
	var pos := n.global_position
	var scheu := {"skarabaeus": 1.6, "maus": 3.2, "eidechse": 2.8, "esel": 1.8}.get(art, 2.0) as float
	var tempo := {"skarabaeus": 0.25, "maus": 1.4, "eidechse": 1.8, "esel": 0.7}.get(art, 1.0) as float
	var nah := pos.distance_to(hp)
	if nah < scheu and e.flieht <= 0.0:
		var weg := pos - hp
		weg.y = 0
		e.ziel = pos + weg.normalized() * (scheu + 2.5)
		e.flieht = 1.2
		e.warte = 0.0
	e.flieht -= d
	var schnell: float = tempo * (2.6 if e.flieht > 0.0 else 1.0)
	if art == "esel":
		schnell = tempo
	var zu: Vector3 = e.ziel - pos
	zu.y = 0
	if zu.length() < 0.08:
		e.warte -= d
		if art == "esel":
			# grasen: der Kopf geht langsam auf und ab
			n.rotation.x = sin(e.v * 0.8) * 0.04
		if e.warte <= 0.0:
			var w := randf() * TAU
			var r := randf_range(0.6, 3.0 if art != "skarabaeus" else 1.2)
			var q: Vector3 = e.heim + Vector3(cos(w), 0, sin(w)) * r
			if game.astar.is_point_solid(game._sub(q)):
				q = e.heim
			e.ziel = q
			e.warte = randf_range(1.5, 6.0) if art != "esel" else randf_range(6.0, 14.0)
		return
	var neu := pos + zu.normalized() * minf(zu.length(), schnell * d)
	if game.astar.is_point_solid(game._sub(neu)):
		e.ziel = e.heim
		return
	# Eidechsen huschen in Stößen, Mäuse hüpfen ein wenig, Skarabäen schaukeln
	if art == "eidechse" and fmod(e.v, 0.9) > 0.55 and e.flieht <= 0.0:
		return
	n.global_position = neu
	n.rotation.y = lerp_angle(n.rotation.y, atan2(zu.x, zu.z), 1.0 - exp(-d * 10.0))
	n.position.y = absf(sin(e.v * 14.0)) * 0.025 if art == "maus" else 0.0

# ---------------------------------------------------------------- Pflanzen
func _pflanzen(k: Karte, drinnen: bool, wenig: bool) -> void:
	var halme := []     # Transform3D für Papyrus
	var bueschel := []  # Transform3D für Grasbüschel
	var lotos := []
	for p in k.pools:
		var c := Welt.cell_pos(p.p)
		var r: float = float(p.r) * Karte.CELL
		var n := 7 if wenig else 14
		for i in n:
			var a := randf() * TAU
			var rr := r + randf_range(0.55, 1.1)
			var at := c + Vector3(cos(a) * rr, 0, sin(a) * rr)
			halme.append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.7, 1.25)), at))
		for i in (3 if wenig else 6):
			var a := randf() * TAU
			var rr := randf_range(0.2, r - 0.3)
			lotos.append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.8, 1.2)), c + Vector3(cos(a) * rr, 0.09, sin(a) * rr)))
	var plaetze := 0 if drinnen and k.kind != "ruin" else (40 if not wenig else 18)
	if drinnen and k.kind == "glass":
		plaetze = 0
	for i in plaetze:
		var cz: Vector2i = frei.pick_random()
		var at := _mitte(cz) + Vector3(randf_range(-0.9, 0.9), 0, randf_range(-0.9, 0.9))
		bueschel.append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.6, 1.3)), at))
	if not halme.is_empty():
		_multi(_papyrus_mesh(), halme)
	if not bueschel.is_empty():
		_multi(_gras_mesh(not drinnen), bueschel)
	if not lotos.is_empty():
		_multi(_lotos_mesh(), lotos)

func _multi(m: Mesh, xf: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.add_child(mi)

static func _halm(st: SurfaceTool, fuss: Vector3, kopf: Vector3, b: float) -> void:
	# ein flacher Halm aus zwei gekreuzten Streifen
	for q in [Vector3(b, 0, 0), Vector3(0, 0, b)]:
		st.set_normal(Vector3.UP)
		Deko._quad(st, fuss - q, fuss + q, kopf + q * 0.3, kopf - q * 0.3)
		Deko._quad(st, kopf - q * 0.3, kopf + q * 0.3, fuss + q, fuss - q)

func _papyrus_mesh() -> ArrayMesh:
	if Deko.cache.has("papyrus_pflanze"):
		return Deko.cache["papyrus_pflanze"]
	var st := Deko._begin()
	var dolde := Deko._begin()
	for i in 5:
		var a := TAU * i / 5.0
		var neig := Vector3(cos(a), 0, sin(a)) * randf_range(0.1, 0.3)
		var h := randf_range(1.2, 1.9)
		var kopf := Vector3(0, h, 0) + neig
		_halm(st, Vector3(cos(a), 0, sin(a)) * 0.06, kopf, 0.02)
		# die Dolde: ein Büschel feiner Strahlen nach allen Seiten
		for j in 6:
			var b := TAU * j / 6.0 + a
			var aus := Vector3(cos(b) * 0.2, 0.12, sin(b) * 0.2)
			_halm(dolde, kopf, kopf + aus, 0.012)
	var m := Deko._commit([[st, Deko.mat("papyrus_halm", Color(0.32, 0.5, 0.2), 0.9)], [dolde, Deko.mat("papyrus_dolde", Color(0.52, 0.66, 0.28), 0.9)]])
	for i in m.get_surface_count():
		var sm: StandardMaterial3D = m.surface_get_material(i)
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	Deko.cache["papyrus_pflanze"] = m
	return m

func _gras_mesh(gruen: bool) -> ArrayMesh:
	var key := "gras_%s" % gruen
	if Deko.cache.has(key):
		return Deko.cache[key]
	var st := Deko._begin()
	for i in 7:
		var a := TAU * i / 7.0 + randf() * 0.4
		var neig := Vector3(cos(a), 0, sin(a)) * randf_range(0.12, 0.28)
		_halm(st, Vector3(cos(a), 0, sin(a)) * 0.04, Vector3(0, randf_range(0.28, 0.5), 0) + neig, 0.025)
	var m := Deko._commit([[st, Deko.mat(key, Color(0.36, 0.4, 0.2) if gruen else Color(0.42, 0.38, 0.25), 0.95)]])
	(m.surface_get_material(0) as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	Deko.cache[key] = m
	return m

func _lotos_mesh() -> ArrayMesh:
	if Deko.cache.has("lotos"):
		return Deko.cache["lotos"]
	var blatt := Deko._begin()
	_ei(blatt, Vector3.ZERO, Vector3(0.28, 0.01, 0.28), 10, 2)
	var bluete := Deko._begin()
	for i in 6:
		var a := TAU * i / 6.0
		_ei(bluete, Vector3(cos(a) * 0.05, 0.07, sin(a) * 0.05), Vector3(0.03, 0.07, 0.03), 5, 3)
	var m := Deko._commit([[blatt, Deko.mat("lotos_blatt", Color(0.22, 0.42, 0.22), 0.6)], [bluete, Deko.mat("lotos_bluete", Color(0.75, 0.82, 1.0), 0.5, Color(0.4, 0.5, 0.9), 0.4)]])
	Deko.cache["lotos"] = m
	return m

# ---------------------------------------------------------------- jeden Physik-Schritt
func tick(d: float) -> void:
	if game == null or game.hero == null or stumm:
		return
	t += d
	var hp: Vector3 = game.hero.global_position
	_leute_tick(d, hp)
	_tiere_tick(d, hp)
	_funde_tick(d, hp)
