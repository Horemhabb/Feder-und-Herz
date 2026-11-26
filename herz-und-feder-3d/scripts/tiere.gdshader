shader_type spatial;
// Kleintiere und Vögel (4.3): ein Shader für alle Arten. Die Netze baut tiere.gd; jeder Punkt trägt, zu welchem Teil er
// gehört (Farbe r: Teil, g: Lage entlang des Teils 0 Ansatz … 1 Spitze, b: Seite, a: frei) und um welchen Punkt sich
// dieser Teil dreht (CUSTOM0.xyz, das Gelenk). Bewegt wird hier, nicht auf dem Prozessor: Beine schreiten, der Leib
// schlängelt, Flügel schlagen, Köpfe nicken. Die Spielseite (tier.gd) schickt je Tier nur vier Zahlen:
//   gang  Phase des Schrittes oder Flügelschlags (wächst mit dem Weg bzw. der Zeit)
//   tempo 0 … 1: wie stark die Beine schreiten (0 = steht)
//   pose  x Kopf nicken (+ nach unten), y Kopf drehen, z und w je Art (Liegestütz, Aufrichten, Flügelweite …)
// Teile: 0 Leib, 1–6 Beine, 7 Kopf, 8 Schwanz, 9 Flügel, 10 Fühler/Ohren, 11 Hals, 12 Flosse.
render_mode cull_back, depth_draw_opaque;

uniform sampler2D tafel : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform int art = 0;          // 1 Eidechse, 2 Käfer, 3 Maus, 4 Vogel im Flug, 5 Vogel sitzend/gehend, 6 Fisch, 7 Fledermaus, 8 Vierbeiner
uniform vec3 bauch : source_color = vec3(0.8, 0.75, 0.62);   // Farbe der Unterseite
uniform float bauch_an = 0.0; // wie stark die Unterseite umgefärbt wird
uniform float rauh = 0.75;
uniform float spiegel = 0.35;
uniform vec3 schimmer : source_color = vec3(0.0);            // Glanzfarbe am Rand (Skarabäus: blaugrün)
uniform float schritt = 0.6;  // Schrittweite in Bogenmaß
uniform float hub = 0.02;     // Fußheben in Metern
uniform float welle = 0.0;    // Seitenwelle des Leibes (Eidechse, Fisch)
uniform float wellen_k = 9.0; // Wellenzahl entlang des Leibes
uniform float leib_z = 0.0;   // Mitte des Leibes (für die Welle)
uniform float schwanz_z = -0.1; // ab hier wächst die Welle zum Schwanz hin
uniform vec3 kopf_piv = vec3(0.0); // Halsansatz: Ohren drehen mit dem Kopf (Maus, Vierbeiner)

instance uniform float gang = 0.0;
instance uniform float tempo = 0.0;
instance uniform vec4 pose = vec4(0.0);
instance uniform vec4 farbe : source_color = vec4(1.0);
instance uniform float zeit0 = 0.0;

varying float unten;
varying float spitze;
varying float hoch;

mat3 rot_x(float a) { float c = cos(a); float s = sin(a); return mat3(vec3(1, 0, 0), vec3(0, c, s), vec3(0, -s, c)); }
mat3 rot_y(float a) { float c = cos(a); float s = sin(a); return mat3(vec3(c, 0, -s), vec3(0, 1, 0), vec3(s, 0, c)); }
mat3 rot_z(float a) { float c = cos(a); float s = sin(a); return mat3(vec3(c, s, 0), vec3(-s, c, 0), vec3(0, 0, 1)); }

