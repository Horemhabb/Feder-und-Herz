@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Netze (Fassung 1.0): Vorlagenbogen → 3D-Netz (TripoSG in ComfyUI) → spielbare Figur (aus_netz.py in Blender).
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Ablage: im ComfyUI-Ordner (C:\CF), neben bildwerk.bat. Das Repo findet es wie einbauen.bat (bildwerk_ort.txt).
# Ablauf je Bogen (PNG aus der Bildstufe gegner_vorlagen):
#   1. Bogen teilen und freistellen (tools/gegnerfabrik/bogen.py): <name>_vorn.png, <name>_hinten.png
#   2. Vorderansicht an ComfyUI schicken, TripoSG rechnen lassen (tools/gegnerfabrik/triposg_api.json), GLB abholen
#   3. wenn Blender da ist: aus_netz.py baut daraus die Figur mit Skelett, Bewegungen und Tafel
# Ergebnisse: C:\CF\gegnerfabrik\netze\ (rohe Netze) und C:\CF\gegnerfabrik\figuren\ (fertige .glb fürs Spiel)
#
# Aufruf:  netze.bat                      alle PNG in C:\CF\gegnerfabrik\vorlagen\
#          netze.bat bogen1.png bogen2.png
#          netze.bat --trocken            nur teilen und den Auftrag zeigen, ohne ComfyUI und Blender
#          netze.bat --ohne-blender       nur Netze holen
# Blender: Umgebungsvariable BLENDER oder C:\CF\blender\blender.exe (portable Fassung von blender.org, Zip entpacken)
import glob, json, os, shutil, subprocess, sys, time, urllib.error, urllib.request, uuid

ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
SERVER = os.environ.get("COMFY_SERVER", "http://127.0.0.1:8188")
ARBEIT = os.path.join(ROOT, "gegnerfabrik")
OUTPUT = os.path.join(ROOT, "ComfyUI", "output")
ORT = os.path.join(ROOT, "bildwerk_ort.txt")
TAKT = float(os.environ.get("NETZE_TAKT", "3"))
WARTEN = 30 * 60          # höchstens eine halbe Stunde je Netz


def sag(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def finde_repo():
    for p in (os.environ.get("BILDWERK_REPO"), open(ORT, encoding="utf-8").read().strip() if os.path.exists(ORT) else None):
        if p and os.path.exists(os.path.join(p, "herz-und-feder-3d", "tools", "gegnerfabrik", "aus_netz.py")):
            return p
    hier = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), "..", "..", ".."))
    if os.path.exists(os.path.join(hier, "herz-und-feder-3d", "tools", "gegnerfabrik", "aus_netz.py")):
        return hier
    return None


def finde_blender():
    kandidaten = [os.environ.get("BLENDER"), os.path.join(ROOT, "blender", "blender.exe")]
    kandidaten += sorted(glob.glob(r"C:\Program Files\Blender Foundation\Blender*\blender.exe"), reverse=True)
    return next((k for k in kandidaten if k and os.path.exists(k)), None)


