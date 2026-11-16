#!/usr/bin/env python3
"""Schneidet dichte Bögen mit Magenta-Hintergrund (nano banana) in Spielbilder und ergänzt art/manifest.json.
Aufruf: python3 -I tools/cut_sheets.py ROHORDNER
  D01.png  16 Dungeon-Requisiten (4x4)            -> art/D01.webp, prop d0..d15
  H01.png  drei Klassen (4 Spalten x 3 Zeilen)     -> art/K02.webp, K03.webp, K04.webp
  E01.png  vier Gegner (4x4)                       -> art/G04, G05, G06, G03
  E02.png  drei Endgegner und der Skorpion (4x4)   -> art/B03, B02, B01, G07
  I01.png  36 Gegenstandssymbole (6x6)             -> art/icons.webp (gleich große Felder)
"""
import json, pathlib, sys
import numpy as np
from PIL import Image, ImageEnhance
from scipy import ndimage

RAW = pathlib.Path(sys.argv[1]); ART = pathlib.Path(__file__).resolve().parent.parent / "art"
man_p = ART / "manifest.json"; man = json.loads(man_p.read_text())

def keyed(path):
    """Magenta herausrechnen: viel Rot und Blau bei wenig Grün ist Hintergrund; Ränder werden vom Farbstich befreit."""
    im = np.asarray(Image.open(path).convert("RGB")).astype(np.float32); r, g, b = im[..., 0], im[..., 1], im[..., 2]
    key = np.minimum(r, b) - g; alpha = 1.0 - np.clip((key - 36.0) / 84.0, 0, 1)
    spill = np.clip(key, 0, None); r2 = np.clip(r - spill, 0, 255); b2 = np.clip(b - spill, 0, 255)
    return np.dstack([r2, g, b2, alpha * 255]).astype(np.uint8)

def cells(rgba, cols, rows, inset=14):
    """Je Rasterfeld die Figur: alle größeren zusammenhängenden Flächen, ohne Rasterlinien am Feldrand."""
    H, W = rgba.shape[:2]; out = []
    for i in range(cols * rows):
        x0, y0, x1, y1 = (i % cols) * W // cols + inset, (i // cols) * H // rows + inset, (i % cols + 1) * W // cols - inset, (i // cols + 1) * H // rows - inset
        c = rgba[y0:y1, x0:x1].copy(); m = c[..., 3] > 90; lab, n = ndimage.label(ndimage.binary_closing(m, iterations=3))
        if n == 0: out.append(None); continue
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1)); keep = [k + 1 for k in range(n) if sizes[k] > max(60, sizes.max() * 0.012)]
        own = ndimage.binary_dilation(np.isin(lab, keep), iterations=5); c[..., 3] = np.where(own, c[..., 3], 0)
        ys, xs = np.where(own & (c[..., 3] > 40)); out.append(Image.fromarray(c[ys.min():ys.max() + 1, xs.min():xs.max() + 1], "RGBA"))
    return out

def foot_x(cell):
    a = np.asarray(cell.getchannel("A")); h, w = a.shape; ys, xs = np.where(a[int(h * 0.55):int(h * 0.95)] > 120)
    return float(np.median(xs)) / w if len(xs) else 0.5

def atlas(code, parts):
    parts = [(n, p) for n, p in parts if p is not None]
    out = Image.new("RGBA", (sum(p.width for _, p in parts) + 4 * len(parts), max(p.height for _, p in parts)), (0, 0, 0, 0)); x, box = 0, {}
    for n, p in parts: out.paste(p, (x, out.height - p.height)); box[n] = [x, out.height - p.height, p.width, p.height, round(foot_x(p), 3)]; x += p.width + 4
    out.save(ART / f"{code}.webp", quality=86, method=6); return box

def scaled(p, k): return None if p is None else p.resize((max(1, round(p.width * k)), max(1, round(p.height * k))), Image.LANCZOS)

def figures(sheet, codes, names, cols, rows, k):
    if not (RAW / sheet).exists(): return
    cs = cells(keyed(RAW / sheet), cols, rows)
    for r, code in enumerate(codes):
        box = atlas(code, [(names[c], scaled(cs[r * cols + c], k)) for c in range(cols)])
        man["sprite"][code] = {"src": f"art/{code}.webp", "tall": box[names[0]][3], "cells": box}; print(code, {n: b[2:4] for n, b in box.items()})

figures("H01.png", ["K02", "K03", "K04"], ["front", "back", "walk", "attack"], 4, 3, 0.8)
figures("E01.png", ["G04", "G05", "G06", "G03"], ["front", "back", "attack", "down"], 4, 4, 0.8)
figures("E02.png", ["B03", "B02", "B01", "G07"], ["front", "back", "attack", "down"], 4, 4, 0.8)
if (RAW / "D01.png").exists():
    cs = cells(keyed(RAW / "D01.png"), 4, 4); box = atlas("D01", [(f"d{i}", scaled(c, 0.55)) for i, c in enumerate(cs)])
    med = sorted(b[2] for b in box.values())[len(box) // 2]
    for n, b in box.items(): man["prop"][n] = {"src": "art/D01.webp", "box": b[:4], "rel": round(b[2] / med, 2), "foot": 0.9}
    print("D01", {n: v["rel"] for n, v in man["prop"].items() if n.startswith("d")})
if (RAW / "I01.png").exists():   # Symbole: jedes mittig in ein Feld von 112 px, sechs je Zeile
    cs = cells(keyed(RAW / "I01.png"), 6, 6, inset=8); S = 112; out = Image.new("RGBA", (6 * S, 6 * S), (0, 0, 0, 0))
    for i, c in enumerate(cs):
        if c is None: continue
        k = (S - 10) / max(c.size); c = scaled(c, k); out.paste(c, ((i % 6) * S + (S - c.width) // 2, (i // 6) * S + (S - c.height) // 2))
    out.save(ART / "icons.webp", quality=88, method=6); man["icons"] = {"src": "art/icons.webp", "n": 6}; print("icons", sum(c is not None for c in cs))
if "G01" in man["sprite"] and "G02" not in man["sprite"]:   # Schuppenseherin: derselbe Körperbau, bleich
    im = Image.open(ART / "G01.webp").convert("RGBA"); a = im.getchannel("A"); rgb = ImageEnhance.Brightness(ImageEnhance.Color(im.convert("RGB")).enhance(0.25)).enhance(1.25)
    rgb = Image.blend(rgb, Image.new("RGB", rgb.size, (190, 205, 215)), 0.18); rgb.putalpha(a); rgb.save(ART / "G02.webp", quality=86, method=6)
    man["sprite"]["G02"] = {**man["sprite"]["G01"], "src": "art/G02.webp"}
man_p.write_text(json.dumps(man, ensure_ascii=False, indent=1))
for p in sorted(ART.glob("*.webp")): print(p.name, p.stat().st_size // 1024, "KB")
