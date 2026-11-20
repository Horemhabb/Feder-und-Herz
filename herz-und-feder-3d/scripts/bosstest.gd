extends Node
# Bosstest (4.0, Start mit „-- --neu --stunde=4 --bosstest“): der Stumme Türhüter in drei Phasen, die Rückkehr vor
# seine Arena nach einer Niederlage und der Lohn am Ende des ersten Aktes.

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

func shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_out"))
		img.save_png("res://test_out/boss_%s.png" % name)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	await wait(1.5)
	var G := g()
	while not G.started:
		G.hud.press_primary()
		await wait(1.6)
		G = g()
	if Stunden.hour_of(Spiel.fall) != 4:
		# eine neue Figur beginnt in Stunde 1: also gleich in die vierte Stunde
		Spiel.max_fall = maxi(Spiel.max_fall, 4)
		G.go_hour(4)
		await wait(2.5)
		G = g()
		while not G.started:
			G.hud.press_primary()
			await wait(1.6)
			G = g()
	var h: Hero = G.hero
	G.orte.auto = false
	G.leben.stumm = true
	Spiel.lvl = 8
	Spiel.auto_lernen()
	h.apply_stats(true)
	var B: Foe = G.boss
	check("Stunde 4: der Hüter ist der Stumme Türhüter und der Endgegner des Aktes (%s, Fall %d)" % [B.K.name, Spiel.fall], B.K.name == "Der Stumme Türhüter" and B.ist_aktende())
	# alle anderen Gegner schlafen weg, damit nur der Hüter kämpft
	for f in G.foes:
		if f != B:
			f.hit(1e9, f.global_position)
	await wait(0.5)
	var arena: Vector3 = G.arena_ort()
	check("vor der Arena gibt es einen freien Platz mit Weg zum Hüter", arena.distance_to(G.start_pos) > 1.0)
	h.inv = 9999.0
	h.global_position = B.global_position + (arena - B.global_position).normalized() * 8.0
	G.cam_pos = h.global_position
	B.hit(1.0, h.global_position)
	G.wake_pack(B.pack)
	await wait(3.0)
	check("der Hüter ist wach und der Kampf läuft", G.boss_awake and B.state == Foe.St.FIGHT)
	# Phase 2: bei zwei Dritteln Leben ruft er und ist unverwundbar
	B.hit(B.hp - B.max_hp * 0.64, h.global_position)
	await wait(0.3)
	var hp2 := B.hp
	B.hit(500.0, h.global_position)
	check("Phase 2 bei 66 %%: Schild, Treffer prallen ab (%d → %d)" % [int(hp2), int(B.hp)], B.phase == 2 and B.schild_t > 0.0 and B.hp == hp2)
	shot("phase2")
	# warten, bis er nicht mehr ruft (die Spielzeit kann unter Last langsamer laufen als die Uhr)
	for i in 30:
		if B.schild_t <= 0.0:
			break
		await wait(0.5)
	await wait(1.5)
	var fahle: int = G.foes.filter(func(f): return f.summoned and f.state != Foe.St.DEAD).size()
	check("Phase 2: Erloschene werden gerufen (%d)" % fahle, fahle >= 2)
	check("nach dem Rufen ist er wieder verwundbar", B.schild_t <= 0.0)
	# Phase 3: das Tor zerbricht, es wird dunkel, Sterne fallen
	var mond0: float = G.moon.light_energy
	B.hit(B.hp - B.max_hp * 0.31, h.global_position)
	await wait(4.5)
	check("Phase 3 bei 33 %%: dunkel (Mond %.2f → %.2f)" % [mond0, G.moon.light_energy], B.phase == 3 and G.moon.light_energy < mond0 * 0.5)
	h.inv = 0.0
	h.hp = h.max_hp
	var hp_vor := h.hp
	var sterne_gefallen := false
	for i in 30:
		await wait(0.2)
		h.inv = 0.0
		if h.hp < hp_vor:
			sterne_gefallen = true
			break
	shot("phase3")
	check("Phase 3: fallende Sterne (oder Stampfer) treffen, wer stehen bleibt", sterne_gefallen)
	# Niederlage: neu vor der Arena, der Hüter wieder voll und in Phase 1, das Licht zurück
	G.orte.boss_weak = 1   # eine Feuerschale hat ihn geschwächt: das soll den Neuversuch überdauern
	G.boss_summon(B, ["fahl", "fahl"])
	await wait(0.3)
	h.inv = 0.0
	h.hp = 1.0
	h.hurt(9999.0, B.global_position, B)
	await wait(2.6)
	G.hud.press_primary()
	await wait(2.5)
	check("Niederlage im Kampf: Neubeginn vor der Arena (tot %s, Abstand %.1f, Rückkehr %s, Arena %s)" % [h.dead, h.global_position.distance_to(G.rueck_pos), G.rueck_pos, arena], not h.dead and h.global_position.distance_to(G.rueck_pos) < 1.5 and G.rueck_pos.distance_to(arena) < 0.5)
	check("der Türhüter beginnt von vorn (Phase 1), mit der Schwächung der Feuerschale (%.0f %%), das Licht ist zurück" % (B.hp / B.max_hp * 100.0), B.phase == 1 and absf(B.hp - B.max_hp * 0.9) < 1.0 and G.moon.light_energy > mond0 * 0.8)
	var diener: int = G.foes.filter(func(f): return f.summoned and f.state != Foe.St.DEAD).size()
	check("die gerufenen Diener sind mit dem Versuch vergangen (%d)" % diener, diener == 0)
	# Sieg: Ende des ersten Aktes mit drei legendären Stücken zur Wahl
	var bag0 := Spiel.bag.size() + Spiel.eq.size()
	var legs0: Array = Spiel.eq.values().filter(func(it): return it.has("leg"))
	h.inv = 9999.0
	B.hit(1e9, h.global_position)
	await wait(6.5)
	check("Ende des ersten Aktes: Tafel mit drei Stücken zur Wahl", G.hud.overlay != null and G.hud.dialog_opts.size() == 3)
	check("die Pforte fragt erst, wenn der Lohn gewählt ist", not G.gate_ask)
	shot("aktende")
	G.hud.press_option(0)
	await wait(0.5)
	check("nach der Wahl darf die Pforte fragen, und der Lohn ist für diese Nacht vergeben", G.gate_ask and Spiel.gesehen(G._akt_lohn_key()))
	G.akt_lohn_genommen = false
	G._aktende_lohn()
	await wait(0.3)
	check("wer die Stunde wiederholt, bekommt den Lohn nicht noch einmal", G.hud.overlay == null)
	var legs1: Array = Spiel.eq.values().filter(func(it): return it.has("leg")) + Spiel.bag.filter(func(it): return it.has("leg"))
	check("das gewählte Stück gehört dir (legendär)", legs1.size() > legs0.size() or Spiel.bag.size() + Spiel.eq.size() > bag0)
	print("BOSSTEST: %d ok, %d Fehler" % [ok, bad])
	get_tree().quit()
