class_name Hud extends CanvasLayer
# Anzeige: Stunde und Fortschritt oben links, Leben, Eidkraft und Fähigkeiten unten,
# dazu Tafel (Kapitel), Pfortenfenster und das Fenster nach einer Niederlage.

const PARCH := Color("ece3cb")
const DIM := Color("a39c8e")
const GOLD := Color("e8b04a")
const TEAL := Color("8fe3e0")
const PANEL := Color(0.09, 0.086, 0.11, 0.94)

var game: Node
var root: Control
var l_track: Label
var bar_track: ProgressBar
var bar_hp: ProgressBar
var bar_en: ProgressBar
var l_hp: Label
var l_en: Label
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
var bag_open := false
var tree_open := false
var chapter_note := ""     # Zusatzzeile auf der Tafel (z. B. Hinweis für das iPhone)
var toasts: VBoxContainer   # Fundmeldungen links oben (07-ui.js › toast)
var bar_xp: ProgressBar
var l_lvl: Label
var tasche_btn: Button
var tree_btn: Button
var l_quer: Label          # Hinweis, das Handy quer zu halten
var tap_frame := -1        # Bild, in dem zuletzt ein Fähigkeitenknopf ausgelöst wurde (Finger meldet sich doppelt)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# oben links: Stunde, Name, Fortschritt
	var tl := VBoxContainer.new()
	tl.position = Vector2(18, 14)
	tl.custom_minimum_size = Vector2(330, 0)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tl)
	tl.add_child(_label(game.TXT.no, 13, GOLD))
	tl.add_child(_label(game.TXT.name, 24, PARCH))
	bar_track = _bar(TEAL, 6)
	tl.add_child(bar_track)
	l_track = _label("", 13, DIM)
	l_track.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.add_child(l_track)
	var hint := _label("Finger halten: laufen · Gegner antippen: angreifen · Fähigkeiten unten antippen" if game.touch else "W A S D oder linke Maustaste: laufen · auf Gegner klicken: angreifen\nF Bildrate · G Grafik · M Ton · I Tasche · K Fähigkeiten · V Vollbild", 12, Color(DIM, 0.7))
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
		var knoepfe := [["Tasche", func(): game.toggle_bag()], ["Fähigk.", func(): game.toggle_tree()], ["Grafik", func(): game.set_low(not game.low_gfx)], ["Ton", func(): game.sfx.set_muted(not game.sfx.muted)], ["Bildrate", func(): toggle_fps()]]
		if game.can_fullscreen:
			knoepfe.insert(0, ["Vollbild", func(): game.toggle_fullscreen()])
		for t in knoepfe:
			var b := Button.new()
			b.text = t[0]
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 13)
			b.custom_minimum_size = Vector2(86, 40)
			b.add_theme_stylebox_override("normal", _flat(PANEL, 8, Color("3d3947"), 1))
			b.add_theme_stylebox_override("hover", _flat(PANEL, 8, Color("3d3947"), 1))
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
	l_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_banner.add_theme_constant_override("outline_size", 6)
	l_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner_box.add_child(l_banner)
	toasts = VBoxContainer.new()
	toasts.position = Vector2(18, 112)
	toasts.custom_minimum_size = Vector2(330, 0)
	toasts.add_theme_constant_override("separation", 6)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toasts)
	# Erfahrung: dünne Leiste unter der Fähigkeitenleiste, daneben die Stufe
	bar_xp = _bar(GOLD, 5)
	bar_xp.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar_xp.position = Vector2(-300, -11)
	bar_xp.custom_minimum_size = Vector2(600, 5)
	bar_xp.size = Vector2(600, 5)
	root.add_child(bar_xp)
	l_lvl = _label("", 11, DIM)
	l_lvl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l_lvl.position = Vector2(310, -16)
	root.add_child(l_lvl)
	l_toast = _label("", 14, PARCH)
	l_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l_toast.position = Vector2(-300, -170)
	l_toast.custom_minimum_size = Vector2(600, 0)
	l_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_toast.modulate.a = 0.0
	root.add_child(l_toast)
	# unten: Leben, Fähigkeiten, Eidkraft
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.position = Vector2(-470, -104)
	bottom.custom_minimum_size = Vector2(940, 88)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	var hpb := _stat_box("Leben", Color("c8443a"))
	bar_hp = hpb[1]
	l_hp = hpb[2]
	bottom.add_child(hpb[0])
	for id in game.hero.ORDER:
		bottom.add_child(_skill_box(id))
	var enb := _stat_box(Spiel.CLS[Spiel.cls].res, Spiel.CLS[Spiel.cls].rc)
	bar_en = enb[1]
	l_en = enb[2]
	bottom.add_child(enb[0])

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _flat(col: Color, radius := 6, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	return s

func _bar(col: Color, h: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.001
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_stylebox_override("background", _flat(Color(0.03, 0.03, 0.05, 0.85), 4, Color("3d3947"), 1))
	b.add_theme_stylebox_override("fill", _flat(col, 4))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _stat_box(title: String, col: Color) -> Array:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(150, 0)
	v.alignment = BoxContainer.ALIGNMENT_END
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := _label(title, 12, DIM)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var val := _label("", 16, PARCH)
	top.add_child(val)
	v.add_child(top)
	var b := _bar(col, 18)
	v.add_child(b)
	return [v, b, val]

func _skill_box(id: String) -> Control:
	var S: Dictionary = game.hero.SK[id]
	var slot: int = game.hero.ORDER.find(id)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(98, 84)
	p.add_theme_stylebox_override("panel", _flat(PANEL, 8, Color("3d3947"), 1))
	p.tooltip_text = "%s: %s" % [S.name, S.txt]
	p.gui_input.connect(func(ev):
		# Maus oder Finger. Ein zweiter Finger kommt nur als Berührung an (der erste hält die Figur in Bewegung),
		# der erste Finger meldet sich als beides: darum je Bild nur einmal auslösen.
		var tap: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)
		if tap and not get_tree().paused and tap_frame != Engine.get_process_frames():
			tap_frame = Engine.get_process_frames()
			# der Zeiger liegt auf dem Knopf, nicht auf einem Ziel: auf den nächsten Gegner zielen, sonst nach vorn
			var near: Foe = game.foe_near(game.hero.global_position, 20.8)
			game.hero.aim = near.global_position if near else game.hero.global_position + game.hero.forward() * 8.8
			game.hero.auto_aim = true
			game.hero.cast(id))
	var cdr := ColorRect.new()
	cdr.color = Color(0, 0, 0, 0.62)
	cdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cdr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cdr.scale.y = 0.0
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	var ic := TextureRect.new()
	ic.texture = Klassen.icon(id, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(26, 26)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ic)
	var k := _label(Klassen.keys()[slot], 16, GOLD)
	top.add_child(k)
	v.add_child(top)
	var n := _label(S.name, 11, PARCH)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(86, 0)
	v.add_child(n)
	var c := _label(("%d %s" % [S.cost, Spiel.CLS[Spiel.cls].res]) if S.cost > 0 else "", 10, DIM)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(c)
	p.add_child(v)
	p.add_child(cdr)
	skill_ui[id] = {"panel": p, "cd": cdr, "sub": c, "key": k}
	return p

func _process(_d: float) -> void:
	if l_quer:
		var vs := get_viewport().get_visible_rect().size
		l_quer.visible = vs.y > vs.x

func mouse_over_ui() -> bool:
	return overlay != null or get_viewport().gui_get_hovered_control() != null

func refresh() -> void:
	var h: Hero = game.hero
	bar_hp.value = h.hp / h.max_hp
	l_hp.text = str(int(ceil(h.hp)))
	bar_en.value = h.en / 100.0
	l_en.text = str(int(h.en))
	bar_xp.value = Spiel.xp / Daten.xp_need(Spiel.lvl)
	l_lvl.text = "Stufe %d" % Spiel.lvl
	if tasche_btn:
		tasche_btn.add_theme_color_override("font_color", GOLD if Spiel.neu > 0 else PARCH)
	if tree_btn:
		tree_btn.add_theme_color_override("font_color", GOLD if Spiel.tree_points() > 0 else PARCH)
	for id in h.ORDER:
		var S: Dictionary = h.SK[id]
		var u: Dictionary = skill_ui[id]
		u.cd.scale.y = clampf(h.cd[id] / h.cd_of(id), 0.0, 1.0)
		if id != "potion" and S.cost > 0:
			u.sub.text = "%d %s" % [h.cost_of(id), Spiel.CLS[Spiel.cls].res]
		var poor: bool = (h.pots <= 0) if id == "potion" else h.en < h.cost_of(id)
		u.panel.modulate = Color(1, 1, 1, 0.45) if poor else Color.WHITE
		if id == "potion":
			u.sub.text = "noch %d" % h.pots
	var p: float = float(game.kills) / maxf(1.0, game.total)
	bar_track.value = p
	if game.gate:
		l_track.text = "Die Pforte steht offen. Tritt hinein, wenn du so weit bist."
	elif game.boss_awake:
		l_track.text = "%s ist hier." % game.boss.K.name
	elif p >= 0.6:
		l_track.text = "Der Hüter der Stunde wartet: %s." % game.boss.K.name
	else:
		l_track.text = "Isfet zurückgedrängt: %d %%" % int(p * 100.0)
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
	p.add_theme_stylebox_override("panel", _flat(Color(0.067, 0.063, 0.086, 0.92), 8, Color("3d3947"), 1))
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

func toast(text: String) -> void:
	l_toast.text = text
	if toast_tw:
		toast_tw.kill()
	toast_tw = create_tween()
	toast_tw.tween_property(l_toast, "modulate:a", 1.0, 0.2)
	toast_tw.tween_interval(2.2)
	toast_tw.tween_property(l_toast, "modulate:a", 0.0, 0.6)

# ---------------------------------------------------------------- Fenster
func _close() -> void:
	bag_open = false
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
		b.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0), 8, Color("3d3947"), 1))
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

