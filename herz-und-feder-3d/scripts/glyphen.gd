class_name Glyphen
# Symbole der Fähigkeiten als goldene Hieroglyphen auf dunklen Steintafeln (Fassung 2.1). Jedes Zeichen lehnt sich an ein
# echtes an: das Udjat-Auge, die Flügelsonne, die Feder der Maat, der Aton mit seinen Strahlenhänden, das Wappen der Neith
# (Schild mit gekreuzten Pfeilen), der Schakal des Upuaut, das Seth-Tier, der Stern im Kreis (Duat), das Zeichen der Seschat,
# der Mund (Hu, das Wort), die Arme des Ka, das Segel (Atem), das Land mit drei Körnern (Geb) und andere.
# Die Tafel trägt die Farbe der Klasse: Lapislazuli, Türkis, Karneol, Amethyst.
# Kürzel in den Zeichen: §s goldene Linie · §f goldene Fläche · §d dunkle Ritzung

const TAFEL := {
	"ermittler": ["#2b477a", "#0a0f1e"], "moench": ["#1f6462", "#06181a"], "jaegerin": ["#6a3f1c", "#190d06"],
	"forensiker": ["#4b3379", "#100a20"], "": ["#742222", "#1a0707"], "basalt": ["#3d3730", "#0d0b09"],
}

