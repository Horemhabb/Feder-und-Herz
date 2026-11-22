@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Symbole, Stapel 1, zweite Fassung (4.0.7): erzeugt die ersten zehn Fähigkeiten-Symbole mit dem laufenden ComfyUI (Z-Image Turbo),
# je zwei Varianten, und baut eine Übersichtstafel. Diese Datei ist ein Batch-Skript und zugleich ein Python-Skript
# (die erste Zeile startet Python mit -x, das sie überspringt). Ablage: im ComfyUI-Ordner (C:\CF). ComfyUI muss laufen.
import json, os, sys, time, uuid, glob, subprocess, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
SERVER = "http://127.0.0.1:8188"
OUT = os.path.join(ROOT, "ComfyUI", "output")
ZIEL = os.path.join(OUT, "icons2")
VAE_PFAD = os.path.join(ROOT, "ComfyUI", "models", "vae", "ae.safetensors")
VAE_URL = "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
VARIANTEN = [("a", 101), ("b", 202)]

STIL = ("Dark fantasy game ability icon in the style of Diablo 4 and Baldur's Gate 3 skill icons: a single emblem centered and filling "
        "about 80% of the square, close-up, strong readable silhouette, painterly digital illustration with realistic hammered gold, "
        "blackened iron and gemstone materials, glowing magical light and a few drifting embers coming from the emblem itself, "
        "dramatic rim lighting, rich moody colors. Behind it only a plain dark textured surface ({TEX}) with a soft vignette: "
        "no scenery, no architecture, no landscape, no ground, no horizon, no objects in the background. "
        "Square game icon, no text, no border, no frame.")

ICONS = [
 ("whirl", "Falkenkreis", "A golden falcon of Horus emblem seen from above, circling in a tight spiral with wings spread wide, surrounded by a ring of swirling blue-white wind.", "weathered dark sandstone"),
 ("dash", "Sturz des Falken", "A golden falcon of Horus emblem diving steeply head-down with talons thrust forward, streaks of motion trailing behind it.", "dark cracked basalt"),
 ("oath", "Eid der Maat", "The white ostrich feather of Maat glowing with golden light, floating above a raised open palm, sparkling gold motes.", "dark stone with faint engraved hieroglyphs"),
 ("udjat", "Blick des Udjat", "The Eye of Horus (udjat) forged from blackened iron and hammered gold with a luminous turquoise iris, a shockwave ring of light pulsing outward.", "dark scorched obsidian"),
 ("beam", "Strahl des Re", "A blazing red-gold sun disc of Re with a rearing cobra, a straight beam of white-gold light shooting downward and ending in small glowing hands.", "dark painted plaster with faint stars"),
 ("flurry", "Faeuste des Month", "Two clenched fists wrapped in linen bandages and bronze studs striking rapidly, with several ghost afterimages and ochre impact sparks.", "scorched dark sandstone"),
 ("step", "Schritt des Schu", "A bare sandaled foot mid-stride dissolving into streaks of swirling wind and white feathers, a small star where it lands.", "smoky grey stone"),
 ("mantra", "Kreis des Ka", "The Egyptian ka symbol, two raised arms, inside a glowing turquoise ring of light with a red beating heart at its center, healing sparks rising.", "dark stone with faint concentric carved circles"),
 ("palm", "Gebs Lachen", "A mighty stone fist smashing into cracked earth that splits open with glowing green fissures, flying rock shards, Geb the earth god.", "dark cracked earth"),
 ("wave", "Atem des Schu", "A billowing sail catching a powerful wind, curling turquoise and white breath streams, flying feathers.", "dark storm-grey stone"),
]


