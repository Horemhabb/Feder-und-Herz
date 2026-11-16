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
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--max="): max_t = float(a.substr(6))
		if a.begins_with("--every="): every = float(a.substr(8))
	game.hud.show_chapter(game.TXT.no, game.TXT.name, game.TXT.lead, game.TXT.brief, "Eintreten", func(): game.begin())

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
				shot("pforte_fenster")
				game.hud.press_primary()
				phase = "ende"
				get_tree().create_timer(1.5, true, false, true).timeout.connect(func(): shot("ende"); finish("durch die Pforte"))
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
		print("t=%d hp=%d en=%d kills=%d/%d tode=%d pos=(%d,%d) wach=%d boss=%s" % [int(t), int(h.hp), int(h.en), game.kills, game.total, game.deaths, int(h.global_position.x), int(h.global_position.z), game.foes.filter(func(f): return f.state == Foe.St.FIGHT).size(), ("%d" % int(game.boss.hp)) if game.boss.state != Foe.St.DEAD else "tot"])
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

# Rundgang (Start mit „-- --autotest --rundgang“): Figur an feste Stellen setzen und je ein Bild machen,
# zum Vergleichen von Mauern, Böden und Licht. Gegner ruhen dabei.
func rundgang() -> void:
	for f in game.foes:
		f.process_mode = Node.PROCESS_MODE_DISABLED
	var spots := [[Vector2i(2, 2), "start", false], [Vector2i(2, 4), "gang", false], [Vector2i(8, 7), "halle", false],
		[Vector2i(13, 3), "gruft", false], [Vector2i(13, 3), "gruft_niedrig", true], [Vector2i(8, 10), "sued", false],
		[Vector2i(18, 7), "ost", false], [Vector2i(2, 2), "start_niedrig", true]]
	for s in spots:
		if game.low_gfx != s[2]:
			game.set_low(s[2])
		game.hero.global_position = game.cell_pos(s[0].x, s[0].y)
		game.hero.want_dir = Vector3.ZERO
		await get_tree().create_timer(2.0).timeout
		shot("rundgang_" + s[1])
		var low_y := 0.0
		for w in game.sunk:
			low_y = minf(low_y, w.position.y)
		print("rundgang %s: %d Mauern/Pfeiler abgesenkt (tiefste %.1f m)" % [s[1], game.sunk.size(), low_y])
	# jede Bodenzelle einmal betreten: wo sinken Mauern, wo Pfeiler?
	var cells := 0
	var with_wall := 0
	var with_pillar := 0
	for cz in game.H:
		for cx in game.W:
			if not game.is_floor(cx, cz):
				continue
			cells += 1
			game.hero.global_position = game.cell_pos(cx, cz) + Vector3(1.2, 0, 1.2)
			game.cam_pos = game.hero.global_position
			await get_tree().create_timer(0.25).timeout
			var w := 0
			var pf := 0
			for node in game.sunk:
				if game.sunk[node] > 0.0:
					if node.has_meta("pfeiler"): pf += 1
					else: w += 1
			if w > 0: with_wall += 1
			if pf > 0: with_pillar += 1
	print("RUNDGANG Zellen: %d · davon sinkt eine Mauer bei %d, ein Pfeiler bei %d" % [cells, with_wall, with_pillar])
	print("RUNDGANG fertig: %d Bilder" % n)
	get_tree().quit()

func finish(why: String) -> void:
	var h: Hero = game.hero
	print("ERGEBNIS: %s · Zeit %ds · Besiegte %d/%d · Hüter %s · Rückschläge %d · Leben %d · Bilder %d" % [why, int(t), game.kills, game.total, "tot" if game.boss.state == Foe.St.DEAD else "lebt", game.deaths, int(h.hp), n])
	get_tree().quit()
