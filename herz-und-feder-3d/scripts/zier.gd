class_name Zier
# Gestaltungssystem der Oberfläche (4.3). Alle Fenster, Knöpfe und Leisten holen ihr Zierwerk von hier, damit alles
# aus einem Guss ist. Die Grafiken erzeugt tools/ui/zier.py (Gold mit Fase, Gravur und Patina, dunkles Leder) nach
# ui/zier/. Liegt unter ui/zier/gemalt/ eine gemalte Fassung derselben Fläche (Wunschliste in
# tools/bildwerk/wunsch_ui.md), wird sie statt der erzeugten genommen.
#
# Drei Flächen:
#   „dunkel“   dunkles Leder mit Goldfassung und Lotos in den Ecken: Spielanzeigen, Menü, Tasche, Baum, Karte
#   „klein“    schlanke dunkle Tafel mit feiner Goldlinie: Meldungen, Hinweise, Tooltips, Einlagen
#   „papyrus“  beschriebenes Blatt: Schriftstücke (Aufgaben, Gespräche, Lexikon, Buch des Thot, Kapiteltafeln)
# Ordnung der Schrift: eine Rubrik in Kapitälchen (Gold oder roter Ocker), darunter ein Titel, darunter ruhiger Text.
#
# Öffentlich, auch für Zwischensequenzen (szene.gd):
#   Zier.tafel(control, art, krone)         Fläche mit Rahmen; krone: "", "sonne", "udjat", "lotos"
#   Zier.stil(art)                          die StyleBox dazu (für eigene Knoten)
#   Zier.kartusche(text, groesse, farbe)    Titel in einer Kartusche (Königsring mit Band)
#   Zier.leiste(breite, mitte)              Zierleiste mit Mittelstück ("sonne", "lotos", "raute", "")
#   Zier.faehnchen(text, groesse)           geschwungenes rotes Band für kurze Rubriken (Banner)
#   Zier.bildrahmen(textur, groesse, krone) Bild in Goldrahmen mit Bekrönung (Porträts, Hüter)
#   Zier.knopf(text, art, cb)               Knopf "haupt" (Gold), "zweit" (dunkel), "tinte" (auf Papyrus)
#   Zier.knopf_stil(button, art)            einen vorhandenen Knopf so aussehen lassen
#   Zier.entfalten(control) / Zier.verblassen(control, sek)   Fenster weich öffnen und schließen
#   Zier.glanz(control)                     kurzer Goldglanz (Belohnung)
#   Zier.schrift("text" | "zier" | "fett")  die drei Schriften des Spiels

const PFAD := "res://ui/zier/"
const GEMALT := "res://ui/zier/gemalt/"

# Farben
const GOLD := Color("e8b04a")
const GOLD_HELL := Color("f6dc9a")
const GOLD_DUNKEL := Color("7a5a26")
const PERGAMENT := Color("ece3cb")
const MATT := Color("a39c8e")
const TINTE := Color("2a1a0c")
const RUBRIK := Color("8c2a14")
const TUERKIS := Color("8fe3e0")
const NACHT := Color(0.02, 0.02, 0.04)

# Ränder der 9-Feld-Rahmen (Pixel der Textur; passen zu tools/ui/zier.py)
const RAND := {"tafel_dunkel": 60, "rahmen_dunkel": 60, "tafel_klein": 22, "kartusche": 44, "faehnchen": 64,
	"leiste_platte": 70, "bildrahmen": 30, "platz": 22, "platz_rahmen": 22}

static var _tex := {}
static var _stil := {}
static var _schrift := {}

# Grafik laden: gemalte Fassung, wenn vorhanden, sonst die erzeugte; null, wenn beides fehlt
static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var t: Texture2D = null
		for p in [GEMALT + name + ".webp", GEMALT + name + ".png", PFAD + name + ".webp"]:
			if ResourceLoader.exists(p):
				t = load(p)
				break
		_tex[name] = t
	return _tex[name]

# waagrecht gespiegelte Fassung einer Grafik (einmal erzeugt und gemerkt)
static func _gespiegelt(name: String) -> Texture2D:
	var key := name + "|links"
	if not _tex.has(key):
		var t := tex(name)
		var img := t.get_image() if t else null
		if img == null:
			_tex[key] = t
		else:
			if img.is_compressed():
				img.decompress()
			img.flip_x()
			_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]

