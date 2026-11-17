#!/usr/bin/env python3
# Bereitet die Higgsfield-Texturen fürs Spiel auf: lädt das Original (2048 px PNG), glättet die Kachelnaht,
# verkleinert auf 1024 px, speichert als JPG nach textures/ und erzeugt eine Normalenkarte (Relief im Fackellicht).
# Die Originale kommen nicht ins Repo.
#
#   python3 tools/texturen.py            alle Texturen, deren Adresse unten eingetragen ist
#   python3 tools/texturen.py t09_sand   nur eine
#
# Neue Textur (z. B. T09 Wüstensand): Dateinamen unten bei QUELLEN eintragen, Skript laufen lassen,
# Godot einmal öffnen (oder mit --import) – main.gd verwendet die Datei dann von selbst.
import os, sys, urllib.request, io
import numpy as np
from PIL import Image, ImageFilter

BASIS = "https://d8j0ntlcm91z4.cloudfront.net/user_3LJxksl6mkxq6rOcdzCctuGsHul/"
QUELLEN = {
	"w01_sandstein": "hf_20261115_211612_0104a296-1c14-45cf-b6b8-c4e0f2b4e626.png",
	"w02_granit":    "hf_20261116_003035_2c675696-8c43-4535-9511-bf9da91a5e0e.png",
	"t06_pflaster":  "hf_20261116_041040_d6dca7d0-df40-44c4-acfb-0b7f4289acb6.png",
	"t07_gruft":     "hf_20261116_052916_39a49fef-54af-4ec2-b1a9-783e8efaf672.png",
	"t09_sand":      "hf_20261116_080638_9e45fbfc-61a4-48fd-b21e-f10590c7a1ac.png",
	# Stunden 2 bis 5 (Bildauftrag 2, Paket D = zweite Fassung) und der Fels im Freiland (Paket C)
	"w03_lehm":         "hf_20261117_134824_58685d8b-d33a-44f2-8a3d-1989936454cf.png",
	"t10_feld":         "hf_20261117_145342_5c55362d-ca84-48e9-ab9b-c490103a5da6.png",
	"w04_grab":         "hf_20261117_155549_3c9c1916-b37f-4a35-9233-f3df77ef8dca.png",
	"t11_glas":         "hf_20261117_165859_603d67cb-74da-4966-9a25-5451a061df66.png",
	"w05_hoehle":       "hf_20261117_180148_8729340e-c9f4-42ee-8e16-628c19c47886.png",
	"t12_hoehlenboden": "hf_20261117_190543_ee03ab8b-0e6d-42e5-947c-520f2b369097.png",
	"f01_fels":         "hf_20261117_032346_a1dbdd0f-6ccd-472a-9c65-772436f66961.png",
}
GROESSE = 1024
NAHT = 6   # Pixel beiderseits der Naht, die überblendet werden (im 2048er Original)

ZIEL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures")


def naht_glätten(a: np.ndarray) -> np.ndarray:
	# Naht in die Bildmitte rollen, dort einen schmalen Streifen weich verwischen (Gewicht fällt nach außen ab),
	# zurückrollen. So verschwindet die harte Pixelkante, ohne dass das Bild sichtbar unscharf wird.
	n = a.shape[0]
	r = np.roll(np.roll(a, n // 2, 0), n // 2, 1).astype(np.float32)
	blur = np.asarray(Image.fromarray(r.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.5))).astype(np.float32)
	idx = np.arange(n)
	w = np.clip(1.0 - np.abs(idx - (n // 2 - 0.5)) / NAHT, 0, 1)
	wx = w[None, :, None]
	wy = w[:, None, None]
	wmax = np.maximum(wx, wy)
	r = r * (1 - wmax) + blur * wmax
	r = np.roll(np.roll(r, -(n // 2), 0), -(n // 2), 1)
	return np.clip(r, 0, 255).astype(np.uint8)


def kachelbar_verkleinern(a: np.ndarray, groesse: int) -> Image.Image:
	# ringsum mit dem gegenüberliegenden Rand auffüllen, verkleinern, wieder beschneiden: kein dunkler Rand durchs Filtern
	p = 32
	t = np.pad(a, ((p, p), (p, p), (0, 0)), mode="wrap")
	f = groesse / a.shape[0]
	im = Image.fromarray(t).resize((round(t.shape[1] * f), round(t.shape[0] * f)), Image.LANCZOS)
	q = round(p * f)
	return im.crop((q, q, q + groesse, q + groesse))


def normalenkarte(im: Image.Image, staerke: float = 2.2) -> Image.Image:
	# Höhe aus der Helligkeit geschätzt (Fugen dunkel = tief); kachelbar über np.roll
	h = np.asarray(im.convert("L").filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255.0
	dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
	dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
	nx = -dx * staerke * 8
	ny = dy * staerke * 8   # OpenGL-Konvention (Y nach oben), wie Godot sie erwartet
	nz = np.ones_like(h)
	l = np.sqrt(nx * nx + ny * ny + nz * nz)
	n = np.stack([nx / l, ny / l, nz / l], -1)
	return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))


def naht_mass(a: np.ndarray) -> str:
	g = a.astype(np.float32).mean(2)
	h = np.abs(g[:, 0] - g[:, -1]).mean() / np.abs(np.diff(g, axis=1)).mean()
	v = np.abs(g[0, :] - g[-1, :]).mean() / np.abs(np.diff(g, axis=0)).mean()
	return "links/rechts %.2f, oben/unten %.2f" % (h, v)


def main() -> None:
	Image.MAX_IMAGE_PIXELS = None
	wahl = sys.argv[1:] or list(QUELLEN)
	os.makedirs(ZIEL, exist_ok=True)
	for name in wahl:
		datei = QUELLEN.get(name, "")
		if not datei:
			print(f"{name}: keine Adresse eingetragen, übersprungen")
			continue
		with urllib.request.urlopen(BASIS + datei) as r:
			a = np.asarray(Image.open(io.BytesIO(r.read())).convert("RGB"))
		vorher = naht_mass(a)
		a = naht_glätten(a)
		im = kachelbar_verkleinern(a, GROESSE)
		nachher = naht_mass(np.asarray(im))
		im.save(os.path.join(ZIEL, name + ".jpg"), quality=88, optimize=True)
		normalenkarte(im).save(os.path.join(ZIEL, name + "_n.jpg"), quality=92, optimize=True)
		print(f"{name}: Naht vorher {vorher} · nachher {nachher}")


if __name__ == "__main__":
	main()
