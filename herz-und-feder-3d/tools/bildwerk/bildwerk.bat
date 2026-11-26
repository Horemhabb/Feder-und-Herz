@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Bildwerk (Fassung 5.4.0): das Masterskript fuer alle Bilder des Spiels mit dem laufenden ComfyUI (Z-Image Turbo).
# Nachfolger von symbole.bat. Diese Datei ist zugleich Batch- und Python-Skript (die erste Zeile startet Python mit -x).
# Ablage: im ComfyUI-Ordner (C:\CF), daneben bildwerk_plan.json. Alle Texte (Stile, Motive, Stufen, Seeds) stehen im Plan.
#
# Aufruf:  bildwerk.bat                       Menue: eine Nacht oder eine oder mehrere Stufen waehlen
#          bildwerk.bat nacht 1               eine ganze Nacht aus dem Plan (Nummer oder Name, z. B. "nacht dinge")
#          bildwerk.bat nacht 0 --trocken     nur zeigen, was die Nacht rechnen wuerde (Bilder, Dauer, Prompts)
#          bildwerk.bat symbole_neu           eine Stufe direkt
#          bildwerk.bat portraets_figuren portraets_leute --weiter
#          bildwerk.bat texturen_stunden --trocken   nur die Prompts in eine Datei schreiben, ohne ComfyUI
#          bildwerk.bat kachel_einrichten     laedt die Erweiterung fuer nahtlose Texturen nach ComfyUI\custom_nodes
#          bildwerk.bat tafeln <stufe>        nur die Uebersichtstafeln einer Stufe neu bauen (ohne ComfyUI)
# Schalter: --weiter (Fehlendes nachholen ohne Frage), --neu (neuer Ordner), --trocken, --ohne-kachel,
#           --stunden=7 (Zeitrahmen der Nacht fuer das Auffuellen mit Reserve-Stufen), --ohne-fuellen
#
# Fuer lange Laeufe: haelt den Rechner wach, ueberspringt fertige Bilder, versucht jedes Bild zweimal, rechnet reihum
# (erst alle Motive in Variante a, dann b ...), startet ComfyUI (start.bat) nach einem Absturz neu (hoechstens dreimal)
# und stellt alle Rueckfragen vor dem Start, damit die Nacht nicht an einer Frage haengen bleibt.
import ctypes, datetime, glob, hashlib, json, os, re, subprocess, sys, time, urllib.error, urllib.request, uuid
try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except Exception:   # ohne numpy oder PIL gibt es nur keine Tafeln; gerechnet wird trotzdem
    np = None

VERSION = "5.4.0"   # muss zur "version" in bildwerk_plan.json passen
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

# Nahtlose Texturen (ungeprueft auf AMD): die Erweiterung "Seamless Latent Tiling" (github.com/mikemojen, Knoten
# SeamlessLatentTiling) legt in jedem Rechenschritt die gegenueberliegenden Raender des Bildes um das Bild herum,
# das Modell sieht ueber die Naht hinweg und malt links passend zu rechts. Sie haengt sich um das Modell, nicht in es:
# geht also auch mit Z-Image (Transformer). Kostet Zeit, weil das Bild beim Rechnen um den Rand groesser ist.
KACHEL_KNOTEN = "SeamlessLatentTiling"
KACHEL_RAND = 128   # Pixel Rand je Seite beim Rechnen (die Erweiterung empfiehlt 128 als Anfang)
KACHEL_ORDNER = os.path.join(ROOT, "ComfyUI", "custom_nodes", "ComfyUI-seamless_latent_tiling")
# Fest genagelt: genau dieser Stand (Commit vom 10.03.2026, von Claude am 26.11.2026 gelesen: nur torch und math, kein Netz,
# keine Dateien). Geladen werden die drei Dateien einzeln von diesem Commit und mit ihrer SHA-256 verglichen; weicht eine
# ab, wird nichts eingerichtet. (Ein ZIP-Archiv von GitHub ist nicht bytegleich garantiert, die Dateien eines Commits sind es.)
KACHEL_COMMIT = "b4cba00b22817ab0ac48ba0d4af7eb1a325c4602"
KACHEL_ROH = "https://raw.githubusercontent.com/mikemojen/ComfyUI-seamless_latent_tiling/%s/%s"
KACHEL_DATEIEN = {
    "__init__.py": "b25c575e83b1acc204613686fa090a1c24c906d29f037fdd6420af46018c4b4f",
    "nodes.py": "9990356a5665f1c950711913057f155a35432b04d5e165f54219285f964a9dd8",
    "LICENSE": "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4",
}

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


