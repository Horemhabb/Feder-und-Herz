extends Node3D
# Filmt eine Bewegung Bild für Bild (PNG-Folge), für zwei Zwecke:
# 1. Probe der Kette „Video → Bewegung“ mit bekannter Wahrheit: die Quellfigur (z. B. Quaternius-Puppe) spielt eine
#    Bewegung, pose_zu_bvh.py schätzt daraus die Gelenke, der Umrechner überträgt sie, das Ergebnis wird mit der
#    direkten Übertragung verglichen.
# 2. Vorschau einer Spielfigur als Bildfolge (mit ffmpeg zu einem Video).
# Aufruf (braucht einen Bildschirm):
#   godot --path . res://tools/bewegung/film.tscn -- --datei=<glb> | --modell=Eidtraeger --satz=eidtraeger
#         --bew=<Name> --aus=<Ordner> [--fps=30] [--dreh=30] [--groesse=640x640]

func _ready() -> void:
	var datei := ""
	var modell := ""
	var satz := ""
	var bew := ""
	var aus := "user://film"
	var fps := 30.0
	var dreh := 30.0
	var groesse := Vector2i(640, 640)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--datei="): datei = a.get_slice("=", 1)
		if a.begins_with("--modell="): modell = a.get_slice("=", 1)
		if a.begins_with("--satz="): satz = a.get_slice("=", 1)
		if a.begins_with("--bew="): bew = a.get_slice("=", 1)
		if a.begins_with("--aus="): aus = a.get_slice("=", 1)
		if a.begins_with("--fps="): fps = float(a.get_slice("=", 1))
		if a.begins_with("--dreh="): dreh = float(a.get_slice("=", 1))
		if a.begins_with("--groesse="):
			var g := a.get_slice("=", 1).split("x")
			groesse = Vector2i(int(g[0]), int(g[1]))
	get_window().size = groesse
	DirAccess.make_dir_recursive_absolute(aus)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.57, 0.6)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 160, 0)
	add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.4, 0.38, 0.34)
	fl.material_override = fm
	add_child(fl)
	var figur: Node3D
	if datei != "":
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		doc.append_from_file(datei, st)
		figur = doc.generate_scene(st)
	else:
		figur = load("res://models/chars/%s.glb" % modell).instantiate()
	add_child(figur)
	figur.rotation.y = deg_to_rad(dreh)
	var ap: AnimationPlayer = figur.find_children("*", "AnimationPlayer", true, false)[0]
	if satz != "":
		Bewegungen.ergaenzen(ap, figur.find_children("*", "Skeleton3D", true, false)[0], satz)
		bew = satz + "/" + bew
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40
	var hoehe := 1.0 if datei != "" else 1.2
	cam.position = Vector3(0, hoehe + 0.3, 4.2 * hoehe)
	cam.look_at(Vector3(0, hoehe * 0.9, 0))
	cam.make_current()
	var a := ap.get_animation(bew)
	ap.play(bew)
	ap.pause()
	var n := int(a.length * fps) + 1
	await get_tree().create_timer(0.3).timeout
	for i in n:
		ap.seek(minf(i / fps, a.length), true)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(aus.path_join("bild_%04d.png" % i))
	print("Film: %d Bilder in %s" % [n, aus])
	get_tree().quit()
