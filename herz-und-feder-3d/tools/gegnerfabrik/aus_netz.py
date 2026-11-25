# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe ../figurenfabrik/LIZENZ.md)
"""Gegnerfabrik: aus einem fremden Netz einen spielbaren Gegner machen.

Das Netz kommt aus einem Bild-zu-3D-Verfahren (TripoSG, TRELLIS.2, Meshy, Tripo …): viele hunderttausend Dreiecke,
ungeordnet, ohne Skelett, oft ohne Textur. Dieses Skript macht daraus in einem Lauf eine Figur wie aus der Figurenfabrik:

  1. laden und säubern (alle Teile zu einem Netz, lose Krümel weg)
  2. ausrichten: oben +Z, vorn −Y, Füße auf dem Boden, Größe wie die übrigen Gegner
  3. vereinfachen auf eine feste Zahl Dreiecke (Standard 5.000)
  4. neue Texturkoordinaten und eine Tafel (Standard 512²): die Farben kommen
       a) aus der Textur des Netzes (wenn es eine hat), Punkt für Punkt vom feinen aufs grobe Netz übertragen, oder
       b) aus den gemalten Ansichten (vorn, hinten, Seite), aufs Netz projiziert, mit Verdeckungsprüfung („Figurenhaut“)
  5. Skelett und Bewegungen:
       zweibeiner  KayKit-Skelett der Fabrik, an die gemessenen Maße angepasst; die Haltung des Netzes (A- oder T-Haltung)
                   wird erkannt und in die Ruhehaltung des Skeletts zurückgerechnet. Alle Bewegungen der Skelettgegner gelten.
       kette       Schlange, Wurm, Aal: eine Knochenkette längs des Körpers (über die Wege auf der Oberfläche gemessen),
                   Bewegungen als Formeln (Schlängeln, Zustoßen, Aufrichten, Sterben) unter den Namen der Skelettgegner.
       teil        ein Stück (Kopf, Maske, Krone, Waffe) auf eine fertige Fabrikfigur setzen, fest an einem Knochen.
  6. als .glb schreiben, die Bewegungen heißen wie bei den übrigen Gegnern (foe.gd › ANIM).

Aufruf (Blender als Python-Modul: pip install bpy pillow numpy; oder blender -b -P aus_netz.py -- …):
  python aus_netz.py --netz roh.glb --ziel ../../models/chars/Mumie_KI.glb --art zweibeiner --vorne vorne.png
  python aus_netz.py --netz schlange.glb --ziel ../../models/chars/Apophis.glb --art kette --dreiecke 6000
  python aus_netz.py --netz maske.glb --ziel ../../models/chars/Krieger_Maske.glb --art teil --koerper ../../models/chars/Krieger.glb --knochen head
"""
import argparse
import heapq
import math
import os
import sys
import tempfile
import time

HIER = os.path.dirname(os.path.abspath(__file__))
FABRIK = os.path.join(HIER, "..", "figurenfabrik")
sys.path.insert(0, FABRIK)
import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree
from PIL import Image
import fabrik
sys.path.insert(0, HIER)
import bogen

# Bewegungen der Skelettgegner (wie hohler.py); Namen wie in foe.gd › ANIM
BEWEGUNGEN = ["Skeletons_Inactive_Floor_Pose", "Skeletons_Awaken_Floor", "Idle_Combat", "Walking_D_Skeletons", "Running_A", "1H_Melee_Attack_Chop",
              "2H_Melee_Attack_Chop", "Spellcast_Shoot", "Hit_A", "Death_C_Skeletons", "Skeleton_Inactive_Standing_Pose", "Skeletons_Awaken_Standing",
              "2H_Melee_Attack_Spin", "Spellcast_Summon", "Unarmed_Melee_Attack_Punch_A", "Idle"]
GEWICHTSKNOCHEN = ["hips", "spine", "chest", "head", "upperarm.l", "lowerarm.l", "hand.l", "upperarm.r", "lowerarm.r", "hand.r",
                   "upperleg.l", "lowerleg.l", "foot.l", "toes.l", "upperleg.r", "lowerleg.r", "foot.r", "toes.r"]
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
T0 = time.time()


def sag(*a):
    print("[%5.1f s]" % (time.time() - T0), *a, flush=True)


