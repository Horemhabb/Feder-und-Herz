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
	Spiel.calc()
	h.apply_stats(true)
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
	# Fähigkeitenbaum
	Spiel.tree = {"r": {}, "a": {}, "p": {}, "key": false}
	var s1: String = h.ORDER[0]
	var pw0 := Spiel.sk_pow(s1)
	check("Rang erhöhen kostet einen Punkt", Spiel.tree_rank_up(s1) and Spiel.tree_rank_up(s1) and Spiel.tree_points() == Spiel.lvl - 2)
	check("Wucht ab Rang 2 macht stärker", Spiel.tree_aug(s1, "wucht") and Spiel.sk_pow(s1) > pw0 + 0.4)
	var hp0: float = Spiel.S.max_hp
	Spiel.tree_passive("zaeh")
	check("Starker Ka erhöht das Leben", Spiel.S.max_hp > hp0)
	check("Schlüsselstein erst ab 8 Punkten", not Spiel.tree_key())
	for k in 5:
		Spiel.tree_passive("scharf")
	check("Schlüsselstein ab 8 Punkten", Spiel.tree_key() and Spiel.has_key())
	Spiel.shards = 999
	check("Zurücksetzen gibt alle Punkte zurück", Spiel.respec() and Spiel.tree_points() == Spiel.lvl)
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
