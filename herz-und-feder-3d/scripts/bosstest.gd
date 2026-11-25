extends Node
# Bosstest (Start mit „-- --neu --stunde=4 --bosstest“, braucht einen Bildschirm: xvfb-run … --rendering-driver opengl3)
# 4.0: der Stumme Türhüter in drei Phasen, die Rückkehr vor seine Arena nach einer Niederlage und der Lohn am Aktende.
# 4.1: die Hüter der Stunden 1, 2, 3 und 5 mit ihren eigenen Kampfmustern (jede Phase wird erreicht, jede Mechanik ist
# lösbar, der Kampf endet und räumt auf) und die Eigenschaften der Champions (jede wirkt und verschwindet mit ihm).
# Bilder: test_out/boss_*.png (jeder Hüter in jeder Phase, Champions mit jeder Eigenschaft).

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
	await RenderingServer.frame_post_draw
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
	# „--nur=mahaf,koenig“ prüft nur diese Teile (zum schnellen Nachprüfen)
	var nur := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nur="):
			nur = a.substr(6)
	if nur == "" or "tuer" in nur:
		await tuerhueter(G)
	if nur == "" or "mahaf" in nur:
		await mahaf()
	if nur == "" or "mutter" in nur:
		await mutter()
	if nur == "" or "koenig" in nur:
		await koenig()
	if nur == "" or "sammler" in nur:
		await sammler()
	if nur == "" or "apophis" in nur:
		await apophis()
	if nur == "" or "champ" in nur:
		await champions()
	print("BOSSTEST: %d ok, %d Fehler" % [ok, bad])
	get_tree().quit()

# ---------------------------------------------------------------- Hilfen
func stunde(n: int) -> Node:
	var G := g()
	Spiel.max_fall = maxi(Spiel.max_fall, n)
	G.go_hour(n)
	await wait(2.5)
	G = g()
	while not G.started:
		G.hud.press_primary()
		await wait(1.6)
		G = g()
	if get_tree().paused:
		G.hud.press_primary()
		await wait(0.6)
	var h: Hero = G.hero
	G.orte.auto = false
	G.leben.stumm = true
	Spiel.lvl = 8
	Spiel.auto_lernen()
	h.apply_stats(true)
	for f in G.foes:
		if f != G.boss and f.state != Foe.St.DEAD:
			f.xp = 0.0   # keine Stufenaufstiege: ihre Tafel läge über den Bildern
			f.hit(1e9, f.global_position)
	await wait(0.5)
	return G

# Held vor den Hüter stellen (unverwundbar) und den Hüter wecken
func wecken(G: Node, abstand := 8.0) -> void:
	var B: Foe = G.boss
	var h: Hero = G.hero
	var arena: Vector3 = G.arena_ort()
	h.inv = 9999.0
	h.global_position = B.global_position + (arena - B.global_position).normalized() * abstand
	h.reset_physics_interpolation()
	G.cam_pos = h.global_position
	B.hit(1.0, h.global_position)
	G.wake_pack(B.pack)
	await wait(3.0)
	# hält eine Tafel das Spiel an (Gespräch, Fund), sie schließen
	for i in 6:
		if not get_tree().paused:
			break
		G.hud.press_primary()
		await wait(0.6)

# Held wieder neben den Hüter (er wandert im Kampf) und die Kamera mit
func heran(G: Node, abstand := 7.0) -> void:
	var B: Foe = G.boss
	var h: Hero = G.hero
	var zu: Vector3 = h.global_position - B.global_position
	zu.y = 0.0
	if zu.length() < 0.5:
		zu = Vector3(1, 0, 0)
	var p: Vector3 = B.global_position + zu.normalized() * abstand
	if G.walkable(B.global_position, p):
		h.global_position = p
		h.reset_physics_interpolation()
	G.cam_pos = h.global_position