# Papyrus: gemalt (ui/zier/gemalt/papyrus), sonst das erzeugte Blatt aus tools/papyrus.py
static func papyrus_tex() -> Texture2D:
	return tex("papyrus") if gemalt("papyrus") else load("res://ui/papyrus.webp")

static func gemalt(name: String) -> bool:
	return ResourceLoader.exists(GEMALT + name + ".webp") or ResourceLoader.exists(GEMALT + name + ".png")

static func schrift(art := "text") -> FontFile:
	if not _schrift.has(art):
		var f: FontFile = load({"text": "res://ui/fonts/almendra.woff", "zier": "res://ui/fonts/almendra_sc.woff", "fett": "res://ui/fonts/almendra_fett.woff"}.get(art, "res://ui/fonts/almendra.woff"))
		if f.fallbacks.is_empty():
			f.fallbacks = [ThemeDB.fallback_font]
		_schrift[art] = f
	return _schrift[art]

static func _neun(name: String, rand := -1, inhalt := -1.0, region := Rect2()) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(name)
	var r: int = rand if rand >= 0 else int(RAND.get(name, 16))
	sb.set_texture_margin_all(r)
	if region.size != Vector2.ZERO:
		sb.region_rect = region
	sb.set_content_margin_all(inhalt if inhalt >= 0.0 else r * 0.55)
	return sb

# ---------------------------------------------------------------- Flächen
# art: "dunkel", "klein", "papyrus", "platte" (Leiste unten), "faehnchen", "platz", "leer"
static func stil(art := "dunkel", inhalt := -1.0) -> StyleBox:
	var key := "%s|%s" % [art, inhalt]
	if _stil.has(key):
		return _stil[key]
	var sb: StyleBox
	match art:
		"dunkel":
			if gemalt("grund_dunkel"):
				# gemalter Grund (Leder, Lapislazuli, dunkles Holz …): er füllt die Fläche, die Fassung legt tafel() darüber
				var g := StyleBoxTexture.new()
				g.texture = tex("grund_dunkel")
				g.set_content_margin_all(inhalt if inhalt >= 0.0 else 30.0)
				g.set_expand_margin_all(-6)
				sb = g
			else:
				sb = _neun("tafel_dunkel", -1, inhalt if inhalt >= 0.0 else 30.0)
		"klein":
			sb = _neun("tafel_klein", -1, inhalt if inhalt >= 0.0 else 12.0)
		"papyrus":
			var p := StyleBoxTexture.new()
			p.texture = papyrus_tex()
			p.set_texture_margin_all(40)
			p.set_content_margin_all(inhalt if inhalt >= 0.0 else 26.0)
			sb = p
		"platte":
			sb = _neun("leiste_platte", -1, inhalt if inhalt >= 0.0 else 12.0)
			(sb as StyleBoxTexture).texture_margin_top = 20
			(sb as StyleBoxTexture).texture_margin_bottom = 16
			sb.content_margin_left = 46
			sb.content_margin_right = 46
			sb.content_margin_top = 16
			sb.content_margin_bottom = 10
		"faehnchen":
			sb = _neun("faehnchen", -1, 0)
			(sb as StyleBoxTexture).texture_margin_top = 24
			(sb as StyleBoxTexture).texture_margin_bottom = 24
			sb.content_margin_left = 54
			sb.content_margin_right = 54
			sb.content_margin_top = 8
			sb.content_margin_bottom = 10
		"platz":
			sb = _neun("platz", -1, inhalt if inhalt >= 0.0 else 6.0)
		"leer":
			sb = StyleBoxEmpty.new()
		_:
			sb = _neun("tafel_dunkel")
	_stil[key] = sb
	return sb

