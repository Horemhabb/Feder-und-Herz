@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Bildwerk (Fassung 5.0.0): das Masterskript fuer alle Bilder des Spiels mit dem laufenden ComfyUI (Z-Image Turbo).
# Nachfolger von symbole.bat. Diese Datei ist zugleich Batch- und Python-Skript (die erste Zeile startet Python mit -x).
# Ablage: im ComfyUI-Ordner (C:\CF), daneben bildwerk_plan.json. Alle Texte (Stile, Motive, Stufen, Seeds) stehen im Plan.
#
# Aufruf:  bildwerk.bat                       Menue: eine oder mehrere Stufen waehlen (z. B. "1 2" fuer eine Nacht)
#          bildwerk.bat symbole_neu           eine Stufe direkt
#          bildwerk.bat portraets_figuren portraets_leute --weiter
#          bildwerk.bat texturen_stunden --trocken   nur die Prompts in eine Datei schreiben, ohne ComfyUI
#
# Fuer lange Laeufe: haelt den Rechner wach, ueberspringt fertige Bilder, versucht jedes Bild zweimal, rechnet reihum
# (erst alle Motive in Variante a, dann b ...), startet ComfyUI (start.bat) nach einem Absturz neu (hoechstens dreimal)
# und stellt alle Rueckfragen vor dem Start, damit die Nacht nicht an einer Frage haengen bleibt.
import ctypes, datetime, glob, json, os, re, subprocess, sys, time, urllib.error, urllib.request, uuid

VERSION = "5.2.0"   # muss zur "version" in bildwerk_plan.json passen
ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
SERVER = os.environ.get("COMFY_SERVER", "http://127.0.0.1:8188")
PLAN = os.path.join(ROOT, "bildwerk_plan.json")
BASIS = os.path.join(ROOT, "ComfyUI", "output", "bildwerk")
VAE_PFAD = os.path.join(ROOT, "ComfyUI", "models", "vae", "ae.safetensors")
VAE_URL = "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
MODELL, TEXTMODELL = "z_image_turbo_bf16.safetensors", "qwen_3_4b.safetensors"
START_BAT = os.path.join(ROOT, "start.bat")
SCHRITTE, KACHEL, TIMEOUT_BILD = 8, 512, 1800
MAX_NEUSTARTS, MAX_FEHLER_IN_FOLGE = 3, 3
SEK_JE_MEGAPIXEL = 185   # gemessen in der ersten Nacht (1024 x 1024, Stil aegypt)
TAKT = float(os.environ.get("SYMBOLE_TAKT", "3"))   # Sekunden zwischen zwei Nachfragen (nur zum Testen aendern)

logdatei = None
neustarts = 0


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
    if logdatei:
        try:
            with open(logdatei, "a", encoding="utf-8") as f:
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


def graph(text, seed, vae, praefix, breite, hoehe):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": MODELL, "weight_dtype": "default"}},
        "2": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": TEXTMODELL, "type": "lumina2", "device": "cpu"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["3", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": "low quality, blurry, text, watermark", "clip": ["3", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": breite, "height": hoehe, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "seed": seed, "steps": SCHRITTE, "cfg": 1.0, "sampler_name": "res_multistep",
                                                   "scheduler": "simple", "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0], "denoise": 1.0}},
        "8": {"class_type": "VAELoader", "inputs": {"vae_name": vae}},
        "9": {"class_type": "VAEDecodeTiled", "inputs": {"samples": ["7", 0], "vae": ["8", 0], "tile_size": KACHEL, "overlap": 64, "temporal_size": 64, "temporal_overlap": 8}},
        "10": {"class_type": "SaveImage", "inputs": {"images": ["9", 0], "filename_prefix": praefix}},
    }


def rechne(a, vae):
    """Ein Bild rechnen. Gibt die Sekunden zurueck; wirft ServerWeg oder BildFehler."""
    try:
        antwort = api("/prompt", {"prompt": graph(a["prompt"], a["seed"], vae, a["comfy_praefix"], a["breite"], a["hoehe"]),
                                  "client_id": str(uuid.uuid4())})
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
        print("Die Datei bildwerk_plan.json fehlt. Sie muss im selben Ordner liegen wie dieses Skript (%s)." % ROOT)
        return None
    with open(PLAN, encoding="utf-8") as f:
        return json.load(f)


def motive_der_stufe(plan, stufe):
    nach_id = {m["id"]: m for m in plan["motive"]}
    if "motive" in stufe:
        return [nach_id[i] for i in stufe["motive"]]
    return [m for m in plan["motive"] if m["gruppe"] in stufe["gruppen"]]


