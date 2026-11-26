class_name Fotos extends Node
# Bildschirmfotos (Start mit „-- --neu --fotos --seed=1“, oder „--fotos=1,5,7“ für eine Auswahl, auch „--fotos=3-6“):
# legt eine neue Figur an, besucht die gewählten Stunden und speichert nach test_out/fotos/ je Stunde zwei Bilder
# (stunde_NN_start.png am Eingang, stunde_NN_rudel.png vor dem ersten Rudel), dazu Titelbild, Fähigkeitenbaum und Tasche.
# Gedacht für den Pull Request: Der Auftraggeber sieht alle Stunden, ohne zu spielen, und die Entwickler-KI sieht,
# ob etwas kaputt aussieht. Braucht einen Bildschirm (unter Linux: xvfb-run -a … --rendering-driver opengl3).
# Ein schwarzes oder leeres Bild zählt als Fehler. Ausgabe am Ende: „FOTOS: n Bilder“, Rückgabewert 0 oder 1.

const AUS := "res://test_out/fotos"

var bilder := 0
var bad := 0
var t_start := 0

# Läuft dieser Start als Fotolauf? (main.gd fragt, ohne etwas zu laden)
static func laeuft() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "--fotos" or a.begins_with("--fotos="):
			return true
	return false

func g() -> Node:
	return get_tree().current_scene

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
	# ohne Grafikkarte rechnet ein Bild bis zu einer Zehntelsekunde: ein paar Bilder abwarten, damit Überblendungen
	# der Oberfläche (Fenster entfalten sich) fertig sind, bevor ein Foto entsteht
	for i in 4:
		await get_tree().process_frame

func fehler(was: String) -> void:
	bad += 1
	print("  FEHLER  " + was)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

# welche Stunden: „--fotos“ alle zwölf, „--fotos=1,5,7“ oder „--fotos=3-6“ eine Auswahl
func stunden() -> Array:
	if nur_ui():
		return [1]
	var out: Array = []
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--fotos="):
			continue
		for teil in a.substr(8).split(",", false):
			if "-" in teil:
				var ab: PackedStringArray = teil.split("-")
				for n in range(int(ab[0]), int(ab[1]) + 1):
					out.append(n)
			else:
				out.append(int(teil))
	if out.is_empty():
		for n in range(1, Stunden.HOURS + 1):
			out.append(n)
	return out.filter(func(n): return n >= 1 and n <= Stunden.HOURS)

# Bild speichern und prüfen: nicht schwarz, nicht einfarbig
func shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUS))
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		fehler("%s: kein Bild vom Fenster (läuft die Prüfung ohne Bildschirm?)" % name)
		return
	var klein: Image = img.duplicate()
	klein.resize(32, 18, Image.INTERPOLATE_BILINEAR)
	var summe := 0.0
	var quad := 0.0
	var n := 0
	for y in klein.get_height():
		for x in klein.get_width():
			var c: Color = klein.get_pixel(x, y)
			var l: float = c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			summe += l
			quad += l * l
			n += 1
	var mittel := summe / n
	var streu := sqrt(maxf(0.0, quad / n - mittel * mittel))
	var pfad := "%s/%s.png" % [AUS, name]
	img.save_png(pfad)
	bilder += 1
	var leer := mittel < 0.03 or streu < 0.015
	print("  %s  %s (%dx%d, Helligkeit %.2f, Streuung %.2f)" % ["FEHLER  leer:" if leer else "ok     ", name, img.get_width(), img.get_height(), mittel, streu])
	if leer:
		bad += 1

# warten, bis eine neue Szene steht und die Kapiteltafel der Stunde darüberliegt (die Stunde ist dann gebaut)
func auf_tafel(alt: Node, max_s := 90.0) -> Node:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_s * 1000.0:
		await wait(0.25)
		var G := g()
		if G != null and G != alt and G.get("hud") != null and G.hud.overlay != null:
			return G
	fehler("die Stunde wurde nicht in %.0f Sekunden gebaut" % max_s)
	return null

# alles zur Seite, was das Spiel anhält oder die Figur ablenkt
func freimachen(G: Node) -> void:
	if G.hud.overlay != null and not G.hud.menu_open:
		G.hud._close()
	if G.hud.overlay == null:
		get_tree().paused = false

func ruhig(G: Node) -> void:
	var h: Hero = G.hero
	h.inv = 9999.0      # die Gegner sollen die Figur in dieser Zeit nicht töten
	h.hp = h.max_hp

