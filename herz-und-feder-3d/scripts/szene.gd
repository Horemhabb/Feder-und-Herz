class_name Szene extends CanvasLayer
# Zwischensequenzen (4.3): eine eigene Ebene über dem Spiel. Eine Sequenz ist eine Liste von Einstellungen (Daten in
# szenen.gd, Drehbuch in SZENEN.md). Jede Einstellung ist entweder
#   ein gemaltes Standbild mit langsamer Kamerafahrt (Schwenk und Zoom), auf Wunsch mit Ebenen für Parallaxe, oder
#   ein Blick in die Spielwelt (Kamera fährt zum Hüter, zur Figur, zur Pforte; Licht geht aus).
# Dazu Schwarzbalken, Untertitel Zeile für Zeile (mit Stimme, falls die Aufnahme da ist), Geräusch und Musik, Blenden,
# Erschütterung, Farbstich und Staub in der Luft.
# Die Bilder malt ComfyUI (tools/bildwerk/wunsch_szenen.md) nach ui/szenen/<name>.webp. Fehlt eines, nimmt die Einstellung
# den ersten vorhandenen Ersatz: ein Porträt, ein Hüter- oder Aktbild, das Titelbild, einen Blick in die Welt, und zuletzt
# immer eine dunkle Fläche mit goldener Zierleiste und einem gezeichneten Zeichen (Waage, Krug, Tor …).
# Jede Sequenz läuft je Spielstand einmal (Spiel.wissen „sz_<name>“), lässt sich überspringen (Esc, B, Start, Knopf
# „Überspringen“; Klick, Tippen, Leertaste, E oder A zeigt die nächste Zeile) und ist unter „Erinnerungen“ wieder abspielbar.
# In Testläufen (Spieltest, Bosstest, Fotos …) wird nichts gezeigt; Tests rufen spielen(…, erzwingen = true).

const ORDNER := "res://ui/szenen/%s.webp"
const SCHWARZ := Color(0.012, 0.01, 0.02)
const GOLD := Color("e8b04a")
const PARCH := Color("ece3cb")
const DIM := Color("a39c8e")
const TEAL := Color("8fe3e0")

static var jetzt: Szene = null   # die laufende Sequenz

var game: Node
var name_sz := ""
var daten: Dictionary
var fertig: Callable
var danach: Array = []            # weitere Sequenzen, die während dieser angefragt wurden: [name, fertig]
var war_pausiert := false
var e_i := -1                     # Einstellung
var z_i := -1                     # Zeile in der Einstellung
var t_e := 0.0                    # Zeit in der Einstellung
var dauer_e := 1.0
var t_z := 0.0
var dauer_z := 0.0
var ende_laeuft := false
var halten := false              # Bilder der Sequenzen (szenenfotos.gd): nicht von selbst weiterschalten
var e: Dictionary = {}

var wurzel: Control
var buehne: Control               # Bild und Ebenen, bewegt von der Kamerafahrt
var hinter: ColorRect
var ebenen: Array = []            # [Control, Tiefe]
var schleier: TextureRect
var balken_o: ColorRect
var balken_u: ColorRect
var vorhang: ColorRect
var text_l: Label
var wer_l: Label
var titel_l: Label
var weiter_l: Label
var staub: CPUParticles2D
var welt_vorher := {}             # Kamera und Licht vor der ersten Welt-Einstellung
var welt_tw: Tween
var musik_vorher := ""
var hud_vorher := true

# ---------------------------------------------------------------- von außen
# Laufen Tests? Dann wird keine Sequenz gezeigt (sie sollen Abläufe prüfen, nicht warten).
static func test_lauf() -> bool:
	var args := OS.get_cmdline_user_args()
	for a in ["--playtest", "--bosstest", "--klassentest", "--autotest", "--mess"]:
		if a in args:
			return true
	return Fotos.laeuft()

# Steht diese Sequenz noch aus? (gibt es sie, ist sie noch nicht gesehen, und läuft kein Test)
static func offen(name: String) -> bool:
	return name != "" and Szenen.hat(name) and not Spiel.gesehen("sz_" + name) and not test_lauf()

static func gesehen(name: String) -> bool:
	return Spiel.gesehen("sz_" + name)

static func laeuft() -> bool:
	return jetzt != null and is_instance_valid(jetzt)

# Spielt die Sequenz und ruft danach „fertig“. Ist sie schon gesehen (oder läuft ein Test), wird gleich „fertig“ gerufen.
# Gibt zurück, ob sie gezeigt wird.
static func spielen(g: Node, name: String, nachher := Callable(), erzwingen := false) -> bool:
	if not erzwingen and not offen(name):
		if nachher.is_valid():
			nachher.call()
		return false
	if not Szenen.hat(name):
		if nachher.is_valid():
			nachher.call()
		return false
	if laeuft():
		jetzt.danach.append([name, nachher])
		return true
	var s := Szene.new()
	s.game = g
	s.name_sz = name
	s.fertig = nachher
	jetzt = s
	g.add_child(s)
	return true