const G := {
	"whirl": '<circle cx="28" cy="24" r="5.5" §f/><path d="M21.5 23C16 17 10 16 5 20c5 1 8 5 16.5 7z" §f/><path d="M34.5 23C40 17 46 16 51 20c-5 1-8 5-16.5 7z" §f/><path d="M13 36a16 9 0 0 0 30 0M43 36l1-5M43 36l-5-1" §s/>',
	"dash": '<path d="M28 48L21 31 6 13l14 7 8-12 8 12 14-7-15 18z" §f/><circle cx="28" cy="19" r="1.6" fill="#0b1120"/><path d="M28 26v12" §d/>',
	"oath": '<path d="M28 48C17 39 16 19 27 8c3-2 7-1 8 3 4 12 2 28-7 37z" §f/><path d="M28 46C27 34 27 22 30 11" §d/><path d="M22 22l5 3M21 29l6 3M22 36l5 2M34 20l-5 4M35 28l-6 3M33 36l-5 2" §d/>',
	"udjat": '<path d="M7 17C17 9 39 9 49 15" §s/><path d="M7 26C16 17 38 15 49 24 39 32 17 34 7 26z" §s/><circle cx="28" cy="24.5" r="5" §f/><path d="M25 32v12" §s/><path d="M30 32c3 11 12 14 16 8 2-4-2-7-5-4" §s/>',
	"beam": '<path d="M22 22L12 46M25 23.5L21 48M28 24v24M31 23.5l4 24.5M34 22l10 24" §s/><path d="M10 46h4M19 48h4M26 48h4M33 48h4M42 46h4" §s/><circle cx="28" cy="15" r="8" §f/><circle cx="28" cy="15" r="2.6" fill="#0b1120"/>',
	"salve": '<ellipse cx="28" cy="28" rx="7.5" ry="11" §s/><path d="M9 13l38 30M47 13L9 43" §s/><path d="M9 13l6 1M9 13l1 6M47 13l-6 1M47 13l-1 6" §s/><path d="M28 21v14" §s/>',
	"roll": '<path d="M21 30h14l-7 15z" §f/><path d="M24 29C18 22 25 15 20 8M32 29c6-7-1-14 4-21" §s/><path d="M21 31l-7-3M35 31l7-3" §s/>',
	"hetz": '<path d="M7 33L25 24l4-2V8l6 12 4-12 5 16-1 20H30l-8-8-15-1z" §f/><circle cx="27" cy="29" r="1.7" fill="#0b1120"/>',
	"rain": '<path d="M7 10h42l-3 5H10z" §f/><path d="M14 20v12M21 20v20M28 20v26M35 20v20M42 20v12" §s/><path d="M11.5 29l2.5 4 2.5-4M18.5 37l2.5 4 2.5-4M25.5 43l2.5 4 2.5-4M32.5 37l2.5 4 2.5-4M39.5 29l2.5 4 2.5-4" §s/>',
	"pierce": '<ellipse cx="18" cy="28" rx="4" ry="9" §s/><ellipse cx="28" cy="28" rx="4" ry="9" §s/><ellipse cx="38" cy="28" rx="4" ry="9" §s/><path d="M5 28h44M49 28l-7-5M49 28l-7 5M5 28l4-4M5 28l4 4" §s/>',
	"chain": '<path d="M8 41c1-9 9-14 19-17l1-16h7l1 14 2-14h7l-2 17 1 20H30c-6-4-13-2-22-4z" §f/><circle cx="27" cy="30" r="1.7" fill="#0b1120"/><path d="M11 10l5 6-4 1 5 7" §s/>',
	"blink": '<circle cx="28" cy="28" r="19" §s/><path d="M28 13L30.65 24.36 42.27 23.36 32.28 29.39 36.82 40.14 28 32.5 19.18 40.14 23.72 29.39 13.73 23.36 25.35 24.36z" §f/>',
	"glass": '<path d="M13 18C13 4 43 4 43 18M13 18v3M43 18v3" §s/><path d="M28 22V13M28 22l7-5.6M28 22l8.8 2M28 22l3.9 8.1M28 22l-7-5.6M28 22l-8.8 2M28 22l-3.9 8.1" §s/><circle cx="28" cy="22" r="2.2" §f/><path d="M28 31v17M22 48h12" §s/>',
	"nova": '<path d="M15 28c7-8 19-8 26 0-7 8-19 8-26 0z" §f/><path d="M19 28h18" §d/><path d="M10 18c10-9 26-9 36 0M10 38c10 9 26 9 36 0" §s/><path d="M7 12C19 3 37 3 49 12M7 44c12 9 30 9 42 0" §s opacity="0.55"/>',
	"meteor": '<path d="M8 44V22C8 6 48 6 48 22v22" §s/><path d="M31 25L32.76 31.57 39.56 31.22 33.85 34.93 36.29 41.28 31 37 25.71 41.28 28.15 34.93 22.44 31.22 29.24 31.57z" §f/><path d="M26 24l-8-9M30 21l-5-8M22 28l-7-5" §s/>',
	"flurry": '<path d="M7 20h24c2-3 6-4 10-3 3 1 5 4 4 7-1 3-4 5-8 5H7z" §f/><path d="M11 33h24c2-3 6-4 10-3 3 1 5 4 4 7-1 3-4 5-8 5H11z" §f/><path d="M36 19v8M40 31v8" §d/>',
	"step": '<path d="M27 9v9L16 43h9M27 18l11 25h9" §s/><path d="M6 20h9M4 28h8M6 36h6" §s/>',
	"mantra": '<circle cx="28" cy="28" r="21" §s opacity="0.5"/><path d="M14 14v20h28V14" §s/><path d="M10 16l4-5 4 5M38 16l4-5 4 5" §s/><path d="M28 34v8" §s/>',
	"palm": '<path d="M7 28h42v7H7z" §f/><circle cx="18" cy="42" r="2" §f/><circle cx="28" cy="42" r="2" §f/><circle cx="38" cy="42" r="2" §f/><path d="M27 35l-2-4 3-3" §d/><path d="M28 28l2-3-4-6 3-5" §s/><path d="M14 22l-4-6M42 22l4-6M20 18l-2-7M36 18l2-7" §s/>',
	"wave": '<path d="M15 7v42M9 49h14" §s/><path d="M15 10c22 1 29 15 25 30l-25-3z" §f/><path d="M15 19c12 1 20 5 25 10M15 28c9 1 17 3 24 6" §d/>',
	# Dauerhafte Stärken (Fassung 2.7.1): Ka-Arme, Auge, Ba-Vogel, Wasser des Hapi, Faust mit Chepesch, Speer des Seth
	"p_zaeh": '<path d="M12 10v16c0 6 4 9 9 9h14c5 0 9-3 9-9V10" §s/><path d="M28 35v12M19 47h18" §s/><path d="M9 10h6M41 10h6" §s/>',
	"p_scharf": '<path d="M8 25c8-9 32-9 40 0-8 9-32 9-40 0z" §s/><circle cx="28" cy="25" r="5.5" §f/><path d="M23 33l-4 13M30 33c4 6 10 6 12 2" §s/><path d="M28 5v6M17 8l3 5M39 8l-3 5" §s/>',
	"p_flink": '<path d="M8 33c9-2 15-8 19-16 2 6 9 10 21 9-7 5-14 7-22 7z" §f/><circle cx="19" cy="15" r="5" §f/><path d="M25 33l-3 12M32 33l3 12M19 45h6M32 45h6" §s/>',
	"p_kraft": '<path d="M7 15l5-4 5 4 5-4 5 4 5-4 5 4 5-4 5 4 5-4" §s/><path d="M7 28l5-4 5 4 5-4 5 4 5-4 5 4 5-4 5 4 5-4" §s/><path d="M7 41l5-4 5 4 5-4 5 4 5-4 5 4 5-4 5 4 5-4" §s/>',
	"p_hieb": '<path d="M10 47l11-12 6 5-11 12z" §f/><path d="M25 37c2-11 10-21 21-25 2 9-4 19-13 23" §s/><path d="M27 36c6-4 10-10 12-16" §d/>',
	"p_jaeger": '<path d="M9 47L44 12" §s/><path d="M46 9l-12 3 9 9z" §f/><path d="M7 33c6-6 10 2 16-4s10 2 16-4" §s/>',
	# Schlüsselsteine: Waage, Feder im Wind, Schakal-Standarte, Ibis mit Schreibpalette
	"k_ermittler": '<path d="M28 9v37M16 46h24M9 18h38" §s/><path d="M9 18l-5 12h10zM47 18l-5 12h10z" §s/><path d="M4 30c2 4 8 4 10 0M42 30c2 4 8 4 10 0" §f/><circle cx="28" cy="8" r="3" §f/>',
	"k_moench": '<path d="M20 48C12 36 14 16 24 6c4 10 4 28-4 42z" §f/><path d="M30 18c8-2 14 2 14 8s-6 8-10 4M30 31c10-2 18 2 18 8s-8 9-12 4" §s/>',
	"k_jaegerin": '<path d="M13 26l4-14 4 8h10l6-8 2 10-6 8H17z" §f/><path d="M28 30v18M18 48h20" §s/><path d="M9 34h38" §s/>',
	"k_forensiker": '<path d="M11 23c2-8 10-12 18-10l7-4c2 4-1 7-4 8 0 8-6 14-14 14" §f/><path d="M36 8c6 4 10 10 10 16" §s/><path d="M15 36h26v10H15z" §s/><circle cx="22" cy="41" r="2" §f/><circle cx="30" cy="41" r="2" §f/>',
	"potion": '<path d="M22 9h12v8c8 4 10 17 4 28H18c-6-11-4-24 4-28z" §f/><path d="M19 30h18M22 13h12" §d/>',
}