# Fläche mit Rahmen. Bei gemaltem Grund liegt die Fassung als Zeichnung darüber. krone: Bekrönung oben in der Mitte.
static func tafel(c: Control, art := "dunkel", krone := "", inhalt := -1.0) -> Control:
	c.add_theme_stylebox_override("panel", stil(art, inhalt))
	if art in ["dunkel", "klein", "platz"]:
		c.set_meta("dunkel", true)   # die Tinte auf Papyrus lässt diese Flächen in Ruhe (Hud._ink_walk)
	var fassung := art == "dunkel" and gemalt("grund_dunkel")
	if fassung or krone != "":
		var rahmen: StyleBox = _neun("rahmen_dunkel") if fassung else null
		c.draw.connect(func():
			if rahmen:
				c.draw_style_box(rahmen, Rect2(Vector2(-4, -4), c.size + Vector2(8, 8)))
			if krone != "":
				_krone_zeichnen(c, krone))
	return c

# nur die Goldfassung der dunklen Tafel (innen durchsichtig): über ein Bild legen
static func rahmen_stil() -> StyleBoxTexture:
	return _neun("rahmen_dunkel", 60, 0)

static func _krone_zeichnen(c: Control, krone: String) -> void:
	var name: String = {"sonne": "fluegelsonne", "udjat": "udjat", "lotos": "lotos", "skarabaeus": "skarabaeus"}.get(krone, krone)
	var t := tex(name)
	if t == null:
		return
	var s := clampf(c.size.x / 520.0, 0.62, 1.0) * (1.25 if krone == "sonne" else 0.9)
	var gr := t.get_size() * s
	c.draw_texture_rect(t, Rect2(Vector2((c.size.x - gr.x) / 2.0, -gr.y * 0.52), gr), false)

# ---------------------------------------------------------------- Titel, Leisten, Bänder
# Titel in einer Kartusche. auf_papyrus: dunkle Tinte statt Gold.
static func kartusche(text: String, groesse := 26, farbe := GOLD_HELL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := _neun("kartusche", 44, 0)
	sb.texture_margin_top = 20
	sb.texture_margin_bottom = 20
	sb.content_margin_left = 40
	sb.content_margin_right = 46
	sb.content_margin_top = 8
	sb.content_margin_bottom = 9
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", schrift("fett"))
	l.add_theme_font_size_override("font_size", groesse)
	l.add_theme_color_override("font_color", farbe)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if farbe.get_luminance() > 0.5:
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.85))
	p.add_child(l)
	return p

# Zierleiste: zwei verjüngte Goldlinien, in der Mitte ein Zeichen. breite 0: so breit wie der Platz
static func leiste(breite := 0.0, mitte := "sonne", hoehe := 22.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(breite, hoehe)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if breite <= 0.0:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.draw.connect(func(): leiste_zeichnen(c, Rect2(Vector2.ZERO, c.size), mitte))
	return c

# dieselbe Leiste in eine beliebige Fläche zeichnen (für _draw eigener Knoten)
static func leiste_zeichnen(c: CanvasItem, r: Rect2, mitte := "sonne", alpha := 1.0) -> void:
	var lin := tex("trenner_linie")
	var y := r.position.y + r.size.y / 2.0
	var mt: Texture2D = null
	var mgr := Vector2.ZERO
	match mitte:
		"sonne":
			mt = tex("fluegelsonne")
			mgr = mt.get_size() * minf(1.0, r.size.y / 34.0) * 0.62
		"lotos":
			mt = tex("lotos")
			mgr = Vector2(r.size.y, r.size.y) * 1.2
		"raute", "":
			mgr = Vector2(10, 10) if mitte == "raute" else Vector2.ZERO
	var halb := (r.size.x - mgr.x) / 2.0 - 2.0
	var lh := 8.0
	var m := Color(1, 1, 1, alpha)
	if halb > 4.0 and lin:
		# Linie wird aus der Mitte nach außen dünner: rechts so, links gespiegelt
		c.draw_texture_rect(lin, Rect2(Vector2(r.position.x + r.size.x - halb, y - lh / 2.0), Vector2(halb, lh)), false, m)
		c.draw_texture_rect(_gespiegelt("trenner_linie"), Rect2(Vector2(r.position.x, y - lh / 2.0), Vector2(halb, lh)), false, m)
	if mt:
		c.draw_texture_rect(mt, Rect2(Vector2(r.position.x + (r.size.x - mgr.x) / 2.0, y - mgr.y / 2.0), mgr), false, m)
	elif mitte == "raute":
		var p := Vector2(r.position.x + r.size.x / 2.0, y)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(6, 0), p + Vector2(0, 6), p + Vector2(-6, 0)]), Color(GOLD, alpha))
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -2.5), p + Vector2(2.5, 0), p + Vector2(0, 2.5), p + Vector2(-2.5, 0)]), Color(0.2, 0.12, 0.05, alpha))

