class_name Leben extends Node
# Lebendige Welt (3.2): Leute, Kleintiere, Pflanzen und Fundstücke.
#   Leute    gehen Wege ab, bleiben stehen, setzen sich, sagen beim Vorbeigehen einen Satz. Sie sind unverwundbar und
#            fliehen, sobald in ihrer Nähe gekämpft wird; danach gehen sie ihrer Wege. Wer sie sind, bleibt offen,
#            bis die fünfte Stunde es auflöst. Etwa jede fünfte Person hat einen kleinen Auftrag.
#   Tiere    Skarabäen (manche mit Kugel), Schwarzkäfer, Dornschwanzagamen, Rennmäuse, Falken am Himmel, Ibisse und
#            Fischschwärme an den Becken, Esel, Fledermäuse in den Gräbern (4.3: tiere.gd, tier.gd, tiere.gdshader).
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
	# Tiere je Landschaft (4.3): Skarabäen und Mäuse überall, wo Sand ist; in Gräbern Schwarzkäfer und Fledermäuse;
	# Eidechsen, wo es warm ist; Falken und Esel nur unter freiem Himmel; Fische und (draußen) ein Ibis an jedem Becken.
	var art: String = k.kind if drinnen else ""
	var plan := {"maus": 4}
	if drinnen and art != "ruin":
		plan["schwarzkaefer"] = 5
	else:
		plan["skarabaeus"] = 6
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
	var ibisse := 0
	for p in k.pools:
		_becken(Welt.cell_pos(p.p), float(p.r) * Karte.CELL, 3 if wenig else 5, not drinnen and ibisse < 2)
		ibisse += 1
	# die Tiere der Aufträge (orte.gd › Deko.such) gehören auch hierher: dann leben sie
	for s in game.orte.sites:
		if s.kind == "such" and s.vis.has("tierobj"):
			tiere.append(s.vis.tierobj)
	_schatten_bauen()
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
# wer mit welcher Bitte kommt, hat eine passende Gestalt (4.3)
const BITTE_MODELL := {"kamm": "Frau", "kelle": "Mann", "udjat": "Alter", "pinsel": "Mann", "sistrum": "Frau", "samen": "Mann"}

func _mensch(c: Vector2i, auftrag: Dictionary) -> void:
	var modell: String = ["Mann", "Frau", "Alter", "Mann", "Frau"].pick_random()
	if not auftrag.is_empty():
		modell = BITTE_MODELL.get(auftrag.art, modell)
	var kind := auftrag.is_empty() and randf() < 0.18
	if kind:
		modell = ["Mann", "Frau"].pick_random()
	var n: Node3D = load("res://models/chars/%s.glb" % modell).instantiate()
	game.add_child(n)
	n.global_position = _mitte(c) + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	n.rotation.y = randf() * TAU
	n.scale = Vector3.ONE * (randf_range(0.92, 1.04) if not kind else randf_range(0.6, 0.68))
	for w in Klassen.WEAPONS:
		var wc := n.find_child(w, true, false)
		if wc:
			wc.visible = false
	# Zubehör: was sie tragen, verrät, wer sie sind; Kinder tragen die Jugendlocke
	var dinge: Array = Leute.NACH_BITTE.get(auftrag.get("art", ""), Leute.ALLTAG.pick_random()) if not kind else ["locke"]
	Leute.ausstatten(n, dinge)
	var koerper := Leute.beleben(n, game, {"atem": 0.028 if modell == "Alter" else 0.02, "brust": 0.07 if modell == "Alter" else 0.02})
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
	if ap:
		Bewegungen.ergaenzen(ap, n.find_child("Skeleton3D", true, false), "gemeinsam")
	var p := {"n": n, "ap": ap, "koerper": koerper, "zustand": "steht", "warte": randf_range(0.5, 6.0), "weg": PackedVector3Array(), "i": 0,
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
		if p.koerper:
			p.koerper.active = dist < 18.0
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
			# beim Sprechen eine Geste: nicken, die Hände heben
			if p.zustand in ["steht", "wartet"] and ap and ap.has_animation("gemeinsam/Jubel"):
				ap.play("gemeinsam/Jubel", 0.25)
				ap.queue("Idle")
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
		# stehen, oder etwas tun: auflesen, hantieren; selten ein Tanzschritt (es ist die Nacht der Götter)
		p.zustand = "steht"
		p.warte = randf_range(3.0, 9.0)
		var r := randf()
		var tat := "Idle" if r < 0.5 else ("Interact" if r < 0.72 else ("PickUp" if r < 0.92 else "gemeinsam/Tanz"))
		_spiele(p, tat)
		if tat != "Idle" and p.ap and p.ap.has_animation(tat):
			p.ap.queue("Idle")

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
# Gestalt in tiere.gd, Verhalten in tier.gd, Bewegung der Glieder in tiere.gdshader (4.3).
func _tier(art: String, c: Vector2i) -> Tier:
	var e := Tier.neu(game, art, _mitte(c) + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)))
	tiere.append(e)
	return e

