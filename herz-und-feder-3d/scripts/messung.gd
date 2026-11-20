extends Node
# Messung (4.0.3, „-- --neu --mess“): Was kostet ein Bild? Schaltet Teile nacheinander ab und misst die Bildzeit.
# Unter einer Software-Grafik (xvfb, SwiftShader) zeigt das, was beim Zeichnen am teuersten ist.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func ms(n := 12) -> float:
	await get_tree().process_frame
	await get_tree().process_frame
	var u := Time.get_ticks_usec()
	for i in n:
		await get_tree().process_frame
	return (Time.get_ticks_usec() - u) / 1000.0 / n

func run() -> void:
	await get_tree().create_timer(4.0).timeout
	var g := get_tree().current_scene
	g.auto_low_done = true
	print("MESS Startbild (Fenster %s): %.0f ms" % [str(DisplayServer.window_get_size()), await ms()])
	while not g.started:
		g.hud.press_primary()
		await get_tree().create_timer(1.5).timeout
		g = get_tree().current_scene
		g.auto_low_done = true
	await get_tree().create_timer(2.0).timeout
	if g.hud.overlay:
		g.hud.close_bag()
	var vp := get_viewport()
	print("MESS Spiel, alles an: %.0f ms" % await ms())
	g.hud.root.visible = false
	print("MESS ohne Oberfläche: %.0f ms" % await ms())
	g.hud.root.visible = true
	vp.disable_3d = true
	print("MESS ohne 3D (nur Oberfläche): %.0f ms" % await ms())
	vp.disable_3d = false
	g.env.glow_enabled = false
	print("MESS ohne Glühen: %.0f ms" % await ms())
	g.env.adjustment_enabled = false
	print("MESS ohne Glühen und Farbkorrektur: %.0f ms" % await ms())
	g.env.fog_enabled = false
	print("MESS dazu ohne Nebel: %.0f ms" % await ms())
	g.moon.shadow_enabled = false
	g.hero.lantern.shadow_enabled = false
	print("MESS dazu ohne Schatten: %.0f ms" % await ms())
	for l in g.lichter:
		if is_instance_valid(l): l.visible = false
	g.set_process(false)
	print("MESS dazu ohne feste Lichter: %.0f ms" % await ms())
	vp.scaling_3d_scale = 0.5
	print("MESS dazu 3D 50 %%: %.0f ms" % await ms())
	vp.scaling_3d_scale = 1.0
	for n in g.get_children():
		if n is MultiMeshInstance3D or n is CPUParticles3D or n is GPUParticles3D: n.visible = false
	for n in g.stimmung:
		if is_instance_valid(n): n.visible = false
	print("MESS dazu ohne Pflanzen, Partikel, Stimmung: %.0f ms" % await ms())
	for c in g.cut_mats.values():
		pass
	var mauern := 0
	for n in g.find_children("*", "MeshInstance3D", true, false):
		if n.material_override is ShaderMaterial:
			n.visible = false
			mauern += 1
	print("MESS dazu ohne %d Flächen mit eigenem Shader (Mauern …): %.0f ms" % [mauern, await ms()])
	g.cam.far = 5.0
	print("MESS dazu fast leeres Bild (Sichtweite 5 m): %.0f ms" % await ms())
	get_tree().quit()
