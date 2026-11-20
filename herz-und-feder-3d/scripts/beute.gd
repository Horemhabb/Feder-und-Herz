class_name Beute extends Node3D
# Etwas, das am Boden liegt (05-update.js › Loot): ein Gegenstand, Scherben, Material, Isisblut oder eine Seite aus dem
# Buch des Thot. Gezeigt wird das Symbol aus dem Bildbogen der 2D-Fassung; Seltenes und Seiten werfen einen Lichtstrahl.

var kind := ""     # "item", "shard", "mat", "blood", "page"
var item := {}
var mat := ""
var amount := 1
var page := -1
var age := 0.0
var spr: Node3D
var t0 := 0.0

func _ready() -> void:
	t0 = randf() * TAU
	var col := Color.WHITE
	var size := 0.55
	var icon := -1
	var text := ""
	var light := false
	var beam := false
	match kind:
		"item":
			col = Daten.RAR[item.rar].col
			icon = Daten.icon_of(item)
			size = 0.95
			text = Daten.item_name(item)
			light = item.rar >= 2
			beam = item.rar >= 2
		"shard":
			col = Color(0.95, 0.85, 0.55)
			icon = Daten.ICON.shard
			size = 0.5
		"mat":
			col = Daten.MATS[mat].col
			icon = Daten.ICON[mat]
			size = 0.55
		"page":
			col = Color(0.98, 0.9, 0.62)
			icon = Daten.ICON.evid
			size = 0.85
			text = "Buchseite"
			light = true
			beam = true
		"blood":
			col = Color(0.9, 0.18, 0.15)
			light = true
	if icon >= 0:
		var s := Sprite3D.new()
		s.texture = Daten.icon(icon)
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.pixel_size = size / s.texture.get_width()
		s.position.y = size * 0.6
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		spr = s
	else:
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.24
		sm.height = 0.48
		sm.radial_segments = 12
		sm.rings = 6
		m.mesh = sm
		var mat3 := StandardMaterial3D.new()
		mat3.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat3.albedo_color = col
		m.material_override = mat3
		m.position.y = 0.4
		spr = m
	add_child(spr)
	if text != "":
		var l := Label3D.new()
		l.text = text
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font_size = 40
		l.outline_size = 10
		l.modulate = col
		l.pixel_size = 0.0055
		l.position.y = size * 1.35 + 0.2
		add_child(l)
	if light:
		var o := OmniLight3D.new()
		o.light_color = col
		o.light_energy = 1.1
		o.omni_range = 3.2
		o.position.y = 0.8
		add_child(o)
	if beam:
		var b := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.09
		cm.height = 5.0
		cm.radial_segments = 8
		cm.rings = 1
		b.mesh = cm
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.albedo_color = Color(col, 0.32)
		b.material_override = bm
		b.position.y = 2.5
		add_child(b)
	# aufploppen: aus der Höhe auf den Boden
	spr.scale = Vector3.ONE * 0.2
	var tw := create_tween()
	tw.tween_property(spr, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	var _u := Time.get_ticks_usec()
	_process_innen(delta)
	Protokoll.zeit("beute", _u)

func _process_innen(delta: float) -> void:
	age += delta
	spr.position.y = (0.55 if kind == "item" or kind == "page" else 0.35) + sin(age * 2.4 + t0) * 0.07