func _sheet(dim: float, width: float) -> VBoxContainer:
	_close()
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.04, dim)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
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
	panel.add_theme_stylebox_override("panel", _flat(PANEL if dim < 0.99 else Color(0, 0, 0, 0), 10, Color("3d3947"), 1 if dim < 0.99 else 0))
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
func show_chapter(no: String, name: String, lead: String, brief: String, btn: String, cb: Callable) -> void:
	var v := _sheet(1.0, 720)
	v.add_child(_para(no, 14, GOLD, true))
	v.add_child(_para(name, 46, PARCH, true))
	v.add_child(_para(lead, 20, PARCH, true))
	v.add_child(_para(brief, 16, DIM, true))
	if chapter_note != "":
		v.add_child(_para(chapter_note, 14, TEAL, true))
	var row := CenterContainer.new()
	primary_btn = _button(_taste("  %s  [E]  " % btn), true, cb)
	primary_btn.disabled = true
	row.add_child(primary_btn)
	v.add_child(row)
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
		p.add_theme_stylebox_override("panel", _flat(Color("211f27"), 8, Color("3d3947"), 1))
		var pv := VBoxContainer.new()
		pv.add_child(_label("  " + s[0], 20, PARCH))
		pv.add_child(_label("  " + s[1].to_upper(), 11, DIM))
		p.add_child(pv)
		row.add_child(p)
	v.add_child(row)
	v.add_child(_para(next_no, 12, TEAL))
	v.add_child(_para(next_name, 20, PARCH))
	v.add_child(_para(next_lead, 14, DIM))
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

