"""Gelenkpunkte zu BVH: der Mittelteil der Ketten „Video → Bewegung“, „Standbild → Pose“ und „Text → Bewegung“.

Eingaben (eine davon):
  * Video (.mp4 .mov .webm .gif .avi) oder ein Ordner mit Einzelbildern: MediaPipe Pose (Google, Apache 2.0) schätzt
    je Bild 33 Punkte im Raum, auf dem Prozessor, ohne Grafikkarte.
  * ein einzelnes Bild (.png .jpg .webp): eine Haltung (ein Bild BVH), z. B. eine Schlüsselpose aus ComfyUI.
  * .npy mit Form (Bilder, 22, 3): Gelenke im HumanML3D-Format, wie sie MoMask, T2M-GPT, MDM und andere
    Text-zu-Bewegung-Modelle ausgeben (Y oben, Meter, 20 Bilder je Sekunde).
  * .json {"fps": 30, "namen": [...], "bilder": [[[x, y, z], ...], ...]} mit eigenen Punktnamen (siehe PUNKTE).

Ausgabe: BVH mit T-Haltung als Ruhelage und SMPL-artigen Knochennamen (Pelvis, L_Hip, L_Knee …). Diese Datei liest der
Umrechner im Spiel (tools/bewegung/umrechnen.gd, Karte "smpl") und Blender.

Was das Skript tut: glätten (Zittern der Schätzung), Füße auf den Boden (die Schätzung kennt keinen Boden), Blick nach
+Z drehen, Knochenlängen festhalten (Mittelwert über alle Bilder), Drehungen aus den Richtungen der Glieder berechnen,
wahlweise das Ende weich an den Anfang führen (Schleife).

Aufruf:
  python pose_zu_bvh.py EINGABE AUSGABE.bvh [--modell pose_landmarker_heavy.task] [--fps 30] [--glaetten 1.5]
                        [--schleife 8] [--ohne_boden] [--punkte_json punkte.json]

Abhängigkeiten: numpy; für Bilder und Videos zusätzlich mediapipe (enthält OpenCV). Lizenz dieses Skripts: wie das Spiel.
"""
import argparse
import json
import math
import os
import sys

import numpy as np

# Unsere Gelenke: Name → Eltern. Reihenfolge = Reihenfolge im BVH.
SKELETT = [
    ("Pelvis", None), ("Spine1", "Pelvis"), ("Spine3", "Spine1"), ("Neck", "Spine3"), ("Head", "Neck"),
    ("L_Shoulder", "Spine3"), ("L_Elbow", "L_Shoulder"), ("L_Wrist", "L_Elbow"),
    ("R_Shoulder", "Spine3"), ("R_Elbow", "R_Shoulder"), ("R_Wrist", "R_Elbow"),
    ("L_Hip", "Pelvis"), ("L_Knee", "L_Hip"), ("L_Ankle", "L_Knee"), ("L_Foot", "L_Ankle"),
    ("R_Hip", "Pelvis"), ("R_Knee", "R_Hip"), ("R_Ankle", "R_Knee"), ("R_Foot", "R_Ankle"),
]
# Glieder: Gelenk → Punkt, auf den der Knochen zeigt, und Richtung in der T-Haltung
GLIEDER = {
    "L_Shoulder": ("L_Elbow", (1, 0, 0)), "L_Elbow": ("L_Wrist", (1, 0, 0)), "L_Wrist": ("L_Hand", (1, 0, 0)),
    "R_Shoulder": ("R_Elbow", (-1, 0, 0)), "R_Elbow": ("R_Wrist", (-1, 0, 0)), "R_Wrist": ("R_Hand", (-1, 0, 0)),
    "L_Hip": ("L_Knee", (0, -1, 0)), "L_Knee": ("L_Ankle", (0, -1, 0)), "L_Ankle": ("L_Foot", None),
    "R_Hip": ("R_Knee", (0, -1, 0)), "R_Knee": ("R_Ankle", (0, -1, 0)), "R_Ankle": ("R_Foot", None),
}

