class_name Hud extends CanvasLayer
# Anzeige: Stunde und Fortschritt oben links, Leben, Eidkraft und Fähigkeiten unten,
# dazu Tafel (Kapitel), Pfortenfenster und das Fenster nach einer Niederlage.

const PARCH := Color("ece3cb")
const DIM := Color("a39c8e")
const GOLD := Color("e8b04a")
const TEAL := Color("8fe3e0")
const PANEL := Color(0.085, 0.075, 0.075, 0.95)
# Tinte auf Papyrus: Fenster sind beschriebene Blätter. Überschriften stehen in rotem Ocker (die Rubriken der Schreiber).
const INK := Color("2a1a0c")
const INK_DIM := Color("6b5236")
const RUBRIK := Color("8c2a14")
const INK_TEAL := Color("1f5c5a")

var game: Node
var root: Control
var l_track: Label
var orb_hp: Kugel
var orb_en: Kugel
var waage: Control          # Herzwaage: Feder links, Herz rechts
var quest_box: VBoxContainer
var l_buff: Label
var f_zier: FontFile        # Almendra SC: Stempel in Kapitälchen, Knöpfe
var f_text: FontFile        # Almendra: Fließtext, wie mit der Rohrfeder geschrieben
var f_fett: FontFile        # Almendra fett: Titel
var papier: Array = []      # Papyrus-Flächen: was darauf steht, wird mit Tinte geschrieben
var ink_dirty := false
var dialog_opts: Array = [] # Antworten im Gesprächsfenster (Tasten 1 bis 9)
var herz_alt := 999.0
var ann_queue: Array = []   # Ankündigungen, die noch anstehen
var ann_box: Control
var punkt_btn: Button       # „Fähigkeitenpunkt frei“ über der Leiste
var punkt_tw: Tween
var skill_ui := {}
var boss_box: Control
var bar_boss: ProgressBar
var l_boss: Label
var l_banner: Label
var l_banner_small: Label
var banner_box: Control
var l_fps: Label
var l_toast: Label
var overlay: Control       # was gerade über dem Spiel liegt (Tafel, Pforte, Niederlage)
var primary: Callable
var secondary: Callable
var primary_btn: Button
var banner_tw: Tween
var toast_tw: Tween
var menu_open := false
var menue: Menue
var bag_open := false
var karte_open := false   # große Karte (3.4)
var tree_open := false
var chapter_note := ""     # Zusatzzeile auf der Tafel (z. B. Hinweis für das iPhone)
var toasts: VBoxContainer   # Fundmeldungen links oben (07-ui.js › toast)
var bar_xp: ProgressBar
var l_lvl: Label
var tasche_btn: Button
var tree_btn: Button
var l_quer: Label          # Hinweis, das Handy quer zu halten
var intro_fall := 1        # im Startbildschirm gewählte Stunde
var tap_frame := -1        # Bild, in dem zuletzt ein Fähigkeitenknopf ausgelöst wurde (Finger meldet sich doppelt)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f_zier = load("res://ui/fonts/almendra_sc.woff")
	f_text = load("res://ui/fonts/almendra.woff")
	f_fett = load("res://ui/fonts/almendra_fett.woff")
	for f in [f_zier, f_text, f_fett]:
		f.fallbacks = [ThemeDB.fallback_font]
	get_tree().node_added.connect(_on_node_added)
	# Vignette: der Bildrand dunkelt ab, der Blick bleibt bei der Figur
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vsh := Shader.new()
	vsh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 p = UV - 0.5;\n\tCOLOR = vec4(0.02, 0.015, 0.03, smoothstep(0.16, 0.72, dot(p, p) * 2.1) * 0.6);\n}\n"
	var vm := ShaderMaterial.new()
	vm.shader = vsh
	vig.material = vm
	root.add_child(vig)
	var th := Theme.new()
	th.default_font = f_text
	th.default_font_size = 18
	root.theme = th
	add_child(root)
	# oben links: Stunde, Name, Fortschritt
	var tlp := PanelContainer.new()
	tlp.position = Vector2(8, 6)
	tlp.add_theme_stylebox_override("panel", _papyrus(16))
	papier.append(tlp)
	tlp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tlp)
	var tl := VBoxContainer.new()
	tl.custom_minimum_size = Vector2(330, 0)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tlp.add_child(tl)
	tl.add_child(_label(Stunden.case_no(Spiel.fall), 13, GOLD))
	tl.add_child(_label(game.hdef.name, 24, PARCH))
	var rule := ColorRect.new()
	rule.color = Color("7a5a26")
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(rule)
	quest_box = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 1)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(quest_box)
	var hint := _label("Finger halten: laufen · Gegner antippen: angreifen · Fähigkeiten unten antippen" if game.touch else "Esc Menü · I Tasche · K Fähigkeiten · Tab Karte · E sprechen", 12, Color(DIM, 0.7))
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.position = Vector2(-560, 14)
	hint.custom_minimum_size = Vector2(540, 0)
	root.add_child(hint)
	if game.touch:
		# ohne Tastatur: Grafik, Ton und Bildrate als Knöpfe
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		row.position = Vector2(-580, 38)
		row.custom_minimum_size = Vector2(560, 0)
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 6)
		# Grafik, Ton, Bildrate und Vollbild stehen seit 3.0 im Menü
		var knoepfe := [["Menü", func(): game.toggle_menu()], ["Tasche", func(): game.toggle_bag()], ["Fähigk.", func(): game.toggle_tree()]]
		for t in knoepfe:
			var b := Button.new()
			b.text = t[0]
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 13)
			b.custom_minimum_size = Vector2(86, 40)
			b.add_theme_stylebox_override("normal", _flat(PANEL, 8, Color("5c4a2e"), 1))
			b.add_theme_stylebox_override("hover", _flat(PANEL, 8, Color("5c4a2e"), 1))
			b.add_theme_stylebox_override("pressed", _flat(Color("211f27"), 8, DIM, 1))
			b.add_theme_color_override("font_color", PARCH)
			b.pressed.connect(t[1])
			row.add_child(b)
			if t[0] == "Tasche":
				tasche_btn = b
			if t[0] == "Fähigk.":
				tree_btn = b
		root.add_child(row)
		l_quer = _label("Bitte das Gerät quer halten.", 30, PARCH)
		l_quer.set_anchors_preset(Control.PRESET_FULL_RECT)
		l_quer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_quer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l_quer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_quer.add_theme_stylebox_override("normal", _flat(Color(0.02, 0.02, 0.04, 0.96), 0))
		l_quer.z_index = 50
		l_quer.visible = false
		root.add_child(l_quer)
	l_fps = _label("", 12, GOLD)
	l_fps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	l_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l_fps.position = Vector2(-260, 86 if game.touch else 56)
	l_fps.custom_minimum_size = Vector2(240, 0)
	l_fps.visible = false
	root.add_child(l_fps)
	# Hüter-Leiste
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(-260, 20)
	boss_box.custom_minimum_size = Vector2(520, 0)
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	l_boss = _label("", 18, PARCH)
	l_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(l_boss)
	bar_boss = _bar(Color("c06be0"), 12)
	boss_box.add_child(bar_boss)
	# Banner in der Bildmitte oben
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_box.position = Vector2(-360, 190)
	banner_box.custom_minimum_size = Vector2(720, 0)
	banner_box.modulate.a = 0.0
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_box)
	l_banner_small = _label("", 13, GOLD)
	l_banner_small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(l_banner_small)
	l_banner = _label("", 26, PARCH)
	l_banner.add_theme_font_override("font", f_text)   # ganze Sätze: Textschrift statt Zierschrift
	l_banner.add_theme_font_size_override("font_size", 28)
	l_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_banner.add_theme_constant_override("outline_size", 6)
	l_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner_box.add_child(l_banner)
	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	toasts.position = Vector2(18, -330)
	toasts.alignment = BoxContainer.ALIGNMENT_END
	toasts.custom_minimum_size = Vector2(330, 0)
	toasts.add_theme_constant_override("separation", 6)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toasts)
	l_toast = _label("", 14, PARCH)
	l_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l_toast.position = Vector2(-300, -286)
	l_toast.custom_minimum_size = Vector2(600, 0)
	l_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_toast.modulate.a = 0.0
	root.add_child(l_toast)
	# unten: Lebenskugel, Fähigkeitenleiste mit Herzwaage und Erfahrung, Kraftkugel
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.position = Vector2(-460, -188)
	bottom.custom_minimum_size = Vector2(920, 180)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	orb_hp = Kugel.new()
	orb_hp.setup(Color("c22a22"), "Leben", f_zier, 140.0)
	orb_hp.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(orb_hp)
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_END
	mid.add_theme_constant_override("separation", 3)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(mid)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(top)
	l_lvl = _label("", 12, DIM)
	l_lvl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_lvl.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(l_lvl)
	waage = Control.new()
	waage.custom_minimum_size = Vector2(96, 38)
	waage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	waage.draw.connect(_draw_waage)
	top.add_child(waage)
	l_buff = _label("", 12, TEAL)
	l_buff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_buff.size_flags_vertical = Control.SIZE_SHRINK_END
	l_buff.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(l_buff)
	var bar := PanelContainer.new()
	var bs := _flat(Color(0.065, 0.055, 0.06, 0.93), 5, Color("7a5a26"), 2)
	bs.set_content_margin_all(7)
	bs.shadow_color = Color(0, 0, 0, 0.5)
	bs.shadow_size = 6
	bar.add_theme_stylebox_override("panel", bs)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(bar)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(slots)
	for id in game.hero.ORDER:
		slots.add_child(_skill_box(id))
	bar_xp = _bar(GOLD, 5)
	mid.add_child(bar_xp)
	orb_en = Kugel.new()
	orb_en.setup(Spiel.CLS[Spiel.cls].rc, Spiel.CLS[Spiel.cls].res, f_zier, 140.0)
	orb_en.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(orb_en)
	# freier Fähigkeitenpunkt: goldener Knopf mitten über der Leiste, pulsiert, öffnet den Baum
	punkt_btn = Button.new()
	punkt_btn.focus_mode = Control.FOCUS_NONE
	punkt_btn.add_theme_font_override("font", f_zier)
	punkt_btn.add_theme_font_size_override("font_size", 15)
	punkt_btn.add_theme_stylebox_override("normal", _flat(GOLD, 8, Color("fff0c0"), 2))
	punkt_btn.add_theme_stylebox_override("hover", _flat(GOLD.lightened(0.15), 8, Color("fff0c0"), 2))
	punkt_btn.add_theme_stylebox_override("pressed", _flat(GOLD.darkened(0.15), 8, Color("fff0c0"), 2))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		punkt_btn.add_theme_color_override(c, Color("14110c"))
	punkt_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	punkt_btn.position = Vector2(-170, -244)
	punkt_btn.custom_minimum_size = Vector2(340, 40)
	punkt_btn.visible = false
	punkt_btn.pressed.connect(func(): game.toggle_tree())
	root.add_child(punkt_btn)
	if game.touch:
		# Ausweichschritt für den Daumen, unten rechts
		var ab := Button.new()
		ab.text = "Ausweichen"
		ab.focus_mode = Control.FOCUS_NONE
		ab.add_theme_font_override("font", f_zier)
		ab.add_theme_font_size_override("font_size", 14)
		ab.add_theme_stylebox_override("normal", _flat(Color(0.065, 0.055, 0.06, 0.9), 8, Color("7a5a26"), 2))
		ab.add_theme_stylebox_override("pressed", _flat(Color("211f27"), 8, GOLD, 2))
		ab.add_theme_color_override("font_color", PARCH)
		ab.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		ab.position = Vector2(-150, -96)
		ab.custom_minimum_size = Vector2(132, 78)
		ab.pressed.connect(func(): game.hero.dodge())
		root.add_child(ab)
	punkt_tw = create_tween().set_loops()
	punkt_tw.tween_property(punkt_btn, "modulate", Color(1.25, 1.2, 1.0, 1.0), 0.7)
	punkt_tw.tween_property(punkt_btn, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.7)

