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
	check("Musik der ersten Stunde läuft (Wüstennacht)", G.sfx.mus_name == "mus_wueste" and G.sfx.mus[0].playing and G.sfx.mus[0].stream != null)
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
	check("Aufwerten kostet Fayencestaub und hebt die Stufe", Spiel.upgrade(ring) and int(ring.up) == 1 and Spiel.mats.staub == st0 - 3)
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
	# ein unverletzter Gegner: der vorige kann durch kritische Treffer schon gefallen sein
	var ziel: Foe = G.foes.filter(func(f): return f.kind != "boss" and f != foe and f.state != Foe.St.DEAD and f.hp >= f.max_hp)[0]
	var hp_vor := ziel.hp
	h.global_position = ziel.global_position + Vector3(2.2, 0, 2.2)
	G.cam_pos = h.global_position
	await wait(0.6)
	var tp: Vector2 = G.cam.unproject_position(ziel.global_position + Vector3(0, 1.0, 0))
	mouse(tp, MOUSE_BUTTON_LEFT, true)
	mouse(tp, MOUSE_BUTTON_LEFT, false)
	await wait(1.0)
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
	print("SPIELTEST: %d ok, %d Fehler" % [ok, bad])
	get_tree().quit()
