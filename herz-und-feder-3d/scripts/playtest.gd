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
	if DisplayServer.get_name() == "headless":
		return   # ohne Bildschirm (Prüfung beim Bauen) gibt es kein Bild
	get_viewport().get_texture().get_image().save_png("res://test_out/pt_%s.png" % tag)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

# eine Stelle neben einem Gegner, von der aus er frei zu erreichen ist (die Karten sind zufällig: blind daneben gesetzt,
# stand die Figur manchmal in einem Felsblock, und die halbe Prüfung fiel als Folgefehler um)
func frei_neben(G: Node, pos: Vector3, r: float) -> Vector3:
	for i in 8:
		var q: Vector3 = pos + Vector3(cos(TAU * i / 8.0), 0, sin(TAU * i / 8.0)) * r
		if G.walkable(pos, q) and not G.astar.is_point_solid(G._sub(q)):
			return q
	return pos + Vector3(r, 0, 0)

func dialog_text(G: Node) -> String:
	if G.hud.overlay == null:
		return ""
	return " ".join(G.hud.overlay.find_children("*", "Label", true, false).map(func(l): return l.text))

# die Figur vor den Gast stellen, damit er im Bild ist (für die Bildschirmfotos)
func vor_gast(G: Node, O: Orte) -> void:
	var vorn: Vector3 = -O.gast_dir if O.gast_dir != Vector3.ZERO else (G.start_pos - O.gast.pos).normalized()
	G.hero.global_position = O.gast.pos + vorn * 3.0
	G.cam_pos = G.hero.global_position
	await wait(0.8)

func stunde_betreten(G: Node, n: int) -> Node:
	G.go_hour(n)
	await wait(2.5)
	var N := g()
	if get_tree().paused:
		await key(KEY_E)
		await wait(0.6)
	N.leben.stumm = true
	return N