func auf(B: Foe, anteil: float) -> void:
	# Leben auf diesen Anteil senken (als Treffer, damit Phasen umschlagen)
	var vor := B.hp
	var ziel := B.max_hp * anteil
	B.schild_t = 0.0   # die Häutung der Mutter macht kurz unverwundbar: im Test nicht abwarten
	if B.kampf:
		B.kampf.offen_t = 0.0
	B.hit(maxf(1.0, B.hp - ziel), B.global_position + Vector3(0.5, 0, 0.5))
	if B.hp > ziel + 1.0 and B.hp == vor:
		print("    (Treffer prallte ab)")

func lebende(G: Node, rolle: String) -> Array:
	return G.foes.filter(func(f): return f.kind == "objekt" and f.rolle == rolle and f.state != Foe.St.DEAD)

# ---------------------------------------------------------------- Der Stumme Türhüter (4.0, Maßstab)
func tuerhueter(G: Node) -> void:
	var h: Hero = G.hero
	G.orte.auto = false
	G.leben.stumm = true
	Spiel.lvl = 8
	Spiel.auto_lernen()
	h.apply_stats(true)
	var B: Foe = G.boss
	check("Stunde 4: der Hüter ist der Stumme Türhüter und der Endgegner des Aktes (%s, Fall %d)" % [B.K.name, Spiel.fall], B.K.name == "Der Stumme Türhüter" and B.ist_aktende() and B.kampf == null)
	# alle anderen Gegner schlafen weg, damit nur der Hüter kämpft
	for f in G.foes:
		if f != B:
			f.hit(1e9, f.global_position)
	await wait(0.5)
	var arena: Vector3 = G.arena_ort()
	check("vor der Arena gibt es einen freien Platz mit Weg zum Hüter", arena.distance_to(G.start_pos) > 1.0)
	await wecken(G)
	check("der Hüter ist wach und der Kampf läuft", G.boss_awake and B.state == Foe.St.FIGHT)
	check("Hüter-Leiste: Name, Beiname und Phase I", G.hud.boss_box.visible and G.hud.l_boss_bei.text != "" and G.hud.l_boss_phase.text.begins_with("PHASE I "))
	await shot("tuer_p1")
	# Phase 2: bei zwei Dritteln Leben ruft er und ist unverwundbar
	B.hit(B.hp - B.max_hp * 0.64, h.global_position)
	await wait(0.3)
	var hp2 := B.hp
	B.hit(500.0, h.global_position)
	check("Phase 2 bei 66 %%: Schild, Treffer prallen ab (%d → %d)" % [int(hp2), int(B.hp)], B.phase == 2 and B.schild_t > 0.0 and B.hp == hp2)
	await shot("tuer_p2")
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
	await shot("tuer_p3")
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
	await shot("aktende")
	G.hud.press_option(0)
	await wait(0.5)
	check("nach der Wahl darf die Pforte fragen, und der Lohn ist für diese Nacht vergeben", G.gate_ask and Spiel.gesehen(G._akt_lohn_key()))
	G.akt_lohn_genommen = false
	G._aktende_lohn()
	await wait(0.3)
	check("wer die Stunde wiederholt, bekommt den Lohn nicht noch einmal", G.hud.overlay == null)
	var legs1: Array = Spiel.eq.values().filter(func(it): return it.has("leg")) + Spiel.bag.filter(func(it): return it.has("leg"))
	check("das gewählte Stück gehört dir (legendär)", legs1.size() > legs0.size() or Spiel.bag.size() + Spiel.eq.size() > bag0)

