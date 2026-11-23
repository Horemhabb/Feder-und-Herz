extends Node
# Ruckelmessung (4.1, „-- --neu --ruckeln“): Läuft die Figur ruhig über den Bildschirm?
# Der Held läuft durch Stunde 1, erst geradeaus, dann gegen eine Mauer, dann Haken schlagend, zuletzt im Kampf.
# Je Bild wird gemessen:
#   - Bildzeit (echte Zeit zwischen zwei Bildern); Spitzen zählen über 25 und 50 ms und über das Dreifache des Medians
#     (unter einer Software-Grafik ist jedes Bild langsam, dort sagt nur der Abstand zum Median etwas)
#   - Zittern: Wie weit springt die Figur auf dem Bildschirm von Bild zu Bild (die Kamera folgt ihr gedämpft, beim
#     gleichmäßigen Laufen steht sie dort fast still). Gemessen in Bildpunkten bei 1600 x 900.
#   - Gleichlauf des Bodens: Wie gleichmäßig zieht der Boden vorbei (Schwankung des Tempos auf dem Bildschirm in %)
#   - Wechsel zwischen Gehen und Laufen
# Ohne Bildschirm (headless) zeichnet das Spiel nicht; Bildzeiten sind dann nur Rechenzeit, das Zittern aber echt.
# „--fps=144“ setzt die Bildrate (Standard 144, wie der Bildschirm des Auftraggebers).

