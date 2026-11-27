@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Einbauen (Fassung 5.4.0): bringt die ausgewaehlten Bilder aus ComfyUI ins Spiel.
# Symbole: zuschneiden, Rahmen wie tools/symbole/wand/magie.py (abgerundete Tafel, duenne Goldlinie, Schein in der Klassenfarbe),
# 256 x 256 als WebP nach herz-und-feder-3d/ui/symbole/. Portraets: auf 717 x 960 zuschneiden, WebP nach ui/portraits/.
# Hueter: auf 560 x 720 zuschneiden, WebP nach ui/hueter/. Akttafeln: 1280 x 720, WebP nach ui/akte/.
# Die Auswahl steht in bildwerk_plan.json unter "einbau". Ablage: C:\CF neben bildwerk.bat und bildwerk_plan.json.
#
# Aufruf:  einbauen.bat            Symbole, Portraets und Texturen aus der Auswahl einbauen (wie bisher)
#          einbauen.bat symbole    nur die Symbole
#          einbauen.bat portraets  nur die Portraets
#          einbauen.bat texturen t09_sand   nur diese Textur (Namen hinter der Art bauen nur diese Bilder)
#          einbauen.bat texturen   nur die Texturen (Helligkeit ausgleichen, Naht glaetten, Normalenkarte, nach textures/)
#          einbauen.bat hueter     nur die Hueterbilder (Auftritt im Kampf und Bildmarke in der Hueter-Leiste)
#          einbauen.bat akttafeln  nur die Bilder hinter den Akttafeln
#          einbauen.bat <art> [namen]   eine der neuen Arten (Liste: einbauen.bat hilfe), z. B. "einbauen.bat zeichen z1"
#          einbauen.bat t09_sand   ein Name ohne Art: wird in allen Arten gesucht
#          einbauen.bat pruefen    nur messen und Vorschau bauen, nichts schreiben (fuer alle Arten mit Auswahl)
# Hueter, Akttafeln und die neuen Arten gehoeren nicht zum Aufruf ohne Namen, der bleibt wie bisher.
#
# Das Skript sucht dein Repo (Ordner mit herz-und-feder-3d\project.godot) und merkt sich den Ort in bildwerk_ort.txt.
# Findet es keins, landen die Dateien nur in ComfyUI\output\bildwerk\fuers_spiel\ (zum Hochladen von Hand).
import glob, json, os, shutil, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

VERSION = "5.4.0"
ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
PLAN = os.path.join(ROOT, "bildwerk_plan.json")
OUTPUT = os.path.join(ROOT, "ComfyUI", "output")
FUERS_SPIEL = os.path.join(OUTPUT, "bildwerk", "fuers_spiel")
ORT = os.path.join(ROOT, "bildwerk_ort.txt")

# Klassen wie in tools/symbole/wand/zeichen.py (ZU) und Farben wie in magie.py (CL: Grundton, Schein)
ZU = {}
for k, ids in {"ermittler": ["whirl", "dash", "oath", "udjat", "beam", "k_ermittler"], "moench": ["flurry", "step", "mantra", "palm", "wave", "k_moench"],
               "jaegerin": ["salve", "roll", "hetz", "rain", "pierce", "k_jaegerin"], "forensiker": ["chain", "blink", "glass", "nova", "meteor", "k_forensiker"],
               "": ["potion"]}.items():
    for i in ids:
        ZU[i] = k
CL = {"ermittler": ((40, 90, 200), (120, 190, 255)), "moench": ((20, 150, 140), (110, 255, 225)), "jaegerin": ((190, 70, 40), (255, 170, 90)),
      "forensiker": ((130, 70, 210), (210, 150, 255)), "basalt": ((90, 80, 70), (255, 215, 140)), "": ((190, 110, 30), (255, 210, 120))}


def klasse(id_):
    return "basalt" if id_.startswith("p_") else ZU.get(id_, "")


def asc(s):
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("Ä", "Ae"), ("Ö", "Oe"), ("Ü", "Ue"), ("ß", "ss")):
        s = s.replace(a, b)
    return s.encode("ascii", "replace").decode("ascii")


# ---------------------------------------------------------------- Repo finden

def ist_repo(pfad):
    return pfad and os.path.exists(os.path.join(pfad, "herz-und-feder-3d", "project.godot"))


def suche(start, tiefe):
    auslassen = {"appdata", "windows", "program files", "program files (x86)", "programdata", "$recycle.bin", "node_modules", ".git",
                 "comfyui", "python_embeded", "system volume information"}
    stapel = [(start, 0)]
    while stapel:
        pfad, t = stapel.pop()
        if ist_repo(pfad):
            return pfad
        if t >= tiefe:
            continue
        try:
            for e in os.scandir(pfad):
                if e.is_dir(follow_symlinks=False) and e.name.lower() not in auslassen:
                    stapel.append((e.path, t + 1))
        except Exception:
            pass
    return None


def finde_repo():
    if os.environ.get("BILDWERK_REPO"):
        return os.environ["BILDWERK_REPO"]
    if os.path.exists(ORT):
        p = open(ORT, encoding="utf-8").read().strip()
        if ist_repo(p):
            return p
    print("Suche dein Repo (Ordner mit herz-und-feder-3d\\project.godot) ...")
    gefunden = suche(os.path.expanduser("~"), 4)
    if not gefunden and os.name == "nt":
        for lw in "CDEFGH":
            if os.path.exists(lw + ":\\"):
                gefunden = suche(lw + ":\\", 3)
                if gefunden:
                    break
    if gefunden:
        a = input("Repo gefunden: %s\nStimmt das? [J/n]: " % gefunden).strip().lower()
        if a.startswith("n"):
            gefunden = None
    if not gefunden:
        p = input("Pfad zum Repo-Ordner eingeben (der Ordner, in dem herz-und-feder-3d liegt), oder leer lassen: ").strip().strip('"')
        gefunden = p if ist_repo(p) else None
        if p and not gefunden:
            print("Dort liegt kein herz-und-feder-3d\\project.godot.")
    if gefunden:
        open(ORT, "w", encoding="utf-8").write(gefunden)
    return gefunden


# ---------------------------------------------------------------- Bildbearbeitung

def quelle(rel):
    dateien = sorted(glob.glob(os.path.join(OUTPUT, rel.replace("/", os.sep) + "_*.png")))
    return dateien[-1] if dateien else None


def tafel(N, rad=0.12, rand=0.015):
    y, x = np.mgrid[0:N, 0:N].astype(np.float32) / N
    dx = np.maximum(np.maximum(rand + rad - x, x - (1 - rand - rad)), 0)
    dy = np.maximum(np.maximum(rand + rad - y, y - (1 - rand - rad)), 0)
    d = np.sqrt(dx * dx + dy * dy) - rad
    alpha = np.clip(-d * N / 2, 0, 1)
    inner = np.minimum(np.minimum(x - rand, 1 - rand - x), np.minimum(y - rand, 1 - rand - y))
    r = np.sqrt((x - 0.5) ** 2 + (y - 0.47) ** 2)
    return alpha, inner, r


