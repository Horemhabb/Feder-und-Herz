// Mauern der generierten Stunden: Steintextur mit Reliefkarte und Tönung wie StandardMaterial3D,
// dazu der Durchblick: Was zwischen Kamera und Figur oberhalb der Hüfte steht, wird ausgespart
// (gerastert, damit die Kante weich wirkt). Kamera und Figur kommen als globale Werte aus main.gd.
shader_type spatial;

uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_normal = true;
uniform float normal_depth = 0.9;
global uniform vec3 cut_hero;
global uniform vec3 cut_cam;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 ab = cut_hero + vec3(0.0, 1.0, 0.0) - cut_cam;
	float t = clamp(dot(wpos - cut_cam, ab) / dot(ab, ab), 0.0, 1.0);
	float d = length(wpos - (cut_cam + ab * t));
	if (t < 0.96 && wpos.y > 1.15) {
		// Rasterkante zwischen 1,6 und 2,4 m Abstand von der Sichtlinie
		float k = clamp((2.4 - d) / 0.8, 0.0, 1.0);
		float n = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
		if (n < k) {
			discard;
		}
	}
	ALBEDO = texture(tex_albedo, UV).rgb * tint.rgb;
	// Fuß der Mauer dunkler: Hier kommt weniger Licht hin. Das stellt die Mauer auf den Boden, statt dass sie schwebt.
	ALBEDO *= mix(0.42, 1.0, smoothstep(0.0, 1.5, wpos.y));
	if (use_normal) {
		NORMAL_MAP = texture(tex_normal, UV).rgb;
		NORMAL_MAP_DEPTH = normal_depth;
	}
	ROUGHNESS = 0.93;
}
