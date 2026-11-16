extends SceneTree
# Liest Animationsnamen und Maße der Modelle aus (nur zum Nachsehen).
func _aabb(n: Node, acc: Array, xf: Transform3D):
	if n is Node3D: xf = xf * n.transform
	if n is MeshInstance3D:
		var a: AABB = xf * n.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children(): _aabb(c, acc, xf)
func _init():
	for f in ["Knight", "Skeleton_Warrior", "Skeleton_Minion", "Skeleton_Mage"]:
		var s = load("res://models/chars/%s.glb" % f).instantiate()
		var acc = [null]; _aabb(s, acc, Transform3D.IDENTITY)
		print("== ", f, " ", acc[0])
		var ap: AnimationPlayer = s.find_child("AnimationPlayer", true, false)
		if ap:
			var names = ap.get_animation_list()
			print(names.size(), " Animationen: ", ", ".join(names))
			for nm in ["Idle", "Running_A", "Walking_A", "1H_Melee_Attack_Chop", "2H_Melee_Attack_Chop", "Death_A", "Hit_A"]:
				if ap.has_animation(nm): print("  ", nm, " ", snapped(ap.get_animation(nm).length, 0.01), "s loop=", ap.get_animation(nm).loop_mode)
		var sk: Skeleton3D = s.find_child("Skeleton3D", true, false)
		if sk:
			var kids = []
			for c in sk.get_children(): kids.append(c.name + (":" + ",".join(c.get_children().map(func(x): return x.name)) if c is BoneAttachment3D else ""))
			print("  Teile: ", " | ".join(kids))
	var d = DirAccess.open("res://models/dungeon")
	for f in d.get_files():
		if f.ends_with(".glb"):
			var s = load("res://models/dungeon/" + f).instantiate()
			var acc = [null]; _aabb(s, acc, Transform3D.IDENTITY)
			var a: AABB = acc[0]
			print(f.get_basename(), "  pos ", a.position.snapped(Vector3.ONE * 0.01), " size ", a.size.snapped(Vector3.ONE * 0.01))
	quit()
