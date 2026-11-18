# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Baukasten für Tiere (Fassung 2.8): Wüstenfuchs (G18), Skorpion und Seelenvogel Ba (G17).

Anders als bei den Menschen gibt es hier keine Vorlage mit Skelett und Bewegungen. Deshalb baut dieses Skript beides selbst:
ein kleines Skelett je Tier und die Bewegungen als Formeln über die Zeit (Galopp, Schreiten der acht Beine, Flügelschlag),
die als Keyframes in Blender landen. Die Bewegungen heißen wie die der Skelettgegner, damit die Kampflogik des Spiels
sie ohne Änderung findet (Idle_Combat, Walking_D_Skeletons, Running_A, 1H_Melee_Attack_Chop, Hit_A, Death_C_Skeletons).

Aufruf: python tiere.py <Fuchs|Skorpion|Ba|alle> [Zielordner] [Arbeitsordner]
Vorne ist −Y (wie bei den Menschen), oben ist +Z.
"""
import math
import os
import sys
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import bpy
import numpy as np
from mathutils import Vector, Quaternion
from PIL import Image, ImageDraw
import fabrik
from fabrik import Bau, lerp
from malen import Tafel
import gemalt as gm

WURZEL = os.path.join(HIER, "..", "..")
BILD = lambda n: os.path.join(WURZEL, "bilder", n)
FPS = 30
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


# ---------------------------------------------------------------- Skelett und Bewegung
def skelett(knochen):
    """knochen: [(Name, Kopf, Ende, Eltern)] → Armatur. Die Rollwinkel sind egal: Drehungen gibt man in Weltachsen an."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS
    daten = bpy.data.armatures.new("Rig")
    arm = bpy.data.objects.new("Rig", daten)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for name, kopf, ende, eltern in knochen:
        b = daten.edit_bones.new(name)
        b.head, b.tail = Vector(kopf), Vector(ende)
        if eltern:
            b.parent = daten.edit_bones[eltern]
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    arm.animation_data_create()
    return arm


def bewegung(arm, name, bilder, pose, schleife=True):
    """Legt eine Bewegung an. pose(t) mit t von 0 bis 1 gibt {Knochen: [(Weltachse, Winkel), …]} und optional
    "_ort": Verschiebung der Wurzel. Jeder Knochen bekommt in jedem Bild einen Schlüssel, damit beim Überblenden im
    Spiel keine Haltung einer anderen Bewegung hängen bleibt."""
    act = bpy.data.actions.new(name)
    arm.animation_data.action = act
    for f in range(bilder + 1):
        t = f / bilder
        p = pose(t)
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
    return act


def ruhe(arm):
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()