var G: Node
var h: Hero
var aufn := false
var phase := ""
var proben := []        # [Phase, Bildzeit ms, Figur auf dem Schirm (Vector2), Bodenpunkt auf dem Schirm, Animation, Trefferstopp]
var boden_pkt := Vector3.ZERO
var uhr := 0
var stopps := 0
var stopp_alt := 0
var pf_alt := 0
var knoten_alt := 0
var res_alt := 0
var spitzen_log := 0
var schwelle_ms := 25.0   # ab hier wird eine Spitze einzeln gemeldet (ohne Bildratengrenze: 1,5 × eines 144-Hz-Bildes)
var neben := {}          # Leute und Tiere: Knoten → [letzte Lage, Tempo des Bildes davor (m/s)]
var neben_bilder := {}   # Phase → [bewegte Bilder, Hänger]
var teile_alt := {}
var teil_spitzen := {}   # Phase → {Teilsystem → Bilder, in denen es allein über 1,5 ms brauchte}
var licht_alt := {}
var licht_wechsel := {}   # Phase → wie oft ein Licht an- oder ausging
var taste_t := 0       # Zeitpunkt (ms) des letzten Richtungswechsels der Tasten
const PHASEN := ["gerade", "mauer", "haken", "kampf"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000   # nach der Kamera (main.gd › _process) messen
	var fps := 144
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fps="):
			fps = int(a.substr(6))
	Engine.max_fps = fps
	if fps == 0:
		schwelle_ms = 10.4
	run.call_deferred()

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func tasten(liste: Array, an: bool) -> void:
	for k in liste:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = an
		Input.parse_input_event(e)

func richtung(liste: Array) -> Vector3:
	var v := Vector2((1 if liste.has(KEY_D) else 0) - (1 if liste.has(KEY_A) else 0), (1 if liste.has(KEY_S) else 0) - (1 if liste.has(KEY_W) else 0))
	return (Vector3(1, 0, -1) * v.x + Vector3(1, 0, 1) * v.y).normalized()

# freie Strecke in Richtung r (in Metern, in Schritten von einem halben Meter)
func frei(r: Vector3, max_m := 60.0) -> float:
	var p := h.global_position
	var m := 0.0
	while m < max_m and G.walkable(p, p + r * 0.5):
		p += r * 0.5
		m += 0.5
	return m

const BAHNEN := [[KEY_D], [KEY_S], [KEY_A], [KEY_W], [KEY_S, KEY_D], [KEY_W, KEY_A], [KEY_W, KEY_D], [KEY_S, KEY_A]]

func _process(_delta: float) -> void:
	var jetzt := Time.get_ticks_usec()
	var ms := (jetzt - uhr) / 1000.0
	uhr = jetzt
	if not aufn or G == null or h == null:
		return
	if G.stopp_bis != stopp_alt:
		stopp_alt = G.stopp_bis
		stopps += 1
	# Spitzen erklären: Physikschritte in diesem Bild, neue Knoten und neu geladene Ressourcen
	var pf := Engine.get_physics_frames()
	var kn := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var rs := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	# Rechenzeit der Teile in diesem Bild (aus dem Protokoll, das je Teilsystem mitzählt)
	var teile := []
	for k in Protokoll.zeiten:
		var d: int = Protokoll.zeiten[k] - teile_alt.get(k, 0)
		if d > 1500:
			teile.append("%s %.1f" % [k, d / 1000.0])
			if aufn:
				var ts: Dictionary = teil_spitzen.get(phase, {})
				ts[k] = ts.get(k, 0) + 1
				teil_spitzen[phase] = ts
	teile_alt = Protokoll.zeiten.duplicate()
	if ms > schwelle_ms and spitzen_log < 40:
		spitzen_log += 1
		print("RUCKELN Spitze %s %.1f ms · Physikschritte %d · Knoten %+d · Ressourcen %+d · Teile über 1,5 ms: %s" % [phase, ms, pf - pf_alt, kn - knoten_alt, rs - res_alt, ", ".join(teile)])
	var lw: int = licht_wechsel.get(phase, 0)
	for l in G.lichter:
		if is_instance_valid(l):
			if licht_alt.has(l) and licht_alt[l] != l.visible:
				lw += 1
			licht_alt[l] = l.visible
	licht_wechsel[phase] = lw
	pf_alt = pf
	knoten_alt = kn
	res_alt = rs
	_neben_messen()
	var cam: Camera3D = G.cam
	var hp: Vector3 = h.get_global_transform_interpolated().origin
	proben.append([phase, ms, cam.unproject_position(hp + Vector3(0, 1.0, 0)), cam.unproject_position(boden_pkt), h.cur_anim, Engine.time_scale < 0.99, Time.get_ticks_msec() - taste_t, G.shake > 0.0, get_process_delta_time() * 1000.0, h.ap.speed_scale, Vector2(h.get_real_velocity().x, h.get_real_velocity().z).length()])

# Leute und Tiere: Ein Hänger ist ein Bild, in dem eine laufende Gestalt stillsteht, obwohl sie in den Bildern
# davor unterwegs war. Bewegt der Physiktakt (60 je Sekunde) sie ohne Zwischenbilder, ist das bei 144 Bildern jedes
# zweite Bild: Sie ruckelt, während die Welt um sie gleichmäßig vorbeizieht.
func _neben_messen() -> void:
	var hp := h.global_position
	var dt := get_process_delta_time()
	if dt <= 0.0:
		return
	var z: Array = neben_bilder.get(phase, [0, 0])
	for e in G.leben.leute + G.leben.tiere:
		var n: Node3D = e.n
		if not is_instance_valid(n) or not n.visible or n.global_position.distance_to(hp) > 22.0:
			neben.erase(n)
			continue
		var p := n.get_global_transform_interpolated().origin if n.is_physics_interpolated_and_enabled() else n.global_position
		if neben.has(n):
			var v: float = (p - neben[n][0]).length() / dt
			var v_alt: float = neben[n][1]
			var v_altalt: float = neben[n][2]
			# im Mittel der letzten drei Bilder unterwegs, aber in diesem Bild ohne Bewegung: ein Hänger
			if (v + v_alt + v_altalt) / 3.0 > 0.3:
				z[0] += 1
				if v < 0.05:
					z[1] += 1
			neben[n] = [p, v, v_alt]
		else:
			neben[n] = [p, 0.0, 0.0]
	neben_bilder[phase] = z

func run() -> void:
	await wait(3.0)
	G = get_tree().current_scene
	while not G.started:
		G.hud.press_primary()
		await wait(1.5)
		G = get_tree().current_scene
		G.auto_low_done = true
	G.auto_low_done = true
	await wait(1.0)
	if G.hud.overlay:
		G.hud.close_bag()
	G.orte.auto = false
	h = G.hero
	await wait(1.0)
	# 1. geradeaus: die längste freie Bahn, hin und zurück, zusammen 10 s
	var beste: Array = BAHNEN[0]
	var weit := 0.0
	for b in BAHNEN:
		var m := frei(richtung(b))
		if m > weit:
			weit = m
			beste = b
	print("RUCKELN Schritte: Gehen %.2f m/s, Laufen %.2f m/s bei Abspieltempo 1, Schwelle %.2f m/s, Tempo der Figur %.2f m/s" % [h.gang[h.a_walk][0], h.gang[h.a_run][0], sqrt(h.gang[h.a_walk][0] * h.gang[h.a_run][0]), Hero.SPEED * Spiel.S.speed])
	print("RUCKELN freie Bahn %.0f m (%s)" % [weit, str(beste)])
	G.freeze_foes = true
	for f in G.foes:
		f.process_mode = Node.PROCESS_MODE_DISABLED
	await _abschnitt("gerade", 10.0, func(t):
		return beste)
	# 2. gegen die Mauer: schräg in die Richtung mit der kürzesten freien Strecke
	var kurz: Array = BAHNEN[0]
	var nah := INF
	for b in BAHNEN:
		var m := frei(richtung(b))
		if m < nah and m > 1.0:
			nah = m
			kurz = b
	await _abschnitt("mauer", 6.0, func(t):
		return kurz)
	# 3. Haken schlagen: alle 0,6 s eine andere Richtung
	await _abschnitt("haken", 8.0, func(t):
		return BAHNEN[int(t / 0.6) % BAHNEN.size()])
	# 4. Kampf: neben den nächsten Gegner, alle Gegner wach, zuschlagen und dazwischen laufen
	G.freeze_foes = false
	for f in G.foes:
		f.process_mode = Node.PROCESS_MODE_INHERIT
	var ziel: Foe = null
	for f in G.foes:
		if f.kind != "boss" and f.state != Foe.St.DEAD and (ziel == null or f.global_position.distance_to(h.global_position) < ziel.global_position.distance_to(h.global_position)):
			ziel = f
	if ziel:
		h.global_position = ziel.global_position + Vector3(2.5, 0, 0)
		h.reset_physics_interpolation()
		G.wake_pack(ziel.pack)
	h.hp = h.max_hp * 50.0   # die Messung soll nicht an einer Niederlage enden
	h.max_hp = h.hp
	await _abschnitt("kampf", 12.0, func(t):
		var f := G.foe_near(h.global_position, 30.0) as Foe
		if f == null:
			return []
		h.aim = f.global_position
		if fmod(t, 1.5) < 1.1:
			h.attack()
			return []
		return BAHNEN[int(t / 1.5) % 4])
	auswerten()
	get_tree().quit()

func _abschnitt(name: String, dauer: float, wahl: Callable) -> void:
	phase = name
	boden_pkt = h.global_position + Vector3(0, 0, 0)
	var t := 0.0
	var gedrueckt := []
	var gegen := false
	var start := Time.get_ticks_msec()
	aufn = true
	while t < dauer:
		var w: Array = wahl.call(t)
		if name == "gerade":
			# am Ende der Bahn umkehren
			if gegen:
				w = w.map(func(k): return {KEY_D: KEY_A, KEY_A: KEY_D, KEY_W: KEY_S, KEY_S: KEY_W}[k])
			if not G.walkable(h.global_position, h.global_position + richtung(w) * 1.5):
				gegen = not gegen
		if w != gedrueckt:
			tasten(gedrueckt, false)
			tasten(w, true)
			gedrueckt = w
			taste_t = Time.get_ticks_msec()
		# der Bodenpunkt bleibt nahe der Figur, sonst läuft er aus dem Bild
		if h.global_position.distance_to(boden_pkt) > 6.0:
			boden_pkt = h.global_position
			proben.append(["neu"])
		await get_tree().process_frame
		t = (Time.get_ticks_msec() - start) / 1000.0
	tasten(gedrueckt, false)
	aufn = false
	await wait(0.5)

func mittel(a: Array) -> float:
	var s := 0.0
	for x in a:
		s += x
	return s / maxf(1, a.size())

func streuung(a: Array) -> float:
	var m := mittel(a)
	var s := 0.0
	for x in a:
		s += (x - m) * (x - m)
	return sqrt(s / maxf(1, a.size()))

func median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]