# Herzwaage: links die Feder der Maat, rechts das Herz. Ein leichtes Herz steigt, ein schweres sinkt.
func _draw_waage() -> void:
	var sz := waage.size
	var c := Vector2(sz.x / 2.0, 9.0)
	var ang := clampf(-Spiel.herz / 100.0, -1.0, 1.0) * 0.4
	var d := Vector2(cos(ang), sin(ang)) * sz.x * 0.36
	var gold := Color("c9a04a")
	var dim := Color("7a5a26")
	waage.draw_line(Vector2(c.x, 3), Vector2(c.x, sz.y - 3), gold, 2.0)
	waage.draw_line(Vector2(c.x - 13, sz.y - 2), Vector2(c.x + 13, sz.y - 2), gold, 3.0)
	waage.draw_line(c - d, c + d, gold, 2.5, true)
	waage.draw_circle(c, 3.0, gold)
	for side in [-1.0, 1.0]:
		var e: Vector2 = c + d * side
		var pan := e + Vector2(0, 14)
		waage.draw_line(e, pan + Vector2(-8, 0), dim, 1.0, true)
		waage.draw_line(e, pan + Vector2(8, 0), dim, 1.0, true)
		waage.draw_arc(pan, 8.0, 0.0, PI, 10, gold, 2.0, true)
		if side < 0.0:
			waage.draw_line(pan + Vector2(-5, 1), pan + Vector2(5, -6), Color("f3ead2"), 3.0, true)
		else:
			waage.draw_circle(pan + Vector2(-2.2, -3), 3.2, Color("c22a22"))
			waage.draw_circle(pan + Vector2(2.2, -3), 3.2, Color("c22a22"))

# Zeichen der Aufgaben (3.0): kleine goldene Symbole statt eines Punktes; erledigt wird zum Haken
const Q_ZEICHEN := {
	"hueter": '<path d="M16 3l11 5v8c0 7-5 11-11 13C10 27 5 23 5 16V8z" §/><circle cx="16" cy="14" r="3.5" §/>',
	"leute": '<circle cx="16" cy="9" r="4.5" §/><path d="M7 28c0-7 4-11 9-11s9 4 9 11" §/>',
	"relikt": '<path d="M16 3l3.6 8.4 9 .8-6.8 6 2 8.8L16 22.4 8.2 27l2-8.8-6.8-6 9-.8z" §/>',
	"feuer": '<path d="M16 3c1 5 7 8 7 15a7 7 0 0 1-14 0c0-4 2-6 3-9 1 2 2 3 3 3 1-2 0-5 1-9z" §/><path d="M7 28h18" §/>',
	"krug": '<path d="M11 5h10M12 5c0 4-5 6-5 13 0 6 4 9 9 9s9-3 9-9c0-7-5-9-5-13" §/><path d="M13 16c1-2 5-2 6 0 1 3-3 5-3 5s-4-2-3-5z" §/>',
	"namenlos": '<ellipse cx="16" cy="14" rx="7" ry="10" §/><path d="M8 28h16" §/><circle cx="16" cy="14" r="1.6" fill="#e8b04a"/>',
	"erledigt": '<circle cx="16" cy="16" r="12" stroke="#7a6a4a" stroke-width="2" fill="none"/><path d="M9.5 16.5l4.5 4.5 8.5-10" stroke="#7a6a4a" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
}
var q_bilder := {}

