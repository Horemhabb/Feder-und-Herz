extends SceneTree
# Schreibt eine Bewegung als BVH: aus einer Quelldatei (glb/fbx) oder aus einem Satz des Spiels auf einer Spielfigur.
# Wozu: Prüfung des BVH-Lesers (Hin- und Rückweg) und der Weg nach Blender oder in andere Werkzeuge.
# Aufruf: godot --headless --path . -s res://tools/bewegung/nach_bvh.gd -- --quelle=<glb> --bew=<Name> --aus=<x.bvh>
#         godot --headless --path . -s res://tools/bewegung/nach_bvh.gd -- --modell=Eidtraeger --satz=eidtraeger --bew=Hiebfolge --aus=<x.bvh>

const Bvh := preload("res://tools/bewegung/bvh.gd")

func _init() -> void:
	var quelle := ""
	var modell := ""
	var satz := ""
	var bew := ""
	var aus := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--quelle="): quelle = a.get_slice("=", 1)
		if a.begins_with("--modell="): modell = a.get_slice("=", 1)
		if a.begins_with("--satz="): satz = a.get_slice("=", 1)
		if a.begins_with("--bew="): bew = a.get_slice("=", 1)
		if a.begins_with("--aus="): aus = a.get_slice("=", 1)
	var wurzel: Node
	if quelle != "":
		var doc: GLTFDocument = FBXDocument.new() if quelle.get_extension().to_lower() == "fbx" else GLTFDocument.new()
		var st: GLTFState = FBXState.new() if quelle.get_extension().to_lower() == "fbx" else GLTFState.new()
		doc.append_from_file(quelle, st)
		wurzel = doc.generate_scene(st)
	else:
		wurzel = load("res://models/chars/%s.glb" % modell).instantiate()
	var sk: Skeleton3D = wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = wurzel.find_children("*", "AnimationPlayer", true, false)[0]
	if satz != "":
		Bewegungen.ergaenzen(ap, sk, satz)
		bew = satz + "/" + bew
	Bvh.schreiben(aus, sk, ap.get_animation(bew))
	print("BVH: ", aus)
	quit()
