extends RefCounted
# BVH lesen (Motion-Capture-Austauschformat: CMU, Bandai Namco, LAFAN1, Ausgaben von Text-zu-Bewegung und Video-Mocap).
# Ergebnis ist ein Knoten wie aus einer glTF-Datei: Wurzel › Skeleton3D „Skeleton3D“ + AnimationPlayer mit einer
# Bewegung „bvh“. Damit geht eine BVH-Datei denselben Weg durch den Umrechner wie Quaternius oder Mixamo.
# Ruhelage = alle Drehungen null (bei den meisten Dateien eine T-Haltung). Einheiten egal: der Umrechner misst Beinlängen.
# drehung_y: Grad um die Hochachse, falls die Datei nicht entlang +Z blickt (CMU: meist schon +Z).


static func laden(pfad: String, drehung_y := 0.0) -> Node3D:
	var text := FileAccess.get_file_as_string(pfad)
	var w := text.replace("\t", " ").replace("\r", "").split("\n")
	var toks := PackedStringArray()
	var motion_ab := -1
	for i in w.size():
		var zeile := w[i].strip_edges()
		if zeile.begins_with("MOTION"):
			motion_ab = i
			break
		for t in zeile.split(" ", false):
			toks.append(t)
	var skel := Skeleton3D.new()
	skel.name = "Skeleton3D"
	var kanaele := []   # [Knochen, Kanalname]
	var stapel := []
	var i := 0
	var letzter := -1
	while i < toks.size():
		var t := toks[i]
		if t == "ROOT" or t == "JOINT":
			var b := skel.get_bone_count()
			skel.add_bone(toks[i + 1])
			if not stapel.is_empty():
				skel.set_bone_parent(b, stapel[-1])
			letzter = b
			i += 2
		elif t == "End":
			letzter = -2
			i += 2
		elif t == "{":
			stapel.append(letzter)
			i += 1
		elif t == "}":
			stapel.pop_back()
			i += 1
		elif t == "OFFSET":
			var o := Vector3(float(toks[i + 1]), float(toks[i + 2]), float(toks[i + 3]))
			if letzter >= 0:
				skel.set_bone_rest(letzter, Transform3D(Basis.IDENTITY, o))
			i += 4
		elif t == "CHANNELS":
			var n := int(toks[i + 1])
			for c in n:
				kanaele.append([letzter, toks[i + 2 + c]])
			i += 2 + n
		else:
			i += 1
	# Endstellen hängen auf -2 und werden nicht gebraucht; Stapel mit -2 ist harmlos
	var bilder := 0
	var dt := 1.0 / 30.0
	var werte := []
	for j in range(motion_ab + 1, w.size()):
		var zeile := w[j].strip_edges()
		if zeile.begins_with("Frames:"):
			bilder = int(zeile.get_slice(":", 1))
		elif zeile.begins_with("Frame Time:"):
			dt = float(zeile.get_slice(":", 1))
		elif zeile != "":
			werte.append(zeile.split(" ", false))
	bilder = mini(bilder, werte.size()) if bilder > 0 else werte.size()
	var anim := Animation.new()
	anim.length = maxf(dt, (bilder - 1) * dt)
	var rot_spur := {}
	var pos_spur := {}
	for b in skel.get_bone_count():
		var r := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(r, NodePath("Skeleton3D:" + skel.get_bone_name(b)))
		rot_spur[b] = r
	for k in kanaele:
		if k[1].ends_with("position") and not pos_spur.has(k[0]):
			var p := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(p, NodePath("Skeleton3D:" + skel.get_bone_name(k[0])))
			pos_spur[k[0]] = p
	for f in bilder:
		var zeile: PackedStringArray = werte[f]
		var rot := {}
		var pos := {}
		for c in kanaele.size():
			var b: int = kanaele[c][0]
			var name: String = kanaele[c][1]
			var v := float(zeile[c]) if c < zeile.size() else 0.0
			if name.ends_with("rotation"):
				var achse := Vector3.RIGHT if name.begins_with("X") else (Vector3.UP if name.begins_with("Y") else Vector3.BACK)
				# Kanäle in Dateireihenfolge von links nach rechts multiplizieren (z. B. Z X Y: Rz·Rx·Ry)
				rot[b] = rot.get(b, Quaternion.IDENTITY) * Quaternion(achse, deg_to_rad(v))
			elif name.ends_with("position"):
				var p: Vector3 = pos.get(b, Vector3.ZERO)
				if name.begins_with("X"): p.x = v
				elif name.begins_with("Y"): p.y = v
				else: p.z = v
				pos[b] = p
		for b in skel.get_bone_count():
			anim.rotation_track_insert_key(rot_spur[b], f * dt, rot.get(b, Quaternion.IDENTITY))
		for b in pos_spur:
			# BVH: Lagekanäle ersetzen den Versatz (bei der Wurzel üblich)
			anim.position_track_insert_key(pos_spur[b], f * dt, pos.get(b, skel.get_bone_rest(b).origin))
	var wurzel := Node3D.new()
	wurzel.name = pfad.get_file().get_basename()
	var halter := Node3D.new()
	halter.name = "Halter"
	halter.rotation.y = deg_to_rad(drehung_y)
	wurzel.add_child(halter)
	halter.add_child(skel)
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	wurzel.add_child(ap)
	ap.root_node = NodePath("../Halter")
	var bib := AnimationLibrary.new()
	bib.add_animation("bvh", anim)
	ap.add_animation_library("", bib)
	return wurzel