# Etappe B: Hatschepsut in der dritten Stunde, Haremhab in der vierten, Rückbezüge und die Tafel am Ende des ersten Aktes
func geschichte_akt1(G: Node) -> void:
	var hz := Spiel.herz
	Spiel.wahl["2"] = "isfet"
	var G4: Node = await stunde_betreten(G, 3)
	var O: Orte = G4.orte
	O.auto = false
	check("Stunde 3: Hatschepsut steht als Umriss in einer Wand", Spiel.fall == 3 and not O.gast.is_empty() and O.GA.get("wand", false) and O.gast.vis.has("kartusche") and O.gast_dir != Vector3.ZERO)
	O.talk()
	await wait(0.3)
	check("Chaemwese bemerkt die gegessene Garbe (Rückbezug auf Stunde 2)", "Krümel" in dialog_text(G4))
	G4.hud.press_option(G4.hud.dialog_opts.size() - 1)
	await wait(0.3)
	O.t = 30.0
	O.ba_zuletzt = -99.0
	O._ba_tick(0.6, true)
	check("dein Ba erinnert an die Garbe", O.ba_done.has("rueck0") and "satt" in G4.hud.l_toast.text)
	if not O.gast.is_empty():
		await vor_gast(G4, O)
		shot("hatschepsut_wand")
		O.talk_gast()
		await wait(0.3)
		check("Hatschepsut spricht (Bart, Myrrhe, Anrede nach Klasse)", get_tree().paused and "Myrrhe" in dialog_text(G4) and Geschichte.anrede() in dialog_text(G4))
		shot("hatschepsut")
		G4.hud.press_option(2)   # „Soll ich deinen Namen zurückschreiben?“
		await wait(0.2)
		check("die ungewogene Wahl: nachziehen, lassen, nachdenken", G4.hud.dialog_opts.size() == 3)
		G4.hud.press_option(0)   # Die Kartusche nachziehen
		await wait(0.2)
		G4.hud.press_option(0)
		await wait(0.3)
		var mat: StandardMaterial3D = O.gast.vis.kartusche.get_meta("mat")
		check("Kartusche nachgezogen: gespeichert, Herz unverändert, Kartusche glüht, Name steht", Spiel.wahl.get("3h", "") == "kartusche" and is_equal_approx(Spiel.herz, hz) and mat.emission_energy_multiplier > 1.0 and O.gast.label.text == "Maatkare" and not get_tree().paused)
	Spiel.wahl["3"] = "maat"
	Spiel.wahl["4"] = "isfet"
	var G5: Node = await stunde_betreten(G4, 4)
	var O4: Orte = G5.orte
	O4.auto = false
	check("Stunde 4: Haremhab steht vor der Arena des Türhüters", Spiel.fall == 4 and not O4.gast.is_empty() and O4.gast.pos.distance_to(Welt.cell_pos(G5.karte.lair)) < 30.0)
	O4.t = 30.0
	O4.ba_zuletzt = -99.0
	O4._ba_tick(0.6, true)
	check("dein Ba erinnert an die Wand der dritten Stunde", O4.ba_done.has("rueck0") and "Wand" in G5.hud.l_toast.text)
	if not O4.gast.is_empty():
		await vor_gast(G5, O4)
		shot("haremhab_tor")
		O4.talk_gast()
		await wait(0.3)
		var tx := dialog_text(G5)
		check("Haremhab: Rückbezug auf den Namen (Stunde 3) und auf sein Versprechen (Stunde 2)", "Feigling" in tx and "Wort gegeben" in tx)
		shot("haremhab")
		G5.hud.press_option(0)   # „Warst du im Grab?“
		await wait(0.2)
		check("Haremhab hat die nachgezogene Kartusche gelesen", "Schief" in dialog_text(G5))
		G5.hud.press_option(G5.hud.dialog_opts.size() - 1)
		await wait(0.3)
		O4.talk_gast()
		await wait(0.3)
		check("Haremhab später: Rückbezug auf das Herz in der Laterne (Stunde 4)", "Zwei Herzen" in dialog_text(G5))
		G5.hud.press_option(0)
		await wait(0.3)
	var tafel := " ".join(Geschichte.akt1_tafel())
	check("Tafel des ersten Aktes: jede Entscheidung in einer Zeile", "Ruder liegt auf deinem Rücken" in tafel and "gegessen" in tafel and "dein Wort" in tafel and "weiß wieder" in tafel and "Maatkare" in tafel and "zwei Herzen" in tafel)
	G5._aktende_lohn()
	await wait(0.3)
	check("Ende des ersten Aktes zeigt den Rückblick und den Lohn", G5.hud.overlay != null and "Maatkare" in dialog_text(G5) and "Ba" in dialog_text(G5) and G5.hud.dialog_opts.size() >= 1)
	G5.hud.press_option(0)
	await wait(0.3)
	check("danach geht es weiter", not get_tree().paused and G5.gate_ask)

func pad_knopf(b: int) -> void:
	for gedrueckt in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = b
		e.pressed = gedrueckt
		Input.parse_input_event(e)
		await wait(0.12)

