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
var chapter_note := ""     # Zusatzzeile auf der Tafel (z. B. Hinweis für das iPhone)
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
	var hint := _label("Finger halten: laufen · Gegner antippen: angreifen · Fähigkeiten unten antippen" if game.touch else "W A S D oder linke Maustaste: laufen · auf Gegner klicken: angreifen\nF Bildrate · G Grafik · M Ton · I Beutel · V Vollbild", 12, Color(DIM, 0.7))
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.position = Vector2(-560, 14)
	hint.custom_minimum_size = Vector2(540, 0)
	root.add_child(hint)
	if game.touch:
		# ohne Tastatur: Grafik, Ton und Bildrate als Knöpfe
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		row.position = Vector2(-470, 38)
		row.custom_minimum_size = Vector2(450, 0)
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 6)
		var knoepfe := [["Beutel", func(): game.toggle_bag()], ["Grafik", func(): game.set_low(not game.low_gfx)], ["Ton", func(): game.sfx.set_muted(not game.sfx.muted)], ["Bildrate", func(): toggle_fps()]]
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
	for id in Hero.ORDER:
		bottom.add_child(_skill_box(id))
	var enb := _stat_box("Eidkraft", Color("3f7fd6"))
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
	var S: Dictionary = Hero.SKILLS[id]
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
			var near: Foe = game.foe_near(game.hero.global_position, 12.0)
			game.hero.aim = near.global_position if near else game.hero.global_position + game.hero.forward() * 6.0
			game.hero.cast(id))
	var cdr := ColorRect.new()
	cdr.color = Color(0, 0, 0, 0.62)
	cdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cdr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cdr.scale.y = 0.0
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var k := _label(S.key, 18, GOLD)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	var n := _label(S.name, 11, PARCH)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(86, 0)
	v.add_child(n)
	var c := _label(("%d Eidkraft" % S.cost) if S.cost > 0 else "", 10, DIM)
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
	for id in Hero.ORDER:
		var S: Dictionary = Hero.SKILLS[id]
		var u: Dictionary = skill_ui[id]
		u.cd.scale.y = clampf(h.cd[id] / S.cd, 0.0, 1.0)
		var poor: bool = (h.pots <= 0) if id == "potion" else h.en < S.cost
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
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.add_theme_stylebox_override("panel", _flat(PANEL if dim < 0.99 else Color(0, 0, 0, 0), 10, Color("3d3947"), 1 if dim < 0.99 else 0))
	center.add_child(panel)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	return v

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
	var h: Hero = game.hero
	var v := _sheet(0.8, 520)
	bag_open = true
	v.add_child(_para("BEUTEL", 13, GOLD))
	v.add_child(_para("Was du bei dir trägst", 26, PARCH))
	var rows := [
		["Rotbier der Sachmet", "%d von 4" % h.pots, "Q: heilt dich. Besiegte lassen manchmal eines fallen."],
		["Münzen", str(game.gold), "Aus dem Beutel der Besiegten. Noch ohne Verwendung: Händler folgen später."],
		["Besiegte Ruhelose", "%d von %d" % [game.kills, game.total], ""],
		["Leben", "%d von %d" % [int(ceil(h.hp)), int(h.max_hp)], ""],
	]
	for r in rows:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat(Color("211f27"), 8, Color("3d3947"), 1))
		var pv := VBoxContainer.new()
		var top := HBoxContainer.new()
		var n := _label("  " + r[0], 17, PARCH)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(n)
		top.add_child(_label(r[1] + "  ", 17, GOLD))
		pv.add_child(top)
		if r[2] != "":
			pv.add_child(_para("  " + r[2], 12, DIM))
		p.add_child(pv)
		v.add_child(p)
	var cb := func(): get_tree().paused = false
	var btns := HBoxContainer.new()
	primary_btn = _button(_taste("  Schließen  [I]  "), true, cb)
	btns.add_child(primary_btn)
	v.add_child(btns)
	primary = cb
	secondary = cb
	primary_btn.grab_focus()

func close_bag() -> void:
	_close()
	get_tree().paused = false

func show_dead(text: String, cb: Callable) -> void:
	var v := _sheet(0.8, 560)
	v.add_child(_para("IN DER DUAT", 13, GOLD))
	v.add_child(_para("Du wurdest überwältigt.", 28, PARCH))
	v.add_child(_para(text + " Deine Kraft kehrt zurück.", 16, PARCH))
	var btns := HBoxContainer.new()
	primary_btn = _button(_taste("  Zurück in die Stunde  [E]  "), true, cb)
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
