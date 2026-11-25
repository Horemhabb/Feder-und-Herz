class_name Bewegungen extends RefCounted
# Zusätzliche Bewegungen für die Fabrikfiguren: fremde, frei lizenzierte Bewegungen (zuerst Quaternius, CC0), mit
# tools/bewegung/umrechnen.gd auf das KayKit-Skelett übertragen und je Satz in models/anim/<satz>.res abgelegt.
# Einhängen (eine Zeile nach Actor.setup):  Bewegungen.ergaenzen(ap, skel, "eidtraeger")
# Danach heißen die Bewegungen "<satz>/<name>", z. B. "eidtraeger/Hiebfolge", und laufen über Actor.play wie jede andere.
# Welche es gibt: BEWEGUNGSWERK.md oder Bewegungen.namen("eidtraeger").

const ORDNER := "res://models/anim/"
const SAETZE := ["eidtraeger", "priester", "jaegerin", "sternleserin", "gemeinsam", "boss"]
# Klasse des Helden → Satz (Schlüssel wie in klassen.gd)
const KLASSE := {"ermittler": "eidtraeger", "moench": "priester", "jaegerin": "jaegerin", "forensiker": "sternleserin"}

static var _angepasst := {}   # Satz und Beinlänge → angepasste Bibliothek (für Skelette mit anderen Maßen)


# Hängt den Satz in den AnimationPlayer der Figur. Gibt die neuen Namen zurück (leer, wenn es den Satz nicht gibt oder das
# Skelett nicht passt). Mehrfacher Aufruf schadet nicht. Die Bibliothek wird zwischen Figuren geteilt, nicht kopiert.
static func ergaenzen(ap: AnimationPlayer, skel: Skeleton3D, satz: String) -> PackedStringArray:
	var aus := PackedStringArray()
	if ap == null or skel == null:
		return aus
	var pfad := ORDNER + satz + ".res"
	if not ResourceLoader.exists(pfad):
		return aus
	if not ap.has_animation_library(satz):
		var bib: AnimationLibrary = load(pfad)
		if bib == null:
			return aus
		var ol := skel.find_bone("upperleg.l")
		var fu := skel.find_bone("foot.l")
		var hu := skel.find_bone("hips")
		if ol < 0 or fu < 0 or hu < 0:
			return aus   # kein KayKit-Skelett (Ba, Skorpion)
		var bein := skel.get_bone_global_rest(ol).origin.y - skel.get_bone_global_rest(fu).origin.y
		var ref: float = bib.get_meta("beinlaenge", bein)
		var wurzel := ap.get_node_or_null(ap.root_node)
		var pfad_skel := str(wurzel.get_path_to(skel)) if wurzel else "Rig/Skeleton3D"
		if absf(bein / ref - 1.0) > 0.01 or pfad_skel != "Rig/Skeleton3D":
			bib = _anpassen(bib, satz, bein / ref, skel.get_bone_rest(hu).origin, pfad_skel)
		ap.add_animation_library(satz, bib)
	for n in ap.get_animation_library(satz).get_animation_list():
		aus.append(satz + "/" + n)
	return aus


# Alle Sätze, die zu einer Heldenklasse passen: ihr eigener und der gemeinsame
static func fuer_klasse(ap: AnimationPlayer, skel: Skeleton3D, klasse: String) -> PackedStringArray:
	var aus := ergaenzen(ap, skel, "gemeinsam")
	if KLASSE.has(klasse):
		aus.append_array(ergaenzen(ap, skel, KLASSE[klasse]))
	return aus


# Weg über Grund, der aus einer Bewegung herausgerechnet wurde (auf der Stelle gespielt): so weit müsste der Körper in
# Blickrichtung (+Z des Modells) und zur Seite (+X) wandern, im Maß des Modells. Null, wenn nichts herausgerechnet ist.
static func weg(ap: AnimationPlayer, anim: String) -> Vector3:
	if ap == null or not ap.has_animation(anim):
		return Vector3.ZERO
	return ap.get_animation(anim).get_meta("weg", Vector3.ZERO)


# Weg über Grund bis zur Zeit t (Sekunden in der Bewegung), wie weg(): für Schritt-für-Schritt-Schieben des Körpers.
static func weg_bei(ap: AnimationPlayer, anim: String, t: float) -> Vector3:
	if ap == null or not ap.has_animation(anim):
		return Vector3.ZERO
	var a := ap.get_animation(anim)
	var kurve: PackedVector3Array = a.get_meta("weg_kurve", PackedVector3Array())
	if kurve.is_empty():
		return Vector3.ZERO
	var f := clampf(t * float(a.get_meta("weg_takt", 30.0)), 0.0, kurve.size() - 1.0)
	var i := mini(int(f), kurve.size() - 2) if kurve.size() > 1 else 0
	return kurve[i].lerp(kurve[mini(i + 1, kurve.size() - 1)], f - i)


static func namen(satz: String) -> PackedStringArray:
	var pfad := ORDNER + satz + ".res"
	if not ResourceLoader.exists(pfad):
		return PackedStringArray()
	return PackedStringArray(Array((load(pfad) as AnimationLibrary).get_animation_list()))


# Für Skelette mit anderer Beinlänge: Beckenlage im Verhältnis der Beine, Drehungen bleiben (die Fabrik ändert nur Längen,
# nie Richtungen). Andere Knotenpfade werden umgeschrieben.
static func _anpassen(bib: AnimationLibrary, satz: String, k: float, huefte: Vector3, pfad_skel: String) -> AnimationLibrary:
	var schluessel := "%s|%.3f|%s" % [satz, k, pfad_skel]
	if _angepasst.has(schluessel):
		return _angepasst[schluessel]
	var huefte_ref: Vector3 = bib.get_meta("huefte", huefte)
	var neu := AnimationLibrary.new()
	for n in bib.get_animation_list():
		var a: Animation = bib.get_animation(n).duplicate(true)
		for i in a.get_track_count():
			var knochen := str(a.track_get_path(i)).get_slice(":", 1)
			a.track_set_path(i, NodePath(pfad_skel + ":" + knochen))
			if knochen == "hips" and a.track_get_type(i) == Animation.TYPE_POSITION_3D:
				for j in a.track_get_key_count(i):
					var v: Vector3 = a.track_get_key_value(i, j)
					a.track_set_key_value(i, j, huefte + (v - huefte_ref) * k)
		neu.add_animation(n, a)
	_angepasst[schluessel] = neu
	return neu