func _quest_bild(id: String) -> Texture2D:
	if not q_bilder.has(id):
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 32 32">%s</svg>' % String(Q_ZEICHEN.get(id, Q_ZEICHEN.relikt)).replace("§", 'stroke="#5a3a12" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"')
		var img := Image.new()
		img.load_svg_from_string(svg, 1.0)
		q_bilder[id] = ImageTexture.create_from_image(img)
	return q_bilder[id]

# Fortschritt aus dem Kurztext: „2/5“ oder „40 %“ → 0 bis 1, sonst −1
func _anteil(kurz: String) -> float:
	if "/" in kurz:
		var t := kurz.split("/")
		return clampf(float(t[0]) / maxf(1.0, float(t[1])), 0.0, 1.0)
	if kurz.ends_with("%"):
		return clampf(float(kurz.trim_suffix("%")) / 100.0, 0.0, 1.0)
	return -1.0

# Questbuch oben links (3.0): je Aufgabe ein Zeichen, der Titel, rechts der Stand, darunter ein Fortschrittsbalken
# und ein Satz. Erledigtes schrumpft auf eine Zeile mit Haken.
func _quests() -> void:
	for c in quest_box.get_children():
		quest_box.remove_child(c)
		c.queue_free()
	var offen := 0
	for q in game.orte.quests:
		if not q.done:
			offen += 1
	var kopf := _label("AUFGABEN DIESER STUNDE" + ("" if offen > 0 else " · ALLE ERLEDIGT"), 11, DIM)
	quest_box.add_child(kopf)
	for q in game.orte.quests:
		var kurz: String = q.get("kurz", "")
		var zeile := HBoxContainer.new()
		zeile.add_theme_constant_override("separation", 7)
		zeile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := TextureRect.new()
		ic.texture = _quest_bild("erledigt" if q.done else q.id)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.custom_minimum_size = Vector2(22, 22)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zeile.add_child(ic)
		var sp := VBoxContainer.new()
		sp.add_theme_constant_override("separation", 1)
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zeile.add_child(sp)
		var kz := HBoxContainer.new()
		kz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var titel := _label(q.titel.to_upper(), 12, DIM if q.done else GOLD)
		titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		titel.clip_text = true
		kz.add_child(titel)
		if not q.done and kurz != "":
			kz.add_child(_label(kurz, 12, PARCH))
		sp.add_child(kz)
		quest_box.add_child(zeile)
		if q.done:
			continue
		var an := _anteil(kurz)
		if an >= 0.0:
			var bahn := ColorRect.new()
			bahn.color = Color(0.25, 0.17, 0.07, 0.35)
			bahn.custom_minimum_size = Vector2(0, 4)
			bahn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var voll := ColorRect.new()
			voll.color = Color("8a5a16")
			voll.mouse_filter = Control.MOUSE_FILTER_IGNORE
			voll.anchor_right = an
			voll.anchor_bottom = 1.0
			bahn.add_child(voll)
			sp.add_child(bahn)
		if game.touch:
			continue   # auf dem Handy knapp: Zeichen, Titel, Stand
		var l := _label(q.text, 13, PARCH)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(290, 0)
		sp.add_child(l)
	var segen := []
	for id in game.orte.buffs:
		for g in Orte.GOETTER:
			if g.id == id:
				segen.append("%s %d s" % [g.name, int(game.orte.buffs[id])])
	l_buff.text = "Segen: " + ", ".join(segen) if not segen.is_empty() else ""

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	# Zierschrift für Titel und für Stempel in Großbuchstaben, sonst die Textschrift (zwei Punkt größer: sie läuft schmaler)
	var stempel: bool = t.length() > 2 and t == t.to_upper() and t != t.to_lower()
	l.add_theme_font_override("font", f_fett if size >= 22 else (f_zier if stempel else f_text))
	l.add_theme_font_size_override("font_size", size + (0 if size >= 22 else (3 if stempel else 2)))
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# Papyrusblatt als Fläche: gekreuzte Fasern, ausgefranster dunkler Rand (ui/papyrus.webp, erzeugt mit tools/papyrus.py)
func _papyrus(margin := 26) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://ui/papyrus.webp")
	sb.set_texture_margin_all(40)
	sb.set_content_margin_all(margin)
	return sb

func _on_node_added(n: Node) -> void:
	if n is Control and not papier.is_empty() and not ink_dirty:
		ink_dirty = true
		_ink_all.call_deferred()

# Alles, was auf Papyrus steht, bekommt Tinte: helle Schrift wird dunkelbraun, Gold wird zur roten Rubrik.
# Dunkle Einlagen (Felder für Gegenstände) behalten ihre helle Schrift.
func _ink_all() -> void:
	ink_dirty = false
	papier = papier.filter(func(p): return is_instance_valid(p))
	for p in papier:
		_ink_walk(p, p)

func _ink_color(c: Color) -> Color:
	for pair in [[PARCH, INK], [DIM, INK_DIM], [GOLD, RUBRIK], [TEAL, INK_TEAL]]:
		var k: Color = pair[0]
		if absf(c.r - k.r) + absf(c.g - k.g) + absf(c.b - k.b) < 0.02:
			return Color(pair[1], maxf(c.a, 0.75))
	if c.get_luminance() > 0.5:
		# unbekannte helle Farbe (Seltenheit eines Gegenstands): dunkler und satter, damit sie auf Papyrus lesbar ist
		return Color.from_hsv(c.h, minf(1.0, c.s * 1.3 + 0.25), c.v * 0.4, maxf(c.a, 0.8))
	return c

func _ink_walk(n: Node, blatt: Node) -> void:
	if n != blatt and (n is PanelContainer or n is Panel):
		var sb: StyleBox = n.get_theme_stylebox("panel")
		if sb is StyleBoxFlat and sb.bg_color.a > 0.5 and sb.bg_color.get_luminance() < 0.35:
			return   # dunkle Einlage: bleibt, wie sie ist
	if n is Button:
		var nb: StyleBox = n.get_theme_stylebox("normal")
		if nb is StyleBoxFlat and nb.bg_color.a > 0.5 and nb.bg_color.get_luminance() < 0.35:
			return
		var hb: StyleBox = n.get_theme_stylebox("hover")
		if hb is StyleBoxFlat and hb.bg_color.a < 0.1 and hb.bg_color.get_luminance() > 0.9:
			n.add_theme_stylebox_override("hover", _flat(Color(0.35, 0.2, 0.08, 0.14), 8, INK_DIM, 1))
	if n is Control:
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
			if n.has_theme_color_override(key):
				var c: Color = n.get_theme_color(key)
				var m := _ink_color(c)
				if m != c:
					n.add_theme_color_override(key, m)
		if n is Label and n.has_theme_constant_override("outline_size"):
			n.add_theme_constant_override("outline_size", 0)
	for ch in n.get_children():
		_ink_walk(ch, blatt)