def satz(s):
    """Saetze sauber abschliessen, damit Motiv und Stiltext nicht ineinanderlaufen."""
    s = s.strip()
    return s if not s or s[-1] in ".!?" else s + "."


def baue_prompt(plan, motiv, stil, ansichtsatz, v):
    text = plan["stile"][stil]["text"]
    for platz, wert in (("{MOTIV}", satz(motiv["motiv"])), ("{HINWEIS}", satz(motiv.get("hinweis", ""))),
                        ("{ANSICHT}", satz(plan["ansichten"].get(ansichtsatz, {}).get(v, ""))), ("{TEX}", motiv.get("tex", ""))):
        text = text.replace(platz, wert)
    return " ".join(text.split())


def auftraege(plan, name, ordner):
    """Reihenfolge: Variante, dann Motiv, dann Stil. So liegt bei jedem Abbruch ein vollstaendiger Satz der ersten Varianten vor."""
    stufe = plan["stufen"][name]
    stile = [plan.get("standardstil", "aegypt") if s == "@standard" else s for s in stufe["stile"]]
    liste = []
    for v in stufe["varianten"]:
        for m in motive_der_stufe(plan, stufe):
            for stil in stile:
                praefix = "%s_%s_%s" % (asc(m.get("datei", m["id"])).replace(" ", "_"), stil, v)
                liste.append({"id": m["id"], "name": m["name"], "stil": stil, "v": v, "seed": plan["seeds"][v],
                              "prompt": baue_prompt(plan, m, stil, stufe.get("ansichten", "emblem"), v),
                              "praefix": praefix, "comfy_praefix": "bildwerk/%s/%s" % (os.path.basename(ordner), praefix),
                              "breite": stufe.get("breite", 1024), "hoehe": stufe.get("hoehe", 1024)})
    return liste


def vorhanden(ordner, a):
    return sorted(glob.glob(os.path.join(ordner, a["praefix"] + "_*.png")))


def schaetzung(jobs):
    return sum(SEK_JE_MEGAPIXEL * a["breite"] * a["hoehe"] / (1024 * 1024) for a in jobs)


def ziffern_warnung(jobs):
    """Z-Image malt Zahlen und Prozentzeichen gern als Schrift ins Bild (aus '80%' wurde ein Bildmotiv). Darum vorher warnen."""
    gefunden = {}
    for a in jobs:
        for t in re.findall(r"\d+%?|%", a["prompt"]):
            gefunden.setdefault(a["stil"], set()).add(t)
    for stil, tokens in gefunden.items():
        sag("ACHTUNG Stil '%s': Zahlen im Prompt (%s). Ziffern koennen als Schrift im Bild landen." % (stil, ", ".join(sorted(tokens))))


# ---------------------------------------------------------------- Uebersichtstafeln

