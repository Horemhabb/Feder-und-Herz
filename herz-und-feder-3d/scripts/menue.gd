class_name Menue extends VBoxContainer
# Spielmenü (3.0): Esc hält das Spiel an. Von hier aus: weiterspielen, Lexikon, Steuerung, Einstellungen,
# eine erreichte Stunde noch einmal betreten, zum Titel zurück oder eine neue Figur anlegen.

var hud: Hud
var game: Node
var seite := ""          # "", "lexikon", "steuerung", "einstellungen", "stunden", "figur"

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	render()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _knopf(text: String, main: bool, cb: Callable, enabled := true, breit := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(breit, 48)
	Zier.knopf_stil(b, "haupt" if main else "zweit", 17)
	b.disabled = not enabled
	b.pressed.connect(func():
		game.sfx.play("ui")
		cb.call())
	return b

func geh(s: String) -> void:
	seite = s
	render()

# Esc: von einer Unterseite zurück ins Menü, vom Menü zurück ins Spiel. Rückgabe: ob das Menü offen bleibt
func zurueck() -> bool:
	if seite == "":
		return false
	geh("")
	return true

func _kopf(titel: String) -> void:
	hud.fenster_kopf(self, titel, hud._taste("  Zurück  [Esc]  ") if seite != "" else "", func(): geh(""))

# Zwischenüberschrift: Rubrik in Gold, daneben eine feine Zierleiste
func _abschnitt(t: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := hud._label(t.to_upper(), 12, Hud.GOLD)
	h.add_child(l)
	var zl := Zier.leiste(0.0, "", 12.0)
	zl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(zl)
	add_child(h)

func render() -> void:
	_clear()
	match seite:
		"lexikon": _lexikon()
		"steuerung": _steuerung()
		"einstellungen": _einstellungen()
		"stunden": _stunden()
		"figur": _figur()
		_: _haupt()
	hud._pass_all(self)

func _haupt() -> void:
	add_child(hud._para("PAUSE", 13, Hud.GOLD, true))
	var zug := TextureRect.new()
	zug.texture = Zier.tex("schriftzug")
	zug.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zug.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zug.custom_minimum_size = Vector2(0, 58)
	add_child(zug)
	add_child(hud._para("%s · %s · Stufe %d" % [Stunden.hour_txt(Spiel.fall), Spiel.CLS[Spiel.cls].name, Spiel.lvl], 14, Hud.DIM, true))
	add_child(Zier.leiste(0.0, "lotos", 16.0))
	var mitte := CenterContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	mitte.add_child(v)
	v.add_child(_knopf(hud._taste("Weiterspielen  [Esc]"), true, func(): game.toggle_menu(), true, 360))
	v.add_child(_knopf("Lexikon: Götter und Begriffe", false, func(): geh("lexikon"), true, 360))
	v.add_child(_knopf("Steuerung", false, func(): geh("steuerung"), true, 360))
	v.add_child(_knopf("Einstellungen", false, func(): geh("einstellungen"), true, 360))
	if Spiel.max_fall > 1:
		v.add_child(_knopf("Stunde wechseln", false, func(): geh("stunden"), true, 360))
	v.add_child(_knopf("Zum Titel", false, func(): game.zum_titel(), true, 360))
	v.add_child(_knopf("Neue Figur anlegen", false, func(): geh("figur"), true, 360))
	add_child(mitte)
	add_child(Zier.leiste(0.0, "raute", 12.0))
	add_child(hud._para("Dein Fortschritt wird laufend gespeichert.", 12, Hud.DIM, true))
	add_child(hud._para(Spiel.fassung_txt(), 11, Hud.DIM, true))

func _lexikon() -> void:
	_kopf("Lexikon")
	add_child(hud._para("Was du schon gehört hast, steht in dunkler Tinte. Der Rest ist zum Nachschlagen da.", 13, Hud.DIM))
	# das Lexikon ist ein Schriftstück: ein Blatt Papyrus in der dunklen Tafel
	var blatt := PanelContainer.new()
	blatt.add_theme_stylebox_override("panel", Zier.stil("papyrus", 26.0))
	hud.papier.append(blatt)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 10)
	blatt.add_child(bv)
	add_child(blatt)
	for g in Lexikon.gruppen():
		var kopf := hud._para(g.to_upper(), 13, Hud.GOLD, true)
		bv.add_child(kopf)
		bv.add_child(Zier.leiste(0.0, "lotos", 14.0))
		for e in Lexikon.W:
			if e.gruppe != g:
				continue
			var kennt := Lexikon.kennt(e.id)
			var z := VBoxContainer.new()
			z.add_theme_constant_override("separation", 0)
			z.add_child(hud._label(e.name, 18, Hud.PARCH if kennt else Hud.DIM))
			z.add_child(hud._para(e.txt, 14, Hud.PARCH if kennt else Hud.DIM))
			bv.add_child(z)

func _zeile(a: String, b: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := hud._label(a, 15, Zier.GOLD_HELL)
	l.custom_minimum_size = Vector2(230, 0)
	h.add_child(l)
	var r := hud._para(b, 15, Hud.PARCH)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(r)
	add_child(h)

func _steuerung() -> void:
	_kopf("Steuerung")
	if game.touch:
		_zeile("Finger halten", "Die Figur läuft dorthin.")
		_zeile("Gegner antippen", "Angreifen.")
		_zeile("Symbole unten", "Fähigkeiten und Rotbier. Nur gelernte Fähigkeiten wirken.")
		_zeile("Menü, Tasche, Fähigk.", "Knöpfe oben rechts.")
		_zeile("Figur am Eingang", "Antippen, um noch einmal mit ihr zu sprechen.")
	else:
		_zeile("W A S D", "Laufen. Die linke Maustaste gedrückt halten geht auch.")
		_zeile("Linke Maustaste", "Auf einen Gegner klicken: angreifen.")
		_zeile("Rechte Maustaste", "Fähigkeit der rechten Hand.")
		_zeile("1  2  3  4", "Fähigkeiten. Sie wirken erst, wenn du sie im Fähigkeitenbaum gelernt hast.")
		_zeile("Q", "Rotbier der Sachmet trinken (heilt).")
		_zeile("Leertaste", "Ausweichschritt, kurz unverwundbar.")
		_zeile("E", "Sprechen, Werkstatt betreten, in Fenstern bestätigen.")
		_zeile("K", "Fähigkeitenbaum.")
		_zeile("I oder Tab", "Tasche und Ausrüstung.")
		_zeile("Esc", "Dieses Menü. Das Spiel steht, solange es offen ist.")
		_zeile("M  G  V  F", "Ton, Grafik, Vollbild, Bildrate anzeigen.")

func _schalter(name: String, wert: String, cb: Callable) -> void:
	var h := HBoxContainer.new()
	var l := hud._label(name, 16, Hud.PARCH)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_knopf(wert, false, func():
		cb.call()
		render(), true, 190))
	add_child(h)

func _regler(name: String, key: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := hud._label(name, 16, Hud.PARCH)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var wert := hud._label("%d %%" % round(float(Spiel.einst[key]) * 100.0), 14, Hud.DIM)
	wert.custom_minimum_size = Vector2(56, 0)
	wert.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Spiel.einst[key])
	s.custom_minimum_size = Vector2(240, 30)
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float):
		Spiel.einst[key] = v
		wert.text = "%d %%" % round(v * 100.0)
		game.sfx.einst_anwenden())
	s.drag_ended.connect(func(_c): Spiel.einst_speichern())
	h.add_child(s)
	h.add_child(wert)
	add_child(h)