func _flat(col: Color, radius := 6, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	if game.touch:
		# auf iPhone und iPad haben geglättete runde Ecken in manchen Fällen den Grafikkontext gekostet (Godot-Fehler 105945)
		s.anti_aliasing = false
		s.corner_detail = 1
	return s

func _bar(col: Color, h: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.001
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_stylebox_override("background", _flat(Color(0.03, 0.03, 0.05, 0.85), 4, Color("5c4a2e"), 1))
	b.add_theme_stylebox_override("fill", _flat(col, 4))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _skill_box(id: String) -> Control:
	var S: Dictionary = game.hero.SK[id]
	var slot: int = game.hero.ORDER.find(id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := Panel.new()
	p.custom_minimum_size = Vector2(84, 84)
	p.add_theme_stylebox_override("panel", _flat(Color(0.115, 0.1, 0.095, 1.0), 5, Color("7a5a26"), 2))
	p.tooltip_text = "%s: %s" % [S.name, S.txt]
	p.gui_input.connect(func(ev):
		# Maus oder Finger. Ein zweiter Finger kommt nur als Berührung an (der erste hält die Figur in Bewegung),
		# der erste Finger meldet sich als beides: darum je Bild nur einmal auslösen.
		var tap: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)
		if tap and not get_tree().paused and tap_frame != Engine.get_process_frames():
			tap_frame = Engine.get_process_frames()
			if not Spiel.gelernt(id):
				game.nicht_gelernt(id)
				return
			# der Zeiger liegt auf dem Knopf, nicht auf einem Ziel: auf den nächsten Gegner zielen, sonst nach vorn
			var near: Foe = game.foe_near(game.hero.global_position, 20.8)
			game.hero.aim = near.global_position if near else game.hero.global_position + game.hero.forward() * 8.8
			game.hero.auto_aim = true
			game.hero.cast(id))
	box.add_child(p)
	# das Zeichen füllt den Platz: goldene Hieroglyphe auf der Steintafel der Klasse (scripts/glyphen.gd)
	var ic := TextureRect.new()
	ic.texture = Klassen.icon(id, 160)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.position = Vector2(2, 2)
	ic.size = Vector2(80, 80)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(ic)
	var cdr := ColorRect.new()
	cdr.color = Color(0, 0, 0, 0.66)
	cdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cdr.position = Vector2(2, 2)
	cdr.size = Vector2(80, 80)
	cdr.scale.y = 0.0
	p.add_child(cdr)
	var k := _label(Klassen.keys()[slot], 13, PARCH)
	k.position = Vector2(8, 4)
	k.add_theme_constant_override("outline_size", 5)
	k.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	p.add_child(k)
	var c := _label(str(int(S.cost)) if S.cost > 0 else "", 12, PARCH)
	c.position = Vector2(0, 60)
	c.size = Vector2(75, 18)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	c.add_theme_constant_override("outline_size", 5)
	c.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	p.add_child(c)
	# noch nicht gelernt: Hinweis mit der Stufe
	var lock := _label("", 12, GOLD)
	lock.position = Vector2(0, 30)
	lock.size = Vector2(84, 24)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.add_theme_constant_override("outline_size", 6)
	lock.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	p.add_child(lock)
	var nm := _label(S.name, 10, DIM)
	nm.custom_minimum_size = Vector2(84, 30)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_constant_override("line_spacing", -3)
	nm.add_theme_constant_override("outline_size", 4)
	nm.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	box.add_child(nm)
	skill_ui[id] = {"panel": p, "cd": cdr, "sub": c, "key": k, "icon": ic, "lock": lock, "name": nm, "need": Klassen.unlock_lvl(Spiel.cls, id)}
	return box

# Ankündigung in der Bildmitte oben: neue Fähigkeit, Stufenaufstieg, freier Punkt. Mehrere stehen nacheinander an.
func announce(icon: Texture2D, stamp: String, title: String, text: String, secs := 6.0) -> void:
	ann_queue.append([icon, stamp, title, text, secs])
	if ann_box == null:
		_announce_next()

func _announce_next() -> void:
	if ann_queue.is_empty():
		ann_box = null
		return
	var a: Array = ann_queue.pop_front()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _papyrus(22))
	papier.append(p)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(-290, 262)   # unter dem Banner der Stunde, mitten im Blick
	p.custom_minimum_size = Vector2(580, 0)
	p.modulate.a = 0.0
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	if a[0]:
		var ic := TextureRect.new()
		ic.texture = a[0]
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.custom_minimum_size = Vector2(88, 88)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(ic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(_label(a[1], 13, GOLD))
	v.add_child(_label(a[2], 26, PARCH))
	var t := _para(a[3], 14, PARCH)
	v.add_child(t)
	root.add_child(p)
	ann_box = p
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.35)
	tw.tween_interval(a[4])
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		p.queue_free()
		_announce_next())

func _process(_d: float) -> void:
	var _u := Time.get_ticks_usec()
	_process_innen(_d)
	Protokoll.zeit("oberfläche", _u)

func _process_innen(_d: float) -> void:
	if ann_box and is_instance_valid(ann_box):
		ann_box.visible = overlay == null   # Ankündigungen liegen nie über einem Fenster
	if l_quer:
		var vs := get_viewport().get_visible_rect().size
		l_quer.visible = vs.y > vs.x

func mouse_over_ui() -> bool:
	return overlay != null or get_viewport().gui_get_hovered_control() != null

func refresh() -> void:
	var h: Hero = game.hero
	orb_hp.value = h.hp / h.max_hp
	orb_hp.set_text(str(int(ceil(h.hp))))
	orb_en.value = h.en / 100.0
	orb_en.set_text(str(int(h.en)))
	if game.orte.dirty or not game.orte.buffs.is_empty():
		game.orte.dirty = false
		_quests()
	if Spiel.herz != herz_alt:
		herz_alt = Spiel.herz
		waage.queue_redraw()
	bar_xp.value = Spiel.xp / Daten.xp_need(Spiel.lvl)
	l_lvl.text = "Stufe %d" % Spiel.lvl
	if tasche_btn:
		tasche_btn.add_theme_color_override("font_color", GOLD if Spiel.neu > 0 else PARCH)
	if tree_btn:
		tree_btn.add_theme_color_override("font_color", GOLD if Spiel.tree_points() > 0 else PARCH)
	var pts: int = Spiel.tree_points()
	punkt_btn.visible = pts > 0 and overlay == null
	if pts > 0:
		punkt_btn.text = ("%d Fähigkeitenpunkt%s frei" % [pts, "" if pts == 1 else "e"]) + ("" if game.touch else "  ·  Taste K")
	for id in h.ORDER:
		var S: Dictionary = h.SK[id]
		var u: Dictionary = skill_ui[id]
		u.cd.scale.y = clampf(h.cd[id] / h.cd_of(id), 0.0, 1.0)
		if id != "potion" and S.cost > 0:
			u.sub.text = str(int(round(h.cost_of(id))))
		var poor: bool = (h.pots <= 0) if id == "potion" else h.en < h.cost_of(id)
		var locked: bool = not Spiel.gelernt(id)
		u.panel.modulate = Color(1, 1, 1, 0.45) if poor and not locked else Color.WHITE
		u.icon.modulate = Color(0.25, 0.25, 0.28, 0.7) if locked else Color.WHITE
		# ungelernt: erst ab ihrer Stufe lernbar, dann wartet sie im Fähigkeitenbaum auf einen Punkt
		# seit 3.3: auf der Stufe, aber im Baum noch kein Weg dorthin
		var weg: bool = Spiel.nachbar_gelernt("s:" + id) if locked and id != "potion" else true
		u.lock.text = "" if not locked else ("AB STUFE %d" % u.need if u.need > Spiel.lvl else ("LERNEN" if weg else "WEG FEHLT"))
		u.lock.add_theme_color_override("font_color", GOLD if pts > 0 and u.need <= Spiel.lvl and weg else DIM)
		u.name.modulate.a = 0.45 if locked else 1.0
		if locked:
			u.sub.text = ""
			continue
		if id == "potion":
			u.sub.text = "×%d" % h.pots
	if boss_box.visible:
		bar_boss.value = game.boss.hp / game.boss.max_hp
	if l_fps.visible:
		l_fps.text = "%d Bilder/s · Grafik %s" % [Engine.get_frames_per_second(), "niedrig" if game.low_gfx else "hoch"]

