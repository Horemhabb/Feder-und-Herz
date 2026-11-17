# Papyrus-Textur: gekreuzte Faserlagen (waagrecht und senkrecht), Flecken, ausgefranste dunklere Ränder.
import sys, numpy as np
from PIL import Image, ImageFilter
out, W, H, seed = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
rng = np.random.default_rng(seed)
def smooth(a, r):
    return np.asarray(Image.fromarray((a * 255).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), dtype=np.float32) / 255.0
def stretch(w, h, sx, sy):
    # Rauschen, entlang einer Achse gestreckt: Fasern
    n = rng.random((max(2, h // sy), max(2, w // sx))).astype(np.float32)
    return np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), dtype=np.float32) / 255.0
hor = stretch(W, H, 90, 2) * 0.6 + stretch(W, H, 40, 1) * 0.4      # waagrechte Fasern
ver = stretch(W, H, 2, 110) * 0.6 + stretch(W, H, 1, 50) * 0.4     # senkrechte Fasern (untere Lage)
blot = smooth(rng.random((H, W)).astype(np.float32), 38)
blot = (blot - blot.min()) / (blot.max() - blot.min())
grain = rng.random((H, W)).astype(np.float32)
v = 0.80 + (hor - 0.5) * 0.20 + (ver - 0.5) * 0.13 + (blot - 0.5) * 0.22 + (grain - 0.5) * 0.05
# dunkle Einzelfasern
fib = (stretch(W, H, 140, 1) > 0.93).astype(np.float32)
v -= smooth(fib, 0.6) * 0.10
# Ränder: dunkler, mit unregelmäßiger Kante
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
d = np.minimum(np.minimum(xx, W - 1 - xx), np.minimum(yy, H - 1 - yy))
wob = smooth(rng.random((H, W)).astype(np.float32), 3.5)
wob = (wob - wob.mean()) / (wob.std() + 1e-6)
edge = d + wob * 2.6
v -= np.clip((26.0 - edge) / 26.0, 0, 1) ** 1.6 * 0.38
alpha = np.clip((edge - 2.0) / 2.0, 0, 1)
v = v.clip(0, 1)
base = np.array([226, 204, 158], dtype=np.float32)   # heller Papyrus
dark = np.array([122, 88, 48], dtype=np.float32)     # nachgedunkelte Faser
rgb = dark[None, None, :] + (base - dark)[None, None, :] * v[:, :, None]
img = np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8)
Image.fromarray(img, "RGBA").save(out)