def api(pfad, daten=None):
    anfrage = urllib.request.Request(SERVER + pfad, data=None if daten is None else json.dumps(daten).encode(),
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(anfrage, timeout=60) as r:
        return json.loads(r.read().decode())


def optionen(knoten, feld):
    try:
        return api("/object_info/" + knoten)[knoten]["input"]["required"][feld][0]
    except Exception:
        return []


def graph(text, seed, vae, praefix):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": "z_image_turbo_bf16.safetensors", "weight_dtype": "default"}},
        "2": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_3_4b.safetensors", "type": "lumina2", "device": "cpu"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["3", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": "low quality, blurry, text, watermark", "clip": ["3", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "seed": seed, "steps": 8, "cfg": 1.0, "sampler_name": "res_multistep",
                                                   "scheduler": "simple", "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0], "denoise": 1.0}},
        "8": {"class_type": "VAELoader", "inputs": {"vae_name": vae}},
        "9": {"class_type": "VAEDecodeTiled", "inputs": {"samples": ["7", 0], "vae": ["8", 0], "tile_size": 512, "overlap": 64, "temporal_size": 64, "temporal_overlap": 8}},
        "10": {"class_type": "SaveImage", "inputs": {"images": ["9", 0], "filename_prefix": praefix}},
    }


def erzeuge(text, seed, vae, praefix):
    try:
        antwort = api("/prompt", {"prompt": graph(text, seed, vae, praefix), "client_id": str(uuid.uuid4())})
    except urllib.error.HTTPError as e:
        print("FEHLER von ComfyUI:", e.read().decode()[:1500])
        sys.exit(1)
    pid = antwort["prompt_id"]
    start = time.time()
    while time.time() - start < 1800:
        time.sleep(3)
        h = api("/history/" + pid)
        if pid in h:
            if h[pid].get("status", {}).get("status_str") == "error":
                print("FEHLER beim Rechnen:", json.dumps(h[pid]["status"])[:1500])
                sys.exit(1)
            return time.time() - start
    print("FEHLER: Zeitueberschreitung")
    sys.exit(1)


def tafel(ids):
    from PIL import Image, ImageDraw, ImageFont
    try:
        schrift = ImageFont.truetype("arial.ttf", 18)
    except Exception:
        schrift = ImageFont.load_default()
    Z, spalten = 300, 4
    paare = [(i, n, v) for (i, n, _, _) in ids for (v, _) in VARIANTEN]
    zeilen = (len(paare) + spalten - 1) // spalten
    blatt = Image.new("RGB", (spalten * (Z + 12) + 12, zeilen * (Z + 40) + 12 + 110), (16, 14, 18))
    d = ImageDraw.Draw(blatt)
    for k, (i, n, v) in enumerate(paare):
        dateien = sorted(glob.glob(os.path.join(ZIEL, "%s_%s_*.png" % (i, v))))
        if not dateien:
            continue
        bild = Image.open(dateien[-1]).convert("RGB").resize((Z, Z), Image.LANCZOS)
        x, y = 12 + (k % spalten) * (Z + 12), 12 + (k // spalten) * (Z + 40)
        blatt.paste(bild, (x, y))
        d.text((x, y + Z + 6), "%s (%s) - %s" % (n, i, v), fill=(230, 200, 120), font=schrift)
    y = zeilen * (Z + 40) + 24
    d.text((12, y - 4), "Leistengroesse (64 px), Variante a und b:", fill=(160, 150, 130), font=schrift)
    for k, (i, n, v) in enumerate(paare):
        dateien = sorted(glob.glob(os.path.join(ZIEL, "%s_%s_*.png" % (i, v))))
        if dateien:
            klein = Image.open(dateien[-1]).convert("RGB").resize((64, 64), Image.LANCZOS)
            blatt.paste(klein, (12 + (k % 20) * 70, y + 20 + (k // 20) * 70))
    pfad = os.path.join(ZIEL, "uebersicht.jpg")
    blatt.save(pfad, quality=90)
    return pfad


def main():
    os.makedirs(ZIEL, exist_ok=True)
    try:
        api("/system_stats")
    except Exception:
        print("ComfyUI laeuft nicht. Starte zuerst C:\\CF\\start.bat und warte, bis dort 'To see the GUI' steht.")
        return
    if not os.path.exists(VAE_PFAD) or os.path.getsize(VAE_PFAD) < 300_000_000:
        print("Lade das bessere Bild-Aufbereiter-Paket (335 MB) ...")
        os.makedirs(os.path.dirname(VAE_PFAD), exist_ok=True)
        subprocess.run(["curl.exe", "-L", "-C", "-", "--retry", "10", "--retry-delay", "10", "--retry-all-errors", "-o", VAE_PFAD, VAE_URL])
    vaes = optionen("VAELoader", "vae_name")
    vae = "ae.safetensors" if "ae.safetensors" in vaes else ("taef1" if "taef1" in vaes else (vaes[0] if vaes else "taef1"))
    print("Bild-Aufbereiter:", vae)
    gesamt, nr = len(ICONS) * len(VARIANTEN), 0
    for i, n, motiv, tex in ICONS:
        for v, seed in VARIANTEN:
            nr += 1
            if glob.glob(os.path.join(ZIEL, "%s_%s_*.png" % (i, v))):
                print("[%d/%d] %s (%s) schon vorhanden" % (nr, gesamt, n, v))
                continue
            sek = erzeuge(motiv + " " + STIL.replace("{TEX}", tex), seed, vae, "icons2/%s_%s" % (i, v))
            print("[%d/%d] %s (%s) fertig in %d s" % (nr, gesamt, n, v, sek))
    pfad = tafel(ICONS)
    print("\nFERTIG. Uebersicht:", pfad)
    try:
        os.startfile(ZIEL)
    except Exception:
        pass


main()