# Gesehene Sequenzen in Erzählfolge: [[name, titel], …] (für „Erinnerungen“ im Menü)
static func erinnerungen() -> Array:
	return Szenen.liste().filter(func(p): return gesehen(p[0]))

# „Erinnerungen“: eine schlichte Liste der gesehenen Sequenzen auf eigener Ebene; die gewählte läuft noch einmal.
# Aufruf aus dem Spielmenü (menue.gd): erst das Menü schließen, dann Szene.erinnerungen_zeigen(game).
static func erinnerungen_zeigen(g: Node) -> void:
	var ebene := CanvasLayer.new()
	ebene.layer = 39
	ebene.process_mode = Node.PROCESS_MODE_ALWAYS
	g.add_child(ebene)
	var war := g.get_tree().paused
	g.get_tree().paused = true
	var grund := ColorRect.new()
	grund.color = Color(SCHWARZ, 0.94)
	grund.set_anchors_preset(Control.PRESET_FULL_RECT)
	ebene.add_child(grund)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grund.add_child(sc)
	var mitte := CenterContainer.new()
	mitte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mitte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(mitte)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(420, 0)
	mitte.add_child(v)
	var schrift: Font = load("res://ui/fonts/almendra.woff")
	var kopf := Label.new()
	kopf.text = "Erinnerungen"
	kopf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kopf.add_theme_font_override("font", load("res://ui/fonts/almendra_fett.woff"))
	kopf.add_theme_font_size_override("font_size", 34)
	kopf.add_theme_color_override("font_color", PARCH)
	v.add_child(kopf)
	var zu := func():
		ebene.queue_free()
		g.get_tree().paused = war
	var liste := erinnerungen()
	if liste.is_empty():
		var l := Label.new()
		l.text = "Noch keine. Sie kommen mit der Nacht."
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", schrift)
		l.add_theme_color_override("font_color", DIM)
		v.add_child(l)
	for p in liste:
		var b := Button.new()
		b.text = "  %s  " % p[1]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", schrift)
		b.add_theme_font_size_override("font_size", 18)
		var nm: String = p[0]
		b.pressed.connect(func():
			ebene.queue_free()
			g.get_tree().paused = war
			Szene.spielen(g, nm, Callable(), true))
		v.add_child(b)
	var zurueck := Button.new()
	zurueck.text = "  Zurück  "
	zurueck.add_theme_font_override("font", schrift)
	zurueck.pressed.connect(zu)
	v.add_child(zurueck)
	zurueck.grab_focus()

# ---------------------------------------------------------------- Aufbau
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	daten = Szenen.baue(name_sz)
	Spiel.merke("sz_" + name_sz)   # gilt als gesehen, auch wenn man sie überspringt
	war_pausiert = get_tree().paused
	get_tree().paused = true
	if game.get("sfx"):
		game.sfx.hush()
		musik_vorher = game.sfx.mus_name
	# die Anzeige des Spiels (Kugeln, Leiste, Questbuch) tritt zurück, solange die Sequenz läuft
	if game.get("hud") != null:
		hud_vorher = game.hud.root.visible
		game.hud.root.visible = false
	_bauen()
	vorhang.color = SCHWARZ
	vorhang.modulate.a = 1.0
	_naechste_einstellung()

func _touch() -> bool:
	return game != null and game.get("touch") == true

