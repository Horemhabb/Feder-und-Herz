#!/usr/bin/env python3
# Baut die Startseite für die Web-Fassung (web/huelle.html).
# Titelbild und Zierschrift stecken als data-URI in der Seite: Sie sind sofort da,
# noch bevor der Browser die großen Dateien (index.wasm, index.pck) geholt hat.
# Aufruf: python3 tools/startseite.py   (aus herz-und-feder-3d/)
import base64, io, pathlib
from PIL import Image

WURZEL = pathlib.Path(__file__).resolve().parent.parent

def daten(art, roh):
    return "data:%s;base64,%s" % (art, base64.b64encode(roh).decode())

def bild():
    im = Image.open(WURZEL / "ui/titel.webp").convert("RGB")
    im = im.resize((1280, round(1280 * im.height / im.width)), Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, "WEBP", quality=70, method=6)
    return daten("image/webp", b.getvalue())

SEITE = r"""<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">
<meta name="theme-color" content="#05050a">
<title>$GODOT_PROJECT_NAME</title>
<style>
@font-face { font-family: "Zier"; src: url(@@SCHRIFT@@) format("woff"); font-display: block; }
html, body, #canvas { margin: 0; padding: 0; border: 0; }
body { color: #eadcb8; background: #05050a; overflow: hidden; touch-action: none; }
#canvas { display: block; }
#canvas:focus { outline: none; }
#status {
	position: absolute; inset: 0; z-index: 2;
	background: #05050a url(@@BILD@@) center 30% / cover no-repeat;
	display: flex; flex-direction: column; justify-content: flex-end; align-items: center;
	font-family: "Zier", Georgia, serif; transition: opacity .6s ease;
}
#status::before {
	content: ""; position: absolute; inset: 0; pointer-events: none;
	background: linear-gradient(to bottom, rgba(5,5,10,.15) 0%, rgba(5,5,10,.05) 40%, rgba(5,5,10,.82) 78%, rgba(5,5,10,.96) 100%);
}
#status.weg { opacity: 0; }
.kasten { position: relative; width: min(560px, 86vw); margin-bottom: max(7vh, 34px); text-align: center; }
h1 {
	margin: 0; font-weight: normal; letter-spacing: .14em; font-size: clamp(30px, 6.2vw, 58px);
	color: #f0d58e; text-shadow: 0 0 18px rgba(240,190,90,.35), 0 2px 2px #000;
}
.unter { margin: .2em 0 1.1em; font-size: clamp(13px, 2.2vw, 17px); letter-spacing: .22em; color: #bfae86; }
.leiste {
	position: relative; height: 12px; border-radius: 7px; overflow: hidden;
	background: linear-gradient(#2a2216, #1a140c); border: 1px solid #8a6c34;
	box-shadow: 0 0 0 1px rgba(0,0,0,.6), inset 0 1px 3px rgba(0,0,0,.7);
}
.leiste i {
	position: absolute; left: 0; top: 0; bottom: 0; width: 0%;
	background: linear-gradient(to bottom, #f7e2a0, #d4a443 55%, #9b6f22);
	box-shadow: 0 0 10px rgba(255,200,90,.6); transition: width .25s ease-out;
}
.leiste.offen i { width: 35%; animation: wandern 1.4s ease-in-out infinite alternate; }
@keyframes wandern { from { left: -10%; } to { left: 75%; } }
.zeile { display: flex; justify-content: space-between; margin-top: .55em; font-size: 14px; letter-spacing: .08em; color: #c9b88e; }
#spruch { min-height: 2.6em; margin-top: .9em; font-size: clamp(13px, 2.1vw, 16px); line-height: 1.3; color: #d9c79a; font-style: italic; transition: opacity .5s; }
#status-notice {
	display: none; margin: 1em 0 0; padding: .9em 1em; border-radius: 8px;
	background: rgba(70,24,24,.92); border: 1px solid #b0503a; color: #f2e2c8;
	font-family: Georgia, serif; font-size: 15px; line-height: 1.35;
}
</style>
$GODOT_HEAD_INCLUDE
</head>
<body>
<canvas id="canvas">Dein Browser kann kein Canvas.</canvas>
<noscript>Dieses Spiel braucht JavaScript.</noscript>
<div id="status">
	<div class="kasten">
		<h1>HERZ UND FEDER</h1>
		<div class="unter">DIE ZWÖLF STUNDEN DER NACHT</div>
		<div class="leiste" id="leiste"><i id="balken"></i></div>
		<div class="zeile"><span id="was">Die Barke wird beladen …</span><span id="wieviel"></span></div>
		<div id="spruch"></div>
		<div id="status-notice"></div>
	</div>
</div>
<script src="$GODOT_URL"></script>
<script>
const GODOT_CONFIG = $GODOT_CONFIG;
const GODOT_THREADS_ENABLED = $GODOT_THREADS_ENABLED;
const engine = new Engine(GODOT_CONFIG);
(function () {
	const huelle = document.getElementById('status');
	const leiste = document.getElementById('leiste');
	const balken = document.getElementById('balken');
	const was = document.getElementById('was');
	const wieviel = document.getElementById('wieviel');
	const spruch = document.getElementById('spruch');
	const notiz = document.getElementById('status-notice');
	const SPRUECHE = [
		'„Leicht wie die Feder der Maat soll dein Herz sein.“',
		'Die Sonne fährt in der Barke durch zwölf Stunden der Nacht.',
		'Wer die Namen der Tore kennt, dem öffnen sie sich.',
		'Die Jägerin jagt nie allein: ihr Fuchs ist schneller als jeder Pfeil.',
		'Die Ba-Seele flattert dorthin, wo ein Name vergessen wurde.',
		'Feuerschalen erinnern sich an jeden, der sie entzündet.',
	];
	let n = Math.floor(Math.random() * SPRUECHE.length), fertig = false, fehler = false;
	function naechster() {
		spruch.style.opacity = 0;
		setTimeout(() => { spruch.textContent = SPRUECHE[n++ % SPRUECHE.length]; spruch.style.opacity = 1; }, 450);
	}
	naechster();
	const uhr = setInterval(naechster, 4200);
	function mb(b) { return (b / 1048576).toFixed(b < 10485760 ? 1 : 0); }
	function fehlschlag(err) {
		console.error(err);
		fehler = true;
		clearInterval(uhr);
		notiz.textContent = (err instanceof Error) ? err.message : (typeof err === 'string' ? err : 'Ein unbekannter Fehler ist aufgetreten.');
		notiz.style.display = 'block';
		was.textContent = 'Die Barke ist auf Grund gelaufen.';
	}
	function weg() {
		if (fehler) return;
		clearInterval(uhr);
		huelle.classList.add('weg');
		setTimeout(() => huelle.remove(), 650);
	}
	const fehlt = Engine.getMissingFeatures({ threads: GODOT_THREADS_ENABLED });
	if (fehlt.length !== 0) {
		fehlschlag('Diesem Browser fehlt etwas, das das Spiel braucht:\n' + fehlt.join('\n'));
		return;
	}
	engine.startGame({
		'onProgress': function (jetzt, gesamt) {
			if (jetzt > 0 && gesamt > 0) {
				leiste.classList.remove('offen');
				const p = Math.min(1, jetzt / gesamt);
				balken.style.width = (p * 100).toFixed(1) + '%';
				wieviel.textContent = mb(jetzt) + ' / ' + mb(gesamt) + ' MB';
				if (p >= 1 && !fertig) {
					fertig = true;
					was.textContent = 'Die Waage wird aufgestellt …';
				}
			} else {
				leiste.classList.add('offen');
				wieviel.textContent = jetzt > 0 ? mb(jetzt) + ' MB' : '';
			}
		},
	}).then(weg, fehlschlag);
}());
</script>
</body>
</html>
"""

def startbild():
    # Startbild der Engine (application/boot_splash/image): Godot liest dort nur PNG.
    # 800 Pixel breit und auf 256 Farben gerechnet, damit es das Paket kaum belastet (etwa 110 KB).
    im = Image.open(WURZEL / "ui/titel.webp").convert("RGB").resize((800, 452), Image.LANCZOS)
    im.quantize(256, method=Image.MEDIANCUT, dither=Image.FLOYDSTEINBERG).save(WURZEL / "ui/start.png", optimize=True)

def main():
    startbild()
    schrift = daten("font/woff", (WURZEL / "ui/fonts/almendra_sc.woff").read_bytes())
    seite = SEITE.replace("@@BILD@@", bild()).replace("@@SCHRIFT@@", schrift)
    ziel = WURZEL / "web/huelle.html"
    ziel.parent.mkdir(exist_ok=True)
    ziel.write_text(seite, encoding="utf-8")
    print(ziel, len(seite) // 1024, "KB")

if __name__ == "__main__":
    main()
