@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Einbauen (Fassung 5.0.0): bringt die ausgewaehlten Bilder aus ComfyUI ins Spiel.
# Symbole: zuschneiden, Rahmen wie tools/symbole/wand/magie.py (abgerundete Tafel, duenne Goldlinie, Schein in der Klassenfarbe),
# 256 x 256 als WebP nach herz-und-feder-3d/ui/symbole/. Portraets: auf 717 x 960 zuschneiden, WebP nach ui/portraits/.
# Die Auswahl steht in bildwerk_plan.json unter "einbau". Ablage: C:\CF neben bildwerk.bat und bildwerk_plan.json.
#
# Aufruf:  einbauen.bat            Symbole und Portraets aus der Auswahl einbauen
#          einbauen.bat symbole    nur die Symbole
#          einbauen.bat portraets  nur die Portraets
#
# Das Skript sucht dein Repo (Ordner mit herz-und-feder-3d\project.godot) und merkt sich den Ort in bildwerk_ort.txt.
# Findet es keins, landen die Dateien nur in ComfyUI\output\bildwerk\fuers_spiel\ (zum Hochladen von Hand).
import glob, json, os, shutil, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

VERSION = "5.0.0"
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
    was = sys.argv[1:] or ["symbole", "portraets"]
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