# eine Stelle mit Sicht auf die Gegner, im Abstand r: frei begehbar und nicht in einem Felsblock
func platz_vor(G: Node, ziel: Vector3, r: float) -> Vector3:
	for rr in [r, r * 0.7, r * 1.3, r * 0.5]:
		for i in 16:
			var q: Vector3 = ziel + Vector3(cos(TAU * i / 16.0), 0, sin(TAU * i / 16.0)) * rr
			if G.walkable(ziel, q) and G.sees(q, ziel) and not G.astar.is_point_solid(G._sub(q)):
				return q
	return Vector3.INF

# das erste Rudel: das nächste Rudel mit mindestens zwei Gegnern, das nicht schon am Eingang liegt
func erstes_rudel(G: Node) -> Foe:
	var liste: Array = G.foes.filter(func(f): return f.kind != "boss" and f.state != Foe.St.DEAD and not f.hidden and f.pack != 99)
	var gross: Array = liste.filter(func(f): return liste.filter(func(o): return o.pack == f.pack).size() >= 2)
	if not gross.is_empty():
		liste = gross
	var fern: Array = liste.filter(func(f): return f.global_position.distance_to(G.start_pos) > 14.0)
	if not fern.is_empty():
		liste = fern
	liste.sort_custom(func(a, b): return a.global_position.distance_to(G.start_pos) < b.global_position.distance_to(G.start_pos))
	return liste[0] if not liste.is_empty() else null

func run() -> void:
	t_start = Time.get_ticks_msec()
	await wait(1.6)
	var G := g()
	print("FOTOS: Stunden ", stunden())
	# Titelbild: der Startbildschirm der neuen Figur
	if G.hud.overlay == null:
		fehler("kein Startbildschirm da (Start ohne --neu?)")
	await wait(1.0)
	shot("00_titel")
	if not G.hud.press_primary():
		fehler("der Startknopf ließ sich nicht drücken")
		return ende()
	G = await auf_tafel(G)
	if G == null:
		return ende()
	var liste := stunden()
	for h in liste:
		if Spiel.fall != h:
			G.go_hour(h)
			G = await auf_tafel(G)
			if G == null:
				return ende()
		var t_h := Time.get_ticks_msec()
		# Das Spiel wählt ohne Grafikkarte die kleinste Stufe (Minimal); für die Bilder gilt die höchste
		G.guete_von_hand(0)
		# die große Akttafel (Stunden 1, 5, 9) würde die Figur verdecken: als schon gesehen vermerken
		Spiel.merke("akt_%d_n%d" % [Stunden.akt(Spiel.fall), Stunden.night_of(Spiel.fall)])
		await wait(0.3)
		if nur_ui():
			await wait(0.9)
			shot("stunde_%02d_tafel" % h)
		if not G.hud.press_primary():
			fehler("Stunde %d: die Tafel ließ sich nicht schließen" % h)
			return ende()
		G.orte.auto = false   # Orte lösen nicht aus, wenn die Figur umgesetzt wird (ein Fenster hielte das Spiel an)
		for c in G.chests:
			c.open = true
		ruhig(G)
		await wait(1.4)
		freimachen(G)
		ruhig(G)
		check_stunde(G, h)
		shot("stunde_%02d_start" % h)
		# zweite Stelle: vor dem ersten Rudel, das aufwacht und auf die Figur zuläuft
		if nur_ui():
			continue
		var f: Foe = erstes_rudel(G)
		var wo := Vector3.INF
		if f != null:
			wo = platz_vor(G, f.global_position, 7.0)
		if wo == Vector3.INF:
			fehler("Stunde %d: kein freier Platz vor einem Rudel gefunden" % h)
		else:
			G.hero.global_position = wo
			G.cam_pos = wo
			G.wake_pack(f.pack)
			await wait(1.8)
			freimachen(G)
			ruhig(G)
			shot("stunde_%02d_rudel" % h)
		print("  Stunde %d: %.1f s" % [h, (Time.get_ticks_msec() - t_h) / 1000.0])
	# Fähigkeitenbaum und Tasche zuletzt: mit etwas Stufe, gelernten Fähigkeiten und Beute, damit sie nicht leer aussehen
	G = g()
	freimachen(G)
	Spiel.lvl = 8
	Spiel.auto_lernen()
	for slot in ["waffe", "helm", "ruestung", "ring", "amulett", "stiefel"]:
		Spiel.bag.append(Spiel.new_item(6, 2, {"slot": slot}))
	for i in 3:   # die letzten drei gleich anlegen, die anderen bleiben in der Tasche
		Spiel.equip(Spiel.bag.size() - 1)
	Spiel.bag.append(Spiel.new_item(6, 3, {"slot": "waffe"}))
	Spiel.shards = 240
	Spiel.mats = {"staub": 12, "leder": 5, "eisen": 4, "stern": 1}
	Spiel.calc()
	G.hero.apply_stats(true)
	ruhig(G)
	await wait(0.3)
	G.toggle_tree()
	await wait(0.8)
	if G.hud.tree_open:
		shot("zusatz_baum")
		G.toggle_tree()
	else:
		fehler("der Fähigkeitenbaum öffnete sich nicht")
	await wait(0.4)
	freimachen(G)
	G.toggle_bag()
	await wait(0.8)
	if G.hud.bag_open:
		shot("zusatz_tasche")
		G.toggle_bag()
	else:
		fehler("die Tasche öffnete sich nicht")
	await wait(0.3)
	await oberflaeche(g())
	ende()

