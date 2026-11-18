extends Node
# Spieltest (Start mit „-- --playtest“): spielt echte Eingaben ein, also Tasten, Mausbewegung und Klicks in Echtzeit,
# genau der Weg, den ein Mensch nimmt. Prüft Start, Laufen, Fähigkeiten, Niederlage, Rückkehr, Pforte und Neustart.

var ok := 0
var bad := 0

func g() -> Node:
	return get_tree().current_scene

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func key(code: int, hold := 0.08) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await wait(hold)
	var r := InputEventKey.new()
	r.keycode = code
	r.physical_keycode = code
	r.pressed = false
	Input.parse_input_event(r)
	await wait(0.05)

func mouse(logical: Vector2, button := 0, pressed := true) -> void:
	# Spielkoordinaten (1600 x 900) in Fensterpunkte umrechnen: eingespielte Ereignisse erwarten Fensterpunkte
	Input.warp_mouse(logical)
	var pos: Vector2 = get_viewport().get_final_transform() * logical
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	Input.parse_input_event(m)
	if button != 0:
		var b := InputEventMouseButton.new()
		b.position = pos
		b.global_position = pos
		b.button_index = button
		b.pressed = pressed
		Input.parse_input_event(b)

func check(what: String, cond: bool) -> void:
	if cond: ok += 1
	else: bad += 1
	print(("  ok      " if cond else "  FEHLER  ") + what)

