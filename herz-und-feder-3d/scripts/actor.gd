class_name Actor extends CharacterBody3D
# Gemeinsame Grundlage für Held und Gegner: Modell, Animation, Treffer-Aufblitzen, Rückstoß.
# Die Modelle (KayKit, CC0) schauen entlang +Z. Animationsnamen stehen nur in den ANIM-Tabellen
# von Held und Gegner, damit ein anderes Modell später nur ein Tausch ist.

const LOOPS := ["Unarmed_Idle", "2H_Ranged_Aiming", "Idle", "2H_Melee_Idle", "Running_A", "Running_B", "Walking_A", "Walking_D_Skeletons", "Idle_Combat", "Spellcasting", "2H_Melee_Attack_Spinning"]

var game: Node
var model: Node3D
var ap: AnimationPlayer
var skel: Skeleton3D
var meshes: Array = []
var hp := 100.0
var max_hp := 100.0
var radius := 0.6
var dead := false
var cur_anim := ""
var face := 0.0
var flash_t := 0.0
var kb := Vector3.ZERO
var stun := 0.0
static var flash_mat: StandardMaterial3D

# Bewegungsgefühl: Stehen, Gehen und Laufen folgen dem Tempo über Grund (fortbewegen), Treffer lassen die Figur zucken
var a_idle := ""
var a_walk := ""
var a_run := ""
var gang := {}         # Bewegung → [Tempo über Grund bei Abspieltempo 1 in m/s, Phase, in der der linke Fuß aufsetzt]
var laeuft := false    # zeigt gerade die Laufbewegung (statt Gehen)
var zuck_t := 0.0
var zuck := Vector2.ZERO   # Neigung beim Treffer in Blickrichtung der Figur: x nach vorn, y zur Seite (Bogenmaß)
static var gang_cache := {}   # je Modell und Bewegung einmal berechnet
const ZUCK_DAUER := 0.22

func setup(path: String, scl: float, r: float) -> void:
	model = load(path).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * scl
	radius = r
	ap = model.find_child("AnimationPlayer", true, false)
	skel = model.find_child("Skeleton3D", true, false)
	for n in LOOPS:
		if ap.has_animation(n):
			ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for n in ["Walking_A", "Walking_D_Skeletons", "Running_A"]:
		if ap.has_animation(n) and skel:
			var g: Vector2 = gang_cache.get(path + "|" + n, Vector2(-1, 0))
			if g.x < 0.0:
				g = schritt_tempo(n)
				gang_cache[path + "|" + n] = g
			if g.x > 0.01:
				gang[n] = [g.x * scl, g.y]
	_collect(model)
	var col := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = r
	sh.height = 2.4 * scl
	col.shape = sh
	col.position.y = 1.2 * scl
	add_child(col)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if flash_mat == null:
		flash_mat = StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Treffer blitzen auf, ohne die Figur weiß zu übermalen (3.0): Licht wird aufaddiert, die Textur bleibt sichtbar
		flash_mat.albedo_color = Color(1.0, 0.82, 0.55, 0.42)
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

func _collect(n: Node) -> void:
	if n is MeshInstance3D:
		meshes.append(n)
	for c in n.get_children():
		_collect(c)

func play(anim: String, speed := 1.0, blend := 0.15, restart := false) -> void:
	if ap == null or not ap.has_animation(anim):
		return
	if cur_anim == anim and not restart:
		ap.speed_scale = speed
		return
	cur_anim = anim
	ap.speed_scale = speed
	ap.play(anim, blend)
	if restart:
		ap.seek(0.0, true)