# Schreibt eine Bewegung als BVH mit drehungsfreier Ruhelage (so erwarten es Blender und die meisten Werkzeuge):
# Versätze im Raum der Ruhelage, Drehung je Gelenk = Weltdrehung gegenüber der Ruhe, relativ zum Elternteil.
# Drehkanäle Z X Y wie CMU. Für Tests (Hin- und Rückweg) und für den Weg nach Blender.
static func schreiben(pfad: String, skel: Skeleton3D, anim: Animation, fps := 30.0) -> void:
	var U = load("res://tools/bewegung/umrechner.gd")
	var sp: Dictionary = U.spuren(anim, skel)
	var ruhe: Array = U.pose(skel, Transform3D.IDENTITY, null, sp, 0.0)
	var f := FileAccess.open(pfad, FileAccess.WRITE)
	f.store_line("HIERARCHY")
	var kinder := {}
	for b in skel.get_bone_count():
		var e := skel.get_bone_parent(b)
		if not kinder.has(e):
			kinder[e] = []
		kinder[e].append(b)
	var reihenfolge := []
	var zeilen := PackedStringArray()
	var schreib_knochen := func(selbst: Callable, b: int, tiefe: int) -> void:
		var ein := "  ".repeat(tiefe)
		var e := skel.get_bone_parent(b)
		var o: Vector3 = ruhe[b].origin - (ruhe[e].origin if e >= 0 else Vector3.ZERO)
		zeilen.append(ein + ("ROOT " if tiefe == 0 else "JOINT ") + skel.get_bone_name(b))
		zeilen.append(ein + "{")
		zeilen.append(ein + "  OFFSET %f %f %f" % [o.x, o.y, o.z])
		if tiefe == 0 or (sp.has(b) and sp[b][0] >= 0):
			zeilen.append(ein + "  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation")
		else:
			zeilen.append(ein + "  CHANNELS 3 Zrotation Xrotation Yrotation")
		reihenfolge.append(b)
		for c in kinder.get(b, []):
			selbst.call(selbst, c, tiefe + 1)
		if not kinder.has(b):
			zeilen.append(ein + "  End Site")
			zeilen.append(ein + "  {")
			zeilen.append(ein + "    OFFSET 0 0 0")
			zeilen.append(ein + "  }")
		zeilen.append(ein + "}")
	for r in kinder[-1]:
		schreib_knochen.call(schreib_knochen, r, 0)
	for z in zeilen:
		f.store_line(z)
	var n := int(round(anim.length * fps)) + 1
	f.store_line("MOTION")
	f.store_line("Frames: %d" % n)
	f.store_line("Frame Time: %f" % (1.0 / fps))
	for i in n:
		var g: Array = U.pose(skel, Transform3D.IDENTITY, anim, sp, minf(i / fps, anim.length))
		var welt := {}
		for b in reihenfolge:
			welt[b] = U.drehung(g[b]) * U.drehung(ruhe[b]).inverse()
		var teile := PackedStringArray()
		for b in reihenfolge:
			var e := skel.get_bone_parent(b)
			if e < 0:
				var p: Vector3 = g[b].origin
				teile.append_array([str(p.x), str(p.y), str(p.z)])
			elif sp.has(b) and sp[b][0] >= 0:
				# verschobenes Gelenk (z. B. Becken unter einer Wurzel): Versatz im gedrehten Elternraum
				var p: Vector3 = Basis(welt[e]).inverse() * (g[b].origin - g[e].origin)
				teile.append_array([str(p.x), str(p.y), str(p.z)])
			var q: Quaternion = welt[b] if e < 0 else (welt[e] as Quaternion).inverse() * welt[b]
			var eu := Basis(q).get_euler(EULER_ORDER_ZXY)
			teile.append_array(["%.4f" % rad_to_deg(eu.z), "%.4f" % rad_to_deg(eu.x), "%.4f" % rad_to_deg(eu.y)])
		f.store_line(" ".join(teile))
	f.close()
