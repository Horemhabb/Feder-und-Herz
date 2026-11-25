# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe ../figurenfabrik/LIZENZ.md)
"""Ersatznetze zum Prüfen der Gegnerfabrik, solange kein echtes Bild-zu-3D-Netz da ist.

Sie entstehen wie bei TripoSG und TRELLIS: eine Abstandsfunktion im Raum, daraus mit „Marching Cubes“ ein einziges,
dichtes, ungeordnetes Dreiecksnetz (über 100.000 Dreiecke), dazu eine Textur auf zerstückelten Texturkoordinaten.
Kein Skelett, keine Bewegung. Braucht zusätzlich scikit-image (pip install scikit-image).

  python ersatznetz.py schakal <ziel.glb>     Schakalwächter in A-Haltung (Zweibeiner, Schurz, Kragen, hohe Ohren)
  python ersatznetz.py schlange <ziel.glb>    Schlange in S-Form mit aufgerichtetem Hals und Haube (Apophis)
"""
import math
import os
import sys
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import bpy
import bmesh
import numpy as np
from PIL import Image
from skimage import measure
import aus_netz as an


# ---------------------------------------------------------------- Abstandsfunktionen
def kapsel(p, a, b, r0, r1=None):
    a, b = np.asarray(a, float), np.asarray(b, float)
    r1 = r0 if r1 is None else r1
    ab = b - a
    t = np.clip(((p - a) @ ab) / (ab @ ab), 0, 1)
    return np.linalg.norm(p - (a + t[..., None] * ab), axis=-1) - (r0 + (r1 - r0) * t)


def ellipsoid(p, c, r):
    q = (p - np.asarray(c, float)) / np.asarray(r, float)
    k0 = np.linalg.norm(q, axis=-1)
    return (k0 - 1.0) * min(r)


def weich(d1, d2, k):
    """weiche Vereinigung (smooth minimum)"""
    h = np.clip(0.5 + 0.5 * (d2 - d1) / k, 0, 1)
    return d2 * (1 - h) + d1 * h - k * h * (1 - h)


def netz_aus_feld(sdf, lo, hi, schritt):
    xs = [np.arange(lo[i], hi[i], schritt) for i in range(3)]
    G = np.stack(np.meshgrid(*xs, indexing="ij"), -1)
    D = sdf(G)
    v, f, _, _ = measure.marching_cubes(D, 0.0, spacing=(schritt,) * 3)
    v += np.asarray(lo)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new("KI_Netz")
    me.from_pydata(v.tolist(), [], f[:, ::-1].tolist())
    ob = bpy.data.objects.new("KI_Netz", me)
    bpy.context.scene.collection.objects.link(ob)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    an.saeubern(ob)
    return ob


