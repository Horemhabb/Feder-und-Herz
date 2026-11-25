@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Einbauen (Fassung 5.2.0): bringt die ausgewaehlten Bilder aus ComfyUI ins Spiel.
# Symbole: zuschneiden, Rahmen wie tools/symbole/wand/magie.py (abgerundete Tafel, duenne Goldlinie, Schein in der Klassenfarbe),
# 256 x 256 als WebP nach herz-und-feder-3d/ui/symbole/. Portraets: auf 717 x 960 zuschneiden, WebP nach ui/portraits/.
# Die Auswahl steht in bildwerk_plan.json unter "einbau". Ablage: C:\CF neben bildwerk.bat und bildwerk_plan.json.
#
# Aufruf:  einbauen.bat            Symbole und Portraets aus der Auswahl einbauen
#          einbauen.bat symbole    nur die Symbole
#          einbauen.bat portraets  nur die Portraets
#          einbauen.bat texturen   nur die Texturen (Helligkeit ausgleichen, Naht glaetten, Normalenkarte, nach textures/)
#
# Das Skript sucht dein Repo (Ordner mit herz-und-feder-3d\project.godot) und merkt sich den Ort in bildwerk_ort.txt.
# Findet es keins, landen die Dateien nur in ComfyUI\output\bildwerk\fuers_spiel\ (zum Hochladen von Hand).
import glob, json, os, shutil, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

VERSION = "5.2.0"
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


def symbol(pfad, id_, zoom):
    """Zuschnitt, dann der Rahmen wie bei magie.py: Rand abdunkeln, Schein der Klassenfarbe innen am Rand, duenne Goldlinie, runde Ecken."""
    N = 512
    im = Image.open(pfad).convert("RGB")
    w, h = im.size
    s = int(min(w, h) * zoom)
    im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s)).resize((N, N), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    alpha, inner, r = tafel(N)
    _, hl = [np.array(c, np.float32) for c in CL[klasse(id_)]]
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


def naht_mass(a):
    g = a.astype(np.float32).mean(2)
    return (np.abs(g[:, 0] - g[:, -1]).mean() / np.abs(np.diff(g, axis=1)).mean() + np.abs(g[0, :] - g[-1, :]).mean() / np.abs(np.diff(g, axis=0)).mean()) / 2


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


def main():
    if not os.path.exists(PLAN):
        print("bildwerk_plan.json fehlt neben diesem Skript.")
        return
    plan = json.load(open(PLAN, encoding="utf-8"))
    print("einbauen.bat Version %s, Plan Version %s" % (VERSION, plan.get("version", "?")))
    if plan.get("version") != VERSION:
        print("ACHTUNG: Skript und Plan passen nicht zusammen. Beide Dateien neu von GitHub laden.")
        return
    was = sys.argv[1:] or ["symbole", "portraets", "texturen"]
    einbau = plan.get("einbau", {})
    repo = finde_repo()
    print("Repo:", repo or "keins (nur Ordner fuers_spiel)")
    sicherung = os.path.join(FUERS_SPIEL, "sicherung_vorher")
    fehlt, gesamt = [], 0

    if "symbole" in was:
        eintraege = []
        zoom = einbau.get("symbole_zoom", {})
        for id_, rel in einbau.get("symbole", {}).items():
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            bild = symbol(pfad, id_, zoom.get(id_, zoom.get("standard", 0.9)))
            schreibe(bild, "ui/symbole/%s.webp" % id_, repo, sicherung, 92)
            eintraege.append((id_, bild))
            gesamt += 1
        if eintraege:
            pfad = os.path.join(FUERS_SPIEL, "vorschau_symbole.jpg")
            vorschau(eintraege, pfad)
            print("%d Symbole eingebaut. Vorschau: %s" % (len(eintraege), pfad))

    if "portraets" in was:
        n = 0
        pz = einbau.get("portraet_zuschnitt", {})
        for code, rel in einbau.get("portraets", {}).items():
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            z = pz.get(code, pz.get("standard", {}))
            schreibe(portraet(pfad, z.get("zoom", 0.66), z.get("oben", 0.03)), "ui/portraits/%s.webp" % code, repo, sicherung, 85)
            n += 1
        print("%d Portraets eingebaut." % n)
        gesamt += n

    if "texturen" in was:
        n = 0
        ohne = set(einbau.get("texturen_ohne_relief", []))
        for name, rel in einbau.get("texturen", {}).items():
            pfad = quelle(rel)
            if not pfad:
                fehlt.append(rel)
                continue
            bild, relief, v, nach = textur(pfad)
            schreibe(bild, "textures/%s.jpg" % name, repo, sicherung, 88)
            if name not in ohne:
                schreibe(relief, "textures/%s_n.jpg" % name, repo, sicherung, 92)
            print("  %s: Naht vorher %.2f, nachher %.2f (1.0 = so glatt wie das Bild selbst)" % (name, v, nach))
            n += 1
        if n:
            print("%d Texturen eingebaut." % n)
        gesamt += n

    if fehlt:
        print("\nNicht gefunden (Pfad in bildwerk_plan.json pruefen):")
        for f in fehlt:
            print("  ", f)
    if os.path.exists(sicherung):
        print("Die vorherigen Dateien liegen gesichert in:", sicherung)
    print("\nAuch ohne Repo liegen alle Dateien in:", FUERS_SPIEL)
    if repo and gesamt:
        print("\nNaechster Schritt: hochladen. Im Repo-Ordner:  herz-und-feder-3d\\tools\\sync.bat \"Bilder aus ComfyUI\"")
        a = input("Jetzt gleich mit sync.bat hochladen? [j/N]: ").strip().lower()
        if a.startswith("j"):
            subprocess.run(["cmd.exe", "/c", os.path.join("herz-und-feder-3d", "tools", "sync.bat"), "Bilder aus ComfyUI"], cwd=repo)
    try:
        os.startfile(FUERS_SPIEL)
    except Exception:
        pass


main()