func pad_achse(a: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = a
	e.axis_value = v
	Input.parse_input_event(e)
	await wait(0.1)

# Fußrutschen messen: Eine Figur bewegt sich, je Physikschritt wird die Weltlage von Knöchel und Ballen beider Füße
# abgetastet. Aufgesetzt ist der tiefste dieser Punkte, solange er höchstens 4 cm über dem tiefsten Stand der ganzen
# Messung steht. Wie weit er dabei waagrecht über den Boden wandert, geteilt durch die Zeit am Boden, ist das Rutschen.
# Ergebnis: Rutschen in m/s (0 = der Fuß steht still) und Tempo der Figur über Grund in m/s.
func fussrutschen(a: Actor, dauer: float) -> Vector2:
	var ids := ["foot.l", "toes.l", "foot.r", "toes.r"].map(func(n): return a.skel.find_bone(n))
	# Bewegung im Physiktakt abspielen, damit Figur und Knochen zum selben Zeitpunkt gelesen werden
	var takt := a.ap.callback_mode_process
	a.ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var proben := []
	var t := 0.0
	while t < dauer:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
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
		# nur derselbe Punkt zählt: wechselt der Fuß, ist das ein Schritt und kein Rutschen
		if proben[i][2] == proben[i - 1][2] and p.y < boden + 0.04 and q.y < boden + 0.04:
			rutsch += Vector2(p.x - q.x, p.z - q.z).length()
			am_boden += t / proben.size()
	var weg: Vector3 = proben[-1][1] - proben[0][1]
	return Vector2(rutsch / maxf(am_boden, 0.01), Vector2(weg.x, weg.z).length() / t)

func run() -> void:
	await wait(1.6)
	var G := g()
	check("Startbildschirm liegt über dem Spiel, Spiel steht", G.hud.overlay != null and get_tree().paused and not G.started)
	check("ohne Spielstand: Startbildschirm im Modus „Neue Figur“", G.hud.intro_new and not Spiel.hat_stand)
	await key(KEY_E)
	await wait(2.0)
	G = g()
	G.auto_low_done = true   # die Grafik-Automatik bei Ruckeln würde der Prüfung von G zuvorkommen
	G.leben.stumm = true   # die lebendige Welt (3.2) hat eigene Prüfungen; hier soll kein Fundstück dazwischenfallen
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
	# Hinweise (4.1): eine neue Figur bekommt zuerst den Hinweis zum Laufen
	var HN: Hinweise = G.hud.hinweise
	await wait(2.6)
	check("Hinweis „laufen“ steht in der neuen Figur, ruhig über der Leiste", HN.aktuell == "laufen" and HN.panel.visible and "laufen" in HN.label.text and HN.panel.get_global_rect().end.y < G.hud.leiste.get_global_rect().position.y + 8.0)
	for i in 40:   # die Blende soll ganz da sein (bei langsamem Bild dauert das)
		if HN.panel.modulate.a >= 0.99:
			break
		await wait(0.1)
	shot("hinweis")
	var p0 := h.global_position
	await key(KEY_D, 0.9)
	check("D läuft (%.1f m)" % p0.distance_to(h.global_position), p0.distance_to(h.global_position) > 1.5)
	# Bewegungsgefühl: zwei Sekunden laufen in eine Richtung mit freier Bahn, dabei rutschen die Füße kaum
	var musik_lauf: float = G.sfx.mus_t   # auch dieser Abschnitt soll das Stück der Stunde nicht verkürzen
	await wait(0.4)
	var bahn := [KEY_D]
	for tasten in [[KEY_D], [KEY_S], [KEY_A], [KEY_W], [KEY_S, KEY_D], [KEY_W, KEY_A], [KEY_W, KEY_D], [KEY_S, KEY_A]]:
		var v := Vector2((1 if tasten.has(KEY_D) else 0) - (1 if tasten.has(KEY_A) else 0), (1 if tasten.has(KEY_S) else 0) - (1 if tasten.has(KEY_W) else 0))
		var r := (Vector3(1, 0, -1) * v.x + Vector3(1, 0, 1) * v.y).normalized()
		if G.walkable(h.global_position, h.global_position + r * 15.0):
			bahn = tasten
			break
	for k in bahn:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = true
		Input.parse_input_event(e)
	await wait(0.3)   # anlaufen
	var rh: Vector2 = await fussrutschen(h, 2.0)
	for k in bahn:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		Input.parse_input_event(e)
	# vor dem Abgleich der Schrittlänge (4.0) rutschten die Füße beim Laufen mit 6,0 m/s, also fast so schnell wie die Figur lief
	check("Laufen: die Füße rutschen kaum (%.2f m/s bei %.2f m/s)" % [rh.x, rh.y], rh.y > 4.0 and rh.x < 1.0)
	# Kein Flattern zwischen Stehen, Gehen und Laufen: eine Sekunde geradeaus, dann Kehrtwende. Früher sprang die Bewegung
	# bei jeder Kehrtwende von Laufen über Gehen und Stehen zurück zum Laufen (vier Überblendungen in 0,2 s).
	var zurueck := bahn.map(func(k): return {KEY_D: KEY_A, KEY_A: KEY_D, KEY_W: KEY_S, KEY_S: KEY_W}[k])
	var gaenge := [h.a_idle, h.a_walk, h.a_run]
	var flattern := [0, 0]   # [Wechsel geradeaus, Wechsel bei der Kehrtwende]
	var lief := false
	for runde in 2:
		for k in (bahn if runde == 0 else zurueck):
			var e := InputEventKey.new()
			e.keycode = k
			e.physical_keycode = k
			e.pressed = true
			Input.parse_input_event(e)
		var alt := h.cur_anim
		var t := 0.0
		while t < (1.2 if runde == 0 else 0.8):
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			if h.cur_anim != alt and gaenge.has(h.cur_anim) and gaenge.has(alt) and (runde == 1 or t > 0.4):
				flattern[runde] += 1
			alt = h.cur_anim
		lief = h.cur_anim == h.a_run
		for k in (bahn if runde == 0 else zurueck):
			var e := InputEventKey.new()
			e.keycode = k
			e.physical_keycode = k
			Input.parse_input_event(e)
	check("Gehen und Laufen flattern nicht: geradeaus %d Wechsel, bei der Kehrtwende %d (und läuft danach)" % flattern, flattern[0] == 0 and flattern[1] <= 1 and lief)
	await wait(0.3)
	G.sfx.mus_t = musik_lauf
	await wait(0.3)
	check("Hinweis „laufen“ verschwindet nach dem Laufen und ist im Spielstand gemerkt", HN.aktuell != "laufen" and not (HN.panel.visible and "laufen" in HN.label.text) and Spiel.gesehen("hinweis_laufen"))
	# Hinweise: kommt nicht wieder, Schalter, Angriff, Heilen, Ausweichen, Text je Eingabeart
	var pos_vor: Vector3 = h.global_position
	h.global_position = G.start_pos   # am Eingang ist es ruhig: in der Zeit dieses Abschnitts soll kein Gegner erwachen
	var musik_t: float = G.sfx.mus_t   # das Stück der Stunde zählt Zeit mit: dieser Abschnitt soll es nicht verkürzen
	HN.ausgeloest.clear()
	HN.start_pos = Vector3.ZERO
	HN.aktiv_t = 0.0
	await wait(1.0)
	check("Hinweis „laufen“ kommt nicht wieder", HN.aktuell != "laufen" and not HN.ausgeloest.has("laufen"))
	var textfehler := 0
	for hid in Hinweise.FOLGE:
		for m in ["maus", "pad", "touch"]:
			var tx := HN.text_fuer(hid, m)
			if tx == "" or "!" in tx or tx.length() > 70:
				textfehler += 1
	check("Texte: für jeden Hinweis und jede Eingabeart kurz und ohne Ausrufezeichen", textfehler == 0 and "Stick" in HN.text_fuer("laufen", "pad") and "Finger" in HN.text_fuer("laufen", "touch") and "Maustaste" in HN.text_fuer("laufen", "maus"))
	Spiel.wissen.erase("hinweis_angriff")
	h.hits = 0
	var hf: Foe = G.foes.filter(func(f): return f.kind != "boss").back()
	HN.ruhe = 0.3
	HN.nah = 100000.0   # „ein Gegner in der Nähe“, ohne einen zu wecken: irgendein lebender genügt
	Spiel.einst["hinweise"] = 0.0
	await wait(1.0)
	check("Schalter „Hinweise“ aus: kein Hinweis, auch mit Gegner in der Nähe", HN.aktuell == "" and not HN.panel.visible)
	Spiel.einst["hinweise"] = 1.0
	Spiel.wissen.erase("hinweis_angriff")
	h.hits = 0
	await wait(1.5)
	check("Schalter an: bei einem Gegner in der Nähe erscheint „angriff“", HN.aktuell == "angriff" and HN.panel.visible)
	h.aim = hf.global_position
	h.attack()
	await wait(0.3)
	check("Hinweis „angriff“ verschwindet nach dem Zuschlagen und ist gemerkt", HN.aktuell != "angriff" and Spiel.gesehen("hinweis_angriff"))
	HN.nah = 12.0
	h.hp = h.max_hp * 0.3
	await wait(0.9)
	check("Leben deutlich gesunken: Hinweis „heilen“", HN.aktuell == "heilen" and "Q" in HN.label.text)
	await key(KEY_Q)
	await wait(0.3)
	check("Hinweis „heilen“ verschwindet nach dem Trinken", HN.aktuell != "heilen" and Spiel.gesehen("hinweis_heilen"))
	Spiel.pots = Daten.POTS
	h.cd["potion"] = 0.0
	h.hp = h.max_hp * 0.6
	await wait(1.2)
	check("danach „ausweichen“, solange das Leben nicht voll ist", HN.aktuell == "ausweichen")
	await key(KEY_SPACE)
	await wait(0.3)
	check("Hinweis „ausweichen“ verschwindet nach dem Ausweichschritt", HN.aktuell != "ausweichen" and Spiel.gesehen("hinweis_ausweichen"))
	h.hp = h.max_hp
	await wait(1.0)
	HN.ruhe = 2.5
	G.sfx.mus_t = musik_t
	h.global_position = pos_vor
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
	check("auf Stufe 5: Eid neben dem Strahl ist lernbar, zum Blick des Udjat fehlt noch der Weg", G.hud.skill_ui["oath"].lock.text == "LERNEN" and G.hud.skill_ui["udjat"].lock.text == "WEG FEHLT" and Klassen.unlock_lvl("ermittler", "udjat") == 5)
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
	# die Grafik-Automatik kann auf diesem Prüfrechner schon vorher gegriffen haben: von „Hoch“ aus prüfen
	G.auto_low_done = true
	G.set_low(false, true)
	await key(KEY_G)
	check("G schaltet auf niedrige Grafik", G.low_gfx and not h.lantern.shadow_enabled)
	await key(KEY_G)
	check("G schaltet zurück", not G.low_gfx and h.lantern.shadow_enabled)
	# Hat der Abschnitt zu den Hinweisen einen Gegner geweckt, läuft gerade die Kampfmusik: auch das ist die Musik der Stunde
	var kampf: bool = G.sfx.mus_name == "mus_kampf"
	check("Musik der ersten Stunde läuft (Wüstennacht)%s" % (" (gerade Kampfmusik)" if kampf else ""), (kampf or G.sfx.mus_list.has(G.sfx.mus_name)) and G.sfx.mus[0].playing and G.sfx.mus[0].stream != null)
	await key(KEY_M)
	check("M schaltet den Ton aus", G.sfx.muted)
	await key(KEY_M)
	# Schritte: Gehen und Laufen haben eigene Aufnahmen (je Untergrund vier), Laufen ist kürzer; alle unter 0,4 s
	var schritte_da := true
	var laenge_geh := 0.0
	var laenge_lauf := 0.0
	var laenge_max := 0.0
	for ug in ["sand", "stein"]:
		for art in ["geh", "lauf"]:
			for i in range(1, 5):
				var st: AudioStream = G.sfx._stream("step_%s_%s%d" % [ug, art, i])
				if st == null:
					schritte_da = false
					continue
				laenge_max = maxf(laenge_max, st.get_length())
				if art == "geh":
					laenge_geh += st.get_length()
				else:
					laenge_lauf += st.get_length()
	check("Schritte: je Untergrund vier Geh- und vier Lauf-Aufnahmen, alle unter 0,4 s", schritte_da and laenge_max < 0.4)
	check("Schritte: Laufen und Gehen spielen verschiedene Klänge, Laufen kürzer",
		Sfx.schritt_name(false, true) != Sfx.schritt_name(false, false) and Sfx.schritt_name(true, true) != Sfx.schritt_name(true, false)
		and Sfx.schritt_name(true, true).ends_with("lauf") and laenge_lauf < laenge_geh)
	var kampf_da := true
	for n in ["skel_die1", "skel_die2", "skel_die3", "skel_attack1", "skel_attack2", "skel_attack3", "hit3", "hurt3", "swing3"]:
		kampf_da = kampf_da and G.sfx._stream(n) != null
	check("Kampfgeräusche (Hieb, Treffer, Skelett) sind geladen", kampf_da)
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
	Spiel.neu = 1   # ein Teil ist in der Tasche gelandet (eben angelegt wurde es nicht)
	await wait(3.5)
	check("erste Beute in der Tasche: Hinweis „tasche“", HN.aktuell == "tasche" and "I" in HN.label.text)
	await key(KEY_I)
	await wait(0.3)
	check("I öffnet die Tasche, Spiel steht", G.hud.bag_open and get_tree().paused and G.hud.overlay != null)
	check("Hinweis „tasche“ ist erledigt und gemerkt", HN.aktuell != "tasche" and Spiel.gesehen("hinweis_tasche"))
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
	check("die Figur der Stunde spricht dich an (%s)" % O.G.wer, G.hud.overlay != null and get_tree().paused and G.hud.dialog_opts.size() == O.G.fragen.size() + 1)
	shot("gespraech")
	await key(KEY_1)
	await wait(0.3)
	check("eine Frage führt zur Antwort, die anderen Fragen bleiben", G.hud.overlay != null and G.hud.dialog_opts.size() == O.G.fragen.size())
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
	check("dein Ba sagt etwas zur Entscheidung", O.ba_done.has("wahl") and Worte.BA_WAHL[0][0] in G.hud.l_toast.text)
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
	h.global_position = frei_neben(G, foe.global_position, 2.6)
	G.cam_pos = h.global_position
	await wait(0.6)
	var sp: Vector2 = G.cam.unproject_position(foe.global_position + Vector3(0, 1.0, 0))
	mouse(sp, MOUSE_BUTTON_LEFT, true)
	# wie ein Mensch: der Zeiger folgt dem Gegner (seit 4.0 kreisen Nahkämpfer ein und bleiben nicht stehen)
	for i in 25:
		await wait(0.1)
		if foe.state != Foe.St.DEAD:
			sp = G.cam.unproject_position(foe.global_position + Vector3(0, 1.0, 0))
			mouse(sp)
	mouse(sp, MOUSE_BUTTON_LEFT, false)
	check("Klick auf Gegner schlägt zu (Leben %d von %d)" % [int(foe.hp), int(foe.max_hp)], foe.hp < foe.max_hp)
	await wait(0.25)   # der Trefferstopp dauert 0,07 s und darf beim Prüfen vorbei sein
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
		h.global_position = frei_neben(G, ziel.global_position, 2.6)
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
	h.global_position = frei_neben(G, killer.global_position, 1.6)
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
	# seit 3.4: am Eingang oder an einer entzündeten Feuerschale, an der kein Gegner wartet
	var an_schale: bool = O.sites.any(func(s): return s.kind == "feuer" and s.done and s.pos.distance_to(h.global_position) < 2.5)
	check("Rückkehr: Figur lebt, steht am Eingang oder an einer entzündeten Feuerschale, Spiel läuft", not h.dead and h.hp == h.max_hp and not get_tree().paused and (h.global_position.distance_to(G.start_pos) < 1.0 or an_schale) and h.global_position.distance_to(G.rueck_pos) < 1.0)
	check("Rückkehr: kein Gegner ist mehr wach (%d)" % awake, awake == 0)
	await wait(2.0)
	check("zwei Sekunden später greift am Start niemand an", h.hp == h.max_hp)
	O._ba_tick(0.6, true)
	check("nach der Niederlage meldet sich dein Ba", O.ba_done.keys().any(func(k): return str(k).begins_with("tod")))
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
	check("Schrein des Thot steht auch in der zweiten Stunde (Dungeon)", not G2.orte.thot.is_empty())
	# Etappe B: Haremhab am Feldtor, mit Rückbezug auf das Ruder und einer eigenen Wahl
	var GO: Orte = G2.orte
	check("Stunde 2: Haremhab steht in der Stunde, mit Eintrag im Questbuch", not GO.gast.is_empty() and GO.GA.wer == "Haremhab" and not GO.quest("gast").is_empty() and GO.gast.pos.distance_to(G2.start_pos) < 40.0)
	if not GO.gast.is_empty():
		GO.talk_gast()
		await wait(0.3)
		check("Haremhab spricht und bemerkt das Ruder der ersten Stunde", G2.hud.overlay != null and get_tree().paused and "Ruder" in dialog_text(G2))
		G2.hud.press_option(1)   # „Wer hat das Tor geöffnet?“
		await wait(0.2)
		check("Haremhab fragt nach einem Versprechen (drei Antworten)", G2.hud.dialog_opts.size() == 3)
		G2.hud.press_option(0)   # „Ich sage es dir.“
		await wait(0.2)
		G2.hud.press_option(0)   # Gehen
		await wait(0.3)
		check("Wahl bei Haremhab ist gespeichert, wiegt nichts, Gespräch gemerkt", Spiel.wahl.get("2h", "") == "versprochen" and GO.gast_talked and Spiel.gesehen("gast_2") and not get_tree().paused and GO.quest("gast").done)
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
	# Ende „In der Schwebe“: das Ruder am Ufer folgt der Entscheidung der ersten Stunde
	var w0: Variant = Spiel.wahl.get("1")
	var hz0 := Spiel.herz
	Spiel.herz = 0.0
	Spiel.wahl["1"] = "maat"
	var ende_maat := Geschichte.urteil(12)
	Spiel.wahl["1"] = "isfet"
	var ende_isfet := Geschichte.urteil(12)
	check("Ende „In der Schwebe“: Ruder aus Zedernholz nur, wenn es aufgehoben wurde", ende_maat.contains("Du kennst es") and not ende_maat.contains("verbrannt") and ende_isfet.contains("verbrannt") and not ende_isfet.contains("Du kennst es"))
	if w0 == null:
		Spiel.wahl.erase("1")
	else:
		Spiel.wahl["1"] = w0
	Spiel.herz = hz0
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
	check("Ba ohne Namen: Stück tragen, heimführen, Herz leichter (%s %s %s %s %s %s, Pause %s, Fenster %s)" % [weichen, Spiel.ba_heim == bh + 1, not BO.traegt_kartusche(), BO.quest("namenlos").get("done", "-"), Spiel.herz >= herz0, not BO.nl.n.visible, get_tree().paused, G3.hud.l_title.text if G3.hud.overlay and "l_title" in G3.hud else str(G3.hud.overlay != null)], weichen and Spiel.ba_heim == bh + 1 and not BO.traegt_kartusche() and BO.quest("namenlos").done and Spiel.herz >= herz0 and not BO.nl.n.visible)
	var reigen: Array = G3.foes.filter(func(f): return f.style == "reigen")
	check("Reigen: reine Irrlicht-Schwärme tanzen und tragen eine Lichtspur", reigen.is_empty() or reigen.all(func(f): return f.has_meta("spur")))
	# Schrein des Thot (3.3): steht in jeder Stunde, dort wird kostenlos umgelernt, danach öffnet sich der Baum
	check("Schrein des Thot steht in der ersten Stunde (Freiland)", not G3.orte.thot.is_empty())
	if not G3.orte.thot.is_empty():
		G3.hero.global_position = frei_neben(G3, G3.orte.thot.pos, 2.0)
		Spiel.auto_lernen()
		var sp_vor := Spiel.tree_spent()
		await wait(0.2)
		G3.orte.thot_reden()
		await wait(0.3)
		G3.hud.press_option(0)
		await wait(0.5)
		check("Thot: Umlernen gibt alle %d Punkte zurück und öffnet den Baum" % sp_vor, sp_vor > 0 and Spiel.tree_spent() == 0 and G3.hud.tree_open)
		if G3.hud.tree_open:
			G3.toggle_tree()
		await wait(0.3)
		Spiel.auto_lernen()
	# Gamepad (4.0): Stick läuft, B weicht aus, X wirkt Fähigkeit 1, Start öffnet das Menü, Zurück die große Karte
	await pad_achse(JOY_AXIS_LEFT_X, 1.0)
	var p_vor: Vector3 = G3.hero.global_position
	await wait(0.6)
	check("Gamepad: linker Stick läuft (%.1f m)" % p_vor.distance_to(G3.hero.global_position), p_vor.distance_to(G3.hero.global_position) > 1.0)
	await pad_achse(JOY_AXIS_LEFT_X, 0.0)
	await pad_knopf(JOY_BUTTON_B)
	check("Gamepad: B weicht aus", G3.hero.dodge_cd > 0.0)
	var id1: String = G3.hero.ORDER[0]
	G3.hero.cd[id1] = 0.0
	G3.hero.en = 100.0
	await pad_knopf(JOY_BUTTON_X)
	check("Gamepad: X wirkt die erste Fähigkeit (%s)" % id1, G3.hero.cd[id1] > 0.0)
	await wait(0.6)
	await pad_knopf(JOY_BUTTON_START)
	check("Gamepad: Start öffnet das Menü", G3.hud.menu_open)
	await pad_knopf(JOY_BUTTON_START)
	check("Gamepad: Start schließt es wieder", not G3.hud.menu_open and not get_tree().paused)
	await pad_knopf(JOY_BUTTON_BACK)
	check("Gamepad: Zurück öffnet die große Karte", G3.hud.karte_open)
	await pad_knopf(JOY_BUTTON_B)
	check("Gamepad: B schließt sie", not G3.hud.karte_open and not get_tree().paused)
	G3.pad = false
	# Bewegungsgefühl: ein Krieger läuft aus 13 m auf die stehende Figur zu, dabei rutschen seine Füße kaum
	var hh: Hero = G3.hero
	var anlauf := Vector3(13, 0, 0)
	for i in 8:
		var r := Vector3(13, 0, 0).rotated(Vector3.UP, TAU * i / 8.0)
		if G3.walkable(hh.global_position, hh.global_position + r):
			anlauf = r
			break
	var krieger: Foe = G3._spawn("lance", hh.global_position + anlauf, 95)
	await wait(0.2)
	krieger.wake()
	await wait(0.5)
	var rk: Vector2 = await fussrutschen(krieger, 2.0)
	# vorher 6,2 m/s; der Rest kommt aus der Gehbewegung der Skelette selbst (schlurft auch beim besten Tempo)
	check("Gegner geht heran: die Füße rutschen kaum (%.2f m/s bei %.2f m/s)" % [rk.x, rk.y], rk.y > 1.0 and rk.x < 2.0)
	# Treffer-Zucken: kurz gekippt, danach wieder gerade
	krieger.hit(1.0, hh.global_position)
	await wait(0.06)
	var gekippt := absf(krieger.model.rotation.x) + absf(krieger.model.rotation.z)
	await wait(0.4)
	check("Treffer: der Gegner zuckt kurz (%.2f) und steht danach wieder gerade" % gekippt, gekippt > 0.05 and absf(krieger.model.rotation.x) + absf(krieger.model.rotation.z) < 0.001)
	G3.foes.erase(krieger)
	krieger.queue_free()
	# Lebendige Welt (3.2): Leute und Tiere sind da, ein Fundstück lässt sich aufheben, ein verlorenes Stück findet heim
	var LB: Leben = G3.leben
	check("Leben: Leute (%d) und Tiere (%d) sind unterwegs" % [LB.leute.size(), LB.tiere.size()], LB.leute.size() >= 2 and LB.tiere.size() >= 5)
	var offen: Array = LB.funde.filter(func(f): return not f.done and not f.has("fuer"))
	if not offen.is_empty():
		var sp0 := Spiel.shards
		G3.hero.global_position = offen[0].pos
		await wait(1.5)
		check("Fundstück: im Vorbeigehen aufgehoben, Splitter fallen", offen[0].done and (G3.loot.size() > 0 or Spiel.shards > sp0))
	var bitter: Array = LB.leute.filter(func(p): return not p.auftrag.is_empty())
	if not bitter.is_empty():
		var bp: Dictionary = bitter[0]
		bp.auftrag.stand = "gefragt"
		LB._fund({"art": bp.auftrag.art, "name": bp.auftrag.ding, "text": "", "fuer": bp}, G3.hero.global_position + Vector3(3, 0, 0))
		G3.hero.global_position += Vector3(3, 0, 0)
		await wait(1.0)
		check("Bitte: das verlorene Stück wird gefunden und gemeldet", bp.auftrag.stand == "gefunden")
	await geschichte_akt1(G3)
	print("SPIELTEST: %d ok, %d Fehler" % [ok, bad])
	get_tree().quit(1 if bad > 0 else 0)   # Fehlercode für die Prüfung beim Bauen (bauen.yml)