# ---------------------------------------------------------------- Mahaf, das Leitlicht (Stunde 1)
func mahaf() -> void:
	var G: Node = await stunde(1)
	var B: Foe = G.boss
	var h: Hero = G.hero
	check("Stunde 1: Mahaf kämpft nach eigenem Muster", B.kampf != null and B.kampf.art == "wisp")
	await wecken(G, 7.0)
	check("Mahaf erwacht und kämpft (blieb vor 4.1 im Erwachen hängen)", B.state == Foe.St.FIGHT)
	await wait(2.5)
	await heran(G)
	check("Mahaf: der Kampf läuft, Angriffe mit Ansage (%s)" % ", ".join(B.kampf.cd.keys()), B.kampf.gestartet and B.kampf.cd.size() >= 1)
	await shot("mahaf_p1")
	var voll: float = Hero.LATERNE_WEITE * Spiel.S.cone
	auf(B, 0.62)
	await wait(0.3)
	check("Mahaf Phase 2 bei 65 %", B.kampf.phase == 2)
	var trug := []
	var hinweis := false
	for i in 20:
		await wait(0.4)
		trug = B.kampf._trugbilder()
		hinweis = hinweis or G.hud.l_boss_status.text.contains("golden")
		if trug.size() == 2:
			break
	await wait(1.0)
	check("Phase 2: die Laterne brennt schwach (%.1f von %.1f m)" % [h.lantern.omni_range, voll], h.lantern.omni_range < voll * 0.6)
	check("Phase 2: zwei Trugbilder führen im Kreis (%d, erzeugt %d)" % [trug.size(), B.kampf.trug_erzeugt], B.kampf.trug_erzeugt >= 2)
	hinweis = hinweis or G.hud.l_boss_status.text.contains("golden")
	check("Leiste: Hinweis auf das echte Licht", hinweis)
	await heran(G)
	await shot("mahaf_p2")
	# ein Trugbild zerplatzt in einen kleinen Reigen; das echte Licht, getroffen, zerreißt die Täuschung
	trug = B.kampf._trugbilder()
	if trug.size() > 0:
		trug[0].hit(1e6, h.global_position)
	await wait(0.1)
	check("ein getroffenes Trugbild zerplatzt in einen kleinen Reigen (übrig %d)" % B.kampf._trugbilder().size(), trug.size() > 0 and B.kampf._trugbilder().size() <= 1 and trug[0].state == Foe.St.DEAD)
	B.hit(B.max_hp * 0.075, h.global_position)
	await wait(0.2)
	check("das echte Licht getroffen: die Täuschung zerreißt", B.kampf._trugbilder().is_empty() and B.kampf.phase == 2)
	# Niederlage in Phase 2: Licht zurück, Trugbilder weg; beim neuen Erwachen nimmt er es wieder
	h.inv = 0.0
	h.hp = 1.0
	h.hurt(9999.0, B.global_position, B)
	await wait(2.6)
	for i in 8:
		G.hud.press_primary()
		await wait(1.0)
		if not h.dead:
			break
	await wait(1.5)
	check("Niederlage gegen Mahaf: die Laterne brennt wieder hell (%.1f), keine Trugbilder" % h.lantern.omni_range, h.lantern.omni_range > voll * 0.9 and B.kampf._trugbilder().is_empty() and not G.boss_awake)
	await wecken(G, 7.0)
	await wait(1.6)
	check("neues Erwachen in Phase 2: er nimmt das Licht wieder", B.kampf.phase == 2 and h.lantern.omni_range < voll * 0.6)
	auf(B, 0.28)
	await wait(1.5)
	check("Mahaf Phase 3 bei 30 %: das Ruder", B.kampf.phase == 3 and B.kampf.ruder != null and B.kampf.ruder.visible)
	B.kampf.cd["ruder"] = 0.0
	for i in 20:
		await wait(0.3)
		if B.kampf.cur.get("id", "") == "ruder" and B.kampf.zustand == "los":
			break
	await heran(G)
	await shot("mahaf_p3")
	B.hit(1e9, h.global_position)
	await wait(2.0)
	check("Mahaf fällt: Licht zurück in der Laterne (%.1f), alles aufgeräumt, Leiste weg" % h.lantern.omni_range, B.state == Foe.St.DEAD and h.lantern.omni_range > voll * 0.9 and B.kampf.objekte.is_empty() and not G.hud.boss_box.visible)