static func svg(id: String, cls: String) -> String:
	var t: Array = TAFEL.get(cls, TAFEL[""])
	var g: String = G.get(id, "")
	g = g.replace("§s", 'fill="none" stroke="url(#au)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"')
	g = g.replace("§f", 'fill="url(#au)"')
	g = g.replace("§d", 'fill="none" stroke="#0b1120" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"')
	return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56" width="56" height="56"><defs>'
		+ '<radialGradient id="bg" gradientUnits="userSpaceOnUse" cx="28" cy="20" r="40"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % [t[0], t[1]]
		+ '<linearGradient id="au" gradientUnits="userSpaceOnUse" x1="0" y1="6" x2="0" y2="50"><stop offset="0" stop-color="#fff0b8"/><stop offset="0.45" stop-color="#e8b04a"/><stop offset="1" stop-color="#8f5d1d"/></linearGradient></defs>'
		+ '<rect x="1.5" y="1.5" width="53" height="53" rx="8" fill="url(#bg)"/>'
		+ '<rect x="3.6" y="3.6" width="48.8" height="48.8" rx="6.2" fill="none" stroke="#c9a04a" stroke-width="0.9" opacity="0.75"/>'
		+ '<path d="M24 3.6h8M24 52.4h8M3.6 24v8M52.4 24v8" stroke="#fff0b8" stroke-width="1.4" stroke-linecap="round" opacity="0.8"/>'
		+ g + '</svg>')

