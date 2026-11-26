class_name Physik
# 3D-Physik in der Welt (4.2): Besiegte fallen als Gliederpuppe (Ragdoll) in Richtung des letzten Schlags,
# zerschlagene Krüge und Kisten zerspringen in Scherben. Beides ist kurz, gezählt und räumt sich selbst auf:
# - Fall: zwölf Körper (Becken, Rücken, Brust, Kopf, Ober- und Unterarme, Ober- und Unterschenkel) mit begrenzten Gelenken.
#   Höchstens FALL_MAX zugleich, nach FALL_DAUER Sekunden wird die Haltung eingefroren und die Körper verschwinden;
#   danach liegt die Figur wie bisher, bis sie im Boden versinkt (foe.gd). Sonst und bei „Grafik niedrig“: die
#   Todesbewegung wie bisher.
# - Scherben: sechs bis neun kleine Körper im Material des Requisits, höchstens SCHERBEN_MAX zugleich, nach gut zwei
#   Sekunden fort.
# Beides prallt an einem unsichtbaren Boden (Ebene 10) und an Mauern (Ebene 1) ab, nicht aneinander und nicht an
# Figuren. Die Ebenen 10 bis 12 sind nur für diese Physik da.

const BODEN := 512        # Ebene 10: unsichtbarer Boden bei y = 0
const PUPPE := 1024       # Ebene 11: Glieder der Gliederpuppen
const SPLITTER := 2048    # Ebene 12: Scherben
const FALL_MAX := 4
const FALL_DAUER := 2.4
const SCHERBEN_MAX := 54

# Glied → [Knochen, an dem es endet (leer: eigene Länge), Kegel des Gelenks in Grad, Dicke im Verhältnis zur Länge]
const GLIEDER := [
	["hips", "spine", 0.0, 0.9], ["spine", "chest", 25.0, 0.8], ["chest", "head", 25.0, 0.7], ["head", "", 40.0, 0.45],
	["upperarm.l", "lowerarm.l", 70.0, 0.26], ["lowerarm.l", "wrist.l", 80.0, 0.22],
	["upperarm.r", "lowerarm.r", 70.0, 0.26], ["lowerarm.r", "wrist.r", 80.0, 0.22],
	["upperleg.l", "lowerleg.l", 45.0, 0.24], ["lowerleg.l", "foot.l", 75.0, 0.2],
	["upperleg.r", "lowerleg.r", 45.0, 0.24], ["lowerleg.r", "foot.r", 75.0, 0.2],
]

static var faelle := 0         # laufende Gliederpuppen
static var scherben_n := 0     # liegende Scherben
static var boden_n: StaticBody3D
static var scherb_mesh: ArrayMesh
static var gezaehlt := {"faelle": 0, "scherben": 0}   # für die Prüfungen: wie viele es insgesamt gab

static func _boden(welt: Node) -> void:
	if is_instance_valid(boden_n) and boden_n.is_inside_tree():
		return
	boden_n = StaticBody3D.new()
	boden_n.name = "PhysikBoden"
	boden_n.collision_layer = BODEN
	boden_n.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	boden_n.add_child(cs)
	welt.add_child(boden_n)

static func erlaubt(game) -> bool:
	return game != null and not game.get("low_gfx")

