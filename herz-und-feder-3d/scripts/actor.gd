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
		flash_mat.albedo_color = Color(1, 0.95, 0.85, 0.75)
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

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
