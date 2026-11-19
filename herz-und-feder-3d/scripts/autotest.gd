extends Node
# Testmodus (Start mit „-- --autotest“): ein einfacher Bot spielt die Stunde durch, schreibt Zustände ins Protokoll
# und speichert Bilder nach test_out/. So lässt sich das Spiel ohne Menschen und ohne Bildschirm prüfen.

var game: Node
var t := 0.0
var shot_t := 0.0
var log_t := 0.0
var n := 0
var frames := 0
var phase := "tafel"
var stuck_t := 0.0
var last_pos := Vector3.ZERO
var burst := 0
var max_t := 420.0
var every := 5.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_out"))
	FileAccess.open("res://test_out/.gdignore", FileAccess.WRITE)   # Testbilder nicht als Spielgrafik einlesen
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--max="): max_t = float(a.substr(6))
		if a.begins_with("--every="): every = float(a.substr(8))
	game.hud.show_chapter(Stunden.case_no(Spiel.fall), game.hdef.name, game.hdef.lead, game.hdef.brief, "Eintreten", func(): game.begin())

func shot(tag: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://test_out/%03d_%s.png" % [n, tag])
	n += 1

func _process(_d: float) -> void:
	frames += 1
	if phase == "tafel" and frames == 40:
		shot("tafel")
		game.hud.press_primary()
		phase = "spiel"
		if "--rundgang" in OS.get_cmdline_user_args():
			phase = "rundgang"
			rundgang()
		elif Array(OS.get_cmdline_user_args()).any(func(a): return a.begins_with("--ort=")):
			phase = "ort"
			ort_bilder()
		elif "--namenlos" in OS.get_cmdline_user_args():
			phase = "namenlos"
			namenlos_bilder()
	if burst > 0:
		burst -= 1
		if burst % 3 == 0:
			shot("folge")

func _physics_process(delta: float) -> void:
	if phase != "spiel":
		return
	var h: Hero = game.hero
	if game.get_tree().paused:
		# Fenster: Niederlage bestätigen, Pforte ansehen und durchgehen
		if game.hud.overlay and frames % 30 == 0:
			if game.gate and not h.dead:
				# die Pforte führt in die nächste Stunde (die Szene lädt neu): hier endet der Bot
				shot("pforte_fenster")
				phase = "ende"
				finish("an der Pforte")
			elif game.hud.bag_open or game.hud.tree_open or game.hud.menu_open:
				game.hud.close_bag()   # Tasche, Werkstatt, Baum oder Menü: zu und weiter
			elif not game.hud.dialog_opts.is_empty():
				# Gespräch oder Entscheidung: der Bot nimmt immer die erste Antwort
				game.hud.press_option(0)
			else:
				shot("niederlage")
				game.hud.press_primary()
		return
	t += delta
	shot_t += delta
	log_t += delta
	if shot_t >= every:
		shot_t = 0.0
		shot("spiel")
	if t > 2.0 and t < 2.1 and burst == 0:
		burst = 18     # Folgebilder: Laufbewegung
	if log_t >= 10.0:
		log_t = 0.0
		print("t=%d hp=%d en=%d kills=%d/%d tode=%d pos=(%d,%d) wach=%d boss=%s aufrufe=%d dreiecke=%d" % [int(t), int(h.hp), int(h.en), game.kills, game.total, game.deaths, int(h.global_position.x), int(h.global_position.z), game.foes.filter(func(f): return f.state == Foe.St.FIGHT).size(), ("%d" % int(game.boss.hp)) if game.boss.state != Foe.St.DEAD else "tot",
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	if game.gate and game.gate_t > 2.9 and not has_meta("g"):
		set_meta("g", true)
		shot("pforte")
	if t > max_t:
		finish("Zeit abgelaufen")
		return
	if h.dead:
		return
	# Ziel: wacher Gegner, sonst der nächste schlafende, sonst Hüter, sonst Pforte
	var target := Vector3.ZERO
	var foe: Foe = null
	var bd := 1e9
	for f in game.live_foes():
		var d: float = f.global_position.distance_to(h.global_position) * (0.4 if f.state == Foe.St.FIGHT else 1.0) + (60.0 if f == game.boss and game.kills < game.total else 0.0)
		if d < bd:
			bd = d
			foe = f
	if foe:
		target = foe.global_position
	elif game.gate:
		target = game.gate.global_position
	else:
		return
	var to := target - h.global_position
	to.y = 0
	var dist := to.length()
	var dir := to.normalized()
	if not game.walkable(h.global_position, target):
		var path: PackedVector3Array = game.find_path(h.global_position, target)
		while path.size() > 0 and (path[0] - h.global_position).length() < 0.8:
			path.remove_at(0)
		if path.size() > 0:
			dir = (path[0] - h.global_position)
			dir.y = 0
			dir = dir.normalized()
	h.aim = target
	h.want_dir = dir
	if Spiel.tree_points() > 0:
		Spiel.auto_lernen()   # der Roboter lernt, was die Stufe hergibt (seit 3.0 wirkt nur Gelerntes)
	if foe:
		var near: int = game.live_foes().filter(func(f): return f.global_position.distance_to(h.global_position) < 4.2).size()
		var awake: bool = foe.state != Foe.St.SLEEP
		if h.hp < h.max_hp * 0.45:
			h.cast("potion")
		if near >= 3:
			h.cast(h.ORDER[3])
		if near >= 2 and h.en >= 40:
			if h.cast(h.ORDER[0]) and burst == 0 and n < 60: burst = 9
		if foe == game.boss and awake:
			h.cast(h.ORDER[2])
		if awake and dist > 7.0 and dist < 12.0 and game.walkable(h.global_position, target):
			h.cast(h.ORDER[1])
		if awake and dist > 5.0 and dist < 15.0 and h.en > 55 and game.sees(h.global_position, target):
			h.cast(h.ORDER[4])
		if dist < h.reach() - 0.3 + foe.radius and (not h.ranged() or game.sees(h.global_position, target)):
			h.want_dir = Vector3.ZERO
			if h.attack() and t > 8.0 and burst == 0 and n < 40:
				burst = 9   # Folgebilder: Hieb
	# hängt die Figur fest?
	if (h.global_position - last_pos).length() > 0.5:
		last_pos = h.global_position
		stuck_t = 0.0
	else:
		stuck_t += delta
		if stuck_t > 12.0 and h.want_dir.length() > 0.1:
			print("HÄNGT bei ", h.global_position, " Ziel ", target, " frei=", game.walkable(h.global_position, target))
			stuck_t = 0.0

# Rundgang (Start mit „-- --autotest --rundgang [--stunde=N]“): Figur an den Start, in Räume und vor den Hüter setzen
# und je ein Bild machen, zum Vergleichen von Mauern, Böden und Licht. Gegner ruhen dabei. Danach jede zehnte Bodenzelle
# betreten und prüfen, ob die Figur dort von der Kamera aus zu sehen ist (Durchblick der Mauern).
func rundgang() -> void:
	for f in game.foes:
		f.process_mode = Node.PROCESS_MODE_DISABLED
	var k: Karte = game.karte
	game.orte.auto = false
	game.freeze_foes = true
	print("RUNDGANG %s · %s · %s · Räume %d · Rudel %d · Truhen %d · Fackeln %d" % [Stunden.case_no(Spiel.fall), game.hdef.name,
		k.kind if k.indoor else "Freiland", k.rooms.size(), k.spots.size(), k.chests.size(), game.torches.size()])
	var spots := [[k.start, "start", false]]
	for r in k.rooms.slice(0, 3):
		spots.append([Vector2(r.cx, r.cy), "raum", false])
	for kind in ["figur", "feuer", "schrein", "krug", "relikt"]:
		for st in k.sites:
			if st.kind == kind:
				spots.append([st.p + Vector2(1.5, 1.5), kind, false])
				break
	if not k.pools.is_empty():
		spots.append([k.pools[0].p + Vector2(3.2, 3.2), "oase", false])
	if not k.road.is_empty():
		spots.append([k.road[k.road.size() / 2], "weg", false])
	spots.append([k.lair + Vector2(0, 3), "huter", false])
	spots.append([k.start, "start_niedrig", true])
	for s in spots:
		if game.low_gfx != s[2]:
			game.set_low(s[2])
		game.hero.global_position = Welt.cell_pos(s[0])
		game.cam_pos = game.hero.global_position
		game.hero.want_dir = Vector3.ZERO
		await get_tree().create_timer(1.0).timeout
		if get_tree().paused:
			# eine Truhe hat sich geöffnet: Fenster schließen, weiter
			game.hud._close()
			get_tree().paused = false
		await get_tree().create_timer(0.5).timeout
		shot("rundgang_%d_%s" % [Spiel.fall, s[1]])
	print("RUNDGANG fertig: %d Bilder" % n)
	get_tree().quit()

# Prüfbilder einzelner Orte: „-- --autotest --ort=werkstatt,figur,helfer“ stellt die Figur davor und hält das Bild fest
func ort_bilder() -> void:
	for f in game.foes:
		f.process_mode = Node.PROCESS_MODE_DISABLED
	game.freeze_foes = true
	game.orte.auto = false
	var arten := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ort="):
			arten = a.substr(6)
	for art in arten.split(","):
		if art == "pforte":
			# die Pforte (3.1): Sie steigt dort auf, wo der Hüter fiel; vier Bilder, während sie aufsteigt
			var gp: Vector3 = Welt.cell_pos(game.karte.lair)
			var weg: Vector3 = game.start_pos - gp
			weg = Vector3(0, 0, 1) if weg.z >= weg.x else Vector3(1, 0, 0)
			game.boss.process_mode = Node.PROCESS_MODE_DISABLED
			game.boss.visible = false
			game.hero.global_position = gp + weg.normalized() * 4.5
			game.cam_pos = game.hero.global_position
			await get_tree().create_timer(1.0).timeout
			game._build_gate(gp)
			game.gate_ask = false
			for i in 4:
				await get_tree().create_timer(1.1).timeout
				shot("pforte_%d" % i)
			continue
		for s in game.orte.sites:
			if s.kind != art:
				continue
			var zu: Vector3 = (game.start_pos - s.pos)
			zu.y = 0
			game.hero.global_position = s.pos + zu.normalized() * 3.6
			game.cam_pos = game.hero.global_position.lerp(s.pos, 0.5)
			game.hero.want_dir = Vector3.ZERO
			await get_tree().create_timer(1.6).timeout
			if get_tree().paused:
				game.hud._close()
				get_tree().paused = false
			await get_tree().create_timer(0.4).timeout
			shot("ort_" + art)
			break
	print("ORTE fertig: %d Bilder" % n)
	get_tree().quit()

# Prüfbilder des Ba ohne Namen (2.9): erster Blick, mit dem Stück im Reigen, die Heimkehr
func namenlos_bilder() -> void:
	var O: Orte = game.orte
	if not O.hat_namenlos():
		print("NAMENLOS: in dieser Stunde keiner")
		get_tree().quit()
		return
	var c: Vector3 = O.nl.pos
	var stellen := [[c + Vector3(0, 0, 7.5), "blick"], [O.stueck.pos + Vector3(2.5, 0, 2.5), "stueck"]]
	for s in stellen:
		game.hero.global_position = s[0]
		game.cam_pos = s[0]
		await get_tree().create_timer(2.5).timeout
		shot("namenlos_" + s[1])
	game.hero.global_position = O.stueck.pos + Vector3(0.6, 0, 0.6)
	await get_tree().create_timer(1.0).timeout
	print("NAMENLOS Stück getragen: ", O.traegt_kartusche())
	game.hero.global_position = c + Vector3(0, 0, 4.5)
	game.cam_pos = game.hero.global_position
	await get_tree().create_timer(2.0).timeout
	shot("namenlos_reigen")
	game.hero.global_position = c + Vector3(0, 0, 2.6)
	game.cam_pos = game.hero.global_position
	await get_tree().create_timer(1.0).timeout
	shot("namenlos_frage")
	if game.hud.overlay != null:
		game.hud._close()
		O._heimkehr()
	for i in 4:
		await get_tree().create_timer(1.1).timeout
		shot("namenlos_heim")
	print("NAMENLOS fertig: ba_heim=%d" % Spiel.ba_heim)
	get_tree().quit()

func finish(why: String) -> void:
	var h: Hero = game.hero
	print("ERGEBNIS: %s · Zeit %ds · Besiegte %d/%d · Hüter %s · Rückschläge %d · Leben %d · Bilder %d" % [why, int(t), game.kills, game.total, "tot" if game.boss.state == Foe.St.DEAD else "lebt", game.deaths, int(h.hp), n])
	get_tree().quit()