# MediaPipe Pose: Nummern der 33 Punkte
MP = {"nase": 0, "ohr_l": 7, "ohr_r": 8, "L_Shoulder": 11, "R_Shoulder": 12, "L_Elbow": 13, "R_Elbow": 14,
      "L_Wrist": 15, "R_Wrist": 16, "L_Hand": 19, "R_Hand": 20, "L_Hip": 23, "R_Hip": 24, "L_Knee": 25,
      "R_Knee": 26, "L_Ankle": 27, "R_Ankle": 28, "L_Ferse": 29, "R_Ferse": 30, "L_Foot": 31, "R_Foot": 32}
# HumanML3D / SMPL, 22 Gelenke
H3D = {"Pelvis": 0, "L_Hip": 1, "R_Hip": 2, "Spine1": 3, "L_Knee": 4, "R_Knee": 5, "Spine2": 6, "L_Ankle": 7,
       "R_Ankle": 8, "Spine3": 9, "L_Foot": 10, "R_Foot": 11, "Neck": 12, "L_Collar": 13, "R_Collar": 14,
       "Head": 15, "L_Shoulder": 16, "R_Shoulder": 17, "L_Elbow": 18, "R_Elbow": 19, "L_Wrist": 20, "R_Wrist": 21}


def norm(v):
    n = np.linalg.norm(v, axis=-1, keepdims=True)
    return v / np.maximum(n, 1e-9)


def mediapipe_punkte(pfad, modell, fps_wunsch, einzeln=False):
    """Liefert (Punkte als dict Name → Array (Bilder, 3), fps, Sichtbarkeit je Bild)."""
    import mediapipe as mp
    from mediapipe.tasks import python as mpt
    from mediapipe.tasks.python import vision
    import cv2

    bilder = []
    fps = fps_wunsch
    if os.path.isdir(pfad):
        for n in sorted(os.listdir(pfad)):
            if n.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
                bilder.append(os.path.join(pfad, n))
        quelle = "ordner"
    elif pfad.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
        bilder = [pfad]
        quelle = "bild"
    else:
        quelle = "video"
    opt = vision.PoseLandmarkerOptions(
        base_options=mpt.BaseOptions(model_asset_path=modell),
        running_mode=vision.RunningMode.IMAGE if quelle == "bild" or einzeln else vision.RunningMode.VIDEO,
        num_poses=1, min_pose_detection_confidence=0.05 if einzeln or quelle == "bild" else 0.3,
        min_pose_presence_confidence=0.05 if einzeln or quelle == "bild" else 0.5, min_tracking_confidence=0.3)
    welt = []
    sicht = []

    def auswerten(rgb, zeit_ms):
        img = mp.Image(image_format=mp.ImageFormat.SRGB, data=np.ascontiguousarray(rgb))
        erg = lm.detect(img) if quelle == "bild" or einzeln else lm.detect_for_video(img, zeit_ms)
        if not erg.pose_world_landmarks:
            welt.append(None)
            sicht.append(0.0)
            return
        p = erg.pose_world_landmarks[0]
        welt.append(np.array([[q.x, q.y, q.z] for q in p]))
        sicht.append(float(np.mean([q.visibility for q in p])))

    with vision.PoseLandmarker.create_from_options(opt) as lm:
        if quelle == "video":
            cap = cv2.VideoCapture(pfad)
            fps = cap.get(cv2.CAP_PROP_FPS) or fps_wunsch
            i = 0
            while True:
                ok, bgr = cap.read()
                if not ok:
                    break
                auswerten(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB), int(i * 1000 / fps))
                i += 1
        else:
            for i, b in enumerate(bilder):
                from PIL import Image, ImageEnhance, ImageOps
                bild = Image.open(b).convert("RGB")
                if einzeln or quelle == "bild":
                    # gemalte Bilder (dunkler Grund, Streiflicht): aufhellen und verkleinern hilft der Erkennung
                    bild = ImageEnhance.Brightness(ImageOps.autocontrast(bild, cutoff=2)).enhance(1.6)
                    bild.thumbnail((512, 512))
                rgb = np.array(bild)
                auswerten(rgb, int(i * 1000 / fps))
    # Prüfung: Steht die geschätzte Person aufrecht? (Bei Gemälden und schwacher Erkennung liefert MediaPipe manchmal eine
    # auf den Kopf gestellte Pose.) Solche Bilder werden verworfen und gemeldet. Nur bei Standbildern: im Video darf
    # die Figur liegen (Sterben, Rolle).
    for i, w in enumerate(welt):
        if w is not None and (einzeln or quelle == "bild"):
            hoch = (w[11] + w[12]) / 2 - (w[23] + w[24]) / 2   # Schultermitte minus Hüftmitte, y zeigt hier nach unten
            if hoch[1] > -0.15:
                print("Bild %d: Pose liegt oder steht kopf (Sichtbarkeit %.2f), verworfen" % (i, sicht[i]))
                welt[i] = None
    gefunden = [w for w in welt if w is not None]
    if not gefunden:
        sys.exit("Keine Person erkannt.")
    # Lücken (keine Person erkannt) mit dem letzten Fund füllen
    letzte = gefunden[0]
    voll = []
    for w in welt:
        letzte = w if w is not None else letzte
        voll.append(letzte)
    a = np.stack(voll)                       # (Bilder, 33, 3); x rechts im Bild, y unten, z zur Kamera kleiner
    a = a * np.array([1.0, -1.0, -1.0])      # um 180° um x drehen: y oben (Drehung, keine Spiegelung)
    pkt = {k: a[:, i] for k, i in MP.items()}
    pkt["Pelvis"] = (pkt["L_Hip"] + pkt["R_Hip"]) / 2
    schulter = (pkt["L_Shoulder"] + pkt["R_Shoulder"]) / 2
    pkt["Spine1"] = pkt["Pelvis"] + (schulter - pkt["Pelvis"]) * 0.3
    pkt["Spine3"] = pkt["Pelvis"] + (schulter - pkt["Pelvis"]) * 0.8
    pkt["Neck"] = schulter
    ohren = (pkt["ohr_l"] + pkt["ohr_r"]) / 2
    pkt["Head"] = schulter + (ohren - schulter) * 0.6
    pkt["Kopf_quer"] = pkt["ohr_l"] - pkt["ohr_r"]
    pkt["Kopf_vorn"] = pkt["nase"] - ohren
    return pkt, fps, sicht