# ---------------------------------------------------------------- Fall als Gliederpuppe
# a: der Besiegte (Actor). stoss: Wucht in m/s (waagrecht), meist sein Rückstoß im Moment des Todes.
# Gibt false zurück, wenn kein Platz ist oder die Figur kein passendes Skelett hat (dann bleibt die Todesbewegung).
static func fallen(a: Node3D, stoss: Vector3) -> bool:
	var sk: Skeleton3D = a.skel
	if sk == null or faelle >= FALL_MAX or not erlaubt(a.game) or not a.is_inside_tree():
		return false
	for g in GLIEDER:
		if sk.find_bone(g[0]) < 0 or (g[1] != "" and sk.find_bone(g[1]) < 0):
			return false
	_boden(a.get_parent())
	var sim := PhysicalBoneSimulator3D.new()
	sim.name = "Fall"
	sk.add_child(sim)
	var koerper := {}
	for g in GLIEDER:
		var i := sk.find_bone(g[0])
		var laenge: Vector3 = sk.get_bone_rest(sk.find_bone(g[1])).origin if g[1] != "" else Vector3(0, 0.32, 0)
		var halb := laenge.length() * 0.5
		var pb := PhysicalBone3D.new()
		pb.name = "G_" + g[0]
		pb.bone_name = g[0]
		var form := CapsuleShape3D.new()
		form.radius = maxf(0.05, halb * 2.0 * g[3] * 0.5)
		form.height = maxf(form.radius * 2.0 + 0.01, halb * 2.0)
		var cs := CollisionShape3D.new()
		cs.shape = form
		# wie der Editor („Physikalisches Skelett erzeugen“): Kapsel entlang des Knochens, Gelenk an seinem Ursprung
		cs.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3.ZERO)
		pb.add_child(cs)
		var oben := Vector3.UP if not Vector3.UP.cross(laenge).is_zero_approx() else Vector3.BACK
		var bt := Transform3D(Basis.looking_at(laenge, oben), Vector3.ZERO)
		bt.origin = bt.basis * Vector3(0, 0, -halb)
		pb.body_offset = bt
		pb.joint_offset = Transform3D(Basis.IDENTITY, Vector3(0, 0, halb))
		if g[2] > 0.0:
			# Kegelgelenke (CONE) schaukeln sich in Godots Physik an Mauern auf und schleuderten Körper hoch in die Luft;
			# sechs Achsen mit Grenzen bleiben ruhig (Probe mit Mauer neben der Figur)
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
			for ax in ["x", "y", "z"]:
				var span: float = g[2] if ax != "z" else 15.0
				pb.set("joint_constraints/%s/angular_limit_enabled" % ax, true)
				pb.set("joint_constraints/%s/angular_limit_upper" % ax, span)
				pb.set("joint_constraints/%s/angular_limit_lower" % ax, -span)
		else:
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
		pb.mass = 3.0 if i == sk.find_bone("hips") or i == sk.find_bone("chest") else 1.0
		pb.friction = 0.9
		pb.linear_damp = 1.2
		pb.angular_damp = 3.0
		pb.collision_layer = PUPPE
		pb.collision_mask = BODEN | 1
		sim.add_child(pb)
		if a is PhysicsBody3D:
			pb.add_collision_exception_with(a)   # nicht an der eigenen Kapsel abprallen
		koerper[g[0]] = pb
	faelle += 1
	gezaehlt.faelle += 1
	if a.get("koerper"):
		a.koerper.active = false
	if a.ap:
		a.ap.speed_scale = 0.0   # Hände und Füße bleiben, wie sie sind; den Rest trägt die Physik
	sim.physical_bones_start_simulation()
	# Wucht: waagrecht nach dem Schlag, dazu etwas Auftrieb und eine kleine Drehung, damit nicht jeder gleich fällt
	var w := (Vector3(stoss.x, 0, stoss.z) * 0.45).limit_length(5.0)
	if w.length() < 1.5:
		w = (w.normalized() if w.length() > 0.01 else -Vector3(sin(a.face), 0, cos(a.face))) * 1.5
	var hoch := 1.2 + w.length() * 0.25
	for n in koerper:
		var pb: PhysicalBone3D = koerper[n]
		var f := 1.25 if n == "chest" or n == "head" else (0.8 if n.begins_with("upperleg") or n.begins_with("lowerleg") else 1.0)
		pb.linear_velocity = (w * f + Vector3(0, hoch, 0))
		pb.angular_velocity = Vector3(randf_range(-2, 2), randf_range(-3, 3), randf_range(-2, 2))
	a.get_tree().create_timer(FALL_DAUER, false, true).timeout.connect(func(): _einfrieren(a, sim, koerper))
	return true

# Haltung der Glieder in die Knochen schreiben, Animation anhalten, Körper entfernen
static func _einfrieren(a: Node3D, sim: PhysicalBoneSimulator3D, koerper: Dictionary) -> void:
	faelle = maxi(0, faelle - 1)
	if not is_instance_valid(a) or not is_instance_valid(sim):
		return
	var sk: Skeleton3D = a.skel
	var inv := sk.global_transform.affine_inverse()
	var glob := {}
	for g in GLIEDER:
		var pb: PhysicalBone3D = koerper[g[0]]
		glob[g[0]] = inv * pb.global_transform * pb.body_offset.affine_inverse()
	# Sicherung: ist die Puppe dennoch weit weg geflogen, bleibt die Todesbewegung (wie ohne Physik)
	var huefte: Transform3D = glob["hips"]
	if huefte.origin.y > 2.5 or Vector2(huefte.origin.x, huefte.origin.z).length() > 14.0 or not huefte.origin.is_finite():
		sim.physical_bones_stop_simulation()
		sim.queue_free()
		if a.ap:
			a.ap.speed_scale = 1.0
			a.ap.seek(a.ap.current_animation_length, true)
		return
	if a.ap:
		a.ap.active = false
	for g in GLIEDER:
		var i := sk.find_bone(g[0])
		var eltern := sk.get_bone_parent(i)
		var pname := sk.get_bone_name(eltern) if eltern >= 0 else ""
		var pg: Transform3D = glob[pname] if glob.has(pname) else (sk.get_bone_global_pose(eltern) if eltern >= 0 else Transform3D.IDENTITY)
		var lokal: Transform3D = pg.affine_inverse() * glob[g[0]]
		sk.set_bone_pose_rotation(i, lokal.basis.get_rotation_quaternion())
		sk.set_bone_pose_position(i, lokal.origin)
	sim.physical_bones_stop_simulation()
	sim.queue_free()