def symbol(pfad, id_, zoom, farbe=None):
    """Zuschnitt, dann der Rahmen wie bei magie.py: Rand abdunkeln, Schein der Klassenfarbe innen am Rand, duenne Goldlinie, runde Ecken.
    farbe: eigene Scheinfarbe (RGB) statt der Klassenfarbe, z. B. fuer die Zeichen der Champion-Eigenschaften."""
    N = 512
    im = Image.open(pfad).convert("RGB")
    w, h = im.size
    s = int(min(w, h) * zoom)
    im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s)).resize((N, N), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    alpha, inner, r = tafel(N)
    _, hl = [np.array(c, np.float32) for c in CL[klasse(id_)]]
    if farbe is not None:
        hl = np.array(farbe, np.float32)
    b *= (1 - 0.45 * np.clip((r - 0.38) / 0.4, 0, 1) ** 2)[..., None]               # Rand ruhiger
    schein = np.exp(-((inner - 0.045) / 0.030) ** 2) * 0.20                          # Klassenfarbe innen am Rahmen (dezent)
    b = b * (1 - schein[..., None] * 0.5) + hl * schein[..., None]
    rl = np.exp(-((inner - 0.04) / 0.005) ** 2)                                       # duenne Goldlinie
    b += np.array([225, 185, 100], np.float32) * rl[..., None] * 0.85
    out = Image.fromarray(np.dstack([np.clip(b, 0, 255), alpha * 255]).astype(np.uint8), "RGBA")
    return out.resize((256, 256), Image.LANCZOS)


def portraet(pfad, zoom=0.66, oben=0.03):
    """Auf 717 x 960 zuschneiden. Im Gespraech erscheint das Bild nur 192 x 256 Pixel gross, darum rueckt der Zuschnitt dicht an Kopf und
    Schultern: zoom = Anteil der Bildbreite, der bleibt (kleiner = naeher dran), oben = Abstand vom oberen Rand als Anteil der Bildhoehe."""
    im = Image.open(pfad).convert("RGB")
    w, h = im.size
    ziel = 717 / 960
    cw = int(w * zoom)
    ch = int(cw / ziel)
    if ch > h:                      # Bild zu flach fuer diesen Zoom: Hoehe voll nutzen
        ch = h
        cw = int(ch * ziel)
    x0 = (w - cw) // 2
    y0 = min(int(h * oben), h - ch)
    return im.crop((x0, y0, x0 + cw, y0 + ch)).resize((717, 960), Image.LANCZOS)


def hueterbild(pfad, zoom=0.94, oben=0.02):
    """Auf 560 x 720 zuschneiden (dasselbe Seitenverhaeltnis wie die Quelle 896 x 1152). Der Hueter erscheint im Spiel gross als
    Hochformat und klein (56 x 72) in der Leiste. Darum nur wenig enger als das ganze Bild, waagrecht mittig, oben ein schmaler Rand weg:
    zoom = Anteil der Bildbreite, der bleibt, oben = Abstand vom oberen Rand als Anteil der Bildhoehe."""
    im = Image.open(pfad).convert("RGB")
    w, h = im.size
    ziel = 560 / 720
    cw = int(w * zoom)
    ch = int(cw / ziel)
    if ch > h:
        ch = h
        cw = int(ch * ziel)
    x0 = (w - cw) // 2
    y0 = max(0, min(int(h * oben), h - ch))
    return im.crop((x0, y0, x0 + cw, y0 + ch)).resize((560, 720), Image.LANCZOS)


def akttafel(pfad):
    """Auf 1280 x 720 bringen: zuerst mittig aufs Seitenverhaeltnis 16 zu 9 zuschneiden, dann skalieren (die Quelle hat meist schon diese Groesse)."""
    im = Image.open(pfad).convert("RGB")
    w, h = im.size
    ziel = 1280 / 720
    if w / h > ziel:
        cw, ch = int(h * ziel), h
    else:
        cw, ch = w, int(w / ziel)
    x0, y0 = (w - cw) // 2, (h - ch) // 2
    im = im.crop((x0, y0, x0 + cw, y0 + ch))
    return im if im.size == (1280, 720) else im.resize((1280, 720), Image.LANCZOS)

# ---------------------------------------------------------------- Texturen (wie tools/texturen.py)

NAHT = 3   # Pixel beiderseits der Kachelnaht, die ueberblendet werden (bei 1024 Pixeln)


def verlauf_weg(a, block=32):
    """Helligkeitsverlauf quer ueber das Bild (Licht von einer Seite) ganz herausrechnen: eine glatte Flaeche zweiten Grades
    je Farbkanal anpassen und dadurch teilen. ausgleich() allein kann das nicht, weil sein Weichzeichner ueber die Naht
    hinweg rechnet und den Sprung oben/unten dabei mittelt. Der Rest des Verlaufs machte an jeder Kachelnaht eine Kante;
    schraeg von oben sah man sie als Rautengitter ueber den ganzen Boden (Sand in Fassung 4.1.4). Mittel bleibt gleich."""
    n = a.shape[0]
    k = n // block
    m = a.astype(np.float32).reshape(k, block, k, block, 3).mean((1, 3))
    y, x = (np.mgrid[0:k, 0:k] + 0.5) / k - 0.5
    A = np.stack([np.ones_like(x), x, y, x * x, x * y, y * y], -1).reshape(-1, 6)
    Y, X = (np.mgrid[0:n, 0:n] + 0.5) / n - 0.5
    B = np.stack([np.ones_like(X), X, Y, X * X, X * Y, Y * Y], -1)
    r = a.astype(np.float32)
    for c in range(3):
        coef = np.linalg.lstsq(A, m[..., c].reshape(-1), rcond=None)[0]
        r[..., c] *= coef[0] / np.maximum(B @ coef, 4.0)
    r *= a.reshape(-1, 3).mean(0) / np.maximum(r.reshape(-1, 3).mean(0), 1.0)
    return np.clip(r + 0.5, 0, 255).astype(np.uint8)


def ausgleich(a, staerke=0.7):
    """KI-Bilder haben oft einen Helligkeitsverlauf (Mitte heller als der Rand): wiederholt sieht man Flecken. Ausgleich mit einem sehr weichen Mittelwert."""
    n = a.shape[0]
    p = n // 4
    t = np.pad(a, ((p, p), (p, p), (0, 0)), mode="wrap")
    weich = np.asarray(Image.fromarray(t).filter(ImageFilter.GaussianBlur(n / 10)))[p:-p, p:-p].astype(np.float32)
    mittel = weich.reshape(-1, 3).mean(0)
    flach = a.astype(np.float32) * (mittel / np.maximum(weich, 8.0))
    return np.clip(a.astype(np.float32) * (1 - staerke) + flach * staerke, 0, 255).astype(np.uint8)


def naht_glaetten(a):
    n = a.shape[0]
    r = np.roll(np.roll(a, n // 2, 0), n // 2, 1).astype(np.float32)
    blur = np.asarray(Image.fromarray(r.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.0))).astype(np.float32)
    w = np.clip(1.0 - np.abs(np.arange(n) - (n // 2 - 0.5)) / NAHT, 0, 1)
    wmax = np.maximum(w[None, :, None], w[:, None, None])
    r = r * (1 - wmax) + blur * wmax
    return np.clip(np.roll(np.roll(r, -(n // 2), 0), -(n // 2), 1), 0, 255).astype(np.uint8)


def kreuzblende(a, breite=0.15):
    """Grosse Spruenge an der Naht (z. B. ein Lichtverlauf im Bild): den Rand weich in die um die halbe Bildgroesse verschobene Fassung ueberblenden.
    Danach passen linker und rechter Rand lueckenlos aneinander. Kostet etwas Schaerfe nahe dem Rand, darum nur wenn noetig."""
    n = a.shape[0]
    d = np.minimum(np.arange(n), n - 1 - np.arange(n)) / (breite * n)
    d = np.clip(d, 0, 1)
    w = d * d * (3 - 2 * d)
    r = a.astype(np.float32)
    r = r * w[None, :, None] + np.roll(r, n // 2, 1) * (1 - w[None, :, None])
    r = r * w[:, None, None] + np.roll(r, n // 2, 0) * (1 - w[:, None, None])
    return np.clip(r, 0, 255).astype(np.uint8)


def normalenkarte(im, staerke=2.2):
    h = np.asarray(im.convert("L").filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255.0
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nx, ny, nz = -dx * staerke * 8, dy * staerke * 8, np.ones_like(h)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    return Image.fromarray(((np.stack([nx / l, ny / l, nz / l], -1) * 0.5 + 0.5) * 255).astype(np.uint8))


# naht_mass steht im gemeinsamen Block weiter unten (gleich in bildwerk.bat).


def textur(pfad):
    """Quelle (1024 Pixel) -> kachelbares Bild und Normalenkarte."""
    a = np.asarray(Image.open(pfad).convert("RGB").resize((1024, 1024), Image.LANCZOS))
    vorher = naht_mass(a)
    a = verlauf_weg(a)
    a = ausgleich(a)
    if naht_mass(a) > 3.0:
        a = kreuzblende(a)
    a = naht_glaetten(a)
    im = Image.fromarray(a)
    return im, normalenkarte(im), vorher, naht_mass(a)


# ---------------------------------------------------------------- gemeinsam: Messwerte und Freistellen
# Dieser Block steht gleich in bildwerk.bat und einbauen.bat (pruefe_plan.py vergleicht beide). Nur numpy und PIL.

def lin_hell(a):
    """Mittlere lineare Helligkeit 0..1 (wie das Licht im Spiel rechnet). Das Spiel erwartet bei hellem Stein etwa 0,24."""
    f = a[..., :3].astype(np.float32) / 255.0
    return float(np.where(f <= 0.04045, f / 12.92, ((f + 0.055) / 1.055) ** 2.4).mean())


def _grau(a, n):
    return np.asarray(Image.fromarray(np.ascontiguousarray(a[..., :3])).convert("L").resize((n, n), Image.LANCZOS)).astype(np.float32)


def schaerfe(a):
    """Feine Zeichnung im Verhaeltnis zum Kontrast, etwa 0..100: verwaschene Bilder liegen unter 15."""
    g = _grau(a, 512)
    lap = np.abs(4 * g - np.roll(g, 1, 0) - np.roll(g, -1, 0) - np.roll(g, 1, 1) - np.roll(g, -1, 1))[1:-1, 1:-1]
    return float(100.0 * lap.mean() / (np.abs(g - g.mean()).mean() * 4 + 1.0))


def naht_mass(a):
    g = a[..., :3].astype(np.float32).mean(2)
    return (np.abs(g[:, 0] - g[:, -1]).mean() / max(np.abs(np.diff(g, axis=1)).mean(), 1e-3) + np.abs(g[0, :] - g[-1, :]).mean() / max(np.abs(np.diff(g, axis=0)).mean(), 1e-3)) / 2


def verlauf_mass(a, k=4):
    """Hellstes durch dunkelstes von k x k Feldern: 1,0 = gleichmaessig, ab 1,3 sieht man den Lichtverlauf beim Kacheln."""
    g = _grau(a, 256)
    m = g.reshape(k, 256 // k, k, 256 // k).mean((1, 3))
    return float(m.max() / max(m.min(), 1.0))


def _korrlaenge(p):
    """Abstand in Pixeln, bei dem die Autokorrelation eines Flecks auf die Haelfte faellt (ein Mass fuer die Groesse der Zeichnung)."""
    p = p - p.mean()
    n = p.shape[0]
    ac = np.fft.fftshift(np.real(np.fft.ifft2(np.abs(np.fft.fft2(p, s=(2 * n, 2 * n))) ** 2)))
    ac = ac / max(ac[n, n], 1e-9)
    y, x = np.mgrid[-n:n, -n:n]
    r = np.sqrt(x * x + y * y).astype(int).ravel()
    prof = np.bincount(r, ac.ravel()) / np.maximum(np.bincount(r), 1)
    for i in range(1, n // 2):
        if prof[i] < 0.5:
            return i - 1 + (prof[i - 1] - 0.5) / max(prof[i - 1] - prof[i], 1e-9)
    return n / 2.0


def perspektive(a):
    """Unterschied der Detailgroesse zwischen oben und unten (und links und rechts), 1,0 = ueberall gleich.
    Ein 'von oben' gemalter Boden mit Perspektive hat oben feine, unten grobe Zeichnung: so etwas kachelt nie.
    Nur wenn die Mitte zwischen beiden Raendern liegt (stetiger Verlauf), zaehlt der volle Unterschied; sonst ist es
    eher ein unruhiges Bild. Grob: Bilder ohne Perspektive liegen bis etwa 1,25, deutlich schraeg gemalte ueber 1,4."""
    im = Image.fromarray(np.ascontiguousarray(a[..., :3])).convert("L").resize((256, 256), Image.LANCZOS)
    g = np.asarray(im).astype(np.float32) - np.asarray(im.filter(ImageFilter.GaussianBlur(10))).astype(np.float32)
    k, s = 64, (256 - 64) // 2

    def achse(fleck):
        w = [float(np.median([_korrlaenge(fleck(j, i)) for i in range(4)])) for j in range(3)]
        q = max(w[0] / w[2], w[2] / w[0])
        stetig = min(w[0], w[2]) * 0.97 <= w[1] <= max(w[0], w[2]) * 1.03
        return q if stetig else q ** 0.5
    senk = achse(lambda j, i: g[j * s:j * s + k, i * k:(i + 1) * k])
    waag = achse(lambda j, i: g[i * k:(i + 1) * k, j * s:j * s + k])
    return max(senk, waag)


def rand_hell(a, breite=0.04):
    """Mittlere Helligkeit 0..1 am aeusseren Rand: Bilder auf Schwarz muessen dort fast 0 haben, sonst sieht man ein Viereck."""
    g = a[..., :3].astype(np.float32).max(2) / 255.0
    b = max(1, int(min(g.shape) * breite))
    return float(np.concatenate([g[:b].ravel(), g[-b:].ravel(), g[:, :b].ravel(), g[:, -b:].ravel()]).mean())


def grundfarbe(a, breite=0.03):
    """Farbe des Hintergrunds aus dem Rand (Median) und wie gleichmaessig er ist (Streuung 0..1, unter 0,05 gut)."""
    f = a[..., :3].astype(np.float32)
    b = max(1, int(min(f.shape[:2]) * breite))
    rand = np.concatenate([f[:b].reshape(-1, 3), f[-b:].reshape(-1, 3), f[:, :b].reshape(-1, 3), f[:, -b:].reshape(-1, 3)])
    mitte = np.median(rand, 0)
    return mitte, float(np.abs(rand - mitte).mean() / 255.0)


def alpha_aus_schwarz(a, schwarz=0.06, rand=0.08):
    """Leuchtendes auf Schwarz (Glut, Funken, Zeichen) -> RGBA: Helligkeit wird Deckkraft, die Farbe bleibt voll.
    schwarz: Rest-Grau des Hintergrunds, das ganz durchsichtig wird. rand: Anteil am Bildrand, der weich auf 0 laeuft."""
    f = a[..., :3].astype(np.float32) / 255.0
    l = np.clip((f.max(2) - schwarz) / (1.0 - schwarz), 0, 1)
    h, w = l.shape
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.minimum(np.minimum(x, w - 1 - x) / (w * rand + 1e-6), np.minimum(y, h - 1 - y) / (h * rand + 1e-6))
    al = l * np.clip(d, 0, 1) ** 2
    col = np.clip(f / np.maximum(f.max(2, keepdims=True), 1e-4), 0, 1)
    return np.dstack([col * 255, al * 255]).astype(np.uint8)


def schwarz_putzen(a, schwarz=0.05, rand=0.08):
    """Fuer additive Bilder (RGB auf Schwarz): Rest-Grau abziehen, Rand weich auf reines Schwarz. Was additiv auf dem Boden
    liegt, darf am Rand nicht einmal ein wenig grau sein, sonst sieht man ein helles Viereck."""
    f = a[..., :3].astype(np.float32) / 255.0
    f = np.clip((f - schwarz) / (1.0 - schwarz), 0, 1)
    h, w = f.shape[:2]
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.minimum(np.minimum(x, w - 1 - x) / (w * rand + 1e-6), np.minimum(y, h - 1 - y) / (h * rand + 1e-6))
    return (f * (np.clip(d, 0, 1) ** 2)[..., None] * 255).astype(np.uint8)


def alpha_aus_grund(a, innen=0.06, aussen=0.16):
    """Gegenstand auf einfarbigem Grund -> RGBA. Abstand jeder Farbe zur Grundfarbe (aus dem Rand geschaetzt):
    unter 'innen' durchsichtig, ueber 'aussen' deckend, dazwischen weich. Der Farbstich des Grundes wird aus den
    halbdurchsichtigen Kanten herausgerechnet, damit kein grauer Saum bleibt."""
    f = a[..., :3].astype(np.float32)
    g, _ = grundfarbe(a)
    d = np.sqrt((((f - g) / 255.0) ** 2).sum(2) / 3.0)
    d = np.asarray(Image.fromarray((np.clip(d, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32) / 255.0
    t = np.clip((d - innen) / (aussen - innen), 0, 1)
    al = t * t * (3 - 2 * t)
    col = np.where(al[..., None] > 0.02, (f - (1 - al[..., None]) * g) / np.maximum(al[..., None], 0.02), f)
    return np.dstack([np.clip(col, 0, 255), al * 255]).astype(np.uint8)


def zuschnitt_alpha(rgba, rand=0.08, schwelle=10):
    """Auf den deckenden Teil zuschneiden (quadratisch, mittig) mit etwas Luft rundherum."""
    al = rgba[..., 3]
    ys, xs = np.where(al > schwelle)
    if len(xs) == 0:
        return rgba
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    s = int(max(x1 - x0, y1 - y0) * (1 + 2 * rand))
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    out = np.zeros((s, s, 4), np.uint8)
    sx0, sy0 = cx - s // 2, cy - s // 2
    qx0, qy0 = max(0, sx0), max(0, sy0)
    qx1, qy1 = min(rgba.shape[1], sx0 + s), min(rgba.shape[0], sy0 + s)
    out[qy0 - sy0:qy1 - sy0, qx0 - sx0:qx1 - sx0] = rgba[qy0:qy1, qx0:qx1]
    return out


def rgba_skalieren(rgba, groesse):
    """RGBA ohne dunkle Saeume verkleinern (vormultipliziert)."""
    return np.asarray(Image.fromarray(rgba, "RGBA").convert("RGBa").resize(groesse, Image.LANCZOS).convert("RGBA"))


def messwerte(a, art):
    """Messwerte fuer die Auswahl. art: kachel, band, schwarz, grau oder leer. Gibt (Kurztext, Punktzahl oder None)."""
    w = {"S": schaerfe(a)}
    if art in ("kachel", "band"):
        w.update(H=lin_hell(a), N=naht_mass(a), P=perspektive(a), V=verlauf_mass(a))
        p = w["S"] - 60 * max(0.0, w["P"] - 1.15) - 4 * max(0.0, w["N"] - 2.0) - 30 * max(0.0, w["V"] - 1.3) - (15 if w["H"] < 0.05 else 0)
        txt = "S%d H%.2f N%.1f P%.2f V%.2f" % (w["S"], w["H"], w["N"], w["P"], w["V"])
    elif art == "schwarz":
        w["R"] = rand_hell(a)
        p = w["S"] - 400 * max(0.0, w["R"] - 0.01)
        txt = "S%d Rand%.3f" % (w["S"], w["R"])
    elif art == "grau":
        _, w["G"] = grundfarbe(a)
        al = alpha_aus_grund(a)[..., 3]
        w["R"] = rand_hell(np.dstack([al, al, al]))
        p = w["S"] - 300 * max(0.0, w["G"] - 0.04) - 200 * max(0.0, w["R"] - 0.02)
        txt = "S%d Grund%.2f Rand%.2f" % (w["S"], w["G"], w["R"])
    else:
        w["H"] = lin_hell(a)
        p = None
        txt = "S%d H%.2f" % (w["S"], w["H"])
    return txt, p, w
# ---------------------------------------------------------------- Ende gemeinsam


# ---------------------------------------------------------------- Neue Arten (5.3): Freistellen, Bander, Zeichen, Gegenstaende

def _lin(f):
    return np.where(f <= 0.04045, f / 12.92, ((f + 0.055) / 1.055) ** 2.4)


def _srgb(l):
    return np.where(l <= 0.0031308, l * 12.92, 1.055 * np.power(np.maximum(l, 0), 1 / 2.4) - 0.055)


def daempfen(a, ziel):
    """Nur dunkler, nie heller: die lineare Helligkeit auf hoechstens 'ziel' senken. Die Bilder aus ComfyUI waren drei- bis
    neunmal so hell wie das Licht im Spiel erwartet (main.gd › HELL); neue Dateien kommen so gleich passend an und brauchen
    dort keinen eigenen Eintrag. Gibt (Bild, vorher, nachher) zurueck."""
    h = lin_hell(a)
    if not ziel or h <= ziel:
        return a, h, h
    l = _lin(a[..., :3].astype(np.float32) / 255.0) * (ziel / h)
    out = a.copy()
    out[..., :3] = np.clip(_srgb(l) * 255 + 0.5, 0, 255).astype(np.uint8)
    return out, h, lin_hell(out)


def flach_rechteck(a, block=32):
    """Wie verlauf_weg, aber fuer jedes Seitenverhaeltnis (Baender, Wandbilder, Tore): glatte Flaeche zweiten Grades je
    Farbkanal anpassen und herausteilen, damit kein Licht von einer Seite im Bild bleibt."""
    h, w = a.shape[:2]
    ky, kx = max(2, h // block), max(2, w // block)
    m = np.asarray(Image.fromarray(a).resize((kx, ky), Image.BOX)).astype(np.float32)
    y, x = np.mgrid[0:ky, 0:kx]
    y, x = (y + 0.5) / ky - 0.5, (x + 0.5) / kx - 0.5
    A = np.stack([np.ones_like(x), x, y, x * x, x * y, y * y], -1).reshape(-1, 6)
    Y, X = np.mgrid[0:h, 0:w]
    Y, X = (Y + 0.5) / h - 0.5, (X + 0.5) / w - 0.5
    B = np.stack([np.ones_like(X), X, Y, X * X, X * Y, Y * Y], -1)
    r = a.astype(np.float32)
    for c in range(3):
        coef = np.linalg.lstsq(A, m[..., c].reshape(-1), rcond=None)[0]
        r[..., c] *= coef[0] / np.maximum(B @ coef, 4.0)
    r *= a.reshape(-1, 3).mean(0) / np.maximum(r.reshape(-1, 3).mean(0), 1.0)
    return np.clip(r + 0.5, 0, 255).astype(np.uint8)


def naht_x(a, breite=0.12):
    """Nur waagrecht kachelbar machen (Baender, Saeulen): Rand weich in die um die halbe Breite verschobene Fassung ueberblenden."""
    w = a.shape[1]
    d = np.clip(np.minimum(np.arange(w), w - 1 - np.arange(w)) / (breite * w), 0, 1)
    g = (d * d * (3 - 2 * d))[None, :, None]
    r = a.astype(np.float32)
    return np.clip(r * g + np.roll(r, w // 2, 1) * (1 - g), 0, 255).astype(np.uint8)


def naht_mass_x(a):
    g = a[..., :3].astype(np.float32).mean(2)
    return float(np.abs(g[:, 0] - g[:, -1]).mean() / max(np.abs(np.diff(g, axis=1)).mean(), 1e-3))


def zuschneiden(im, w, h):
    """Mittig aufs Seitenverhaeltnis w:h zuschneiden, dann auf w x h bringen."""
    sw, sh = im.size
    if sw / sh > w / h:
        cw, ch = int(sh * w / h), sh
    else:
        cw, ch = sw, int(sw * h / w)
    x0, y0 = (sw - cw) // 2, (sh - ch) // 2
    im = im.crop((x0, y0, x0 + cw, y0 + ch))
    return im if im.size == (w, h) else im.resize((w, h), Image.LANCZOS)


def zeichen_bild(pfad, n):
    """Bodenzeichen (Stufe bodenzeichen): RGB auf reinem Schwarz fuer additives Zeichnen, Rand sicher schwarz."""
    a = np.asarray(Image.open(pfad).convert("RGB").resize((n, n), Image.LANCZOS))
    return Image.fromarray(schwarz_putzen(a, 0.05, 0.10))


def fx_bild(pfad, n, art):
    """Effektbild (Stufe effektbilder): 'add' = RGB auf Schwarz (Glut, Funken, Blitz), 'alpha' = RGBA aus der Helligkeit
    (Rauch, Staub: das Spiel mischt sie normal, dunkler Rauch kann so auch abdunkeln)."""
    a = np.asarray(Image.open(pfad).convert("RGB").resize((n, n), Image.LANCZOS))
    if art == "alpha":
        return Image.fromarray(alpha_aus_schwarz(a, 0.06, 0.12), "RGBA")
    return Image.fromarray(schwarz_putzen(a, 0.05, 0.12))


def band_bild(pfad, w, h, ziel):
    """Fries oder Saeulenmantel: waagrecht kachelbar, ohne Lichtverlauf, gedaempft. Gibt (Bild, Relief, Bericht)."""
    im = Image.open(pfad).convert("RGB")
    a = np.asarray(zuschneiden(im, w, h))
    vorher = naht_mass_x(a)
    a = flach_rechteck(a)
    a = naht_x(a)
    a, h0, h1 = daempfen(a, ziel)
    bild = Image.fromarray(a)
    return bild, normalenkarte(bild, 1.6), "Naht %.2f -> %.2f, Helligkeit %.2f -> %.2f" % (vorher, naht_mass_x(a), h0, h1)


def wand_bild(pfad, w, h, ziel):
    """Wandbild, Tor oder Relief: zuschneiden, Lichtverlauf heraus, gedaempft, mit Relief. Kachelt nicht (ein Bild je Flaeche)."""
    a = np.asarray(zuschneiden(Image.open(pfad).convert("RGB"), w, h))
    a = flach_rechteck(a)
    a, h0, h1 = daempfen(a, ziel)
    bild = Image.fromarray(a)
    return bild, normalenkarte(bild, 1.6), "Helligkeit %.2f -> %.2f" % (h0, h1)


def frei_bild(pfad, n, schatten=0.0, rand=0.08):
    """Gegenstand oder Abziehbild auf einfarbigem Grund -> RGBA n x n, auf den Gegenstand zugeschnitten.
    schatten: weicher dunkler Hof hinter dem Gegenstand (0 = keiner), damit er auf jedem Grund lesbar bleibt."""
    a = np.asarray(Image.open(pfad).convert("RGB"))
    rgba = zuschnitt_alpha(alpha_aus_grund(a), rand)
    klein = rgba_skalieren(rgba, (n, n))
    if schatten > 0:
        al = Image.fromarray(klein[..., 3]).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(n / 40))
        s = np.asarray(al).astype(np.float32) / 255.0 * schatten
        a1 = klein[..., 3].astype(np.float32) / 255.0
        a_out = a1 + s * (1 - a1)
        rgb = klein[..., :3].astype(np.float32) * (a1 / np.maximum(a_out, 1e-4))[..., None]
        klein = np.dstack([np.clip(rgb, 0, 255), a_out * 255]).astype(np.uint8)
    return Image.fromarray(klein, "RGBA")


def abzieh_bild(pfad, n):
    """Abziehbild (Risse, Blut, Sand) fuer den Boden: freigestellt, und zum Rand hin sicher durchsichtig."""
    bild = np.asarray(frei_bild(pfad, n, 0.0, 0.04)).copy()
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    d = np.clip(np.minimum(np.minimum(x, n - 1 - x), np.minimum(y, n - 1 - y)) / (n * 0.06), 0, 1)
    bild[..., 3] = (bild[..., 3].astype(np.float32) * d).astype(np.uint8)
    return Image.fromarray(bild, "RGBA")


ICON_N = 6   # wie Daten.ICON_N: 6 x 6 Felder in ui/icons.webp


def atlas_bauen(einbau, repo, namen, nur_pruefen):
    """Gegenstaende (Stufe gegenstaende): die gewaehlten Felder in den Bildbogen ui/icons.webp setzen. Felder ohne Auswahl
    bleiben, wie sie sind (aus dem Bogen im Repo, vergroessert). Das Spiel teilt den Bogen selbst in 6 x 6 (Daten.icon)."""
    zelle = int(einbau.get("gegenstaende_zelle", 160))
    wahl = einbau.get("gegenstaende", {})
    if not wahl:
        return None, [], []
    basis = None
    for p in ([os.path.join(repo, "herz-und-feder-3d", "ui", "icons.webp")] if repo else []) + [os.path.join(FUERS_SPIEL, "ui", "icons.webp")]:
        if os.path.exists(p):
            basis = Image.open(p).convert("RGBA").resize((zelle * ICON_N, zelle * ICON_N), Image.LANCZOS)
            break
    bogen = basis or Image.new("RGBA", (zelle * ICON_N, zelle * ICON_N), (0, 0, 0, 0))
    fehlt, gesetzt = [], []
    for feld, rel in wahl.items():
        if namen and feld not in namen:
            continue
        pfad = quelle(rel)
        if not pfad:
            fehlt.append(rel)
            continue
        i = int(feld)
        x, y = (i % ICON_N) * zelle, (i // ICON_N) * zelle
        bild = frei_bild(pfad, zelle, float(einbau.get("gegenstaende_schatten", 0.45)), 0.06)
        bogen.paste(Image.new("RGBA", (zelle, zelle), (0, 0, 0, 0)), (x, y))
        bogen.alpha_composite(bild, (x, y))
        gesetzt.append((feld, bild))
        if nur_pruefen:
            print("  Feld %s: %s" % (feld, messwerte(np.asarray(Image.open(pfad).convert("RGB")), "grau")[0]))
    return bogen, gesetzt, fehlt


def vorschau_frei(eintraege, pfad, groesse=160):
    """Freigestellte Bilder auf dem Spielgrund und auf Papyrus nebeneinander, damit Saeume auffallen."""
    try:
        schrift = ImageFont.truetype("arial.ttf", 14)
    except Exception:
        schrift = ImageFont.load_default()
    pro = 8
    zeilen = (len(eintraege) + pro - 1) // pro
    blatt = Image.new("RGB", (pro * (2 * groesse + 20) + 10, zeilen * (groesse + 34) + 10), (16, 14, 18))
    d = ImageDraw.Draw(blatt)
    for k, (id_, bild) in enumerate(eintraege):
        x, y = 10 + (k % pro) * (2 * groesse + 20), 10 + (k // pro) * (groesse + 34)
        b = bild.convert("RGBA").resize((groesse, int(groesse * bild.height / bild.width)), Image.LANCZOS)
        for j, grund in enumerate(((46, 36, 28, 255), (214, 190, 140, 255))):
            g = Image.new("RGBA", b.size, grund)
            g.alpha_composite(b)
            blatt.paste(g.convert("RGB"), (x + j * groesse, y))
        d.text((x, y + b.height + 4), str(id_), fill=(230, 200, 120), font=schrift)
    blatt.save(pfad, quality=90)


# ---------------------------------------------------------------- Ablauf

def schreibe(bild, rel, repo, sicherung, qualitaet):
    """rel z. B. ui/symbole/whirl.webp. Immer nach fuers_spiel, ins Repo nur wenn gefunden (alte Datei vorher sichern)."""
    ziel1 = os.path.join(FUERS_SPIEL, rel.replace("/", os.sep))
    os.makedirs(os.path.dirname(ziel1), exist_ok=True)
    bild.save(ziel1, quality=qualitaet, method=6)
    if repo:
        ziel2 = os.path.join(repo, "herz-und-feder-3d", rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(ziel2), exist_ok=True)
        if os.path.exists(ziel2):
            alt = os.path.join(sicherung, rel.replace("/", os.sep))
            if not os.path.exists(alt):
                os.makedirs(os.path.dirname(alt), exist_ok=True)
                shutil.copy2(ziel2, alt)
        shutil.copy2(ziel1, ziel2)


def vorschau(eintraege, pfad):
    try:
        schrift = ImageFont.truetype("arial.ttf", 14)
    except Exception:
        schrift = ImageFont.load_default()
    pro = 8
    zeilen = (len(eintraege) + pro - 1) // pro
    blatt = Image.new("RGB", (pro * 270 + 10, zeilen * 300 + 60 + 70 * ((len(eintraege) * 68) // (pro * 270) + 1)), (16, 14, 18))
    d = ImageDraw.Draw(blatt)
    for k, (id_, bild) in enumerate(eintraege):
        x, y = 10 + (k % pro) * 270, 10 + (k // pro) * 300
        blatt.paste(bild, (x, y), bild)
        d.text((x, y + 262), id_, fill=(230, 200, 120), font=schrift)
    y = zeilen * 300 + 20
    d.text((10, y), "Spielgroesse 64 px:", fill=(160, 150, 130), font=schrift)
    for k, (id_, bild) in enumerate(eintraege):
        klein = bild.resize((64, 64), Image.LANCZOS)
        blatt.paste(klein, (10 + k * 68 % (pro * 270), y + 22 + (k * 68 // (pro * 270)) * 68), klein)
    blatt.save(pfad, quality=90)


ALTE_ARTEN = ("symbole", "portraets", "texturen", "hueter", "akttafeln")
# Neue Arten (5.3): Name -> (Schluessel unter "einbau", Ziel im Spiel, Beschreibung). Alle bauen nur, was unter dem Schluessel
# ausgewaehlt ist; ein Name hinter der Art baut nur dieses eine Bild. Keine gehoert zum Aufruf ohne Namen.
NEUE_ARTEN = {
    "zeichen": ("zeichen", "ui/zeichen/<id>.webp", "Bodenzeichen: RGB auf Schwarz fuer additives Zeichnen, 1024 px (zeichen_groesse)"),
    "fx": ("fx", "textures/fx/<id>.webp", "Effektbilder: 'add' RGB auf Schwarz oder 'alpha' RGBA (fx_art), 512 px (fx_groesse)"),
    "fries": ("fries", "textures/fries/<id>.jpg und _n.jpg", "Wandbaender: 1024 x 512, waagrecht kachelbar, ohne Lichtverlauf, gedaempft"),
    "saeulen": ("saeulen", "textures/saeule/<id>.jpg und _n.jpg", "Saeulenmantel: 1024 x 1024, waagrecht kachelbar"),
    "gegenstaende": ("gegenstaende", "ui/icons.webp", "Gegenstaende: Feldnummer 0 bis 35 -> Bild, freigestellt in den Bildbogen 6 x 6"),
    "champions": ("champions", "ui/affixe/<id>.webp", "Zeichen der Champion-Eigenschaften: 256 px mit Rahmen in ihrer Farbe"),
    "abzieh": ("abziehbilder", "textures/abzieh/<id>.webp", "Abziehbilder fuer den Boden: freigestellt (RGBA), 512 px (abzieh_groesse)"),
    "wandbilder": ("wandbilder", "textures/wand/<id>.jpg und _n.jpg", "Wandbilder und Reliefs: 1024 x 768, gedaempft, mit Relief"),
    "tore": ("tore", "textures/tor/<id>.jpg und _n.jpg", "Tore und Tueren: 768 x 1024, gedaempft, mit Relief"),
    "ladebilder": ("ladebilder", "ui/laden/<id>.webp", "Ladebilder je Stunde: 1280 x 720"),
    "buchbilder": ("buchbilder", "ui/lexikon/<id>.webp", "Bilder fuers Lexikon im Buch des Thot: 800 x 600"),
    "titel": ("titel", "ui/titel.webp", "Titelbild: 1600 x 905 (ersetzt das jetzige, sofort im Spiel)"),
    "szenen": ("szenen", "ui/szenen/<name>.webp", "Szenenbilder der Zwischensequenzen: 1280 x 720; Namen unter szenen_add als Lichter-Ebene (RGB auf Schwarz)"),
    "zier": ("zier", "ui/zier/gemalt/<name>.webp", "Gemalte Flaechen und Ornamente der Oberflaeche (Groessen in zier_groessen)"),
    "lebewesen": ("lebewesen", "bilder/lebewesen/<name>.webp", "Musterkacheln der Kleintiere: nahtlos, 1024 px; danach Tafel neu rechnen (Claude)"),
}


def baue_neu(art, id_, pfad, einbau):
    """Ein Bild einer neuen Art bauen. Gibt ([(Bild, Pfad im Spiel, Qualitaet)], Bericht)."""
    hz = einbau.get("hell_ziel", {})
    ziel = hz.get(id_, hz.get(art, 0.24))
    if art == "zeichen":
        n = int(einbau.get("zeichen_groesse", 1024))
        return [(zeichen_bild(pfad, n), "ui/zeichen/%s.webp" % id_, 90)], "Rand vorher %.3f" % rand_hell(np.asarray(Image.open(pfad).convert("RGB")))
    if art == "fx":
        n = int(einbau.get("fx_groesse", 512))
        fa = einbau.get("fx_art", {}).get(id_, "add")
        return [(fx_bild(pfad, n, fa), "textures/fx/%s.webp" % id_, 90)], "als %s" % fa
    if art in ("fries", "saeulen"):
        w, h = (1024, 512) if art == "fries" else (1024, 1024)
        bild, relief, txt = band_bild(pfad, w, h, ziel)
        ordner = "fries" if art == "fries" else "saeule"
        return [(bild, "textures/%s/%s.jpg" % (ordner, id_), 88), (relief, "textures/%s/%s_n.jpg" % (ordner, id_), 92)], txt
    if art in ("wandbilder", "tore"):
        w, h = (1024, 768) if art == "wandbilder" else (768, 1024)
        bild, relief, txt = wand_bild(pfad, w, h, ziel)
        ordner = "wand" if art == "wandbilder" else "tor"
        return [(bild, "textures/%s/%s.jpg" % (ordner, id_), 88), (relief, "textures/%s/%s_n.jpg" % (ordner, id_), 92)], txt
    if art == "champions":
        farbe = einbau.get("champions_farben", {}).get(id_)
        bild = symbol(pfad, id_, einbau.get("symbole_zoom", {}).get("standard", 0.9), farbe)
        return [(bild, "ui/affixe/%s.webp" % id_, 92)], ""
    if art == "abzieh":
        n = int(einbau.get("abzieh_groesse", 512))
        _, grund = grundfarbe(np.asarray(Image.open(pfad).convert("RGB")))
        return [(abzieh_bild(pfad, n), "textures/abzieh/%s.webp" % id_, 90)], "Unruhe des Grundes %.2f%s" % (grund, " (hoch: Saeume pruefen)" if grund > 0.05 else "")
    if art == "ladebilder":
        return [(zuschneiden(Image.open(pfad).convert("RGB"), 1280, 720), "ui/laden/%s.webp" % id_, 82)], ""
    if art == "szenen":
        bild = zuschneiden(Image.open(pfad).convert("RGB"), 1280, 720)
        if id_ in einbau.get("szenen_add", []):
            a = np.asarray(bild)
            return [(Image.fromarray(schwarz_putzen(a, 0.05, 0.04)), "ui/szenen/%s.webp" % id_, 88)], "Lichter-Ebene, Rand vorher %.3f" % rand_hell(a)
        return [(bild, "ui/szenen/%s.webp" % id_, 82)], ""
    if art == "zier":
        return zier_bild(id_, pfad, einbau)
    if art == "lebewesen":
        roh = np.asarray(Image.open(pfad).convert("RGB").resize((1024, 1024), Image.LANCZOS))
        bild, _, v, nach = textur(pfad)
        return [(bild, "bilder/lebewesen/%s.webp" % id_, 90)], "Naht %.2f -> %.2f, Perspektive %.2f" % (v, nach, perspektive(roh))
    if art == "buchbilder":
        return [(zuschneiden(Image.open(pfad).convert("RGB"), 800, 600), "ui/lexikon/%s.webp" % id_, 85)], ""
    if art == "titel":
        return [(zuschneiden(Image.open(pfad).convert("RGB"), 1600, 905), "ui/titel.webp", 85)], ""
    raise ValueError(art)


ORNAMENTE = ("fluegelsonne", "udjat", "lotos", "skarabaeus")
REPO = [None]   # gefundenes Repo, damit zier_bild die Groesse der erzeugten Ornamente lesen kann


def zier_bild(name, pfad, einbau):
    """Gemalte Flaeche oder Ornament fuer ui/zier/gemalt/ (Zier.tex nimmt sie statt der erzeugten, ohne Code).
    Ornamente: freigestellt aus Grau und in die Groesse der erzeugten Datei gesetzt (Seitenverhaeltnis bleibt).
    sterne: nahtlos wie eine Textur. Dunkle Gruende: auf hell_ziel gedaempft, damit heller Text lesbar bleibt."""
    gr = einbau.get("zier_groessen", {})
    w, h = gr.get(name, [1024, 1024])
    ziel = "ui/zier/gemalt/%s.webp" % name
    if name in ORNAMENTE:
        # Zier zeichnet Ornamente in der Pixelgroesse der Datei: also genau so gross wie die erzeugte Fassung
        alt = os.path.join(REPO[0], "herz-und-feder-3d", "ui", "zier", name + ".webp") if REPO[0] else ""
        if alt and os.path.exists(alt):
            w, h = Image.open(alt).size
        rgba = alpha_aus_grund(np.asarray(Image.open(pfad).convert("RGB")))
        ys, xs = np.where(rgba[..., 3] > 10)
        if len(xs):
            rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        f = min(w * 0.96 / rgba.shape[1], h * 0.96 / rgba.shape[0])
        klein = rgba_skalieren(np.ascontiguousarray(rgba), (max(1, int(rgba.shape[1] * f)), max(1, int(rgba.shape[0] * f))))
        bild = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        bild.alpha_composite(Image.fromarray(klein, "RGBA"), ((w - klein.shape[1]) // 2, (h - klein.shape[0]) // 2))
        return [(bild, ziel, 92)], "Ornament %d x %d" % (w, h)
    if name == "sterne":
        bild, _, v, nach = textur(pfad)
        return [(bild.resize((w, h), Image.LANCZOS), ziel, 90)], "nahtlos, Naht %.2f -> %.2f" % (v, nach)
    a = np.asarray(zuschneiden(Image.open(pfad).convert("RGB"), w, h))
    hz = einbau.get("hell_ziel", {}).get(name)
    a, h0, h1 = daempfen(a, hz)
    return [(Image.fromarray(a), ziel, 90)], "%d x %d, Helligkeit %.3f -> %.3f" % (w, h, h0, h1)


def hilfe():
    print("\nArten fuer einbauen.bat <art> [namen]:")
    for a in ALTE_ARTEN:
        print("  %-13s (wie bisher)" % a)
    for a, (k, ziel, txt) in NEUE_ARTEN.items():
        print("  %-13s %s\n  %-13s -> %s   (Auswahl unter einbau.%s)" % (a, txt, "", ziel, k))


NUR_PRUEFEN = [False]


def sag(*teile):
    """print, beim Pruefen mit 'geprueft' statt 'eingebaut' (es wird dann nichts geschrieben)."""
    text = " ".join(str(t) for t in teile)
    print(text.replace("eingebaut", "geprueft (nicht geschrieben)") if NUR_PRUEFEN[0] else text)


def main():
    if not os.path.exists(PLAN):
        sag("bildwerk_plan.json fehlt neben diesem Skript.")
        return
    plan = json.load(open(PLAN, encoding="utf-8"))
    sag("einbauen.bat Version %s, Plan Version %s" % (VERSION, plan.get("version", "?")))
    if plan.get("version") != VERSION:
        sag("ACHTUNG: Skript und Plan passen nicht zusammen. Beide Dateien neu von GitHub laden.")
        return
    args = sys.argv[1:]
    if args[:1] in (["hilfe"], ["--hilfe"], ["-h"]):
        hilfe()
        return
    nur_pruefen = "pruefen" in args
    NUR_PRUEFEN[0] = nur_pruefen
    args = [w for w in args if w != "pruefen"]
    alle_arten = ALTE_ARTEN + tuple(NEUE_ARTEN)
    # Namen hinter einer Art (z. B. "texturen t09_sand") bauen nur diese Bilder und lassen die anderen unberuehrt.
    namen = [w for w in args if w not in alle_arten]
    was = [w for w in args if w in alle_arten]
    if not was:
        was = list(alle_arten) if (namen or nur_pruefen) else ["symbole", "portraets", "texturen"]
    einbau = plan.get("einbau", {})
    repo = None if nur_pruefen else finde_repo()
    REPO[0] = repo
    sag("Repo:", repo or ("(nur pruefen, nichts wird geschrieben)" if nur_pruefen else "keins (nur Ordner fuers_spiel)"))
    sicherung = os.path.join(FUERS_SPIEL, "sicherung_vorher")
    fehlt, gesamt = [], 0
    os.makedirs(FUERS_SPIEL, exist_ok=True)

    def raus(bild, rel, q):
        if not nur_pruefen:
            schreibe(bild, rel, repo, sicherung, q)

    def gilt(n):
        return not namen or n in namen

    if "symbole" in was:
        eintraege = []
        zoom = einbau.get("symbole_zoom", {})
        for id_, rel in einbau.get("symbole", {}).items():
            if not gilt(id_):
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            bild = symbol(pfad, id_, zoom.get(id_, zoom.get("standard", 0.9)))
            raus(bild, "ui/symbole/%s.webp" % id_, 92)
            eintraege.append((id_, bild))
            gesamt += 1
        if eintraege:
            pfad = os.path.join(FUERS_SPIEL, "vorschau_symbole.jpg")
            vorschau(eintraege, pfad)
            sag("%d Symbole eingebaut. Vorschau: %s" % (len(eintraege), pfad))

    if "portraets" in was:
        n = 0
        pz = einbau.get("portraet_zuschnitt", {})
        for code, rel in einbau.get("portraets", {}).items():
            if not gilt(code):
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            z = pz.get(code, pz.get("standard", {}))
            raus(portraet(pfad, z.get("zoom", 0.66), z.get("oben", 0.03)), "ui/portraits/%s.webp" % code, 85)
            n += 1
        if n or not namen:
            sag("%d Portraets eingebaut." % n)
        gesamt += n

    if "texturen" in was:
        n = 0
        ohne = set(einbau.get("texturen_ohne_relief", []))
        von_hand = set(einbau.get("texturen_von_hand", []))
        hell = einbau.get("texturen_hell", {})
        for name, rel in einbau.get("texturen", {}).items():
            if not gilt(name):
                continue
            if name in von_hand and name not in namen:
                sag("  %s: uebersprungen, die Datei im Spiel ist von Hand korrigiert (bauen nur mit: einbauen.bat texturen %s)" % (name, name))
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            roh = np.asarray(Image.open(pfad).convert("RGB").resize((1024, 1024), Image.LANCZOS))
            p, vl = perspektive(roh), verlauf_mass(roh)
            urteil = "gut" if p < 1.3 else ("pruefen" if p < 1.5 else "PERSPEKTIVE")
            if p >= 1.5 and name not in namen:
                sag("  %s: NICHT eingebaut. Perspektive %.2f (oben und unten verschieden grob gemalt, das kachelt nicht)." % (name, p))
                sag("     Andere Variante waehlen, oder trotzdem: einbauen.bat texturen %s" % name)
                continue
            bild, relief, v, nach = textur(pfad)
            h0 = h1 = lin_hell(np.asarray(bild))
            if name in hell:
                a, h0, h1 = daempfen(np.asarray(bild), hell[name])
                bild = Image.fromarray(a)
            raus(bild, "textures/%s.jpg" % name, 88)
            if name not in ohne:
                raus(relief, "textures/%s_n.jpg" % name, 92)
            sag("  %s: Naht vorher %.2f, nachher %.2f (1.0 = so glatt wie das Bild selbst); Perspektive %.2f (%s), Lichtverlauf %.2f, "
                  "Helligkeit %.2f%s" % (name, v, nach, p, urteil, vl, h0, (" -> %.2f" % h1) if h1 != h0 else ""))
            n += 1
        if n:
            sag("%d Texturen eingebaut." % n)
        gesamt += n

    if "hueter" in was:
        n = 0
        hz = einbau.get("hueter_zuschnitt", {})
        for id_, rel in einbau.get("hueter", {}).items():
            if not gilt(id_):
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            z = hz.get(id_, hz.get("standard", {}))
            raus(hueterbild(pfad, z.get("zoom", 0.94), z.get("oben", 0.02)), "ui/hueter/%s.webp" % id_, 85)
            n += 1
        if n or not namen:
            sag("%d Hueterbilder eingebaut." % n)
        gesamt += n

    if "akttafeln" in was:
        n = 0
        for id_, rel in einbau.get("akttafeln", {}).items():
            if not gilt(id_):
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            raus(akttafel(pfad), "ui/akte/%s.webp" % id_, 82)
            n += 1
        if n or not namen:
            sag("%d Akttafeln eingebaut." % n)
        gesamt += n

    if "gegenstaende" in was and einbau.get("gegenstaende"):
        bogen, gesetzt, f = atlas_bauen(einbau, repo, namen, nur_pruefen)
        fehlt += f
        if gesetzt:
            raus(bogen, "ui/icons.webp", 92)
            pfad = os.path.join(FUERS_SPIEL, "vorschau_gegenstaende.jpg")
            vorschau_frei(gesetzt, pfad)
            bogen.save(os.path.join(FUERS_SPIEL, "vorschau_bildbogen.png"))
            sag("%d Gegenstaende in den Bildbogen gesetzt. Vorschau: %s" % (len(gesetzt), pfad))
            gesamt += len(gesetzt)

    for art, (schluessel, _, _) in NEUE_ARTEN.items():
        if art not in was or art == "gegenstaende":
            continue
        auswahl = einbau.get(schluessel, {})
        eintraege, n = [], 0
        for id_, rel in auswahl.items():
            if not gilt(id_):
                continue
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            try:
                teile, txt = baue_neu(art, id_, pfad, einbau)
            except Exception as e:
                sag("  %s %s: Fehler beim Bauen: %s" % (art, id_, e))
                continue
            for bild, rel_ziel, q in teile:
                raus(bild, rel_ziel, q)
            eintraege.append((id_, teile[0][0]))
            sag("  %s %s -> %s %s" % (art, id_, teile[0][1], txt))
            n += 1
        if eintraege:
            pfad = os.path.join(FUERS_SPIEL, "vorschau_%s.jpg" % art)
            vorschau_frei(eintraege, pfad, 200 if art in ("ladebilder", "szenen", "titel", "buchbilder", "fries") else 160)
            sag("%d %s eingebaut. Vorschau: %s" % (n, art, pfad))
            if art == "lebewesen" and not nur_pruefen:
                sag("Danach: Claude rechnet die Tafel der Kleintiere neu (python3 tools/figurenfabrik/kleintiere_tafel.py, dann Godot-Import).")
                sag("Die Kacheln liegen in bilder/ und gehen nicht in die Webfassung; erst die neue Tafel models/tiere/tiere_tafel.webp aendert das Spiel.")
        gesamt += n

    if fehlt:
        sag("\nNicht gefunden (Pfad in bildwerk_plan.json pruefen):")
        for f in fehlt:
            sag("  ", f)
    if nur_pruefen:
        sag("\nNur geprueft, nichts geschrieben. Vorschaubilder liegen in:", FUERS_SPIEL)
        return
    if os.path.exists(sicherung):
        sag("Die vorherigen Dateien liegen gesichert in:", sicherung)
    sag("\nAuch ohne Repo liegen alle Dateien in:", FUERS_SPIEL)
    if repo and gesamt:
        sag("\nNaechster Schritt: hochladen. Im Repo-Ordner:  herz-und-feder-3d\\tools\\sync.bat \"Bilder aus ComfyUI\"")
        a = input("Jetzt gleich mit sync.bat hochladen? [j/N]: ").strip().lower()
        if a.startswith("j"):
            subprocess.run(["cmd.exe", "/c", os.path.join("herz-und-feder-3d", "tools", "sync.bat"), "Bilder aus ComfyUI"], cwd=repo)
    try:
        os.startfile(FUERS_SPIEL)
    except Exception:
        pass


main()