def h3d_punkte(pfad):
    a = np.load(pfad)
    if a.ndim == 4:
        a = a[0]
    if a.shape[-1] != 3 or a.shape[1] < 22:
        sys.exit("Erwartet (Bilder, 22, 3), gefunden %s" % (a.shape,))
    pkt = {k: a[:, i] for k, i in H3D.items()}
    # Hände: Unterarm verlängern
    for s in "LR":
        pkt[s + "_Hand"] = pkt[s + "_Wrist"] + (pkt[s + "_Wrist"] - pkt[s + "_Elbow"]) * 0.35
    return pkt, 20.0


def glaetten(pkt, sigma):
    if sigma <= 0:
        return pkt
    r = int(math.ceil(sigma * 2.5))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    aus = {}
    for n, v in pkt.items():
        p = np.pad(v, ((r, r), (0, 0)), mode="edge")
        aus[n] = np.stack([np.convolve(p[:, d], k, mode="valid") for d in range(3)], axis=1)
    return aus


def drehung_aus_achsen(x, y):
    """Drehmatrix (Bilder, 3, 3) aus einer Querachse x und einer Hochachse y (y wird senkrecht zu x gemacht)."""
    x = norm(x)
    y = norm(y - x * np.sum(x * y, axis=-1, keepdims=True))
    z = np.cross(x, y)
    return np.stack([x, y, z], axis=-1)


def bogen(a, b):
    """Kürzeste Drehung (Matrizen) von Richtungen a nach b, je Bild."""
    a, b = norm(a), norm(b)
    v = np.cross(a, b)
    c = np.sum(a * b, axis=-1)
    s = np.linalg.norm(v, axis=-1)
    R = np.zeros(a.shape[:-1] + (3, 3))
    for i in range(a.shape[0]):
        if s[i] < 1e-8:
            R[i] = np.eye(3) if c[i] > 0 else -np.eye(3) + 2 * np.outer(*([np.array([0, 1.0, 0])] * 2))
            continue
        k = v[i] / s[i]
        K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
        ang = math.atan2(s[i], c[i])
        R[i] = np.eye(3) + math.sin(ang) * K + (1 - math.cos(ang)) * K @ K
    return R


