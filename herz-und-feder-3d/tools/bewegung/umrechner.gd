extends RefCounted
# Umrechner: überträgt Bewegungen eines fremden Skeletts (Quaternius, Mixamo, SMPL, CMU-BVH …) auf das KayKit-Skelett
# der Fabrikfiguren. Läuft nur beim Bauen (tools/ kommt nicht ins Spiel), ohne Blender.
#
# Verfahren („Weltdrehung übertragen“): Für jeden Knochen der Figur wird ein Knochen der Quelle gewählt (KARTEN). In
# jedem Bild wird gemessen, wie weit sich der Quellknochen gegenüber seiner Ruhelage im Raum gedreht hat, und genau diese
# Drehung bekommt der Zielknochen gegenüber seiner Ruhelage. Weil beide Skelette in Ruhe in derselben T-Haltung stehen,
# ist das unabhängig davon, wie die Knochen intern ausgerichtet sind (Rollwinkel, Achsen). Weicht die Ruhehaltung ab
# (A-Haltung, Arme etwas nach hinten), gleicht eine Schwenkung je Glied das aus (GLIEDER).
# Das Becken wird mit dem Verhältnis der Beinlängen verschoben, die Knöchel werden danach per Zweigelenk-IK genau dorthin
# gesetzt, wo der Knöchel der Quelle (skaliert) steht. Steht der Fuß der Quelle still, steht er auch beim Ziel still.

const KNOCHEN := ["root", "hips", "spine", "chest", "head", "upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "handslot.l",
	"upperarm.r", "lowerarm.r", "wrist.r", "hand.r", "handslot.r", "upperleg.l", "lowerleg.l", "foot.l", "toes.l",
	"upperleg.r", "lowerleg.r", "foot.r", "toes.r"]

# Ziel (KayKit) ← Quelle. Nur die Seite .l ist eingetragen, .r folgt nach Namensregel (RECHTS).
const KARTEN := {
	"ual": {"hips": "pelvis", "spine": "spine_01", "chest": "spine_03", "head": "Head",
		"upperarm.l": "upperarm_l", "lowerarm.l": "lowerarm_l", "wrist.l": "hand_l", "hand.l": "hand_l",
		"upperleg.l": "thigh_l", "lowerleg.l": "calf_l", "foot.l": "foot_l", "toes.l": "ball_l"},
	"mixamo": {"hips": "mixamorig_Hips", "spine": "mixamorig_Spine", "chest": "mixamorig_Spine2", "head": "mixamorig_Head",
		"upperarm.l": "mixamorig_LeftArm", "lowerarm.l": "mixamorig_LeftForeArm", "wrist.l": "mixamorig_LeftHand",
		"hand.l": "mixamorig_LeftHand", "upperleg.l": "mixamorig_LeftUpLeg", "lowerleg.l": "mixamorig_LeftLeg",
		"foot.l": "mixamorig_LeftFoot", "toes.l": "mixamorig_LeftToeBase"},
	"smpl": {"hips": "Pelvis", "spine": "Spine1", "chest": "Spine3", "head": "Head",
		"upperarm.l": "L_Shoulder", "lowerarm.l": "L_Elbow", "wrist.l": "L_Wrist", "hand.l": "L_Wrist",
		"upperleg.l": "L_Hip", "lowerleg.l": "L_Knee", "foot.l": "L_Ankle", "toes.l": "L_Foot"},
	"cmu": {"hips": "Hips", "spine": "LowerBack", "chest": "Spine1", "head": "Head",
		"upperarm.l": "LeftArm", "lowerarm.l": "LeftForeArm", "wrist.l": "LeftHand", "hand.l": "LeftHand",
		"upperleg.l": "LeftUpLeg", "lowerleg.l": "LeftLeg", "foot.l": "LeftFoot", "toes.l": "LeftToeBase"},
	# Gelenkpunkte aus pose_zu_bvh.py (Video, Standbild, Text-zu-Bewegung): dieselben Namen wie SMPL
	"punkte": {"hips": "Pelvis", "spine": "Spine1", "chest": "Spine3", "head": "Head",
		"upperarm.l": "L_Shoulder", "lowerarm.l": "L_Elbow", "wrist.l": "L_Wrist", "hand.l": "L_Wrist",
		"upperleg.l": "L_Hip", "lowerleg.l": "L_Knee", "foot.l": "L_Ankle", "toes.l": "L_Foot"},
}
# Knochen, deren Fehler sich bis zum Fuß aufsummieren: beim Ausdünnen der Schlüssel streng behandeln
const STRENG := ["root", "hips", "upperleg.l", "lowerleg.l", "foot.l", "upperleg.r", "lowerleg.r", "foot.r"]
const RECHTS := [["_l", "_r"], ["Left", "Right"], ["L_", "R_"], [".l", ".r"]]