# zu welcher Klasse eine Fähigkeit gehört (Rotbier: keine)
static func cls_of(id: String) -> String:
	if id.begins_with("k_"):
		return id.substr(2)
	if id.begins_with("p_"):
		return "basalt"
	for c in Klassen.ORDER:
		var C: Dictionary = Klassen.CLS[c]
		if C.sk.has(id) or C.rmb == id:
			return c
	return ""

# Zeichen ohne Tafel, weiß auf durchsichtig: als Maske für glühende Runen (Farbe und Pulsieren macht der Shader).
static func _roh(id: String) -> String:
	var g: String = G.get(id, "")
	g = g.replace("§s", 'fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"')
	g = g.replace("§f", 'fill="#fff"')
	return g.replace("§d", 'fill="none" stroke="#000" stroke-opacity="0.55" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"')

# Zeichenreihe für Wandfriese: n Zeichen nebeneinander, dazwischen Trennstriche
static func band(ids: Array, hoehe := 128) -> ImageTexture:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d 64" width="%d" height="64">' % [ids.size() * 60, ids.size() * 60]
	svg += '<path d="M0 3h%d M0 61h%d" stroke="#fff" stroke-width="2"/>' % [ids.size() * 60, ids.size() * 60]
	for i in ids.size():
		svg += '<g transform="translate(%d 4)">%s</g>' % [i * 60 + 2, _roh(ids[i])]
		svg += '<path d="M%d 12v40" stroke="#fff" stroke-width="1" stroke-opacity="0.5"/>' % (i * 60)
	var img := Image.new()
	img.load_svg_from_string(svg + "</svg>", hoehe / 64.0)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# Runenkreis für den Boden: zwei Ringe, dazwischen die Zeichen, in der Mitte ein Stern
static func kreis(ids: Array, px := 512) -> ImageTexture:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">'
	svg += '<circle cx="200" cy="200" r="194" fill="none" stroke="#fff" stroke-width="3"/><circle cx="200" cy="200" r="128" fill="none" stroke="#fff" stroke-width="2"/>'
	svg += '<circle cx="200" cy="200" r="120" fill="none" stroke="#fff" stroke-width="1" stroke-dasharray="3 9"/>'
	for i in ids.size():
		var a := 360.0 * i / ids.size()
		svg += '<g transform="rotate(%.1f 200 200) translate(172 10)">%s</g>' % [a, _roh(ids[i])]
		svg += '<path d="M200 6v60" stroke="#fff" stroke-width="1" stroke-opacity="0.6" transform="rotate(%.1f 200 200)"/>' % (a + 180.0 / ids.size())
	var stern := ""
	for i in 8:
		var a := TAU * i / 8.0
		var b := a + TAU / 16.0
		stern += "%s%.1f %.1f L%.1f %.1f " % ["M" if i == 0 else "L", 200 + 96 * cos(a), 200 + 96 * sin(a), 200 + 40 * cos(b), 200 + 40 * sin(b)]
	svg += '<path d="%sZ" fill="none" stroke="#fff" stroke-width="2.5" stroke-linejoin="round"/>' % stern
	var img := Image.new()
	img.load_svg_from_string(svg + "</svg>", px / 400.0)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# Masken für die Relief-Symbole (tools/symbole.py): nur Gold (weiß) oder nur die dunkle Ritzung (weiß), 56er Raster
static func maske(id: String, teil: String) -> String:
	var g: String = G.get(id, "")
	var weiss := 'stroke="#fff" stroke-width="3.3" stroke-linecap="round" stroke-linejoin="round"'
	if teil == "gold":
		g = g.replace("§s", 'fill="none" ' + weiss).replace("§f", 'fill="#fff"').replace("§d", 'fill="none" stroke="none"')
	else:
		g = g.replace("§s", 'fill="none" stroke="none"').replace("§f", 'fill="none"').replace("§d", 'fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"')
	return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56" width="56" height="56">' + g + '</svg>'