# ---------------------------------------------------------------- Die Mutter der Häute (Stunde 2)
func mutter() -> void:
	var G: Node = await stunde(2)
	var B: Foe = G.boss
	var h: Hero = G.hero
	check("Stunde 2: die Mutter der Häute kämpft nach eigenem Muster", B.kampf != null and B.kampf.art == "mutter")
	await wecken(G, 8.0)
	await heran(G)
	await shot("mutter_p1")
	var gr0: float = B.model.scale.x
	var spd0: float = B.spd
	auf(B, 0.73)
	await wait(1.0)
	var huellen: Array = B.kampf.huellen.filter(func(x): return x.state != Foe.St.DEAD)
	check("Häutung bei 75 %%: eine Hülle liegt im Sand (%d), sie selbst kleiner und schneller" % huellen.size(), B.kampf.phase == 2 and huellen.size() == 1 and huellen[0].huelle_t > 0.0 and B.model.scale.x < gr0 * 0.95 and B.spd > spd0)
	await heran(G)
	await shot("mutter_p2")
	if huellen.size() > 0:
		var x: Foe = huellen[0]
		var hp0: float = x.hp
		x.hit(10.0, h.global_position)
		check("die Hülle reißt leicht: dreifacher Schaden (%.0f)" % (hp0 - x.hp), absf((hp0 - x.hp) - 30.0) < 0.5)
		for i in 20:
			await wait(0.4)
			if x.huelle_t <= 0.0:
				break
		check("nicht zerschlagen: die Haut steht auf und kämpft", x.huelle_t <= 0.0 and x.state == Foe.St.FIGHT)
	auf(B, 0.48)
	await wait(1.0)
	var h2: Array = B.kampf.huellen.filter(func(x): return x.state != Foe.St.DEAD and x.huelle_t > 0.0)
	check("zweite Häutung bei 50 %% (Phase %d, Hülle %d)" % [B.kampf.phase, h2.size()], B.kampf.phase == 3 and h2.size() == 1)
	if h2.size() > 0:
		h2[0].hit(h2[0].max_hp / 3.0 + 1.0, h.global_position)
		check("zerschlagen, bevor sie aufsteht: die Hülle ist hin", h2[0].state == Foe.St.DEAD)
	await heran(G)
	await shot("mutter_p3")
	auf(B, 0.22)
	await wait(1.0)
	check("dritte Häutung bei 25 %%: Ohne Haut (Phase %d)" % B.kampf.phase, B.kampf.phase == 4 and B.model.scale.x < gr0 * 0.75)
	B.kampf.cd["ansturm"] = 0.0
	await wait(1.0)
	await heran(G)
	await shot("mutter_p4")
	B.hit(1e9, h.global_position)
	await wait(2.0)
	var reste: int = B.kampf.huellen.filter(func(x): return is_instance_valid(x) and x.state != Foe.St.DEAD).size() + G.foes.filter(func(f): return f.summoned and f.state != Foe.St.DEAD).size()
	check("die Mutter fällt: was sie abgestreift und gerufen hat, vergeht (%d)" % reste, B.state == Foe.St.DEAD and reste == 0)

