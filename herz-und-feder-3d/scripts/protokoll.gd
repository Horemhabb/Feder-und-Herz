extends Node
# Protokoll (4.0.1): schreibt beim Spielen mit, was später beim Suchen von Fehlern hilft.
#   user://protokoll/protokoll_<Datum>.txt   eine Datei je Spielsitzung, die letzten acht bleiben liegen
# Inhalt:
#   - Rechner, Grafik, Fenstergröße, Fassung; jede betretene Stunde mit Bauzeit und Bau-Prüfung
#   - alle fünf Sekunden: Bildrate, schlechtestes Bild, Ruckler (Bilder über 50 ms), Zeichenaufrufe, Dreiecke,
#     Zahl der Gegner, Rechenzeit je Teilsystem (Gegner, Leben, Orte, Klang, Karte …) in Millisekunden je Bild
#   - jeder einzelne grobe Ruckler (über 120 ms) mit Zeitpunkt und Ort der Figur
#   - alle Fehler und Warnungen der Engine und der Skripte (über einen eigenen Logger)
# Lesen: auf dem Rechner im Menü › Einstellungen › „Protokoll öffnen“ (zeigt den Ordner), im Browser lädt derselbe
# Knopf die Datei herunter. Taste F9 tut dasselbe.

const ORDNER := "user://protokoll"
const BEHALTEN := 8
const ABSCHNITT := 5.0

var datei: FileAccess
var pfad := ""
var zeilen := PackedStringArray()     # alles dieser Sitzung (für das Herunterladen im Browser)
var t := 0.0
var bilder := 0
var summe_ms := 0.0
var schlechtestes := 0.0
var ruckler := 0
var zeiten := {}                       # Teilsystem → µs in diesem Abschnitt
var spitzen := {}                      # Teilsystem → längster einzelner Aufruf (µs)
var guete := -1               # Grafikstufe, die gemessen oder gewählt wurde: gilt über die Stunden hinweg
var guete_von_hand := false
var gesagt := false           # der Hinweis auf Software-Grafik kam schon
var physik_zuletzt := 0
var uhr := 0
var zeitlupe := 0.0     # so viel echte Zeit ging in diesem Abschnitt verloren, weil das Spiel nicht nachkam
var fanger: Fanger
var grafik := ""        # echter Name der Grafik (im Browser über WEBGL_debug_renderer_info)
var software := false   # ohne Grafikkarte gerechnet (SwiftShader, llvmpipe …)
var _sperre := Mutex.new()
var _eingang := PackedStringArray()   # vom Logger (kann aus anderen Fäden kommen)