def euler_zxy(R):
    """Matrix → BVH-Winkel Z, X, Y in Grad (R = Rz · Rx · Ry)."""
    x = np.arcsin(np.clip(R[:, 2, 1], -1, 1))
    z = np.arctan2(-R[:, 0, 1], R[:, 1, 1])
    y = np.arctan2(-R[:, 2, 0], R[:, 2, 2])
    return np.degrees(np.stack([z, x, y], axis=1))


def bvh_schreiben(pkt, fps, aus, boden=True, schleife=0, drehung=None, je_bild=False):
    T = pkt["Pelvis"].shape[0]
    # Blick nach +Z. drehung: wie weit die Person zur Kamera gedreht steht (Grad, links herum positiv), falls bekannt;
    # sonst aus der Hüftlinie des ersten Bildes (bei Kampfhaltungen mit seitlich gestellter Hüfte ungenauer)
    if drehung is None:
        quer = pkt["L_Hip"][0] - pkt["R_Hip"][0]
        vorn = np.cross(quer, [0, 1.0, 0])
        winkel = math.atan2(vorn[0], vorn[2])
    else:
        winkel = math.radians(drehung)
    def dreh_y(w):
        c, s = math.cos(-w), math.sin(-w)
        return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])

    if je_bild:
        # Schlüsselposen aus verschiedenen Bildern: jede für sich nach vorn drehen (Blickwinkel des Malers egal)
        for t in range(T):
            quer = pkt["L_Hip"][t] - pkt["R_Hip"][t]
            vorn = np.cross(quer, [0, 1.0, 0])
            R = dreh_y(math.atan2(vorn[0], vorn[2]))
            for n in pkt:
                pkt[n][t] = pkt[n][t] @ R.T
    else:
        R = dreh_y(winkel)
        pkt = {n: v @ R.T for n, v in pkt.items()}
    # Boden: der tiefste Fußpunkt je Bild liegt auf dem Boden (weich, damit Sprünge nicht ganz verschwinden)
    fusspunkte = [n for n in ("L_Foot", "R_Foot", "L_Ankle", "R_Ankle", "L_Ferse", "R_Ferse") if n in pkt]
    if boden:
        tief = np.min(np.stack([pkt[n][:, 1] for n in fusspunkte], axis=1), axis=1)
        tief = glaetten({"t": np.stack([tief] * 3, axis=1)}, 2.0)["t"][:, 0]
        for n in pkt:
            if n not in ("Kopf_quer", "Kopf_vorn"):
                pkt[n] = pkt[n] - np.stack([np.zeros(T), tief, np.zeros(T)], axis=1)
    if schleife > 1 and T > schleife:
        for n in pkt:
            d = pkt[n][0] - pkt[n][-1]
            w = np.clip((np.arange(T) - (T - schleife)) / (schleife - 1), 0, 1)[:, None]
            pkt[n] = pkt[n] + d * w
    # Weltdrehungen je Gelenk
    W = {}
    W["Pelvis"] = drehung_aus_achsen(pkt["L_Hip"] - pkt["R_Hip"], pkt["Spine1"] - pkt["Pelvis"])
    schulter_quer = pkt["L_Shoulder"] - pkt["R_Shoulder"]
    W["Spine1"] = drehung_aus_achsen((pkt["L_Hip"] - pkt["R_Hip"]) * 0.5 + schulter_quer * 0.5, pkt["Spine3"] - pkt["Spine1"])
    W["Spine3"] = drehung_aus_achsen(schulter_quer, pkt["Neck"] - pkt["Spine3"])
    W["Neck"] = drehung_aus_achsen(schulter_quer, pkt["Head"] - pkt["Neck"])
    if "Kopf_quer" in pkt:
        W["Head"] = drehung_aus_achsen(pkt["Kopf_quer"], np.cross(pkt["Kopf_vorn"], pkt["Kopf_quer"]))
    else:
        W["Head"] = W["Neck"]
    # Fußrichtung in Ruhe: wie im Stand gemessen (Ballen vor und unter dem Knöchel), Mittel beider Füße
    fd = np.concatenate([norm(pkt["L_Foot"] - pkt["L_Ankle"]), norm(pkt["R_Foot"] - pkt["R_Ankle"])])
    fd_ruhe = norm(np.array([0.0, np.median(fd[:, 1]), math.sqrt(max(0.05, 1 - np.median(fd[:, 1]) ** 2))]))
    eltern = dict(SKELETT)
    for gel, (ziel, ruhe) in GLIEDER.items():
        r = np.array(fd_ruhe if ruhe is None else ruhe, dtype=float)
        P = W[eltern[gel]]
        mitgetragen = np.einsum("tij,j->ti", P, r)
        W[gel] = np.einsum("tij,tjk->tik", bogen(mitgetragen, pkt[ziel] - pkt[gel]), P)
    for s in "LR":
        W[s + "_Foot"] = W[s + "_Ankle"]
    # Versätze der Ruhelage: Längen als Median, Richtungen der T-Haltung (Glieder) bzw. im Elternraum gemessen
    def laenge(a, b):
        return float(np.median(np.linalg.norm(pkt[b] - pkt[a], axis=1)))

    ver = {"Pelvis": np.zeros(3)}
    for gel, el in SKELETT[1:]:
        if el in GLIEDER and GLIEDER[el][0] == gel:
            r = GLIEDER[el][1]
            ver[gel] = np.array(fd_ruhe if r is None else r, dtype=float) * laenge(el, gel)
        else:
            # z. B. Hüfte und Schulter: Lage im Raum des Elternteils, Median über alle Bilder
            lokal = np.einsum("tji,tj->ti", W[el], pkt[gel] - pkt[el])
            ver[gel] = np.median(lokal, axis=0)
    # Ruhelage steht auf dem Boden: Becken so hoch wie Hüftversatz + Oberschenkel + Schienbein + Knöchelhöhe im Stand
    knoechel = np.concatenate([pkt["L_Ankle"][:, 1], pkt["R_Ankle"][:, 1]])
    knoechel_hoehe = float(np.percentile(knoechel, 10)) if boden else 0.08
    ver["Pelvis"] = np.array([0.0, -ver["L_Hip"][1] + laenge("L_Hip", "L_Knee") + laenge("L_Knee", "L_Ankle") + knoechel_hoehe, 0.0])
    with open(aus, "w") as f:
        f.write("HIERARCHY\n")
        kinder = {}
        for g, e in SKELETT:
            kinder.setdefault(e, []).append(g)

        def schreib(g, tiefe):
            ein = "  " * tiefe
            o = ver[g]
            f.write("%s%s %s\n%s{\n" % (ein, "ROOT" if tiefe == 0 else "JOINT", g, ein))
            f.write("%s  OFFSET %.5f %.5f %.5f\n" % (ein, o[0], o[1], o[2]))
            if tiefe == 0:
                f.write("%s  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation\n" % ein)
            else:
                f.write("%s  CHANNELS 3 Zrotation Xrotation Yrotation\n" % ein)
            for k in kinder.get(g, []):
                schreib(k, tiefe + 1)
            if g not in kinder:
                f.write("%s  End Site\n%s  {\n%s    OFFSET 0 0 0\n%s  }\n" % (ein, ein, ein, ein))
            f.write("%s}\n" % ein)

        schreib("Pelvis", 0)
        f.write("MOTION\nFrames: %d\nFrame Time: %.6f\n" % (T, 1.0 / fps))
        winkel = {}
        for g, e in SKELETT:
            L = W[g] if e is None else np.einsum("tji,tjk->tik", W[e], W[g])
            winkel[g] = euler_zxy(L)
        for t in range(T):
            werte = list(pkt["Pelvis"][t])
            for g, _ in SKELETT:
                werte += list(winkel[g][t])
            f.write(" ".join("%.4f" % v for v in werte) + "\n")
    return T, pkt