# Nur die Oberfläche (Start mit „-- --neu --fotos=ui“): Titel, Tafel der ersten Stunde und jede Fläche einmal
static func nur_ui() -> bool:
	return "--fotos=ui" in OS.get_cmdline_user_args()

# Jede Fläche der Oberfläche einmal im Bild (4.3): Leiste mit Meldungen, Ankündigung, Champion, Hüter, Gespräch,
# Truhe, Pforte, Niederlage, Menü mit Unterseiten, große Karte, Tasche mit gewähltem Teil, Werkstatt.
func oberflaeche(G: Node) -> void:
	if G == null:
		return
	freimachen(G)
	ruhig(G)
	var H: Hud = G.hud
	var nichts := func(): pass
	# Leiste, Fundmeldungen und Banner
	H.toast_item(Daten.ICON.shard, "Truhe geleert", "3 Teile, 42 Scherben", Color(0.95, 0.85, 0.55))
	var it: Dictionary = Spiel.new_item(6, 3, {"slot": "waffe"})
	H.toast_item(Daten.icon_of(it), Daten.item_name(it), G.item_sub(it), Daten.RAR[it.rar].col)
	H.toast_item(Daten.ICON.evid, Daten.EVID[0][0], "Seite aus dem Buch des Thot.", Color(0.98, 0.9, 0.62))
	H.banner("Die Pforte der Stunde steht offen.", "DER HÜTER IST GEFALLEN", 4.0)
	H.toast("Dein Ba flüstert: Hier war schon jemand.", 4.0, Hud.TEAL)
	await wait(0.9)
	shot("ui_hud")
	# Ankündigung (neue Fähigkeit)
	var sid: String = G.hero.ORDER[1]
	H.announce(Klassen.icon(sid, 176), "JETZT LERNBAR · IM FÄHIGKEITENBAUM", Klassen.SK[sid].name, Klassen.SK[sid].txt, 3.0)
	await wait(1.0)
	shot("ui_ankuendigung")
	await wait(3.6)
	# Champion-Schild
	var art := ""
	for f in G.foes:
		if f.kind != "boss":
			art = f.kind
			break
	if art != "":
		Affixe.vorgabe = ["glut", "feder"]
		var c: Foe = G._spawn(art, G.hero.global_position + Vector3(30, 0, 30), 97, "zaeh", G.hdef)
		Affixe.vorgabe = []
		c.process_mode = Node.PROCESS_MODE_DISABLED
		H.champ_f = c
		H.champ_t = 1e12
		H._champion_fuellen(c)
		H.champ_box.visible = true
		await wait(0.5)
		shot("ui_champion")
		H.champ_t = 0.0
	# Hüter-Leiste mit Ansage
	if G.boss:
		H.boss_show(G.boss)
		H.boss_ansage("Überfahrt")
		await wait(0.5)
		shot("ui_hueter")
		H.boss_hide()
		H.champ_t = 0.0
	# Gespräch mit Porträt und drei Antworten
	get_tree().paused = true
	H.show_dialog("EINE BITTE", "Merit, Tochter des Schreibers", "am Eingang der Stunde",
		["„Mein Bruder ist vorausgegangen, mit einer Lampe und ohne Namen. Wenn du ihn findest, sag ihm, dass ich warte.“",
		"Sie hält dir ein Stück Leinen hin, auf dem ein Zeichen steht."],
		[["„Ich halte die Augen offen.“", nichts], ["„Was steht auf dem Leinen?“", nichts], ["„Jetzt nicht.“", nichts]], "P01")
	await wait(0.6)
	shot("ui_gespraech")
	# Gespräch ohne Bild (Schrein)
	H.show_dialog("SCHREIN DES THOT", "Thot, Schreiber der Götter", "", ["Der Ibis neigt den Kopf und hält dir die Tafel hin, auf der steht, was du gelernt hast."], [["Zum Fähigkeitenbaum", nichts], ["Gehen", nichts]])
	await wait(0.5)
	shot("ui_schrein")
	# Truhe
	var zeilen := []
	for r in [1, 2, 3]:
		var t: Dictionary = Spiel.new_item(6, r, {})
		zeilen.append([Daten.icon_of(t), Daten.item_name(t), G.item_sub(t), Daten.RAR[t.rar].col])
	H.show_chest("PRUNKFUND", "Truhe eines Schreibers", zeilen, "Die Truhe ist leer, sobald du alles nimmst.", nichts, nichts)
	await wait(0.5)
	shot("ui_truhe")
	# Pforte
	H.show_gate(Stunden.case_no(1) + " · VOLLENDET", G.hdef.name, "Hinter dir schließt sich der Sand. Vor dir liegt Wasser, still und schwarz.",
		[["12:40", "Zeit"], ["84", "Gegner"], ["3 / 4", "Aufgaben"]], "HINTER DER PFORTE · " + Stunden.case_no(2), Stunden.def(2).name, Stunden.def(2).lead, nichts, nichts)
	await wait(0.5)
	shot("ui_pforte")
	# Kapiteltafel
	H.show_chapter(Stunden.case_no(1), G.hdef.name, G.hdef.lead, G.hdef.get("brief", ""), "Die Stunde betreten", nichts)
	await wait(1.2)
	shot("ui_tafel")
	# Niederlage
	H.show_dead("Die Schatten haben dich zu Boden gezogen.", nichts)
	await wait(0.5)
	shot("ui_niederlage")
	H._close()
	get_tree().paused = false
	await wait(0.2)
	# Menü und Unterseiten
	G.toggle_menu()
	await wait(0.6)
	if H.menu_open:
		shot("ui_menue")
		for s in ["einstellungen", "lexikon", "steuerung"]:
			H.menue.geh(s)
			await wait(0.4)
			shot("ui_menue_" + s)
		G.toggle_menu()
	else:
		fehler("das Menü öffnete sich nicht")
	await wait(0.3)
	freimachen(G)
	# große Karte
	G.toggle_karte()
	await wait(0.6)
	if H.karte_open:
		shot("ui_karte")
		G.toggle_karte()
	else:
		fehler("die große Karte öffnete sich nicht")
	await wait(0.3)
	freimachen(G)
	# Tasche mit gewähltem Teil, dann die Werkstatt
	G.toggle_bag()
	await wait(0.5)
	if H.bag_open:
		for t in H.overlay.find_children("*", "Tasche", true, false):
			t.sel = {"bag": 0}
			t.render()
		await wait(0.4)
		shot("ui_tasche_teil")
		G.toggle_bag()
	await wait(0.3)
	get_tree().paused = true
	H.show_werkstatt()
	await wait(0.5)
	for t in H.overlay.find_children("*", "Tasche", true, false):
		t.sel = {"eq": "waffe"}
		t.render()
	await wait(0.4)
	shot("ui_werkstatt")
	H.close_bag()
	await wait(0.3)

# Stimmt die Stunde? Name der Tafel gegen die Stunde, die verlangt war
func check_stunde(G: Node, h: int) -> void:
	if Stunden.hour_of(Spiel.fall) != h or G.hdef.name != Stunden.def(h).name:
		fehler("Stunde %d: gebaut wurde %s" % [h, G.hdef.name])
	if G.foes.is_empty():
		fehler("Stunde %d: keine Gegner gebaut" % h)

func ende() -> void:
	print("FOTOS: %d Bilder, %d Fehler, %.0f Sekunden" % [bilder, bad, (Time.get_ticks_msec() - t_start) / 1000.0])
	print("FOTOS: %d Bilder" % bilder)
	get_tree().quit(1 if (bad > 0 or bilder == 0) else 0)
