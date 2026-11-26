class_name Former extends RefCounted
# Baukasten für die Netze der Tiere (4.3): Leiber aus Ringen entlang eines Weges, Kuppeln aus einem Umriss (Käfer),
# flache Häute (Flügel, Flossen, Ohren). Jeder Punkt bekommt mit, zu welchem Teil er gehört und um welches Gelenk sich
# der Teil dreht; tiere.gdshader bewegt danach. Vorn ist +z, oben +y, links +x.
# Texturkoordinaten: jedes Tier hat ein Feld in der gemeinsamen Tafel (models/tiere/tiere_tafel.webp). Ein Punkt wird
# von oben (xz) oder von der Seite (zy) in sein Feld projiziert; Beine nehmen die Farbe der Stelle, an der sie ansetzen.

var st := SurfaceTool.new()
var feld := Rect2(0, 0, 1, 1)   # Feld in der Tafel (0 … 1)
var mass := AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))   # Ausdehnung des Tieres, die auf das Feld fällt
var seitlich := false            # Projektion von der Seite (z → u, y → v) statt von oben (x → u, z → v)
var tris := 0

func _init(f: Rect2, m: AABB, von_der_seite := false) -> void:
	feld = f
	mass = m
	seitlich = von_der_seite
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)

# Wohin ein Punkt in der Tafel fällt. Feldbild: oben die Schnauze (vorn), links die linke Seite (+x) … von oben gesehen
# ist die linke Körperseite rechts im Bild; das Feld ist symmetrisch gemalt, darum gleich.
func uv_von(p: Vector3) -> Vector2:
	var u: float
	var v: float
	if seitlich:
		u = (mass.end.z - p.z) / mass.size.z
		v = (mass.end.y - p.y) / mass.size.y
	else:
		u = (p.x - mass.position.x) / mass.size.x
		v = (mass.end.z - p.z) / mass.size.z
	u = clampf(u, 0.002, 0.998)
	v = clampf(v, 0.002, 0.998)
	return feld.position + Vector2(u, v) * feld.size

# ein Punkt mit allem, was der Shader braucht
func _punkt(p: Vector3, n: Vector3, teil: int, g: float, piv: Vector3, uvp, frei := 0.0) -> void:
	st.set_normal(n.normalized())
	st.set_uv(uv_von(uvp) if uvp is Vector3 else uvp)
	var seite := 0.5 + 0.5 * signf(piv.x) if absf(piv.x) > 0.001 else (0.5 + 0.5 * signf(p.x) if absf(p.x) > 0.001 else 0.5)
	st.set_color(Color(teil / 16.0, clampf(g, 0.0, 1.0), seite, frei))
	st.set_custom(0, Color(piv.x, piv.y, piv.z, 0.0))
	st.add_vertex(p)

# Dreieck, von außen im Uhrzeigersinn (so zeigt Godot die Vorderseite)
func _dreieck(a: Array, b: Array, c: Array) -> void:
	for q in [a, b, c]:
		_punkt(q[0], q[1], q[2], q[3], q[4], q[5])
	tris += 1

# Leib aus Ringen. weg: Mittelpunkte, r: Halbachsen (Vector2 Breite, Höhe) je Ring, teil/g/piv je Ring als Arrays oder
# fest. uv_quelle: null = Punkt selbst; sonst ein fester Punkt (Beine nehmen die Farbe ihres Ansatzes).
func roehre(weg: Array, r: Array, teil, g, piv, seg := 8, deckel := [true, true], uv_quelle = null, oben := Vector3.UP, drehung := 0.0) -> void:
	var n := weg.size()
	var ringe := []
	for i in n:
		var p: Vector3 = weg[i]
		var vor: Vector3 = weg[mini(i + 1, n - 1)]
		var hin: Vector3 = weg[maxi(i - 1, 0)]
		var ax := (vor - hin).normalized()
		var up := oben
		if absf(ax.dot(up)) > 0.92:
			up = Vector3.BACK if absf(ax.dot(Vector3.BACK)) < 0.92 else Vector3.RIGHT
		var sx := ax.cross(up).normalized()      # Seite
		var sy := sx.cross(ax).normalized()      # oben im Ring
		var rr: Vector2 = r[i]
		var ring := []
		for k in seg + 1:
			var th := TAU * k / seg + drehung   # 0 = unten (Bauch)
			var cs := Vector2(sin(th), -cos(th))
			var pos := p + sx * cs.x * rr.x + sy * cs.y * rr.y
			var nrm := (sx * cs.x / maxf(rr.x, 0.0005) + sy * cs.y / maxf(rr.y, 0.0005)).normalized()
			var ti: int = teil[i] if teil is Array else teil
			var gi: float = g[i] if g is Array else g
			var pv: Vector3 = piv[i] if piv is Array else piv
			ring.append([pos, nrm, ti, gi, pv, pos if uv_quelle == null else uv_quelle])
		ringe.append(ring)
	for i in n - 1:
		for k in seg:
			var a: Array = ringe[i][k]
			var b: Array = ringe[i][k + 1]
			var c: Array = ringe[i + 1][k + 1]
			var d: Array = ringe[i + 1][k]
			_dreieck(a, b, c)
			_dreieck(a, c, d)
	# Deckel: Fächer zur Mitte (ein spitzer Punkt, wenn der Ring klein ist)
	for e in 2:
		if not deckel[e]:
			continue
		var i := 0 if e == 0 else n - 1
		var p: Vector3 = weg[i]
		var nach: Vector3 = (weg[mini(1, n - 1)] - weg[0]) if e == 0 else (weg[n - 1] - weg[maxi(n - 2, 0)])
		var ax := nach.normalized() * (-1.0 if e == 0 else 1.0)
		var ti: int = teil[i] if teil is Array else teil
		var gi: float = g[i] if g is Array else g
		var pv: Vector3 = piv[i] if piv is Array else piv
		var mitte := [p, ax, ti, gi, pv, p if uv_quelle == null else uv_quelle]
		for k in seg:
			if e == 0:
				_dreieck(mitte, ringe[i][k + 1], ringe[i][k])
			else:
				_dreieck(mitte, ringe[i][k], ringe[i][k + 1])