# ---------------------------------------------------------------- Der König ohne Namen (Stunde 3)
func koenig() -> void:
	var G: Node = await stunde(3)
	var B: Foe = G.boss
	var h: Hero = G.hero
	check("Stunde 3: der König ohne Namen kämpft nach eigenem Muster", B.kampf != null and B.kampf.art == "koenig")
	await wecken(G, 8.0)
	var kart: Array = B.kampf.objekte.filter(func(o): return o.rolle == "kartusche")
	check("drei Kartuschen stehen in der Arena (%d), er ist unverwundbar" % kart.size(), kart.size() == 3 and B.kampf.schild)
	kart = lebende(G, "kartusche")
	var hp0 := B.hp
	B.hit(500.0, h.global_position)
	check("Treffer prallen am Namenlosen ab", B.hp == hp0)
	check("Leiste sagt, was zu tun ist", G.hud.l_boss_status.text.contains("Kartuschen"))
	await heran(G)
	await shot("koenig_p1")
	var wege := true
	for k in kart:
		wege = wege and not G.find_path(G.arena_ort(), k.global_position).is_empty()
	check("jede Kartusche ist zu Fuß erreichbar", wege)
	# die Kamera an eine Kartusche: so sieht man, was man entzündet
	if kart.size() > 0:
		h.global_position = kart[0].global_position + (B.global_position - kart[0].global_position).normalized() * 2.5
		h.reset_physics_interpolation()
		G.cam_pos = h.global_position
		await wait(0.3)
		await shot("koenig_kartusche")
	for k in kart:
		k.hit(k.max_hp + 1.0, h.global_position)
		await wait(0.2)
	check("alle Kartuschen brennen: er hört seinen Namen, kniet und ist verwundbar", not B.kampf.schild and B.kampf.fenster_t > 0.0 and B.stun > 0.0)
	await heran(G)
	await shot("koenig_offen")
	auf(B, 0.58)
	await wait(0.5)
	check("Phase 2 bei 60 %%: Grabwache und eine vierte Kartusche (%d)" % B.kampf.objekte.size(), B.kampf.phase == 2 and B.kampf.objekte.filter(func(o): return o.rolle == "kartusche").size() == 4)
	B.kampf.fenster_t = 0.05
	await wait(1.8)
	check("das Fenster schließt sich: er schlägt den Namen wieder aus (Schild, %d Kartuschen dunkel)" % lebende(G, "kartusche").size(), B.kampf.schild and lebende(G, "kartusche").size() == 4)
	await heran(G)
	await shot("koenig_p2")
	for k in lebende(G, "kartusche"):
		k.hit(k.max_hp + 1.0, h.global_position)
		await wait(0.15)
	check("wieder entzündet: verwundbar", not B.kampf.schild)
	auf(B, 0.22)
	await wait(0.5)
	B.kampf.fenster_t = 0.05
	await wait(1.8)
	check("Phase 3 bei 25 %: der Name hält, kein Schild mehr", B.kampf.phase == 3 and not B.kampf.schild)
	await heran(G)
	await shot("koenig_p3")
	B.hit(1e9, h.global_position)
	await wait(2.0)
	check("der König fällt: die Kartuschen vergehen", B.state == Foe.St.DEAD and lebende(G, "kartusche").is_empty() and B.kampf.objekte.is_empty())