func toggle_fps() -> void:
	l_fps.visible = not l_fps.visible

func boss_show(name: String) -> void:
	l_boss.text = name
	boss_box.visible = true

func boss_hide() -> void:
	boss_box.visible = false

func banner(text: String, small := "", secs := 3.5) -> void:
	l_banner.text = text
	l_banner_small.text = small
	if banner_tw:
		banner_tw.kill()
	banner_tw = create_tween()
	banner_tw.tween_property(banner_box, "modulate:a", 1.0, 0.5)
	banner_tw.tween_interval(secs)
	banner_tw.tween_property(banner_box, "modulate:a", 0.0, 0.9)

# Fundmeldung mit Symbol (höchstens fünf, ältere fallen heraus)
func toast_item(icon: int, title: String, sub: String, col: Color, secs := 4.0) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _flat(Color(0.067, 0.063, 0.086, 0.92), 8, Color("5c4a2e"), 1))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(3, 0)
	h.add_child(bar)
	if icon >= 0:
		var tr := TextureRect.new()
		tr.texture = Daten.icon(icon)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(36, 36)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := _label(title, 14, col)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	v.add_child(t)
	if sub != "":
		var sl := _label(sub, 11, Color("7ad08a") if sub.contains("▲") else DIM)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sl)
	h.add_child(v)
	toasts.add_child(p)
	while toasts.get_child_count() > 5:
		var o := toasts.get_child(0)
		toasts.remove_child(o)
		o.queue_free()
	var tw := p.create_tween()
	tw.tween_interval(secs)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

func toast(text: String, secs := 2.2, col := PARCH) -> void:
	l_toast.text = text
	l_toast.add_theme_color_override("font_color", col)
	if toast_tw:
		toast_tw.kill()
	toast_tw = create_tween()
	toast_tw.tween_property(l_toast, "modulate:a", 1.0, 0.2)
	toast_tw.tween_interval(secs)
	toast_tw.tween_property(l_toast, "modulate:a", 0.0, 0.6)

# dein Ba spricht leise über der Leiste
func whisper(text: String) -> void:
	toast(text, 7.0, TEAL)
	erklaere(text)

# ---------------------------------------------------------------- Fenster
# Gespräch oder Entscheidung: Absätze, darunter die Antworten (Tasten 1 bis 9; Esc nimmt die letzte: gehen, liegen lassen)
# bild: Kürzel eines Porträts (ui/portraits/P01.webp …). Liegt es vor, steht es links neben dem Text, wie bei den
# alten Rollenspielen; fehlt es, bleibt das Fenster wie bisher.
func show_dialog(stamp: String, title: String, sub: String, paras: Array, opts: Array, bild := "") -> void:
	var path := "res://ui/portraits/%s.webp" % bild
	var has_pic := bild != "" and ResourceLoader.exists(path)
	var v := _sheet(0.5, 860 if has_pic and not game.touch else 680)
	if has_pic:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		var frame := PanelContainer.new()
		var fs := _flat(Color(0, 0, 0, 0.6), 6, Color("c9a04a"), 2)
		fs.set_content_margin_all(3)
		frame.add_theme_stylebox_override("panel", fs)
		frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var pic := TextureRect.new()
		pic.texture = load(path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(150, 200) if game.touch else Vector2(192, 256)
		frame.add_child(pic)
		row.add_child(frame)
		var right := VBoxContainer.new()
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right.add_theme_constant_override("separation", 14)
		row.add_child(right)
		v.add_child(row)
		v = right
	v.add_child(_para(stamp, 13, GOLD))
	v.add_child(_para(title, 28, PARCH))
	if sub != "":
		v.add_child(_para(sub, 14, DIM))
	for p in paras:
		if p != "":
			v.add_child(_para(p, 16, PARCH))
	_fussnoten(v, [title, sub] + paras, 2)
	var cbs := []
	var i := 0
	for o in opts:
		i += 1
		var cb: Callable = o[1]
		var b := _button(("  %d    %s  " % [i, o[0]]) if not game.touch and opts.size() > 1 else "  %s  " % o[0], opts.size() == 1, cb)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", f_text)
		b.add_theme_font_size_override("font_size", 18)
		v.add_child(b)
		cbs.append(cb)
		if opts.size() == 1:
			primary = cb
			primary_btn = b
			b.grab_focus()
	if opts.size() > 1:
		secondary = cbs[-1]
	dialog_opts = cbs
	_pass_all(v)

func press_option(i: int) -> bool:
	if i < 0 or i >= dialog_opts.size():
		return false
	var f: Callable = dialog_opts[i]
	_close()
	f.call()
	return true

func _close() -> void:
	bag_open = false
	karte_open = false
	menu_open = false
	menue = null
	dialog_opts = []

	tree_open = false
	if overlay:
		overlay.queue_free()
		overlay = null
	primary = Callable()
	secondary = Callable()
	primary_btn = null

func _button(text: String, main: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", f_zier)
	b.add_theme_font_size_override("font_size", 17)
	b.custom_minimum_size = Vector2(0, 46)
	if main:
		b.add_theme_stylebox_override("normal", _flat(GOLD, 8))
		b.add_theme_stylebox_override("hover", _flat(GOLD.lightened(0.15), 8))
		b.add_theme_stylebox_override("pressed", _flat(GOLD.darkened(0.15), 8))
		b.add_theme_stylebox_override("disabled", _flat(Color(GOLD, 0.3), 8))
		b.add_theme_stylebox_override("focus", _flat(Color(0, 0, 0, 0), 8, PARCH, 2))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			b.add_theme_color_override(c, Color("14110c"))
	else:
		b.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0), 8, Color("5c4a2e"), 1))
		b.add_theme_stylebox_override("hover", _flat(Color(1, 1, 1, 0.06), 8, DIM, 1))
		b.add_theme_color_override("font_color", PARCH)
	var m := MarginContainer.new()
	b.pressed.connect(func():
		game.sfx.play("ui")
		var f := cb
		_close()
		f.call())
	return b

func _taste(text: String) -> String:
	# auf dem Handy gibt es keine Tasten: den Hinweis in eckigen Klammern weglassen
	if not game.touch:
		return text
	return text.replace("[E]  ", "").replace("[Esc]  ", "").replace("[I]  ", "")

func _sheet(dim: float, width: float, titel := false) -> VBoxContainer:
	_close()
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.04, dim)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	if titel:
		# Titelbild der Nebelmark (X01: Sandtor bei Nacht) hinter einem Verlauf von halb zu fast ganz dunkel, wie in der 2D-Fassung
		var bild := TextureRect.new()
		bild.texture = load("res://ui/titel.webp")
		bild.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bild.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bild.set_anchors_preset(Control.PRESET_FULL_RECT)
		bild.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bild)
		var g := Gradient.new()
		g.set_color(0, Color(0.02, 0.02, 0.04, 0.5))
		g.set_color(1, Color(0.02, 0.02, 0.04, 0.86))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		var schleier := TextureRect.new()
		schleier.texture = gt
		schleier.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		schleier.stretch_mode = TextureRect.STRETCH_SCALE
		schleier.set_anchors_preset(Control.PRESET_FULL_RECT)
		schleier.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(schleier)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(sc)
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 16)
	sc.add_child(mc)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mc.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(width, get_viewport().get_visible_rect().size.x - 32.0), 0)
	panel.add_theme_stylebox_override("panel", _papyrus(14))
	papier.append(panel)
	center.add_child(panel)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	_pass_all.call_deferred(overlay)
	return v

