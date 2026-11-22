@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Symbole (Fassung 4.0.8): ein Skript fuer Probelaeufe UND die Nachtschicht, mit dem laufenden ComfyUI (Z-Image Turbo).
# Diese Datei ist zugleich Batch- und Python-Skript (die erste Zeile startet Python mit -x, das sie ueberspringt).
# Ablage: im ComfyUI-Ordner (C:\CF), daneben die Datei symbole_plan.json. Alle Texte (Stile, Motive, Laeufe, Seeds) stehen im Plan.
#
# Aufruf:  symbole.bat                 Menue zur Auswahl
#          symbole.bat probe           den Lauf "probe" starten (weitere: probe_breit, rest, nacht, aeste)
#          symbole.bat nacht --weiter  Bilder, die es schon gibt, nicht neu rechnen (ohne Rueckfrage)
#          symbole.bat nacht --neu     in einem neuen Ordner beginnen
#          symbole.bat probe --trocken nur die Prompts in eine Datei schreiben, ohne ComfyUI
#
# Was das Skript fuer die Nacht tut: haelt den Rechner wach, ueberspringt fertige Bilder, versucht ein Bild zweimal,
# rechnet die Bilder reihum (erst alle Symbole in Variante a, dann b ...), damit bei einem Abbruch ein vollstaendiger
# Satz vorliegt, und startet ComfyUI (start.bat) neu, falls es abstuerzt (AMD-Treiber), hoechstens dreimal.
import ctypes, datetime, glob, json, os, subprocess, sys, time, urllib.error, urllib.request, uuid

ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
SERVER = os.environ.get("COMFY_SERVER", "http://127.0.0.1:8188")
PLAN = os.path.join(ROOT, "symbole_plan.json")
BASIS = os.path.join(ROOT, "ComfyUI", "output", "symbole")
VAE_PFAD = os.path.join(ROOT, "ComfyUI", "models", "vae", "ae.safetensors")
VAE_URL = "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
MODELL, TEXTMODELL = "z_image_turbo_bf16.safetensors", "qwen_3_4b.safetensors"
START_BAT = os.path.join(ROOT, "start.bat")
SCHRITTE, KACHEL, TIMEOUT_BILD = 8, 512, 1800
MAX_NEUSTARTS, MAX_FEHLER_IN_FOLGE = 3, 3
TAKT = float(os.environ.get("SYMBOLE_TAKT", "3"))   # Sekunden zwischen zwei Nachfragen (nur zum Testen aendern)

ziel_logdatei = None


class ServerWeg(Exception):
    pass


class BildFehler(Exception):
    pass


def asc(s):
    """Fuer die Windows-Konsole: Umlaute ausschreiben (sonst droht ein Zeichensatzfehler)."""
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("Ä", "Ae"), ("Ö", "Oe"), ("Ü", "Ue"), ("ß", "ss")):
        s = s.replace(a, b)
    return s.encode("ascii", "replace").decode("ascii")


def sag(*teile):
    text = " ".join(str(t) for t in teile)
    print(asc(text), flush=True)
    if ziel_logdatei:
        try:
            with open(ziel_logdatei, "a", encoding="utf-8") as f:
                f.write(datetime.datetime.now().strftime("%H:%M:%S ") + text + "\n")
        except Exception:
            pass


def dauer(sek):
    sek = int(sek)
    return "%d h %02d min" % (sek // 3600, sek % 3600 // 60) if sek >= 3600 else "%d min %02d s" % (sek // 60, sek % 60)


def wach_halten(an):
    try:
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000001 if an else 0x80000000)
    except Exception:
        pass


# ---------------------------------------------------------------- ComfyUI