# Schrittlänge aus der Bewegung selbst: Die Bewegungen laufen auf der Stelle, der aufgesetzte Fuß wandert also nach
# hinten, und zwar genau so schnell, wie die Figur über den Boden gehen müsste, damit er stillsteht. Dazu wird die
# Bewegung 48-mal abgetastet (nur aus den Spuren und der Ruhelage, ohne den AnimationPlayer zu stören). Aufgesetzt ist
# der tiefste Punkt aus Knöchel und Ballen beider Füße, solange er nahe am Boden steht.
# Ergebnis: Tempo über Grund in Modellmaß je Sekunde bei Abspieltempo 1, und die Phase (0 bis 1), in der der linke
# Fuß aufsetzt. 0, wenn die Figur keine Füße hat (Ba, Skorpion).
func schritt_tempo(anim_name: String) -> Vector2:
	var punkte := ["foot.l", "toes.l", "foot.r", "toes.r"].map(func(n): return skel.find_bone(n))
	if punkte.has(-1):
		return Vector2.ZERO
	var anim := ap.get_animation(anim_name)
	var spuren := {}   # Knochen → [Lage, Drehung, Größe] (Spurnummer oder -1)
	var kette := []    # alle Knochen von der Wurzel bis zu den Füßen, Eltern zuerst
	for p in punkte:
		var b: int = p
		var teil := []
		while b >= 0 and not kette.has(b) and not teil.has(b):
			teil.push_front(b)
			b = skel.get_bone_parent(b)
		kette.append_array(teil)
	for b in kette:
		var s := [-1, -1, -1]
		for i in anim.get_track_count():
			if anim.track_get_path(i).get_concatenated_subnames() == skel.get_bone_name(b):
				match anim.track_get_type(i):
					Animation.TYPE_POSITION_3D: s[0] = i
					Animation.TYPE_ROTATION_3D: s[1] = i
					Animation.TYPE_SCALE_3D: s[2] = i
		spuren[b] = s
	# vom Skelett bis zum Modell (Zwischenknoten der Vorlage)
	var bis_modell := Transform3D.IDENTITY
	var n: Node = skel
	while n and n != model:
		if n is Node3D:
			bis_modell = n.transform * bis_modell
		n = n.get_parent()
	var N := 48
	var proben := []   # [tiefster Punkt im Modell, welcher, Zeit]
	for k in N + 1:
		var t := anim.length * k / N
		var glob := {}
		for b in kette:
			var ruhe := skel.get_bone_rest(b)
			var s: Array = spuren[b]
			var pos: Vector3 = anim.position_track_interpolate(s[0], t) if s[0] >= 0 else ruhe.origin
			var rot: Quaternion = anim.rotation_track_interpolate(s[1], t) if s[1] >= 0 else ruhe.basis.get_rotation_quaternion()
			var scl: Vector3 = anim.scale_track_interpolate(s[2], t) if s[2] >= 0 else ruhe.basis.get_scale()
			var lokal := Transform3D(Basis(rot) * Basis.from_scale(scl), pos)
			var eltern := skel.get_bone_parent(b)
			glob[b] = glob[eltern] * lokal if glob.has(eltern) else lokal
		var tief := Vector3(0, INF, 0)
		var welcher := -1
		for p in punkte:
			var q: Vector3 = bis_modell * glob[p].origin
			if q.y < tief.y:
				tief = q
				welcher = p
		proben.append([tief, welcher, t])
	var boden := INF
	for p in proben:
		boden = minf(boden, p[0].y)
	var schritte := []   # Wege des aufgesetzten Fußes je Abtastung: [Weg im Modell, Zeit]
	var links := -1.0
	for i in range(1, proben.size()):
		var a: Array = proben[i - 1]
		var b: Array = proben[i]
		if a[1] == b[1] and a[0].y < boden + 0.04 and b[0].y < boden + 0.04:
			schritte.append([b[0] - a[0], b[2] - a[2]])
		if links < 0.0 and (b[1] == punkte[0] or b[1] == punkte[1]) and not (a[1] == punkte[0] or a[1] == punkte[1]):
			links = float(i) / N
	if schritte.is_empty():
		return Vector2.ZERO
	# Das Tempo, bei dem der aufgesetzte Fuß am wenigsten über den Boden wandert (Modelle schauen entlang +Z).
	# Gesucht statt gemittelt: Beim Gehen rollt der Fuß ab, ein Mittelwert läge dort ein Viertel zu hoch.
	var bestes := 0.0
	var wenigst := INF
	for k in 400:
		var v := k * 0.04
		var rutsch := 0.0
		for st in schritte:
			rutsch += Vector2(st[0].x, st[0].z + v * st[1]).length()
		if rutsch < wenigst:
			wenigst = rutsch
			bestes = v
	return Vector2(bestes, maxf(links, 0.0))