# ---------------------------------------------------------------- Der Sammler (Stunde 5)
func sammler() -> void:
	var G: Node = await stunde(5)
	var B: Foe = G.boss
	var h: Hero = G.hero
	check("Stunde 5: der Sammler kämpft nach eigenem Muster", B.kampf != null and B.kampf.art == "sammler")
	await wecken(G, 8.0)
	B.kampf.cd["kruege"] = 0.0
	var kruege: Array = []
	for i in 30:
		await wait(0.4)
		kruege = lebende(G, "krug")
		if kruege.size() >= 3:
			break
	check("Krüge mit Herzen steigen auf (%d)" % kruege.size(), kruege.size() >= 3)
	await heran(G)
	await shot("sammler_p1")
	if kruege.size() >= 2:
		h.hp = h.max_hp * 0.5
		var hh := h.hp
		kruege[0].hit(1e6, h.global_position)
		check("ein zerschlagener Krug: das Herz findet heim, du bekommst Leben (%d → %d)" % [int(hh), int(h.hp)], h.hp > hh and kruege[0].state == Foe.St.DEAD)
		B.hp = B.max_hp * 0.8
		var bh := B.hp
		for k in lebende(G, "krug"):
			k.set_meta("bis", G.clock)
		await wait(0.4)
		check("was stehen bleibt, leert sich in ihn: er heilt (%d → %d)" % [int(bh), int(B.hp)], B.hp > bh and lebende(G, "krug").is_empty())
	auf(B, 0.58)
	await wait(1.5)
	check("Phase 2 bei 60 %: das Verzeichnis", B.kampf.phase == 2)
	var am_meisten := 0
	for i in 40:
		if lebende(G, "krug").is_empty():
			B.kampf.cd["kruege"] = 0.0
		await wait(0.3)
		am_meisten = maxi(am_meisten, lebende(G, "krug").size())
		if am_meisten >= 4:
			break
	check("Phase 2: mehr Krüge (%d)" % am_meisten, am_meisten >= 4)
	await heran(G)
	await shot("sammler_p2")
	auf(B, 0.28)
	await wait(1.0)
	check("Phase 3 bei 30 %: sein eigener Krug", B.kampf.phase == 3 and B.kampf.eigenkrug != null and B.kampf.eigenkrug.visible)
	await heran(G)
	await shot("sammler_p3")
	B.hit(1e9, h.global_position)
	await wait(2.0)
	check("der Sammler fällt: Krüge vergehen, das Licht ist zurück", B.state == Foe.St.DEAD and lebende(G, "krug").is_empty() and G.dunkel_vorher.is_empty())

# ---------------------------------------------------------------- Eine Windung des Apophis (Stunde 7): neue Gestalt von Agent A
func apophis() -> void:
	var G: Node = await stunde(7)
	var B: Foe = G.boss
	var h: Hero = G.hero
	check("Stunde 7: die Windung des Apophis trägt die Schlange und häutet sich wie die Mutter", B.kampf != null and B.kampf.art == "mutter" and B.K.get("neu", "") == "Apophis")
	await wecken(G, 8.0)
	check("die Schlange erwacht und kämpft", B.state == Foe.St.FIGHT and G.boss_awake)
	await heran(G)
	await shot("apophis_p1")
	auf(B, 0.73)
	await wait(1.0)
	check("die Schlange häutet sich bei 75 %", B.kampf.phase == 2)
	await heran(G)
	await shot("apophis_p2")
	B.schild_t = 0.0
	B.hit(1e9, h.global_position)
	await wait(1.5)
	check("die Windung fällt", B.state == Foe.St.DEAD)

# ---------------------------------------------------------------- Champions und ihre Eigenschaften
func champion(G: Node, art: String, ids: Array, ort: Vector3, leben := 1e6) -> Foe:
	Affixe.vorgabe = ids
	var c: Foe = G._spawn(art, ort, 97, "zaeh", G.hdef)
	Affixe.vorgabe = []
	c.max_hp = leben
	c.hp = leben
	c.xp = 0.0
	return c

func frei_neben(G: Node, p: Vector3, d: float) -> Vector3:
	for i in 12:
		var a := TAU * i / 12.0
		var q: Vector3 = p + Vector3(sin(a), 0, cos(a)) * d
		if G.walkable(p, q) and not G.astar.is_point_solid(G._sub(q)):
			return q
	return p + Vector3(d, 0, 0)

