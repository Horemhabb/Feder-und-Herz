extends Node3D
# Prüfbilder der Fabrik: eine Figur in mehreren Bewegungen und Blickwinkeln nebeneinander.
# Aufruf: godot --path . res://tools/figurenfabrik/probe.tscn -- --modell=Eidtraeger --bew=Idle:0.2,Running_A:0.3 --aus=/tmp/x.png [--nah]

func _ready() -> void:
	var modell := "Eidtraeger"
	var bew := ["2H_Melee_Idle:0.3"]
	var aus := "user://probe.png"
	var nah := false
	var dreh := 0.0
	var abstand := 2.6
	var blick := Vector3(0, 1.2, 0)
	var weit := 0.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modell="): modell = a.get_slice("=", 1)
		if a.begins_with("--bew="): bew = Array(a.get_slice("=", 1).split(","))
		if a.begins_with("--aus="): aus = a.get_slice("=", 1)
		if a.begins_with("--dreh="): dreh = float(a.get_slice("=", 1))
		if a == "--nah": nah = true
		if a.begins_with("--abstand="): abstand = float(a.get_slice("=", 1))
		if a.begins_with("--weit="): weit = float(a.get_slice("=", 1))
		if a.begins_with("--blick="): blick.y = float(a.get_slice("=", 1))
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
	sun.shadow_enabled = true
	add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 20)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.38, 0.32)
	fl.material_override = fm
	add_child(fl)
	var n := bew.size()
	for i in n:
		var m: Node3D = load("res://models/chars/%s.glb" % modell).instantiate()
		add_child(m)
		m.position = Vector3((i - (n - 1) * 0.5) * abstand, 0, 0)
		m.rotation.y = deg_to_rad(dreh + (0.0 if n == 1 else 0.0))
		var teile: PackedStringArray = bew[i].split(":")
		if teile.size() > 2:
			m.rotation.y = deg_to_rad(float(teile[2]))
		var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
		if ap and ap.has_animation(teile[0]):
			ap.play(teile[0])
			ap.seek(float(teile[1]) * ap.get_animation(teile[0]).length, true)
			ap.pause()
		elif ap:
			print("fehlt: ", teile[0], " von ", ap.get_animation_list())
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 30
	var w := n * abstand
	var d := weit if weit > 0.0 else maxf(6.0, w * 1.15)
	cam.position = Vector3(0, blick.y + d * 0.22, d)
	cam.look_at(blick)
	cam.make_current()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(aus)
	get_tree().quit()