# Stehen, Gehen oder Laufen nach dem Tempo über Grund. soll: gewolltes Tempo ohne Rückstoß; das wirkliche Tempo
# (an einer Mauer weniger) begrenzt es. Das Abspieltempo folgt der Schrittlänge, damit die Füße nicht rutschen.
# Zwischen Gehen und Laufen liegt eine Schwelle mit etwas Spiel, damit es nicht hin und her springt; beim Wechsel
# setzt die neue Bewegung mit demselben Fuß fort und wird kurz überblendet.
# ersatz, ersatz_anim: Abspieltempo und Bewegung für Figuren ohne gemessene Schritte (Ba, Skorpion), wie bisher.
# mindest_takt: kleinstes Abspieltempo beim Laufen. Die Laufbewegung der Modelle ist ein Sprint (gut vier Meter je
# Schritt); auf das Tempo der Figur gebremst, wirkt sie wie Zeitlupe und schwebt zwischen den Schritten. Mit einer
# Untergrenze bleibt der Takt lebendig, dafür rutscht der Fuß beim Aufsetzen ein wenig. Dann wird auch früher vom
# Gehen ins Laufen gewechselt, damit das Gehen nicht hastig trippelt.
func fortbewegen(soll: float, ersatz := 1.0, ersatz_anim := "", mindest_takt := 0.0) -> void:
	var v := minf(soll, Vector2(get_real_velocity().x, get_real_velocity().z).length() + 0.3)
	if v < 0.35:
		play(a_idle, 1.0, 0.2)
		laeuft = false
		return
	if not gang.has(a_run):
		play(ersatz_anim if ersatz_anim != "" and ap and ap.has_animation(ersatz_anim) else a_run, ersatz)
		return
	var g_lauf: float = gang[a_run][0]
	if gang.has(a_walk):
		var g_geh: float = gang[a_walk][0]
		var schwelle := minf(g_geh * 1.4, g_lauf) if mindest_takt > 0.0 else sqrt(g_geh * g_lauf)
		laeuft = v > schwelle * (0.9 if laeuft else 1.1)
	else:
		laeuft = true
	var anim := a_run if laeuft else a_walk
	var tempo := clampf(v / gang[anim][0], mindest_takt if laeuft else 0.3, 2.6)
	if cur_anim != anim and (cur_anim == a_run or cur_anim == a_walk) and gang.has(cur_anim):
		# im Schritt bleiben: die Phase des alten Laufs auf den neuen übertragen
		var alt: Animation = ap.get_animation(cur_anim)
		var phase := fposmod(ap.current_animation_position / alt.length - gang[cur_anim][1] + gang[anim][1], 1.0)
		play(anim, tempo, 0.25)
		ap.seek(phase * anim_len(anim), false)
	else:
		play(anim, tempo, 0.2)

# Treffer-Zucken: Die Figur kippt kurz vom Treffer weg und federt zurück, ohne dass die laufende Bewegung abbricht.
# staerke 1 für einen gewöhnlichen Treffer, mehr für schwere.
func zucken(von: Vector3, staerke := 1.0) -> void:
	if model == null:
		return
	var d := flat(global_position - von)
	if d.length() < 0.01:
		d = -forward()
	d = d.normalized().rotated(Vector3.UP, -model.rotation.y)
	zuck = Vector2(d.z, d.x) * 0.28 * clampf(staerke, 0.5, 1.8)
	zuck_t = ZUCK_DAUER

# Wo steht die laufende Geh- oder Laufbewegung (0 bis 1)? -1, wenn gerade keine mit gemessenen Schritten läuft.
func gang_phase() -> float:
	if ap == null or not gang.has(cur_anim) or ap.current_animation != cur_anim:
		return -1.0
	return fposmod(ap.current_animation_position / anim_len(cur_anim), 1.0)

func anim_len(anim: String) -> float:
	return ap.get_animation(anim).length if ap and ap.has_animation(anim) else 0.6

func turn(delta: float, rate := 14.0) -> void:
	model.rotation.y = lerp_angle(model.rotation.y, face, minf(1.0, delta * rate))

func look_to(p: Vector3) -> void:
	var d := p - global_position
	if d.x * d.x + d.z * d.z > 0.0001:
		face = atan2(d.x, d.z)

func forward() -> Vector3:
	return Vector3(sin(face), 0, cos(face))

func flash() -> void:
	flash_t = 0.1
	for m in meshes:
		m.material_overlay = flash_mat

func tick_common(delta: float) -> void:
	if flash_t > 0.0:
		flash_t -= delta
		if flash_t <= 0.0:
			for m in meshes:
				m.material_overlay = null
	if zuck_t > 0.0:
		# schnell weg, langsam zurück: die Neigung steigt im ersten Fünftel an und klingt dann aus
		zuck_t -= delta
		var e := maxf(zuck_t, 0.0) / ZUCK_DAUER
		var k := minf(1.0, (1.0 - e) * 5.0) * e * e
		model.rotation.x = zuck.x * k
		model.rotation.z = -zuck.y * k
	kb = kb.move_toward(Vector3.ZERO, delta * 40.0)
	if stun > 0.0:
		stun -= delta

func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)

func attach(bone: String, node: Node3D) -> bool:
	var idx := skel.find_bone(bone)
	if idx < 0:
		return false
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	ba.add_child(node)
	return true