func _einstellungen() -> void:
	_kopf("Einstellungen")
	_abschnitt("Ton")
	_schalter("Ton", "Aus" if game.sfx.muted else "An", func(): game.sfx.set_muted(not game.sfx.muted))
	_regler("Lautstärke gesamt", "laut")
	_regler("Musik", "musik")
	_abschnitt("Bild")
	_schalter("Grafik", game.GUETE_NAME[game.guete], func(): game.guete_von_hand((game.guete + 1) % 4))
	if not game.touch:
		_schalter("Leiste unten", "%d %%" % round(float(Spiel.einst.get("leiste", 0.75)) * 100.0), func():
			var stufen := [0.6, 0.75, 0.9, 1.0]
			var i := 0
			for k in stufen.size():
				if absf(stufen[k] - float(Spiel.einst.get("leiste", 0.75))) < 0.03:
					i = k
			Spiel.einst["leiste"] = stufen[(i + 1) % stufen.size()]
			Spiel.einst_speichern()
			hud.leiste_skalieren())
	if game.can_fullscreen or not OS.has_feature("web"):
		_schalter("Vollbild", "An" if game.is_fullscreen() else "Aus", func(): game.toggle_fullscreen())
	_schalter("Bildrate anzeigen", "An" if hud.l_fps.visible else "Aus", func(): hud.toggle_fps())
	add_child(hud._para("Vier Stufen: „Niedrig“ schaltet Schatten, Glühen und Dunst ab und rechnet das Bild kleiner; „Sparsam“ und „Minimal“ rechnen noch kleiner und mit weniger Lichtern. Ruckelt es, stellt das Spiel die Stufe von selbst herunter.", 13, Hud.DIM))
	# Protokoll (4.0.1): was beim Spielen passiert, zum Nachlesen bei Fehlern und Ruckeln
	_abschnitt("Protokoll")
	_schalter("Protokoll", "Herunterladen" if OS.has_feature("web") else "Ordner öffnen", func(): hud.toast(Protokoll.ausgeben(), 6.0))
	add_child(hud._para("Das Spiel schreibt Bildrate, Ruckler, Rechenzeit, Fehler und eine Bau-Prüfung jeder Stunde mit (Taste F9 geht auch). Die Datei kannst du weitergeben, wenn etwas nicht stimmt.", 13, Hud.DIM))
	# Schwierigkeit nachträglich wechseln (4.0, G2): gilt ab der nächsten Stunde oder wenn man eine Stunde neu betritt
	_abschnitt("Schwierigkeit")
	var hf := HFlowContainer.new()
	hf.add_theme_constant_override("h_separation", 6)
	for i in Daten.DIFF.size():
		var ii: int = i
		hf.add_child(_knopf(Daten.DIFF[i].name, i == Spiel.diff, func():
			Spiel.diff = ii
			Spiel.calc()
			Spiel.speichern()
			hud.toast("Schwierigkeit: %s. Das Verhalten der Gegner gilt sofort, Leben und Schaden ab der nächsten Stunde." % Daten.DIFF[ii].name, 4.0)
			geh("einstellungen"), i != Spiel.diff))
	add_child(hf)
	add_child(hud._para("%s: %s. Ein Wechsel wirkt sofort auf das Verhalten (wie viele zugleich angreifen, ob Rudel einander rufen, wie weit Gegner sehen, wie oft Legendäres fällt); Leben und Schaden der Gegner ändern sich ab der nächsten Stunde oder wenn du eine Stunde neu betrittst." % [Daten.DIFF[Spiel.diff].name, Daten.DIFF[Spiel.diff].txt], 13, Hud.DIM))