def knoten_da(knoten):
    try:
        return knoten in api("/object_info/" + knoten)
    except Exception:
        return False


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


def graph(text, seed, vae, praefix, breite, hoehe, kachel=None):
    """kachel: None oder (Rand in Pixeln, waagrecht, senkrecht). Dann haengt sich SeamlessLatentTiling um das Modell."""
    g = {
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
    if kachel:
        g["11"] = {"class_type": KACHEL_KNOTEN, "inputs": {"model": ["2", 0], "padding": kachel[0], "tile_x": kachel[1], "tile_y": kachel[2]}}
        g["7"]["inputs"]["model"] = ["11", 0]
    return g


def rechne(a, vae):
    """Ein Bild rechnen. Gibt die Sekunden zurueck; wirft ServerWeg oder BildFehler."""
    try:
        antwort = api("/prompt", {"prompt": graph(a["prompt"], a["seed"], vae, a["comfy_praefix"], a["breite"], a["hoehe"], a.get("kachel")),
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


def _sha(daten):
    return hashlib.sha256(daten).hexdigest()


def kachel_einrichten():
    """Die Erweiterung fuer nahtlose Texturen in genau dem gelesenen Stand nach ComfyUI\\custom_nodes legen.
    Freiwillig: alle Naechte laufen auch mit --ohne-kachel. Danach ComfyUI neu starten."""
    print("Erweiterung 'Seamless Latent Tiling' (fremder Code, Stand %s), Ziel: %s" % (KACHEL_COMMIT[:12], KACHEL_ORDNER))
    vorhanden_ok = all(os.path.exists(os.path.join(KACHEL_ORDNER, n)) and
                       _sha(open(os.path.join(KACHEL_ORDNER, n), "rb").read()) == h for n, h in KACHEL_DATEIEN.items())
    if vorhanden_ok:
        print("Liegt schon da, Pruefsummen stimmen.")
    else:
        geladen = {}
        for name, soll in KACHEL_DATEIEN.items():
            try:
                with urllib.request.urlopen(KACHEL_ROH % (KACHEL_COMMIT, name), timeout=60) as r:
                    daten = r.read()
            except Exception as e:
                print("Laden ging nicht (%s): %s. Nichts eingerichtet; die Naechte laufen auch mit --ohne-kachel." % (name, e))
                return
            if _sha(daten) != soll:
                print("ABBRUCH: %s hat nicht die erwartete Pruefsumme (erwartet %s, bekommen %s). Nichts eingerichtet." % (name, soll[:16], _sha(daten)[:16]))
                return
            geladen[name] = daten
        os.makedirs(KACHEL_ORDNER, exist_ok=True)
        for alt in glob.glob(os.path.join(KACHEL_ORDNER, "*.py")):   # fremde Reste eines frueheren Standes
            if os.path.basename(alt) not in KACHEL_DATEIEN:
                os.rename(alt, alt + ".alt")
        for name, daten in geladen.items():
            with open(os.path.join(KACHEL_ORDNER, name), "wb") as f:
                f.write(daten)
        print("Eingerichtet, alle drei Pruefsummen stimmen.")
    print("\nJetzt ComfyUI neu starten: das schwarze Fenster von start.bat schliessen, start.bat wieder starten,")
    print("warten bis dort 'To see the GUI' steht. Dann prueft bildwerk.bat beim naechsten Start selbst, ob der Knoten da ist.")
    if server_da():
        print("ComfyUI laeuft gerade: Knoten %s %s." % (KACHEL_KNOTEN, "ist schon geladen" if knoten_da(KACHEL_KNOTEN) else "ist noch NICHT geladen (Neustart noetig)"))


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


def bausteine(plan, text):
    """{NEBET}, {LATERNE} ... durch die festen Saetze aus plan["bausteine"] ersetzen (gleiche Figur in jedem Bild)."""
    for name, b in plan.get("bausteine", {}).items():
        text = text.replace("{%s}" % name, b["text"])
    return text


def baue_prompt(plan, motiv, stil, ansichtsatz, v):
    text = plan["stile"][stil]["text"]
    for platz, wert in (("{MOTIV}", satz(bausteine(plan, motiv["motiv"]))), ("{HINWEIS}", satz(bausteine(plan, motiv.get("hinweis", "")))),
                        ("{ANSICHT}", satz(plan["ansichten"].get(ansichtsatz, {}).get(v, ""))), ("{TEX}", bausteine(plan, motiv.get("tex", "")))):
        text = text.replace(platz, wert)
    return " ".join(text.split())


def kachel_der_stufe(stufe):
    """'xy', 'x' oder 'y' im Plan -> (Rand, waagrecht, senkrecht), sonst None."""
    k = stufe.get("kachel")
    if not k:
        return None
    k = "xy" if k is True else str(k)
    return (stufe.get("kachel_rand", KACHEL_RAND), "x" in k, "y" in k)


def zeitfaktor(breite, hoehe, kachel):
    """Mehr Rechenzeit durch den Rand beim nahtlosen Rechnen (Flaeche, etwas mehr wegen der Aufmerksamkeit im Modell)."""
    if not kachel:
        return 1.0
    r, x, y = kachel
    flaeche = ((breite + 2 * r * x) * (hoehe + 2 * r * y)) / float(breite * hoehe)
    return flaeche ** 1.2


def auftraege(plan, name, ordner, ohne_kachel=False):
    """Reihenfolge: Variante, dann Motiv, dann Stil. So liegt bei jedem Abbruch ein vollstaendiger Satz der ersten Varianten vor.
    Nahtlos gerechnete Bilder haengen _k an den Namen, damit sie nicht mit gewoehnlich gerechneten verwechselt werden."""
    stufe = plan["stufen"][name]
    stile = [plan.get("standardstil", "aegypt") if s == "@standard" else s for s in stufe["stile"]]
    kachel = None if ohne_kachel else kachel_der_stufe(stufe)
    liste = []
    for v in stufe["varianten"]:
        for m in motive_der_stufe(plan, stufe):
            for stil in stile:
                praefix = "%s_%s_%s" % (asc(m.get("datei", m["id"])).replace(" ", "_"), stil, v) + ("_k" if kachel else "")
                b, h = stufe.get("breite", 1024), stufe.get("hoehe", 1024)
                liste.append({"id": m["id"], "name": m["name"], "stil": stil, "v": v, "seed": plan["seeds"][v],
                              "prompt": baue_prompt(plan, m, stil, stufe.get("ansichten", "emblem"), v),
                              "praefix": praefix, "comfy_praefix": "bildwerk/%s/%s" % (os.path.basename(ordner), praefix),
                              "breite": b, "hoehe": h, "kachel": kachel, "faktor": zeitfaktor(b, h, kachel)})
    return liste


def vorhanden(ordner, a):
    return sorted(glob.glob(os.path.join(ordner, a["praefix"] + "_*.png")))


def schaetzung(jobs):
    return sum(SEK_JE_MEGAPIXEL * a["breite"] * a["hoehe"] / (1024 * 1024) * a.get("faktor", 1.0) for a in jobs)


def ziffern_warnung(jobs):
    """Z-Image malt Zahlen und Prozentzeichen gern als Schrift ins Bild (aus '80%' wurde ein Bildmotiv). Darum vorher warnen."""
    gefunden = {}
    for a in jobs:
        for t in re.findall(r"\d+%?|%", a["prompt"]):
            gefunden.setdefault(a["stil"], set()).add(t)
    for stil, tokens in gefunden.items():
        sag("ACHTUNG Stil '%s': Zahlen im Prompt (%s). Ziffern koennen als Schrift im Bild landen." % (stil, ", ".join(sorted(tokens))))


def vorschau_art(plan, name):
    """Wie die Tafel ein Bild zeigt: kachel (2 x 2 gekachelt), band (2 x nebeneinander), schwarz (additiv auf Spielgrund),
    grau (freigestellt auf Spielgrund) oder leer (wie gerechnet). Aus der Stufe, sonst aus dem Stil."""
    st = plan["stufen"][name]
    if "vorschau" in st:
        return st["vorschau"]
    k = kachel_der_stufe(st)
    if k and not (k[1] and k[2]):
        return "band"
    return plan["stile"].get(st["stile"][0], {}).get("vorschau", "")


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


# ---------------------------------------------------------------- Uebersichtstafeln

SPIELGRUND = (46, 36, 28)   # dunkler Sandton wie der Boden im Spiel bei Nacht: darauf werden Schwarz- und Grau-Bilder gezeigt
LEGENDE = {
    "kachel": "2 x 2 gekachelt. S Schaerfe (unter 15 verwaschen)  H Helligkeit (Spiel: um 0,24)  N Naht (1 = glatt)  "
              "P Perspektive (bis 1,25 gut, ab 1,4 kachelt es nicht)  V Lichtverlauf (ab 1,3 sichtbar)",
    "band": "2 x nebeneinander. S Schaerfe  H Helligkeit (Spiel: um 0,24)  N Naht  P Perspektive (bis 1,25 gut)  V Lichtverlauf",
    "schwarz": "Additiv auf dem Spielboden gezeigt. S Schaerfe  Rand: Helligkeit am Bildrand (ueber 0,01 sieht man ein Viereck)",
    "grau": "Freigestellt auf dem Spielboden gezeigt. S Schaerfe  Grund: Unruhe des Hintergrunds (unter 0,04 gut)  "
            "Rand: Deckkraft am Bildrand (ueber 0,02 beruehrt der Gegenstand den Rand)",
    "": "S Schaerfe (unter 15 verwaschen)  H Helligkeit linear",
}


_zellen = {}   # schon aufbereitete Zellen: die Zwischentafeln alle fuenf Bilder messen nicht alles neu


def zelle(pfad, art, zb, zh):
    """Ein Bild so aufbereiten, wie es die Tafel zeigt, dazu Messwerte (Text, Punktzahl)."""
    schluessel = (pfad, os.path.getmtime(pfad), art, zb, zh)
    if schluessel not in _zellen:
        _zellen[schluessel] = _zelle(pfad, art, zb, zh)
    return _zellen[schluessel]


def _zelle(pfad, art, zb, zh):
    im = Image.open(pfad).convert("RGB")
    a = np.asarray(im)
    txt, punkte, _ = messwerte(a, art)
    if art == "kachel":
        k = im.resize((zb // 2, zh // 2), Image.LANCZOS)
        bild = Image.new("RGB", (zb, zh))
        for x in (0, 1):
            for y in (0, 1):
                bild.paste(k, (x * (zb // 2), y * (zh // 2)))
    elif art == "band":
        k = im.resize((zb // 2, zh), Image.LANCZOS)
        bild = Image.new("RGB", (zb, zh))
        bild.paste(k, (0, 0))
        bild.paste(k, (zb // 2, 0))
    elif art == "schwarz":
        k = np.asarray(im.resize((zb, zh), Image.LANCZOS)).astype(np.float32)
        bild = Image.fromarray(np.clip(k + np.array(SPIELGRUND, np.float32), 0, 255).astype(np.uint8))
    elif art == "grau":
        rgba = alpha_aus_grund(np.asarray(im.resize((zb * 2, zh * 2), Image.LANCZOS)))
        bild = Image.new("RGBA", (zb * 2, zh * 2), SPIELGRUND + (255,))
        bild.alpha_composite(Image.fromarray(rgba, "RGBA"))
        bild = bild.convert("RGB").resize((zb, zh), Image.LANCZOS)
    else:
        bild = im.resize((zb, zh), Image.LANCZOS)
    return bild, txt, punkte


def tafeln(ordner, jobs, art=""):
    """Uebersichtstafeln: je Motiv alle Varianten nebeneinander, darunter Messwerte. Wo die Werte etwas sagen (Texturen,
    Bilder auf Schwarz oder Grau), bekommt die beste Variante einen goldenen Rahmen und das Wort EMPFOHLEN."""
    if np is None or not jobs:
        return []
    try:
        schrift = ImageFont.truetype("arial.ttf", 16)
        klein = ImageFont.truetype("arial.ttf", 13)
    except Exception:
        schrift = klein = ImageFont.load_default()
    ZB = 256
    ZH = int(ZB * jobs[0]["hoehe"] / jobs[0]["breite"])
    LUECKE, SEITE, KOPF, FUSS = 10, 12, 34, 44
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
        hoch = 22 + ZH + FUSS
        blatt = Image.new("RGB", (max(pro_zeile * gruppenbreite + LUECKE, 900), KOPF + zeilen * hoch + LUECKE), (16, 14, 18))
        d = ImageDraw.Draw(blatt)
        d.text((LUECKE, 8), asc(LEGENDE.get(art, LEGENDE[""])), fill=(150, 140, 120), font=klein)
        for k, (i, n) in enumerate(teil):
            gx, gy = LUECKE + (k % pro_zeile) * gruppenbreite, KOPF + (k // pro_zeile) * hoch
            d.text((gx, gy), "%s (%s)" % (asc(n), i), fill=(230, 200, 120), font=schrift)
            werte = []
            for c, a in enumerate(gruppen[i]):
                dateien = vorhanden(ordner, a)
                x = gx + c * (ZB + LUECKE)
                txt, punkte = "", None
                if dateien:
                    try:
                        bild, txt, punkte = zelle(dateien[-1], art, ZB, ZH)
                        blatt.paste(bild, (x, gy + 22))
                    except Exception as e:
                        txt = "Fehler: %s" % e
                werte.append((punkte, x))
                d.text((x, gy + 22 + ZH + 4), "%s / %s%s" % (a["stil"], a["v"], " / nahtlos" if a.get("kachel") else ""), fill=(160, 150, 130), font=klein)
                d.text((x, gy + 22 + ZH + 21), txt, fill=(130, 125, 115), font=klein)
            mit = [w for w in werte if w[0] is not None]
            if len(mit) >= 2:
                _, bx = max(mit)
                d.rectangle((bx - 3, gy + 19, bx + ZB + 2, gy + 22 + ZH + 2), outline=(240, 200, 90), width=3)
                d.text((bx + 6, gy + 26), "EMPFOHLEN", fill=(255, 215, 110), font=schrift)
        pfad = os.path.join(ordner, "uebersicht_%02d.jpg" % (seite + 1))
        blatt.save(pfad, quality=88)
        ergebnis.append(pfad)
    return ergebnis


# ---------------------------------------------------------------- Ablauf

def stand(plan, name, ohne_kachel=False):
    ordner = os.path.join(BASIS, name)
    jobs = auftraege(plan, name, ordner, ohne_kachel)
    fertig = sum(1 for a in jobs if vorhanden(ordner, a))
    return jobs, fertig


def offen_sek(plan, name):
    jobs, _ = stand(plan, name)
    return schaetzung([a for a in jobs if not vorhanden(os.path.join(BASIS, name), a)])


def nacht_finden(plan, wort):
    """Nacht per Nummer (Reihenfolge im Plan, ab 0) oder Name."""
    namen = list(plan.get("naechte", {}).keys())
    w = wort.lower().lstrip("n")
    if wort in plan.get("naechte", {}):
        return wort
    if w.isdigit() and int(w) < len(namen):
        return namen[int(w)]
    treffer = [n for n in namen if wort.lower() in n.lower()]
    return treffer[0] if len(treffer) == 1 else None


def nacht_stand(plan, nacht):
    """(Bilder, fertig, Sekunden offen) ueber alle Stufen der Nacht ohne Reserve."""
    n = f = 0
    sek = 0.0
    for name in plan["naechte"][nacht]["stufen"]:
        jobs, fertig = stand(plan, name)
        n, f = n + len(jobs), f + fertig
        sek += offen_sek(plan, name)
    return n, f, sek


def frage_stufen(plan):
    """Menue. Gibt (Stufen, Nacht oder None) zurueck."""
    naechte = list(plan.get("naechte", {}).keys())
    if naechte:
        print("\nNAECHTE (eine Nacht = mehrere Stufen in der Reihenfolge ihres Nutzens). Waehlen mit N und Nummer, z. B. N1:\n")
        for k, nacht in enumerate(naechte):
            nd = plan["naechte"][nacht]
            n, f, sek = nacht_stand(plan, nacht)
            status = "FERTIG" if n and f >= n else "fertig %3d von %3d" % (f, n)
            print("  N%d  %-12s %-20s noch ca. %-12s %s" % (k, nacht, status, dauer(sek), asc(nd["titel"])))
    namen = list(plan["stufen"].keys())
    print("\nEINZELNE STUFEN: eine oder mehrere Nummern, mit Leerzeichen getrennt (z. B. 1 2).\n")
    for n, name in enumerate(namen, 1):
        st = plan["stufen"][name]
        jobs, fertig = stand(plan, name)
        print("  %2d  %-24s %3d Bilder  fertig %3d  ca. %-12s %s" % (n, name, len(jobs), fertig, dauer(offen_sek(plan, name)), asc(st["titel"])))
        print("      %-24s im Spiel: %s" % ("", asc(st.get("im_spiel", "?"))))
    antwort = input("\nN und Nummer fuer eine Nacht, sonst Nummern oder Namen: ").strip()
    if antwort[:1] in "nN" and antwort[1:].strip().isdigit():
        nacht = nacht_finden(plan, antwort[1:].strip())
        if nacht:
            return list(plan["naechte"][nacht]["stufen"]), nacht
    gewaehlt = []
    for teil in antwort.replace(",", " ").split():
        if teil.isdigit() and 1 <= int(teil) <= len(namen):
            gewaehlt.append(namen[int(teil) - 1])
        elif teil in plan["stufen"]:
            gewaehlt.append(teil)
        else:
            print("Unbekannt:", teil)
            return [], None
    return gewaehlt, None


def bereite_vor(plan, name, flags, ohne_kachel=False, fragen=True):
    """Ordner festlegen (mit Rueckfrage, falls schon Bilder da sind) und die Auftraege bauen. Vor dem Start, damit die Nacht nicht wartet."""
    ordner = os.path.join(BASIS, name)
    schon = glob.glob(os.path.join(ordner, "*.png"))
    if schon and "--neu" in flags:
        ordner += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    elif schon and fragen and "--weiter" not in flags and "--trocken" not in flags:
        w = input("\n'%s': im Ordner liegen schon %d Bilder.  [W] Fehlende nachholen (Standard)   [N] Neu in neuem Ordner: " % (name, len(schon))).strip().lower()
        if w.startswith("n"):
            ordner += "_" + datetime.datetime.now().strftime("%Y%m%d_%H%M")
    os.makedirs(ordner, exist_ok=True)
    jobs = auftraege(plan, name, ordner, ohne_kachel)
    with open(os.path.join(ordner, "prompts.txt"), "w", encoding="utf-8") as f:
        for a in jobs:
            f.write("%s | %s | %s | seed %d | %dx%d%s\n%s\n\n" % (a["id"], a["stil"], a["v"], a["seed"], a["breite"], a["hoehe"],
                                                               " | nahtlos" if a.get("kachel") else "", a["prompt"]))
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


def kachel_klaeren(plan, vorbereitet, flags):
    """Stufen mit nahtlosem Rechnen brauchen den Knoten SeamlessLatentTiling. Fehlt er, jetzt fragen (vor der Nacht)."""
    mit = [n for n, o, jobs in vorbereitet if any(a.get("kachel") for a in jobs)]
    if not mit or knoten_da(KACHEL_KNOTEN):
        if mit:
            sag("Nahtlos rechnen: Knoten %s ist da." % KACHEL_KNOTEN)
        return vorbereitet
    if "--ohne-kachel" in flags:
        w = "o"
    else:
        print("\nDie Stufen %s wollen nahtlos rechnen, aber in ComfyUI fehlt der Knoten %s." % (", ".join(mit), KACHEL_KNOTEN))
        print("  [E] Erweiterung jetzt einrichten und abbrechen (dann ComfyUI neu starten und dieses Skript nochmal starten)")
        print("  [O] diese Stufen gewoehnlich rechnen (Standard; Naht glaettet spaeter einbauen.bat, Perspektive bleibt ein Risiko)")
        print("  [U] diese Stufen auslassen")
        w = input("Wahl: ").strip().lower()
    if w.startswith("e"):
        kachel_einrichten()
        return None
    neu = []
    for n, o, jobs in vorbereitet:
        if n not in mit:
            neu.append((n, o, jobs))
        elif not w.startswith("u"):
            neu.append((n, o, auftraege(plan, n, o, ohne_kachel=True)))
            sag("Stufe '%s' ohne Kacheln (Dateien ohne _k)." % n)
        else:
            sag("Stufe '%s' ausgelassen." % n)
    return neu


def rechne_stufe(name, ordner, jobs, vae, art="", frist=None):
    """Gibt False zurueck, wenn die ganze Sitzung abbrechen soll (Strg+C, zu viele Neustarts oder Fehler in Folge).
    frist: Uhrzeit (time.time()), nach der kein neues Bild mehr begonnen wird (fuer Reserve-Stufen)."""
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
            if frist is not None:
                schnitt = summe / gerechnet if gerechnet else schaetzung([a])
                if time.time() + schnitt > frist:
                    sag("Zeitrahmen der Nacht erreicht: Reserve-Stufe '%s' hoert hier auf." % name)
                    break
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
                                      "breite": a["breite"], "hoehe": a["hoehe"], "nahtlos": bool(a.get("kachel")), "sekunden": round(sek, 1), "prompt": a["prompt"]}
            with open(manifest_pfad, "w", encoding="utf-8") as f:
                json.dump(list(manifest.values()), f, ensure_ascii=False, indent=1)
            if gerechnet % 5 == 0:
                try:
                    tafeln(ordner, jobs, art)   # Zwischenstand zum Hineinschauen
                except Exception as e:
                    sag("Zwischentafel nicht moeglich:", e)
    except KeyboardInterrupt:
        sag("Abgebrochen.")
        weiter = False
    sag("Stufe '%s': %d Bilder in %s (im Schnitt %s je Bild)." % (name, gerechnet, dauer(time.time() - start), dauer(summe / gerechnet) if gerechnet else "-"))
    if ausgefallen:
        sag("Fehlgeschlagen: %s  (nochmal starten holt sie nach)" % ", ".join(ausgefallen))
    bericht = {"stufe": name, "gerechnet": gerechnet, "sekunden": round(time.time() - start), "ausgefallen": ausgefallen, "tafeln": []}
    try:
        bericht["tafeln"] = tafeln(ordner, jobs, art)
    except Exception as e:
        sag("Tafeln nicht moeglich:", e)
    for pfad in bericht["tafeln"]:
        sag("Tafel:", pfad)
    bericht["fertig"] = sum(1 for a in jobs if vorhanden(ordner, a))
    bericht["bilder"] = len(jobs)
    return weiter, bericht


def zusammenfassung(nacht, berichte, beginn):
    """Am Ende einer Nacht: eine Datei mit allen Stufen, Zahlen und den Pfaden aller Tafeln (die schickt der Auftraggeber)."""
    zeilen = ["Nacht '%s' vom %s, Dauer %s" % (nacht or "ohne Namen", datetime.datetime.fromtimestamp(beginn).strftime("%d.%m.%Y %H:%M"),
                                                dauer(time.time() - beginn)), ""]
    for b in berichte:
        zeilen.append("%-26s %3d gerechnet, %3d von %3d fertig, %s%s" % (b["stufe"], b["gerechnet"], b["fertig"], b["bilder"], dauer(b["sekunden"]),
                                                                       "  RESERVE" if b.get("reserve") else ""))
        if b["ausgefallen"]:
            zeilen.append("     fehlgeschlagen: " + ", ".join(b["ausgefallen"]))
    zeilen += ["", "Tafeln (diese Bilder an Claude schicken):"]
    for b in berichte:
        for t in b["tafeln"]:
            zeilen.append("  " + t)
    os.makedirs(BASIS, exist_ok=True)
    pfad = os.path.join(BASIS, "zusammenfassung_%s_%s.txt" % (nacht or "stufen", datetime.datetime.now().strftime("%Y%m%d_%H%M")))
    with open(pfad, "w", encoding="utf-8") as f:
        f.write("\n".join(zeilen) + "\n")
    sag("\n" + "\n".join(zeilen))
    sag("\nZusammenfassung gespeichert:", pfad)
    return pfad


def tafeln_neu(plan, name):
    """Nur die Tafeln einer Stufe neu bauen (zum Beispiel nach einem Werkzeug-Update), ohne ComfyUI."""
    ordner = os.path.join(BASIS, name)
    jobs = auftraege(plan, name, ordner)
    if not any(vorhanden(ordner, a) for a in jobs):
        jobs = auftraege(plan, name, ordner, ohne_kachel=True)   # die Stufe wurde ohne Kacheln gerechnet
    for pfad in tafeln(ordner, jobs, vorschau_art(plan, name)):
        print("Tafel:", pfad)


def main():
    args = sys.argv[1:]
    flags = [a for a in args if a.startswith("--")]
    namen = [a for a in args if not a.startswith("--")]
    if namen[:1] == ["kachel_einrichten"]:
        kachel_einrichten()
        return
    plan = lade_plan()
    if plan is None:
        return
    print("bildwerk.bat Version %s, Plan Version %s" % (VERSION, plan.get("version", "?")))
    if plan.get("version") != VERSION:
        print("ACHTUNG: Skript und Plan passen nicht zusammen. Beide Dateien neu von GitHub laden (bei Zwischenspeicher ein paar Minuten warten).")
        return
    if namen[:1] == ["tafeln"]:
        for n in namen[1:]:
            tafeln_neu(plan, n)
        return
    nacht = None
    if namen[:1] == ["nacht"]:
        nacht = nacht_finden(plan, namen[1]) if len(namen) > 1 else None
        if not nacht:
            print("Welche Nacht? Moeglich: %s (oder die Nummer ab 0)" % ", ".join(plan.get("naechte", {})))
            return
        gewaehlt = list(plan["naechte"][nacht]["stufen"])
    elif namen:
        gewaehlt = namen
    else:
        gewaehlt, nacht = frage_stufen(plan)
    unbekannt = [n for n in gewaehlt if n not in plan["stufen"]]
    if not gewaehlt or unbekannt:
        print("Keine gueltige Stufe gewaehlt. Moeglich: %s" % ", ".join(plan["stufen"]))
        return
    nd = plan["naechte"][nacht] if nacht else {}
    reserve = [] if "--ohne-fuellen" in flags else [r for r in nd.get("fuellen", []) if r in plan["stufen"] and r not in gewaehlt]
    stunden = nd.get("stunden", 0)
    for f in flags:
        if f.startswith("--stunden="):
            stunden = float(f.split("=", 1)[1].replace(",", "."))
    if nacht:
        print("\nNacht '%s': %s\nZweck: %s" % (nacht, asc(nd["titel"]), asc(nd.get("zweck", ""))))
    ohne_kachel = "--ohne-kachel" in flags
    vorbereitet = [(n,) + bereite_vor(plan, n, flags, ohne_kachel) for n in gewaehlt]   # alle Rueckfragen jetzt, nicht mitten in der Nacht
    vorrat = [(n,) + bereite_vor(plan, n, flags, ohne_kachel, fragen=False) for n in reserve]
    gesamt = sum(schaetzung([a for a in jobs if not vorhanden(o, a)]) for _, o, jobs in vorbereitet)
    print("\nGewaehlt: %s. Geschaetzte Rechenzeit fuer alles Offene: %s." % (", ".join(gewaehlt), dauer(gesamt)))
    if any(a.get("kachel") for _, _, jobs in vorbereitet for a in jobs):
        ohne = sum(schaetzung([dict(a, faktor=1.0) for a in jobs if not vorhanden(o, a)]) for _, o, jobs in vorbereitet)
        print("Darin nahtlos gerechnete Bilder (brauchen mehr Zeit). Ohne Kacheln waeren es etwa %s." % dauer(ohne))
    if vorrat and stunden:
        print("Reserve zum Auffuellen bis %s nach Beginn: %s (zusammen bis zu %s offen)." % (dauer(stunden * 3600), ", ".join(reserve),
              dauer(sum(schaetzung([a for a in jobs if not vorhanden(o, a)]) for _, o, jobs in vorrat))))
    if "--trocken" in flags:
        for n, o, jobs in vorbereitet + vorrat:
            ziffern_warnung(jobs)
            print("Trockenlauf '%s': %d Bilder, ca. %s, Prompts in %s" % (n, len(jobs), dauer(schaetzung(jobs)), os.path.join(o, "prompts.txt")))
        return
    vae = bereite_comfy()
    if vae is None:
        return
    vorbereitet = kachel_klaeren(plan, vorbereitet, flags)
    if vorbereitet is None:
        return
    vorrat = kachel_klaeren(plan, vorrat, flags + ["--ohne-kachel"]) if vorrat else []
    print("Bild-Aufbereiter:", vae)
    print("Der Rechner bleibt wach, solange das Skript laeuft. Beenden mit Strg+C. Nicht ins Fenster klicken (sonst haelt es an; dann Esc).")
    beginn = time.time()
    berichte = []
    wach_halten(True)
    try:
        weiter = True
        for n, o, jobs in vorbereitet:
            weiter, b = rechne_stufe(n, o, jobs, vae, vorschau_art(plan, n))
            berichte.append(b)
            if not weiter:
                break
        if weiter and vorrat and stunden:
            frist = beginn + stunden * 3600
            for n, o, jobs in vorrat:
                if time.time() + 300 > frist:
                    break
                sag("\nNoch Zeit bis zum Ende des Rahmens (%s): fuelle mit Reserve-Stufe '%s' auf." % (dauer(frist - time.time()), n))
                weiter, b = rechne_stufe(n, o, jobs, vae, vorschau_art(plan, n), frist)
                b["reserve"] = True
                berichte.append(b)
                if not weiter:
                    break
    finally:
        wach_halten(False)
    if berichte:
        zusammenfassung(nacht, berichte, beginn)
    sag("\nFERTIG. Ergebnisse unter", BASIS)
    try:
        os.startfile(BASIS)
    except Exception:
        pass


main()
