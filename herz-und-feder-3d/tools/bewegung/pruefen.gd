extends SceneTree
# Prüft die Bewegungssätze ohne Bildschirm, im Vergleich zur Quelle.
# Aufruf: godot --headless --path . -s res://tools/bewegung/pruefen.gd -- --quellen=<Ordner> [--modell=Eidtraeger]
# Rutschen: In den Bildern, in denen der Fuß der Quelle steht (waagrecht langsamer als 15 cm/s und höchstens 3 cm über
#   seinem Tiefststand), wie schnell wandert der Fuß der Spielfigur? Mittel und Größtwert in cm/s. 0 = steht wie die Quelle.
# Knie: Anteil der Bilder mit aufrechtem Becken, in denen ein Knie nach hinten durchgedrückt ist (Ziel / Quelle).
# Fehler: größter Abstand des Knöchels von der skalierten Lage in der Quelle (relativ zum Becken), in cm.

const Umrechner := preload("res://tools/bewegung/umrechner.gd")
const ZIEL := ["upperleg.l", "lowerleg.l", "foot.l", "toes.l", "upperleg.r", "lowerleg.r", "foot.r", "toes.r", "hips"]
const UAL := ["thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r", "pelvis"]

func _init() -> void:
	var modell := "Eidtraeger"
	var quellen := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modell="): modell = a.get_slice("=", 1)
		if a.begins_with("--quellen="): quellen = a.get_slice("=", 1)
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/bewegung/saetze.json"))
	var wurzel: Node = load("res://models/chars/%s.glb" % modell).instantiate()
	var ap: AnimationPlayer = wurzel.find_child("AnimationPlayer", true, false)
	var z: Skeleton3D = wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var bz := z.get_bone_global_rest(z.find_bone("upperleg.l")).origin.y - z.get_bone_global_rest(z.find_bone("foot.l")).origin.y
	var qs := {}
	print("%-28s %7s %7s %7s %9s %6s" % ["Bewegung", "Rutsch", "max", "Quelle", "Knie Z/Q", "Fehler"])
	var summe := [0.0, 0]
	for satz in plan.saetze:
		Bewegungen.ergaenzen(ap, z, satz)
		for e in plan.saetze[satz]:
			var name: String = satz + "/" + e.name
			if not ap.has_animation(name) or quellen == "":
				continue
			if not qs.has(e.quelle):
				var doc := GLTFDocument.new()
				var st := GLTFState.new()
				doc.append_from_file(quellen.path_join(plan.quellen[e.quelle]), st)
				qs[e.quelle] = doc.generate_scene(st)
			var qw: Node = qs[e.quelle]
			var qsk: Skeleton3D = qw.find_children("*", "Skeleton3D", true, false)[0]
			var qap: AnimationPlayer = qw.find_children("*", "AnimationPlayer", true, false)[0]
			var bq := qsk.get_bone_global_rest(qsk.find_bone("thigh_l")).origin.y - qsk.get_bone_global_rest(qsk.find_bone("foot_l")).origin.y
			var qa := qap.get_animation(e.bew)
			var za := ap.get_animation(name)
			var von: float = e.get("von", 0.0)
			var bis: float = e.get("bis", qa.length)
			var n := int((bis - von) * 30.0) + 1
			var zp := spur(z, Umrechner.bis_wurzel(z, wurzel), za, ZIEL, n, 0.0, za.length, 1.0, e.get("spiegeln", false))
			var qp := spur(qsk, Umrechner.bis_wurzel(qsk, qw), qa, UAL, n, von, bis, bz / bq, false)
			var dt := za.length / maxf(1.0, n - 1)
			var rutsch := 0.0
			var rmax := 0.0
			var qrutsch := 0.0
			var zahl := 0
			var fehler := 0.0
			for s in 2:
				var tief := INF
				for p in qp.fuss:
					tief = minf(tief, p[s].y)
				for i in range(1, n):
					var q0: Vector3 = qp.fuss[i - 1][s]
					var q1: Vector3 = qp.fuss[i][s]
					var vq := Vector2(q1.x - q0.x, q1.z - q0.z).length() / dt
					if vq < 0.15 and q1.y < tief + 0.03:
						var z0: Vector3 = zp.fuss[i - 1][s]
						var z1: Vector3 = zp.fuss[i][s]
						var vz := Vector2(z1.x - z0.x, z1.z - z0.z).length() / dt
						rutsch += vz
						qrutsch += vq
						rmax = maxf(rmax, vz)
						zahl += 1
				var d0: Vector3 = (zp.knoechel[0][s] - zp.becken[0]) - (qp.knoechel[0][s] - qp.becken[0])
				for i in n:
					fehler = maxf(fehler, ((zp.knoechel[i][s] - zp.becken[i]) - (qp.knoechel[i][s] - qp.becken[i]) - d0).length())
			var r := rutsch / maxi(zahl, 1)
			summe[0] += r
			summe[1] += 1
			print("%-28s %7.1f %7.1f %7.1f %4.0f/%-4.0f %6.1f" % [name, r * 100.0, rmax * 100.0, qrutsch / maxi(zahl, 1) * 100.0, zp.knie * 100.0, qp.knie * 100.0, fehler * 100.0])
	print("PRUEFEN fertig, mittleres Rutschen %.1f cm/s über %d Bewegungen" % [summe[0] / maxi(summe[1], 1) * 100.0, summe[1]])
	quit()


