# Attrappe von ComfyUI zum Pruefen von bildwerk.bat ohne Grafikkarte (fuer Claude in der Cloud, nicht fuer den PC).
# Beantwortet /system_stats, /object_info, /prompt und /history wie ComfyUI und legt fuer jeden Auftrag ein Probebild ab,
# das zum Stil passt: Flaechen (nahtlos nur, wenn der Graph den Kachel-Knoten enthaelt, sonst mit Perspektive),
# Dinge auf Grau, Leuchtendes auf Schwarz, sonst ein Verlauf. So lassen sich Naechte, Tafeln und Messwerte durchspielen.
#
#   python3 attrappe_comfy.py <ComfyUI-Ordner> [port] [--ohne-kachel]
#   COMFY_SERVER=http://127.0.0.1:8199 SYMBOLE_TAKT=0.05 python3 -x bildwerk.bat nacht 0 --weiter
import json, os, sys, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

COMFY = sys.argv[1]
PORT = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 8199
KACHEL = "--ohne-kachel" not in sys.argv
LOG = os.path.join(COMFY, "attrappe_graphen.jsonl")
fertig = {}
zaehler = [0]


def rauschen(n, k, seed, nahtlos):
    rng = np.random.default_rng(seed)
    if nahtlos:   # periodisches Rauschen: kachelt
        f = np.fft.fft2(rng.standard_normal((n, n)))
        fy, fx = np.fft.fftfreq(n)[:, None], np.fft.fftfreq(n)[None, :]
        r = np.sqrt(fx * fx + fy * fy) + 1e-3
        g = np.real(np.fft.ifft2(f * np.exp(-(r * n / k) ** 2) / r ** 0.5))
    else:         # Perspektive: oben fein, unten grob, dazu Licht von links
        g = np.zeros((n, n))
        for y in range(n):
            s = 0.4 + 0.6 * y / n
            x = np.arange(n) * 0.05 / s
            g[y] = np.sin(x + y * 0.08 / s) + 0.4 * np.sin(x * 2.3 + y * 0.03 / s)
        g = g * (0.7 + 0.6 * np.linspace(0, 1, n)[None, :])
    g = (g - g.min()) / (np.ptp(g) + 1e-9)
    return g


def bild(prompt, b, h, seed, nahtlos):
    p = prompt.lower()
    if "surface texture" in p or "tileable" in p:
        g = rauschen(max(b, h), 24, seed, nahtlos)[:h, :b]
        a = np.stack([g * 150 + 60, g * 120 + 50, g * 90 + 40], -1)
        return Image.fromarray(a.astype(np.uint8))
    if "medium grey background" in p:
        im = Image.new("RGB", (b, h), (128, 128, 128))
        d = ImageDraw.Draw(im)
        d.ellipse((b * 0.22, h * 0.18, b * 0.78, h * 0.82), fill=(200, 150, 50))
        d.rectangle((b * 0.45, h * 0.1, b * 0.55, h * 0.9), fill=(40, 60, 160))
        return im.filter(ImageFilter.GaussianBlur(1.5))
    if "pure flat black" in p or "pure black" in p:
        y, x = np.mgrid[0:h, 0:b]
        r = np.sqrt((x - b / 2) ** 2 + (y - h / 2) ** 2) / (min(b, h) / 2)
        g = np.clip(1 - r, 0, 1) ** 2 * (0.6 + 0.4 * np.sin(np.arctan2(y - h / 2, x - b / 2) * 8))
        return Image.fromarray((np.stack([g * 255, g * 190, g * 90], -1) + 6).clip(0, 255).astype(np.uint8))
    y = np.linspace(0, 1, h)[:, None, None] * np.ones((1, b, 1))
    return Image.fromarray((np.concatenate([y * 120 + 30, y * 90 + 30, y * 160 + 40], -1)).astype(np.uint8))


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def antwort(self, daten, code=200):
        t = json.dumps(daten).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(t)))
        self.end_headers()
        self.wfile.write(t)

    def do_GET(self):
        if self.path == "/system_stats":
            return self.antwort({"system": {}})
        if self.path.startswith("/object_info/"):
            k = self.path.split("/")[-1]
            listen = {"UNETLoader": ("unet_name", ["z_image_turbo_bf16.safetensors"]), "CLIPLoader": ("clip_name", ["qwen_3_4b.safetensors"]),
                      "VAELoader": ("vae_name", ["ae.safetensors"])}
            if k in listen:
                return self.antwort({k: {"input": {"required": {listen[k][0]: [listen[k][1]]}}}})
            if k == "SeamlessLatentTiling" and KACHEL:
                return self.antwort({k: {"input": {"required": {"model": ["MODEL"], "padding": ["INT", {}], "tile_x": ["BOOLEAN", {}], "tile_y": ["BOOLEAN", {}]}}}})
            return self.antwort({})
        if self.path.startswith("/history/"):
            pid = self.path.split("/")[-1]
            return self.antwort({pid: {"status": {"status_str": "success"}}} if pid in fertig else {})
        self.antwort({}, 404)

    def do_POST(self):
        daten = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        g = daten["prompt"]
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(g) + "\n")
        if any(n["class_type"] == "SeamlessLatentTiling" for n in g.values()) and not KACHEL:
            return self.antwort({"error": "node SeamlessLatentTiling does not exist"}, 400)
        nahtlos = any(n["class_type"] == "SeamlessLatentTiling" for n in g.values())
        lat, sp, ks = g["6"]["inputs"], g["10"]["inputs"], g["7"]["inputs"]
        if nahtlos:
            assert ks["model"] == ["11", 0] and g["11"]["inputs"]["model"] == ["2", 0], "Kachel-Knoten falsch verdrahtet"
        pid = str(uuid.uuid4())
        zaehler[0] += 1
        ziel = os.path.join(COMFY, "output", sp["filename_prefix"].replace("/", os.sep) + "_%05d_.png" % 1)
        os.makedirs(os.path.dirname(ziel), exist_ok=True)
        bild(g["4"]["inputs"]["text"], lat["width"], lat["height"], ks["seed"], nahtlos).save(ziel)
        fertig[pid] = True
        self.antwort({"prompt_id": pid})


if __name__ == "__main__":
    print("Attrappe auf Port %d, Kachel-Knoten %s, Ausgabe nach %s" % (PORT, "da" if KACHEL else "fehlt", COMFY), flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
