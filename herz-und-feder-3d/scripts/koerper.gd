class_name Koerper extends SkeletonModifier3D
# Körperschicht (4.2): legt sich nach dem AnimationPlayer über die Knochen und gibt jeder Figur ihre eigene
# Körpersprache, ohne neue Bewegungen zu brauchen. Alles sind kleine Drehungen auf die laufende Bewegung:
# - Neigung: in Lauf und Beschleunigung nach vorn, in die Kurve zur Seite; eine Feder mit Masse sorgt dafür, dass
#   der schwere Eidträger beim Anhalten nachschwingt und der Priester sofort steht.
# - Haltung: Oberkörper, Kopf und Schultern je Klasse (aufrecht, gebeugt, Arme breit oder eng).
# - Atem im Stand, Blick: Kopf und Brust folgen dem Ziel (Held: Mauszeiger, Gegner: Held).
# - Treffer: der Oberkörper federt vom Schlag weg (statt die ganze Figur zu kippen).
# - Sonderbewegungen für die Ausweichschritte: Satz (Sprung mit Bogen), Gleiten (tief vorgebeugt), Schweben im Stand.
# Die Werte stehen als Profil in klassen.gd › GANG (Helden) und unten in GEGNER. Kosten: rund ein Dutzend
# Quaternionen je Figur und Bild; fern der Kamera und bei „Grafik niedrig“ schaltet Actor die Schicht für Gegner ab.

const GEGNER := {
	"vor": 0.10, "traeg": 0.010, "kurve": 0.012, "feder": 90.0, "daempf": 12.0,
	"brust": 0.04, "kopf": 0.0, "arme": 0.0, "atem": 0.012, "blick": 0.8, "schweben": 0.0, "treffer": 1.0,
}

var akteur: Node3D          # die Figur (Actor); untypisiert, damit Actor und Koerper sich nicht gegenseitig laden
var P: Dictionary = GEGNER
var b := {}                 # Knochennummern
var neig := Vector2.ZERO    # Neigung vor/zur Seite (Bogenmaß), mit Feder
var neig_v := Vector2.ZERO
var stoss := Vector2.ZERO   # Treffer: Oberkörper vom Schlag weg
var stoss_v := Vector2.ZERO
var blick := 0.0            # Drehung von Brust und Kopf zum Ziel
var atem_t := randf() * TAU
var v_alt := Vector3.ZERO
var acc := Vector3.ZERO     # geglättete Beschleunigung im Körpermaß (x Seite, z vorn)
var ziel = null             # Vector3 oder null: wohin die Figur schaut
var satz_t := -1.0          # laufender Satz: Zeit seit Beginn, Dauer, Höhe
var satz_dauer := 0.3
var satz_hoehe := 0.0
var gleiten := 0.0          # 0 bis 1: tief vorgebeugt gleiten (Wind des Schu)
var schwebe := 0.0          # 0 bis 1: wie weit die Figur gerade schwebt
var bewegt := 0.0           # 0 bis 1: Anteil der vollen Laufbewegung (für Atem und Schweben)

func _init() -> void:
	name = "Koerper"

func bereit(sk: Skeleton3D) -> bool:
	for n in ["root", "hips", "spine", "chest", "head", "upperarm.l", "upperarm.r"]:
		var i := sk.find_bone(n)
		if i < 0:
			return false
		b[n] = i
	return true

func profil(p: Dictionary) -> void:
	P = GEGNER.duplicate()
	P.merge(p, true)

func treffer(richtung_lokal: Vector2, staerke: float) -> void:
	# richtung_lokal: wohin der Schlag die Figur drückt (x Seite, y vorn), staerke 1 = gewöhnlicher Treffer
	stoss_v += richtung_lokal.normalized() * 6.5 * clampf(staerke, 0.4, 2.0) * float(P.treffer)

func satz(dauer: float, hoehe: float) -> void:
	satz_t = 0.0
	satz_dauer = dauer
	satz_hoehe = hoehe

