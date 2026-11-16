#!/usr/bin/env python3
"""Schneidet die Higgsfield-Bögen (transparenter Hintergrund) in Spielbilder und schreibt art/manifest.json.
Aufruf: python3 -I tools/cut_art.py ROHORDNER   (erwartet K01.png, G01.png, P01.png, T01.png, X01.png ...)"""
import json, pathlib, sys
from PIL import Image

RAW = pathlib.Path(sys.argv[1]); ART = pathlib.Path(__file__).resolve().parent.parent / "art"
man_p = ART / "manifest.json"
man = json.loads(man_p.read_text()) if man_p.exists() else {"sprite": {}, "tex": {}, "prop": {}, "portrait": {}}

def bbox(im):
    a = im.getchannel("A").point(lambda v: 255 if v > 24 else 0); return a.getbbox()

def foot_x(cell):   # Mittelwert (Median) der deckenden Pixel im Bereich von Hüfte bis Knöchel: Waffen und Umhänge verschieben ihn kaum
    a = cell.getchannel("A"); w, h = a.size; px = a.load(); xs = []
    for y in range(int(h * 0.55), int(h * 0.95)):
        xs += [x for x in range(0, w, 2) if px[x, y] > 120]
    xs.sort(); return xs[len(xs) // 2] / w if xs else 0.5

def sheet(code, names, cols, rows, scale):
    im = Image.open(RAW / f"{code}.png").convert("RGBA"); W, H = im.size; cw, ch = W // cols, H // rows
    parts = []
    for i, n in enumerate(names):
        if not n: continue
        c = im.crop(((i % cols) * cw, (i // cols) * ch, (i % cols + 1) * cw, (i // cols + 1) * ch)); b = bbox(c)
        c = c.crop(b); c = c.resize((max(1, round(c.width * scale)), max(1, round(c.height * scale))), Image.LANCZOS); parts.append((n, c))
    out = Image.new("RGBA", (sum(p.width for _, p in parts) + 4 * len(parts), max(p.height for _, p in parts)), (0, 0, 0, 0))
    x, cells = 0, {}
    for n, p in parts:
        out.paste(p, (x, out.height - p.height)); cells[n] = [x, out.height - p.height, p.width, p.height, round(foot_x(p), 3)]; x += p.width + 4
    out.save(ART / f"{code}.webp", quality=88, method=6)
    return out, cells

for code in ["K01", "K02", "K03", "K04", "K05"]:   # Klassen: vorn, hinten, gehen, angreifen
    if (RAW / f"{code}.png").exists():
        _, cells = sheet(code, ["front", "back", "walk", "attack"], 2, 2, 0.42)
        man["sprite"][code] = {"src": f"art/{code}.webp", "tall": cells["front"][3], "cells": cells}
for code in ["G01", "G02", "G03", "G04", "G05", "G06", "B01", "B02", "B03"]:   # Gegner: vorn, hinten, angreifen, besiegt
    if (RAW / f"{code}.png").exists():
        _, cells = sheet(code, ["front", "back", "attack", "down"], 2, 2, 0.42)
        man["sprite"][code] = {"src": f"art/{code}.webp", "tall": cells["front"][3], "cells": cells}
PROPS = {"P01": ["rock0", "rock1", "needle0", "needle1", "rock2", "rock3", "rock4", "rock5"],
         "P02": [f"ruin{i}" for i in range(8)], "P03": [f"tomb{i}" for i in range(8)], "P04": [f"camp{i}" for i in range(8)], "P05": [f"star{i}" for i in range(8)]}
for code, names in PROPS.items():
    if (RAW / f"{code}.png").exists():
        _, cells = sheet(code, names, 4, 2, 0.5)
        med = sorted(c[2] for c in cells.values())[len(cells) // 2]
        for n, c in cells.items():   # rel: Breite im Verhältnis zum mittleren Teil des Bogens, so bleiben die Größenverhältnisse erhalten
            man["prop"][n] = {"src": f"art/{code}.webp", "box": c[:4], "rel": round(c[2] / med, 2), "foot": 0.86 if n.startswith("needle") or n in ("rock3",) else 0.92}
for code in ["T01", "T02", "T03", "T04", "T05"]:
    if (RAW / f"{code}.png").exists():
        Image.open(RAW / f"{code}.png").convert("RGB").resize((768, 768), Image.LANCZOS).save(ART / f"{code}.webp", quality=82, method=6); man["tex"][code] = f"art/{code}.webp"
if (RAW / "X01.png").exists():
    im = Image.open(RAW / "X01.png").convert("RGB"); im.resize((1600, round(1600 * im.height / im.width)), Image.LANCZOS).save(ART / "X01.webp", quality=78, method=6); man["title"] = "art/X01.webp"
man_p.write_text(json.dumps(man, ensure_ascii=False, indent=1))
print(json.dumps({k: (list(v) if isinstance(v, dict) else v) for k, v in man.items()}, ensure_ascii=False))
for p in sorted(ART.glob("*.webp")): print(p.name, p.stat().st_size // 1024, "KB")
