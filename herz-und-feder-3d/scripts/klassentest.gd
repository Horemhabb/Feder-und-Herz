extends Node
# Klassentest (Start mit „-- --neu --klasse=<id> --klassentest“): startet die Stunde mit der Klasse, prüft den
# Standardangriff, wirkt jede Fähigkeit an echten Gegnern und prüft ihre Wirkung, dazu den Fähigkeitenbaum.

var ok := 0
var bad := 0

func g() -> Node:
	return get_tree().current_scene

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func check(what: String, cond: bool) -> void:
	if cond: ok += 1
	else: bad += 1
	print(("  ok      " if cond else "  FEHLER  ") + what)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

# Schaden aller Gegner zusammen: steigt, wenn etwas trifft
func harm(G: Node) -> float:
	var s := 0.0
	for f in G.foes:
		s += f.max_hp - maxf(0.0, f.hp)
	return s

func near_group(G: Node) -> Vector3:
	# ein Platz neben dem nächsten Rudel, das noch lebt
	for f in G.foes:
		if f.kind != "boss" and f.state != Foe.St.DEAD:
			return f.global_position
	return G.boss.global_position

func taste(code: int, gedrueckt: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = gedrueckt
	Input.parse_input_event(e)

# Fußrutschen wie im Spieltest (playtest.gd › fussrutschen): Weg des aufgesetzten Fußes je Sekunde am Boden.
# Nebenbei: größte Vorneigung der Körperschicht.
var neig_max := 0.0
func fussrutschen(a: Actor, dauer: float) -> Vector2:
	var ids := ["foot.l", "toes.l", "foot.r", "toes.r"].map(func(n): return a.skel.find_bone(n))
	var takt := a.ap.callback_mode_process
	a.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var proben := []
	var t := 0.0
	neig_max = 0.0
	while t < dauer:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		neig_max = maxf(neig_max, a.koerper.neig.x if a.koerper else 0.0)
		var gt := a.skel.global_transform
		var tief := Vector3(0, INF, 0)
		var welcher := -1
		for i in ids:
			var p: Vector3 = gt * a.skel.get_bone_global_pose(i).origin
			if p.y < tief.y:
				tief = p
				welcher = i
		proben.append([tief, a.global_position, welcher])
	a.ap.callback_mode_process = takt
	var boden := INF
	for p in proben:
		boden = minf(boden, p[0].y)
	var rutsch := 0.0
	var am_boden := 0.0
	for i in range(1, proben.size()):
		var p: Vector3 = proben[i][0]
		var q: Vector3 = proben[i - 1][0]
		if proben[i][2] == proben[i - 1][2] and p.y < boden + 0.04 and q.y < boden + 0.04:
			rutsch += Vector2(p.x - q.x, p.z - q.z).length()
			am_boden += t / proben.size()
	var weg: Vector3 = proben[-1][1] - proben[0][1]
	return Vector2(rutsch / maxf(am_boden, 0.01), Vector2(weg.x, weg.z).length() / t)

# Gang und Körpersprache der Klasse (4.2): eigenes Profil, Laufen ohne Rutschen, Neigung, eigener Ausweichschritt
func bewegung(G: Node, h: Hero) -> void:
	var cls := h.cls
	var GA: Dictionary = Klassen.GANG[cls]
	var eigen := true
	for c in Klassen.GANG:
		if c != cls and Klassen.GANG[c].ausweich == GA.ausweich:
			eigen = false
	check("Gang: eigenes Profil der Klasse (Ausweichen „%s“, Feder %.0f, Trab %.2f)" % [GA.ausweich, GA.feder, GA.trab], h.koerper != null and h.koerper.active and h.G == GA and eigen)
	var bahn := []
	for tasten in [[KEY_D], [KEY_S], [KEY_A], [KEY_W], [KEY_S, KEY_D], [KEY_W, KEY_A], [KEY_W, KEY_D], [KEY_S, KEY_A]]:
		var v := Vector2((1 if tasten.has(KEY_D) else 0) - (1 if tasten.has(KEY_A) else 0), (1 if tasten.has(KEY_S) else 0) - (1 if tasten.has(KEY_W) else 0))
		var r := (Vector3(1, 0, -1) * v.x + Vector3(1, 0, 1) * v.y).normalized()
		if G.walkable(h.global_position, h.global_position + r * 16.0) and G.foe_near(h.global_position + r * 8.0, 9.0) == null:
			bahn = tasten
			break
	if bahn.is_empty():
		print("  (keine freie Bahn für die Laufprobe)")
		return
	for k in bahn:
		taste(k, true)
	await wait(0.35)
	var rh: Vector2 = await fussrutschen(h, 1.5)
	check("Gang: Laufen ohne Fußrutschen (%.2f m/s bei %.2f m/s, %s)" % [rh.x, rh.y, h.cur_anim], rh.y > 4.0 and rh.x < 1.0)
	check("Gang: der Körper neigt sich in den Lauf (%.2f)" % neig_max, neig_max > 0.04)
	var p0 := h.global_position
	var art_ok: bool = h.dodge() and h.ausweich_art == GA.ausweich
	var mitten_unsichtbar := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 420:
		await get_tree().process_frame
		mitten_unsichtbar = mitten_unsichtbar or not h.model.visible
	for k in bahn:
		taste(k, false)
	var weg := p0.distance_to(h.global_position)
	check("Ausweichen „%s“: eigene Art, rund 3 m (mit Lauf %.1f m), danach sichtbar%s" % [GA.ausweich, weg, ", dazwischen verschwunden" if mitten_unsichtbar else ""], art_ok and weg > 2.5 and h.model.visible and h.ausweich_art == "" and (mitten_unsichtbar == (GA.ausweich == "schritt")))
	if GA.get("schweben", 0.0) > 0.0:
		await wait(2.5)
		check("Gang: im Stand schwebt die Figur (%.2f)" % h.koerper.schwebe, h.koerper.schwebe > 0.5)
	await wait(0.3)

func run() -> void:
	await wait(1.5)
	var G := g()
	while not G.started:
		G.hud.press_primary()
		await wait(1.6)
		G = g()
	var h: Hero = G.hero
	G.orte.auto = false   # Orte lösen im Klassentest nicht aus (die Figur wird neben Gegner gesetzt)
	for c in G.chests:
		c.open = true     # Truhen ebenso: ein Fundfenster hielte das Spiel an
	var cls := Spiel.cls
	print("KLASSE ", cls, " (", Spiel.CLS[cls].name, ")")
	check("die gewählte Klasse ist im Spiel", h.cls == cls and h.SK.size() == 6)
	check("Fähigkeitenleiste zeigt die Fähigkeiten der Klasse", G.hud.skill_ui.has(h.ORDER[0]) and G.hud.skill_ui.has(h.ORDER[4]))
	h.inv = 9999.0
	Spiel.lvl = 12
	check("ohne Punkt im Baum wirkt keine Fähigkeit", not h.can(h.ORDER[0]) and not Spiel.gelernt(h.ORDER[4]))
	Spiel.auto_lernen()
	check("gelernt: alle fünf Fähigkeiten stehen bereit", h.ORDER.all(func(i): return Spiel.gelernt(i)))
	Spiel.calc()
	h.apply_stats(true)
	G.auto_low_done = true
	await bewegung(G, h)
	# Standardangriff
	var target := near_group(G)
	# auf einen Fleck mit freier Schusslinie (die Karte ist jedes Mal anders)
	h.global_position = target + Vector3(h.reach() * 0.6, 0, 0)
	for k in 12:
		var cand0: Vector3 = target + Vector3(sin(k * 0.52), 0, cos(k * 0.52)) * minf(h.reach() * 0.6, 5.0)
		if G.walkable(target, cand0) and G.sees(cand0, target):
			h.global_position = cand0
			break
	G.cam_pos = h.global_position
	await wait(0.5)
	var f0 := harm(G)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2500:
		var f: Foe = G.foe_near(h.global_position, 30.0)
		if f:
			h.aim = f.global_position
			h.attack()
		await wait(0.1)
	check("Standardangriff (%s) trifft (%.0f Schaden)" % [h.C.basic, harm(G) - f0], harm(G) > f0)
	if h.C.get("pet", false):
		check("der Fuchs begleitet die Jägerin", G.pet != null)
	# jede Fähigkeit
	for i in 5:
		var id: String = h.ORDER[i]
		await wait(0.6)
		target = near_group(G)
		# auf einen freien Fleck mit Sicht neben einen lebenden Gegner
		var spot: Vector3 = target + Vector3(2.5, 0, 0)
		for k in 12:
			var cand: Vector3 = target + Vector3(sin(k * 0.52), 0, cos(k * 0.52)) * 2.8
			if G.walkable(target, cand) and G.sees(cand, target):
				spot = cand
				break
		h.global_position = spot
		G.cam_pos = h.global_position
		h.en = 100.0
		h.busy = 0.0
		h.cd[id] = 0.0
		await wait(0.3)
		var nf: Foe = G.foe_near(h.global_position, 12.0)   # Gegner bewegen sich: auf den jetzt nächsten zielen
		h.aim = nf.global_position if nf else target
		if id == "roll" or id == "blink":
			# Sprung und Schritt brauchen freie Bahn: in die Richtung zielen, in der sechs Meter frei sind
			# (ein Gegner direkt vor der Figur oder eine Mauer verkürzten den Weg, und der Test prüfte den Zufall)
			for k2 in 12:
				var ri := Vector3(sin(k2 * TAU / 12.0), 0, cos(k2 * TAU / 12.0))
				if G.walkable(h.global_position, h.global_position + ri * 6.0):
					h.aim = h.global_position + ri * 9.0
					break
		h.auto_aim = false
		var before := harm(G)
		var p0 := h.global_position
		var cast_ok := h.cast(id)
		await wait(1.6)
		var name: String = h.SK[id].name
		check("%s lässt sich wirken" % name, cast_ok and h.cd[id] > 0.0 or (cast_ok and h.cd_of(id) < 1.6))
		match id:
			"oath":
				check("%s gibt den Schwur" % name, h.oath_t > 0.0)
			"mantra":
				check("%s legt den Kreis an" % name, h.mantra_t > 0.0)
			"roll", "blink":
				check("%s versetzt die Figur (%.1f m)" % [name, p0.distance_to(h.global_position)], p0.distance_to(h.global_position) > 1.5)
			"glass":
				check("%s legt eine Fläche, die verlangsamt" % name, G.zones.size() > 0 or harm(G) > before)
			_:
				if harm(G) <= before:
					# verzögerte Flächen können ein laufendes Ziel verfehlen: ein zweiter Versuch auf den jetzt nächsten Gegner
					nf = G.foe_near(h.global_position, 30.0)
					if nf:
						h.global_position = nf.global_position + Vector3(1.3, 0, 0)   # dicht heran: das Ziel war weggelaufen
						await wait(0.2)
					h.aim = nf.global_position if nf else target
					h.en = 100.0
					h.busy = 0.0
					h.cd[id] = 0.0
					h.cast(id)
					await wait(1.6)
				check("%s trifft (%.0f Schaden)" % [name, harm(G) - before], harm(G) > before)
	# 3D-Physik (4.2): ein Besiegter fällt als Gliederpuppe und liegt danach still
	var opfer: Foe = null
	for f in G.foes:
		if f.kind != "boss" and f.kind != "objekt" and f.elite == "" and f.state != Foe.St.DEAD and f.skel != null and f.proc == null and f.skel.find_bone("upperleg.l") >= 0:
			opfer = f
			break
	if opfer:
		var tief: bool = G.low_gfx
		G.low_gfx = false
		var voll := Physik.faelle >= Physik.FALL_MAX   # Fähigkeiten haben gerade viele umgeworfen: dann gilt die Todesbewegung
		opfer.hit(opfer.hp + 1.0, h.global_position, 8.0)
		await wait(0.3)
		print("  (Opfer: %s, Zustand %d, Puppen %d)" % [opfer.kind, opfer.state, Physik.faelle])
		check("Physik: der Besiegte fällt als Gliederpuppe%s" % (" (alle Plätze belegt: Todesbewegung)" if voll else ""), opfer.skel.get_node_or_null("Fall") != null or voll)
		if voll:
			opfer.ap.active = false   # falls nicht gefallen, scheitert auch die nächste Prüfung
		await wait(Physik.FALL_DAUER + 0.3)
		check("Physik: danach liegt er still, die Körper sind fort (%d laufen noch)" % Physik.faelle, opfer.skel.get_node_or_null("Fall") == null and Physik.faelle <= Physik.FALL_MAX and not opfer.ap.active)
		G.low_gfx = tief
	# Fähigkeitenbaum (seit 3.3 ein Baum: lernbar nur neben Gelerntem)
	Spiel.tree = {"r": {}, "a": {}, "p": {}, "key": false}
	var s1: String = h.ORDER[0]
	var pw0 := Spiel.sk_pow(s1)
	check("Rang erhöhen kostet einen Punkt", Spiel.tree_rank_up(s1) and Spiel.tree_rank_up(s1) and Spiel.tree_points() == Spiel.lvl + 1 - 2)
	check("Wucht ab Rang 2 macht stärker", Spiel.tree_aug(s1, "wucht") and Spiel.sk_pow(s1) > pw0 + 0.3)
	check("Baum: ein Knoten ohne gelernten Nachbarn lässt sich nicht lernen", not Spiel.tree_passive("scharf") and not Spiel.tree_rank_up(h.ORDER[3]))
	var hp0: float = Spiel.S.max_hp
	check("Starker Ka hängt am Stamm und erhöht das Leben", Spiel.tree_passive("zaeh") and Spiel.S.max_hp > hp0)
	check("Schlüsselstein: ohne Weg und vor 8 Punkten nicht", not Spiel.tree_key())
	# der Weg zum Schlüsselstein: rechte Maustaste, Taste 3, Fülle des Hapi
	Spiel.tree_rank_up(h.ORDER[4])
	Spiel.tree_rank_up(h.ORDER[2])
	Spiel.tree_passive("kraft")
	Spiel.tree_passive("kraft")
	check("Schlüsselstein über den mittleren Ast ab 8 Punkten (%d)" % Spiel.tree_spent(), Spiel.tree_key() and Spiel.has_key())
	check("Baum gültig: alles hängt am Stamm", Spiel.baum_gueltig())
	var heil: Dictionary = Spiel.tree.duplicate(true)
	Spiel.tree.p["jaeger"] = 1   # ein Stück ohne Weg dorthin, wie es ein alter Spielstand haben kann
	check("Baum ungültig, wenn etwas nicht am Stamm hängt", not Spiel.baum_gueltig())
	Spiel.tree = heil
	check("Umlernen (am Schrein des Thot) gibt alle Punkte zurück und kostet nichts", Spiel.respec() and Spiel.tree_points() == Spiel.lvl + 1 and Spiel.respec_cost() == 0)
	# alte Spielstände (3.3): ein Baum, der am Stamm hängt, bleibt; einer, der es nicht tut, wird zurückgegeben
	Spiel.tree = {"r": {h.ORDER[0]: 2}, "a": {}, "p": {"zaeh": 1}, "key": false}
	Spiel.speichern()
	var roh: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Spiel.DATEI))
	roh["regel"] = 3
	var f := FileAccess.open(Spiel.DATEI, FileAccess.WRITE)
	f.store_string(JSON.stringify(roh))
	f.close()
	Spiel.laden()
	check("alter Spielstand mit gültigem Baum: bleibt, wie er war", Spiel.rank(h.ORDER[0]) == 2 and Spiel.pas("zaeh") == 1 and not Spiel.baum_neu)
	roh["tree"] = {"r": {h.ORDER[3]: 3}, "a": {}, "p": {"scharf": 2}, "key": false}
	f = FileAccess.open(Spiel.DATEI, FileAccess.WRITE)
	f.store_string(JSON.stringify(roh))
	f.close()
	Spiel.laden()
	check("alter Spielstand mit losem Baum: Punkte zurück, Hinweis steht an", Spiel.tree_spent() == 0 and Spiel.baum_neu and Spiel.tree_points() == Spiel.lvl + 1 + Spiel.tree_frei)
	Spiel.baum_neu = false
	Spiel.lvl = 12
	Spiel.auto_lernen()
	check("auto_lernen geht vom Stamm aus und lernt alle Fähigkeiten der Stufe", h.ORDER.all(func(i): return i == "potion" or Spiel.gelernt(i) or not Spiel.lernbar(i)) and Spiel.baum_gueltig())
	await wait(0.2)
	get_tree().paused = true
	await wait(0.1)
	G.toggle_tree()
	get_tree().paused = false
	G.toggle_tree()
	await wait(0.4)
	check("K öffnet das Baum-Fenster", G.hud.tree_open)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_out"))
	get_viewport().get_texture().get_image().save_png("res://test_out/baum_%s.png" % cls)
	G.toggle_tree()
	await wait(0.3)
	check("K schließt das Baum-Fenster", not G.hud.tree_open and not get_tree().paused)
	get_viewport().get_texture().get_image().save_png("res://test_out/kampf_%s.png" % cls)
	print("KLASSENTEST %s: %d ok, %d Fehler" % [cls, ok, bad])
	get_tree().quit()