def ausgeben(arm, bau, name, tafel, glut, ziel, matwahl=None):
    ruhe(arm)
    bild = bpy.data.images.load(tafel)
    gb = bpy.data.images.load(glut) if glut else None
    mats = matwahl(bild, gb) if matwahl else [fabrik.material("fell", bild, 0.0, 0.85)]
    ob = bau.mesh(name, arm, mats)
    tri = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    fabrik.ausgabe(ziel)
    print("%s: %d Dreiecke, %d Bewegungen, %d KB" % (name, tri, len(bpy.data.actions), os.path.getsize(ziel) // 1024))


def kegel(B, a, b, r0, r1, w, feld, n=8, deckel=(True, True), mat=0, vorn=None):
    """Glied von a nach b mit Halbmesser r0 → r1 (Halbmesser als Zahl oder (vorn/hinten, seitlich))."""
    ax = (Vector(b) - Vector(a)).normalized()
    v = vorn or (Z if abs(ax.dot(Z)) < 0.9 else Y)
    def rr(r):
        return (r, r) if not isinstance(r, tuple) else r
    B.loft([{"c": Vector(a), "a": rr(r0)[0], "b": rr(r0)[1], "w": w if not callable(w) else w(0)},
            {"c": Vector(b), "a": rr(r1)[0], "b": rr(r1)[1], "w": w if not callable(w) else w(1)}], n, feld, mat,
           achse=tuple(ax), vorn=tuple(v), deckel=deckel)


def kette(B, punkte, radien, gewichte, feld, n=10, deckel=(True, True), mat=0, vorn=None, p=2.0):
    """Körper aus Ringen entlang beliebiger Punkte (Rumpf, Schwanz). radien: Zahl oder (a, b), gewichte: dict je Ring."""
    ringe = []
    for i, c in enumerate(punkte):
        nach = punkte[min(i + 1, len(punkte) - 1)]
        vor = punkte[max(i - 1, 0)]
        ax = (Vector(nach) - Vector(vor)).normalized()
        r = radien[i] if isinstance(radien[i], tuple) else (radien[i], radien[i])
        v = vorn or (Z if abs(ax.dot(Z)) < 0.9 else Y)
        ringe.append({"c": Vector(c), "a": r[0], "b": r[1], "w": gewichte[i], "ax": tuple(ax), "vorn": tuple(v), "v": i / max(1, len(punkte) - 1)})
    B.loft(ringe, n, feld, mat, deckel=deckel, p=p)


def wackel(t, f=1.0, ph=0.0):
    return math.sin(2 * math.pi * (t * f + ph))


# ---------------------------------------------------------------- Texturen aus den Bögen
def tafel_fuchs(pfad):
    k = Image.open(BILD("G18_voll.webp")).convert("RGB")
    F = {"fell": (0, 0, 256, 256), "bauch": (256, 0, 512, 256), "ohr": (0, 256, 128, 384), "schwanz": (128, 256, 512, 384),
         "kopf": (0, 384, 256, 512), "kragen": (256, 384, 384, 448), "auge": (384, 384, 448, 448), "nase": (448, 384, 512, 448), "pfote": (256, 448, 512, 512)}
    t = Image.new("RGB", (512, 512), (170, 150, 130))
    def setz(feld, fl):
        x0, y0, x1, y1 = F[feld]
        t.paste(fl.resize((x1 - x0, y1 - y0), Image.LANCZOS), (x0, y0))
    setz("fell", gm.kachel(gm.flach(k.crop((300, 300, 480, 420)), 0.7), 256, 256, 128))
    setz("bauch", gm.kachel(gm.flach(k.crop((500, 640, 570, 740)), 0.6), 256, 256, 128))
    setz("ohr", gm.angleichen(k.crop((600, 270, 650, 370)), 150))
    schw = gm.kachel(gm.flach(k.crop((220, 400, 300, 520)), 0.6), 384, 128, 128)
    a = np.asarray(schw).astype(np.float32)
    dunkel = np.clip((np.arange(384) / 384 - 0.75) / 0.25, 0, 1)[None, :, None]   # dunkle Schwanzspitze
    setz("schwanz", Image.fromarray(np.clip(a * (1 - 0.7 * dunkel), 0, 255).astype(np.uint8)))
    setz("kopf", gm.kachel(gm.flach(k.crop((700, 380, 780, 440)), 0.6), 256, 128, 128))
    setz("kragen", gm.kachel(k.crop((570, 470, 600, 540)), 128, 64, 64))
    au = Image.new("RGB", (64, 64), (40, 24, 16))
    d = ImageDraw.Draw(au)
    d.ellipse([8, 8, 56, 56], fill=(120, 60, 30))
    d.ellipse([20, 20, 44, 44], fill=(12, 8, 6))
    d.ellipse([16, 14, 26, 24], fill=(240, 230, 220))
    setz("auge", au)
    setz("nase", Image.new("RGB", (64, 64), (34, 26, 24)))
    setz("pfote", gm.kachel(gm.flach(k.crop((520, 800, 580, 860)), 0.6), 256, 64, 64))
    t.save(pfad)
    return F


def tafel_skorpion(pfad):
    k = Image.open(BILD("G17_voll.webp")).convert("RGB")
    F = {"panzer": (0, 0, 256, 256), "glied": (256, 0, 512, 256), "schere": (0, 256, 256, 512), "stachel": (256, 256, 384, 384), "auge": (384, 256, 448, 320)}
    t = Image.new("RGB", (512, 512), (40, 36, 34))
    def setz(feld, fl):
        x0, y0, x1, y1 = F[feld]
        t.paste(fl.resize((x1 - x0, y1 - y0), Image.LANCZOS), (x0, y0))
    setz("panzer", gm.kachel(gm.flach(k.crop((880, 230, 1000, 330)), 0.5), 256, 256, 128))
    setz("glied", gm.kachel(gm.flach(k.crop((830, 60, 900, 160)), 0.5), 256, 256, 128))
    setz("schere", gm.kachel(gm.flach(k.crop((1150, 360, 1260, 470)), 0.5), 256, 256, 128))
    setz("stachel", k.crop((1020, 120, 1060, 200)))
    au = Image.new("RGB", (64, 64), (20, 10, 8))
    ImageDraw.Draw(au).ellipse([16, 16, 48, 48], fill=(180, 40, 20))
    setz("auge", au)
    t.save(pfad)
    g = Image.new("RGB", (512, 512), (0, 0, 0))
    ImageDraw.Draw(g).ellipse([396, 268, 436, 308], fill=(255, 80, 40))     # glimmende Augen
    g.save(pfad.replace(".png", "_glut.png"))
    return F


def tafel_ba(pfad):
    k = Image.open(BILD("G17_voll.webp")).convert("RGB")
    F = {"feder": (0, 0, 512, 192), "leib": (0, 192, 256, 384), "kopf": (256, 192, 512, 384), "band": (0, 384, 256, 448),
         "kralle": (256, 384, 384, 448), "auge": (384, 384, 448, 448), "haar": (0, 448, 256, 512)}
    t = Image.new("RGB", (512, 512), (90, 150, 150))
    def setz(feld, fl):
        x0, y0, x1, y1 = F[feld]
        t.paste(fl.resize((x1 - x0, y1 - y0), Image.LANCZOS), (x0, y0))
    setz("feder", k.crop((90, 80, 330, 200)))
    setz("leib", gm.kachel(gm.flach(k.crop((330, 330, 430, 420)), 0.6), 256, 192, 96))
    setz("kopf", gm.haut(k, (585, 330, 600, 350), 256, 192, 5, 1.15))
    setz("band", gm.kachel(k.crop((470, 225, 560, 245)), 256, 64, 64))
    setz("kralle", gm.kachel(k.crop((380, 480, 440, 540)), 128, 64, 64))
    au = Image.new("RGB", (64, 64), (230, 250, 255))
    ImageDraw.Draw(au).ellipse([20, 20, 44, 44], fill=(20, 60, 70))
    setz("auge", au)
    setz("haar", Image.new("RGB", (256, 64), (24, 30, 36)))
    t.save(pfad)
    # Leuchtkarte: die ganze Gestalt glimmt türkis, die Augen hell
    a = np.asarray(t).astype(np.float32) * 0.55
    g = Image.fromarray(np.clip(a * np.array([0.7, 1.1, 1.15]), 0, 255).astype(np.uint8))
    ImageDraw.Draw(g).ellipse([396, 396, 436, 436], fill=(255, 255, 255))
    g.save(pfad.replace(".png", "_glut.png"))
    return F


# ---------------------------------------------------------------- Wüstenfuchs (Begleiter der Jägerin)
def fuchs(ziel, tmp):
    tafel = os.path.join(tmp, "Fuchs_tafel.png")
    F = tafel_fuchs(tafel)
    beine = []
    for s, x in ((".l", 0.11), (".r", -0.11)):
        beine += [("vorn" + s, (x, -0.22, 0.46), (x, -0.23, 0.24), "brust"), ("vornunten" + s, (x, -0.23, 0.24), (x, -0.25, 0.04), "vorn" + s),
                  ("hinten" + s, (x, 0.26, 0.46), (x, 0.31, 0.25), "ruecken"), ("hintenunten" + s, (x, 0.31, 0.25), (x, 0.27, 0.04), "hinten" + s),
                  ("ohr" + s, (x * 0.6, -0.44, 0.86), (x * 1.3, -0.42, 1.12), "kopf")]
    arm = skelett([("root", (0, 0, 0), (0, 0, 0.2), None), ("ruecken", (0, 0.32, 0.5), (0, -0.04, 0.52), "root"),
                   ("brust", (0, -0.04, 0.52), (0, -0.3, 0.56), "ruecken"), ("hals", (0, -0.3, 0.58), (0, -0.42, 0.75), "brust"),
                   ("kopf", (0, -0.42, 0.75), (0, -0.66, 0.72), "hals"), ("schwanz", (0, 0.34, 0.52), (0, 0.62, 0.44), "ruecken"),
                   ("schwanzende", (0, 0.62, 0.44), (0, 0.9, 0.34), "schwanz")] + beine)
    B = Bau(512)
    # Rumpf: vom Ansatz des Schwanzes bis zur Brust, unten heller Bauch über die Texturhälfte
    kette(B, [(0, 0.38, 0.5), (0, 0.24, 0.52), (0, 0.04, 0.53), (0, -0.16, 0.55), (0, -0.3, 0.57)],
          [(0.11, 0.1), (0.15, 0.13), (0.16, 0.14), (0.16, 0.13), (0.12, 0.11)],
          [{"ruecken": 1}, {"ruecken": 1}, {"ruecken": .5, "brust": .5}, {"brust": 1}, {"brust": .6, "hals": .4}], F["fell"], 14)
    kette(B, [(0, -0.28, 0.56), (0, -0.36, 0.66), (0, -0.42, 0.75)], [0.1, 0.085, 0.08], [{"brust": .6, "hals": .4}, {"hals": 1}, {"hals": .4, "kopf": .6}], F["fell"], 10)
    kette(B, [(0, -0.37, 0.67), (0, -0.37, 0.67)], [0.1, 0.1], [{"hals": 1}, {"hals": 1}], F["kragen"], 12, deckel=(False, False))
    B.loft([{"c": Vector((0, -0.36, 0.665)), "a": .098, "b": .098, "w": {"hals": 1}, "ax": (0, -0.6, 0.8), "vorn": (0, 0.8, 0.6)},
            {"c": Vector((0, -0.38, 0.69)), "a": .1, "b": .1, "w": {"hals": 1}, "ax": (0, -0.6, 0.8), "vorn": (0, 0.8, 0.6)}], 12, F["kragen"], 0)
    # Kopf: Schädel und spitze Schnauze
    kette(B, [(0, -0.38, 0.78), (0, -0.46, 0.79), (0, -0.55, 0.76), (0, -0.63, 0.73), (0, -0.675, 0.72)],
          [(0.09, 0.085), (0.1, 0.095), (0.065, 0.06), (0.035, 0.033), (0.012, 0.012)], [{"kopf": 1}] * 5, F["kopf"], 12)
    kegel(B, (0, -0.665, 0.725), (0, -0.69, 0.722), 0.018, 0.004, {"kopf": 1}, F["nase"], 6)
    for s in (1, -1):
        kegel(B, (s * 0.06, -0.535, 0.80), (s * 0.068, -0.55, 0.80), 0.022, 0.012, {"kopf": 1}, F["auge"], 8, vorn=Z)
        o = ".l" if s > 0 else ".r"
        # große Ohren: flach, innen rosa
        B.loft([{"c": Vector((s * 0.055, -0.44, 0.86)), "a": 0.03, "b": 0.075, "w": {"ohr" + o: 1}, "v": 0},
                {"c": Vector((s * 0.09, -0.43, 0.99)), "a": 0.022, "b": 0.06, "w": {"ohr" + o: 1}, "v": 0.5},
                {"c": Vector((s * 0.13, -0.42, 1.13)), "a": 0.004, "b": 0.006, "w": {"ohr" + o: 1}, "v": 1}],
               8, F["ohr"], 0, achse=(s * 0.25, 0, 1), vorn=(0, -1, 0), deckel=(True, False))
    # Beine mit Pfoten
    for s in (".l", ".r"):
        x = 0.11 if s == ".l" else -0.11
        for vor, y0, y1, y2 in (("vorn", -0.22, -0.23, -0.25), ("hinten", 0.26, 0.31, 0.27)):
            o, u = vor + s, ("vornunten" if vor == "vorn" else "hintenunten") + s
            dick = 0.06 if vor == "hinten" else 0.05
            kette(B, [(x, y0, 0.5), (x, y1 - (0 if vor == "vorn" else 0.0), 0.25), (x, y2, 0.06)], [dick, 0.032, 0.026],
                  [{o: 1}, {o: .5, u: .5}, {u: 1}], F["bauch"], 8)
            kette(B, [(x, y2 + 0.02, 0.05), (x, y2 - 0.04, 0.025), (x, y2 - 0.07, 0.015)], [(0.03, 0.035), (0.028, 0.034), (0.01, 0.012)],
                  [{u: 1}] * 3, F["pfote"], 8)
    # buschiger Schwanz
    kette(B, [(0, 0.36, 0.51), (0, 0.5, 0.49), (0, 0.66, 0.43), (0, 0.8, 0.37), (0, 0.92, 0.33)], [0.05, 0.085, 0.095, 0.075, 0.015],
          [{"ruecken": .5, "schwanz": .5}, {"schwanz": 1}, {"schwanz": .4, "schwanzende": .6}, {"schwanzende": 1}, {"schwanzende": 1}], F["schwanz"], 10)

    def lauf(tempo, hub):
        def pose(t):
            f = 2 * math.pi * t
            p = {"_ort": (0, 0, hub * abs(math.sin(f)))}
            for s, ph in ((".l", 0.0), (".r", 0.18)):
                p["vorn" + s] = [(X, -tempo * math.sin(f + ph * 6.28))]
                p["vornunten" + s] = [(X, 0.6 * tempo * max(0.0, math.cos(f + ph * 6.28)))]
                p["hinten" + s] = [(X, tempo * math.sin(f + ph * 6.28))]
                p["hintenunten" + s] = [(X, -0.7 * tempo * max(0.0, -math.cos(f + ph * 6.28)))]
                p["ohr" + s] = [(X, 0.08 * math.sin(f))]
            p["ruecken"] = [(X, 0.06 * math.sin(2 * f))]
            p["kopf"] = [(X, -0.05 * math.sin(2 * f))]
            p["schwanz"] = [(X, -0.25 + 0.15 * math.sin(f)), (Z, 0.15 * math.sin(f))]
            return p
        return pose

    bewegung(arm, "Running_A", 16, lauf(0.65, 0.05))
    bewegung(arm, "Walking_A", 28, lauf(0.3, 0.015))
    bewegung(arm, "Idle", 90, lambda t: {"schwanz": [(Z, 0.25 * wackel(t))], "schwanzende": [(Z, 0.2 * wackel(t, 1, 0.15))],
                                          "kopf": [(Z, 0.15 * wackel(t, 1, 0.3)), (X, 0.05 * wackel(t, 2))],
                                          "ohr.l": [(Y, 0.12 * max(0, wackel(t, 3)) ** 8)], "ohr.r": [(Y, -0.12 * max(0, wackel(t, 3, 0.4)) ** 8)],
                                          "_ort": (0, 0, 0.006 * wackel(t, 2))})
    def biss(t):
        u = math.sin(math.pi * min(1.0, t * 1.6))
        return {"brust": [(X, 0.25 * u)], "hals": [(X, 0.35 * u)], "kopf": [(X, -0.2 * u)], "_ort": (0, -0.15 * u, -0.04 * u),
                "hinten.l": [(X, 0.3 * u)], "hinten.r": [(X, 0.3 * u)], "schwanz": [(X, -0.4 * u)]}
    bewegung(arm, "Bite", 14, biss, False)
    ausgeben(arm, B, "Fuchs", tafel, None, os.path.join(ziel, "Fuchs.glb"))


# ---------------------------------------------------------------- Skorpion (Tefens Brut)
def skorpion(ziel, tmp):
    tafel = os.path.join(tmp, "Skorpion_tafel.png")
    F = tafel_skorpion(tafel)
    schwanz = [(0, 0.34, 0.24), (0, 0.58, 0.36), (0, 0.72, 0.58), (0, 0.7, 0.82), (0, 0.56, 0.98), (0, 0.38, 1.0)]
    kn = [("root", (0, 0, 0), (0, 0, 0.2), None), ("leib", (0, 0.36, 0.22), (0, -0.34, 0.22), "root")]
    eltern = "leib"
    for i in range(5):
        kn.append(("s%d" % i, schwanz[i], schwanz[i + 1], eltern))
        eltern = "s%d" % i
    kn.append(("stachel", schwanz[5], (0, 0.28, 0.9), "s4"))
    for s, x in ((".l", 1), (".r", -1)):
        kn += [("arm" + s, (x * 0.14, -0.3, 0.22), (x * 0.32, -0.52, 0.26), "leib"), ("schere" + s, (x * 0.32, -0.52, 0.26), (x * 0.3, -0.84, 0.24), "arm" + s)]
        for j, y in enumerate((-0.16, 0.0, 0.14, 0.28)):
            kn += [("bein%d%s" % (j, s), (x * 0.14, y, 0.2), (x * 0.4, y + 0.02 * (j - 1.5), 0.3), "leib"),
                   ("fuss%d%s" % (j, s), (x * 0.4, y + 0.02 * (j - 1.5), 0.3), (x * 0.56, y + 0.06 * (j - 1.5), 0.0), "bein%d%s" % (j, s))]
    arm = skelett(kn)
    B = Bau(512)
    PANZER, GLUT = 0, 1
    # Leib: flach, vorn breiter, Kopfschild
    kette(B, [(0, 0.38, 0.22), (0, 0.2, 0.24), (0, 0.0, 0.25), (0, -0.2, 0.24), (0, -0.34, 0.22), (0, -0.4, 0.21)],
          [(0.07, 0.12), (0.1, 0.17), (0.11, 0.19), (0.1, 0.18), (0.08, 0.15), (0.03, 0.06)], [{"leib": 1}] * 6, F["panzer"], 12, p=2.6)
    for s in (1, -1):
        kegel(B, (s * 0.05, -0.34, 0.27), (s * 0.055, -0.36, 0.28), 0.018, 0.01, {"leib": 1}, F["auge"], 6, mat=GLUT)
    # Schwanz aus Gliedern, jedes Glied an seinem Knochen
    for i in range(5):
        a, b = Vector(schwanz[i]), Vector(schwanz[i + 1])
        r0, r1 = 0.075 - i * 0.008, 0.068 - i * 0.008
        kette(B, [a, lerp(a, b, 0.5), b], [r0, r0 * 1.12, r1], [{"s%d" % i: 1}] * 3, F["glied"], 9)
    kette(B, [schwanz[5], (0, 0.33, 1.0), (0, 0.27, 0.93), (0, 0.25, 0.86)], [0.06, 0.045, 0.02, 0.003], [{"stachel": 1}] * 4, F["stachel"], 8)
    for s in (".l", ".r"):
        x = 1 if s == ".l" else -1
        kette(B, [(x * 0.14, -0.3, 0.22), (x * 0.24, -0.42, 0.24), (x * 0.32, -0.52, 0.26)], [0.035, 0.04, 0.035], [{"leib": .5, "arm" + s: .5}, {"arm" + s: 1}, {"arm" + s: .5, "schere" + s: .5}], F["glied"], 8)
        # Schere: dicke Hand mit zwei Zinken
        kette(B, [(x * 0.32, -0.52, 0.26), (x * 0.33, -0.62, 0.26), (x * 0.32, -0.7, 0.25)], [(0.05, 0.06), (0.07, 0.085), (0.05, 0.06)], [{"schere" + s: 1}] * 3, F["schere"], 10)
        kette(B, [(x * 0.35, -0.7, 0.25), (x * 0.36, -0.8, 0.25), (x * 0.32, -0.88, 0.24)], [0.025, 0.018, 0.003], [{"schere" + s: 1}] * 3, F["schere"], 6)
        kette(B, [(x * 0.29, -0.7, 0.25), (x * 0.27, -0.78, 0.24), (x * 0.29, -0.84, 0.23)], [0.02, 0.014, 0.003], [{"schere" + s: 1}] * 3, F["schere"], 6)
        for j, y in enumerate((-0.16, 0.0, 0.14, 0.28)):
            k1, k2 = "bein%d%s" % (j, s), "fuss%d%s" % (j, s)
            kn_ = (x * 0.4, y + 0.02 * (j - 1.5), 0.3)
            fu = (x * 0.56, y + 0.06 * (j - 1.5), 0.0)
            kette(B, [(x * 0.14, y, 0.2), kn_], [0.022, 0.018], [{k1: 1}, {k1: .5, k2: .5}], F["glied"], 6)
            kette(B, [kn_, fu], [0.018, 0.006], [{k1: .5, k2: .5}, {k2: 1}], F["glied"], 6)

    def schreiten(tempo):
        def pose(t):
            f = 2 * math.pi * t
            p = {"_ort": (0, 0, 0.01 * math.sin(4 * f))}
            for s, sg in ((".l", 1), (".r", -1)):
                for j in range(4):
                    ph = f + math.pi * ((j + (0 if s == ".l" else 1)) % 2)
                    p["bein%d%s" % (j, s)] = [(Z, sg * tempo * math.sin(ph)), (Y, -sg * 0.35 * max(0.0, math.cos(ph)))]
                p["arm" + s] = [(Z, sg * 0.08 * math.sin(f))]
            p["s0"] = [(Z, 0.06 * math.sin(f))]
            p["s3"] = [(X, 0.05 * math.sin(2 * f))]
            return p
        return pose
    bewegung(arm, "Walking_D_Skeletons", 20, schreiten(0.25))
    bewegung(arm, "Running_A", 12, schreiten(0.4))
    bewegung(arm, "Idle_Combat", 60, lambda t: {"s1": [(Z, 0.08 * wackel(t))], "s3": [(X, 0.06 * wackel(t, 2))], "stachel": [(X, 0.1 * wackel(t, 2, 0.2))],
                                                "schere.l": [(Z, 0.15 * max(0, wackel(t, 2)))], "schere.r": [(Z, -0.15 * max(0, wackel(t, 2, 0.5)))],
                                                "arm.l": [(Z, 0.06 * wackel(t))], "arm.r": [(Z, -0.06 * wackel(t))]})
    def stich(t):
        u = math.sin(math.pi * min(1.0, t * 1.4))
        return {"s1": [(X, 0.25 * u)], "s2": [(X, 0.35 * u)], "s3": [(X, 0.4 * u)], "s4": [(X, 0.3 * u)], "stachel": [(X, 0.4 * u)],
                "leib": [(X, -0.06 * u)], "schere.l": [(Z, -0.3 * u)], "schere.r": [(Z, 0.3 * u)], "_ort": (0, -0.06 * u, 0)}
    bewegung(arm, "1H_Melee_Attack_Chop", 18, stich, False)
    bewegung(arm, "Hit_A", 10, lambda t: {"leib": [(X, -0.15 * math.sin(math.pi * t))], "_ort": (0, 0.08 * math.sin(math.pi * t), 0)}, False)
    def tod(t):
        u = min(1.0, t * 1.5)
        p = {"root": [(Y, 2.9 * u)], "_ort": (0, 0, 0.25 * math.sin(math.pi * u))}
        for s, sg in ((".l", 1), (".r", -1)):
            for j in range(4):
                p["fuss%d%s" % (j, s)] = [(Y, sg * 0.9 * u)]
        p["s2"] = [(X, -0.3 * u)]
        return p
    bewegung(arm, "Death_C_Skeletons", 24, tod, False)
    ausgeben(arm, B, "Skorpion", tafel, tafel.replace(".png", "_glut.png"), os.path.join(ziel, "Skorpion.glb"),
             lambda bild, gb: [fabrik.material("panzer", bild, 0.2, 0.45), fabrik.material("glut", bild, 0.0, 0.5, glut=3.0, glutbild=gb)])


# ---------------------------------------------------------------- Seelenvogel Ba (Irrender Ba)
def ba(ziel, tmp):
    tafel = os.path.join(tmp, "Ba_tafel.png")
    F = tafel_ba(tafel)
    H = 1.3
    kn = [("root", (0, 0, 0), (0, 0, 0.2), None), ("leib", (0, 0.24, H), (0, -0.12, H + 0.04), "root"),
          ("kopf", (0, -0.12, H + 0.06), (0, -0.2, H + 0.3), "leib"), ("schwanz", (0, 0.24, H), (0, 0.5, H - 0.08), "leib")]
    for s, x in ((".l", 1), (".r", -1)):
        kn += [("fluegel" + s, (x * 0.08, -0.04, H + 0.08), (x * 0.42, 0.0, H + 0.12), "leib"),
               ("hand" + s, (x * 0.42, 0.0, H + 0.12), (x * 0.82, 0.08, H + 0.1), "fluegel" + s),
               ("kralle" + s, (x * 0.06, 0.08, H - 0.1), (x * 0.07, 0.04, H - 0.32), "leib")]
    arm = skelett(kn)
    B = Bau(512)
    # Leib eines Vogels
    kette(B, [(0, 0.3, H - 0.02), (0, 0.18, H), (0, 0.02, H + 0.02), (0, -0.1, H + 0.06), (0, -0.14, H + 0.1)],
          [0.04, 0.11, 0.13, 0.1, 0.06], [{"leib": 1}, {"leib": 1}, {"leib": 1}, {"leib": .6, "kopf": .4}, {"kopf": 1}], F["leib"], 12)
    # Kopf einer Frau: rund, mit Gesicht nach vorn, Stirnband, dunkles Haar hinten
    zs = [H + 0.12, H + 0.16, H + 0.21, H + 0.26, H + 0.31, H + 0.35, H + 0.37]
    rs = [(0.045, 0.05), (0.07, 0.07), (0.085, 0.08), (0.088, 0.083), (0.078, 0.075), (0.05, 0.05), (0.01, 0.01)]
    B.loft([{"c": Vector((0, -0.17, z)), "a": r[0], "b": r[1], "w": {"kopf": 1}, "v": i / 6} for i, (z, r) in enumerate(zip(zs, rs))], 14, F["kopf"], 0, deckel=(False, True))
    B.loft([{"c": Vector((0, -0.17, z)), "a": r[0] + 0.006, "b": r[1] + 0.006, "w": {"kopf": 1}} for z, r in ((H + 0.28, (0.086, 0.081)), (H + 0.31, (0.08, 0.077)))], 14, F["band"], 0)
    B.loft([{"c": Vector((0, -0.16, z)), "a": r[0] + 0.012, "b": r[1] + 0.012, "w": {"kopf": 1}} for z, r in ((H + 0.14, (0.06, 0.06)), (H + 0.22, (0.09, 0.085)), (H + 0.32, (0.08, 0.077)), (H + 0.37, (0.02, 0.02)))],
           10, F["haar"], 0, bogen=(math.radians(110), math.radians(250)), deckel=(False, True))
    for s in (1, -1):
        kegel(B, (s * 0.032, -0.235, H + 0.25), (s * 0.034, -0.252, H + 0.25), 0.014, 0.007, {"kopf": 1}, F["auge"], 6)
    kegel(B, (0, -0.25, H + 0.22), (0, -0.27, H + 0.205), 0.012, 0.003, {"kopf": 1}, F["kopf"], 5)
    # Flügel: Fächer aus Federn an Arm und Hand, die hinteren länger
    fx0, fy0, fx1, fy1 = F["feder"]
    for s, x in ((".l", 1), (".r", -1)):
        for i in range(9):
            u = i / 8
            wurzel = Vector((x * (0.1 + 0.72 * u), -0.02 + 0.08 * u, H + 0.1 + 0.02 * math.sin(u * 3)))
            laenge = 0.28 + 0.35 * math.sin(u * 2.4) + (0.15 if u > 0.8 else 0)
            spitze = wurzel + Vector((x * 0.12 * u, laenge, -0.04 - 0.05 * u))
            breit = 0.095
            w = {"fluegel" + s: 1 - u, "hand" + s: u} if u < 0.5 else {"hand" + s: 1}
            q = Vector((x * breit, 0, 0))
            uv = lambda a, b: (fx0 + a * (fx1 - fx0) * 0.5 + (0.5 if x < 0 else 0) * (fx1 - fx0), fy0 + b * (fy1 - fy0))
            B.flaeche([wurzel - q, wurzel + q, spitze + q * 0.4, spitze - q * 0.4], [uv(u, 0.1), uv(u + 0.1, 0.1), uv(u + 0.1, 0.95), uv(u, 0.95)], w, 0)
        # Krallen
        kette(B, [(x * 0.06, 0.08, H - 0.08), (x * 0.07, 0.06, H - 0.22), (x * 0.07, 0.02, H - 0.32)], [0.03, 0.018, 0.01], [{"leib": .5, "kralle" + s: .5}, {"kralle" + s: 1}, {"kralle" + s: 1}], F["kralle"], 6)
    # Schwanzfedern
    for i in range(5):
        a = (i - 2) * 0.18
        wurzel = Vector((0, 0.28, H - 0.02))
        spitze = wurzel + Vector((math.sin(a) * 0.3, 0.36 + 0.05 * (2 - abs(i - 2)), -0.1))
        q = Vector((0.04, 0, 0))
        B.flaeche([wurzel - q, wurzel + q, spitze + q * 0.5, spitze - q * 0.5], [(fx0 + 20, fy0 + 20), (fx0 + 60, fy0 + 20), (fx0 + 60, fy1 - 10), (fx0 + 20, fy1 - 10)], {"schwanz": 1}, 0)

    def flug(schlag, f_bob=1.0):
        def pose(t):
            f = 2 * math.pi * t
            sl = math.sin(f)
            return {"fluegel.l": [(Y, -schlag * sl)], "fluegel.r": [(Y, schlag * sl)], "hand.l": [(Y, -schlag * 0.6 * math.sin(f - 0.6))],
                    "hand.r": [(Y, schlag * 0.6 * math.sin(f - 0.6))], "_ort": (0, 0, 0.1 * math.sin(f * f_bob + 1.2)),
                    "schwanz": [(X, 0.12 * math.sin(f))], "kopf": [(X, -0.06 * math.sin(f))], "kralle.l": [(X, 0.2)], "kralle.r": [(X, 0.2)]}
        return pose
    bewegung(arm, "Idle_Combat", 24, flug(0.55))
    bewegung(arm, "Walking_D_Skeletons", 18, flug(0.7))
    bewegung(arm, "Running_A", 12, flug(0.85))
    def sturz(t):
        u = math.sin(math.pi * min(1.0, t * 1.3))
        return {"leib": [(X, 0.5 * u)], "kopf": [(X, -0.3 * u)], "fluegel.l": [(Y, 0.6 * u), (X, -0.4 * u)], "fluegel.r": [(Y, -0.6 * u), (X, -0.4 * u)],
                "kralle.l": [(X, -0.7 * u)], "kralle.r": [(X, -0.7 * u)], "_ort": (0, -0.35 * u, -0.25 * u)}
    bewegung(arm, "1H_Melee_Attack_Chop", 16, sturz, False)
    bewegung(arm, "Hit_A", 10, lambda t: {"leib": [(X, -0.3 * math.sin(math.pi * t))], "_ort": (0, 0.12 * math.sin(math.pi * t), 0.05 * math.sin(math.pi * t))}, False)
    def fall(t):
        u = min(1.0, t * 1.3)
        return {"root": [(Y, 1.2 * u)], "fluegel.l": [(Y, 0.9 * u)], "fluegel.r": [(Y, -0.9 * u)], "_ort": (0, 0, -(H - 0.2) * u * u)}
    bewegung(arm, "Death_C_Skeletons", 24, fall, False)
    ausgeben(arm, B, "Ba", tafel, tafel.replace(".png", "_glut.png"), os.path.join(ziel, "Ba.glb"),
             lambda bild, gb: [fabrik.material("geist", bild, 0.0, 0.6, glut=1.6, glutbild=gb)])


if __name__ == "__main__":
    wahl = sys.argv[1]
    ziel = sys.argv[2] if len(sys.argv) > 2 else os.path.join(WURZEL, "models", "chars")
    tmp = sys.argv[3] if len(sys.argv) > 3 else ziel
    for name, fn in (("Fuchs", fuchs), ("Skorpion", skorpion), ("Ba", ba)):
        if wahl in ("alle", name):
            fn(ziel, tmp)