# Fenster rollen per Finger nur, wenn die Berührung beim Rollbereich ankommt: alle Flächen darin reichen sie weiter
# (Knöpfe lösen trotzdem aus). Die Abdeckung selbst bleibt dicht, damit nichts ins Spiel durchgeht.
func _pass_all(n: Node) -> void:
	if not is_instance_valid(n):
		return
	for c in n.get_children():
		if c is Control and not (c is ScrollContainer) and c.mouse_filter == Control.MOUSE_FILTER_STOP:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_all(c)

func _para(text: String, size: int, col: Color, center := false) -> Label:
	var l := _label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", 5)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

# Schwarze Tafel mit Stunde, Namen und Lage. Erst der Knopf gibt das Spiel frei.
# Fußnoten (3.0): Begriffe, die in diesen Texten zum ersten Mal vorkommen, werden darunter in einem Satz erklärt
func _fussnoten(v: VBoxContainer, texte: Array, hoechstens := 2, mitte := false) -> void:
	var neu := Lexikon.neu_in(texte, hoechstens)
	if neu.is_empty():
		return
	var kasten := PanelContainer.new()
	var st := _flat(Color(0.2, 0.14, 0.06, 0.1), 6, Color(0.36, 0.25, 0.1, 0.55), 1)
	st.set_content_margin_all(10)
	kasten.add_theme_stylebox_override("panel", st)
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 4)
	kasten.add_child(kv)
	for e in neu:
		kv.add_child(_para("%s: %s" % [e.name, e.txt], 13, TEAL, mitte))
	v.add_child(kasten)

# Kurzer Hinweis nach einem geflüsterten oder eingeblendeten Satz: ein neuer Begriff, in einem Satz erklärt
func erklaere(text: String) -> void:
	var neu := Lexikon.neu_in([text], 1)
	if neu.is_empty():
		return
	var e: Dictionary = neu[0]
	get_tree().create_timer(2.2, true, false, true).timeout.connect(func():
		toast("%s: %s" % [e.name, e.txt], 9.0, TEAL))

func show_chapter(no: String, name: String, lead: String, brief: String, btn: String, cb: Callable) -> void:
	var v := _sheet(1.0, 720)
	v.add_child(_para(no, 14, GOLD, true))
	v.add_child(_para(name, 46, PARCH, true))
	# Rückblick: was in der Stunde davor geschah (ab der zweiten Stunde der ersten Nacht)
	var bisher := Worte.bisher(Stunden.hour_of(Spiel.fall)) if Stunden.night_of(Spiel.fall) == 1 else ""
	if bisher != "":
		v.add_child(_para("BISHER", 11, DIM, true))
		v.add_child(_para(bisher, 14, DIM, true))
	v.add_child(_para(lead, 20, PARCH, true))
	v.add_child(_para(brief, 16, DIM, true))
	# auf dem Handy steht der Knopf vor den Erklärungen, damit er ohne Rollen zu sehen ist
	var knopf := func():
		var row := CenterContainer.new()
		primary_btn = _button(_taste("  %s  [E]  " % btn), true, cb)
		primary_btn.disabled = true
		row.add_child(primary_btn)
		v.add_child(row)
	if game.touch:
		knopf.call()
	if not Spiel.gesehen("so_geht_es"):
		Spiel.merke("so_geht_es")
		v.add_child(_para(Worte.SO_GEHT_ES, 14, TEAL, true))
	_fussnoten(v, [bisher, lead, brief], 3, true)
	if chapter_note != "":
		v.add_child(_para(chapter_note, 14, TEAL, true))
	if not game.touch:
		knopf.call()
	primary = cb
	var b := primary_btn
	get_tree().create_timer(0.9, true, false, true).timeout.connect(func():
		if is_instance_valid(b):
			b.disabled = false
			b.grab_focus())

func show_gate(stamp: String, title: String, epi: String, stats: Array, next_no: String, next_name: String, next_lead: String, go: Callable, stay: Callable) -> void:
	var v := _sheet(0.8, 560)
	v.add_child(_para(stamp, 13, GOLD))
	v.add_child(_para(title, 28, PARCH))
	v.add_child(_para(epi, 16, PARCH))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for s in stats:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", _flat(Color("211f27"), 8, Color("5c4a2e"), 1))
		var pv := VBoxContainer.new()
		pv.add_child(_label("  " + s[0], 20, PARCH))
		pv.add_child(_label("  " + s[1].to_upper(), 11, DIM))
		p.add_child(pv)
		row.add_child(p)
	v.add_child(row)
	v.add_child(_para(next_no, 12, TEAL))
	v.add_child(_para(next_name, 20, PARCH))
	v.add_child(_para(next_lead, 14, DIM))
	_fussnoten(v, [epi], 2)
	v.add_child(_para("Die Pforte bleibt offen, solange du willst.", 13, DIM))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	primary_btn = _button(_taste("  Durch die Pforte gehen  [E]  "), true, go)
	btns.add_child(primary_btn)
	btns.add_child(_button(_taste("  Noch bleiben  [Esc]  "), false, stay))
	v.add_child(btns)
	primary = go
	secondary = stay
	primary_btn.grab_focus()

# Große Karte der Stunde (3.4): dieselbe Karte wie oben rechts, groß, mit Legende
func show_karte() -> void:
	var vs := get_viewport().get_visible_rect().size
	var v := _sheet(0.86, minf(1100.0, vs.x - 32.0))
	karte_open = true
	var kopf := HBoxContainer.new()
	var t := _label("Karte · " + Stunden.hour_txt(Spiel.fall), 24, PARCH)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(t)
	kopf.add_child(_button(_taste("  Schließen  [Tab]  "), false, func(): close_bag()))
	v.add_child(kopf)
	var k := KarteAnzeige.new()
	k.gross = true
	k.setup(game, game.karte)
	k.seen = game.karte_ui.seen   # was die Figur schon gesehen hat, ist auch groß aufgedeckt
	var breite := minf(1100.0, vs.x - 32.0) - 48.0
	var hoehe := minf(breite * float(Karte.GH) / float(Karte.GW), vs.y - 240.0)
	k.custom_minimum_size = Vector2(hoehe * float(Karte.GW) / float(Karte.GH), hoehe)
	k.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(k)
	var leg := HFlowContainer.new()
	leg.add_theme_constant_override("h_separation", 18)
	for e in [["●", Color(1.0, 0.62, 0.25), "Feuerschale (entzündet: Rückkehrpunkt)"], ["▮", Color(0.55, 0.75, 1.0), "Schrein des Thot (umlernen)"],
			["■", Color(0.95, 0.75, 0.4), "Werkstatt des Ptah"], ["●", Color(0.95, 0.82, 0.29), "Rudel"], ["◆", Color(1.0, 0.85, 0.4), "Fundstück der Stunde"],
			["○", Color(0.56, 0.89, 0.88), "Pforte"], ["▲", Color(1.0, 0.97, 0.88), "du"]]:
		var h := HBoxContainer.new()
		h.add_child(_label(e[0], 14, e[1]))
		h.add_child(_label(e[2], 12, DIM))
		leg.add_child(h)
	v.add_child(leg)
	secondary = func(): get_tree().paused = false