# ---------------------------------------------------------------- Scherben
# n: das zerschlagene Requisit (MeshInstance3D), von: Mitte des Schlags. Höchstens SCHERBEN_MAX liegen zugleich.
static func scherben(welt: Node, n: Node3D, von: Vector3) -> int:
	if not (n is MeshInstance3D) or n.mesh == null or not n.is_inside_tree() or scherben_n >= SCHERBEN_MAX:
		return 0
	var game = welt
	if not erlaubt(game):
		return 0
	_boden(welt)
	var mi: MeshInstance3D = n
	var aabb: AABB = mi.global_transform * mi.get_aabb()
	var mat: Material = mi.get_active_material(0)
	if scherb_mesh == null:
		scherb_mesh = _scherbe()
	var zahl := mini(randi_range(6, 9), SCHERBEN_MAX - scherben_n)
	var mitte := aabb.get_center()
	var groesse := clampf(aabb.size.length() * 0.16, 0.1, 0.34)
	for k in zahl:
		var rb := RigidBody3D.new()
		rb.collision_layer = SPLITTER
		rb.collision_mask = BODEN | 1
		rb.mass = 0.3
		rb.angular_damp = 1.0
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3.ONE * groesse * 0.8
		cs.shape = bx
		rb.add_child(cs)
		var m := MeshInstance3D.new()
		m.mesh = scherb_mesh
		m.scale = Vector3(randf_range(0.6, 1.2), randf_range(0.4, 1.0), randf_range(0.6, 1.2)) * groesse
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rb.add_child(m)
		welt.add_child(rb)
		var p := mitte + Vector3(randf_range(-0.5, 0.5) * aabb.size.x, randf_range(0.0, 0.8) * aabb.size.y - aabb.size.y * 0.3, randf_range(-0.5, 0.5) * aabb.size.z)
		p.y = maxf(p.y, groesse)
		rb.global_position = p
		rb.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var weg := Vector3(p.x - von.x, 0, p.z - von.z)
		if weg.length() < 0.05:
			weg = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		rb.linear_velocity = weg.normalized() * randf_range(2.5, 5.0) + Vector3(0, randf_range(2.5, 5.0), 0)
		rb.angular_velocity = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		scherben_n += 1
		gezaehlt.scherben += 1
		var tw := rb.create_tween()
		tw.tween_interval(randf_range(1.6, 2.2))
		tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.4).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): scherben_n = maxi(0, scherben_n - 1); rb.queue_free())
	return zahl

# eine kantige Scherbe: ein flacher, schiefer Keil (einmal gebaut, von allen geteilt)
static func _scherbe() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := [Vector3(-0.5, -0.15, -0.4), Vector3(0.55, -0.15, -0.2), Vector3(0.0, -0.15, 0.5), Vector3(0.1, 0.25, 0.0)]
	var mitte: Vector3 = (p[0] + p[1] + p[2] + p[3]) / 4.0
	for t in [[0, 2, 1], [0, 1, 3], [1, 2, 3], [2, 0, 3]]:
		var nrm: Vector3 = (p[t[1]] - p[t[0]]).cross(p[t[2]] - p[t[0]]).normalized()
		var fl: Vector3 = (p[t[0]] + p[t[1]] + p[t[2]]) / 3.0 - mitte
		var tt: Array = t
		if nrm.dot(fl) > 0.0:
			tt = [t[0], t[2], t[1]]   # Vorderseite im Uhrzeigersinn (Godot): das Kreuzprodukt zeigt nach innen
		else:
			nrm = -nrm
		for j in 3:
			st.set_normal(nrm)
			st.set_uv(Vector2(p[tt[j]].x + 0.5, p[tt[j]].z + 0.5) * 0.3)
			st.add_vertex(p[tt[j]])
	return st.commit()