func _bauen() -> void:
	wurzel = Control.new()
	wurzel.set_anchors_preset(Control.PRESET_FULL_RECT)
	wurzel.mouse_filter = Control.MOUSE_FILTER_STOP
	wurzel.gui_input.connect(_klick)
	add_child(wurzel)
	hinter = ColorRect.new()
	hinter.color = SCHWARZ
	hinter.set_anchors_preset(Control.PRESET_FULL_RECT)
	hinter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wurzel.add_child(hinter)
	buehne = Control.new()
	buehne.set_anchors_preset(Control.PRESET_FULL_RECT)
	buehne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wurzel.add_child(buehne)
	# Verlauf über dem Bild: unten dunkler, damit der Untertitel lesbar bleibt
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.25), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.75)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	schleier = TextureRect.new()
	schleier.texture = gt
	schleier.set_anchors_preset(Control.PRESET_FULL_RECT)
	schleier.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	schleier.stretch_mode = TextureRect.STRETCH_SCALE
	schleier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wurzel.add_child(schleier)
	staub = CPUParticles2D.new()
	staub.amount = 40
	staub.lifetime = 9.0
	staub.preprocess = 9.0
	staub.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	staub.direction = Vector2(1, -0.3)
	staub.spread = 40.0
	staub.gravity = Vector2.ZERO
	staub.initial_velocity_min = 6.0
	staub.initial_velocity_max = 22.0
	staub.scale_amount_min = 1.0
	staub.scale_amount_max = 2.6
	staub.color = Color(1.0, 0.86, 0.6, 0.35)
	staub.emitting = false
	wurzel.add_child(staub)
	balken_o = _balken(true)
	balken_u = _balken(false)
	# Untertitel: wer spricht (klein, golden), darunter die Zeile
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.anchor_left = 0.1
	box.anchor_right = 0.9
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_top = -190 if not _touch() else -150
	box.offset_bottom = -26
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	wurzel.add_child(box)
	wer_l = _schrift("", 15 if not _touch() else 14, GOLD, "res://ui/fonts/almendra_sc.woff")
	box.add_child(wer_l)
	text_l = _schrift("", 30 if not _touch() else 22, PARCH, "res://ui/fonts/almendra.woff")
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text_l)
	# Zwischentitel (Ende eines Aktes): groß in der Mitte
	titel_l = _schrift("", 46 if not _touch() else 34, PARCH, "res://ui/fonts/almendra_fett.woff")
	titel_l.set_anchors_preset(Control.PRESET_CENTER)
	titel_l.anchor_left = 0.0
	titel_l.anchor_right = 1.0
	titel_l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	titel_l.grow_vertical = Control.GROW_DIRECTION_BOTH
	titel_l.modulate.a = 0.0
	wurzel.add_child(titel_l)
	vorhang = ColorRect.new()
	vorhang.set_anchors_preset(Control.PRESET_FULL_RECT)
	vorhang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wurzel.add_child(vorhang)
	# Hinweise in den Ecken: weiter und überspringen
	weiter_l = _schrift("Tippen: weiter" if _touch() else "Klick oder Leertaste: weiter", 12, Color(DIM, 0.75), "res://ui/fonts/almendra.woff")
	weiter_l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	weiter_l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	weiter_l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	weiter_l.position -= Vector2(18, 6)
	weiter_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wurzel.add_child(weiter_l)
	var skip := Button.new()
	skip.text = "  Überspringen ›  " if _touch() else "  Überspringen  [Esc]  "
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_override("font", load("res://ui/fonts/almendra.woff"))
	skip.add_theme_font_size_override("font_size", 16 if _touch() else 14)
	skip.add_theme_color_override("font_color", Color(DIM, 0.85))
	skip.add_theme_color_override("font_hover_color", PARCH)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.position += Vector2(-12, 6)
	skip.pressed.connect(func(): _ende())
	wurzel.add_child(skip)

func _balken(oben: bool) -> ColorRect:
	var b := ColorRect.new()
	b.color = Color.BLACK
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.anchor_left = 0.0
	b.anchor_right = 1.0
	b.anchor_top = 0.0 if oben else 1.0
	b.anchor_bottom = 0.0 if oben else 1.0
	wurzel.add_child(b)
	return b

func _schrift(t: String, groesse: int, farbe: Color, font: String) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f: Font = load(font)
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", groesse)
	l.add_theme_color_override("font_color", farbe)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("line_spacing", 4)
	return l

# ---------------------------------------------------------------- Ablauf
func _naechste_einstellung() -> void:
	e_i += 1
	var liste: Array = daten.get("einstellungen", [])
	if e_i >= liste.size():
		_ende()
		return
	e = liste[e_i]
	z_i = -1
	t_e = 0.0
	var zeilen: Array = e.get("zeilen", [])
	dauer_e = float(e.get("dauer", 0.0))
	var summe := 0.0
	for z in zeilen:
		summe += _zeilendauer(z)
	dauer_e = maxf(dauer_e, summe + 0.8)
	_einstellung_zeigen()
	_naechste_zeile()

func _zeilendauer(z: Dictionary) -> float:
	if z.has("d"):
		return float(z.d)
	var d := clampf(str(z.get("t", "")).length() * 0.058 + 1.4, 2.4, 9.0)
	var vo := str(z.get("vo", ""))
	if vo != "" and game.get("sfx") and game.sfx._stream(vo):
		d = maxf(d, game.sfx._stream(vo).get_length() + 0.6)
	return d