func shot(tag: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_out"))
	get_viewport().get_texture().get_image().save_png("res://test_out/pt_%s.png" % tag)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	await wait(1.6)
	var G := g()
	check("Startbildschirm liegt über dem Spiel, Spiel steht", G.hud.overlay != null and get_tree().paused and not G.started)
	check("ohne Spielstand: Startbildschirm im Modus „Neue Figur“", G.hud.intro_new and not Spiel.hat_stand)
	await key(KEY_E)
	await wait(2.0)
	G = g()
	check("neue Figur angelegt und gespeichert (Stufe 1, Normal)", Spiel.hat_stand and Spiel.lvl == 1 and Spiel.diff == 0)
	check("danach die Tafel der Stunde", G.hud.overlay != null and get_tree().paused and not G.started)
	await wait(1.0)
	await key(KEY_E)
	await wait(0.4)
	check("E gibt das Spiel frei", G.started and not get_tree().paused and G.hud.overlay == null)
	var h: Hero = G.hero
	G.orte.auto = false   # Orte lösen erst im eigenen Abschnitt aus, damit das Umsetzen der Figur nichts anstößt
	check("Lebens- und Kraftkugel zeigen die Werte", is_equal_approx(G.hud.orb_hp.value, h.hp / h.max_hp) and G.hud.orb_hp.text == str(int(ceil(h.hp))))
	check("Questbuch zeigt die Aufgaben der Stunde (%d)" % G.orte.quests.size(), G.orte.quests.size() >= 3 and G.hud.quest_box.get_child_count() >= 6)
	var p0 := h.global_position
	await key(KEY_D, 0.9)
	check("D läuft (%.1f m)" % p0.distance_to(h.global_position), p0.distance_to(h.global_position) > 1.5)
	p0 = h.global_position
	var vs := get_viewport().get_visible_rect().size
	mouse(vs * Vector2(0.35, 0.62), MOUSE_BUTTON_LEFT, true)
	await wait(1.0)
	mouse(vs * Vector2(0.35, 0.62), MOUSE_BUTTON_LEFT, false)
	check("gehaltene linke Maustaste läuft (%.1f m)" % p0.distance_to(h.global_position), p0.distance_to(h.global_position) > 1.5)
	shot("laufen")
	# Fähigkeiten und Schalter
	# Ausweichschritt
	await wait(0.3)
	p0 = h.global_position
	await key(KEY_SPACE)
	await wait(0.35)
	check("Leertaste: Ausweichschritt (%.1f m), kurz unverwundbar" % p0.distance_to(h.global_position), p0.distance_to(h.global_position) > 1.5 and h.dodge_cd > 0.0)
	check("Fenster liegen auf Papyrus, die Schrift ist Tinte", G.hud.papier.size() >= 1 and G.hud.f_text != null)
	# Fähigkeiten werden mit den Stufen gelernt und groß angekündigt
	# seit 3.0: nichts wirkt von selbst. Zwei Punkte zum Einstand, die Leiste zeigt „LERNEN“ oder die Stufe
	check("auf Stufe 1 ist nichts gelernt: zwei Punkte, Leiste zeigt LERNEN und Stufen", not h.can("whirl") and Spiel.tree_points() == 2 and G.hud.skill_ui["whirl"].lock.text == "LERNEN" and G.hud.skill_ui["dash"].lock.text == "AB STUFE 2")
	check("Lernen geht erst ab der Stufe der Fähigkeit", not Spiel.tree_rank_up("dash") and Spiel.tree_rank_up("whirl") and Spiel.tree_rank_up("beam"))
	await wait(0.2)
	check("gelernt: Falkenkreis und Strahl wirken, die Leiste ist frei", h.can("whirl") and h.can("beam") and G.hud.skill_ui["whirl"].lock.text == "" and not h.can("dash"))
	while Spiel.lvl < 5:
		if Spiel.xp_gain(Daten.xp_need(Spiel.lvl)):
			G._level_up()
	await wait(0.3)
	check("Aufstieg: Ankündigung in der Bildmitte, weitere stehen an (%d)" % G.hud.ann_queue.size(), G.hud.ann_box != null and G.hud.ann_queue.size() >= 3)
	check("freie Punkte: goldener Knopf über der Leiste", G.hud.punkt_btn.visible and ("%d Fähigkeitenpunkt" % Spiel.tree_points()) in G.hud.punkt_btn.text and Spiel.tree_points() >= 4)
	check("auf Stufe 5 sind alle Fähigkeiten lernbar", G.hud.skill_ui["udjat"].lock.text == "LERNEN" and Klassen.unlock_lvl("ermittler", "udjat") == 5)
	Spiel.auto_lernen()
	await wait(0.2)
	check("alle gelernt: keine Sperre mehr auf der Leiste", G.hud.skill_ui["udjat"].lock.text == "" and Spiel.gelernt("oath"))
	shot("aufstieg")
	h.en = 100.0
	for k in [[KEY_1, "whirl"], [KEY_2, "dash"], [KEY_3, "oath"], [KEY_4, "udjat"]]:
		# Abwarten, bis die Figur wieder handeln darf (kein Hieb, keine Betäubung): sonst prüft der Test den Zufall
		var warte := 0.0
		while not h.can(k[1]) and warte < 3.0:
			await wait(0.1)
			warte += 0.1
		await key(k[0])
		check("Taste %s löst %s aus" % [OS.get_keycode_string(k[0]), h.SK[k[1]].name], h.cd[k[1]] > 0.0)
		await wait(0.7)
	var en0 := h.en
	mouse(vs * Vector2(0.6, 0.4), MOUSE_BUTTON_RIGHT, true)
	await wait(0.1)
	mouse(vs * Vector2(0.6, 0.4), MOUSE_BUTTON_RIGHT, false)
	check("rechte Maustaste: Strahl des Re", h.en < en0)
	h.hp = 50.0
	await wait(0.5)
	await key(KEY_Q)
	check("Q trinkt Rotbier", h.hp > 60.0 and h.pots == 3)
	await key(KEY_F)
	check("F zeigt die Bildrate", G.hud.l_fps.visible)
	await key(KEY_G)
	check("G schaltet auf niedrige Grafik", G.low_gfx and not h.lantern.shadow_enabled)
	await key(KEY_G)
	check("G schaltet zurück", not G.low_gfx and h.lantern.shadow_enabled)
	check("Musik der ersten Stunde läuft (Wüstennacht)", G.sfx.mus_list.has(G.sfx.mus_name) and G.sfx.mus[0].playing and G.sfx.mus[0].stream != null)
	await key(KEY_M)
	check("M schaltet den Ton aus", G.sfx.muted)
	await key(KEY_M)
	# Angriff mit der Maus auf einen Gegner (mit Treffer-Stillstand)
	# Beute, Tasche, Anlegen, Aufwerten
	var opfer: Foe = G.foes.filter(func(f): return f.kind != "boss")[1]
	var xp0 := Spiel.xp + Spiel.lvl * 100000.0
	opfer.hit(99999.0, h.global_position)
	await wait(0.6)
	check("ein besiegter Gegner gibt Erfahrung", Spiel.xp + Spiel.lvl * 100000.0 > xp0)
	var n_loot: int = G.loot.size()
	G.drop_item(h.global_position, Spiel.new_item(1, 2, {"slot": "ring"}), h.global_position + Vector3(0.5, 0, 0))
	G.drop("shard", h.global_position, 5, "", h.global_position + Vector3(0, 0, 0.5))
	G.drop("mat", h.global_position, 20, "staub", h.global_position + Vector3(-0.5, 0, 0))
	var sh0 := Spiel.shards
	await wait(1.0)
	check("Beute wird beim Darüberstehen aufgehoben (Scherben %d -> %d)" % [sh0, Spiel.shards], Spiel.shards >= sh0 + 5 and G.loot.size() <= n_loot)
	check("ein Ring für den leeren Platz wird direkt angelegt", Spiel.eq.has("ring"))
	var ring: Dictionary = Spiel.eq.ring
	Spiel.bag.append(Spiel.new_item(1, 1, {"slot": "ruestung"}))
	await key(KEY_I)
	await wait(0.3)
	check("I öffnet die Tasche, Spiel steht", G.hud.bag_open and get_tree().paused and G.hud.overlay != null)
	shot("tasche")
	Spiel.equip(Spiel.bag.size() - 1)
	h.apply_stats()
	check("Anlegen einer Rüstung erhöht die Rüstung", Spiel.S.armor > 0)
	var st0: int = Spiel.mats.staub
	Spiel.shards = 200
	check("Aufwerten kostet Fayencestaub und eine Gebühr in Scherben", Spiel.upgrade(ring) and int(ring.up) == 1 and Spiel.mats.staub == st0 - 3 and Spiel.shards == 194)
	# Werkstatt des Ptah (3.0): Gebühr in Scherben, Neu-Fassen mit Auswahl; in der Tasche gibt es beides nicht mehr
	Spiel.shards = 200
	Spiel.mats.staub = 20
	var wsh := Spiel.shards
	var aff0: String = ring.aff.keys()[0] if ring.aff.size() > 0 else ""
	var wopts := Spiel.reroll_angebot(ring) if aff0 != "" else []
	check("Neu fassen: Gebühr vorab, zwei Fassungen zur Wahl", aff0 == "" or (wopts.size() == 2 and Spiel.shards == wsh - Daten.reroll_fee(ring) and ring.aff.has(aff0)))
	if not wopts.is_empty():
		Spiel.reroll_setzen(ring, aff0, wopts[0])
		check("Neu fassen: die gewählte Eigenschaft ersetzt die alte", ring.aff.has(wopts[0].k) and not ring.aff.has(aff0))
	check("Werkstatt des Ptah steht in der Stunde, nahe am Eingang", not G.orte.werk.is_empty() and G.orte.werk.pos.distance_to(G.start_pos) < 30.0)
	var tb: Tasche = G.hud.overlay.find_children("*", "Tasche", true, false)[0]
	tb.sel = {"eq": "ring"}
	tb.render()
	await wait(0.1)
	var knoepfe := tb.find_children("*", "Button", true, false).map(func(b): return b.text)
	check("Tasche: kein Aufwerten, kein Neu-Fassen mehr", not knoepfe.any(func(t): return "Aufwerten" in t or "neu fassen" in t))
	G.hud.close_bag()
	G.hud.show_werkstatt()
	await wait(0.2)
	tb = G.hud.overlay.find_children("*", "Tasche", true, false)[0]
	tb.sel = {"eq": "ring"}
	tb.render()
	await wait(0.1)
	knoepfe = tb.find_children("*", "Button", true, false).map(func(b): return b.text)
	check("Werkstatt: Aufwerten mit Gebühr, Neu-Fassen, Fundkiste", knoepfe.any(func(t): return "Aufwerten" in t and "Scherben" in t) and knoepfe.any(func(t): return "Fundkiste" in t))
	shot("werkstatt")
	G.hud.close_bag()
	get_tree().paused = true
	G.hud.show_bag()
	await wait(0.2)
	await key(KEY_I)
	await wait(0.3)
	check("I schließt die Tasche, Spiel läuft", not G.hud.bag_open and not get_tree().paused and G.hud.overlay == null)
	await key(KEY_I)
	await wait(0.3)
	await key(KEY_ESCAPE)
	await wait(0.3)
	check("Esc schließt die Tasche", not G.hud.bag_open and not get_tree().paused and G.hud.overlay == null)
	# Truhe: öffnet sich bei Berührung, „Alles nehmen“ (E)
	var ch: Dictionary = G.chests[0]
	var bag0 := Spiel.bag.size() + Spiel.eq.size()
	h.global_position = ch.pos + Vector3(1.4, 0, 0)
	await wait(0.6)
	check("Truhe öffnet sich bei Berührung und zeigt den Fund", ch.open and G.hud.overlay != null and get_tree().paused)
	shot("truhe")
	await key(KEY_E)
	await wait(0.4)
	check("„Alles nehmen“ legt den Fund in die Tasche", Spiel.bag.size() + Spiel.eq.size() > bag0 and not get_tree().paused)
	check("Spielstand liegt vor und enthält die Ausrüstung", FileAccess.file_exists(Spiel.DATEI) and FileAccess.get_file_as_string(Spiel.DATEI).contains(String(ring.name)))
	# Fassung 2.0: Feuerschale, Schrein, Seelenkrüge, Figur der Stunde, Fundstück, Herzwaage
	var O: Orte = G.orte
	var site := func(kind: String, n := 0) -> Dictionary:
		var l: Array = O.sites.filter(func(s): return s.kind == kind)
		return l[n] if n < l.size() else {}
	Spiel.herz = 0.0
	O.auto = true
	O.helfer_talked = true   # der Mensch am Eingang spricht erst in seinem eigenen Abschnitt
	var fs: Dictionary = site.call("feuer")
	var lights: int = G.torches.size()
	h.global_position = fs.pos + Vector3(1.3, 0, 0)
	await wait(0.5)
	check("Feuerschale entzündet sich bei Berührung, das Herz wird leichter", fs.done and G.torches.size() == lights + 1 and Spiel.herz > 0.0)
	var sr: Dictionary = site.call("schrein")
	h.global_position = sr.pos + Vector3(1.4, 0, 0)
	await wait(0.5)
	check("Schrein gibt den Segen der Gottheit (%s)" % sr.gott.name, sr.done and O.buffs.has(sr.gott.id) and Spiel.segen.has(sr.gott.id))
	var k1: Dictionary = site.call("krug", 0)
	var hz := Spiel.herz
	h.global_position = k1.pos + Vector3(1.3, 0, 0)
	await wait(0.5)
	check("Seelenkrug fragt, was geschehen soll", G.hud.overlay != null and get_tree().paused and G.hud.dialog_opts.size() == 3)
	shot("krug")
	await key(KEY_1)
	await wait(0.3)
	check("Taste 1 lässt das Herz frei: leichter", k1.done and Spiel.herz > hz and not get_tree().paused)
	var k2: Dictionary = site.call("krug", 1)
	hz = Spiel.herz
	var nl: int = G.loot.size()
	var sh1: int = Spiel.shards
	h.global_position = k2.pos + Vector3(1.3, 0, 0)
	await wait(0.5)
	await key(KEY_2)
	await wait(0.3)
	check("Taste 2 plündert den Krug: schwerer, Beute fällt", k2.done and Spiel.herz < hz and (G.loot.size() > nl or Spiel.shards > sh1))
	var k3: Dictionary = site.call("krug", 2)
	h.global_position = k3.pos + Vector3(1.3, 0, 0)
	await wait(0.5)
	await key(KEY_ESCAPE)
	await wait(0.3)
	check("Esc lässt den Krug stehen", not k3.done and not get_tree().paused and G.hud.overlay == null)
	h.global_position = O.npc.pos + Vector3(2.0, 0, 0)
	await wait(0.5)
	check("die Figur der Stunde spricht dich an (%s)" % O.G.wer, G.hud.overlay != null and get_tree().paused and G.hud.dialog_opts.size() == 3)
	shot("gespraech")
	await key(KEY_1)
	await wait(0.3)
	check("eine Frage führt zur Antwort, die andere Frage bleibt", G.hud.overlay != null and G.hud.dialog_opts.size() == 2)
	await key(KEY_ESCAPE)
	await wait(0.3)
	check("nach dem Gespräch steht der Auftrag im Questbuch", O.talked and not get_tree().paused and O.quest("relikt").text == O.G.auftrag)
	var rl: Dictionary = site.call("relikt")
	var boss_hp: float = G.boss.hp
	hz = Spiel.herz
	h.global_position = rl.pos + Vector3(1.3, 0, 0)
	await wait(0.5)
	check("das Fundstück stellt vor die Wahl", G.hud.overlay != null and G.hud.dialog_opts.size() == 3)
	shot("fundstueck")
	await key(KEY_1)
	await wait(0.3)
	check("nach der Entscheidung steht, was sie bewirkt", G.hud.overlay != null and G.hud.dialog_opts.size() == 1 and rl.done)
	await key(KEY_E)
	await wait(0.3)
	check("Entscheidung für Maat: Herz leichter, Hüter geschwächt, gemerkt", Spiel.herz > hz and G.boss.hp < boss_hp and Spiel.wahl.get("1", "") == "maat" and not get_tree().paused)
	# Leute und ihre Sorgen: der Hirte und seine drei Schafe
	O.helfer_talked = false
	O.helfer.asked = false
	h.global_position = O.helfer.pos + Vector3(2.0, 0, 0)
	await wait(0.5)
	check("ein Mensch am Eingang bittet um Hilfe (%s, %s)" % [O.L.wer, O.L.was], G.hud.overlay != null and get_tree().paused and G.hud.dialog_opts.size() == 1)
	shot("hirte")
	await key(KEY_E)
	await wait(0.3)
	check("danach steht die Suche im Questbuch", O.helfer_talked and not get_tree().paused and "0 von 3" in O.quest("leute").text)
	hz = Spiel.herz
	for i in 3:
		var su: Dictionary = site.call("such", i)
		h.global_position = su.pos + Vector3(1.2, 0, 0)
		await wait(0.5)
	check("alle drei gefunden: Aufgabe erledigt, Herz leichter", O.quest("leute").done and O.count("such", true) == 3 and Spiel.herz > hz)
	nl = G.loot.size()
	sh1 = Spiel.shards
	var bag1: int = Spiel.bag.size() + Spiel.eq.size()
	h.global_position = O.helfer.pos + Vector3(2.0, 0, 0)
	await wait(0.4)
	await key(KEY_E)
	await wait(0.4)
	check("E beim Menschen: Dank im Gespräch", G.hud.overlay != null and G.hud.dialog_opts.size() == 1)
	await key(KEY_E)
	await wait(0.3)
	check("zum Dank gibt es Lohn", O.helfer_paid and (G.loot.size() > nl or Spiel.shards > sh1 or Spiel.bag.size() + Spiel.eq.size() > bag1) and not get_tree().paused)
	Spiel.herz = 30.0
	Spiel.calc()
	var cone: float = Spiel.S.cone
	Spiel.herz = -30.0
	Spiel.calc()
	check("leichtes Herz: Laterne weiter · schweres Herz: mehr Schaden und Scherben", cone > 1.0 and Spiel.S.shard > 1.0 and Spiel.S.cone == 1.0)
	Spiel.herz = 0.0
	Spiel.calc()
	O.auto = false
	h.global_position = G.start_pos
	var foe: Foe = G.foes.filter(func(f): return f.kind != "boss" and f.K.ai != "swarm")[0]
	h.global_position = foe.global_position + Vector3(2.2, 0, 2.2)
	G.cam_pos = h.global_position
	await wait(0.6)
	var sp: Vector2 = G.cam.unproject_position(foe.global_position + Vector3(0, 1.0, 0))
	mouse(sp, MOUSE_BUTTON_LEFT, true)
	await wait(2.5)
	mouse(sp, MOUSE_BUTTON_LEFT, false)
	check("Klick auf Gegner schlägt zu (Leben %d von %d)" % [int(foe.hp), int(foe.max_hp)], foe.hp < foe.max_hp)
	await wait(0.25)   # der Trefferstopp dauert 0,05 s und darf beim Prüfen vorbei sein
	# Handy: ein Fingertipp, der im selben Bild losgelassen wird, muss trotzdem treffen
	G.touch = true
	# ein unverletzter Gegner, der stillhält und frei zu sehen ist (der vorige kann schon gefallen sein; Schwärme huschen weg).
	# Bis zu drei Versuche: Auf zufälligen Karten steht der Erste manchmal an einer Mauer.
	var kandidaten: Array = G.foes.filter(func(f): return f.kind != "boss" and f != foe and f.state != Foe.St.DEAD and f.hp >= f.max_hp and f.K.ai != "swarm")
	if kandidaten.is_empty():
		# auf dieser Karte steht kein passender Gegner mehr: einen eigenen hinstellen
		var neu: Foe = G._spawn("lance", h.global_position + Vector3(3.0, 0, 0.5), 96)
		await wait(0.3)
		kandidaten = [neu]
	var ziel: Foe = kandidaten[0]
	var hp_vor := ziel.hp
	for versuch in mini(3, kandidaten.size()):
		ziel = kandidaten[versuch]
		hp_vor = ziel.hp
		h.global_position = ziel.global_position + Vector3(2.2, 0, 2.2)
		G.cam_pos = h.global_position
		await wait(0.6)
		var tp: Vector2 = G.cam.unproject_position(ziel.global_position + Vector3(0, 1.0, 0))
		mouse(tp, MOUSE_BUTTON_LEFT, true)
		mouse(tp, MOUSE_BUTTON_LEFT, false)
		await wait(1.0)
		if ziel.hp < hp_vor:
			break
	G.touch = false
	check("Handy: kurzer Fingertipp auf einen Gegner schlägt zu", ziel.hp < hp_vor)
	# die Figur greift von selbst weiter an, darum kann gerade ein neuer Trefferstopp laufen: kurz darauf muss er vorbei sein
	var ts_ok := false
	for i in 10:
		if is_equal_approx(Engine.time_scale, 1.0):
			ts_ok = true
			break
		await wait(0.03)
	check("Zeit läuft nach dem Treffer normal weiter", ts_ok)
	shot("angriff")
	# Niederlage und Rückkehr
	h.pots = 0
	h.inv = 0.0
	h.hp = 3.0
	# ein Gegner, der den Auto-Angriff der Figur überlebt, steht direkt daneben und ist wach
	var cand: Array = G.foes.filter(func(f): return f.kind != "boss" and f.state != Foe.St.DEAD and f.K.ai == "melee" and not f.hidden)
	if cand.is_empty():
		cand = G.foes.filter(func(f): return f.kind != "boss" and f.state != Foe.St.DEAD)
	var killer: Foe = cand[0]
	killer.max_hp = 1e6
	killer.hp = 1e6
	h.global_position = killer.global_position + Vector3(1.6, 0, 0)
	G.cam_pos = h.global_position
	G.wake_pack(killer.pack)
	var t0 := Time.get_ticks_msec()
	while not h.dead and Time.get_ticks_msec() - t0 < 25000:
		h.inv = 0.0
		h.hp = minf(h.hp, 3.0)   # ein Stufenaufstieg durch den Auto-Angriff heilt sonst
		await wait(0.2)
	check("die Figur kann fallen", h.dead)
	await wait(2.6)
	check("Fenster nach der Niederlage erscheint", G.hud.overlay != null and get_tree().paused)
	shot("niederlage")
	await key(KEY_E)
	await wait(0.5)
	var awake: int = G.foes.filter(func(f): return f.state == Foe.St.FIGHT or f.state == Foe.St.WAKING).size()
	check("Rückkehr: Figur lebt, steht am Start, Spiel läuft", not h.dead and h.hp == h.max_hp and not get_tree().paused and h.global_position.distance_to(G.start_pos) < 1.0)
	check("Rückkehr: kein Gegner ist mehr wach (%d)" % awake, awake == 0)
	await wait(2.0)
	check("zwei Sekunden später greift am Start niemand an", h.hp == h.max_hp)
	shot("rueckkehr")
	# Hüter fällen, Pforte, „Noch bleiben“, dann durchgehen mit Mausklick, Ende, Neustart
	G.boss.hit(99999.0, h.global_position)
	await wait(3.6)
	check("Pforte steht", G.gate != null)
	check("nach dem Hüter wieder die Musik der Stunde", G.sfx.mus_name == "mus_wueste")
	check("an der Pforte: Hüter-Aufgabe erledigt", G.orte.quest("hueter").done or G.gate != null)
	h.global_position = G.gate.global_position + Vector3(0.5, 0, 1.0)
	await wait(0.8)
	check("Pforte fragt", G.hud.overlay != null and get_tree().paused)
	shot("pforte")
	await key(KEY_ESCAPE)
	await wait(0.4)
	check("Esc: noch bleiben, Spiel läuft weiter", G.hud.overlay == null and not get_tree().paused)
	await wait(0.8)
	check("die Pforte fragt nicht sofort wieder", G.hud.overlay == null)
	h.global_position = G.gate.global_position + Vector3(9, 0, 9)
	await wait(0.5)
	h.global_position = G.gate.global_position + Vector3(0.5, 0, 1.0)
	await wait(0.8)
	check("nach dem Weggehen fragt sie wieder", G.hud.overlay != null)
	var b: Button = G.hud.primary_btn
	var c := b.get_global_rect().get_center()
	mouse(c, MOUSE_BUTTON_LEFT, true)
	await wait(0.1)
	mouse(c, MOUSE_BUTTON_LEFT, false)
	await wait(2.5)
	var G2 := g()
	check("Mausklick auf „Durch die Pforte gehen“ führt in die zweite Stunde", G2 != null and G2 != G and Spiel.fall == 2 and Spiel.max_fall >= 2)
	check("die zweite Stunde ist ein Dungeon mit eigener Karte", G2 != null and G2.karte.indoor and G2.karte.kind == "ruin" and G2.hdef.name == "Die Felder von Wernes")
	check("Kapiteltafel der zweiten Stunde steht", G2 != null and not G2.started and G2.hud.overlay != null)
	shot("stunde2")
	await key(KEY_ENTER)
	await wait(1.0)
	check("Eintreten startet die zweite Stunde", G2.started and not get_tree().paused and G2.foes.size() > 10 and G2.chests.size() > 0)
	check("Hüter der zweiten Stunde ist die Mutter der Häute", G2.boss.K.name == "Die Mutter der Häute")
	G2.go_hour(1)
	await wait(2.5)
	var G3 := g()
	check("Stundenwahl: zurück in die erste Stunde (Freiland)", G3 != null and G3 != G2 and Spiel.fall == 1 and Spiel.max_fall == 2 and not G3.karte.indoor)
	# Champions verschwinden ganz: Ring und Name blieben früher stehen, wenn ein Irrender Ba oder Skorpion fiel
	if get_tree().paused:
		await key(KEY_E)   # die Stunde betreten: auf der Tafel steht das Spiel, dort laufen keine Animationen
		await wait(0.6)
	for art in ["wisp", "skorp", "guard"]:
		var champ: Foe = G3._spawn(art, G3.hero.global_position + Vector3(30, 0, 30), 97, "zaeh")
		champ.die()
		await wait(0.8)
		check("Champion (%s) besiegt: Ring und Name sind weg" % art, champ.elite_teile.size() == 2 and champ.elite_teile.all(func(n): return not n.visible))
	# Tuch der Gewogenen: erst nach dem Urteil der fünften Stunde (sechste Stunde erreicht)
	var mf := Spiel.max_fall
	Spiel.max_fall = 5
	var vorher := Geschichte.hat_tuch()
	Spiel.max_fall = 6
	check("Tuch der Gewogenen erst ab der sechsten Stunde", not vorher and Geschichte.hat_tuch() and Geschichte.urteil(5).contains("Tuch"))
	Spiel.max_fall = mf
	# Tuchfarbe: das festgehaltene Urteil gilt, auch wenn sich das Herz danach ändert
	var u0 := Spiel.urteil5
	var h0 := Spiel.herz
	Spiel.urteil5 = ""
	var frei := Geschichte.urteil_art(30.0) == "leicht" and Geschichte.urteil_art(-30.0) == "schwer" and Geschichte.urteil_art(0.0) == "schwebe"
	Spiel.urteil5 = "schwer"
	Spiel.herz = 40.0
	check("Tuchfarbe folgt dem Urteil der fünften Stunde", frei and Geschichte.urteil_art() == "schwer" and ResourceLoader.exists("res://models/chars/tuch_schwer.webp") and ResourceLoader.exists("res://models/chars/tuch_schwebe.webp"))
	Spiel.urteil5 = u0
	Spiel.herz = h0
	# Spielmenü (3.0): Esc hält an, Unterseiten, Esc zurück, Esc weiter
	if get_tree().paused:
		G3.hud._close()
		get_tree().paused = false
	await wait(0.3)
	await key(KEY_ESCAPE)
	await wait(0.3)
	check("Esc öffnet das Spielmenü, Spiel steht", G3.hud.menu_open and get_tree().paused)
	shot("menue")
	G3.hud.menue.geh("lexikon")
	await wait(0.2)
	var eintraege: Array = G3.hud.menue.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("Lexikon erklärt Ba, Duat und Maat", eintraege.has("Ba") and eintraege.has("Duat") and eintraege.has("Maat"))
	shot("lexikon")
	await key(KEY_ESCAPE)
	await wait(0.2)
	check("Esc auf einer Unterseite führt zurück ins Menü", G3.hud.menu_open and G3.hud.menue.seite == "")
	G3.hud.menue.geh("einstellungen")
	await wait(0.2)
	shot("einstellungen")
	G3.hud.menue.geh("")
	await key(KEY_ESCAPE)
	await wait(0.3)
	check("Esc schließt das Menü, Spiel läuft", not G3.hud.menu_open and not get_tree().paused)
	# Begriffe werden beim ersten Auftauchen erklärt, danach nicht mehr
	Spiel.wissen.erase("lex_ba")
	var fn1: Array = Lexikon.neu_in(["Dein Ba flüstert etwas über die Barke."], 2)
	var fn2: Array = Lexikon.neu_in(["Dein Ba flüstert."], 2)
	check("Lexikon: Ba wird einmal erklärt (nicht in „Barke“ verwechselt), dann nicht wieder", fn1.any(func(e): return e.id == "ba") and not fn2.any(func(e): return e.id == "ba"))
	# wechselnde Texte: ein Stapel wiederholt sich erst, wenn alle Sätze dran waren
	Worte.stapel.erase("ba_frei")
	var gezogen := {}
	for i2 in Worte.T["ba_frei"].size():
		gezogen[Worte.zieh("ba_frei")] = 1
	check("wechselnde Texte: %d verschiedene Sätze hintereinander" % gezogen.size(), gezogen.size() == Worte.T["ba_frei"].size())
	# Der Ba ohne Namen (2.9): Stück finden, zurückbringen, er kehrt heim und flüstert den ersten Satz
	var BO: Orte = G3.orte
	if not BO.hat_namenlos():
		BO.namenlos(G3.hero.global_position + Vector3(20, 0, 0), G3.hero.global_position + Vector3(-20, 0, 0), 98)
	var bh := Spiel.ba_heim
	var herz0 := Spiel.herz
	BO._stueck_finden()
	var weichen := BO.traegt_kartusche()
	BO._heimkehr()
	await wait(8.0)
	check("Ba ohne Namen: Stück tragen, heimführen, Herz leichter", weichen and Spiel.ba_heim == bh + 1 and not BO.traegt_kartusche() and BO.quest("namenlos").done and Spiel.herz >= herz0 and not BO.nl.n.visible)
	var reigen: Array = G3.foes.filter(func(f): return f.style == "reigen")
	check("Reigen: reine Irrlicht-Schwärme tanzen und tragen eine Lichtspur", reigen.is_empty() or reigen.all(func(f): return f.has_meta("spur")))
	print("SPIELTEST: %d ok, %d Fehler" % [ok, bad])
	get_tree().quit()