func champions() -> void:
	var G: Node = await stunde(3)
	var h: Hero = G.hero
	G.boss.process_mode = Node.PROCESS_MODE_DISABLED
	h.global_position = G.start_pos
	h.reset_physics_interpolation()
	G.cam_pos = h.global_position
	h.inv = 9999.0
	var voll: float = Hero.LATERNE_WEITE * Spiel.S.cone
	# Anzahl der Eigenschaften steigt mit der Stunde
	check("Eigenschaften je Stunde: 1 in Stunde 1, 2 in Stunde 3, 3 in Stunde 7", Affixe.anzahl(1, 0) == 1 and Affixe.anzahl(3, 0) == 2 and Affixe.anzahl(7, 0) == 3 and Affixe.anzahl(3, 2) == 3)
	for id in Affixe.ORDNUNG:
		var p: Vector3 = frei_neben(G, h.global_position, 6.0)
		var art := "lance"
		var c: Foe = champion(G, art, [id], p)
		var mate: Foe = null
		if id == "klage" or id == "kette":
			mate = G._spawn("lance", frei_neben(G, p, 4.5 if id == "kette" else 2.0), 97, "", G.hdef)
			mate.max_hp = 1e6
			mate.hp = 1e6
		G.wake_pack(97)
		await wait(1.2)
		h.hp = h.max_hp
		match id:
			"glut":
				for i in 20:
					await wait(0.3)
					if c.aff.glut.flecken.size() >= 2:
						break
				check("Glutspur: er hinterlässt Glut (%d Flecken)" % c.aff.glut.flecken.size(), c.aff.glut.flecken.size() >= 2)
				if c.aff.glut.flecken.size() > 0:
					h.inv = 0.0
					h.global_position = c.aff.glut.flecken[0].c
					var hh := h.hp
					await wait(0.6)
					check("Glutspur: wer darin steht, verbrennt (%d → %d)" % [int(hh), int(h.hp)], h.hp < hh)
					h.inv = 9999.0
			"sturm":
				h.global_position = c.global_position + Vector3(2.0, 0, 0)
				await wait(1.2)
				check("Sandsturm: im Sand brennt die Laterne schwach (%.1f m)" % h.lantern.omni_range, h.lantern.omni_range < voll * 0.6)
			"feder":
				c.stun = 0.0
				c.look_to(h.global_position)
				c.model.rotation.y = c.face
				var vorn: Vector3 = c.global_position + c.forward() * 2.0
				var hinten: Vector3 = c.global_position - c.forward() * 2.0
				var a0 := c.hp
				c.hit(100.0, vorn)
				var von_vorn := a0 - c.hp
				a0 = c.hp
				c.hit(100.0, hinten)
				var von_hinten := a0 - c.hp
				check("Schild der Maat: von vorn %.0f, von hinten %.0f Schaden" % [von_vorn, von_hinten], von_vorn < 30.0 and von_hinten > 90.0)
				c.model.rotation.y = c.face
				c.hit(c.max_hp * 0.5, c.global_position + Vector3(sin(c.model.rotation.y), 0, cos(c.model.rotation.y)) * 2.0)
				check("Schild der Maat: die Feder bricht", c.aff.feder.bruch_t > 0.0)
			"ruf":
				for i in 25:
					await wait(0.3)
					if c.aff.ruf.diener.size() >= 2:
						break
				check("Rufer: Diener stehen auf (%d)" % c.aff.ruf.diener.size(), c.aff.ruf.diener.size() >= 2)
			"sprung":
				h.global_position = frei_neben(G, c.global_position, 9.0)
				var weg0: float = c.global_position.distance_to(h.global_position)
				var gesprungen := false
				for i in 30:
					await wait(0.3)
					if c.global_position.distance_to(h.global_position) < 3.2:
						gesprungen = true
						break
				check("Ba-Sprung: er steht plötzlich neben dir (vorher %.1f m)" % weg0, gesprungen)
			"klage":
				for i in 25:
					await wait(0.3)
					if mate.peitsche_t > 0.0:
						break
				check("Totenklage: das Rudel wird rasend", mate.peitsche_t > 0.0)
			"fessel":
				c.aff.fessel.t = 0.0
				var p2: Vector3 = frei_neben(G, c.global_position, 7.0)
				h.global_position = p2
				h.reset_physics_interpolation()
				h.inv = 0.0
				var hh := h.hp
				var gezogen := false
				for i in 30:
					await wait(0.1)
					h.inv = 0.0
					if h.kb.length() > 3.0 or h.hp < hh:
						gezogen = true
						break
				h.inv = 9999.0
				check("Fessel der Selket: die Fessel zieht dich heran", gezogen)
			"spalt":
				pass
			"kette":
				for i in 20:
					await wait(0.3)
					if c.aff.kette.get("mesh") != null:
						break
				var partner = c.aff.kette.get("partner")
				check("Feuerkette: ein Gefährte wird Champion, die Kette spannt sich", partner != null and partner.elite != "" and c.aff.kette.get("mesh") != null)
				if partner != null:
					await wait(1.2)
					c.stun = 99.0
					partner.stun = 99.0
					await wait(0.3)
					h.inv = 0.0
					h.global_position = (c.global_position + partner.global_position) * 0.5
					h.reset_physics_interpolation()
					var hh := h.hp
					var tief := h.hp   # tiefster Stand im Fenster: Ausrüstung des Testhelden kann den kleinen Brand gleich wieder heilen
					for k in 20:
						h.global_position = (c.global_position + partner.global_position) * 0.5   # auf der Kette halten
						await wait(0.05)
						tief = minf(tief, h.hp)
					h.inv = 9999.0
					check("Feuerkette: wer sie berührt, verbrennt (%d → %d)" % [int(hh), int(tief)], tief < hh - 0.5 or c.global_position.distance_to(partner.global_position) < 1.2)
		h.global_position = frei_neben(G, c.global_position, 3.0)
		h.reset_physics_interpolation()
		G.cam_pos = h.global_position
		await wait(0.4)
		await shot("champion_" + id)
		check("Champion-Schild zeigt %s" % Affixe.LISTE[id].name, G.hud.champ_box.visible and G.hud.champ_f != null and G.hud.champ_f.affixe.has(id))
		# Tod: alles räumt sich auf
		var vorher: int = G.foes.size()
		c.die()
		await wait(1.4)
		var sichtbar: int = c.elite_teile.filter(func(n): return is_instance_valid(n) and n.visible).size()
		check("%s: nach dem Tod ist alles fort (%d Teile sichtbar)" % [Affixe.LISTE[id].name, sichtbar], sichtbar == 0)
		match id:
			"glut":
				await wait(0.5)
				check("Glutspur: die Glut erlischt mit ihm", c.aff.glut.flecken.is_empty())
			"sturm":
				await wait(0.8)
				check("Sandsturm: die Laterne brennt wieder hell (%.1f)" % h.lantern.omni_range, h.lantern.omni_range > voll * 0.9)
			"ruf":
				check("Rufer: seine Diener zerfallen mit ihm", G.foes.filter(func(f): return f.summoned and f.state != Foe.St.DEAD and f.kind != "objekt").is_empty())
			"spalt":
				var neu: Array = G.foes.slice(vorher).filter(func(f): return f.has_meta("gespalten"))   # die Figur schlägt ggf. schon zu
				check("Zweigeteilt: zwei kleinere stehen auf (%d)" % neu.size(), neu.size() == 2)
				for x in neu:
					x.hit(1e9, x.global_position)
			"kette":
				check("Feuerkette: die Kette erlischt, wenn einer fällt", c.aff.kette.get("mesh") == null)
		for f in G.foes:
			if f.state != Foe.St.DEAD and f != G.boss and f.kind != "objekt":
				f.xp = 0.0
				f.hit(1e9, f.global_position)
		await wait(0.6)
	# ein Champion der siebten Stunde: drei Eigenschaften auf einmal
	var p3: Vector3 = frei_neben(G, h.global_position, 6.0)
	var c3: Foe = champion(G, "haut", ["sturm", "feder", "glut"], p3)
	G.wake_pack(97)
	await wait(1.5)
	h.global_position = frei_neben(G, c3.global_position, 3.5)
	G.cam_pos = h.global_position
	await wait(0.3)
	await shot("champion_drei")
	c3.die()
	await wait(1.5)
	check("die Laterne ist nach allen Champions wieder hell", h.lantern.omni_range > voll * 0.9)