class Fanger extends Logger:
	var p: Node
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var art: String = ["FEHLER", "WARNUNG", "SKRIPTFEHLER", "SHADERFEHLER"][clampi(error_type, 0, 3)]
		p._von_logger("%s %s (%s:%d in %s)" % [art, rationale if rationale != "" else code, file.get_file(), line, function])
	func _log_message(message: String, error: bool) -> void:
		if error:
			p._von_logger("MELDUNG " + message.strip_edges())

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_aufraeumen()
	var jetzt := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	pfad = "%s/protokoll_%s.txt" % [ORDNER, jetzt]
	datei = FileAccess.open(pfad, FileAccess.WRITE)
	schreib("Herz und Feder · Fassung %s · Protokoll · %s" % [Spiel.FASSUNG, Time.get_datetime_string_from_system()])
	schreib("System: %s · %s · Prozessorkerne %d · Web %s · Handy %s" % [OS.get_name(), OS.get_processor_name(), OS.get_processor_count(), OS.has_feature("web"), OS.has_feature("web_ios") or OS.has_feature("web_android") or OS.has_feature("mobile")])
	schreib("Grafik: %s · %s · Fenster %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), str(DisplayServer.window_get_size())])
	if OS.has_feature("web"):
		# der Browser verrät den echten Namen der Grafik nur über diese Erweiterung; dazu Pixeldichte und Kerne
		var info = JavaScriptBridge.eval("(function(){try{var c=document.createElement('canvas');var g=c.getContext('webgl2')||c.getContext('webgl');var e=g&&g.getExtension('WEBGL_debug_renderer_info');return [(e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):'unbekannt'),(e?g.getParameter(e.UNMASKED_VENDOR_WEBGL):''),window.devicePixelRatio,navigator.hardwareConcurrency,screen.width+'x'+screen.height,navigator.userAgent].join(' | ')}catch(x){return 'unbekannt'}})()")
		grafik = str(info)
		schreib("Browser-Grafik: " + grafik)
	else:
		grafik = RenderingServer.get_video_adapter_name()
	var g := grafik.to_lower()
	software = g.contains("swiftshader") or g.contains("llvmpipe") or g.contains("software") or g.contains("basic render")
	if software:
		schreib("WARNUNG Die Grafik wird ohne Grafikkarte gerechnet (Software). Das Spiel kann so nicht flüssig laufen.")
	fanger = Fanger.new()
	fanger.p = self
	OS.add_logger(fanger)

# Im Browser zeichnet das Spiel so viele Bildpunkte, wie der Bildschirm hat (bei 150 % Skalierung 2,25-mal, auf Handys
# bis 9-mal so viele wie die Seite groß ist). Ab der Stufe „Sparsam“ rechnet es mit einfacher Dichte: Der Browser
# vergrößert das Bild dann selbst. Das entlastet auch die Oberfläche, nicht nur die 3D-Welt.
var dichte_gesenkt := false
func dichte_senken(an: bool) -> void:
	if not OS.has_feature("web") or an == dichte_gesenkt:
		return
	dichte_gesenkt = an
	JavaScriptBridge.eval("(function(){try{if(!window.__hf_dpr){window.__hf_dpr=window.devicePixelRatio||1}Object.defineProperty(window,'devicePixelRatio',{configurable:true,get:function(){return %s}});window.dispatchEvent(new Event('resize'))}catch(e){}})()" % ("Math.min(1,window.__hf_dpr)" if an else "window.__hf_dpr"))
	schreib("BILDPUNKTE %s" % ("einfache Dichte (der Browser vergrößert)" if an else "volle Dichte des Bildschirms"))

func _aufraeumen() -> void:
	var d := DirAccess.open(ORDNER)
	if d == null:
		return
	var alle: Array = Array(d.get_files()).filter(func(f): return f.begins_with("protokoll_"))
	alle.sort()
	while alle.size() >= BEHALTEN:
		d.remove(alle.pop_front())

func _von_logger(text: String) -> void:
	_sperre.lock()
	_eingang.append(text)
	_sperre.unlock()

func schreib(text: String) -> void:
	var z := "[%7.1f] %s" % [Time.get_ticks_msec() / 1000.0, text]
	zeilen.append(z)
	if zeilen.size() > 6000:
		zeilen = zeilen.slice(1000)
	if datei:
		datei.store_line(z)
		datei.flush()

# Rechenzeit eines Teilsystems: u = Time.get_ticks_usec() vom Anfang
func zeit(name: String, u: int) -> void:
	var d := Time.get_ticks_usec() - u
	zeiten[name] = zeiten.get(name, 0) + d
	if d > spitzen.get(name, 0):
		spitzen[name] = d

func _process(delta: float) -> void:
	_sperre.lock()
	var neu := _eingang
	_eingang = PackedStringArray()
	_sperre.unlock()
	for z in neu:
		schreib(z)
	# echte Zeit seit dem letzten Bild: „delta“ kappt die Engine bei acht Physikschritten (133 ms), ein langsames Gerät
	# sähe sonst immer nach 7 Bildern/s aus, auch wenn es in Wahrheit 2 sind und das Spiel in Zeitlupe läuft
	var jetzt := Time.get_ticks_usec()
	var echt := (jetzt - uhr) / 1000000.0 if uhr > 0 else delta
	uhr = jetzt
	if echt > 2.0:
		echt = delta   # Tab war im Hintergrund oder die Stunde wurde geladen
	zeitlupe += maxf(0.0, echt - delta)
	delta = echt
	var ms := delta * 1000.0
	bilder += 1
	summe_ms += ms
	schlechtestes = maxf(schlechtestes, ms)
	if ms > 50.0:
		ruckler += 1
	if ms > 120.0 and t > 1.0:
		var g := get_tree().current_scene
		var wo := ""
		if g and "hero" in g and g.hero:
			wo = " bei (%d, %d)" % [int(g.hero.global_position.x), int(g.hero.global_position.z)]
		schreib("RUCKLER %.0f ms%s" % [ms, wo])
	t += delta
	if t >= ABSCHNITT:
		_abschnitt()

func _abschnitt() -> void:
	var g := get_tree().current_scene
	var teile := []
	var schl := zeiten.keys()
	schl.sort_custom(func(a, b): return zeiten[a] > zeiten[b])
	for k in schl:
		teile.append("%s %.2f (Spitze %.0f)" % [k, zeiten[k] / 1000.0 / maxf(1.0, bilder), spitzen.get(k, 0) / 1000.0])
	var lage := ""
	if g and "foes" in g and g.started:
		var wach: int = g.foes.filter(func(f): return f.state == Foe.St.FIGHT).size()
		var lichter: int = g.lichter.filter(func(l): return is_instance_valid(l) and l.visible).size() if "lichter" in g else -1
		lage = " · 3D-Auflösung %d %%" % int(get_viewport().scaling_3d_scale * 100.0) + " · Stunde %d · Gegner %d (wach %d) · Lichter an %d · Raumklänge an %d · Grafik %s" % [Spiel.fall, g.foes.size(), wach, lichter, g.sfx.schleifen_aktiv, g.GUETE_NAME[g.guete]]
	var pf := Engine.get_physics_frames()
	var schritte := float(pf - physik_zuletzt) / maxf(1.0, bilder)
	physik_zuletzt = pf
	schreib("LEISTUNG %.1f Bilder/s · Zeitlupe %d %% · Physikschritte je Bild %.1f · schlechtestes Bild %.0f ms · Ruckler über 50 ms: %d · Zeichenaufrufe %d · Dreiecke %d · Skript (ms je Bild): Verarbeitung %.1f, Physik %.1f%s" % [
		bilder / t, int(zeitlupe / t * 100.0), schritte, schlechtestes, ruckler,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, lage])
	if not teile.is_empty():
		schreib("  TEILE (ms je Bild, Spitze ms): " + ", ".join(teile))
	zeitlupe = 0.0
	t = 0.0
	bilder = 0
	summe_ms = 0.0
	schlechtestes = 0.0
	ruckler = 0
	zeiten.clear()
	spitzen.clear()

# Protokoll zum Lesen bereitstellen: im Browser herunterladen, sonst den Ordner öffnen
func ausgeben() -> String:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer("\n".join(zeilen).to_utf8_buffer(), pfad.get_file(), "text/plain")
		return "Das Protokoll wird heruntergeladen (%s)." % pfad.get_file()
	var ort := ProjectSettings.globalize_path(ORDNER)
	OS.shell_open(ort)
	return "Protokoll: %s" % ProjectSettings.globalize_path(pfad)

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_F9:
		var text := ausgeben()
		var g := get_tree().current_scene
		if g and "hud" in g and g.hud:
			g.hud.toast(text, 5.0)