void vertex() {
	int teil = int(COLOR.r * 16.0 + 0.5);
	float g = COLOR.g;
	float seite = COLOR.b * 2.0 - 1.0;
	vec3 piv = CUSTOM0.xyz;
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	float t = TIME + zeit0;
	unten = smoothstep(0.15, -0.6, NORMAL.y);
	spitze = (teil >= 1 && teil <= 6) ? g : 0.0;
	// Beinphasen: Eidechse und Vierbeiner diagonal, Käfer im Dreifuß, Maus hüpft (Paare)
	float ph = 0.0;
	if (teil >= 1 && teil <= 6) {
		if (art == 2) { ph = (teil == 1 || teil == 4 || teil == 5) ? 0.0 : 3.14159; }
		else if (art == 3) { ph = (teil <= 2) ? 0.0 : 2.4; }
		else if (art == 8) { ph = (teil == 1) ? 1.5708 : (teil == 2) ? 4.7124 : (teil == 3) ? 0.0 : 3.14159; }
		else if (art == 5) { ph = (teil == 1) ? 0.0 : 3.14159; }
		else { ph = (teil == 1 || teil == 4) ? 0.0 : 3.14159; }
	}
	float s = sin(gang + ph);
	float c = cos(gang + ph);

	if (art == 1) {
		// Eidechse: gespreizte Beine schwingen waagrecht um die Schulter, die Füße heben ab; der Leib schlängelt
		if (teil >= 1 && teil <= 4) {
			float vorn = (teil <= 2) ? 1.0 : -1.0;
			float a = schritt * s * tempo * (teil == 2 || teil == 4 ? -1.0 : 1.0) * -1.0;
			mat3 r = rot_y(a * sign(piv.x));
			v = piv + r * (v - piv);
			n = r * n;
			v.y += g * hub * max(0.0, c) * tempo;
			// Liegestütz: Vorderbeine strecken sich, die Füße bleiben am Boden
			if (vorn > 0.0) { v.y += pose.z * 0.05 * (1.0 - g); }
		}
		if (teil == 7) {
			mat3 r = rot_y(pose.y) * rot_x(-pose.x);
			v = piv + r * (v - piv);
			n = r * n;
		}
		// Liegestütz hebt die Brust
		float zz = (teil >= 1 && teil <= 6) ? piv.z : v.z;
		v.y += pose.z * 0.05 * smoothstep(-0.06, 0.08, zz) * ((teil >= 1 && teil <= 6) ? 0.0 : 1.0);
		if (teil == 7) { v.y += pose.z * 0.05; }
		// Welle: steht als S-Form (pose.w) und läuft mit dem Schritt; zum Schwanz hin weiter ausschlagend
		float schw = smoothstep(schwanz_z, schwanz_z - 0.35, zz);
		float amp = welle * (tempo + 0.15) * (1.0 + 2.5 * schw);
		float off = amp * sin(zz * wellen_k + gang) + pose.w * 0.03 * sin(zz * 5.0 + 0.6) * (0.4 + 1.6 * schw);
		off += (teil == 8 || schw > 0.0) ? 0.012 * schw * sin(t * 1.3 + zz * 6.0) * (1.0 - tempo) : 0.0;
		v.x += off;
	} else if (art == 2) {
		// Käfer: sechs Beine im Dreifuß, Fühler zucken, Leib kippt beim Kugelschieben (pose.x)
		if (teil >= 1 && teil <= 6) {
			float a = schritt * s * tempo;
			mat3 r = rot_y(a * sign(piv.x));
			v = piv + r * (v - piv);
			n = r * n;
			v.y += g * hub * max(0.0, c) * tempo;
		}
		if (teil == 10) {
			mat3 r = rot_y(0.25 * sin(t * 7.0 + seite) * (0.4 + tempo)) * rot_x(0.15 * sin(t * 5.3 + seite * 2.0));
			v = piv + r * (v - piv);
			n = r * n;
		}
		v.y += 0.002 * sin(gang * 2.0) * tempo;
		mat3 k = rot_x(pose.x);
		vec3 m = vec3(0.0, 0.0, 0.0);
		if (teil < 1 || teil > 6) { v = m + k * (v - m); n = k * n; }
		else { vec3 p2 = m + k * (piv - m); v += p2 - piv; }
	} else if (art == 3) {
		// Maus: hüpft (Vorder- und Hinterbeine paarweise), richtet sich auf (pose.z), Ohren und Schwanz zucken
		if (teil >= 1 && teil <= 4) {
			mat3 r = rot_x(-schritt * s * tempo);
			v = piv + r * (v - piv);
			n = r * n;
		}
		float hopp = abs(sin(gang * 0.5)) * 0.03 * tempo;
		v.y += hopp;
		if (teil == 10) {
			mat3 r = rot_x(0.3 * pow(max(0.0, sin(t * 2.3 + seite)), 12.0));
			v = piv + r * (v - piv);
			n = r * n;
		}
		if (teil == 8) {
			mat3 r = rot_y(0.25 * g * sin(t * 1.7) * (1.0 - tempo) + 0.15 * g * sin(gang) * tempo) * rot_x(-0.25 * g * pose.z);
			v = piv + r * (v - piv);
			n = r * n;
		}
		if (teil == 7 || teil == 10) {
			mat3 r = rot_y(pose.y) * rot_x(-pose.x);
			vec3 kp = (teil == 7) ? piv : kopf_piv;
			v = kp + r * (v - kp);
			n = r * n;
		}
		// Aufrichten: alles vor der Hüfte dreht um die Hüfte nach oben; Hinterbeine und Schwanz bleiben
		if (teil != 3 && teil != 4 && teil != 8) {
			vec3 h = vec3(0.0, 0.03, -0.05);
			mat3 r = rot_x(-pose.z * 1.15);
			v = h + r * (v - h);
			n = r * n;
		}
	} else if (art == 4 || art == 7) {
		// Vogel oder Fledermaus im Flug: Flügel schlagen um die Schulter, die Hand schlägt verzögert nach
		if (teil == 9) {
			float schlag = pose.z * sin(gang);
			float hand = pose.z * 0.45 * sin(gang - 0.9);
			float a = (pose.w + schlag + hand * g) * seite;
			// Fledermaus: unregelmäßig, die Haut faltet sich beim Aufschlag
			if (art == 7) { a += 0.25 * g * sin(gang * 2.0) * seite; }
			mat3 r = rot_z(a);
			v = piv + r * (v - piv);
			n = r * n;
			v.z -= g * 0.06 * pose.z * max(0.0, -sin(gang)) * (art == 7 ? 1.5 : 1.0);
		}
		if (teil == 8) {
			mat3 r = rot_x(0.12 * sin(gang + 1.0) * pose.z + pose.x * 0.3) * rot_z(-pose.y * 0.6);
			v = piv + r * (v - piv);
			n = r * n;
		}
		if (teil == 7) {
			mat3 r = rot_y(pose.y * 0.8);
			v = piv + r * (v - piv);
			n = r * n;
		}
		v.y -= 0.03 * pose.z * sin(gang);
	} else if (art == 5) {
		// Vogel sitzend oder schreitend: Beine schreiten, Hals und Kopf picken/stochern (pose.x), Kopf dreht (pose.y)
		if (teil >= 1 && teil <= 2) {
			mat3 r = rot_x(-schritt * s * tempo);
			v = piv + r * (v - piv);
			n = r * n;
			v.y += g * hub * max(0.0, c) * tempo * 0.0;
		}
		if (teil == 11 || teil == 7) {
			float w = (teil == 11) ? g : 1.0;
			mat3 r = rot_y(pose.y * w) * rot_x(pose.x * w);
			v = piv + r * (v - piv);
			n = r * n;
		}
		if (teil == 8) {
			mat3 r = rot_x(0.08 * sin(t * 2.0) * (1.0 - tempo) + pose.w * 0.3);
			v = piv + r * (v - piv);
			n = r * n;
		}
		// Körper wippt beim Schreiten
		if (teil != 1 && teil != 2) { v.y += 0.012 * abs(s) * tempo; }
		if (teil == 10) {
			// Haube (Wiedehopf) aufstellen
			mat3 r = rot_x(-pose.z * 1.2 * g);
			v = piv + r * (v - piv);
			n = r * n;
		}
	} else if (art == 6) {
		// Fisch: Welle von vorn nach hinten, nach hinten stärker
		float hinten = clamp((leib_z - v.z) / 0.3, 0.0, 1.5);
		float amp = welle * (0.25 + tempo) * hinten * hinten;
		v.x += amp * sin(v.z * wellen_k + gang) + pose.y * hinten * 0.06;
		if (teil == 12) {
			mat3 r = rot_z(0.4 * sin(t * 6.0 + seite) * seite);
			v = piv + r * (v - piv);
			n = r * n;
		}
	} else if (art == 8) {
		// Vierbeiner: Beine pendeln um Schulter und Hüfte, das untere Bein knickt beim Vorziehen
		if (teil >= 1 && teil <= 4) {
			mat3 r = rot_x(-schritt * s * tempo);
			v = piv + r * (v - piv);
			n = r * n;
			v.y += smoothstep(0.35, 1.0, g) * hub * max(0.0, c) * tempo;
			v.z -= smoothstep(0.4, 1.0, g) * hub * 0.6 * max(0.0, c) * tempo;
		}
		if (teil == 11 || teil == 7) {
			float w = (teil == 11) ? g : 1.0;
			mat3 r = rot_y(pose.y * w) * rot_x(pose.x * w);
			v = piv + r * (v - piv);
			n = r * n;
			if (teil == 7) { v.y += 0.004 * sin(t * 9.0) * step(0.6, pose.x); }   // kaut beim Grasen
		}
		if (teil == 8) {
			mat3 r = rot_y(0.35 * g * sin(t * 1.6 + zeit0) * (0.6 + 0.6 * pow(max(0.0, sin(t * 0.7)), 4.0))) * rot_x(-pose.w * g);
			v = piv + r * (v - piv);
			n = r * n;
		}
		if (teil == 10) {
			mat3 r = rot_x(0.35 * pow(max(0.0, sin(t * 1.9 + seite * 1.3)), 16.0)) * rot_z(0.2 * pose.z * seite);
			v = piv + r * (v - piv);
			n = r * n;
			mat3 k = rot_y(pose.y) * rot_x(pose.x);
			v = kopf_piv + k * (v - kopf_piv);
			n = k * n;
		}
		// Atmen
		if (teil == 0) { v.x *= 1.0 + 0.015 * sin(t * 2.2) * (1.0 - tempo); }
		v.y += 0.015 * abs(sin(gang)) * tempo;
	}
	VERTEX = v;
	NORMAL = normalize(n);
#ifdef SCHATTEN
	// Schatten eines fliegenden Vogels: flach auf den Boden gelegt, schräg versetzt wie vom Mond
	vec4 w = MODEL_MATRIX * vec4(VERTEX, 1.0);
	hoch = max(w.y, 0.0);
	w.xz += vec2(0.3, 0.22) * hoch;
	w.y = 0.04;
	VERTEX = (inverse(MODEL_MATRIX) * w).xyz;
#endif
}

void fragment() {
#ifdef SCHATTEN
	ALBEDO = vec3(0.03, 0.022, 0.015);
	ALPHA = 0.5 * clamp(1.0 - hoch / 30.0, 0.3, 1.0);
#else
	vec4 tx = texture(tafel, UV);
	vec3 a = tx.rgb * farbe.rgb;
	a = mix(a, bauch * farbe.rgb, unten * bauch_an);
	a *= 1.0 - spitze * 0.25;
	ALBEDO = a;
	ROUGHNESS = rauh;
	SPECULAR = spiegel;
	// Schimmer am Rand: Käferpanzer, Gefieder im Gegenlicht
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = schimmer * fr * 0.6;
#endif
}
