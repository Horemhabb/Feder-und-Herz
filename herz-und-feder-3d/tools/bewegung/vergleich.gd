extends SceneTree
# Vergleicht zwei Bewegungen auf derselben Spielfigur Bild für Bild: Winkelfehler je Knochen (im Raum) und Abstand der
# Gelenke. Wozu: Güte eines Weges messen, z. B. „aus Video geschätzt“ gegen „direkt übertragen“ (bekannte Wahrheit).
# Aufruf: godot --headless --path . -s res://tools/bewegung/vergleich.gd -- --satz=probe --a=Kreuz_direkt --b=Kreuz_video [--modell=Eidtraeger]

const Umrechner := preload("res://tools/bewegung/umrechner.gd")
const KNOCHEN := ["hips", "spine", "chest", "head", "upperarm.l", "lowerarm.l", "wrist.l", "upperarm.r", "lowerarm.r",
	"wrist.r", "upperleg.l", "lowerleg.l", "foot.l", "upperleg.r", "lowerleg.r", "foot.r"]

func _init() -> void:
	var modell := "Eidtraeger"
	var satz := "probe"
	var a_name := ""
	var b_name := ""
	for x in OS.get_cmdline_user_args():
		if x.begins_with("--modell="): modell = x.get_slice("=", 1)
		if x.begins_with("--satz="): satz = x.get_slice("=", 1)
		if x.begins_with("--a="): a_name = x.get_slice("=", 1)
		if x.begins_with("--b="): b_name = x.get_slice("=", 1)
	var wurzel: Node = load("res://models/chars/%s.glb" % modell).instantiate()
	var ap: AnimationPlayer = wurzel.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = wurzel.find_children("*", "Skeleton3D", true, false)[0]
	Bewegungen.ergaenzen(ap, sk, satz)
	var a := ap.get_animation(satz + "/" + a_name)
	var b := ap.get_animation(satz + "/" + b_name)
	var spa := Umrechner.spuren(a, sk)
	var spb := Umrechner.spuren(b, sk)
	var basis := Umrechner.bis_wurzel(sk, wurzel)
	var n := 31
	var summe := {}
	var groesst := {}
	var pos_fehler := 0.0
	var pos_summe := 0.0
	for k in KNOCHEN:
		summe[k] = 0.0
		groesst[k] = 0.0
	for i in n:
		var ga: Array = Umrechner.pose(sk, basis, a, spa, a.length * i / (n - 1))
		var gb: Array = Umrechner.pose(sk, basis, b, spb, b.length * i / (n - 1))
		# Becken gleich legen (die Lage im Raum ist nicht Teil des Vergleichs)
		var versatz: Vector3 = ga[sk.find_bone("hips")].origin - gb[sk.find_bone("hips")].origin
		for k in KNOCHEN:
			var j := sk.find_bone(k)
			var w := rad_to_deg(Umrechner.drehung(ga[j]).angle_to(Umrechner.drehung(gb[j])))
			summe[k] += w
			groesst[k] = maxf(groesst[k], w)
			var d: float = ga[j].origin.distance_to(gb[j].origin + versatz)
			pos_fehler = maxf(pos_fehler, d)
			pos_summe += d
	print("%-12s %8s %8s" % ["Knochen", "Mittel°", "größt°"])
	var gesamt := 0.0
	for k in KNOCHEN:
		print("%-12s %8.1f %8.1f" % [k, summe[k] / n, groesst[k]])
		gesamt += summe[k] / n
	print("VERGLEICH %s gegen %s: mittlerer Winkelfehler %.1f°, Gelenke im Mittel %.1f cm, höchstens %.1f cm daneben (Figur 2 m)" % [a_name, b_name, gesamt / KNOCHEN.size(), pos_summe / (n * KNOCHEN.size()) * 100.0, pos_fehler * 100.0])
	quit()
