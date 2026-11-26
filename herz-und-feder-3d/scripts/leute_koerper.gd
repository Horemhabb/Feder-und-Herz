class_name LeuteKoerper extends Koerper
# Körperschicht für Leute, die keine Actor sind (4.3): Dorfleute, Leute der Aufträge, Gestalten der Geschichte.
# Sie bekommen dieselbe Schicht wie Held und Gegner (koerper.gd), nur dass hier ein kleiner Träger die Werte liefert,
# die sonst Actor hat (Modell, Ort, Tempo), und der Blick von selbst dem Helden folgt, wenn er nah ist.

# hängt als leerer Knoten an der Figur und liefert, was koerper.gd von einem Actor liest
class Traeger extends Node3D:
	var model: Node3D
	var velocity := Vector3.ZERO
	var alt := Vector3.ZERO

var traeger := Traeger.new()
var game
var figur: Node3D
var blick_weit := 7.0
var weg_schauen := 0.0      # Zeit, in der die Figur sich anderswo umsieht

func _process_modification_with_delta(delta: float) -> void:
	if figur == null or not is_instance_valid(figur) or delta <= 0.0:
		return
	var p := figur.global_position
	traeger.velocity = (p - traeger.alt) / delta if traeger.alt != Vector3.ZERO else Vector3.ZERO
	traeger.alt = p
	# Blick: zum Helden, wenn er nah ist; sonst ab und zu umsehen
	ziel = null
	if game and game.get("hero") != null and is_instance_valid(game.hero):
		var hp: Vector3 = game.hero.global_position
		if hp.distance_to(p) < blick_weit:
			ziel = hp
	if ziel == null:
		weg_schauen -= delta
		if weg_schauen < -6.0:
			weg_schauen = randf_range(1.5, 3.0)
		if weg_schauen > 0.0:
			var w := figur.rotation.y + sin(atem_t * 0.37) * 1.2
			ziel = p + Vector3(sin(w), 0, cos(w)) * 4.0
	super(delta)