func show_bag() -> void:
	var v := _sheet(0.86, 880)
	bag_open = true
	var t := Tasche.new()
	t.hud = self
	t.game = game
	v.add_child(t)
	var cb := func(): get_tree().paused = false
	secondary = cb

# Spielmenü: hält das Spiel an (Esc)
func show_menu() -> void:
	var v := _sheet(0.82, 640)
	menu_open = true
	menue = Menue.new()
	menue.hud = self
	menue.game = game
	v.add_child(menue)

# Werkstatt des Ptah: dasselbe Fenster wie die Tasche, aber mit Aufwerten, Neu-Fassen und der Fundkiste
func show_werkstatt() -> void:
	var v := _sheet(0.86, 880)
	bag_open = true
	var t := Tasche.new()
	t.hud = self
	t.game = game
	t.werkstatt = true
	v.add_child(t)
	secondary = func(): get_tree().paused = false

func show_tree() -> void:
	var v := _sheet(0.86, 1180)
	tree_open = true
	var t := Baum.new()
	t.hud = self
	t.game = game
	baum_ui = t
	v.add_child(t)
	secondary = func(): get_tree().paused = false

func close_bag() -> void:
	_close()
	get_tree().paused = false

func show_dead(text: String, cb: Callable, btn := "Zurück in die Stunde") -> void:
	var v := _sheet(0.8, 560)
	v.add_child(_para("IN DER DUAT", 13, GOLD))
	v.add_child(_para("Du wurdest überwältigt.", 28, PARCH))
	v.add_child(_para(text + ("" if Spiel.hc else " Deine Kraft kehrt zurück."), 16, PARCH))
	var btns := HBoxContainer.new()
	primary_btn = _button(_taste("  %s  [E]  " % btn), true, cb)
	btns.add_child(primary_btn)
	v.add_child(btns)
	primary = cb
	primary_btn.grab_focus()

func press_primary() -> bool:
	if overlay == null or not primary.is_valid() or (primary_btn and primary_btn.disabled):
		return false
	var f := primary
	_close()
	f.call()
	return true

var baum_ui: Baum

# Gamepad in Fenstern (4.0): A bestätigt bzw. wählt die erste Antwort, X und Y die zweite und dritte, B schließt.
# Im Baum wählt das Steuerkreuz links/rechts einen Knoten, A lernt ihn.
func _pad(ev: InputEventJoypadButton) -> bool:
	var b := ev.button_index
	if menu_open:
		if b == JOY_BUTTON_START or b == JOY_BUTTON_B:
			if b == JOY_BUTTON_START or not menue.zurueck():
				game.toggle_menu()
			return true
		return false
	if tree_open and baum_ui:
		match b:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				baum_ui.pad_schritt(-1 if b == JOY_BUTTON_DPAD_LEFT else 1)
			JOY_BUTTON_A:
				baum_ui.pad_lernen()
			JOY_BUTTON_B, JOY_BUTTON_DPAD_UP:
				close_bag()
		return true
	if karte_open or bag_open:
		if b == JOY_BUTTON_B or b == JOY_BUTTON_BACK or b == JOY_BUTTON_DPAD_DOWN:
			close_bag()
		return true
	if overlay == null:
		return false
	if not dialog_opts.is_empty():
		var i := {JOY_BUTTON_A: 0, JOY_BUTTON_X: 1, JOY_BUTTON_Y: 2}.get(b, -1) as int
		if i >= 0 and i < dialog_opts.size():
			game.sfx.play("ui")
			press_option(i)
		return true
	if b == JOY_BUTTON_A and primary.is_valid() and not (primary_btn and primary_btn.disabled):
		game.sfx.play("ui")
		press_primary()
	elif b == JOY_BUTTON_B and secondary.is_valid():
		var f := secondary
		_close()
		f.call()
	return true