# ---------------------------------------------------------------- Netz laden und vorbereiten
def importiere(pfad):
    """Lädt .glb/.gltf/.obj/.ply/.stl, legt alle Netze zu einem zusammen (Lage eingerechnet), wirft den Rest weg.
    Gibt das Netzobjekt und die Bilder seiner Materialien zurück."""
    vorher = set(bpy.data.objects)
    endung = os.path.splitext(pfad)[1].lower()
    if endung in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=pfad)
    elif endung == ".obj":
        bpy.ops.wm.obj_import(filepath=pfad)
    elif endung == ".ply":
        bpy.ops.wm.ply_import(filepath=pfad)
    elif endung == ".stl":
        bpy.ops.wm.stl_import(filepath=pfad)
    else:
        raise SystemExit("Unbekanntes Format: " + endung)
    neu = [o for o in bpy.data.objects if o not in vorher]
    netze = [o for o in neu if o.type == 'MESH' and len(o.data.polygons)]
    if not netze:
        raise SystemExit("Im Netz %s ist keine Fläche." % pfad)
    bm = bmesh.new()
    mats = []
    for o in netze:
        me = o.data.copy()
        me.transform(o.matrix_world)
        # Materialnummern auf die gemeinsame Liste umschreiben
        umbau = []
        for m in me.materials:
            if m not in mats:
                mats.append(m)
            umbau.append(mats.index(m))
        if umbau:
            for p in me.polygons:
                p.material_index = umbau[p.material_index] if p.material_index < len(umbau) else 0
        if me.uv_layers:
            me.uv_layers.active.name = "UVMap"
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
    for o in neu:
        bpy.data.objects.remove(o, do_unlink=True)
    me = bpy.data.meshes.new("Hoch")
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    ob = bpy.data.objects.new("Hoch", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def bild_des_materials(m):
    """Erstes Bild, das in die Grundfarbe eines Materials fließt (oder irgendein Bild darin)."""
    if m is None or not m.use_nodes:
        return None
    bilder = [n for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
    for n in bilder:
        for l in n.outputs["Color"].links:
            if l.to_socket.name in ("Base Color", "Color"):
                return n.image
    return bilder[0].image if bilder else None


def saeubern(ob, anteil=0.02):
    """Punkte verschmelzen, Dreiecke bilden, lose Krümel (unter `anteil` der Punkte) entfernen."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.verts.ensure_lookup_table()
    gesehen = set()
    teile = []
    for v in bm.verts:
        if v.index in gesehen:
            continue
        stapel, teil = [v], []
        gesehen.add(v.index)
        while stapel:
            a = stapel.pop()
            teil.append(a)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in gesehen:
                    gesehen.add(b.index)
                    stapel.append(b)
        teile.append(teil)
    gross = max(len(t) for t in teile)
    weg = [v for t in teile if len(t) < anteil * gross for v in t]
    if weg:
        bmesh.ops.delete(bm, geom=weg, context='VERTS')
    bm.to_mesh(ob.data)
    bm.free()
    sag("gesäubert: %d Teile, %d verworfen (%s Punkte), %d Dreiecke" % (len(teile), sum(1 for t in teile if len(t) < anteil * gross), sorted(len(t) for t in teile if len(t) < anteil * gross)[-5:], len(ob.data.polygons)))


def punkte(ob):
    co = np.empty(len(ob.data.vertices) * 3, np.float64)
    ob.data.vertices.foreach_get("co", co)
    return co.reshape(-1, 3)


def setze_punkte(ob, P):
    ob.data.vertices.foreach_set("co", np.asarray(P, np.float64).ravel())
    ob.data.update()


def transformiere(obs, M):
    for ob in obs:
        ob.data.transform(M)
        ob.data.update()


def vereinfache(ob, ziel):
    """Kopie des Netzes mit höchstens `ziel` Dreiecken (Kantenkollaps), ohne Texturkoordinaten (die kommen neu)."""
    me = ob.data.copy()
    tief = bpy.data.objects.new("Tief", me)
    bpy.context.scene.collection.objects.link(tief)
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    n = len(me.polygons)
    if n > ziel:
        mod = tief.modifiers.new("weniger", 'DECIMATE')
        mod.ratio = ziel / n
        mod.use_collapse_triangulate = True
        dg = bpy.context.evaluated_depsgraph_get()
        neu = bpy.data.meshes.new_from_object(tief.evaluated_get(dg))
        tief.modifiers.clear()
        tief.data = neu
        bpy.data.meshes.remove(me)
    bm = bmesh.new()
    bm.from_mesh(tief.data)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(tief.data)
    bm.free()
    for p in tief.data.polygons:
        p.use_smooth = True
    sag("vereinfacht: %d → %d Dreiecke" % (n, len(tief.data.polygons)))
    return tief


def neue_uv(ob, rand=0.006):
    """Texturkoordinaten neu: Inseln nach Winkel (Smart UV Project), dicht gepackt."""
    for o in bpy.context.scene.objects:
        if o is not None:
            o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    ob.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=rand, area_weight=0.6, scale_to_bounds=True)
    try:
        bpy.ops.uv.pack_islands(rotate=True, margin=rand)      # dichter packen: lange Inseln (Schwanz, Arme) drehen
    except Exception as e:
        sag("Inseln nicht neu gepackt:", e)
    bpy.ops.object.mode_set(mode='OBJECT')


# ---------------------------------------------------------------- Ausrichten
def scheiben(P, z, dicke, luecke):
    """Punkte einer waagrechten Scheibe, entlang x in zusammenhängende Gruppen geteilt: [(x0, x1, Punkte)]."""
    S = P[np.abs(P[:, 2] - z) < dicke]
    if len(S) == 0:
        return []
    S = S[np.argsort(S[:, 0])]
    gruppen, anfang = [], 0
    for i in range(1, len(S) + 1):
        if i == len(S) or S[i, 0] - S[i - 1, 0] > luecke:
            gruppen.append((S[anfang, 0], S[i - 1, 0], S[anfang:i]))
            anfang = i
    return gruppen


def ausrichten_zweibeiner(hoch, hoehe, drehen):
    """Dreht die Figur so, dass die Schulterlinie auf x liegt und die Zehen nach −Y zeigen, stellt sie auf den Boden
    und bringt sie auf `hoehe` Meter."""
    P = punkte(hoch)
    z0, z1 = P[:, 2].min(), P[:, 2].max()
    H = z1 - z0
    if drehen is None:
        B = P[(P[:, 2] > z0 + 0.62 * H) & (P[:, 2] < z0 + 0.8 * H)][:, :2]
        B = B - B.mean(0)
        w, v = np.linalg.eigh(np.cov(B.T))
        quer = v[:, np.argmax(w)]
        winkel = -math.atan2(quer[1], quer[0])
        R = Matrix.Rotation(winkel, 4, 'Z')
        Q = np.array(R.to_3x3()) @ P.T
        Q = Q.T
        # Zehen zeigen nach vorn: die tiefsten Punkte liegen weiter vorn als die Schienbeine
        fuss = Q[Q[:, 2] < z0 + 0.04 * H]
        schien = Q[(Q[:, 2] > z0 + 0.10 * H) & (Q[:, 2] < z0 + 0.22 * H)]
        if len(fuss) and len(schien) and fuss[:, 1].mean() > schien[:, 1].mean():
            winkel += math.pi
        sag("ausgerichtet: Drehung %.0f° (Schulterlinie, Zehen vorn)" % (round(math.degrees(winkel)) % 360))
    else:
        winkel = math.radians(drehen)
    M = Matrix.Rotation(winkel, 4, 'Z')
    transformiere([hoch], M)
    P = punkte(hoch)
    unten = P[P[:, 2] < z0 + 0.5 * H]
    mitte = Vector((unten[:, 0].mean() if len(unten) else 0, unten[:, 1].mean() if len(unten) else 0, z0))
    S = Matrix.Scale(hoehe / H, 4) @ Matrix.Translation(-mitte)
    transformiere([hoch], S)
    return S @ M


def ausrichten_allgemein(hoch, hoehe, drehen):
    """Nur auf den Boden stellen, mittig setzen, auf Höhe bringen (die Länge regelt `hoehe` bei der Kette nicht)."""
    P = punkte(hoch)
    z0 = P[:, 2].min()
    mitte = Vector((P[:, 0].mean(), P[:, 1].mean(), z0))
    M = Matrix.Rotation(math.radians(drehen or 0.0), 4, 'Z') @ Matrix.Translation(-mitte)
    transformiere([hoch], M)
    if hoehe:
        P = punkte(hoch)
        groesse = max(np.ptp(P[:, 0]), np.ptp(P[:, 1]), np.ptp(P[:, 2]))
        transformiere([hoch], Matrix.Scale(hoehe / groesse, 4))


# ---------------------------------------------------------------- Texturtafel
def dreiecke(ob):
    me = ob.data
    F = np.empty(len(me.polygons) * 3, np.int64)
    me.polygons.foreach_get("vertices", F)
    return F.reshape(-1, 3)


def uv_der_ecken(ob):
    me = ob.data
    uv = np.empty(len(me.loops) * 2, np.float64)
    me.uv_layers.active.data.foreach_get("uv", uv)
    return uv.reshape(-1, 3, 2)


def normalen(ob):
    me = ob.data
    n = np.empty(len(me.vertices) * 3, np.float64)
    me.vertices.foreach_get("normal", n)
    return n.reshape(-1, 3)


def rastern(uv_px, groesse):
    """Alle Bildpunkte der Tafel, die ein Dreieck bedeckt: (y, x, Dreieck, Baryzentrische Gewichte)."""
    ys, xs, fs, bs = [], [], [], []
    for f, t in enumerate(uv_px):
        x0, y0 = np.floor(t.min(0)).astype(int)
        x1, y1 = np.ceil(t.max(0)).astype(int)
        x0, y0 = max(x0 - 1, 0), max(y0 - 1, 0)
        x1, y1 = min(x1 + 1, groesse - 1), min(y1 + 1, groesse - 1)
        if x1 < x0 or y1 < y0:
            continue
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        px, py = gx.ravel() + 0.5, gy.ravel() + 0.5
        (ax, ay), (bx, by), (cx, cy) = t
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-12:
            continue
        l0 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / d
        l1 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / d
        l2 = 1 - l0 - l1
        tol = -0.02
        innen = (l0 >= tol) & (l1 >= tol) & (l2 >= tol)
        if not innen.any():
            continue
        ys.append(gy.ravel()[innen])
        xs.append(gx.ravel()[innen])
        fs.append(np.full(innen.sum(), f))
        bs.append(np.clip(np.stack([l0, l1, l2], 1)[innen], 0, 1))
    B = np.concatenate(bs)
    B /= B.sum(1, keepdims=True)
    return np.concatenate(ys), np.concatenate(xs), np.concatenate(fs), B


def ausbluten(rgb, belegt, schritte=12):
    """Leere Bildpunkte am Rand der Inseln mit den Nachbarfarben füllen, damit beim Verkleinern keine Nähte leuchten."""
    rgb = rgb.copy()
    belegt = belegt.copy()
    for _ in range(schritte):
        summe = np.zeros_like(rgb)
        anzahl = np.zeros(belegt.shape, np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                m = np.roll(np.roll(belegt, dy, 0), dx, 1)
                summe += np.roll(np.roll(rgb, dy, 0), dx, 1) * m[..., None]
                anzahl += m
        neu = (~belegt) & (anzahl > 0)
        rgb[neu] = summe[neu] / anzahl[neu][:, None]
        belegt |= neu
    rest = ~belegt
    if rest.any():
        rgb[rest] = rgb[belegt].mean(0)
    return rgb


def bild_als_feld(img):
    """Blender-Bild als Feld (H, W, 4) in 0..1, oben = Zeile 0."""
    w, h = img.size
    px = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(px)
    return px.reshape(h, w, 4)[::-1]


def abtasten(feld, u, v):
    """Bilinear in einem Feld abtasten; u, v in 0..1, v = 0 unten (Blender-Texturkoordinaten)."""
    h, w = feld.shape[:2]
    x = np.clip(u % 1.0 * w - 0.5, 0, w - 1.001)
    y = np.clip((1 - v % 1.0) * h - 0.5, 0, h - 1.001)
    x0, y0 = x.astype(int), y.astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    a = feld[y0, x0] * (1 - fx) + feld[y0, x0 + 1] * fx
    b = feld[y0 + 1, x0] * (1 - fx) + feld[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def farbe_aus_textur(hoch, Pt):
    """Farben vom feinen, texturierten Netz holen: nächster Punkt auf dem feinen Netz → dessen Texturkoordinate → Bild."""
    me = hoch.data
    Ph = punkte(hoch)
    Fh = dreiecke(hoch)
    UVh = uv_der_ecken(hoch)
    mat_idx = np.empty(len(me.polygons), np.int64)
    me.polygons.foreach_get("material_index", mat_idx)
    felder = [bild_als_feld(b) if b else None for b in (bild_des_materials(m) for m in me.materials)]
    baum = BVHTree.FromPolygons([tuple(p) for p in Ph], [tuple(f) for f in Fh])
    n = len(Pt)
    idx = np.zeros(n, np.int64)
    ort = np.zeros((n, 3))
    for i in range(n):
        co, _, fi, _ = baum.find_nearest(Vector(Pt[i]))
        if fi is None:
            continue
        idx[i] = fi
        ort[i] = co
    # baryzentrisch im getroffenen Dreieck
    A, B_, C = Ph[Fh[idx, 0]], Ph[Fh[idx, 1]], Ph[Fh[idx, 2]]
    v0, v1, v2 = B_ - A, C - A, ort - A
    d00, d01, d11 = (v0 * v0).sum(1), (v0 * v1).sum(1), (v1 * v1).sum(1)
    d20, d21 = (v2 * v0).sum(1), (v2 * v1).sum(1)
    den = np.maximum(d00 * d11 - d01 * d01, 1e-20)
    b1 = (d11 * d20 - d01 * d21) / den
    b2 = (d00 * d21 - d01 * d20) / den
    b0 = 1 - b1 - b2
    uv = UVh[idx, 0] * b0[:, None] + UVh[idx, 1] * b1[:, None] + UVh[idx, 2] * b2[:, None]
    farbe = np.full((n, 3), 0.5, np.float32)
    for k, feld in enumerate(felder):
        m = mat_idx[idx] == k
        if feld is not None and m.any():
            farbe[m] = abtasten(feld, uv[m, 0], uv[m, 1])[:, :3]
    return farbe


# --- Figurenhaut: gemalte Ansichten aufs Netz projizieren
class Ansicht:
    """Eine gemalte Ansicht mit Freistellmaske. blick: Richtung, in die die Kamera schaut; rechts: Bildrechts in Weltachsen."""

    def __init__(s, pfad, blick, rechts):
        im = Image.open(pfad)
        if im.mode != "RGBA":
            im = bogen.freistellen(im)
        a = np.asarray(im).astype(np.float32) / 255.0
        s.rgb, s.alpha = a[..., :3], a[..., 3]
        ys, xs = np.nonzero(s.alpha > 0.5)
        s.box = (xs.min(), ys.min(), xs.max(), ys.max())
        s.blick, s.rechts = np.array(blick, float), np.array(rechts, float)
        s.oben = np.array([0.0, 0.0, 1.0])
        # Farbe je Bildzeile (Mittelwert der Figur): Ersatz für Stellen, die keine Ansicht zeigt
        s.zeile = np.zeros((s.rgb.shape[0], 3), np.float32)
        for y in range(s.rgb.shape[0]):
            m = s.alpha[y] > 0.5
            if m.sum() > 3:
                s.zeile[y] = np.median(s.rgb[y][m], 0)
        gueltig = s.zeile.sum(1) > 0
        for y in range(len(s.zeile)):
            if not gueltig[y]:
                j = np.argmin(np.abs(np.nonzero(gueltig)[0] - y))
                s.zeile[y] = s.zeile[np.nonzero(gueltig)[0][j]]
        s.drehung = 0.0
        s.folgt = None        # Rückansicht vom selben Bogen: dreht sich mit der Vorderansicht
        s.suche = (-75, 76, 6)

    def achsen(s):
        R = np.array(Matrix.Rotation(s.folgt.drehung if s.folgt else s.drehung, 3, 'Z'))
        return R @ s.blick, R @ s.rechts

    def abbilden(s, P, rahmen):
        """Weltpunkte → Bildpunkte (x, y) und Tiefe; rahmen: (u0, u1, z0, z1) der Figur in dieser Ansicht."""
        blick, rechts = s.achsen()
        u, z, t = P @ rechts, P[:, 2], P @ blick
        x0, y0, x1, y1 = s.box
        k = (y1 - y0) / (rahmen[3] - rahmen[2])          # gleicher Maßstab in beiden Richtungen (Höhe gibt ihn vor)
        x = 0.5 * (x0 + x1) + (u - 0.5 * (rahmen[0] + rahmen[1])) * k
        y = y0 + (rahmen[3] - z) * k
        return x, y, t

    def rahmen(s, P):
        _, rechts = s.achsen()
        u = P @ rechts
        return (u.min(), u.max(), P[:, 2].min(), P[:, 2].max())


def tiefenbild(Pt, F, ansicht, rahmen, groesse):
    """Tiefe des groben Netzes aus Sicht der Ansicht (für die Verdeckung): je Bildpunkt die nächste Fläche."""
    h, w = ansicht.alpha.shape
    k = groesse / max(h, w)
    x, y, t = ansicht.abbilden(Pt, rahmen)
    x, y = x * k, y * k
    H, W = int(h * k) + 1, int(w * k) + 1
    tiefe = np.full((H, W), np.inf)
    for f in F:
        xs, ys, ts = x[f], y[f], t[f]
        x0, x1 = max(int(xs.min()), 0), min(int(xs.max()) + 1, W - 1)
        y0, y1 = max(int(ys.min()), 0), min(int(ys.max()) + 1, H - 1)
        if x1 < x0 or y1 < y0:
            continue
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        px, py = gx + 0.5, gy + 0.5
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-9:
            continue
        l0 = ((ys[1] - ys[2]) * (px - xs[2]) + (xs[2] - xs[1]) * (py - ys[2])) / d
        l1 = ((ys[2] - ys[0]) * (px - xs[2]) + (xs[0] - xs[2]) * (py - ys[2])) / d
        l2 = 1 - l0 - l1
        m = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
        if not m.any():
            continue
        tt = l0 * ts[0] + l1 * ts[1] + l2 * ts[2]
        blk = tiefe[y0:y1 + 1, x0:x1 + 1]
        np.minimum(blk, np.where(m, tt, np.inf), out=blk)
    return tiefe, k


def drehung_finden(ansicht, Pt, F):
    """Die gemalte Ansicht ist oft schräg (3/4). Suche die Drehung, bei der der Umriss des Netzes am besten passt:
    erst grob, dann um den besten Wert in Gradschritten."""
    G = 256

    def deckung(grad):
        ansicht.drehung = math.radians(grad)
        tiefe, k = tiefenbild(Pt, F, ansicht, ansicht.rahmen(Pt), G)
        maske = np.isfinite(tiefe)
        ziel = np.asarray(Image.fromarray((ansicht.alpha * 255).astype(np.uint8)).resize((maske.shape[1], maske.shape[0]))) > 127
        iou = (maske & ziel).sum() / max(1, (maske | ziel).sum())
        # bei fast gleicher Deckung die kleinere Drehung (von vorn sind ±10° kaum zu unterscheiden)
        return iou - 0.001 * abs(((grad - ansicht.suche[0] if ansicht.suche[1] - ansicht.suche[0] >= 360 else grad) + 180) % 360 - 180)
    werte = {g: deckung(g) for g in range(*ansicht.suche)}
    if os.environ.get("GF_DEBUG"):
        sag("Deckung je Winkel:", {g: round(v, 3) for g, v in werte.items()})
    grob = max(werte, key=werte.get)
    for g in range(grob - ansicht.suche[2] + 1, grob + ansicht.suche[2]):
        if g not in werte:
            werte[g] = deckung(g)
    beste = max(werte, key=werte.get)
    ansicht.drehung = math.radians(beste)
    sag("Ansicht passt bei %d° (Deckung des Umrisses %.0f %%)" % (beste % 360, werte[beste] * 100))
    return werte[beste]


def farbe_aus_ansichten(ansichten, Pt_netz, F, P, N):
    """Jeder Tafelpunkt nimmt Farbe aus den Ansichten, die ihn sehen (Gewicht: wie frontal er in die Kamera schaut).
    Stellen, die keine Ansicht sieht, bekommen die mittlere Farbe ihrer Höhe."""
    summe = np.zeros((len(P), 3))
    gewicht = np.zeros(len(P))
    ersatz = np.zeros((len(P), 3))
    for a in ansichten:
        r = a.rahmen(Pt_netz)
        tiefe, k = tiefenbild(Pt_netz, F, a, r, 384)
        x, y, t = a.abbilden(P, r)
        blick, _ = a.achsen()
        sicht = np.clip(-(N @ blick), 0, 1) ** 1.5
        xi = np.clip((x * k).astype(int), 0, tiefe.shape[1] - 1)
        yi = np.clip((y * k).astype(int), 0, tiefe.shape[0] - 1)
        frei = t <= tiefe[yi, xi] + 0.025 * (r[3] - r[2])
        g = sicht * frei
        hh, ww = a.alpha.shape
        xs, ys = np.clip(x, 0, ww - 1.001), np.clip(y, 0, hh - 1.001)
        feld = np.dstack([a.rgb, a.alpha])
        c = abtasten(feld, xs / ww, 1 - ys / hh)
        g = g * np.clip(c[:, 3] * 1.5 - 0.3, 0, 1)        # außerhalb der Freistellung nicht nehmen
        summe += c[:, :3] * g[:, None]
        gewicht += g
        ersatz += a.zeile[np.clip(ys.astype(int), 0, hh - 1)]
    ersatz /= len(ansichten)
    rest = np.clip(0.35 - gewicht, 0, 0.35) / 0.35
    farbe = (summe + ersatz * rest[:, None] * 0.35) / (gewicht + rest * 0.35 + 1e-9)[:, None]
    return farbe.astype(np.float32)


def tafel_backen(tief, hoch, ansichten, groesse, pfad):
    """Die Tafel des groben Netzes füllen und als PNG schreiben."""
    neue_uv(tief)
    Pt, F, Nt = punkte(tief), dreiecke(tief), normalen(tief)
    UV = uv_der_ecken(tief)
    uv_px = np.stack([UV[..., 0] * groesse, (1 - UV[..., 1]) * groesse], -1)
    ys, xs, fs, B = rastern(uv_px, groesse)
    P = (Pt[F[fs]] * B[..., None]).sum(1)
    N = (Nt[F[fs]] * B[..., None]).sum(1)
    N /= np.linalg.norm(N, axis=1, keepdims=True) + 1e-12
    sag("Tafel %d²: %d Bildpunkte belegt (%.0f %%)" % (groesse, len(P), 100 * len(P) / groesse ** 2))
    if ansichten:
        for a in ansichten:
            if a.folgt is None:
                drehung_finden(a, Pt, F)
        farbe = farbe_aus_ansichten(ansichten, Pt, F, P, N)
    elif hoch is not None and hoch.data.uv_layers and any(bild_des_materials(m) for m in hoch.data.materials):
        farbe = farbe_aus_textur(hoch, P)
    else:
        sag("keine Textur und keine Ansicht: graue Tafel")
        farbe = np.full((len(P), 3), 0.55, np.float32)
    rgb = np.zeros((groesse, groesse, 3), np.float32)
    belegt = np.zeros((groesse, groesse), bool)
    rgb[ys, xs] = farbe
    belegt[ys, xs] = True
    rgb = ausbluten(rgb, belegt)
    Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).save(pfad)
    sag("Tafel geschrieben:", pfad)
    return pfad


# ---------------------------------------------------------------- Zweibeiner: Maße messen, Skelett anpassen, binden
def vermessen(P):
    """Gelenke aus der Form schätzen (Figur steht, vorn −Y, Füße bei z = 0). Ergebnis in Metern."""
    H = P[:, 2].max()
    luecke = 0.02 * H

    def mitte_gruppe(z):
        g = scheiben(P, z, 0.012 * H, luecke)
        return min(g, key=lambda q: abs(0.5 * (q[0] + q[1]))) if g else None

    # Schritt: unterste Höhe, in der eine Gruppe über x = 0 reicht und links wie rechts nichts Eigenes mehr steht
    schritt = None
    for z in np.arange(0.12, 0.6, 0.01) * H:
        g = scheiben(P, z, 0.01 * H, luecke)
        if any(q[0] < -0.01 * H and q[1] > 0.01 * H for q in g):
            schritt = z
            break
    if schritt is None or schritt < 0.36 * H or schritt > 0.55 * H:
        sag("Schritt nicht klar (gemessen: %s), nehme 0,46 der Höhe" % (None if schritt is None else "%.2f H" % (schritt / H)))
        schritt = 0.46 * H
    # Hals: schmalste Stelle der Mittelgruppe zwischen 0,70 und 0,87 der Höhe
    hals, breite = 0.8 * H, 1e9
    for z in np.arange(0.70, 0.87, 0.005) * H:
        q = mitte_gruppe(z)
        if q is not None and q[1] - q[0] < breite:
            hals, breite = z, q[1] - q[0]
    brust = mitte_gruppe(hals - 0.12 * H)
    schulter_x = max(0.07 * H, 0.42 * (brust[1] - brust[0]) if brust is not None else 0.1 * H)
    schulter_z = hals - 0.045 * H
    rumpf_y = np.median(P[np.abs(P[:, 2] - (schritt + hals) / 2) < 0.03 * H][:, 1])
    hals_y = np.median(P[np.abs(P[:, 2] - hals) < 0.02 * H][:, 1])
    J = {"H": H, "schritt": schritt, "hals": hals, "rumpf_y": rumpf_y, "hals_y": hals_y}
    for s, sg in ((".l", 1), (".r", -1)):
        S = np.array([sg * schulter_x, hals_y, schulter_z])
        # Hand: in A- und T-Haltung der Punkt, der am weitesten zur Seite reicht (oberhalb des Schritts)
        seite = P[(sg * P[:, 0] > schulter_x) & (P[:, 2] > schritt)]
        if len(seite) == 0:
            spitze = S + np.array([sg * 0.36 * H, 0, -0.30 * H])
        else:
            spitze = seite[np.argmax(sg * seite[:, 0])]
        L = np.linalg.norm(spitze - S)
        richtung = (spitze - S) / max(L, 1e-6)
        if L < 0.25 * H or L > 0.55 * H:          # Waffe in der Hand oder Arm am Körper: Maß nach Proportion
            L = min(max(L, 0.25 * H), 0.42 * H)
        J["schulter" + s] = S
        J["arm" + s] = (richtung, L)
        # Bein: Mitte der Beingruppe auf drei Höhen
        bein = []
        for z in (schritt - 0.03 * H, 0.5 * (schritt + 0.05 * H), 0.06 * H):
            # nur Gruppen nahe der Mitte (die Hände hängen in A-Haltung auf Hüfthöhe weit außen)
            g = [q for q in scheiben(P, z, 0.012 * H, luecke) if 0.01 * H < sg * 0.5 * (q[0] + q[1]) < 0.2 * H]
            if g:
                q = min(g, key=lambda q: abs(0.5 * (q[0] + q[1]) - sg * 0.08 * H))
                bein.append(np.array([0.5 * (q[0] + q[1]), np.median(q[2][:, 1]), z]))
            else:
                bein.append(np.array([sg * 0.09 * H, rumpf_y, z]))
        J["bein" + s] = bein
    return J


def plan_aus_massen(J):
    """Bauplan für fabrik.umbauen (Knochenköpfe und Längen) aus den gemessenen Gelenken."""
    H = J["H"]
    huefte = J["schritt"] + 0.02 * H
    rumpf = J["hals"] - huefte
    plan = {
        "root": {"head": (0, 0, 0)},
        "hips": {"head": (0, J["rumpf_y"], huefte), "len": 0.22 * rumpf},
        "spine": {"an": True, "len": 0.43 * rumpf},
        "chest": {"an": True, "len": 0.35 * rumpf},
        "head": {"head": (0, J["hals_y"], J["hals"]), "len": 0.9 * (H - J["hals"])},
    }
    S = J["schulter.l"]
    _, L = J["arm.l"]
    plan["upperarm.l"] = {"head": tuple(S), "len": 0.42 * L}
    plan["lowerarm.l"] = {"an": True, "len": 0.37 * L}
    plan["wrist.l"] = {"an": True, "len": 0.06 * L}
    plan["hand.l"] = {"an": True, "len": 0.15 * L}
    plan["handslot.l"] = {"rel": (0.08 * L, 0, -0.04 * L)}
    h, k, a = J["bein.l"]
    hj = np.array([h[0], h[1], J["schritt"] + 0.03 * H])
    plan["upperleg.l"] = {"head": tuple(hj), "len": np.linalg.norm(k - hj)}
    plan["lowerleg.l"] = {"an": True, "len": np.linalg.norm(a - k)}
    plan["foot.l"] = {"an": True, "len": 0.055 * H}
    plan["toes.l"] = {"an": True, "len": 0.06 * H}
    return plan


def haltung_einnehmen(arm, J):
    """Skelett in die Haltung des Netzes bringen: Arme in die gemessene Richtung, Beine zu den gemessenen Knien und
    Knöcheln. Es ist nur eine Pose; die Ruhehaltung des Skeletts bleibt die der Bewegungen (T-Haltung)."""
    vl = bpy.context.view_layer

    def richte(name, ziel):
        pb = arm.pose.bones[name]
        vl.update()
        R = pb.matrix.to_3x3()
        jetzt = (R @ Y).normalized()
        R = jetzt.rotation_difference(Vector(ziel).normalized()).to_matrix() @ R
        M = R.to_4x4()
        M.translation = pb.matrix.translation
        pb.matrix = M
        vl.update()
    for s in (".l", ".r"):
        d, _ = J["arm" + s]
        richte("upperarm" + s, d)
        for n in ("lowerarm", "wrist", "hand"):
            richte(n + s, d)
        h, k, a = J["bein" + s]
        kopf = arm.pose.bones["upperleg" + s].head
        richte("upperleg" + s, Vector(k) - kopf)
        knie = arm.pose.bones["lowerleg" + s].head
        richte("lowerleg" + s, Vector(a) - knie + Vector((0, 0, -0.04 * J["H"])))


def nachbarn(ob):
    me = ob.data
    E = np.empty(len(me.edges) * 2, np.int64)
    me.edges.foreach_get("vertices", E)
    return E.reshape(-1, 2)


def glaetten(W, E, schritte, n):
    """Gewichte über die Kanten des Netzes glätten: fließt nur über die Oberfläche, nie durch die Luft (Arm ↛ Rumpf)."""
    grad = np.bincount(E.ravel(), minlength=n).astype(np.float64)[:, None] + 1e-9
    for _ in range(schritte):
        S = np.zeros_like(W)
        np.add.at(S, E[:, 0], W[E[:, 1]])
        np.add.at(S, E[:, 1], W[E[:, 0]])
        W = 0.5 * W + 0.5 * S / grad
    return W


def abstand_strecke(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def binden_zweibeiner(ob, arm, J, glatt=6):
    """Gewichte zum Skelett in der Haltung des Netzes berechnen, dann das Netz in die Ruhehaltung zurückrechnen
    (umgekehrtes Skinning). Danach passt das Netz zum Skelett wie eine Fabrikfigur."""
    vl = bpy.context.view_layer
    vl.update()
    P = punkte(ob)
    n = len(P)
    mw = arm.matrix_world
    seg = []
    for name in GEWICHTSKNOCHEN:
        pb = arm.pose.bones[name]
        a, b = np.array(mw @ pb.head), np.array(mw @ pb.tail)
        if name.startswith("hand"):
            b = a + (b - a) * 1.8      # die Hand reicht über die Knochenspitze hinaus (Finger, Klauen)
        seg.append((a, b))
    D = np.stack([abstand_strecke(P, a, b) for a, b in seg], 1)
    H = J["H"]
    for i, name in enumerate(GEWICHTSKNOCHEN):
        if name.endswith(".l"):
            D[P[:, 0] < -0.015 * H, i] = np.inf
        elif name.endswith(".r"):
            D[P[:, 0] > 0.015 * H, i] = np.inf
        if name == "head":
            D[P[:, 2] < J["hals"] - 0.05 * H, i] = np.inf
    dmin = D.min(1, keepdims=True)
    W = np.where(D <= dmin * 1.25 + 0.01 * H, 1.0 / (D + 0.005 * H) ** 4, 0.0)
    W /= W.sum(1, keepdims=True)
    # Rock und Schurz: was weit vom Oberschenkel absteht, hängt am Becken (sonst reißt der Stoff bei jedem Schritt auf)
    hi = GEWICHTSKNOCHEN.index("hips")
    knie = min(J["bein.l"][1][2], J["bein.r"][1][2])
    for s in (".l", ".r"):
        k = GEWICHTSKNOCHEN.index("upperleg" + s)
        stoff = np.clip((D[:, k] - 0.05 * H) / (0.04 * H), 0, 1) * 0.92
        stoff[np.isinf(D[:, k])] = 0
        for kn in ("upperleg" + s, "lowerleg" + s):
            k2 = GEWICHTSKNOCHEN.index(kn)
            f = stoff if kn.startswith("upper") else stoff * (P[:, 2] > knie - 0.02 * H)
            W[:, hi] += W[:, k2] * f
            W[:, k2] *= 1 - f
    W = glaetten(W, nachbarn(ob), glatt, n)
    if os.environ.get("GF_DEBUG"):
        saum = (P[:, 2] < 0.3 * H) & (P[:, 2] > 0.24 * H) & (np.linalg.norm(P[:, :2], axis=1) > 0.11 * H)
        sag("Saum: %d Punkte, mittlere Gewichte" % saum.sum(), {nm: round(float(W[saum, i].mean()), 2) for i, nm in enumerate(GEWICHTSKNOCHEN) if W[saum, i].mean() > 0.01})
        sag("Knie", knie, "Schritt", J["schritt"], "Bein l", [np.round(x, 2) for x in J["bein.l"]])
    # höchstens vier Knochen je Punkt (glTF)
    weg = np.argsort(W, 1)[:, :-4]
    np.put_along_axis(W, weg, 0.0, 1)
    W /= W.sum(1, keepdims=True)
    # umgekehrtes Skinning: Pose-Matrizen je Knochen, je Punkt gemischt und umgekehrt
    Ms = []
    for name in GEWICHTSKNOCHEN:
        pb = arm.pose.bones[name]
        Ms.append(np.array((mw @ pb.matrix) @ (mw @ pb.bone.matrix_local).inverted()))
    Ms = np.stack(Ms)
    Mv = np.einsum("nb,bij->nij", W, Ms)
    Ph = np.c_[P, np.ones(n)]
    ruhe = np.einsum("nij,nj->ni", np.linalg.inv(Mv), Ph)[:, :3]
    setze_punkte(ob, ruhe)
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix()
    vl.update()
    gruppen = [ob.vertex_groups.new(name=nm) for nm in GEWICHTSKNOCHEN]
    for i in range(n):
        for k in np.nonzero(W[i] > 1e-4)[0]:
            gruppen[k].add([i], float(W[i, k]), 'REPLACE')
    ob.parent = arm
    mod = ob.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    sag("gebunden: %d Punkte an %d Knochen, in die Ruhehaltung zurückgerechnet" % (n, len(GEWICHTSKNOCHEN)))


# ---------------------------------------------------------------- Kette: Schlange, Wurm, Aal
def oberflaechenwege(P, E, start):
    """Kürzeste Wege über die Kanten (Dijkstra) von `start` aus."""
    n = len(P)
    nb = [[] for _ in range(n)]
    L = np.linalg.norm(P[E[:, 0]] - P[E[:, 1]], axis=1)
    for (a, b), l in zip(E, L):
        nb[a].append((b, l))
        nb[b].append((a, l))
    d = np.full(n, np.inf)
    d[start] = 0.0
    q = [(0.0, start)]
    while q:
        dd, a = heapq.heappop(q)
        if dd > d[a]:
            continue
        for b, l in nb[a]:
            nd = dd + l
            if nd < d[b]:
                d[b] = nd
                heapq.heappush(q, (nd, b))
    d[np.isinf(d)] = d[np.isfinite(d)].max()
    return d


def kette_messen(ob, glieder):
    """Längsmaß t (0 = Schwanz, 1 = Kopf) je Punkt und Gelenkpunkte der Kette."""
    P = punkte(ob)
    E = nachbarn(ob)
    d0 = oberflaechenwege(P, E, int(np.argmax(P[:, 0])))
    a = int(np.argmax(d0))
    da = oberflaechenwege(P, E, a)
    b = int(np.argmax(da))
    db = oberflaechenwege(P, E, b)
    t = da / (da + db + 1e-12)

    def ende(m):
        Q = P[m]
        return Q[:, 2].max() + 0.5 * np.ptp(Q[:, 0]) + 0.5 * np.ptp(Q[:, 1])
    if ende(t < 0.12) > ende(t > 0.88):        # der Kopf ist das höhere, dickere Ende
        t = 1 - t
        a, b = b, a
    gelenke = []
    for k in range(glieder + 1):
        tk = k / glieder
        m = np.abs(t - tk) < 0.5 / glieder
        if k == 0:
            gelenke.append(P[a])
        elif k == glieder:
            gelenke.append(P[b])
        else:
            gelenke.append(P[m].mean(0) if m.any() else gelenke[-1])
    return t, np.array(gelenke)


def kette_bauen(ob, glieder, kopfanteil):
    """Knochenkette längs des Körpers; der Kopf schaut nach −Y."""
    t, G = kette_messen(ob, glieder)
    # drehen: Blick des Kopfes (vom vorletzten zum letzten Gelenk, waagrecht) nach −Y
    blick = G[-1] - G[-2]
    blick[2] = 0
    if np.linalg.norm(blick) < 1e-6:
        blick = G[-1] - G[0]
        blick[2] = 0
    w = math.atan2(-blick[0], -blick[1])
    R = Matrix.Rotation(w, 4, 'Z')
    transformiere([ob], R)
    KETTE_DREHUNG["R"] = R
    G = (np.array(R.to_3x3()) @ G.T).T
    sag("Kette: %d Glieder, Länge %.2f m über die Oberfläche, Kopf nach vorn gedreht (%.0f°)" % (glieder, np.linalg.norm(np.diff(G, axis=0), axis=1).sum(), math.degrees(w)))
    daten = bpy.data.armatures.new("Rig")
    arm = bpy.data.objects.new("Rig", daten)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    wurzel = daten.edit_bones.new("root")
    mitte = G.mean(0)
    wurzel.head, wurzel.tail = Vector((mitte[0], mitte[1], 0)), Vector((mitte[0], mitte[1], 0.2))
    eltern = wurzel
    namen = []
    for k in range(glieder):
        nm = "kopf" if k == glieder - 1 else "s%d" % k
        b = daten.edit_bones.new(nm)
        b.head, b.tail = Vector(G[k]), Vector(G[k + 1])
        if b.length < 1e-4:
            b.tail = b.head + Vector((0, -0.01, 0))
        b.parent = eltern
        b.use_connect = k > 0
        eltern = b
        namen.append(nm)
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    arm.animation_data_create()
    # Gewichte: je Punkt zwischen den zwei nächsten Gliedern, sanft geglättet
    f = np.clip(t * glieder - 0.5, 0, glieder - 1)
    i0 = np.floor(f).astype(int)
    i1 = np.minimum(i0 + 1, glieder - 1)
    u = f - i0
    W = np.zeros((len(t), glieder))
    W[np.arange(len(t)), i0] += 1 - u
    W[np.arange(len(t)), i1] += u
    W = glaetten(W, nachbarn(ob), 4, len(t))
    W /= W.sum(1, keepdims=True)
    gruppen = [ob.vertex_groups.new(name=nm) for nm in namen]
    for i in range(len(t)):
        for k in np.nonzero(W[i] > 1e-3)[0]:
            gruppen[k].add([i], float(W[i, k]), 'REPLACE')
    ob.parent = arm
    mod = ob.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm
    # welcher Teil ist aufgerichtet (Hals)? Glieder, die deutlich steigen
    steil = [k for k in range(glieder) if (G[k + 1][2] - G[k][2]) > 0.4 * np.linalg.norm(G[k + 1] - G[k])]
    hals = sorted(set(steil) | set(range(max(0, glieder - max(2, int(glieder * kopfanteil))), glieder)))
    return arm, namen, hals, G


def bewegung(arm, name, bilder, pose):
    """Wie tiere.bewegung: pose(t) → {Knochen: [(Weltachse, Winkel), …], "_ort": Verschiebung der Wurzel}."""
    act = bpy.data.actions.new(name)
    arm.animation_data.action = act
    for f in range(bilder + 1):
        p = pose(f / bilder)
        for pb in arm.pose.bones:
            q = Quaternion()
            R = pb.bone.matrix_local.to_3x3().inverted()
            for achse, winkel in p.get(pb.name, []):
                q = Quaternion((R @ Vector(achse)).normalized(), winkel) @ q
            pb.rotation_quaternion = q
            pb.location = (R @ Vector(p.get("_ort", (0, 0, 0)))) if pb.parent is None else Vector()
            pb.keyframe_insert("rotation_quaternion", frame=f)
            pb.keyframe_insert("location", frame=f)
    act.use_fake_user = True
    arm.animation_data.action = None
    return act


def bewegungen_kette(arm, namen, hals):
    """Schlangenbewegungen unter den Namen der Skelettgegner (foe.gd › ANIM)."""
    n = len(namen)
    leib = [k for k in range(n) if k not in hals]
    S = lambda x: math.sin(2 * math.pi * x)

    def schlaengeln(tempo, weite):
        def pose(t):
            p = {}
            for k in leib:
                p[namen[k]] = [(Z, weite * S(t - k / max(1, len(leib)) * 1.2))]
            if leib:
                p[namen[leib[0]]] = [(Z, weite * 0.6 * S(t))]
            for j, k in enumerate(hals):
                p[namen[k]] = [(Z, -weite * 0.35 * S(t + 0.25) / (1 + j))]
            return p
        return pose

    def hals_neigen(winkel, seite=0.0):
        p = {}
        for j, k in enumerate(hals):
            p[namen[k]] = [(X, winkel / len(hals)), (Z, seite / len(hals))]
        return p

    def misch(*ps):
        r = {}
        for p in ps:
            for k, v in p.items():
                r[k] = r.get(k, []) + v if k != "_ort" else v
        return r

    bewegung(arm, "Idle_Combat", 60, lambda t: misch(schlaengeln(1, 0.05)(t), hals_neigen(0.08 * S(t * 2), 0.15 * S(t))))
    bewegung(arm, "Skeleton_Inactive_Standing_Pose", 2, lambda t: hals_neigen(0.0))
    bewegung(arm, "Walking_D_Skeletons", 30, schlaengeln(1, 0.16))
    bewegung(arm, "Running_A", 18, schlaengeln(1, 0.24))

    def zustossen(stark):
        def pose(t):
            aus = math.sin(math.pi * min(1, t / 0.35)) if t < 0.35 else 0.0       # ausholen: Kopf zurück und hoch
            hin = math.sin(math.pi * min(1, max(0, (t - 0.3) / 0.45)))            # zustoßen: nach vorn und unten
            return misch(hals_neigen(-0.5 * aus * stark + 1.1 * hin * stark), {"_ort": (0, -0.25 * hin * stark, 0)})
        return pose
    bewegung(arm, "1H_Melee_Attack_Chop", 24, zustossen(1.0))
    bewegung(arm, "2H_Melee_Attack_Chop", 30, lambda t: zustossen(1.3)(min(1.0, t * 2) if t < 0.5 else (t - 0.5) * 2))
    bewegung(arm, "Unarmed_Melee_Attack_Punch_A", 20, zustossen(0.8))
    bewegung(arm, "Spellcast_Shoot", 30, lambda t: misch(hals_neigen(-0.45 * math.sin(math.pi * t)), schlaengeln(2, 0.03)(t)))
    bewegung(arm, "Spellcast_Summon", 40, lambda t: misch(hals_neigen(-0.6 * math.sin(math.pi * t), 0.4 * S(t)), schlaengeln(2, 0.06)(t)))
    bewegung(arm, "2H_Melee_Attack_Spin", 36, lambda t: misch(hals_neigen(-0.7 * math.sin(math.pi * min(1, t / 0.5)) if t < 0.5 else 1.4 * math.sin(math.pi * min(1, (t - 0.5) / 0.4))),
                                                                {"_ort": (0, 0, 0.0)}))
    bewegung(arm, "Hit_A", 12, lambda t: misch(hals_neigen(-0.35 * math.sin(math.pi * t)), {"_ort": (0, 0.12 * math.sin(math.pi * t), 0)}))

    def tod(t):
        u = min(1.0, t * 1.4)
        p = hals_neigen(1.5 * u)
        for k in leib:
            p[namen[k]] = [(Z, 0.25 * u * S(k / max(1, len(leib)) * 0.8))]
        p["root"] = [(Y, 0.6 * u)]
        return p
    bewegung(arm, "Death_C_Skeletons", 30, tod)
    liegen = lambda t: misch(hals_neigen(1.45), {k: [(Z, 0.2 * S(i / max(1, len(leib))))] for i, k in enumerate(namen[j] for j in leib)})
    bewegung(arm, "Skeletons_Inactive_Floor_Pose", 2, liegen)

    def aufrichten(t):
        u = 1 - (1 - min(1.0, t * 1.2)) ** 2
        p = hals_neigen(1.45 * (1 - u))
        for i, k in enumerate(leib):
            p[namen[k]] = [(Z, 0.2 * (1 - u) * S(i / max(1, len(leib))))]
        return p
    bewegung(arm, "Skeletons_Awaken_Floor", 40, aufrichten)
    bewegung(arm, "Skeletons_Awaken_Standing", 40, aufrichten)
    bewegung(arm, "Idle", 60, lambda t: misch(schlaengeln(1, 0.03)(t), hals_neigen(0.05 * S(t))))


# ---------------------------------------------------------------- Teil auf eine Fabrikfigur setzen
def teil_aufsetzen(tief, koerper, knochen, groesse, versatz):
    """Lädt eine fertige Figur (mit Skelett und Bewegungen), setzt das Teil an einen Knochen und bindet es fest."""
    vorher = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=koerper)
    neu = [o for o in bpy.data.objects if o not in vorher]
    arm = next(o for o in neu if o.type == 'ARMATURE')
    bpy.context.view_layer.update()
    pb = arm.pose.bones[knochen]
    kopf = arm.matrix_world @ pb.bone.head_local
    P = punkte(tief)
    unten = P[:, 2].min()
    mitte = P.mean(0)
    k = groesse / max(1e-6, np.ptp(P[:, 2]))
    P = (P - np.array([mitte[0], mitte[1], unten])) * k + np.array(kopf) + np.array(versatz)
    setze_punkte(tief, P)
    tief.vertex_groups.new(name=knochen).add(list(range(len(P))), 1.0, 'REPLACE')
    tief.parent = arm
    mod = tief.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm
    sag("Teil an '%s' gesetzt (%.2f m hoch)" % (knochen, groesse))
    return arm


# ---------------------------------------------------------------- Ablauf
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="Gegnerfabrik: fremdes Netz → spielbarer Gegner (.glb)")
    ap.add_argument("--netz", required=True, help="Netz aus Bild-zu-3D (.glb .gltf .obj .ply .stl)")
    ap.add_argument("--ziel", required=True, help="fertige Figur (.glb)")
    ap.add_argument("--art", default="zweibeiner", choices=["zweibeiner", "kette", "teil"])
    ap.add_argument("--name", default=None)
    ap.add_argument("--hoehe", type=float, default=2.45, help="Zweibeiner: Scheitelhöhe in m (Fabrikgegner: rund 2,45). Kette: größte Ausdehnung")
    ap.add_argument("--dreiecke", type=int, default=5000)
    ap.add_argument("--tafel", type=int, default=512, help="Kantenlänge der Texturtafel (512 für Gegner, 1024 für Hüter)")
    ap.add_argument("--vorne", help="gemalte Vorderansicht (PNG mit Alpha oder einfarbiger Grund)")
    ap.add_argument("--hinten", help="gemalte Rückansicht")
    ap.add_argument("--seite", help="gemalte Seitenansicht")
    ap.add_argument("--bogen", help="Vorlagenbogen der Bildstufe gegner_vorlagen (links vorn, rechts hinten bzw. Seite): wird geteilt")
    ap.add_argument("--drehen", type=float, default=None, help="Drehung um die Hochachse in Grad statt automatischer Ausrichtung")
    ap.add_argument("--glieder", type=int, default=14, help="Kette: Zahl der Glieder")
    ap.add_argument("--hals", type=float, default=0.25, help="Kette: Anteil der Glieder, die sich aufrichten und zustoßen")
    ap.add_argument("--rig", default=os.path.join(FABRIK, "rigs", "Skelett.glb"))
    ap.add_argument("--koerper", help="Teil: fertige Figur (.glb), auf die das Teil kommt")
    ap.add_argument("--knochen", default="head")
    ap.add_argument("--teilgroesse", type=float, default=0.5)
    ap.add_argument("--versatz", default="0,0,0")
    ap.add_argument("--arbeit", help="Ordner für Zwischendateien (Tafel als PNG); Standard: temporärer Ordner")
    ap.add_argument("--rau", type=float, default=0.8)
    ap.add_argument("--metall", type=float, default=0.0)
    a = ap.parse_args(argv)
    name = a.name or os.path.splitext(os.path.basename(a.ziel))[0]
    arbeit = a.arbeit or os.path.join(tempfile.gettempdir(), "gegnerfabrik")
    os.makedirs(arbeit, exist_ok=True)
    tafel_pfad = os.path.join(arbeit, name + "_tafel.png")
    os.makedirs(os.path.dirname(os.path.abspath(a.ziel)), exist_ok=True)

    if a.art == "zweibeiner":
        arm = fabrik.lade_rig(a.rig, BEWEGUNGEN)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.scene.render.fps = 30
        arm = None
    hoch = importiere(a.netz)
    saeubern(hoch)
    if a.art == "zweibeiner":
        ausrichten_zweibeiner(hoch, a.hoehe, a.drehen)
    else:
        ausrichten_allgemein(hoch, a.hoehe if a.art == "kette" else None, a.drehen)
    tief = vereinfache(hoch, a.dreiecke)
    tief.name = name

    if a.art == "kette":
        arm, namen, hals, _ = kette_bauen(tief, a.glieder, a.hals)
        _richte_wie(hoch, tief)      # das feine Netz mitdrehen, damit die Farben am selben Ort liegen
    if a.bogen:
        links, rechts_ = bogen.teilen(a.bogen, arbeit)
        a.vorne = a.vorne or links
        if a.art == "kette":
            a.seite = a.seite or rechts_
        else:
            a.hinten = a.hinten or rechts_
        sag("Bogen geteilt:", links, rechts_)
    ansichten = []
    vorn = None
    for pfad, blick, rechts in ((a.vorne, (0, 1, 0), (1, 0, 0)), (a.hinten, (0, -1, 0), (-1, 0, 0)), (a.seite, (-1, 0, 0), (0, 1, 0))):
        if pfad:
            v = Ansicht(pfad, blick, rechts)
            if pfad == a.vorne:
                vorn = v
            elif pfad == a.hinten and vorn is not None:
                v.folgt = vorn
            else:
                v.suche = (0, 360, 10)     # Seitenansicht: Blickrichtung des Tiers im Bild unbekannt
            ansichten.append(v)
    tafel_backen(tief, hoch, ansichten, a.tafel, tafel_pfad)
    bild = bpy.data.images.load(tafel_pfad)
    tief.data.materials.clear()
    tief.data.materials.append(fabrik.material(name, bild, a.metall, a.rau))
    bpy.data.objects.remove(hoch, do_unlink=True)

    if a.art == "zweibeiner":
        J = vermessen(punkte(tief))
        sag("gemessen: Schritt %.2f, Hals %.2f, Arme %.2f/%.2f m" % (J["schritt"], J["hals"], J["arm.l"][1], J["arm.r"][1]))
        plan = plan_aus_massen(J)
        fabrik.umbauen(arm, plan, (plan["upperleg.l"]["len"] + plan["lowerleg.l"]["len"]) / (0.227 + 0.147))
        haltung_einnehmen(arm, J)
        binden_zweibeiner(tief, arm, J)
        fabrik.boden(arm, tief)
    elif a.art == "kette":
        bewegungen_kette(arm, namen, hals)
    else:
        arm = teil_aufsetzen(tief, a.koerper, a.knochen, a.teilgroesse, [float(x) for x in a.versatz.split(",")])
    tri = len(tief.data.polygons)
    os.makedirs(os.path.dirname(os.path.abspath(a.ziel)), exist_ok=True)
    fabrik.ausgabe(a.ziel)
    sag("fertig: %s · %d Dreiecke · %d Bewegungen · %d KB" % (a.ziel, tri, len(bpy.data.actions), os.path.getsize(a.ziel) // 1024))


def _richte_wie(hoch, tief):
    """kette_bauen dreht nur das grobe Netz (Kopf nach vorn); das feine bekommt dieselbe Drehung."""
    R = KETTE_DREHUNG.get("R")
    if R is not None:
        transformiere([hoch], R)


KETTE_DREHUNG = {}

if __name__ == "__main__":
    main()