def api(pfad, daten=None, timeout=60):
    anfrage = urllib.request.Request(SERVER + pfad, data=None if daten is None else json.dumps(daten).encode(),
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(anfrage, timeout=timeout) as r:
        return json.loads(r.read().decode())


def optionen(knoten, feld):
    try:
        return api("/object_info/" + knoten)[knoten]["input"]["required"][feld][0]
    except Exception:
        return None


def server_da():
    try:
        api("/system_stats", timeout=10)
        return True
    except Exception:
        return False


def starte_comfy():
    if os.name == "nt" and os.path.exists(START_BAT):
        sag("Starte ComfyUI mit start.bat in einem neuen Fenster ...")
        subprocess.Popen(["cmd.exe", "/c", "start.bat"], cwd=ROOT, creationflags=0x00000010)  # neue Konsole
        return True
    return False


def warte_auf_server(minuten):
    ende = time.time() + minuten * 60
    while time.time() < ende:
        if server_da():
            return True
        time.sleep(5)
    return False


def graph(text, seed, vae, praefix):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": MODELL, "weight_dtype": "default"}},
        "2": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": TEXTMODELL, "type": "lumina2", "device": "cpu"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["3", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": "low quality, blurry, text, watermark", "clip": ["3", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "seed": seed, "steps": SCHRITTE, "cfg": 1.0, "sampler_name": "res_multistep",
                                                   "scheduler": "simple", "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0], "denoise": 1.0}},
        "8": {"class_type": "VAELoader", "inputs": {"vae_name": vae}},
        "9": {"class_type": "VAEDecodeTiled", "inputs": {"samples": ["7", 0], "vae": ["8", 0], "tile_size": KACHEL, "overlap": 64, "temporal_size": 64, "temporal_overlap": 8}},
        "10": {"class_type": "SaveImage", "inputs": {"images": ["9", 0], "filename_prefix": praefix}},
    }


def rechne(text, seed, vae, praefix):
    """Ein Bild rechnen. Gibt die Sekunden zurueck; wirft ServerWeg oder BildFehler."""
    try:
        antwort = api("/prompt", {"prompt": graph(text, seed, vae, praefix), "client_id": str(uuid.uuid4())})
    except urllib.error.HTTPError as e:
        raise BildFehler("ComfyUI lehnt den Auftrag ab: " + e.read().decode()[:600])
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
        raise ServerWeg()
    pid, start, fehlversuche = antwort["prompt_id"], time.time(), 0
    while time.time() - start < TIMEOUT_BILD:
        time.sleep(TAKT)
        try:
            h = api("/history/" + pid)
            fehlversuche = 0
        except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
            fehlversuche += 1
            if fehlversuche >= 4:
                raise ServerWeg()
            continue
        if pid in h:
            if h[pid].get("status", {}).get("status_str") == "error":
                raise BildFehler("Fehler beim Rechnen: " + json.dumps(h[pid]["status"])[:600])
            return time.time() - start
    raise BildFehler("Zeitueberschreitung nach %d s" % TIMEOUT_BILD)


# ---------------------------------------------------------------- Plan

def lade_plan():
    if not os.path.exists(PLAN):
        sag("Die Datei symbole_plan.json fehlt. Sie muss im selben Ordner liegen wie dieses Skript (%s)." % ROOT)
        return None
    with open(PLAN, encoding="utf-8") as f:
        return json.load(f)


def icons_des_laufs(plan, lauf):
    nach_id = {i["id"]: i for i in plan["icons"]}
    if "icons" in lauf:
        return [nach_id[i] for i in lauf["icons"]]
    return [i for i in plan["icons"] if i["gruppe"] in lauf["gruppen"]]


def stile_des_laufs(plan, lauf):
    return [plan["standardstil"] if s == "@standard" else s for s in lauf["stile"]]


def baue_prompt(plan, icon, stil, v):
    text = plan["stile"][stil]["text"]
    for platz, wert in (("{MOTIV}", icon["motiv"]), ("{HINWEIS}", icon.get("hinweis", "")),
                        ("{ANSICHT}", plan["ansichten"].get(v, "")), ("{TEX}", icon["tex"])):
        text = text.replace(platz, wert)
    return " ".join(text.split())


def dateiname_teil(s):
    return asc(s).replace(" ", "_")


def auftraege(plan, lauf):
    """Reihenfolge: Variante, dann Stil, dann Symbol. So liegt bei jedem Abbruch ein vollstaendiger Satz vor."""
    icons, stile = icons_des_laufs(plan, lauf), stile_des_laufs(plan, lauf)
    liste = []
    for v in lauf["varianten"]:
        for stil in stile:
            for icon in icons:
                liste.append({"id": icon["id"], "name": icon["name"], "stil": stil, "v": v, "seed": plan["seeds"][v],
                              "prompt": baue_prompt(plan, icon, stil, v),
                              "praefix": "%s_%s_%s" % (dateiname_teil(icon["id"]), stil, v)})
    return liste


def vorhanden(ziel, a):
    return sorted(glob.glob(os.path.join(ziel, a["praefix"] + "_*.png")))


# ---------------------------------------------------------------- Uebersichtstafeln

def tafeln(ziel, jobs):
    try:
        from PIL import Image, ImageDraw, ImageFont
    except Exception:
        sag("Pillow fehlt, die Uebersichtstafeln entfallen.")
        return []
    try:
        schrift = ImageFont.truetype("arial.ttf", 16)
    except Exception:
        schrift = ImageFont.load_default()
    Z, LUECKE, SEITE = 256, 10, 12
    reihenfolge, gruppen = [], {}
    for a in jobs:
        if a["id"] not in gruppen:
            gruppen[a["id"]] = []
            reihenfolge.append((a["id"], a["name"]))
        gruppen[a["id"]].append(a)
    ergebnis = []
    for seite in range((len(reihenfolge) + SEITE - 1) // SEITE):
        teil = reihenfolge[seite * SEITE:(seite + 1) * SEITE]
        zellen = max(len(gruppen[i]) for i, _ in teil)
        gruppenbreite = zellen * (Z + LUECKE) + 20
        pro_zeile = max(1, 2400 // gruppenbreite)
        zeilen = (len(teil) + pro_zeile - 1) // pro_zeile
        blatt = Image.new("RGB", (pro_zeile * gruppenbreite + LUECKE, zeilen * (Z + 70) + LUECKE), (16, 14, 18))
        d = ImageDraw.Draw(blatt)
        for k, (i, n) in enumerate(teil):
            gx, gy = LUECKE + (k % pro_zeile) * gruppenbreite, LUECKE + (k // pro_zeile) * (Z + 70)
            d.text((gx, gy), "%s (%s)" % (asc(n), i), fill=(230, 200, 120), font=schrift)
            for c, a in enumerate(gruppen[i]):
                dateien = vorhanden(ziel, a)
                x = gx + c * (Z + LUECKE)
                if dateien:
                    try:
                        blatt.paste(Image.open(dateien[-1]).convert("RGB").resize((Z, Z), Image.LANCZOS), (x, gy + 22))
                    except Exception:
                        pass
                d.text((x, gy + 22 + Z + 4), "%s / %s" % (a["stil"], a["v"]), fill=(160, 150, 130), font=schrift)
        pfad = os.path.join(ziel, "uebersicht_%02d.jpg" % (seite + 1))
        blatt.save(pfad, quality=88)
        ergebnis.append(pfad)
    # Leiste in Spielgroesse (64 px): jedes Bild, in der Reihenfolge der Auftraege
    fertig = [(a, vorhanden(ziel, a)) for a in jobs]
    fertig = [(a, f[-1]) for a, f in fertig if f]
    if fertig:
        pro_zeile = 24
        zeilen = (len(fertig) + pro_zeile - 1) // pro_zeile
        leiste = Image.new("RGB", (pro_zeile * 72 + 8, zeilen * 72 + 8), (16, 14, 18))
        for k, (a, f) in enumerate(fertig):
            try:
                leiste.paste(Image.open(f).convert("RGB").resize((64, 64), Image.LANCZOS), (8 + (k % pro_zeile) * 72, 8 + (k // pro_zeile) * 72))
            except Exception:
                pass
        pfad = os.path.join(ziel, "leiste_64px.jpg")
        leiste.save(pfad, quality=90)
        ergebnis.append(pfad)
    return ergebnis


# ---------------------------------------------------------------- Ablauf

def frage_lauf(plan):
    namen = list(plan["laeufe"].keys())
    print("\nWelcher Lauf?\n")
    for n, name in enumerate(namen, 1):
        lauf = plan["laeufe"][name]
        anzahl = len(icons_des_laufs(plan, lauf)) * len(stile_des_laufs(plan, lauf)) * len(lauf["varianten"])
        print("  %d  %-12s %3d Bilder   %s" % (n, name, anzahl, asc(lauf["titel"])))
    print("\nStandardstil im Plan: %s" % plan["standardstil"])
    antwort = input("\nNummer oder Name: ").strip()
    if antwort.isdigit() and 1 <= int(antwort) <= len(namen):
        return namen[int(antwort) - 1]
    return antwort


def main():
    global ziel_logdatei
    args = sys.argv[1:]
    flags = [a for a in args if a.startswith("--")]
    namen = [a for a in args if not a.startswith("--")]
    plan = lade_plan()
    if plan is None:
        return
    name = namen[0] if namen else frage_lauf(plan)
    if name not in plan["laeufe"]:
        sag("Unbekannter Lauf '%s'. Moeglich: %s" % (name, ", ".join(plan["laeufe"])))
        return
    lauf = plan["laeufe"][name]
    ziel = os.path.join(BASIS, name)
    schon = glob.glob(os.path.join(ziel, "*.png"))
    if schon and "--neu" in flags:
        ziel += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    elif schon and "--weiter" not in flags and "--trocken" not in flags:
        w = input("\nIm Ordner liegen schon %d Bilder.  [W] Fehlende nachholen (Standard)   [N] Neu in neuem Ordner: " % len(schon)).strip().lower()
        if w.startswith("n"):
            ziel += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    os.makedirs(ziel, exist_ok=True)
    ziel_logdatei = os.path.join(ziel, "protokoll.txt")

    jobs = auftraege(plan, lauf)
    with open(os.path.join(ziel, "prompts.txt"), "w", encoding="utf-8") as f:
        for a in jobs:
            f.write("%s | %s | %s | seed %d\n%s\n\n" % (a["id"], a["stil"], a["v"], a["seed"], a["prompt"]))
    sag("Lauf '%s': %s" % (name, lauf["titel"]))
    sag("%d Symbole, Stile %s, Varianten %s = %d Bilder. Ordner: %s" % (len(icons_des_laufs(plan, lauf)), "+".join(stile_des_laufs(plan, lauf)),
                                                                       "".join(lauf["varianten"]), len(jobs), ziel))
    if "--trocken" in flags:
        sag("Trockenlauf: alle Prompts stehen in %s" % os.path.join(ziel, "prompts.txt"))
        return

    if not server_da():
        sag("ComfyUI laeuft nicht.")
        if not (starte_comfy() and warte_auf_server(6)):
            sag("Bitte C:\\CF\\start.bat starten, warten bis dort 'To see the GUI' steht, und dieses Skript noch einmal starten.")
            return
    for knoten, feld, datei in (("UNETLoader", "unet_name", MODELL), ("CLIPLoader", "clip_name", TEXTMODELL)):
        liste = optionen(knoten, feld)
        if liste is not None and datei not in liste:
            sag("Die Modelldatei %s fehlt in ComfyUI (gefunden: %s)." % (datei, ", ".join(liste[:5]) or "nichts"))
            return
    if not os.path.exists(VAE_PFAD) or os.path.getsize(VAE_PFAD) < 300_000_000:
        sag("Lade das Bild-Aufbereiter-Paket (335 MB) ...")
        os.makedirs(os.path.dirname(VAE_PFAD), exist_ok=True)
        subprocess.run(["curl.exe", "-L", "-C", "-", "--retry", "10", "--retry-delay", "10", "--retry-all-errors", "-o", VAE_PFAD, VAE_URL])
    vaes = optionen("VAELoader", "vae_name") or []
    vae = "ae.safetensors" if "ae.safetensors" in vaes else ("taef1" if "taef1" in vaes else (vaes[0] if vaes else "taef1"))
    sag("Bild-Aufbereiter:", vae)

    offen = [a for a in jobs if not vorhanden(ziel, a)]
    sag("%d Bilder gibt es schon, %d sind noch zu rechnen." % (len(jobs) - len(offen), len(offen)))
    if len(offen) > 8:
        sag("Der Rechner bleibt wach, solange das Skript laeuft. Beenden mit Strg+C (die Tafeln werden dann trotzdem gebaut).")
    manifest_pfad = os.path.join(ziel, "manifest.json")
    try:
        with open(manifest_pfad, encoding="utf-8") as f:
            manifest = {m["praefix"]: m for m in json.load(f)}
    except Exception:
        manifest = {}

    wach_halten(True)
    start, gerechnet, summe, neustarts, fehler_folge, ausgefallen = time.time(), 0, 0.0, 0, 0, []
    try:
        for nr, a in enumerate(jobs, 1):
            if vorhanden(ziel, a):
                continue
            sek = None
            for versuch in (1, 2, 3, 4):
                try:
                    sek = rechne(a["prompt"], a["seed"], vae, "symbole/%s/%s" % (os.path.basename(ziel), a["praefix"]))
                    break
                except ServerWeg:
                    sag("ComfyUI antwortet nicht mehr (vermutlich Treiberabsturz).")
                    if neustarts >= MAX_NEUSTARTS:
                        sag("Schon %d Neustarts: Ich gebe auf." % neustarts)
                        raise KeyboardInterrupt
                    neustarts += 1
                    time.sleep(max(1.0, TAKT * 7))
                    if not server_da():
                        starte_comfy()
                    if not warte_auf_server(6):
                        sag("ComfyUI kommt nicht zurueck.")
                        raise KeyboardInterrupt
                    sag("ComfyUI ist wieder da (Neustart %d von %d). Mache mit demselben Bild weiter." % (neustarts, MAX_NEUSTARTS))
                except BildFehler as e:
                    sag("[%d/%d] %s %s %s: %s" % (nr, len(jobs), a["id"], a["stil"], a["v"], e))
                    if versuch >= 2:
                        break
                    time.sleep(10)
            if sek is None:
                ausgefallen.append(a["praefix"])
                fehler_folge += 1
                sag("[%d/%d] %s %s %s: uebersprungen" % (nr, len(jobs), a["id"], a["stil"], a["v"]))
                if fehler_folge >= MAX_FEHLER_IN_FOLGE:
                    sag("%d Bilder hintereinander fehlgeschlagen. Das ist kein Zufall, ich halte an." % fehler_folge)
                    break
                continue
            fehler_folge, gerechnet, summe = 0, gerechnet + 1, summe + sek
            rest = (len(offen) - gerechnet - len(ausgefallen)) * (summe / gerechnet)
            sag("[%d/%d] %s | %s | %s | %d s   (noch etwa %s)" % (nr, len(jobs), a["name"], a["stil"], a["v"], sek, dauer(rest)))
            manifest[a["praefix"]] = {"praefix": a["praefix"], "id": a["id"], "stil": a["stil"], "v": a["v"], "seed": a["seed"],
                                      "sekunden": round(sek, 1), "prompt": a["prompt"]}
            with open(manifest_pfad, "w", encoding="utf-8") as f:
                json.dump(list(manifest.values()), f, ensure_ascii=False, indent=1)
    except KeyboardInterrupt:
        sag("Abgebrochen.")
    finally:
        wach_halten(False)
        sag("\nGerechnet: %d Bilder in %s (im Schnitt %s je Bild)." % (gerechnet, dauer(time.time() - start), dauer(summe / gerechnet) if gerechnet else "-"))
        if ausgefallen:
            sag("Fehlgeschlagen: %s  (nochmal starten mit --weiter holt sie nach)" % ", ".join(ausgefallen))
        for pfad in tafeln(ziel, jobs):
            sag("Tafel:", pfad)
    sag("FERTIG. Ordner:", ziel)
    try:
        os.startfile(ziel)
    except Exception:
        pass


main()