func show_bag() -> void:
	var v := _sheet(0.86, 880)
	bag_open = true
	var t := Tasche.new()
	t.hud = self
	t.game = game
	v.add_child(t)
	var cb := func(): get_tree().paused = false
	secondary = cb

func show_tree() -> void:
	var v := _sheet(0.86, 900)
	tree_open = true
	var t := Baum.new()
	t.hud = self
	t.game = game
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

func _input(ev: InputEvent) -> void:
	if tree_open and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_K:
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		close_bag()
		return
	if bag_open and ev is InputEventKey and ev.pressed and not ev.echo and (ev.keycode == KEY_I or ev.keycode == KEY_TAB):
		get_viewport().set_input_as_handled()
		game.sfx.play("ui")
		close_bag()
		return
	if overlay == null or not (ev is InputEventKey) or not ev.pressed or ev.echo:
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
		p.add_theme_stylebox_override("panel", _flat(Color("211f27"), 8, Color("3d3947"), 1))
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
	b.custom_minimum_size = Vector2(0, 92 if game.touch else 150)
	b.add_theme_stylebox_override("normal", _flat(Color("211f27"), 8, C.col if on else Color("3d3947"), 3 if on else 1))
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
	tr.custom_minimum_size = Vector2(34 if game.touch else 56, 0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var l := _label(C.name, 13 if game.touch else 15, C.col if on else PARCH)
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

func show_intro(force_new := false) -> void:
	intro_new = force_new or not Spiel.hat_stand
	intro_diff = Spiel.diff
	intro_hc = false
	intro_cls = Spiel.cls
	_render_intro()

func _render_intro() -> void:
	var v := _sheet(1.0, 760)
	v.add_child(_para("ZWÖLF STUNDEN DURCH DIE DUAT", 13, GOLD))
	v.add_child(_para("Herz und Feder", 34 if game.touch else 46, PARCH))
	if game.touch:
		# auf dem Handy knapp, damit der Startknopf ohne Rollen zu sehen ist
		v.add_child(_para("Unten steht die Waage still. Steig mit der letzten Laterne aus Sandtor hinab, Stunde um Stunde, und finde heraus, wer sie angehalten hat.", 14, PARCH))
	else:
		_intro_story(v)
	_intro_rest(v)

func _intro_story(v: VBoxContainer) -> void:
	v.add_child(_para("Die Nebelmark ist das letzte Land vor dem Westen. Ihr Nebel steigt aus der Duat, der Unterwelt, durch die Re jede Nacht in seiner Barke fährt. Seit dem Herbst kommt der Morgen später. Unten steht die Waage still: Kein Herz wird mehr gegen die Feder der Maat gewogen.", 15, PARCH))
	v.add_child(_para("Die Priester im Sonnentempel von Sandtor haben dir ihre letzte Laterne gegeben. Steig hinab, Stunde um Stunde, und finde heraus, wer die Waage angehalten hat. Unterwegs liegen die verstreuten Seiten aus dem Buch des Thot.", 15, DIM))

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
	var go := func(): game.start_game(intro_new, intro_diff, intro_hc, intro_cls)
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
	primary = go
	primary_btn.grab_focus()
