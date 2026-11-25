@python_embeded\python.exe -x "%~f0" %* & pause & exit /b
# Bewegungswerk (Fassung 1.0): vom Video zur Bewegung, auf dem PC des Auftraggebers. Ablage: C:\CF (neben bildwerk.bat),
# daneben pose_zu_bvh.py und wan22_bewegung_api.json. Diese Datei ist zugleich Batch- und Python-Skript.
#
#   bewegungswerk.bat einrichten                 MediaPipe ins ComfyUI-Python, Posenmodell laden (einmal, etwa 2 Minuten)
#   bewegungswerk.bat video C:\Pfad\hieb.mp4     Video (Handy oder ComfyUI) -> hieb.bvh und hieb_vorschau.png
#   bewegungswerk.bat video hieb.mp4 --drehung 30    wenn man schräg zur Kamera stand (Grad, links herum positiv)
#   bewegungswerk.bat wan "a man in plain white linen ..." hieb    Video mit Wan 2.2 erzeugen (ComfyUI muss laufen),
#                                                danach wie "video"
# Ergebnis liegt in ComfyUI\output\bewegung\. Die .bvh-Datei und das Vorschaubild an Claude geben (oder mit
# herz-und-feder-3d\tools\sync.bat hochladen); Claude überträgt sie mit tools/bewegung/umrechnen.gd auf die Figuren.
import json, os, shutil, subprocess, sys, time, urllib.request, uuid

ROOT = os.path.dirname(os.path.abspath(sys.argv[0]))
PY = sys.executable
SERVER = os.environ.get("COMFY_SERVER", "http://127.0.0.1:8188")
AUS = os.path.join(ROOT, "ComfyUI", "output", "bewegung")
MODELL = os.path.join(ROOT, "pose_landmarker_heavy.task")
MODELL_URL = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task"
SKRIPT = os.path.join(ROOT, "pose_zu_bvh.py")
WORKFLOW = os.path.join(ROOT, "wan22_bewegung_api.json")


def sag(*t):
    print(" ".join(str(x) for x in t), flush=True)


def einrichten():
    sag("1/2 MediaPipe installieren (etwa 40 MB) ...")
    subprocess.check_call([PY, "-m", "pip", "install", "mediapipe"])
    if not os.path.exists(MODELL):
        sag("2/2 Posenmodell laden (30 MB) ...")
        urllib.request.urlretrieve(MODELL_URL, MODELL)
    sag("Fertig. Probe:  bewegungswerk.bat video <Datei.mp4>")


def video(datei, rest):
    if not os.path.exists(MODELL):
        sag("Erst einrichten:  bewegungswerk.bat einrichten")
        return
    os.makedirs(AUS, exist_ok=True)
    name = os.path.splitext(os.path.basename(datei))[0]
    bvh = os.path.join(AUS, name + ".bvh")
    bild = os.path.join(AUS, name + "_vorschau.png")
    t0 = time.time()
    subprocess.check_call([PY, SKRIPT, datei, bvh, "--modell", MODELL, "--vorschau", bild] + rest)
    sag("Dauer: %.0f s" % (time.time() - t0))
    sag("Jetzt das Vorschaubild ansehen:", bild)
    sag("Tor: Stehen die Strichmaennchen aufrecht, folgen die Arme der Bewegung, bleiben die Fuesse unten?")


def wan(text, name, rest):
    wf = json.load(open(WORKFLOW, encoding="utf-8"))
    wf.pop("_hinweis", None)
    if any(ch.isdigit() for ch in text):
        sag("Warnung: Ziffern im Prompt (siehe BILDWERK.md, Regel 1)")
    wf["5"]["inputs"]["text"] = text
    wf["11"]["inputs"]["filename_prefix"] = "bewegung/" + name
    wf["8"]["inputs"]["seed"] = int(time.time()) % 100000
    daten = json.dumps({"prompt": wf, "client_id": str(uuid.uuid4())}).encode()
    try:
        antwort = json.load(urllib.request.urlopen(urllib.request.Request(SERVER + "/prompt", data=daten, headers={"Content-Type": "application/json"})))
    except Exception as e:
        sag("ComfyUI antwortet nicht (laeuft start.bat?):", e)
        return
    pid = antwort["prompt_id"]
    sag("Wan rechnet ... (auf der RX 6800 XT vermutlich viele Minuten; Fortschritt im ComfyUI-Fenster)")
    t0 = time.time()
    while True:
        time.sleep(10)
        hist = json.load(urllib.request.urlopen(SERVER + "/history/" + pid))
        if pid in hist:
            break
    sag("Video fertig nach %.0f min" % ((time.time() - t0) / 60))
    for knoten in hist[pid]["outputs"].values():
        for liste in knoten.values():
            for f in liste if isinstance(liste, list) else []:
                if isinstance(f, dict) and str(f.get("filename", "")).endswith(".mp4"):
                    pfad = os.path.join(ROOT, "ComfyUI", "output", f.get("subfolder", ""), f["filename"])
                    video(pfad, rest)
                    return
    sag("Kein Video in der Ausgabe gefunden.")


def main():
    a = sys.argv[1:]
    if not a:
        sag(__doc__ or "bewegungswerk.bat einrichten | video <Datei> | wan \"<Prompt>\" <Name>")
        return
    if a[0] == "einrichten":
        einrichten()
    elif a[0] == "video" and len(a) > 1:
        video(a[1], a[2:])
    elif a[0] == "wan" and len(a) > 2:
        wan(a[1], a[2], a[3:])
    else:
        sag("Aufruf: bewegungswerk.bat einrichten | video <Datei> | wan \"<Prompt>\" <Name>")


main()
