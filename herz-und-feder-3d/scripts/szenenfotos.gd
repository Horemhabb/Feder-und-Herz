extends Node
# Bilder der Zwischensequenzen (4.3). Start: „-- --neu --szenenfotos --aus=/pfad“ (braucht einen Bildschirm, unter Linux
# xvfb-run -a … --rendering-driver opengl3; fürs Handy dazu --touch und --resolution 844x390).
# Spielt jede Sequenz aus Szenen.LISTE (das Ende in allen drei Urteilen) und speichert von jeder Einstellung ein Bild:
# <aus>/<vorsilbe>_<sequenz>_<nr>.png. „--nur=auftakt,mitte“ wählt aus, „--vorsilbe=pc“ benennt den Lauf.
# Ausgabe am Ende: „SZENENFOTOS: n Bilder, m Fehler“.

var bilder := 0
var bad := 0
var aus := "res://test_out/szenen"
var vorsilbe := "pc"

func g() -> Node:
	return get_tree().current_scene

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--aus="):
			aus = a.substr(6)
		if a.begins_with("--vorsilbe="):
			vorsilbe = a.substr(11)
	run.call_deferred()

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		bad += 1
		print("  FEHLER  kein Bild: " + name)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(aus) if aus.begins_with("res://") else aus)
	var pfad := "%s/%s_%s.png" % [aus, vorsilbe, name]
	img.save_png(pfad)
	bilder += 1
	print("  ok      " + pfad)

func run() -> void:
	await wait(1.5)
	var G := g()
	# Startbildschirm und Auftakt überspringen, bis die Stunde läuft
	for i in 20:
		if G.started:
			break
		if Szene.laeuft():
			Szene.jetzt._ende()
			await wait(1.0)
		else:
			G.hud.press_primary()
			await wait(1.8)
		G = g()
	G.auto_low_done = true
	if G.get("leben"):
		G.leben.stumm = true
	G.freeze_foes = true
	var nur := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nur="):
			nur = Array(a.substr(6).split(","))
	for p in Szenen.LISTE:
		var name: String = p[0]
		if not nur.is_empty() and not name in nur:
			continue
		if name == "finale":
			# alle drei Urteile, mit wechselnden Entscheidungen, damit jede Fassung einmal im Bild ist
			for v in [["leicht", 40.0, "maat"], ["schwebe", 0.0, "isfet"], ["schwer", -40.0, "isfet"]]:
				Spiel.herz = v[1]
				for k in ["1", "4", "6", "8", "11"]:
					Spiel.wahl[k] = v[2]
				await sequenz(G, name, "finale_" + v[0])
			Spiel.herz = 0.0
			Spiel.wahl = {}
		else:
			await sequenz(G, name, name)
	print("SZENENFOTOS: %d Bilder, %d Fehler" % [bilder, bad])
	get_tree().quit(1 if bad > 0 else 0)

func sequenz(G: Node, name: String, tag: String) -> void:
	for i in 30:
		if not Szene.laeuft():
			break
		await wait(0.2)
	Szene.spielen(G, name, Callable(), true)
	await wait(0.2)
	var s: Szene = Szene.jetzt
	if s == null or s.name_sz != name:
		bad += 1
		print("  FEHLER  %s startet nicht (%s)" % [name, s.name_sz if s else "-"])
		return
	s.halten = true   # nicht von selbst weiter: jede Einstellung wird mit ihrer ersten Zeile aufgenommen
	var n: int = s.daten.einstellungen.size()
	for i in n:
		# erste Zeile eingeblendet, Kamera angekommen
		await wait(2.1)
		if not is_instance_valid(s) or not Szene.laeuft():
			break
		await shot("%s_%d" % [tag, i + 1])
		if i < n - 1 and is_instance_valid(s):
			s.z_i = 99
			s._naechste_einstellung()
	if Szene.laeuft() and is_instance_valid(s):
		s._ende()
	await wait(0.9)
	if get_tree().paused:
		get_tree().paused = false