func _input(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton and ev.pressed:
		if _pad(ev):
			get_viewport().set_input_as_handled()
		return
	if menu_open and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		if not menue.zurueck():
			game.toggle_menu()
		return
	if tree_open and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_K:
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		close_bag()
		return
	if karte_open and ev is InputEventKey and ev.pressed and not ev.echo and (ev.keycode == KEY_TAB or ev.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		close_bag()
		return
	if bag_open and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_I:
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		close_bag()
		return
	if overlay == null or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if not dialog_opts.is_empty() and ev.keycode >= KEY_1 and ev.keycode <= KEY_9 and ev.keycode - KEY_1 < dialog_opts.size():
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		press_option(ev.keycode - KEY_1)
		return
	if ev.keycode == KEY_E or ev.keycode == KEY_ENTER or ev.keycode == KEY_KP_ENTER:
		get_viewport().set_input_as_handled()
		if primary.is_valid() and not (primary_btn and primary_btn.disabled):
			game.sfx.play("ui")   # vor dem Auslösen: danach kann die Szene schon neu geladen sein
			press_primary()
	elif ev.keycode == KEY_ESCAPE and secondary.is_valid():
		get_viewport().set_input_as_handled()
		var f := secondary
		_close()
		f.call()

# Fund aus einer Truhe (07-ui.js › showChest): „Alles nehmen“ (E) oder „Liegen lassen“ (Esc)
func show_chest(stamp: String, title: String, lines: Array, note: String, take: Callable, leave: Callable) -> void:
	var v := _sheet(0.8, 500)
	v.add_child(_para(stamp, 13, GOLD))
	v.add_child(_para(title, 26, PARCH))
	for ln in lines:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat(Color("211f27"), 8, Color("5c4a2e"), 1))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		p.add_child(h)
		var bar := ColorRect.new()
		bar.color = ln[3]
		bar.custom_minimum_size = Vector2(3, 0)
		h.add_child(bar)
		var tr := TextureRect.new()
		tr.texture = Daten.icon(ln[0])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(44, 44)
		h.add_child(tr)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(_label(ln[1], 16, ln[3]))
		if ln[2] != "":
			tv.add_child(_label(ln[2], 11, Color("7ad08a") if String(ln[2]).contains("▲") else DIM))
		h.add_child(tv)
		v.add_child(p)
	if note != "":
		v.add_child(_para(note, 13, DIM))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	primary_btn = _button(_taste("  Alles nehmen  [E]  "), true, take)
	btns.add_child(primary_btn)
	btns.add_child(_button(_taste("  Liegen lassen  [Esc]  "), false, leave))
	v.add_child(btns)
	primary = take
	secondary = leave
	primary_btn.grab_focus()

# Startbildschirm (07-ui.js › showIntro): neue Figur mit Schwierigkeit und Hardcore, oder weiterspielen
var intro_new := false
var intro_diff := 0
var intro_hc := false
var intro_cls := "ermittler"

func _class_card(c: String) -> Control:
	var C: Dictionary = Klassen.CLS[c]
	var on := c == intro_cls
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 92 if game.touch else 146)
	b.add_theme_stylebox_override("normal", _flat(Color("211f27"), 8, C.col if on else Color("5c4a2e"), 3 if on else 1))
	b.add_theme_stylebox_override("hover", _flat(Color("2a2731"), 8, C.col, 2))
	b.add_theme_stylebox_override("pressed", _flat(Color("2a2731"), 8, C.col, 3))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.offset_right = -6
	h.offset_top = 6
	h.offset_bottom = -6
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 6)
	var tr := TextureRect.new()
	tr.texture = Klassen.portrait(c)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(60 if game.touch else 100, 0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var l := _label(C.name, 11 if game.touch else 14, C.col if on else PARCH)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	b.add_child(h)
	b.pressed.connect(func():
		game.sfx.play("ui")
		intro_cls = c
		_render_intro())
	return b

# Stunde wählen (02-ui.js › Stundenwahl): jede schon erreichte Stunde lässt sich noch einmal betreten
func _hour_pick() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_label("STUNDE  ", 12, DIM))
	for step in [-1, 1]:
		var b := _button("  ‹  " if step < 0 else "  ›  ", false, func(): pass)
		for c in b.pressed.get_connections():
			b.pressed.disconnect(c.callable)
		var st: int = step
		b.disabled = intro_fall + st < 1 or intro_fall + st > Spiel.max_fall
		b.pressed.connect(func():
			game.sfx.play("ui")
			intro_fall = clampi(intro_fall + st, 1, Spiel.max_fall)
			_render_intro())
		if step < 0:
			row.add_child(b)
		else:
			var l := _label("%s · %s" % [Stunden.hour_txt(intro_fall), Stunden.def(intro_fall).name], 15, PARCH if intro_fall == Spiel.fall else TEAL)
			l.custom_minimum_size = Vector2(380, 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(l)
			row.add_child(b)
	return row

func show_intro(force_new := false) -> void:
	intro_fall = Spiel.fall
	intro_new = force_new or not Spiel.hat_stand
	intro_diff = Spiel.diff
	intro_hc = false
	intro_cls = Spiel.cls
	_render_intro()

func _render_intro() -> void:
	var v := _sheet(1.0, 760, true)
	v.add_child(_para("ZWÖLF STUNDEN DURCH DIE DUAT · FASSUNG 4.0.2", 13, GOLD))
	v.add_child(_para("Herz und Feder", 34 if game.touch else 46, PARCH))
	if game.touch:
		# auf dem Handy knapp, damit der Startknopf ohne Rollen zu sehen ist
		v.add_child(_para("Unten steht die Waage still. Steig mit der letzten Laterne aus Sandtor hinab, Stunde um Stunde, und finde heraus, wer sie angehalten hat.", 14, PARCH))
	else:
		_intro_story(v)
	_intro_rest(v)

func _intro_story(v: VBoxContainer) -> void:
	# in schlichten Worten: worum es geht, wer du bist, was du tun sollst (3.0)
	v.add_child(_para("Die alten Ägypter erzählten: Jede Nacht fährt die Sonne in einer Barke durch die Unterwelt, die Duat. Zwölf Stunden dauert die Fahrt. Kommt die Barke an, wird es Morgen.", 15, PARCH))
	v.add_child(_para("Seit dem Herbst kommt der Morgen später. Tief unten steht die Waage still, auf der die Herzen der Toten gegen eine Feder gewogen werden. Ohne dieses Gericht findet niemand Ruhe, und niemand zieht mehr die Barke.", 15, PARCH))
	v.add_child(_para("Du kommst aus Sandtor, der letzten Stadt vor dem Westen. Die Priester haben dir ihre letzte Laterne in die Hand gegeben. Steig hinab, Stunde um Stunde, und finde heraus, wer die Waage angehalten hat. Was du unterwegs entscheidest, macht dein eigenes Herz leichter oder schwerer. Am Ende wird auch deins gewogen.", 15, DIM))

func _intro_rest(v: VBoxContainer) -> void:
	if not intro_new:
		v.add_child(_para("Spielstand: %s%s, Stufe %d, %d von %d Seiten im Buch des Thot." % [Spiel.CLS[Spiel.cls].name, " (Hardcore)" if Spiel.hc else "", Spiel.lvl, Spiel.evid.size(), Daten.EVID.size()], 15, TEAL))
	else:
		if not game.touch:
			v.add_child(_para("WÄHLE DEINE KLASSE", 12, DIM))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		for c in Klassen.ORDER:
			row.add_child(_class_card(c))
		v.add_child(row)
		var C: Dictionary = Klassen.CLS[intro_cls]
		if game.touch:
			v.add_child(_para("%s · %s" % [C.like, C.txt], 12, DIM))
		else:
			var names := []
			for id in Klassen.order(intro_cls):
				if id != "potion":
					names.append(Klassen.SK[id].name)
			v.add_child(_para("%s · %s" % [C.like, C.txt], 14, PARCH))
			v.add_child(_para("Fähigkeiten: " + ", ".join(names), 12, DIM))
	if not intro_new and Spiel.max_fall > 1:
		v.add_child(_hour_pick())
	if not game.touch:
		v.add_child(_para("SCHWIERIGKEIT", 12, DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for i in Daten.DIFF.size():
		var b := _button("  %s  " % Daten.DIFF[i].name, i == intro_diff, func(): pass)
		var idx := i
		for c in b.pressed.get_connections():
			b.pressed.disconnect(c.callable)
		b.pressed.connect(func():
			game.sfx.play("ui")
			intro_diff = idx
			_render_intro())
		row.add_child(b)
	v.add_child(row)
	v.add_child(_para(Daten.DIFF[intro_diff].txt[0].to_upper() + Daten.DIFF[intro_diff].txt.substr(1) + "." + ("" if intro_new or intro_diff == Spiel.diff else " Die Stunde beginnt dann von vorn."), 13, DIM))
	if intro_new:
		var hc := CheckBox.new()
		hc.text = "Hardcore: Stirbt die Figur, ist sie verloren."
		hc.button_pressed = intro_hc
		hc.add_theme_font_size_override("font_size", 14)
		hc.add_theme_color_override("font_color", DIM)
		hc.toggled.connect(func(on): intro_hc = on)
		v.add_child(hc)
	if chapter_note != "":
		v.add_child(_para(chapter_note, 14, TEAL))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	var go := func(): game.start_game(intro_new, intro_diff, intro_hc, intro_cls, intro_fall)
	primary_btn = _button(_taste("  %s  [E]  " % ("Die Nacht betreten" if intro_new else "Weiterspielen")), true, go)
	btns.add_child(primary_btn)
	if not intro_new:
		var nb := _button("  Neue Figur anlegen  ", false, func(): pass)
		for c in nb.pressed.get_connections():
			nb.pressed.disconnect(c.callable)
		nb.pressed.connect(func():
			game.sfx.play("ui")
			intro_new = true
			_render_intro())
		btns.add_child(nb)
	v.add_child(btns)
	if not intro_new:
		v.add_child(_para("„Neue Figur anlegen“ löscht den Spielstand, sobald die neue Figur die Nacht betritt.", 12, Color(DIM, 0.7)))
	# Werkstatt (Fassung 2.3): Figuren aus der Figurenfabrik. Nur die Darstellung ändert sich, der Spielstand bleibt, wie er ist.
	var werk := HBoxContainer.new()
	werk.add_theme_constant_override("separation", 10)
	var sk := _button("  Schaukasten  ", false, func(): pass)
	for c in sk.pressed.get_connections():
		sk.pressed.disconnect(c.callable)
	sk.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://schau.tscn"))
	sk.custom_minimum_size = Vector2(0, 36)
	if game.touch:
		# am Handy in die Reihe des Startknopfs: so bleibt alles ohne Rollen sichtbar
		sk.custom_minimum_size = Vector2(0, 46)
		btns.add_child(sk)
	else:
		werk.add_child(sk)
		v.add_child(werk)
	primary = go
	primary_btn.grab_focus()