def bemalen(ob, groesse, farbe_fn, pfad):
    """Textur malen wie ein KI-Netz sie mitbringt: Texturkoordinaten zerstückelt, Farbe je Ort auf der Oberfläche."""
    an.neue_uv(ob, rand=0.002)
    Pt, F = an.punkte(ob), an.dreiecke(ob)
    UV = an.uv_der_ecken(ob)
    uv_px = np.stack([UV[..., 0] * groesse, (1 - UV[..., 1]) * groesse], -1)
    ys, xs, fs, B = an.rastern(uv_px, groesse)
    P = (Pt[F[fs]] * B[..., None]).sum(1)
    rgb = np.zeros((groesse, groesse, 3), np.float32)
    belegt = np.zeros((groesse, groesse), bool)
    rgb[ys, xs] = farbe_fn(P)
    belegt[ys, xs] = True
    rgb = an.ausbluten(rgb, belegt, 4)
    Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).save(pfad)
    m = bpy.data.materials.new("haut")
    m.use_nodes = True
    nt = m.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(pfad)
    nt.links.new(tex.outputs["Color"], next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED').inputs["Base Color"])
    ob.data.materials.append(m)


def rauschen(P, k, keim=0):
    g = np.random.default_rng(keim)
    w = g.normal(size=(6, 3)) * k
    ph = g.random(6) * 6.28
    return sum(np.sin(P @ w[i] + ph[i]) for i in range(6)) / 6


# ---------------------------------------------------------------- Schakalwächter
def schakal(ziel):
    def sdf(p):
        d = ellipsoid(p, (0, 0, 1.2), (0.21, 0.15, 0.28))                       # Becken und Bauch
        d = weich(d, ellipsoid(p, (0, 0, 1.58), (0.3, 0.19, 0.3)), 0.12)        # Brust
        d = weich(d, kapsel(p, (0, 0.01, 1.8), (0, 0.0, 1.98), 0.08), 0.06)     # Hals
        d = weich(d, ellipsoid(p, (0, 0.0, 2.1), (0.12, 0.14, 0.13)), 0.05)     # Schädel
        d = weich(d, kapsel(p, (0, -0.06, 2.07), (0, -0.32, 2.02), 0.07, 0.035), 0.04)   # Schnauze
        for s in (1, -1):
            d = weich(d, kapsel(p, (s * 0.06, 0.03, 2.17), (s * 0.1, 0.04, 2.46), 0.05, 0.015), 0.03)   # Ohren
            sch, ell, hand = (s * 0.27, 0, 1.73), (s * 0.5, 0.02, 1.43), (s * 0.7, -0.02, 1.18)
            d = weich(d, kapsel(p, sch, ell, 0.085, 0.07), 0.06)
            d = weich(d, kapsel(p, ell, hand, 0.07, 0.055), 0.03)
            d = weich(d, ellipsoid(p, (s * 0.75, -0.03, 1.1), (0.05, 0.07, 0.09)), 0.03)
            hu, kn, fu = (s * 0.12, 0, 1.05), (s * 0.15, -0.02, 0.56), (s * 0.17, 0.02, 0.1)
            d = weich(d, kapsel(p, hu, kn, 0.11, 0.08), 0.05)
            d = weich(d, kapsel(p, kn, fu, 0.075, 0.055), 0.03)
            d = weich(d, kapsel(p, (s * 0.17, 0.03, 0.05), (s * 0.18, -0.18, 0.04), 0.06, 0.045), 0.04)
        # Schurz: ein kurzer Kegelstumpf, vorn etwas länger
        r = np.linalg.norm(p[..., :2] * np.array([1.0, 1.25]), axis=-1)
        z = p[..., 2]
        schurz = np.maximum(r - (0.2 + 0.18 * np.clip((1.12 - z) / 0.5, 0, 1)), np.maximum(z - 1.12, 0.66 - z))
        d = weich(d, schurz, 0.03)
        # Kragen
        kragen = np.maximum(np.abs(np.linalg.norm(p[..., :2] * np.array([1.0, 1.4]), axis=-1) - 0.2) - 0.06, np.abs(z - 1.8) - 0.04)
        return weich(d, kragen, 0.03)
    ob = netz_aus_feld(sdf, (-0.95, -0.5, -0.02), (0.95, 0.4, 2.55), 0.008)

    def farbe(P):
        x, y, z = P.T
        r = 0.09 + 0.03 * rauschen(P, 9)
        c = np.stack([r, r * 0.95, r * 1.15], 1)                                  # schwarze Haut mit Glanz
        schurz = (z > 0.64) & (z < 1.12) & (np.linalg.norm(P[:, :2], axis=1) > 0.17)
        f = 0.08 * np.sin(np.arctan2(y[schurz], x[schurz]) * 40)
        c[schurz] = np.stack([0.8 + f, 0.76 + f, 0.64 + f], 1)
        kragen = (z > 1.72) & (z < 1.9) & (np.abs(x) < 0.4)
        band = np.sin(z[kragen] * 140) > 0
        c[kragen] = np.where(band[:, None], [[0.88, 0.64, 0.18]], [[0.1, 0.25, 0.6]])
        auge = (z > 2.1) & (z < 2.15) & (np.abs(np.abs(x) - 0.055) < 0.022) & (y < -0.06)
        c[auge] = [1.0, 0.82, 0.25]
        return c
    bemalen(ob, 1024, farbe, os.path.splitext(ziel)[0] + "_tex.png")
    return ob


# ---------------------------------------------------------------- Schlange (Apophis)
def schlange(ziel):
    pfad = []
    for i in range(70):
        u = i / 69
        pfad.append((1.0 * math.sin(u * 2.4 * math.pi) * (0.35 + 0.65 * u), 2.4 - 3.0 * u, 0.15))
    for i in range(1, 25):
        u = i / 24
        pfad.append((pfad[-1][0], -0.6 - 0.35 * math.sin(u * math.pi / 2), 0.15 + 1.2 * math.sin(u * math.pi / 2)))
    pfad = np.array(pfad)
    n = len(pfad)
    radien = [0.03 + 0.12 * math.sin(min(1.0, i / n * 1.3) * math.pi / 2) for i in range(n)]
    kopf = pfad[-1]

    def sdf(p):
        d = np.full(p.shape[:-1], 1e9)
        for i in range(n - 1):
            d = np.minimum(d, kapsel(p, pfad[i], pfad[i + 1], radien[i], radien[i + 1]))
        haube = np.maximum(ellipsoid(p, kopf + np.array([0, 0.04, -0.32]), (0.32, 0.07, 0.34)), -(p[..., 2] - 0.65))
        d = weich(d, haube, 0.06)
        d = weich(d, ellipsoid(p, kopf + np.array([0, -0.12, 0.05]), (0.14, 0.24, 0.09)), 0.06)
        return d
    lo = pfad.min(0) - 0.45
    hi = pfad.max(0) + 0.45
    lo[2] = -0.02
    ob = netz_aus_feld(sdf, lo, hi, 0.012)

    def farbe(P):
        x, y, z = P.T
        schuppe = 0.5 + 0.5 * np.sin(x * 70) * np.sin(y * 70) * np.sin(z * 70)
        gold = np.stack([0.62 + 0.25 * schuppe, 0.44 + 0.18 * schuppe, 0.12 + 0.05 * schuppe], 1)
        dunkel = np.stack([0.14 + 0.05 * schuppe, 0.1 + 0.04 * schuppe, 0.08 + 0.03 * schuppe], 1)
        band = (np.sin((y + 0.3 * x + 0.4 * z) * 8) > 0.5)[:, None]
        c = np.where(band, dunkel, gold)
        c[z < 0.05] = [0.82, 0.74, 0.55]
        haube = (z > 0.7) & (y > kopf[1] - 0.02) & (np.abs(x - kopf[0]) > 0.1)
        c[haube] = c[haube] * 0.5 + np.array([0.04, 0.14, 0.32])
        auge = (z > kopf[2]) & (y < kopf[1] - 0.2) & (np.abs(np.abs(x - kopf[0]) - 0.08) < 0.035)
        c[auge] = [0.95, 0.22, 0.08]
        return c
    bemalen(ob, 1024, farbe, os.path.splitext(ziel)[0] + "_tex.png")
    return ob


if __name__ == "__main__":
    art, ziel = sys.argv[1], sys.argv[2]
    ob = {"schakal": schakal, "schlange": schlange}[art](ziel)
    bpy.ops.export_scene.gltf(filepath=ziel, export_format='GLB', export_image_format='JPEG', export_materials='EXPORT')
    print("Ersatznetz", art, len(ob.data.polygons), "Dreiecke ->", ziel, os.path.getsize(ziel) // 1024, "KB")
