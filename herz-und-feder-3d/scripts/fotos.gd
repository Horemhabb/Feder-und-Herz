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

func fehler(was: String) -> void:
	bad += 1
	print("  FEHLER  " + was)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

# welche Stunden: „--fotos“ alle zwölf, „--fotos=1,5,7“ oder „--fotos=3-6“ eine Auswahl
func stunden() -> Array:
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
	# dieselbe Tafel mit dem Gamepad: die zweite Klasse ist gewählt, Rahmen und Tastenzeile sind da
	G.hud._pad_modus(true)
	var fk: Array = G.hud.fokussierbar(G.hud.overlay)
	if fk.size() > 1:
		(fk[1] as Control).grab_focus()
	await wait(0.4)
	shot("00_titel_pad")
	G.hud._pad_modus(false)
	if fk.size() > 0:
		(fk[fk.size() - 1] as Control).release_focus()
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
			if h == liste[0]:
				await kampfbild(G, f)
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
		G.hud._pad_modus(true)
		G.hud._fokus_pruefen()
		await wait(0.3)
		shot("zusatz_tasche_pad")
		G.hud._pad_modus(false)
		G.toggle_bag()
	else:
		fehler("die Tasche öffnete sich nicht")
	await wait(0.3)
	await padbilder(G)
	ende()

# Kampf mit Rückmeldung (Etappe B): Lebensbalken über verletzten Gegnern, Schadenszahlen, Treffer auf die Figur,
# Abklingzeiten in der Leiste. Die Figur ist dabei unverwundbar, der Treffer wird nur vorgeführt.
func kampfbild(G: Node, f: Foe) -> void:
	var h: Hero = G.hero
	var rudel: Array = G.foes.filter(func(o): return o.pack == f.pack and o.state != Foe.St.DEAD)
	var n := 0
	for o in rudel:
		o.hit(o.max_hp * (0.25 + 0.15 * (n % 3)), h.global_position, 2.0, 0.0, n == 1)
		n += 1
		await wait(0.18)
	for id in h.ORDER:
		if Spiel.gelernt(id):
			h.cd[id] = h.cd_of(id) * 0.6
	await wait(0.25)
	h.inv = 0.0
	h.hurt(h.max_hp * 0.08, f.global_position, f)
	h.inv = 9999.0
	await wait(0.1)
	print("  Rückmeldung: Blitz %.2f, Rand sichtbar %s, Größe %s, Balken %d" % [G.hud.rueck.blitz, G.hud.rueck.rand.visible, G.hud.rueck.rand.size, G.hud.rueck.sichtbar_anzahl])
	shot("zusatz_kampf")

# Menü und Tasche so, wie sie mit dem Gamepad aussehen: Fokusrahmen und Tastenzeile
func padbilder(G: Node) -> void:
	freimachen(G)
	G.hud._pad_modus(true)
	G.toggle_menu()
	await wait(0.5)
	G.hud._fokus_pruefen()
	await wait(0.3)
	shot("zusatz_menue_pad")
	G.hud.menue.geh("einstellungen")
	await wait(0.4)
	shot("zusatz_einstellungen_pad")
	G.toggle_menu()
	await wait(0.3)
	freimachen(G)

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
