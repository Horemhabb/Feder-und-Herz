extends Node3D
# Prüfbilder für übertragene Bewegungen: oben die Spielfigur, unten (wahlweise) die Quellfigur in derselben Phase.
# Aufruf (braucht einen Bildschirm, z. B. xvfb-run -a … --rendering-driver opengl3):
#   godot --path . res://tools/bewegung/probe.tscn -- --modell=Eidtraeger --satz=eidtraeger --bew=Hiebfolge
#         [--phasen=6] [--dreh=30] [--quelle=<UAL1_Standard.glb> --quellbew=Sword_Regular_Combo] [--spiel] --aus=x.png
# --spiel: eine Figur aus der Spielkamera (Schrägsicht von oben, Blickfeld 30°), Phasen nebeneinander.

const Umrechner := preload("res://tools/bewegung/umrechner.gd")

func _ready() -> void:
	var modell := "Eidtraeger"
	var satz := "eidtraeger"
	var bew := "Kampfhaltung"
	var phasen := 6
	var dreh := 30.0
	var aus := "user://bewegung.png"
	var quelle := ""
	var quellbew := ""
	var spiel := false
	var groesse := Vector2i(1800, 520)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modell="): modell = a.get_slice("=", 1)
		if a.begins_with("--satz="): satz = a.get_slice("=", 1)
		if a.begins_with("--bew="): bew = a.get_slice("=", 1)
		if a.begins_with("--phasen="): phasen = int(a.get_slice("=", 1))
		if a.begins_with("--dreh="): dreh = float(a.get_slice("=", 1))
		if a.begins_with("--aus="): aus = a.get_slice("=", 1)
		if a.begins_with("--quelle="): quelle = a.get_slice("=", 1)
		if a.begins_with("--quellbew="): quellbew = a.get_slice("=", 1)
		if a == "--spiel": spiel = true
	get_window().size = groesse
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.7)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = not OS.get_cmdline_user_args().has("--ohne_schatten")
	add_child(sun)
	# Boden mit Gitter (50 cm): Fußrutschen sieht man an den Linien
	var gitter := Image.create(64, 64, false, Image.FORMAT_RGB8)
	gitter.fill(Color(0.42, 0.38, 0.32))
	for i in 64:
		gitter.set_pixel(i, 0, Color(0.22, 0.2, 0.17))
		gitter.set_pixel(0, i, Color(0.22, 0.2, 0.17))
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 40)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = ImageTexture.create_from_image(gitter)
	fm.uv1_scale = Vector3(160, 80, 1)
	fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fl.material_override = fm
	add_child(fl)
	var quellfiguren := []
	var zielfiguren := []
	var abstand := 2.2
	var name := satz + "/" + bew if satz != "" else bew
	for i in phasen:
		var m: Node3D = load("res://models/chars/%s.glb" % modell).instantiate()
		add_child(m)
		zielfiguren.append(m)
		m.position = Vector3((i - (phasen - 1) * 0.5) * abstand, 0, 0)
		if spiel:
			# quer zur Blickrichtung der Spielkamera aufreihen
			m.position = Vector3(1, 0, -1).normalized() * (i - (phasen - 1) * 0.5) * abstand * 1.3
		m.rotation.y = deg_to_rad(dreh)
		var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
		var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
		if satz != "":
			Bewegungen.ergaenzen(ap, sk, satz)
		if not ap.has_animation(name):
			print("fehlt: ", name)
			continue
		ap.play(name)
		ap.seek(ap.get_animation(name).length * i / maxf(1.0, phasen - 1), true)
		ap.pause()
	if quelle != "":
		for i in phasen:
			var doc := GLTFDocument.new()
			var st := GLTFState.new()
			doc.append_from_file(quelle, st)
			var q: Node3D = doc.generate_scene(st)
			add_child(q)
			q.scale = Vector3.ONE * 1.28
			q.position = Vector3((i - (phasen - 1) * 0.5) * abstand, 0, 0)
			q.visible = false
			quellfiguren.append(q)
			q.rotation.y = deg_to_rad(dreh)
			var ap: AnimationPlayer = q.find_children("*", "AnimationPlayer", true, false)[0]
			ap.play(quellbew)
			ap.seek(ap.get_animation(quellbew).length * i / maxf(1.0, phasen - 1), true)
			ap.pause()
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 30
	var breite := phasen * abstand
	var seitlich := atan(tan(deg_to_rad(15.0)) * float(groesse.x) / groesse.y)
	if spiel:
		# Spielkamera: Richtung wie im Spiel (14,5 / 27 / 14,5), Abstand so, dass alle Phasen ins Bild passen
		var r := Vector3(14.5, 27.0, 14.5).normalized()
		cam.position = r * maxf(12.0, breite * 0.5 / tan(seitlich) * 1.15)
		cam.look_at(Vector3(0, 0.8, 0))
	else:
		var d := breite * 0.5 / tan(seitlich) * 1.08
		cam.position = Vector3(0, 1.0 + d * 0.18, d)
		cam.look_at(Vector3(0, 1.0, 0))
	cam.make_current()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var bild := get_viewport().get_texture().get_image()
	if not quellfiguren.is_empty():
		for m in zielfiguren: m.visible = false
		for q in quellfiguren: q.visible = true
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var unten := get_viewport().get_texture().get_image()
		var beide := Image.create(bild.get_width(), bild.get_height() * 2, false, bild.get_format())
		beide.blit_rect(bild, Rect2i(Vector2i.ZERO, bild.get_size()), Vector2i.ZERO)
		beide.blit_rect(unten, Rect2i(Vector2i.ZERO, unten.get_size()), Vector2i(0, bild.get_height()))
		bild = beide
	bild.save_png(aus)
	print("Bild: ", aus)
	get_tree().quit()