# Füße (tiefster Punkt aus Knöchel und Ballen), Knöchel, Becken je Bild; Knie-Anteil. Lagen mal k (Maß des Ziels).
func spur(sk: Skeleton3D, basis: Transform3D, a: Animation, namen: Array, n: int, von: float, bis: float, k: float, gespiegelt: bool) -> Dictionary:
	var idx := namen.map(func(x): return sk.find_bone(x))
	var sp := Umrechner.spuren(a, sk)
	var aus := {"fuss": [], "knoechel": [], "becken": [], "knie": 0.0}
	var schlecht := 0
	var aufrecht := 0
	for i in n:
		var t := von + (bis - von) * i / maxf(1.0, n - 1)
		var g: Array = Umrechner.pose(sk, basis, a, sp, t)
		var fuesse := []
		var knoechel := []
		var becken: Basis = Basis(Umrechner.drehung(g[idx[8]]))
		var oben_v: Vector3 = (g[idx[2]].origin + g[idx[6]].origin) * 0.5
		var hoch: Vector3 = (g[idx[0]].origin + g[idx[4]].origin) * 0.5 - oben_v
		var steht: bool = hoch.normalized().y > 0.8
		if steht:
			aufrecht += 1
		for s in 2:
			var seite := s if not gespiegelt else 1 - s
			var o := seite * 4
			var f: Vector3 = g[idx[o + 2]].origin
			var to: Vector3 = g[idx[o + 3]].origin
			var sx := Vector3(-1, 1, 1) if gespiegelt else Vector3.ONE
			fuesse.append((f if f.y < to.y else to) * k * sx)
			knoechel.append(f * k * sx)
			var h: Vector3 = g[idx[o]].origin
			var kn: Vector3 = g[idx[o + 1]].origin
			# Blickrichtung aus der Hüftlinie (bei beiden Skeletten gleich bestimmt): links − rechts, gekreuzt mit oben
			var quer: Vector3 = g[idx[0]].origin - g[idx[4]].origin
			var vorn := quer.cross(Vector3.UP).normalized()
			var linie := f - h
			var mitte := h + linie * clampf((kn - h).dot(linie) / maxf(0.0001, linie.length_squared()), 0.0, 1.0)
			if steht and (kn - h).angle_to(f - kn) > deg_to_rad(5.0) and (kn - mitte).dot(vorn) < -0.01:
				schlecht += 1
		aus.fuss.append(fuesse)
		aus.knoechel.append(knoechel)
		aus.becken.append((g[idx[8]].origin) * k * (Vector3(-1, 1, 1) if gespiegelt else Vector3.ONE))
	aus.knie = float(schlecht) / maxf(1.0, 2.0 * aufrecht)
	return aus