def api(pfad, daten=None, timeout=60):
    r = urllib.request.Request(SERVER + pfad, data=None if daten is None else json.dumps(daten).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(r, timeout=timeout) as a:
        return json.loads(a.read().decode())


def hochladen(pfad):
    """Bild per /upload/image in ComfyUI/input legen (multipart von Hand, nur Standardbibliothek)."""
    grenze = uuid.uuid4().hex
    name = os.path.basename(pfad)
    kopf = ('--%s\r\nContent-Disposition: form-data; name="image"; filename="%s"\r\nContent-Type: image/png\r\n\r\n' % (grenze, name)).encode()
    fuss = ('\r\n--%s\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n--%s--\r\n' % (grenze, grenze)).encode()
    daten = kopf + open(pfad, "rb").read() + fuss
    r = urllib.request.Request(SERVER + "/upload/image", data=daten, headers={"Content-Type": "multipart/form-data; boundary=" + grenze})
    with urllib.request.urlopen(r, timeout=120) as a:
        return json.loads(a.read().decode())["name"]


def auftrag(vorlage, bild, praefix, seed):
    t = json.dumps({k: v for k, v in vorlage.items() if not k.startswith("_")})
    t = t.replace("@BILD@", bild).replace("@PRAEFIX@", praefix).replace('"@SEED@"', str(seed))
    return json.loads(t)


def netz_holen(vorlage, vorn, name, seed):
    praefix = "gegnerfabrik/" + name
    bild = hochladen(vorn)
    start = time.time()
    try:
        pid = api("/prompt", {"prompt": auftrag(vorlage, bild, praefix, seed), "client_id": str(uuid.uuid4())})["prompt_id"]
    except urllib.error.HTTPError as e:
        raise RuntimeError("ComfyUI lehnt den Auftrag ab (fehlt der Knoten 'TripoSG (ROCm)'?): " + e.read().decode()[:800])
    while time.time() - start < WARTEN:
        time.sleep(TAKT)
        h = api("/history/" + pid)
        if pid in h:
            st = h[pid].get("status", {})
            if st.get("status_str") == "error":
                raise RuntimeError("Fehler beim Rechnen: " + json.dumps(st)[:800])
            if st.get("completed", True):
                break
    else:
        raise RuntimeError("Zeitüberschreitung")
    dateien = sorted(glob.glob(os.path.join(OUTPUT, praefix + "*.glb")), key=os.path.getmtime)
    if not dateien:
        raise RuntimeError("ComfyUI meldet fertig, aber unter %s liegt kein Netz" % os.path.join(OUTPUT, "gegnerfabrik"))
    ziel = os.path.join(ARBEIT, "netze", name + ".glb")
    shutil.copy2(dateien[-1], ziel)
    sag("  Netz: %s (%d MB, %.0f s)" % (ziel, os.path.getsize(ziel) // (1 << 20), time.time() - start))
    return ziel


def figur_bauen(blender, aus_netz, netz, bogen, name, art):
    ziel = os.path.join(ARBEIT, "figuren", name + ".glb")
    befehl = [blender, "-b", "--python-exit-code", "1", "-P", aus_netz, "--", "--netz", netz, "--bogen", bogen, "--ziel", ziel,
              "--art", art, "--arbeit", os.path.join(ARBEIT, "arbeit")]
    if art == "kette":
        befehl += ["--hoehe", "3.4", "--dreiecke", "6000"]
    sag("  Blender: " + " ".join('"%s"' % b if " " in b else b for b in befehl[1:]))
    r = subprocess.run(befehl, capture_output=True, text=True, encoding="utf-8", errors="replace")
    for zeile in r.stdout.splitlines():
        if zeile.startswith("[") or "Error" in zeile or "Fehler" in zeile:
            print("   ", zeile)
    if r.returncode != 0 or not os.path.exists(ziel):
        print(r.stderr[-1500:])
        if "No module named 'PIL'" in r.stdout + r.stderr:
            print("  Blender braucht einmal Pillow:  \"<Blender-Ordner>\\<Version>\\python\\bin\\python.exe\" -m pip install pillow")
        raise RuntimeError("Blender ist nicht durchgelaufen")
    sag("  Figur: %s (%d KB)" % (ziel, os.path.getsize(ziel) // 1024))
    return ziel


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    boegen = [a for a in sys.argv[1:] if not a.startswith("--")]
    for d in ("vorlagen", "netze", "figuren", "arbeit"):
        os.makedirs(os.path.join(ARBEIT, d), exist_ok=True)
    repo = finde_repo()
    if not repo:
        print("Repo nicht gefunden. Einmal einbauen.bat starten (merkt sich den Ort) oder BILDWERK_REPO setzen.")
        return 1
    gf = os.path.join(repo, "herz-und-feder-3d", "tools", "gegnerfabrik")
    sys.path.insert(0, gf)
    import bogen as bg
    vorlage = json.load(open(os.path.join(gf, "triposg_api.json"), encoding="utf-8"))
    boegen = boegen or sorted(glob.glob(os.path.join(ARBEIT, "vorlagen", "*.png")))
    if not boegen:
        print("Keine Bögen. Lege die ausgewählten Bilder aus ComfyUI\\output\\bildwerk\\gegner_vorlagen nach %s" % os.path.join(ARBEIT, "vorlagen"))
        return 1
    blender = None if ("--trocken" in flags or "--ohne-blender" in flags) else finde_blender()
    if not blender and "--trocken" not in flags and "--ohne-blender" not in flags:
        print("Blender nicht gefunden (BLENDER oder %s): hole nur die Netze." % os.path.join(ROOT, "blender", "blender.exe"))
    if "--trocken" not in flags:
        try:
            api("/system_stats", timeout=10)
        except Exception:
            print("ComfyUI läuft nicht (%s). Erst start.bat, dann noch einmal." % SERVER)
            return 1
    fehler = 0
    for i, b in enumerate(boegen, 1):
        name = os.path.splitext(os.path.basename(b))[0]
        art = "kette" if any(w in name.lower() for w in ("apophis", "schlange", "serpent")) else "zweibeiner"
        sag("[%d/%d] %s (%s)" % (i, len(boegen), name, art))
        vorn, hinten = bg.teilen(b, os.path.join(ARBEIT, "arbeit"))
        sag("  geteilt: %s | %s" % (os.path.basename(vorn), os.path.basename(hinten)))
        if "--trocken" in flags:
            print(json.dumps(auftrag(vorlage, os.path.basename(vorn), "gegnerfabrik/" + name, 42), indent=1))
            continue
        try:
            netz = netz_holen(vorlage, vorn, name, 42)
            if blender:
                figur_bauen(blender, os.path.join(gf, "aus_netz.py"), netz, b, name, art)
        except Exception as e:
            fehler += 1
            sag("  FEHLER: %s" % e)
    sag("Fertig, %d Fehler. Netze: %s  Figuren: %s" % (fehler, os.path.join(ARBEIT, "netze"), os.path.join(ARBEIT, "figuren")))
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