# Kuppel über einem Umriss (Käferpanzer, Halsschild, Kopfschild): umriss(phi) gibt den Halbmesser in der Ebene,
# höhe die Wölbung, unten der Boden. Die Kuppel ist oben rund, unten flach.
func kuppel(mitte: Vector3, umriss: Callable, hoehe: float, unten: float, teil: int, seg := 16, lagen := 4, piv := Vector3.ZERO, kante := 0.35) -> void:
	var ringe := []
	# Lagen von der Unterkante (Rand) bis zur Spitze
	for j in lagen + 1:
		var w := float(j) / lagen            # 0 Rand, 1 Scheitel
		var ang := w * PI * 0.5
		var s := cos(ang)
		var y := mitte.y + sin(ang) * hoehe
		var ring := []
		for k in seg + 1:
			var phi := TAU * k / seg
			var rad: float = umriss.call(phi)
			var dir := Vector3(sin(phi), 0, cos(phi))
			var pos := mitte + dir * rad * s
			pos.y = y
			var nrm := (dir * cos(ang) * hoehe / maxf(rad, 0.001) + Vector3.UP * sin(ang)).normalized()
			ring.append([pos, nrm, teil, w, piv, pos])
		ringe.append(ring)
	for j in lagen:
		for k in seg:
			var a: Array = ringe[j][k]
			var b: Array = ringe[j][k + 1]
			var c: Array = ringe[j + 1][k + 1]
			var d: Array = ringe[j + 1][k]
			_dreieck(a, c, b)
			_dreieck(a, d, c)
	# Unterseite: ein flacher Rand nach innen und unten
	var boden := []
	for k in seg + 1:
		var p: Array = ringe[0][k]
		var pos: Vector3 = mitte + (p[0] - mitte) * (1.0 - kante)
		pos.y = mitte.y - unten
		boden.append([pos, Vector3.DOWN, teil, 0.0, piv, pos])
	for k in seg:
		_dreieck(ringe[0][k], ringe[0][k + 1], boden[k + 1])
		_dreieck(ringe[0][k], boden[k + 1], boden[k])
	var bm := mitte
	bm.y -= unten
	var bmp := [bm, Vector3.DOWN, teil, 0.0, piv, bm]
	for k in seg:
		_dreieck(bmp, boden[k], boden[k + 1])

# flache Haut mit Ober- und Unterseite: streifen = Liste von [vorne, hinten] Punktpaaren entlang der Spannweite,
# g je Paar (0 Ansatz … 1 Spitze). Für Flügel, Flossen, Ohren. dick: halbe Dicke an der Wurzel.
func haut(streifen: Array, teil: int, piv: Vector3, dick := 0.004, uv_oben := true, oben := Vector3.UP) -> void:
	var n := streifen.size()
	for lage in 2:
		var sg := 1.0 if lage == 0 else -1.0
		for i in n - 1:
			var g0 := float(i) / (n - 1)
			var g1 := float(i + 1) / (n - 1)
			var d0 := oben * dick * (1.0 - g0) * sg
			var d1 := oben * dick * (1.0 - g1) * sg
			var a := [streifen[i][0] + d0, oben * sg, teil, g0, piv, streifen[i][0]]
			var b := [streifen[i][1] + d0, oben * sg, teil, g0, piv, streifen[i][1]]
			var c := [streifen[i + 1][1] + d1, oben * sg, teil, g1, piv, streifen[i + 1][1]]
			var d := [streifen[i + 1][0] + d1, oben * sg, teil, g1, piv, streifen[i + 1][0]]
			# Umlaufsinn hängt davon ab, auf welcher Seite die Spitze liegt: über die Normale entscheiden
			var nrm: Vector3 = (b[0] - a[0]).cross(d[0] - a[0])
			var gleich := nrm.dot(oben * sg) > 0.0
			if gleich:
				_dreieck(a, d, c)
				_dreieck(a, c, b)
			else:
				_dreieck(a, b, c)
				_dreieck(a, c, d)

# kleine Kugel (Augen, Mistkugel)
func kugel(mitte: Vector3, r: Vector3, teil: int, piv: Vector3, seg := 8, ringe := 5, uvp = null) -> void:
	var pts := []
	for j in ringe + 1:
		var row := []
		var v := PI * j / ringe
		for i in seg + 1:
			var u := TAU * i / seg
			var nrm := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var pos := mitte + nrm * r
			row.append([pos, (nrm / r).normalized(), teil, 0.0, piv, pos if uvp == null else uvp])
		pts.append(row)
	for j in ringe:
		for i in seg:
			_dreieck(pts[j][i], pts[j][i + 1], pts[j + 1][i + 1])
			_dreieck(pts[j][i], pts[j + 1][i + 1], pts[j + 1][i])

func fertig() -> ArrayMesh:
	st.index()
	var m := st.commit()
	return m