func _naechste_zeile() -> void:
	z_i += 1
	var zeilen: Array = e.get("zeilen", [])
	if z_i >= zeilen.size():
		dauer_z = maxf(0.6, dauer_e - t_e)   # Rest der Einstellung ohne neue Zeile
		t_z = 0.0
		var tw := create_tween()
		tw.tween_property(text_l, "modulate:a", 0.0, 0.3)
		tw.parallel().tween_property(wer_l, "modulate:a", 0.0, 0.3)
		return
	var z: Dictionary = zeilen[z_i]
	t_z = 0.0
	dauer_z = _zeilendauer(z)
	text_l.text = str(z.get("t", ""))
	var wer := str(z.get("wer", ""))
	wer_l.text = wer.to_upper()
	wer_l.visible = wer != ""
	# Erzähler kursiv wirkt in Almendra zu blass: Figuren hell, Erzähler etwas gedämpft
	text_l.add_theme_color_override("font_color", PARCH if wer != "" else Color(PARCH, 0.92).lerp(DIM, 0.15))
	text_l.modulate.a = 0.0
	wer_l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(text_l, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(wer_l, "modulate:a", 1.0, 0.35)
	var vo := str(z.get("vo", ""))
	if vo != "" and game.get("sfx"):
		game.sfx.say(vo)   # spielt nichts, wenn die Aufnahme fehlt oder der Ton aus ist
	if z.has("ton") and game.get("sfx"):
		game.sfx.play(str(z.ton), 0.0)

func _process(delta: float) -> void:
	if ende_laeuft or e.is_empty():
		return
	t_e += delta
	t_z += delta
	_fahrt()
	if t_z >= dauer_z and not halten:
		if z_i >= e.get("zeilen", []).size():
			_naechste_einstellung()
		else:
			_naechste_zeile()

# Weiter: nächste Zeile, nach der letzten die nächste Einstellung
func weiter() -> void:
	if ende_laeuft:
		return
	if game.get("sfx"):
		game.sfx.hush()
	if z_i >= e.get("zeilen", []).size() - 1:
		z_i = e.get("zeilen", []).size()
		_naechste_einstellung()
	else:
		_naechste_zeile()

func _klick(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		wurzel.accept_event()
		weiter()

func _input(ev: InputEvent) -> void:
	if ende_laeuft:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		get_viewport().set_input_as_handled()
		if ev.keycode == KEY_ESCAPE:
			_ende()
		elif ev.keycode in [KEY_SPACE, KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT]:
			weiter()
	elif ev is InputEventJoypadButton and ev.pressed:
		get_viewport().set_input_as_handled()
		if ev.button_index in [JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK]:
			_ende()
		elif ev.button_index in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_DPAD_RIGHT]:
			weiter()

# ---------------------------------------------------------------- eine Einstellung zeigen
func _einstellung_zeigen() -> void:
	for n in buehne.get_children():
		n.queue_free()
	ebenen.clear()
	var art := _bildart(e)
	var welt: bool = art[0] == "welt"
	# Blende: kurz durch Schwarz (oder Weiß), beim ersten Bild aus dem Schwarz heraus
	var blende := str(e.get("blende", "schwarz"))
	vorhang.color = Color(1, 0.97, 0.9) if blende == "weiss" else SCHWARZ
	var tw := create_tween()
	if e_i > 0 and blende != "weiss":
		vorhang.modulate.a = maxf(vorhang.modulate.a, 0.85)
	elif blende == "weiss":
		vorhang.modulate.a = 1.0
	tw.tween_property(vorhang, "modulate:a", 0.0, 0.9 if e_i == 0 or blende == "weiss" else 0.45)
	# Schwarzbalken: bei Bildern schmal, in der Welt breiter (Kino in der Spielwelt)
	var h := wurzel.size.y if wurzel.size.y > 0 else get_viewport().get_visible_rect().size.y
	var ziel_h := h * (0.13 if welt else 0.085)
	var tb := create_tween().set_parallel(true)
	tb.tween_property(balken_o, "offset_bottom", ziel_h, 0.6)
	tb.tween_property(balken_u, "offset_top", -ziel_h, 0.6)
	hinter.visible = not welt
	schleier.modulate.a = 0.55 if welt else 1.0
	staub.emitting = bool(e.get("staub", not welt))
	staub.position = Vector2.ZERO
	staub.emission_rect_extents = get_viewport().get_visible_rect().size * 0.5
	staub.position = get_viewport().get_visible_rect().size * 0.5
	get_viewport().disable_3d = not welt
	if welt:
		_welt(e)
	else:
		_bild(art)
	buehne.modulate = Color(e.get("stich", Color.WHITE))
	if e.has("musik") and game.get("sfx"):
		game.sfx.music(str(e.musik), 1.5)
	if e.has("ton") and game.get("sfx"):
		game.sfx.play(str(e.ton), 0.0)
	# Zwischentitel
	var titel := str(e.get("titel", ""))
	titel_l.text = titel
	titel_l.modulate.a = 0.0
	if titel != "":
		var tt := create_tween()
		tt.tween_interval(0.6)
		tt.tween_property(titel_l, "modulate:a", 1.0, 1.2)

# Welches Bild? ["bild", Pfad] · ["portrait", Pfad] · ["breit", Pfad] (Hüter, Akt, Titel) · ["welt", ""] · ["zeichen", Motiv]
func _bildart(x: Dictionary) -> Array:
	if str(x.get("art", "")) == "welt":
		return ["welt", ""]
	var b := str(x.get("bild", ""))
	if b != "" and ResourceLoader.exists(ORDNER % b):
		return ["bild", ORDNER % b]
	for ers in x.get("ersatz", []):
		var teil: PackedStringArray = str(ers).split(":")
		var p := ""
		match teil[0]:
			"portrait":
				p = "res://ui/portraits/%s.webp" % teil[1]
				if ResourceLoader.exists(p):
					return ["portrait", p]
			"hueter":
				p = "res://ui/hueter/%s.webp" % teil[1]
				if ResourceLoader.exists(p):
					return ["breit", p]
			"akt":
				p = Stunden.akt_bild(int(teil[1]))
				if p != "":
					return ["breit", p]
			"titel":
				if ResourceLoader.exists("res://ui/titel.webp"):
					return ["breit", "res://ui/titel.webp"]
			"welt":
				if game.get("cam") != null:
					return ["welt", ""]
			"zeichen":
				return ["zeichen", teil[1] if teil.size() > 1 else "sonne"]
	return ["zeichen", str(x.get("zeichen", "sonne"))]

func _bildrect(pfad: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(pfad)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _bild(art: Array) -> void:
	match art[0]:
		"bild":
			buehne.add_child(_bildrect(art[1]))
			ebenen.append([buehne.get_child(-1), 1.0])
			# Ebenen für Parallaxe: Figur auf Schwarz oder Staub, mit eigener Tiefe
			for eb in e.get("ebenen", []):
				var p := ORDNER % str(eb.get("bild", ""))
				if ResourceLoader.exists(p):
					var r := _bildrect(p)
					if str(eb.get("mischen", "")) == "add":
						# Lichter oder Staub auf reinem Schwarz: addiert, so braucht das Bild keinen Alphakanal
						var mat := CanvasItemMaterial.new()
						mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
						r.material = mat
					buehne.add_child(r)
					ebenen.append([r, float(eb.get("tiefe", 1.6))])
		"breit":
			# geliehenes breites Bild (Akttafel, Hüter, Titel): stärker verschleiert, damit es nicht wie die Tafel aussieht
			buehne.add_child(_bildrect(art[1]))
			ebenen.append([buehne.get_child(-1), 1.0])
			var dunkel := ColorRect.new()
			dunkel.color = Color(0.02, 0.02, 0.05, 0.42)
			dunkel.set_anchors_preset(Control.PRESET_FULL_RECT)
			dunkel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			buehne.add_child(dunkel)
		"portrait":
			# Porträt im Goldrahmen vor einer dunklen Fläche mit Zierleiste (das Zeichen bleibt leise dahinter)
			var z := Zier.new()
			z.motiv = str(e.get("zeichen", ""))
			z.leise = true
			z.set_anchors_preset(Control.PRESET_FULL_RECT)
			buehne.add_child(z)
			var vs := get_viewport().get_visible_rect().size
			var ph := vs.y * (0.56 if _touch() else 0.6)
			var rahmen := Panel.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0.6)
			sb.border_color = Color("c9a04a")
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(4)
			sb.shadow_color = Color(0, 0, 0, 0.6)
			sb.shadow_size = 18
			rahmen.add_theme_stylebox_override("panel", sb)
			rahmen.size = Vector2(ph * 0.75, ph) + Vector2(8, 8)
			rahmen.position = Vector2(vs.x * 0.5 - rahmen.size.x * 0.5, vs.y * 0.12)
			rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rahmen.pivot_offset = rahmen.size * 0.5
			buehne.add_child(rahmen)
			var pic := TextureRect.new()
			pic.texture = load(art[1])
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.position = Vector2(4, 4)
			pic.size = rahmen.size - Vector2(8, 8)
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rahmen.add_child(pic)
			ebenen.append([rahmen, 0.5])
		"zeichen":
			var z := Zier.new()
			z.motiv = art[1]
			z.oben = str(e.get("titel", "")) != ""   # unter einem Zwischentitel steht das Zeichen klein darüber
			z.set_anchors_preset(Control.PRESET_FULL_RECT)
			buehne.add_child(z)
			ebenen.append([z, 0.35])

# Kamerafahrt: „fahrt“ = [[Zoom, x, y] am Anfang, [Zoom, x, y] am Ende]; x, y in Anteilen der Bildgröße (−1 … 1)
func _fahrt() -> void:
	if ebenen.is_empty():
		_beben_welt()
		# Mauern zwischen Kamera und Ziel werden durchsichtig wie im Spiel (mauer.gdshader); main.gd steht ja still
		var cam: Camera3D = game.get("cam")
		if cam:
			RenderingServer.global_shader_parameter_set("cut_cam", cam.global_position)
			RenderingServer.global_shader_parameter_set("cut_hero", _weltziel(str(e.get("ziel", "held"))))
		return
	var f: Array = e.get("fahrt", [[1.04, 0.0, 0.0], [1.14, 0.0, -0.2]])
	var k := smoothstep(0.0, 1.0, clampf(t_e / maxf(0.1, dauer_e), 0.0, 1.0))
	var z := lerpf(float(f[0][0]), float(f[1][0]), k)
	var off := Vector2(lerpf(float(f[0][1]), float(f[1][1]), k), lerpf(float(f[0][2]), float(f[1][2]), k))
	var vs := get_viewport().get_visible_rect().size
	var beben := float(e.get("beben", 0.0)) * maxf(0.0, 1.0 - t_e / 1.6)
	var ruck := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * beben * 14.0
	for p in ebenen:
		var n: Control = p[0]
		var tiefe: float = p[1]
		var zt := 1.0 + (z - 1.0) * tiefe
		n.pivot_offset = n.size * 0.5
		n.scale = Vector2.ONE * zt
		# Verschiebung höchstens so weit, wie der Zoom Rand übrig lässt (x, y = ±1: bis an die Kante)
		var weg := off * vs * maxf(0.0, zt - 1.0) * 0.5
		if n is Panel:
			n.position = Vector2(vs.x * 0.5 - n.size.x * 0.5, vs.y * 0.12) + off * vs * 0.02 + ruck
		else:
			n.position = weg + ruck * tiefe
	if staub.emitting:
		staub.position = vs * 0.5 + off * vs * 0.04

# ---------------------------------------------------------------- Einstellungen in der Spielwelt
# „ziel“: "hueter", "held", "pforte", "arena"; „nah“: Abstand der Kamera (Meter, schräg von oben); „licht“: Faktor für
# Mond und Umgebungslicht; „dreh“: die Kamera kreist während der Einstellung um so viel (Bogenmaß)
func _weltziel(was: String) -> Vector3:
	match was:
		"hueter":
			if game.get("boss") != null and is_instance_valid(game.boss):
				return game.boss.global_position
		"pforte":
			if game.get("gate") != null and is_instance_valid(game.gate):
				return game.gate.global_position
		"arena":
			if game.get("karte") != null:
				return Welt.cell_pos(game.karte.lair)
	if game.get("hero") != null:
		return game.hero.global_position
	return Vector3.ZERO

func _welt(x: Dictionary) -> void:
	var cam: Camera3D = game.get("cam")
	if cam == null:
		return
	if welt_vorher.is_empty():
		welt_vorher = {"t": cam.global_transform, "fov": cam.fov, "3d": false}
		if game.get("moon") != null:
			welt_vorher["mond"] = game.moon.light_energy
			welt_vorher["umgebung"] = game.env.ambient_light_energy
	var ziel := _weltziel(str(x.get("ziel", "held")))
	var nah := float(x.get("nah", 9.0))
	var dreh := float(x.get("winkel", 0.0))
	var richtung := Vector3(1.0, 0.0, 1.0).normalized().rotated(Vector3.UP, dreh)
	var pos := ziel + richtung * nah + Vector3(0, nah * 0.85, 0)
	var t_ziel := Transform3D(Basis(), pos).looking_at(ziel + Vector3(0, 1.3, 0), Vector3.UP)
	if welt_tw and welt_tw.is_valid():
		welt_tw.kill()   # die Fahrt der vorigen Einstellung endet hier
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	welt_tw = tw
	tw.tween_property(cam, "global_transform", t_ziel, 1.8)
	tw.parallel().tween_property(cam, "fov", float(x.get("fov", 34.0)), 1.8)
	var kreis := float(x.get("dreh", 0.12))
	if absf(kreis) > 0.001:
		# langsames Kreisen um das Ziel, so lange die Einstellung läuft
		var start_w := dreh
		tw.tween_method(func(w: float):
			var r := Vector3(1.0, 0.0, 1.0).normalized().rotated(Vector3.UP, w)
			cam.global_transform = Transform3D(Basis(), ziel + r * nah + Vector3(0, nah * 0.85, 0)).looking_at(ziel + Vector3(0, 1.3, 0), Vector3.UP),
			start_w, start_w + kreis, maxf(1.0, dauer_e - 1.8))
	if x.has("licht") and game.get("moon") != null:
		var f := float(x.licht)
		var tl := create_tween().set_parallel(true)
		tl.tween_property(game.moon, "light_energy", float(welt_vorher.mond) * f, 1.6)
		tl.tween_property(game.env, "ambient_light_energy", float(welt_vorher.umgebung) * maxf(0.2, f), 1.6)

func _beben_welt() -> void:
	var b := float(e.get("beben", 0.0))
	var cam: Camera3D = game.get("cam")
	if b <= 0.0 or cam == null or t_e > 1.6:
		return
	cam.h_offset = randf_range(-1, 1) * b * 0.15 * (1.0 - t_e / 1.6)
	cam.v_offset = randf_range(-1, 1) * b * 0.15 * (1.0 - t_e / 1.6)

func _welt_zurueck() -> void:
	if welt_tw and welt_tw.is_valid():
		welt_tw.kill()
	if welt_vorher.is_empty():
		return
	var cam: Camera3D = game.get("cam")
	if cam:
		cam.global_transform = welt_vorher.t
		cam.fov = welt_vorher.fov
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	if welt_vorher.has("mond"):
		game.moon.light_energy = welt_vorher.mond
		game.env.ambient_light_energy = welt_vorher.umgebung
	welt_vorher = {}

# ---------------------------------------------------------------- Ende
func _ende() -> void:
	if ende_laeuft:
		return
	ende_laeuft = true
	if game.get("sfx"):
		game.sfx.hush()
	var tw := create_tween()
	tw.tween_property(vorhang, "modulate:a", 1.0, 0.45)
	tw.tween_callback(_aufraeumen)

func _aufraeumen() -> void:
	_welt_zurueck()
	get_viewport().disable_3d = false
	if game.get("hud") != null:
		game.hud.root.visible = hud_vorher
	if game.get("sfx") and game.sfx.mus_name != musik_vorher:
		if game.get("started") and game.has_method("area_music"):
			game.sfx.music_set(game.area_music(), 2.0)
		else:
			game.sfx.music(musik_vorher, 2.0)
	jetzt = null
	var weitere := danach.duplicate()
	var nachher := fertig
	get_tree().paused = war_pausiert
	queue_free()
	if nachher.is_valid():
		nachher.call()
	for w in weitere:
		Szene.spielen(game, w[0], w[1])


# ---------------------------------------------------------------- Ersatzbild: dunkle Fläche, Zierleiste, Zeichen
# Steht, solange ein gemaltes Bild fehlt: doppelter Goldrahmen, ein Horizont, darüber in feinen Linien ein Zeichen der
# Einstellung (sonne, waage, krug, tor, feder, laterne, ba, auge, schlange). Atmet langsam.
class Zier extends Control:
	var motiv := "sonne"
	var leise := false
	var oben := false   # Zeichen klein im oberen Drittel (unter einem Zwischentitel)
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 2.0:
			return
		# Grund: tiefes Nachtblau, zur Mitte etwas heller
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.03, 0.06))
		for i in 6:
			var r := s.y * (0.75 - i * 0.1)
			draw_circle(s * Vector2(0.5, 0.58), r, Color(0.09, 0.07, 0.12, 0.12))
		var g := Color(0.91, 0.69, 0.29, 0.55 if not leise else 0.3)
		var gd := Color(g, g.a * 0.45)
		# doppelter Rahmen mit Ecken wie ein Fries
		# innerhalb der Schwarzbalken (oben und unten je 8,5 % der Höhe)
		var m := Vector2(minf(s.x, s.y) * 0.05, s.y * 0.12)
		draw_rect(Rect2(m, s - m * 2), g, false, 1.5)
		draw_rect(Rect2(m + Vector2(10, 10), s - m * 2 - Vector2(20, 20)), gd, false, 1.0)
		for ecke in [m, Vector2(s.x - m.x, m.y), Vector2(m.x, s.y - m.y), s - m]:
			draw_circle(ecke, 3.0, g)
		# Fries oben und unten: kleine Rauten zwischen den beiden Rahmenlinien
		var n := int(s.x / 34.0)
		for i in n:
			var x := m.x * 2.0 + (s.x - m.x * 4.0) * (i + 0.5) / n
			for y in [m.y + 5.0, s.y - m.y - 5.0]:
				var p := Vector2(x, y)
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(3, 0), p + Vector2(0, 3), p + Vector2(-3, 0)]), gd)
		if leise or motiv == "":
			return
		var atem := 0.85 + sin(t * 0.9) * 0.15
		var c := s * Vector2(0.5, 0.3 if oben else 0.44)
		var k := s.y * (0.1 if oben else 0.2)
		var lc := Color(g, g.a * atem)
		var hy := c.y + k * 0.9   # Horizont
		draw_line(Vector2(s.x * 0.2, hy), Vector2(s.x * 0.8, hy), gd, 1.0)
		match motiv:
			"sonne":
				var mc := Vector2(c.x, hy)
				draw_arc(mc, k * 0.8, PI, TAU, 48, lc, 2.0)
				for i in 9:
					var w := PI + PI * (i + 0.5) / 9.0 + sin(t * 0.3) * 0.02
					draw_line(mc + Vector2(cos(w), sin(w)) * k * 0.95, mc + Vector2(cos(w), sin(w)) * k * 1.4, gd, 1.0)
			"waage":
				draw_line(c + Vector2(0, -k), c + Vector2(0, k * 0.95), lc, 2.0)
				var neig := sin(t * 0.7) * 0.06
				var a := c + Vector2(-k, -k * 0.7 + neig * k)
				var b := c + Vector2(k, -k * 0.7 - neig * k)
				draw_line(a, b, lc, 2.0)
				for p in [a, b]:
					draw_line(p, p + Vector2(-k * 0.3, k * 0.6), gd, 1.0)
					draw_line(p, p + Vector2(k * 0.3, k * 0.6), gd, 1.0)
					draw_arc(p + Vector2(0, k * 0.6), k * 0.3, 0.0, PI, 16, lc, 1.5)
				draw_line(c + Vector2(-k * 0.5, k * 0.95), c + Vector2(k * 0.5, k * 0.95), lc, 2.0)
			"krug":
				var pts := PackedVector2Array()
				for i in 25:
					var y := -1.0 + 2.0 * i / 24.0
					var w := 0.42 + 0.28 * sin((y + 1.0) * 1.5) - 0.15 * maxf(0.0, y - 0.7) * 3.0
					pts.append(c + Vector2(w * k, y * k))
				var rechts := pts.duplicate()
				var links := PackedVector2Array()
				for p in pts:
					links.append(Vector2(c.x * 2.0 - p.x, p.y))
				draw_polyline(rechts, lc, 2.0)
				draw_polyline(links, lc, 2.0)
				draw_arc(c + Vector2(0, -k * 1.1), k * 0.3, PI, TAU, 16, lc, 2.0)
				draw_line(c + Vector2(-k * 0.4, -k), c + Vector2(k * 0.4, -k), lc, 1.5)
				var schlag := pow(maxf(0.0, sin(t * 3.2)), 8.0)
				draw_circle(c + Vector2(0, k * 0.1), k * (0.12 + schlag * 0.04), Color(0.85, 0.3, 0.25, 0.25 + schlag * 0.35))
			"tor":
				var bw := k * 0.75
				for sx in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([c + Vector2(sx * k * 0.25, k * 0.95), c + Vector2(sx * (k * 0.25 + bw), k * 0.95), c + Vector2(sx * (k * 0.3 + bw * 0.8), -k), c + Vector2(sx * k * 0.3, -k)]), Color(g, 0.08))
					draw_polyline(PackedVector2Array([c + Vector2(sx * k * 0.25, k * 0.95), c + Vector2(sx * (k * 0.25 + bw), k * 0.95), c + Vector2(sx * (k * 0.3 + bw * 0.8), -k), c + Vector2(sx * k * 0.3, -k), c + Vector2(sx * k * 0.25, k * 0.95)]), lc, 1.5)
				draw_rect(Rect2(c + Vector2(-k * 0.25, -k * 0.55), Vector2(k * 0.5, k * 1.5)), Color(1.0, 0.85, 0.55, 0.05 + 0.04 * sin(t)), true)
			"feder":
				var pts := PackedVector2Array()
				for i in 21:
					var u := float(i) / 20.0
					pts.append(c + Vector2(sin(u * 2.4) * k * 0.12, (u * 2.0 - 1.0) * k * 1.1))
				draw_polyline(pts, lc, 1.5)
				for i in range(2, 19):
					var p: Vector2 = pts[i]
					var len := k * 0.38 * sin(float(i) / 20.0 * PI)
					draw_line(p, p + Vector2(-len, -len * 0.5), gd, 1.0)
					draw_line(p, p + Vector2(len, -len * 0.5), gd, 1.0)
			"laterne":
				draw_rect(Rect2(c + Vector2(-k * 0.35, -k * 0.6), Vector2(k * 0.7, k * 1.2)), lc, false, 2.0)
				draw_arc(c + Vector2(0, -k * 0.6), k * 0.3, PI, TAU, 16, lc, 1.5)
				draw_line(c + Vector2(-k * 0.45, k * 0.6), c + Vector2(k * 0.45, k * 0.6), lc, 2.0)
				var fl := 1.0 + sin(t * 7.0) * 0.08 + sin(t * 13.0) * 0.05
				draw_circle(c + Vector2(0, k * 0.05), k * 0.5 * fl, Color(1.0, 0.7, 0.3, 0.06))
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k * 0.35 * fl), c + Vector2(k * 0.12, k * 0.15), c + Vector2(0, k * 0.3), c + Vector2(-k * 0.12, k * 0.15)]), Color(1.0, 0.78, 0.4, 0.55))
			"ba":
				# Vogel mit Menschenkopf, ganz schlicht: Körper, zwei Flügel, Kopf
				var hb := sin(t * 1.6) * k * 0.05
				draw_arc(c + Vector2(0, k * 0.2 + hb), k * 0.45, 0.2, PI - 0.2, 20, lc, 2.0)
				draw_line(c + Vector2(-k * 0.42, k * 0.3 + hb), c + Vector2(-k * 1.2, -k * 0.2 + hb * 2.0), lc, 1.5)
				draw_line(c + Vector2(k * 0.42, k * 0.3 + hb), c + Vector2(k * 1.2, -k * 0.2 + hb * 2.0), lc, 1.5)
				draw_line(c + Vector2(-k * 1.2, -k * 0.2 + hb * 2.0), c + Vector2(-k * 0.5, k * 0.05 + hb), gd, 1.0)
				draw_line(c + Vector2(k * 1.2, -k * 0.2 + hb * 2.0), c + Vector2(k * 0.5, k * 0.05 + hb), gd, 1.0)
				draw_arc(c + Vector2(0, -k * 0.3 + hb), k * 0.22, 0.0, TAU, 20, lc, 2.0)
			"auge":
				draw_arc(c + Vector2(0, k * 0.5), k * 0.9, PI * 1.2, PI * 1.8, 24, lc, 2.0)
				draw_arc(c + Vector2(0, -k * 0.5), k * 0.9, PI * 0.2, PI * 0.8, 24, lc, 2.0)
				draw_circle(c, k * 0.22, Color(g, 0.5))
				draw_line(c + Vector2(-k * 0.1, k * 0.3), c + Vector2(-k * 0.3, k * 0.9), lc, 1.5)
			"schlange":
				var pts := PackedVector2Array()
				for i in 60:
					var u := float(i) / 59.0
					pts.append(Vector2(s.x * (0.22 + u * 0.56), c.y + sin(u * TAU * 2.0 + t * 0.6) * k * 0.35 + k * 0.4))
				draw_polyline(pts, lc, 3.0)