LINIEN = [("Pelvis", "Spine1"), ("Spine1", "Spine3"), ("Spine3", "Neck"), ("Neck", "Head"),
          ("Spine3", "L_Shoulder"), ("L_Shoulder", "L_Elbow"), ("L_Elbow", "L_Wrist"),
          ("Spine3", "R_Shoulder"), ("R_Shoulder", "R_Elbow"), ("R_Elbow", "R_Wrist"),
          ("Pelvis", "L_Hip"), ("L_Hip", "L_Knee"), ("L_Knee", "L_Ankle"), ("L_Ankle", "L_Foot"),
          ("Pelvis", "R_Hip"), ("R_Hip", "R_Knee"), ("R_Knee", "R_Ankle"), ("R_Ankle", "R_Foot")]


def vorschau(pkt, pfad, n=8):
    """Strichmännchen zum schnellen Prüfen ohne Godot: oben von vorn, unten von der Seite; links blau, rechts rot."""
    from PIL import Image, ImageDraw
    T = pkt["Pelvis"].shape[0]
    n = min(n, T)
    w, h = 160, 220
    bild = Image.new("RGB", (w * n, h * 2), (32, 34, 40))
    d = ImageDraw.Draw(bild)
    for k in range(n):
        t = int(round(k * (T - 1) / max(1, n - 1)))
        for reihe, achse in ((0, 0), (1, 2)):
            ox, oy = k * w + w // 2, reihe * h + h - 15
            d.line([(k * w + 5, oy), (k * w + w - 5, oy)], fill=(90, 90, 90))
            for a, b in LINIEN:
                if a not in pkt or b not in pkt:
                    continue
                pa, pb = pkt[a][t], pkt[b][t]
                farbe = (110, 150, 255) if "L_" in a + b else ((255, 110, 110) if "R_" in a + b else (230, 230, 230))
                d.line([(ox + pa[achse] * 90, oy - pa[1] * 90), (ox + pb[achse] * 90, oy - pb[1] * 90)], fill=farbe, width=3)
        d.text((k * w + 6, 4), "Bild %d" % t, fill=(200, 200, 200))
    bild.save(pfad)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("eingabe")
    ap.add_argument("ausgabe")
    ap.add_argument("--modell", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "pose_landmarker_heavy.task"))
    ap.add_argument("--fps", type=float, default=30.0)
    ap.add_argument("--glaetten", type=float, default=1.5, help="Glättung in Bildern (0 = aus)")
    ap.add_argument("--schleife", type=int, default=0, help="letzte N Bilder weich an den Anfang führen")
    ap.add_argument("--ohne_boden", action="store_true")
    ap.add_argument("--drehung", type=float, default=None, help="Drehung der Person zur Kamera in Grad (sonst aus der Hüfte)")
    ap.add_argument("--einzeln", action="store_true", help="Ordner mit Schlüsselposen: jedes Bild für sich (kein Video), nicht glätten")
    ap.add_argument("--vorschau", default="", help="Strichmännchen als PNG zum Prüfen")
    ap.add_argument("--punkte_json", default="", help="geschätzte Punkte zusätzlich als JSON speichern")
    a = ap.parse_args()
    e = a.eingabe.lower()
    if e.endswith(".npy"):
        pkt, fps = h3d_punkte(a.eingabe)
    elif e.endswith(".json"):
        d = json.load(open(a.eingabe))
        arr = np.array(d["bilder"], dtype=float)
        pkt = {n: arr[:, i] for i, n in enumerate(d["namen"])}
        fps = float(d.get("fps", a.fps))
    else:
        pkt, fps, sicht = mediapipe_punkte(a.eingabe, a.modell, a.fps, a.einzeln)
        if a.einzeln:
            a.glaetten = 0.0
        print("Bilder: %d, mittlere Sichtbarkeit %.2f" % (len(sicht), float(np.mean(sicht))))
    if pkt["Pelvis"].shape[0] > 1:
        pkt = glaetten(pkt, a.glaetten)
    if a.punkte_json:
        namen = sorted(pkt)
        json.dump({"fps": fps, "namen": namen, "bilder": np.stack([pkt[n] for n in namen], axis=1).round(4).tolist()},
                  open(a.punkte_json, "w"))
    T, fertig = bvh_schreiben(pkt, fps, a.ausgabe, boden=not a.ohne_boden, schleife=a.schleife, drehung=a.drehung, je_bild=a.einzeln)
    if a.vorschau:
        vorschau(fertig, a.vorschau)
        print("Vorschau: %s" % a.vorschau)
    print("BVH geschrieben: %s (%d Bilder, %.0f fps)" % (a.ausgabe, T, fps))


if __name__ == "__main__":
    main()