# rotes Band mit Goldkanten und Schwalbenschwanz, darin eine kurze Rubrik in Kapitälchen
static func faehnchen(text: String, groesse := 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stil("faehnchen"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", schrift("zier"))
	l.add_theme_font_size_override("font_size", groesse + 3)
	l.add_theme_color_override("font_color", GOLD_HELL)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p

# Bild (Porträt, Hüter, Figur) in Goldrahmen, oben eine Bekrönung. Kind 0 ist das Bild (TextureRect).
static func bildrahmen(t: Texture2D, groesse: Vector2, krone := "udjat") -> PanelContainer:
	var p := PanelContainer.new()
	var g := StyleBoxFlat.new()
	g.bg_color = Color(0.03, 0.025, 0.03, 0.9)
	g.set_content_margin_all(7)
	p.add_theme_stylebox_override("panel", g)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("dunkel", true)
	var pic := TextureRect.new()
	pic.texture = t
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = groesse
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(pic)
	var rahmen := _neun("bildrahmen", 30, 0)
	# Rahmen über dem Bild: eine eigene Zeichenfläche, die das ganze Feld deckt
	var ueber := Control.new()
	ueber.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(ueber)
	ueber.draw.connect(func():
		var r := Rect2(Vector2(-7, -7), ueber.size + Vector2(14, 14))
		ueber.draw_style_box(rahmen, r)
		if krone != "":
			var kt := tex({"sonne": "fluegelsonne"}.get(krone, krone))
			if kt:
				var s := clampf(r.size.x / 220.0, 0.55, 1.0)
				var gr := kt.get_size() * s
				ueber.draw_texture_rect(kt, Rect2(Vector2(r.position.x + (r.size.x - gr.x) / 2.0, r.position.y - gr.y * 0.55), gr), false))
	return p

# ---------------------------------------------------------------- Knöpfe
# art: "haupt" (getriebenes Gold, dunkle Schrift), "zweit" (dunkles Leder mit Goldkante, helle Schrift),
# "tinte" (auf Papyrus: ohne Fläche, beim Darüberfahren ein warmer Streifen)
static func knopf(text: String, art := "zweit", cb := Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 46)
	knopf_stil(b, art)
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static func _knopf_region(spalte: int, zeile: int) -> Rect2:
	return Rect2(spalte * 128, zeile * 52, 128, 52)

# die Fläche eines Knopfes zum eigenen Zeichnen (draw_style_box): art "haupt"/"zweit", zustand "normal", "hover",
# "pressed", "disabled"
static func knopf_box(art := "haupt", zustand := "normal") -> StyleBoxTexture:
	var key := "_knopf_%s_%s" % [art, zustand]
	if not _stil.has(key):
		var sb := _neun("knoepfe", 22, 0, _knopf_region(0 if art == "haupt" else 1, {"normal": 0, "hover": 1, "pressed": 2, "disabled": 3}.get(zustand, 0)))
		sb.texture_margin_top = 16
		sb.texture_margin_bottom = 16
		_stil[key] = sb
	return _stil[key]

static func knopf_stil(b: Button, art := "zweit", schriftgroesse := 17) -> void:
	b.add_theme_font_override("font", schrift("zier"))
	b.add_theme_font_size_override("font_size", schriftgroesse)
	if art == "tinte":
		var leer := StyleBoxFlat.new()
		leer.bg_color = Color(0, 0, 0, 0)
		leer.set_content_margin_all(8)
		leer.content_margin_left = 14
		var hov := StyleBoxFlat.new()
		hov.bg_color = Color(0.55, 0.3, 0.08, 0.16)
		hov.border_color = Color(0.45, 0.25, 0.08, 0.5)
		hov.border_width_bottom = 2
		hov.set_corner_radius_all(4)
		hov.set_content_margin_all(8)
		hov.content_margin_left = 14
		var dr := hov.duplicate()
		dr.bg_color = Color(0.55, 0.3, 0.08, 0.28)
		for s in ["normal", "disabled", "focus"]:
			b.add_theme_stylebox_override(s, leer)
		b.add_theme_stylebox_override("hover", hov)
		b.add_theme_stylebox_override("pressed", dr)
		b.add_theme_stylebox_override("hover_pressed", dr)
		for c in ["font_color", "font_focus_color"]:
			b.add_theme_color_override(c, TINTE)
		for c in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(c, RUBRIK)
		b.add_theme_color_override("font_disabled_color", Color(TINTE, 0.45))
		b.set_meta("tinte", true)
	else:
		var sp := 0 if art == "haupt" else 1
		var zustaende := {"normal": 0, "hover": 1, "pressed": 2, "hover_pressed": 2, "disabled": 3}
		for s in zustaende:
			var sb := _neun("knoepfe", 22, -1, _knopf_region(sp, zustaende[s]))
			sb.texture_margin_top = 16
			sb.texture_margin_bottom = 16
			sb.content_margin_left = 22
			sb.content_margin_right = 22
			sb.content_margin_top = 6
			sb.content_margin_bottom = 8 if s != "pressed" and s != "hover_pressed" else 6
			b.add_theme_stylebox_override(s, sb)
		var fokus := StyleBoxFlat.new()
		fokus.draw_center = false
		fokus.border_color = Color(GOLD_HELL, 0.8)
		fokus.set_border_width_all(2)
		fokus.set_corner_radius_all(9)
		fokus.set_expand_margin_all(3)
		b.add_theme_stylebox_override("focus", fokus)
		if art == "haupt":
			for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				b.add_theme_color_override(c, Color("1c1206"))
			b.add_theme_color_override("font_disabled_color", Color("3a3226"))
		else:
			b.add_theme_color_override("font_color", PERGAMENT)
			b.add_theme_color_override("font_focus_color", PERGAMENT)
			b.add_theme_color_override("font_hover_color", GOLD_HELL)
			b.add_theme_color_override("font_pressed_color", GOLD)
			b.add_theme_color_override("font_hover_pressed_color", GOLD)
			b.add_theme_color_override("font_disabled_color", Color(MATT, 0.5))
			b.set_meta("dunkel", true)
	_knopf_regung(b)

# Knöpfe reagieren: beim Drücken sinken sie ein wenig ein (die Schrift rückt mit dem Rand der Textur), beim
# Loslassen federn sie zurück. Nur ein kurzer Tween, nichts läuft dauerhaft.
static func _knopf_regung(b: Button) -> void:
	if b.has_meta("regung"):
		return
	b.set_meta("regung", true)
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.97, 0.97), 0.06))
	b.button_up.connect(func():
		if not is_instance_valid(b):
			return
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))

