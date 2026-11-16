class_name Baum extends VBoxContainer
# Fähigkeitenbaum (07-ui.js › renderTree): ein Punkt je Stufe. Ränge verstärken eine Fähigkeit (Hilfsfähigkeiten laden
# schneller), ab Rang 2 wählt man Wucht oder Eile. Dazu sechs dauerhafte Stärken, ein Schlüsselstein je Klasse
# (ab 8 verteilten Punkten) und das Zurücksetzen gegen Scherben.

var hud: Hud
var game: Node

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	render()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _knopf(text: String, main: bool, cb: Callable, enabled := true, pressed := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_theme_font_size_override("font_size", 14)
	b.custom_minimum_size = Vector2(40, 38)
	var edge := Hud.GOLD if (main or pressed) else Color("3d3947")
	b.add_theme_stylebox_override("normal", hud._flat(Color(Hud.GOLD, 0.16) if pressed else Color(0, 0, 0, 0), 8, edge, 1))
	b.add_theme_stylebox_override("hover", hud._flat(Color(1, 1, 1, 0.06), 8, Hud.GOLD, 1))
	b.add_theme_stylebox_override("pressed", hud._flat(Color(1, 1, 1, 0.1), 8, Hud.GOLD, 1))
	b.add_theme_stylebox_override("disabled", hud._flat(Color(0, 0, 0, 0), 8, Color("2a2731"), 1))
	b.add_theme_color_override("font_color", Hud.GOLD if (main or pressed) else Hud.PARCH)
	b.add_theme_color_override("font_disabled_color", Color(Hud.DIM, 0.45))
	b.disabled = not enabled
	b.pressed.connect(func():
		game.sfx.play("ui")
		cb.call()
		game.hero.apply_stats()
		render())
	return b

func _card(on: bool) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(270, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", hud._flat(Color("211f27"), 8, Hud.GOLD if on else Color("3d3947"), 1))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	return [p, v]

func _pips(n: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	for i in Klassen.SK_RANKS:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(14, 6)
		r.color = Hud.GOLD if i < n else Color("3d3947")
		h.add_child(r)
	return h

func _grid() -> HFlowContainer:
	var g := HFlowContainer.new()
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	return g

func render() -> void:
	_clear()
	var h: Hero = game.hero
	var pts := Spiel.tree_points()
	var top := HBoxContainer.new()
	var t := hud._label("Fähigkeitenbaum", 26, Hud.PARCH)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var close := Button.new()
	close.text = hud._taste("  Schließen  [K]  ").strip_edges()
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 15)
	close.add_theme_stylebox_override("normal", hud._flat(Color(0, 0, 0, 0), 8, Color("3d3947"), 1))
	close.pressed.connect(func(): game.toggle_tree())
	top.add_child(close)
	add_child(top)
	add_child(hud._para("%s · Stufe %d · %s" % [Spiel.CLS[Spiel.cls].name, Spiel.lvl, ("%d freie Punkte" % pts) if pts != 1 else "1 freier Punkt"], 15, Hud.GOLD if pts > 0 else Hud.DIM))
	# Fähigkeiten
	var g := _grid()
	for id in h.ORDER:
		if id == "potion":
			continue
		var S: Dictionary = h.SK[id]
		var rk := Spiel.rank(id)
		var c := _card(rk > 0)
		var v: VBoxContainer = c[1]
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		var ic := TextureRect.new()
		ic.texture = Klassen.icon(id, 80)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.custom_minimum_size = Vector2(40, 40)
		head.add_child(ic)
		var hv := VBoxContainer.new()
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.add_theme_constant_override("separation", 2)
		hv.add_child(hud._label(S.name, 16, Hud.PARCH))
		hv.add_child(hud._label("Taste %s · Rang %d von %d" % [Klassen.keys()[h.ORDER.find(id)], rk, Klassen.SK_RANKS], 11, Hud.DIM))
		hv.add_child(_pips(rk))
		head.add_child(hv)
		var sid: String = id
		head.add_child(_knopf("+", true, func(): Spiel.tree_rank_up(sid), pts > 0 and rk < Klassen.SK_RANKS))
		v.add_child(head)
		v.add_child(hud._para(S.txt, 12, Hud.DIM))
		var eff := ""
		if S.util:
			eff = "Abklingzeit −6 %% je Rang · jetzt %.1f s" % h.cd_of(id)
		else:
			eff = "Stärke +12 %% je Rang · jetzt ×%.2f" % Spiel.sk_pow(id)
		v.add_child(hud._label(eff, 12, Hud.TEAL))
		if rk >= 2:
			var ar := HBoxContainer.new()
			ar.add_theme_constant_override("separation", 6)
			for a in ["wucht", "eile"]:
				var aa: String = a
				var cur := Spiel.aug(id)
				var b := _knopf("%s: %s" % [Klassen.AUGS[a].name, Klassen.AUGS[a].txt], false, func(): Spiel.tree_aug(sid, aa), cur != "" or pts > 0, cur == a)
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.add_theme_font_size_override("font_size", 11)
				ar.add_child(b)
			v.add_child(ar)
		else:
			v.add_child(hud._label("Ab Rang 2: Wucht oder Eile wählen.", 11, Color(Hud.DIM, 0.6)))
		g.add_child(c[0])
	add_child(g)
	# Dauerhafte Stärken
	add_child(hud._label("DAUERHAFTE STÄRKEN", 12, Hud.DIM))
	var pg := _grid()
	for pd in Klassen.PASSIVES:
		var rk := Spiel.pas(pd.id)
		var c := _card(rk > 0)
		var v: VBoxContainer = c[1]
		var head := HBoxContainer.new()
		var hv := VBoxContainer.new()
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.add_child(hud._label(pd.name, 15, Hud.PARCH))
		hv.add_child(_pips(rk))
		head.add_child(hv)
		var pid: String = pd.id
		head.add_child(_knopf("+", true, func(): Spiel.tree_passive(pid), pts > 0 and rk < Klassen.SK_RANKS))
		v.add_child(head)
		v.add_child(hud._para(pd.txt, 12, Hud.DIM))
		pg.add_child(c[0])
	add_child(pg)
	# Schlüsselstein
	var K: Dictionary = Klassen.KEYSTONE[Spiel.cls]
	var kc := _card(Spiel.has_key())
	var kv: VBoxContainer = kc[1]
	var kh := HBoxContainer.new()
	var kl := hud._label("Schlüsselstein: " + K.name, 16, Hud.GOLD if Spiel.has_key() else Hud.PARCH)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kh.add_child(kl)
	if Spiel.has_key():
		kh.add_child(hud._label("freigeschaltet", 12, Color("7ad08a")))
	else:
		kh.add_child(_knopf("Freischalten", true, func(): Spiel.tree_key(), pts > 0 and Spiel.tree_spent() >= Klassen.KEY_NEED))
	kv.add_child(kh)
	kv.add_child(hud._para(K.txt, 12, Hud.DIM))
	if not Spiel.has_key():
		kv.add_child(hud._label("Braucht %d verteilte Punkte (jetzt %d)." % [Klassen.KEY_NEED, Spiel.tree_spent()], 11, Color(Hud.DIM, 0.7)))
	add_child(kc[0])
	# Zurücksetzen
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 10)
	rr.add_child(_knopf("Alles zurücksetzen: %d Scherben" % Spiel.respec_cost(), false, func(): Spiel.respec(), Spiel.tree_spent() > 0 and Spiel.shards >= Spiel.respec_cost()))
	rr.add_child(hud._label("Scherben: %d" % Spiel.shards, 13, Hud.DIM))
	add_child(rr)
	hud._pass_all(self)