# Glieder, deren Richtung in Ruhe eine Haltung ist (nicht nur eine Bauweise): Ziel → Zielkind. Wirbelsäule, Becken und
# Füße gehören nicht dazu, dort ist die Lage der Gelenke Bauweise des Skeletts.
const GLIEDER := {"upperarm.l": "lowerarm.l", "lowerarm.l": "wrist.l", "upperleg.l": "lowerleg.l", "lowerleg.l": "foot.l",
	"upperarm.r": "lowerarm.r", "lowerarm.r": "wrist.r", "upperleg.r": "lowerleg.r", "lowerleg.r": "foot.r"}


static func rechts(n: String) -> String:
	for p in RECHTS:
		if n.contains(p[0]):
			return n.replace(p[0], p[1])
	return n


static func gegenseite(n: String) -> String:
	for p in RECHTS:
		if n.contains(p[0]):
			return n.replace(p[0], p[1])
		if n.contains(p[1]):
			return n.replace(p[1], p[0])
	return n


# Volle Karte (beide Seiten) für ein Quellskelett; Namen werden auch mit ":" → "_" und ohne Groß/klein gesucht.
static func karte_fuer(name: String, q: Skeleton3D) -> Dictionary:
	var roh: Dictionary = KARTEN[name]
	var voll := {}
	for z in roh:
		voll[z] = roh[z]
		if z.ends_with(".l"):
			voll[rechts(z)] = rechts(roh[z])
	var aus := {}
	for z in voll:
		var b := finde(q, voll[z])
		if b >= 0:
			aus[z] = q.get_bone_name(b)
	return aus


static func finde(q: Skeleton3D, n: String) -> int:
	var b := q.find_bone(n)
	if b >= 0:
		return b
	for i in q.get_bone_count():
		var m := q.get_bone_name(i)
		if m.replace(":", "_").to_lower() == n.replace(":", "_").to_lower():
			return i
	return -1


# Welche Karte passt am besten zu diesem Skelett?
static func karte_raten(q: Skeleton3D) -> String:
	var beste := ""
	var n := 0
	for k in KARTEN:
		var c := karte_fuer(k, q).size()
		if c > n:
			n = c
			beste = k
	return beste


