extends SceneTree
# Baut die Bewegungssätze des Spiels (models/anim/<satz>.res) aus fremden Bewegungsdateien, ohne Blender.
# Aufruf (im Ordner herz-und-feder-3d):
#   godot --headless --path . -s res://tools/bewegung/umrechnen.gd -- --quellen=<Ordner mit den Quelldateien> [--satz=eidtraeger] [--nur=Name]
# Rezept: tools/bewegung/saetze.json. Quelldateien (.glb, .gltf, .fbx, .bvh) liegen außerhalb des Repos (Lizenz, Größe).

const Umrechner := preload("res://tools/bewegung/umrechner.gd")
const Bvh := preload("res://tools/bewegung/bvh.gd")

var quellen_ordner := ""
var geladen := {}   # Quellname → [Wurzel, Skelett, AnimationPlayer]


func _init() -> void:
	var nur_satz := ""
	var nur := ""
	var rezept := "res://tools/bewegung/saetze.json"
	var roh := false   # ohne Ausdünnen der Schlüssel (zum Vergleichen)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--quellen="): quellen_ordner = a.get_slice("=", 1)
		if a.begins_with("--satz="): nur_satz = a.get_slice("=", 1)
		if a.begins_with("--nur="): nur = a.get_slice("=", 1)
		if a.begins_with("--rezept="): rezept = a.get_slice("=", 1)
		if a == "--roh": roh = true
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rezept))
	var ziel_wurzel: Node = load(plan.ziel).instantiate()
	var z: Skeleton3D = ziel_wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var z_basis := Umrechner.bis_wurzel(z, ziel_wurzel)
	var z_pfad := str(ziel_wurzel.get_path_to(z))
	var bein := z.get_bone_global_rest(z.find_bone("upperleg.l")).origin.y - z.get_bone_global_rest(z.find_bone("foot.l")).origin.y
	var fehler := 0
	for satz in plan.saetze:
		if nur_satz != "" and satz != nur_satz:
			continue
		var bib := AnimationLibrary.new()
		var bytes_vorher := 0
		print("Satz ", satz)
		for e in plan.saetze[satz]:
			if nur != "" and e.name != nur:
				continue
			var q = _quelle(plan.quellen[e.quelle])
			if q == null:
				print("  FEHLT Quelle ", e.quelle)
				fehler += 1
				continue
			var ap: AnimationPlayer = q[2]
			if not ap.has_animation(e.bew):
				print("  FEHLT Bewegung ", e.bew, " in ", e.quelle)
				fehler += 1
				continue
			var karte_name: String = e.get("karte", plan.karten.get(e.quelle, ""))
			if karte_name == "":
				karte_name = Umrechner.karte_raten(q[1])
			var karte := Umrechner.karte_fuer(karte_name, q[1])
			if roh:
				e = e.duplicate()
				e["toleranz_grad"] = 0.0
				e["toleranz_bein_grad"] = 0.0
				e["toleranz_m"] = 0.0
			var erg := Umrechner.uebertragen(q[1], Umrechner.bis_wurzel(q[1], q[0]), ap.get_animation(e.bew), karte, z, z_basis, z_pfad, e)
			var anim: Animation = erg[0]
			var b: Dictionary = erg[1]
			anim.set_meta("quelle", "%s › %s" % [e.quelle, e.bew])
			bib.add_animation(e.name, anim)
			print("  %-18s ← %-24s %5.2f s  %3d Bilder  %4d Schlüssel  Weg %s  tiefster Fußpunkt %.3f  IK-Rest %.3f" % [e.name, e.bew, anim.length, b.bilder, b.schluessel, str(b.weg.snapped(Vector3.ONE * 0.01)), b.tiefst, b.ik])
		bib.set_meta("beinlaenge", bein)
		bib.set_meta("huefte", z.get_bone_rest(z.find_bone("hips")).origin)
		bib.set_meta("lizenz", plan.lizenz.get(satz, "siehe models/anim/LIZENZ.md"))
		var pfad := "res://models/anim/%s.res" % satz
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://models/anim"))
		var err := ResourceSaver.save(bib, pfad, ResourceSaver.FLAG_COMPRESS)
		var groesse := FileAccess.get_file_as_bytes(pfad).size()
		print("  → %s  %d Bewegungen  %.1f KB  (Fehler %d)" % [pfad, bib.get_animation_list().size(), groesse / 1024.0, err])
	print("UMRECHNEN fertig, Fehler: ", fehler)
	quit(1 if fehler > 0 else 0)


func _quelle(datei: String):
	if geladen.has(datei):
		return geladen[datei]
	var pfad := datei if datei.is_absolute_path() or datei.begins_with("res://") else quellen_ordner.path_join(datei)
	if not FileAccess.file_exists(pfad):
		return null
	var wurzel: Node
	var ext := pfad.get_extension().to_lower()
	if ext == "bvh":
		wurzel = Bvh.laden(pfad)
	else:
		var doc: GLTFDocument = FBXDocument.new() if ext == "fbx" else GLTFDocument.new()
		var st: GLTFState = FBXState.new() if ext == "fbx" else GLTFState.new()
		if doc.append_from_file(pfad, st) != OK:
			return null
		wurzel = doc.generate_scene(st)
	var sk: Skeleton3D = wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = wurzel.find_children("*", "AnimationPlayer", true, false)[0]
	geladen[datei] = [wurzel, sk, ap]
	return geladen[datei]
