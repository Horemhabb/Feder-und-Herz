extends Node
# Messung (4.0.1, „-- --neu --mess“): welche Knotenart frisst die Verarbeitungszeit? Schaltet Gruppen nacheinander ab.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()
func t_proc() -> float:
	var s := 0.0
	for i in 30:
		await get_tree().process_frame
		s += Performance.get_monitor(Performance.TIME_PROCESS)
	return s / 30.0 * 1000.0
func run() -> void:
	await get_tree().create_timer(6.0).timeout
	var g := get_tree().current_scene
	while not g.started:
		g.hud.press_primary()
		await get_tree().create_timer(1.5).timeout
		g = get_tree().current_scene
	await get_tree().create_timer(2.0).timeout
	var arten := {}
	for n in get_tree().root.find_children("*", "", true, false):
		var k := n.get_class()
		if n.is_processing() or n.is_physics_processing() or k in ["AnimationPlayer", "AnimationTree", "CPUParticles3D", "GPUParticles3D", "Label3D"]:
			arten[k] = arten.get(k, 0) + 1
	print("MESS Knoten mit Verarbeitung: ", arten)
	print("MESS alles an: %.1f ms" % await t_proc())
	var aps: Array = get_tree().root.find_children("*", "AnimationPlayer", true, false)
	for a in aps: a.active = false
	print("MESS ohne %d AnimationPlayer: %.1f ms" % [aps.size(), await t_proc()])
	for a in aps: a.active = true
	var cps: Array = get_tree().root.find_children("*", "CPUParticles3D", true, false)
	for c in cps: c.process_mode = Node.PROCESS_MODE_DISABLED
	print("MESS ohne %d CPUParticles3D: %.1f ms" % [cps.size(), await t_proc()])
	for c in cps: c.process_mode = Node.PROCESS_MODE_INHERIT
	for f in g.foes: f.process_mode = Node.PROCESS_MODE_DISABLED
	print("MESS ohne Gegner: %.1f ms" % await t_proc())
	for f in g.foes: f.process_mode = Node.PROCESS_MODE_INHERIT
	g.leben.process_mode = Node.PROCESS_MODE_DISABLED
	for p in g.leben.leute: p.n.process_mode = Node.PROCESS_MODE_DISABLED
	print("MESS ohne Leute: %.1f ms" % await t_proc())
	get_tree().quit()