# ein Schwarm Fische in einem Becken; dazu (im Freien) ein Ibis am Ufer
func _becken(c: Vector3, r: float, n: int, ibis: bool) -> void:
	var s := {"mitte": c, "r": maxf(0.6, r - 0.3), "ziel": c, "zeit": 0.0, "tempo": 0.45, "scheu": false, "fuehrer": null}
	for i in n:
		var e := Tier.neu(game, "fisch", c + Vector3(randf_range(-0.3, 0.3), 0.1, randf_range(-0.3, 0.3)))
		e.schwarm = s
		e.versatz = Vector3(randf_range(-0.35, 0.35), randf_range(-0.04, 0.04), randf_range(-0.35, 0.35))
		if s.fuehrer == null:
			s.fuehrer = e
		tiere.append(e)
	if ibis:
		for versuch in 12:
			var w := randf() * TAU
			var q := c + Vector3(cos(w), 0, sin(w)) * (r + randf_range(0.4, 1.2))
			q.y = 0.0
			if not game.astar.is_point_solid(game._sub(q)):
				var e := Tier.neu(game, "ibis", q)
				e.schwarm = {"mitte": Vector3(c.x, 0, c.z), "r": r}
				tiere.append(e)
				break

func _tiere_tick(d: float, hp: Vector3) -> void:
	var si := 0
	for e: Tier in tiere:
		var p := e.n.global_position
		# nur in der Nähe des Helden: weiter weg steht alles still und wird nicht gezeichnet (Falken immer)
		var nah := Vector2(p.x - hp.x, p.z - hp.z).length() < 24.0 or e.art == "falke"
		if not nah:
			e.n.visible = false
			if e.kugel:
				e.kugel.visible = false
			continue
		e.tick(d, hp)
		e.n.visible = e.sichtbar
		if e.sichtbar and e.schatten > 0.0 and si < _schatten_n:
			var gr := e.schatten * e.gross
			var dreh := Basis(Vector3.UP, e.n.rotation.y)
			var b := dreh.scaled(Vector3(gr * e.schatten_form.x, 1.0, gr * e.schatten_form.y))
			var q := p + dreh * Vector3(0, 0, e.schatten_versatz * e.gross)
			q.y = 0.025
			_schatten.multimesh.set_instance_transform(si, Transform3D(b, q))
			si += 1
	if _schatten:
		_schatten.multimesh.visible_instance_count = si

# Schattenflecken unter den Tieren (4.3): ein MultiMesh für alle, ein Zeichenaufruf. Ohne sie schweben kleine Tiere
# aus der Höhe der Kamera über dem Sand.
var _schatten: MultiMeshInstance3D
var _schatten_n := 0

func _schatten_bauen() -> void:
	_schatten_n = 0
	for e: Tier in tiere:
		if e.schatten > 0.0 or e.art in ["falke", "ibis"]:
			_schatten_n += 1
	if _schatten_n == 0:
		return
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.04, 0.03, 0.02, 0.72)
	m.albedo_texture = _fleck_tex()
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	mm.instance_count = _schatten_n
	mm.visible_instance_count = 0
	_schatten = MultiMeshInstance3D.new()
	_schatten.multimesh = mm
	_schatten.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_schatten.custom_aabb = AABB(Vector3(-500, -1, -500), Vector3(1000, 4, 1000))
	game.add_child(_schatten)

static var _fleck: ImageTexture
static func _fleck_tex() -> ImageTexture:
	if _fleck:
		return _fleck
	var im := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var r := Vector2(x - 15.5, y - 15.5).length() / 15.5
			im.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - r, 0.0, 1.0) ** 1.6))
	_fleck = ImageTexture.create_from_image(im)
	return _fleck

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