def tafeln(ordner, jobs):
    try:
        from PIL import Image, ImageDraw, ImageFont
    except Exception:
        return []
    try:
        schrift = ImageFont.truetype("arial.ttf", 16)
    except Exception:
        schrift = ImageFont.load_default()
    ZB = 256
    ZH = int(ZB * jobs[0]["hoehe"] / jobs[0]["breite"]) if jobs else ZB
    LUECKE, SEITE = 10, 12
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
        gruppenbreite = zellen * (ZB + LUECKE) + 20
        pro_zeile = max(1, 2400 // gruppenbreite)
        zeilen = (len(teil) + pro_zeile - 1) // pro_zeile
        blatt = Image.new("RGB", (pro_zeile * gruppenbreite + LUECKE, zeilen * (ZH + 70) + LUECKE), (16, 14, 18))
        d = ImageDraw.Draw(blatt)
        for k, (i, n) in enumerate(teil):
            gx, gy = LUECKE + (k % pro_zeile) * gruppenbreite, LUECKE + (k // pro_zeile) * (ZH + 70)
            d.text((gx, gy), "%s (%s)" % (asc(n), i), fill=(230, 200, 120), font=schrift)
            for c, a in enumerate(gruppen[i]):
                dateien = vorhanden(ordner, a)
                x = gx + c * (ZB + LUECKE)
                if dateien:
                    try:
                        blatt.paste(Image.open(dateien[-1]).convert("RGB").resize((ZB, ZH), Image.LANCZOS), (x, gy + 22))
                    except Exception:
                        pass
                d.text((x, gy + 22 + ZH + 4), "%s / %s" % (a["stil"], a["v"]), fill=(160, 150, 130), font=schrift)
        pfad = os.path.join(ordner, "uebersicht_%02d.jpg" % (seite + 1))
        blatt.save(pfad, quality=88)
        ergebnis.append(pfad)
    return ergebnis


# ---------------------------------------------------------------- Ablauf

def stand(plan, name):
    ordner = os.path.join(BASIS, name)
    jobs = auftraege(plan, name, ordner)
    fertig = sum(1 for a in jobs if vorhanden(ordner, a))
    return jobs, fertig


def frage_stufen(plan):
    namen = list(plan["stufen"].keys())
    print("\nWelche Stufen? Eine oder mehrere Nummern, mit Leerzeichen getrennt (z. B. 1 2 fuer eine Nacht).\n")
    for n, name in enumerate(namen, 1):
        st = plan["stufen"][name]
        jobs, fertig = stand(plan, name)
        offen = [a for a in jobs if not vorhanden(os.path.join(BASIS, name), a)]
        print("  %d  %-18s %3d Bilder  fertig %3d  ca. %-12s %s" % (n, name, len(jobs), fertig, dauer(schaetzung(offen)), asc(st["titel"])))
        print("     %-18s im Spiel: %s" % ("", asc(st.get("im_spiel", "?"))))
    antwort = input("\nNummern oder Namen: ").strip()
    gewaehlt = []
    for teil in antwort.replace(",", " ").split():
        if teil.isdigit() and 1 <= int(teil) <= len(namen):
            gewaehlt.append(namen[int(teil) - 1])
        elif teil in plan["stufen"]:
            gewaehlt.append(teil)
        else:
            print("Unbekannt:", teil)
            return []
    return gewaehlt


def bereite_vor(plan, name, flags):
    """Ordner festlegen (mit Rueckfrage, falls schon Bilder da sind) und die Auftraege bauen. Vor dem Start, damit die Nacht nicht wartet."""
    ordner = os.path.join(BASIS, name)
    schon = glob.glob(os.path.join(ordner, "*.png"))
    if schon and "--neu" in flags:
        ordner += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    elif schon and "--weiter" not in flags and "--trocken" not in flags:
        w = input("\n'%s': im Ordner liegen schon %d Bilder.  [W] Fehlende nachholen (Standard)   [N] Neu in neuem Ordner: " % (name, len(schon))).strip().lower()
        if w.startswith("n"):
            ordner += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    os.makedirs(ordner, exist_ok=True)
    jobs = auftraege(plan, name, ordner)
    with open(os.path.join(ordner, "prompts.txt"), "w", encoding="utf-8") as f:
        for a in jobs:
            f.write("%s | %s | %s | seed %d | %dx%d\n%s\n\n" % (a["id"], a["stil"], a["v"], a["seed"], a["breite"], a["hoehe"], a["prompt"]))
    return ordner, jobs


def bereite_comfy():
    if not server_da():
        sag("ComfyUI laeuft nicht.")
        if not (starte_comfy() and warte_auf_server(6)):
            sag("Bitte C:\\CF\\start.bat starten, warten bis dort 'To see the GUI' steht, und dieses Skript noch einmal starten.")
            return None
    for knoten, feld, datei in (("UNETLoader", "unet_name", MODELL), ("CLIPLoader", "clip_name", TEXTMODELL)):
        liste = optionen(knoten, feld)
        if liste is not None and datei not in liste:
            sag("Die Modelldatei %s fehlt in ComfyUI (gefunden: %s)." % (datei, ", ".join(liste[:5]) or "nichts"))
            return None
    if not os.path.exists(VAE_PFAD) or os.path.getsize(VAE_PFAD) < 300_000_000:
        sag("Lade das Bild-Aufbereiter-Paket (335 MB) ...")
        os.makedirs(os.path.dirname(VAE_PFAD), exist_ok=True)
        subprocess.run(["curl.exe", "-L", "-C", "-", "--retry", "10", "--retry-delay", "10", "--retry-all-errors", "-o", VAE_PFAD, VAE_URL])
    vaes = optionen("VAELoader", "vae_name") or []
    return "ae.safetensors" if "ae.safetensors" in vaes else ("taef1" if "taef1" in vaes else (vaes[0] if vaes else "taef1"))


def rechne_stufe(name, ordner, jobs, vae):
    """Gibt False zurueck, wenn die ganze Sitzung abbrechen soll (Strg+C, zu viele Neustarts oder Fehler in Folge)."""
    global logdatei, neustarts
    logdatei = os.path.join(ordner, "protokoll.txt")
    offen = [a for a in jobs if not vorhanden(ordner, a)]
    sag("\n=== Stufe '%s': %d Bilder, %d schon da, %d zu rechnen (ca. %s). Ordner: %s" % (name, len(jobs), len(jobs) - len(offen), len(offen),
                                                                                    dauer(schaetzung(offen)), ordner))
    ziffern_warnung(jobs)
    manifest_pfad = os.path.join(ordner, "manifest.json")
    try:
        with open(manifest_pfad, encoding="utf-8") as f:
            manifest = {m["praefix"]: m for m in json.load(f)}
    except Exception:
        manifest = {}
    start, gerechnet, summe, fehler_folge, ausgefallen, weiter = time.time(), 0, 0.0, 0, [], True
    try:
        for nr, a in enumerate(jobs, 1):
            if vorhanden(ordner, a):
                continue
            sek = None
            for versuch in (1, 2, 3, 4):
                try:
                    sek = rechne(a, vae)
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
                    weiter = False
                    break
                continue
            fehler_folge, gerechnet, summe = 0, gerechnet + 1, summe + sek
            rest = (len(offen) - gerechnet - len(ausgefallen)) * (summe / gerechnet)
            sag("[%d/%d] %s | %s | %s | %d s   (Stufe noch etwa %s)" % (nr, len(jobs), a["name"], a["stil"], a["v"], sek, dauer(rest)))
            manifest[a["praefix"]] = {"praefix": a["praefix"], "id": a["id"], "stil": a["stil"], "v": a["v"], "seed": a["seed"],
                                      "breite": a["breite"], "hoehe": a["hoehe"], "sekunden": round(sek, 1), "prompt": a["prompt"]}
            with open(manifest_pfad, "w", encoding="utf-8") as f:
                json.dump(list(manifest.values()), f, ensure_ascii=False, indent=1)
            if gerechnet % 5 == 0:
                try:
                    tafeln(ordner, jobs)   # Zwischenstand zum Hineinschauen
                except Exception as e:
                    sag("Zwischentafel nicht moeglich:", e)
    except KeyboardInterrupt:
        sag("Abgebrochen.")
        weiter = False
    sag("Stufe '%s': %d Bilder in %s (im Schnitt %s je Bild)." % (name, gerechnet, dauer(time.time() - start), dauer(summe / gerechnet) if gerechnet else "-"))
    if ausgefallen:
        sag("Fehlgeschlagen: %s  (nochmal starten holt sie nach)" % ", ".join(ausgefallen))
    for pfad in tafeln(ordner, jobs):
        sag("Tafel:", pfad)
    return weiter


def main():
    args = sys.argv[1:]
    flags = [a for a in args if a.startswith("--")]
    namen = [a for a in args if not a.startswith("--")]
    plan = lade_plan()
    if plan is None:
        return
    print("bildwerk.bat Version %s, Plan Version %s" % (VERSION, plan.get("version", "?")))
    if plan.get("version") != VERSION:
        print("ACHTUNG: Skript und Plan passen nicht zusammen. Beide Dateien neu von GitHub laden (bei Zwischenspeicher ein paar Minuten warten).")
        return
    gewaehlt = namen or frage_stufen(plan)
    unbekannt = [n for n in gewaehlt if n not in plan["stufen"]]
    if not gewaehlt or unbekannt:
        print("Keine gueltige Stufe gewaehlt. Moeglich: %s" % ", ".join(plan["stufen"]))
        return
    vorbereitet = [(n,) + bereite_vor(plan, n, flags) for n in gewaehlt]   # alle Rueckfragen jetzt, nicht mitten in der Nacht
    gesamt = sum(schaetzung([a for a in jobs if not vorhanden(o, a)]) for _, o, jobs in vorbereitet)
    print("\nGewaehlt: %s. Geschaetzte Rechenzeit fuer alles Offene: %s." % (", ".join(gewaehlt), dauer(gesamt)))
    if "--trocken" in flags:
        for n, o, jobs in vorbereitet:
            ziffern_warnung(jobs)
            print("Trockenlauf '%s': %d Bilder, Prompts in %s" % (n, len(jobs), os.path.join(o, "prompts.txt")))
        return
    vae = bereite_comfy()
    if vae is None:
        return
    print("Bild-Aufbereiter:", vae)
    print("Der Rechner bleibt wach, solange das Skript laeuft. Beenden mit Strg+C. Nicht ins Fenster klicken (sonst haelt es an; dann Esc).")
    wach_halten(True)
    try:
        for n, o, jobs in vorbereitet:
            if not rechne_stufe(n, o, jobs, vae):
                break
    finally:
        wach_halten(False)
    sag("\nFERTIG. Ergebnisse unter", BASIS)
    try:
        os.startfile(BASIS)
    except Exception:
        pass


main()