# ---------------------------------------------------------------- Bewegung
# Fenster entfalten sich: aus leichtem Verkleinern und Durchsichtigkeit in ihre Größe (0,22 s)
static func entfalten(c: Control, dauer := 0.22) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.96, 0.96)
	var los := func():
		if not is_instance_valid(c):
			return
		c.pivot_offset = c.size / 2.0
		var tw := c.create_tween().set_parallel()
		tw.tween_property(c, "modulate:a", 1.0, dauer)
		tw.tween_property(c, "scale", Vector2.ONE, dauer * 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	los.call_deferred()

static func verblassen(c: Control, dauer := 0.4) -> Tween:
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 0.0, dauer)
	return tw

# kurzer Goldglanz: hell aufleuchten und zurück
static func glanz(c: CanvasItem, kraft := 0.55) -> void:
	var tw := c.create_tween()
	c.modulate = Color(1.0 + kraft, 1.0 + kraft * 0.8, 1.0 + kraft * 0.3, c.modulate.a)
	tw.tween_property(c, "modulate", Color(1, 1, 1, c.modulate.a), 0.7).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- Thema für alles Übrige
# Bildlaufleisten, Regler, Kästchen, Tooltips und Knöpfe ohne eigene Gestaltung
static func thema(t: Theme) -> void:
	var bt := tex("bedienteile")
	# Tooltip: schlanke dunkle Tafel
	var tip := _neun("tafel_klein", 22, 12)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", PERGAMENT)
	t.set_font("font", "TooltipLabel", schrift("text"))
	t.set_font_size("font_size", "TooltipLabel", 17)
	# Bildlaufleiste: dunkle Bahn, goldener Griff
	for art in ["VScrollBar", "HScrollBar"]:
		var bahn := StyleBoxTexture.new()
		bahn.texture = bt
		bahn.region_rect = Rect2(26, 72, 12, 48)
		bahn.set_texture_margin_all(5)
		bahn.set_content_margin_all(1)
		var griff := StyleBoxTexture.new()
		griff.texture = bt
		griff.region_rect = Rect2(2, 74, 12, 44)
		griff.set_texture_margin_all(6)
		griff.set_content_margin_all(4)
		t.set_stylebox("scroll", art, bahn)
		t.set_stylebox("grabber", art, griff)
		var gh := griff.duplicate()
		gh.modulate_color = Color(1.2, 1.15, 1.0)
		t.set_stylebox("grabber_highlight", art, gh)
		t.set_stylebox("grabber_pressed", art, gh)
	# Regler: Bahn mit Goldkante, Lotosknopf
	var rb := StyleBoxTexture.new()
	rb.texture = bt
	rb.region_rect = Rect2(0, 49, 64, 10)
	rb.texture_margin_left = 6
	rb.texture_margin_right = 6
	rb.texture_margin_top = 4
	rb.texture_margin_bottom = 4
	rb.content_margin_top = 5
	rb.content_margin_bottom = 5
	t.set_stylebox("slider", "HSlider", rb)
	var voll := StyleBoxFlat.new()
	voll.bg_color = Color(GOLD, 0.55)
	voll.set_corner_radius_all(3)
	voll.content_margin_top = 3
	voll.content_margin_bottom = 3
	voll.expand_margin_top = -2
	voll.expand_margin_bottom = -2
	t.set_stylebox("grabber_area", "HSlider", voll)
	t.set_stylebox("grabber_area_highlight", "HSlider", voll)
	var knauf := AtlasTexture.new()
	knauf.atlas = bt
	knauf.region = Rect2(0, 0, 40, 40)
	t.set_icon("grabber", "HSlider", knauf)
	t.set_icon("grabber_highlight", "HSlider", knauf)
	# Kästchen
	var aus := AtlasTexture.new()
	aus.atlas = bt
	aus.region = Rect2(42, 4, 34, 34)
	var an := AtlasTexture.new()
	an.atlas = bt
	an.region = Rect2(82, 4, 34, 34)
	for k in ["CheckBox"]:
		t.set_icon("unchecked", k, aus)
		t.set_icon("checked", k, an)
		t.set_icon("unchecked_disabled", k, aus)
		t.set_icon("checked_disabled", k, an)
		t.set_constant("h_separation", k, 10)
		var leer := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			t.set_stylebox(s, k, leer)
	# Knöpfe ohne eigene Gestaltung: dunkel mit Goldkante
	var probe := Button.new()
	knopf_stil(probe, "zweit")
	for s in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
		t.set_stylebox(s, "Button", probe.get_theme_stylebox(s))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", probe.get_theme_color(c))
	probe.free()

# Platz für einen Gegenstand oder eine Fähigkeit: vertieft, mit Goldfassung; farbe: Seltenheit (dünner Ring innen)
static func platz_zeichnen(c: CanvasItem, r: Rect2, farbe := Color(0, 0, 0, 0), nur_rahmen := false) -> void:
	c.draw_style_box(_platz_sb(nur_rahmen), r)
	if farbe.a > 0.0:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = farbe
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(5)
		c.draw_style_box(sb, r.grow(-r.size.x * 0.105))

static func _platz_sb(nur_rahmen: bool) -> StyleBoxTexture:
	var k := "platz_rahmen" if nur_rahmen else "platz"
	if not _stil.has("_" + k):
		_stil["_" + k] = _neun(k, 22, 0)
	return _stil["_" + k]