func auswerten() -> void:
	print("RUCKELN Bildrate gewollt %d, Fenster %s, Grafik %s" % [Engine.max_fps, str(get_viewport().get_visible_rect().size), RenderingServer.get_video_adapter_name()])
	var alle_ms := []
	for name in PHASEN:
		var zeiten := []
		var sprung := []     # Figur auf dem Schirm: Weg von Bild zu Bild (px)
		var ruck := []       # Figur: Änderung dieses Weges von Bild zu Bild (px), also das, was das Auge als Zittern sieht
		var boden_v := []    # Boden: Tempo auf dem Schirm (px/s)
		var wechsel := 0
		var gangwechsel := 0     # alle Wechsel zwischen Stehen, Gehen und Laufen
		var wechsel_ruhig := 0   # Wechsel, obwohl die Richtung seit mindestens 0,6 s gleich ist
		var bilder_ruhig := 0.0
		var schuettel := 0
		var stopp_bilder := 0
		var vor: Array = []
		var vorvor: Array = []
		var dauer := 0.0
		for p in proben:
			if p[0] == "neu":
				vor = []
				vorvor = []
				continue
			if p[0] != name:
				continue
			zeiten.append(p[1])
			dauer += p[1] / 1000.0
			if p[5]:
				stopp_bilder += 1
			if p[7]:
				schuettel += 1
			if p[6] > 600:
				bilder_ruhig += p[1] / 1000.0
			if not vor.is_empty():
				var gaenge := [h.a_idle, h.a_walk, h.a_run]
				if vor[4] != p[4] and gaenge.has(vor[4]) and gaenge.has(p[4]):
					gangwechsel += 1
				if (vor[4] == h.a_walk and p[4] == h.a_run) or (vor[4] == h.a_run and p[4] == h.a_walk):
					wechsel += 1
					if p[6] > 600:
						wechsel_ruhig += 1
				var d: Vector2 = p[2] - vor[2]
				sprung.append(d.length())
				if p[1] > 0.1:
					boden_v.append((p[3] - vor[3]).length() / (p[8] / 1000.0))
				if not vorvor.is_empty():
					ruck.append((d - (vor[2] - vorvor[2])).length())
			vorvor = vor
			vor = p
		alle_ms.append_array(zeiten)
		var med := median(zeiten)
		var s25 := zeiten.filter(func(z): return z > 25.0).size()
		var s50 := zeiten.filter(func(z): return z > 50.0).size()
		var s3 := zeiten.filter(func(z): return z > med * 3.0).size()
		var s15 := zeiten.filter(func(z): return z > med * 1.5).size()   # bei Bildratengrenze: ein verpasstes Bild
		var mittel_ruck := 0.0
		for r in ruck:
			mittel_ruck += r
		mittel_ruck /= maxf(1.0, ruck.size())
		var gross := ruck.filter(func(r): return r > 2.0).size()
		# Gleichlauf: mittlere Abweichung des Bodentempos vom gleitenden Mittel über 9 Bilder, in % des Tempos
		var schwank := 0.0
		var n := 0
		for i in range(4, boden_v.size() - 4):
			var m := 0.0
			for k in range(-4, 5):
				m += boden_v[i + k]
			m /= 9.0
			if m > 30.0:
				schwank += absf(boden_v[i] - m) / m
				n += 1
		var minute := 60.0 / maxf(dauer, 0.01)
		print("RUCKELN %-6s %4.1f s · %d Bilder · Median %.1f ms · über 25 ms: %d (%.0f/min) · über 50 ms: %d (%.0f/min) · über 1,5×Median (verpasst): %d (%.0f/min) · über 3×Median: %d (%.0f/min) · längstes %.0f ms" % [
			name, dauer, zeiten.size(), med, s25, s25 * minute, s50, s50 * minute, s15, s15 * minute, s3, s3 * minute, zeiten.max() if not zeiten.is_empty() else 0.0])
		var nb: Array = neben_bilder.get(name, [0, 0])
		print("RUCKELN %-6s Teile über 1,5 ms in einem Bild (je Teil: Zahl der Bilder): %s" % [name, str(teil_spitzen.get(name, {}))])
		# Abspieltempo der Bewegung und Tempo über Grund beim Laufen in gleicher Richtung: Schwankung (Standardabweichung)
		var tempi := []
		var vs := []
		for p in proben:
			if p[0] == name and p[6] > 600 and p[4] == h.a_run:
				tempi.append(p[9])
				vs.append(p[10])
		print("RUCKELN %-6s beim Laufen in gleicher Richtung: Abspieltempo %.3f ± %.4f · Tempo über Grund %.2f ± %.3f m/s · Lichter an/aus %d" % [name, mittel(tempi), streuung(tempi), mittel(vs), streuung(vs), licht_wechsel.get(name, 0)])
		print("RUCKELN %-6s Leute und Tiere: %d bewegte Bilder, davon Hänger %d (%.0f %%)" % [name, nb[0], nb[1], nb[1] * 100.0 / maxf(1, nb[0])])
		print("RUCKELN %-6s Zittern der Figur %.2f px je Bild (über 2 px: %d) · Gleichlauf des Bodens ±%.1f %% · Gehen/Laufen-Wechsel %d (%.1f je 10 s) (davon bei gleicher Richtung %d, %.1f je 10 s) · Wechsel Stehen/Gehen/Laufen %d · Bilder im Trefferstopp %d · Bilder mit Schütteln %d" % [
			name, mittel_ruck, gross, schwank / maxf(1, n) * 100.0, wechsel, wechsel * 10.0 / maxf(dauer, 0.01), wechsel_ruhig, wechsel_ruhig * 10.0 / maxf(bilder_ruhig, 0.01), gangwechsel, stopp_bilder, schuettel])
	print("RUCKELN gesamt: Trefferstopps %d · Median %.1f ms · Physik %d Hz · Zwischenbilder %s · Ausgleich %.2f" % [
		stopps, median(alle_ms), Engine.physics_ticks_per_second, str(get_tree().physics_interpolation), Engine.physics_jitter_fix])