func _stunden() -> void:
	_kopf("Stunde wechseln")
	add_child(hud._para("Jede erreichte Stunde lässt sich noch einmal betreten. Sie beginnt dann von vorn; Stufe und Ausrüstung behältst du.", 14, Hud.DIM))
	var hf := HFlowContainer.new()
	hf.add_theme_constant_override("h_separation", 6)
	hf.add_theme_constant_override("v_separation", 6)
	for n in range(maxi(1, Spiel.max_fall - 11), Spiel.max_fall + 1):
		var nn: int = n
		hf.add_child(_knopf("%d · %s" % [Stunden.hour_of(n), Stunden.def(n).name] if Stunden.night_of(n) == 1 else Stunden.hour_txt(n),
			n == Spiel.fall, func(): game.go_hour(nn), n != Spiel.fall))
	add_child(hf)

func _figur() -> void:
	_kopf("Neue Figur anlegen")
	add_child(hud._para("Der jetzige Spielstand (%s, Stufe %d) wird dabei gelöscht. Das lässt sich nicht rückgängig machen." % [Spiel.CLS[Spiel.cls].name, Spiel.lvl], 15, Hud.PARCH))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(_knopf("Ja, neue Figur anlegen", false, func(): game.new_character()))
	h.add_child(_knopf("Abbrechen", true, func(): geh("")))
	add_child(h)