# Vom Skelett bis zur Wurzel der Szene (Zwischenknoten wie „Armature“ mit Drehung oder Maßstab)
static func bis_wurzel(skel: Skeleton3D, wurzel: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = skel
	while n and n != wurzel:
		if n is Node3D:
			t = n.transform * t
		n = n.get_parent()
	return t


# Spuren einer Animation je Knochen: [Lage, Drehung, Größe] als Spurnummer oder -1
static func spuren(anim: Animation, skel: Skeleton3D) -> Dictionary:
	var sp := {}
	for i in anim.get_track_count():
		var b := skel.find_bone(anim.track_get_path(i).get_concatenated_subnames())
		if b < 0:
			continue
		if not sp.has(b):
			sp[b] = [-1, -1, -1]
		match anim.track_get_type(i):
			Animation.TYPE_POSITION_3D: sp[b][0] = i
			Animation.TYPE_ROTATION_3D: sp[b][1] = i
			Animation.TYPE_SCALE_3D: sp[b][2] = i
	return sp


# Alle Knochen im Raum der Szene zur Zeit t (anim null = Ruhelage)
static func pose(skel: Skeleton3D, basis: Transform3D, anim: Animation, sp: Dictionary, t: float) -> Array:
	var n := skel.get_bone_count()
	var glob := []
	glob.resize(n)
	for b in n:
		_glob(skel, basis, anim, sp, t, b, glob)
	return glob


static func _glob(skel: Skeleton3D, basis: Transform3D, anim: Animation, sp: Dictionary, t: float, b: int, glob: Array) -> Transform3D:
	if glob[b] != null:
		return glob[b]
	var ruhe := skel.get_bone_rest(b)
	var pos := ruhe.origin
	var rot := ruhe.basis.get_rotation_quaternion()
	var scl := ruhe.basis.get_scale()
	if anim and sp.has(b):
		var s: Array = sp[b]
		if s[0] >= 0: pos = anim.position_track_interpolate(s[0], t)
		if s[1] >= 0: rot = anim.rotation_track_interpolate(s[1], t)
		if s[2] >= 0: scl = anim.scale_track_interpolate(s[2], t)
	var lokal := Transform3D(Basis(rot).scaled_local(scl), pos)
	var e := skel.get_bone_parent(b)
	var g: Transform3D = (_glob(skel, basis, anim, sp, t, e, glob) if e >= 0 else basis) * lokal
	glob[b] = g
	return g


static func drehung(t: Transform3D) -> Quaternion:
	return t.basis.orthonormalized().get_rotation_quaternion()


# kürzeste Drehung, die Richtung a auf Richtung b bringt
static func bogen(a: Vector3, b: Vector3) -> Quaternion:
	a = a.normalized()
	b = b.normalized()
	var d := a.dot(b)
	if d > 0.999999:
		return Quaternion.IDENTITY
	if d < -0.999999:
		var ach := a.cross(Vector3.UP)
		if ach.length() < 0.01:
			ach = a.cross(Vector3.RIGHT)
		return Quaternion(ach.normalized(), PI)
	return Quaternion(a.cross(b).normalized(), acos(clampf(d, -1.0, 1.0)))


static func spiegel_q(q: Quaternion) -> Quaternion:
	return Quaternion(q.x, -q.y, -q.z, q.w)


static func spiegel_v(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)


# Hauptfunktion. q: Quellskelett, q_basis: Skelett → Szene, anim: Quellbewegung, karte: Ziel → Quellknochen (voll),
# z: Zielskelett (Ruhelage), z_basis wie q_basis, z_pfad: Knotenpfad der Spuren („Rig/Skeleton3D“).
# opt: fps (30), von/bis (Sekunden der Quelle), tempo (1), schleife (false), auf_der_stelle (false), spiegeln (false),
#      fuesse (true: Knöchel per IK), haltung ({Zielknochen: [x, y, z] Grad}, zusätzliche Drehung im Raum)
# Rückgabe: [Animation, Bericht (Dictionary)]
static func uebertragen(q: Skeleton3D, q_basis: Transform3D, anim: Animation, karte: Dictionary, z: Skeleton3D,
		z_basis: Transform3D, z_pfad: String, opt := {}) -> Array:
	var fps: float = opt.get("fps", 30.0)
	var von: float = opt.get("von", 0.0)
	var bis: float = opt.get("bis", anim.length)
	var tempo: float = opt.get("tempo", 1.0)
	var spiegeln: bool = opt.get("spiegeln", false)
	var stelle: bool = opt.get("auf_der_stelle", false)
	var fuesse: bool = opt.get("fuesse", true)
	var haltung: Dictionary = opt.get("haltung", {})
	var sp := spuren(anim, q)
	var q_ruhe := pose(q, q_basis, null, sp, 0.0)
	var z_ruhe := pose(z, z_basis, null, {}, 0.0)
	var zi := {}   # Zielname → Index
	for n in KNOCHEN:
		zi[n] = z.find_bone(n)
	# Quelle je Zielknochen; beim Spiegeln liefert die Gegenseite der Quelle
	var quelle := {}
	for zn in karte:
		quelle[zn] = q.find_bone(karte[gegenseite(zn)] if spiegeln and karte.has(gegenseite(zn)) else karte[zn])
	var sv := func(v: Vector3) -> Vector3: return spiegel_v(v) if spiegeln else v
	var sq := func(r: Quaternion) -> Quaternion: return spiegel_q(r) if spiegeln else r
	# Ausgleich der Ruhehaltung je Glied: Quellrichtung → Zielrichtung
	var ausgleich := {}
	for zn in GLIEDER:
		var kind: String = GLIEDER[zn]
		if not quelle.has(zn) or not quelle.has(kind):
			continue
		var qa: Vector3 = sv.call(q_ruhe[quelle[kind]].origin - q_ruhe[quelle[zn]].origin)
		var za: Vector3 = z_ruhe[zi[kind]].origin - z_ruhe[zi[zn]].origin
		ausgleich[zn] = bogen(qa, za)
	# Beinlänge: Hüftgelenk bis Knöchel, senkrecht
	var k := 1.0
	if quelle.has("upperleg.l") and quelle.has("foot.l"):
		var lq: float = q_ruhe[quelle["upperleg.l"]].origin.y - q_ruhe[quelle["foot.l"]].origin.y
		var lz: float = z_ruhe[zi["upperleg.l"]].origin.y - z_ruhe[zi["foot.l"]].origin.y
		if lq > 0.01:
			k = lz / lq
	# Länge der Beinknochen (Oberschenkel + Schienbein) im Verhältnis, für Füße in der Luft
	var k_bein := k
	if quelle.has("upperleg.l") and quelle.has("lowerleg.l") and quelle.has("foot.l"):
		var lq: float = (q_ruhe[quelle["lowerleg.l"]].origin - q_ruhe[quelle["upperleg.l"]].origin).length() + (q_ruhe[quelle["foot.l"]].origin - q_ruhe[quelle["lowerleg.l"]].origin).length()
		var lz: float = (z_ruhe[zi["lowerleg.l"]].origin - z_ruhe[zi["upperleg.l"]].origin).length() + (z_ruhe[zi["foot.l"]].origin - z_ruhe[zi["lowerleg.l"]].origin).length()
		if lq > 0.01:
			k_bein = lz / lq
	var hb: int = quelle.get("hips", -1)
	# Abgetastet wird im Takt der Quelle (fps), gedehnt wird nur die Zeitachse: so liegen die Proben auf den Schlüsseln
	# der Quelle, auch bei tempo ≠ 1 (zwischen weit auseinanderliegenden Schlüsseln wäre die Quelle sonst ungenau).
	var n_bilder := maxi(2, int(round((bis - von) * fps)) + 1)
	# Posen zu Bewegung: jedes Bild der Quelle ist eine Schlüsselpose (z. B. aus Standbildern), "zeiten" sagt, wann sie
	# erreicht wird (Sekunden). Dazwischen wird weich übergeblendet (langsam los, schnell durch, sanft an).
	var zeiten_posen: Array = opt.get("zeiten", [])
	if not zeiten_posen.is_empty():
		n_bilder = zeiten_posen.size()
	var bilder := []   # je Bild: Zielname → [lokale Drehung, lokale Lage]
	var weg0 := Vector3.ZERO
	var weg_ende := Vector3.ZERO
	var weg_kurve := PackedVector3Array()
	var tiefst := INF
	var ik_fehler := 0.0
	for i in n_bilder:
		var tq := von + float(i) / (n_bilder - 1) * (bis - von)
		if not zeiten_posen.is_empty():
			# welches Bild der Quelle ist die i-te Schlüsselpose ("posen": Bildnummern, Takt der Quelle "posen_takt")
			var nr: Array = opt.get("posen", range(zeiten_posen.size()))
			tq = minf(float(nr[i]) / float(opt.get("posen_takt", 30.0)), anim.length)
		var g := pose(q, q_basis, anim, sp, tq)
		# Weg über Grund (waagrecht, Becken) für „auf der Stelle“
		var weg := Vector3.ZERO
		if hb >= 0:
			var w: Vector3 = sv.call(g[hb].origin - q_ruhe[hb].origin) * k
			if i == 0:
				weg0 = Vector3(w.x, 0, w.z)
			weg = Vector3(w.x, 0, w.z) - weg0
			weg_ende = weg
		weg_kurve.append(weg)
		var gd := {}   # Zielname → Drehung im Raum
		var gp := {}   # Zielname → Lage im Raum
		for zn in KNOCHEN:
			var b: int = zi[zn]
			var e := z.get_bone_parent(b)
			var en: String = z.get_bone_name(e) if e >= 0 else ""
			var ruhe_l := z.get_bone_rest(b)
			var pd: Quaternion = gd[en] if e >= 0 else drehung(z_basis)
			var pp: Vector3 = gp[en] if e >= 0 else z_basis.origin
			var pt := Transform3D(Basis(pd), pp)
			if quelle.has(zn):
				var s: int = quelle[zn]
				var delta: Quaternion = sq.call(drehung(g[s]) * drehung(q_ruhe[s]).inverse())
				if ausgleich.has(zn):
					delta = delta * ausgleich[zn].inverse()
				gd[zn] = (delta * drehung(z_ruhe[b])).normalized()
			else:
				gd[zn] = (pd * ruhe_l.basis.get_rotation_quaternion()).normalized()
			if haltung.has(zn):
				var h: Array = haltung[zn]
				gd[zn] = (Quaternion.from_euler(Vector3(deg_to_rad(h[0]), deg_to_rad(h[1]), deg_to_rad(h[2]))) * gd[zn]).normalized()
			if zn == "hips" and hb >= 0:
				var d: Vector3 = sv.call(g[hb].origin - q_ruhe[hb].origin) * k
				if stelle:
					d -= weg
				gp[zn] = z_ruhe[b].origin + d
			else:
				gp[zn] = pt * ruhe_l.origin
		if fuesse:
			var ziele := {}
			for s in ["l", "r"]:
				if not quelle.has("foot." + s):
					continue
				var qf: int = quelle["foot." + s]
				var qh: int = quelle["upperleg." + s]
				# Steht der Fuß, bleibt er an seinem Platz im Raum (kein Rutschen). Ist er in der Luft, zählt die Lage
				# zur Hüfte (Streckung des Beins wie in der Quelle, auch bei Rolle und Tritt). Dazwischen weich gemischt.
				var ziel: Vector3 = z_ruhe[zi["foot." + s]].origin + sv.call(g[qf].origin - q_ruhe[qf].origin) * k
				if stelle:
					ziel -= weg
				var zur_huefte: Vector3 = gp["upperleg." + s] + sv.call(g[qf].origin - g[qh].origin) * k_bein
				var hoehe: float = (g[qf].origin.y - q_ruhe[qf].origin.y) * k
				ziele[s] = ziel.lerp(zur_huefte, smoothstep(0.03, 0.15, hoehe))
			# Reicht ein Bein nicht bis zu seinem Ziel (breiter Stand, die Beine der Figur sind anders geteilt), senkt
			# sich das Becken gerade so weit, dass es reicht: lieber etwas tiefer stehen als mit dem Fuß rutschen.
			var senken := 0.0
			for s in ziele:
				var h: Vector3 = gp["upperleg." + s]
				var l: float = ((gp["lowerleg." + s] as Vector3) - h).length() + ((gp["foot." + s] as Vector3) - (gp["lowerleg." + s] as Vector3)).length()
				var v: Vector3 = ziele[s] - h
				var quer2 := v.x * v.x + v.z * v.z
				var lr := l * 0.998
				if v.length() > lr and quer2 < lr * lr and v.y < 0.0:
					senken = maxf(senken, -sqrt(lr * lr - quer2) - v.y)
			if senken > 0.0:
				senken = minf(senken, 0.25)
				for zn in gp:
					if zn != "root":
						gp[zn] = (gp[zn] as Vector3) + Vector3(0, -senken, 0)
			for s in ziele:
				ik_fehler = maxf(ik_fehler, _ik_bein(z, zi, gd, gp, s, ziele[s]))
		for s in ["l", "r"]:
			tiefst = minf(tiefst, (gp["toes." + s] as Vector3).y)
			tiefst = minf(tiefst, (gp["foot." + s] as Vector3).y)
		# in lokale Werte umrechnen
		var lok := {}
		for zn in KNOCHEN:
			var b: int = zi[zn]
			var e := z.get_bone_parent(b)
			var pd: Quaternion = gd[z.get_bone_name(e)] if e >= 0 else drehung(z_basis)
			var pp: Vector3 = gp[z.get_bone_name(e)] if e >= 0 else z_basis.origin
			var lr: Quaternion = (pd.inverse() * gd[zn]).normalized()
			var lp: Vector3 = Basis(pd).inverse() * (gp[zn] - pp)
			lok[zn] = [lr, lp]
		bilder.append(lok)
	if not zeiten_posen.is_empty():
		bilder = _posen_zeitlich(bilder, zeiten_posen, fps * tempo, opt.get("weich", 1.0))
		n_bilder = bilder.size()
		tempo = 1.0
	# Spuren schreiben
	var neu := Animation.new()
	neu.length = (n_bilder - 1) / fps / tempo
	neu.loop_mode = Animation.LOOP_LINEAR if opt.get("schleife", false) else Animation.LOOP_NONE
	var zeiten := PackedFloat32Array()
	for i in n_bilder:
		zeiten.append(i / fps / tempo)
	for zn in KNOCHEN:
		var tr := neu.add_track(Animation.TYPE_ROTATION_3D)
		neu.track_set_path(tr, NodePath(z_pfad + ":" + zn))
		var werte := []
		for i in n_bilder:
			werte.append(bilder[i][zn][0])
		if opt.get("schleife", false):
			werte[n_bilder - 1] = werte[0]
		var tol: float = opt.get("toleranz_grad", 0.8)
		if zn in STRENG:
			tol = minf(tol, opt.get("toleranz_bein_grad", 0.1))
		for i in _ausduennen(zeiten, werte, deg_to_rad(tol), true):
			neu.rotation_track_insert_key(tr, zeiten[i], werte[i])
	var tp := neu.add_track(Animation.TYPE_POSITION_3D)
	neu.track_set_path(tp, NodePath(z_pfad + ":hips"))
	var lagen := []
	for i in n_bilder:
		lagen.append(bilder[i]["hips"][1])
	if opt.get("schleife", false):
		lagen[n_bilder - 1] = lagen[0]
	for i in _ausduennen(zeiten, lagen, opt.get("toleranz_m", 0.001), false):
		neu.position_track_insert_key(tp, zeiten[i], lagen[i])
	if stelle:
		# herausgerechneter Weg über Grund: gesamt und je Bild (Takt fps / tempo), damit das Spiel den Körper genau so
		# weit schieben kann, wie die Füße es verlangen
		neu.set_meta("weg", weg_ende)
		neu.set_meta("weg_kurve", weg_kurve)
		neu.set_meta("weg_takt", fps * tempo)
	var bericht := {"bilder": n_bilder, "k": k, "weg": weg_ende, "tiefst": tiefst, "ik": ik_fehler, "schluessel": _schluessel(neu)}
	return [neu, bericht]


# Schlüsselposen auf eine Zeitachse legen: zwischen Pose i und i+1 wird mit einer S-Kurve übergeblendet (weich 0 =
# gleichmäßig, 1 = volle S-Kurve). Gleiche Zeiten zweimal hintereinander = Pose halten.
static func _posen_zeitlich(posen: Array, zeiten: Array, fps: float, weich: float) -> Array:
	var aus := []
	var ende: float = zeiten[-1]
	var n := int(round(ende * fps)) + 1
	for i in n:
		var t := i / fps
		var j := 0
		while j < zeiten.size() - 2 and t > float(zeiten[j + 1]):
			j += 1
		var t0: float = zeiten[j]
		var t1: float = zeiten[j + 1]
		var f := 0.0 if t1 <= t0 else clampf((t - t0) / (t1 - t0), 0.0, 1.0)
		f = lerpf(f, f * f * (3.0 - 2.0 * f), weich)
		var a: Dictionary = posen[j]
		var b: Dictionary = posen[j + 1]
		var mix := {}
		for zn in a:
			mix[zn] = [(a[zn][0] as Quaternion).slerp(b[zn][0], f), (a[zn][1] as Vector3).lerp(b[zn][1], f)]
		aus.append(mix)
	return aus


static func _schluessel(a: Animation) -> int:
	var s := 0
	for i in a.get_track_count():
		s += a.track_get_key_count(i)
	return s


# Zweigelenk-IK: Oberschenkel und Schienbein so drehen, dass der Knöchel auf ziel liegt; die Knieebene bleibt erhalten.
static func _ik_bein(z: Skeleton3D, zi: Dictionary, gd: Dictionary, gp: Dictionary, s: String, ziel: Vector3) -> float:
	var ob := "upperleg." + s
	var un := "lowerleg." + s
	var fu := "foot." + s
	var to := "toes." + s
	var h: Vector3 = gp[ob]
	var kn: Vector3 = gp[un]
	var an: Vector3 = gp[fu]
	var l1 := (kn - h).length()
	var l2 := (an - kn).length()
	var weg := ziel - h
	var d := clampf(weg.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.0005)
	var u := weg.normalized()
	var alt_u := (an - h).normalized()
	var pol := (kn - h) - alt_u * (kn - h).dot(alt_u)
	if pol.length() < 0.0001:
		pol = Basis(gd["hips"]) * Vector3(0, 0, 1)
	# Pol in die neue Ebene senkrecht zu u bringen
	pol = bogen(alt_u, u) * pol
	pol = (pol - u * pol.dot(u)).normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var hh := sqrt(maxf(0.0, l1 * l1 - a * a))
	var kn_neu := h + u * a + pol * hh
	var an_neu := h + u * d
	var d1 := bogen(kn - h, kn_neu - h)
	gd[ob] = (d1 * gd[ob]).normalized()
	var shin_alt: Vector3 = d1 * (an - kn)
	var d2 := bogen(shin_alt, an_neu - kn_neu)
	gd[un] = (d2 * d1 * gd[un]).normalized()
	gp[un] = kn_neu
	gp[fu] = an_neu
	# Fuß und Zehen behalten ihre Drehung im Raum, nur ihre Lage folgt
	var zl := z.get_bone_rest(zi[to]).origin
	gp[to] = an_neu + Basis(gd[fu]) * zl
	return an_neu.distance_to(ziel)


# Schlüssel ausdünnen: behält nur Bilder, ohne die die Zwischenwerte mehr als tol abweichen würden.
static func _ausduennen(zeiten: PackedFloat32Array, werte: Array, tol: float, ist_drehung: bool) -> Array:
	var n := werte.size()
	var behalten := [0]
	var s := 0
	var e := 2
	while e < n:
		var gut := true
		for j in range(s + 1, e):
			var f := (zeiten[j] - zeiten[s]) / (zeiten[e] - zeiten[s])
			var fehler := 0.0
			if ist_drehung:
				var a: Quaternion = werte[s]
				fehler = a.slerp(werte[e], f).angle_to(werte[j])
			else:
				var a: Vector3 = werte[s]
				fehler = a.lerp(werte[e], f).distance_to(werte[j])
			if fehler > tol:
				gut = false
				break
		if not gut:
			behalten.append(e - 1)
			s = e - 1
		e += 1
	if n > 1:
		behalten.append(n - 1)
	# gleichbleibende Spur: ein Schlüssel genügt
	if behalten.size() == 2:
		var gleich := true
		for j in n:
			var fehler: float = (werte[0] as Quaternion).angle_to(werte[j]) if ist_drehung else (werte[0] as Vector3).distance_to(werte[j])
			if fehler > tol:
				gleich = false
				break
		if gleich:
			return [0]
	return behalten
