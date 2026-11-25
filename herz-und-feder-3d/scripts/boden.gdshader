// Böden der Stunden (Sand, Pflaster, Gruft, Feld, Glas, Höhlenboden): Textur mit Reliefkarte und Tönung wie StandardMaterial3D,
// aber ohne sichtbare Kachel. Eine Kachel misst vier bis sechs Meter; schräg von oben sah man ihre Wiederholung als Rauten.
// Darum zweierlei, beides ohne zusätzliche Textur:
//  1. Verwürfeln (nach Inigo Quilez, „texture repetition“, Weg 3): ein weiches Rauschen teilt den Boden in Flecken von etwa
//     einer Kachel Größe. Jeder Fleck liest die Textur um ein anderes Stück verschoben; dazwischen wird weich überblendet.
//     Nur verschoben, nie gedreht: so bleibt die Reliefkarte richtig, und das Licht fällt weiter von derselben Seite.
//     Steine im Verband (Pflaster) werden nur um ganze Steine verschoben, dann laufen die Fugen weiter (Raster).
//  2. Flecken: eine sehr große, weiche Helligkeitswelle (im Mittel 1,0, ändert die Gesamthelligkeit also nicht).
// Kosten: zwei statt einem Zugriff je Textur, mit Reliefkarte vier statt zwei; das Rauschen ist reine Rechnung.
shader_type spatial;

uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_normal = true;
uniform float normal_depth = 0.9;
uniform bool use_vertex_color = false;   // Gelände: Farbflecken aus den Ecken (welt.gd › _ground)
uniform int verteilung = 1;              // 0 nur Flecken, 1 frei verschoben, 2 auf dem Raster der Steine
uniform vec2 raster_a = vec2(0.0);       // erlaubte Verschiebungen im Raster (in Kacheln)
uniform vec2 raster_b = vec2(0.0);
uniform float fleck = 0.75;              // Größe der verwürfelten Flecken in Kacheln
uniform float flecken = 0.10;            // Stärke der großen Helligkeitswelle

float hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

// weiches Wertrauschen 0..1
float rauschen(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec2 versatz(float i) {
	vec2 o = sin(vec2(3.0, 7.0) * i);
	if (verteilung == 2) {
		// ganze Steine: Vielfache der Rasterschritte, die Fugen bleiben in einer Flucht
		return floor(o.x * 6.0) * raster_a + floor(o.y * 6.0) * raster_b;
	}
	return o;
}

void fragment() {
	vec2 uv = UV;
	vec2 gx = dFdx(uv);
	vec2 gy = dFdy(uv);
	vec3 col;
	vec3 nrm = vec3(0.5, 0.5, 1.0);
	if (verteilung == 0) {
		col = texture(tex_albedo, uv).rgb;
		if (use_normal) {
			nrm = texture(tex_normal, uv).rgb;
		}
	} else {
		float l = rauschen(uv / fleck) * 8.0;
		float ia = floor(l);
		vec2 oa = versatz(ia);
		vec2 ob = versatz(ia + 1.0);
		// textureGrad mit den Ableitungen der ungebrochenen UV: keine Mipmap-Säume an den Sprüngen
		vec3 ca = textureGrad(tex_albedo, uv + oa, gx, gy).rgb;
		vec3 cb = textureGrad(tex_albedo, uv + ob, gx, gy).rgb;
		// die Grenze folgt ein wenig dem Bild (hell/dunkel), dann wirkt sie gewachsen statt gezogen
		vec3 dd = ca - cb;
		float w = smoothstep(0.25, 0.75, fract(l) - 0.1 * (dd.x + dd.y + dd.z));
		col = mix(ca, cb, w);
		if (use_normal) {
			vec3 na = textureGrad(tex_normal, uv + oa, gx, gy).rgb;
			vec3 nb = textureGrad(tex_normal, uv + ob, gx, gy).rgb;
			nrm = mix(na, nb, w);
		}
	}
	// große Welle: zwei Lagen Rauschen, etwa fünf und zwei Kacheln groß
	float m = rauschen(uv * 0.21 + 17.0) * 0.65 + rauschen(uv * 0.53 - 9.0) * 0.35;
	col *= 1.0 + flecken * (m - 0.5) * 2.0;
	col *= tint.rgb;
	if (use_vertex_color) {
		col *= COLOR.rgb;
	}
	ALBEDO = col;
	if (use_normal) {
		NORMAL_MAP = nrm;
		NORMAL_MAP_DEPTH = normal_depth;
	}
	ROUGHNESS = 0.93;
}