func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or akteur == null or b.is_empty() or delta <= 0.0:
		return
	var model: Node3D = akteur.model
	var dreh: float = model.rotation.y
	# Tempo und Beschleunigung im Körpermaß (Modelle schauen entlang +z)
	var v: Vector3 = akteur.velocity
	v.y = 0.0
	var a_roh := (v - v_alt) / maxf(delta, 1.0 / 120.0)
	v_alt = v
	acc = acc.lerp(a_roh.limit_length(60.0), minf(1.0, delta * 14.0))
	var a_lok := acc.rotated(Vector3.UP, -dreh)
	var v_lok := v.rotated(Vector3.UP, -dreh)
	var tempo := v.length()
	bewegt = move_toward(bewegt, clampf(tempo / 5.0, 0.0, 1.0), delta * 4.0)
	# Feder der Neigung: Ziel aus Tempo (vor) und Beschleunigung (Trägheit: Bremsen kippt nach vorn, Kurve zur Seite)
	var soll := Vector2(
		float(P.vor) * clampf(v_lok.z / 7.0, -0.5, 1.2) - float(P.traeg) * a_lok.z,
		float(P.kurve) * a_lok.x)
	soll.x = clampf(soll.x, -0.35, 0.45)
	soll.y = clampf(soll.y, -0.3, 0.3)
	var k: float = P.feder
	var c: float = P.daempf
	# Federn in kleinen Schritten rechnen: bei stockendem Bild (langes delta) schaukelten sie sich sonst auf
	var rest := minf(delta, 0.1)
	while rest > 0.0:
		var h := minf(rest, 1.0 / 120.0)
		rest -= h
		neig_v += ((soll - neig) * k - neig_v * c) * h
		neig += neig_v * h
		stoss_v += (-stoss * 160.0 - stoss_v * 13.0) * h
		stoss += stoss_v * h
	neig = neig.clamp(Vector2(-0.5, -0.4), Vector2(0.6, 0.4))
	stoss = stoss.limit_length(0.6)
	# Blick zum Ziel: Winkel gegen die Blickrichtung des Körpers, begrenzt
	var blick_soll := 0.0
	if ziel != null:
		var d: Vector3 = ziel - akteur.global_position
		if d.x * d.x + d.z * d.z > 1.0:
			blick_soll = clampf(wrapf(atan2(d.x, d.z) - dreh, -PI, PI), -float(P.blick), float(P.blick))
	blick = lerpf(blick, blick_soll, minf(1.0, delta * 6.0))
	atem_t += delta * (1.6 + 1.4 * bewegt)
	var atem := sin(atem_t) * float(P.atem) * (1.0 - bewegt)
	# Schweben (Sternleserin im Stand), Satz (Jägerin), Gleiten (Priester)
	var schwebe_soll := float(P.schweben) * (1.0 - bewegt)
	schwebe = move_toward(schwebe, schwebe_soll, delta * (0.6 if schwebe_soll > schwebe else 4.0))   # setzt beim Loslaufen rasch auf
	var hoch := schwebe * (0.07 + 0.03 * sin(atem_t * 0.7))
	var kipp_satz := 0.0
	if satz_t >= 0.0:
		satz_t += delta
		var u := satz_t / satz_dauer
		if u >= 1.0:
			satz_t = -1.0
		else:
			hoch += 4.0 * u * (1.0 - u) * satz_hoehe
			kipp_satz = -0.35 * sin(u * PI)   # im Flug nach hinten gelehnt
	gleiten = move_toward(gleiten, 0.0, delta * 2.5)
	# ---- auf die Knochen legen
	# ganze Figur: Seitenneigung (um die Füße), Satz-Höhe
	var wurzel: int = b.root
	_dreh_global(sk, wurzel, Quaternion(Vector3.FORWARD, neig.y) * Quaternion(Vector3.RIGHT, kipp_satz * 0.3))
	if hoch != 0.0:
		sk.set_bone_pose_position(wurzel, sk.get_bone_pose_position(wurzel) + _lokal_verschub(sk, wurzel, Vector3(0, hoch, 0)))
	# Oberkörper: Haltung, Vorneigung, Atem, Treffer, Gleiten, Blick
	var vor := neig.x + gleiten * 0.7 + kipp_satz * 0.5
	var sp := Quaternion(Vector3.RIGHT, vor * 0.4 + stoss.y * 0.5) * Quaternion(Vector3.FORWARD, stoss.x * 0.5)
	var br := Quaternion(Vector3.UP, blick * 0.35) * Quaternion(Vector3.RIGHT, float(P.brust) + vor * 0.6 + atem + stoss.y * 0.5) * Quaternion(Vector3.FORWARD, stoss.x * 0.5)
	_dreh_global(sk, b.spine, sp)
	_dreh_global(sk, b.chest, br)
	_dreh_global(sk, b.head, Quaternion(Vector3.UP, blick * 0.55) * Quaternion(Vector3.RIGHT, float(P.kopf) - vor * 0.5 - atem * 0.5))
	# Schultern: Arme breiter oder enger, beim Gleiten nach hinten gestreckt
	var arm: float = float(P.arme) + atem * 0.5
	if absf(arm) > 0.001 or gleiten > 0.01:
		_dreh_global(sk, b["upperarm.l"], Quaternion(Vector3.BACK, arm) * Quaternion(Vector3.RIGHT, gleiten * 0.9))
		_dreh_global(sk, b["upperarm.r"], Quaternion(Vector3.BACK, -arm) * Quaternion(Vector3.RIGHT, gleiten * 0.9))

# Einen Knochen um eine Drehung im Raum des Skeletts drehen (um seinen eigenen Ursprung):
# neu = lokal · G⁻¹ · R · G, mit G der Drehung des Knochens im Skelett.
func _dreh_global(sk: Skeleton3D, i: int, r: Quaternion) -> void:
	var g := sk.get_bone_global_pose(i).basis.get_rotation_quaternion()
	var l := sk.get_bone_pose_rotation(i)
	sk.set_bone_pose_rotation(i, (l * g.inverse() * r * g).normalized())

func _lokal_verschub(sk: Skeleton3D, i: int, v: Vector3) -> Vector3:
	var eltern := sk.get_bone_parent(i)
	if eltern < 0:
		return v
	return sk.get_bone_global_pose(eltern).basis.inverse() * v
