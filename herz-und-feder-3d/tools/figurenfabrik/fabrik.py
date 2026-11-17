# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Figurenfabrik: baut aus Daten eine Figur für Herz und Feder.

Idee: Das Skelett und die Bewegungen stammen aus den KayKit-Figuren (CC0). Die Fabrik streckt dieses Skelett auf
menschliche Proportionen, überträgt die Bewegungen darauf (mit Bodenkontakt-Korrektur) und setzt einen neuen,
aus Querschnitten gedrehten Körper mit ägyptischer Tracht darauf. Jede weitere Figur ist nur ein neuer Bauplan.

Aufruf (Blender als Python-Modul, `pip install bpy pillow`):  python eidtraeger.py <KayKit.glb> <ziel.glb>
"""
import math
import bpy
import bmesh
from mathutils import Vector

DEFORM = ["root", "hips", "spine", "chest", "head"] + [b + s for s in (".l", ".r") for b in
          ("upperarm", "lowerarm", "wrist", "hand", "handslot", "upperleg", "lowerleg", "foot", "toes")]

_ALT = {}       # je Bewegung und Bild: tiefster Punkt des Körpers der Vorlage
_VORLAGE = []   # Körperteile der Vorlage (nur bis zum Umbau)


def lade_rig(glb, behalten):
    """KayKit-Figur laden; nur Skelett und die gewünschten Bewegungen bleiben."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 30
    bpy.ops.import_scene.gltf(filepath=glb)
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    _VORLAGE.clear()
    for o in list(bpy.data.objects):
        if o is arm:
            continue
        if o.type == 'MESH' and o.parent is arm and o.parent_bone == "" and any(m.type == 'ARMATURE' for m in o.modifiers):
            _VORLAGE.append(o)      # Leib der Vorlage: an ihm wird gemessen, wo der Boden ist
        else:
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        if a.name not in behalten:
            bpy.data.actions.remove(a)
    fehlen = [n for n in behalten if n not in bpy.data.actions]
    if fehlen:
        print("FEHLT:", fehlen)
    return arm


def _kurven(act):
    for layer in act.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    yield fc


def _setze(arm, act):
    arm.animation_data.action = act
    if act and act.slots:
        arm.animation_data.action_slot = act.slots[0]


def _tief(koerper, ohne=()):
    """Tiefster Punkt der verformten Körper im aktuellen Bild (ohne die Punkte, die an den Knochen `ohne` hängen)."""
    import numpy as np
    dg = bpy.context.evaluated_depsgraph_get()
    z = 1e9
    for ob in koerper:
        ev = ob.evaluated_get(dg)
        me = ev.to_mesh()
        co = np.empty(len(me.vertices) * 3, np.float32)
        me.vertices.foreach_get("co", co)
        zs = co.reshape(-1, 3)[:, 2]
        if ohne and ob.name not in _MASKEN:
            idx = {g.index for g in ob.vertex_groups if g.name in ohne}
            _MASKEN[ob.name] = np.array([not any(g.group in idx and g.weight > 0.5 for g in v.groups) for v in ob.data.vertices])
        if ohne:
            zs = zs[_MASKEN[ob.name]]
        z = min(z, float(zs.min()) + ob.matrix_world.translation.z)
        ev.to_mesh_clear()
    return z


_MASKEN = {}


def _bilder(act):
    return range(int(math.floor(act.frame_range[0])), int(math.ceil(act.frame_range[1])) + 1)


def _aufnahme(arm, act):
    """Vorlage vermessen: je Bild der tiefste Punkt des Leibs sowie Hüfte, Knie und Knöchel beider Beine."""
    sc = bpy.context.scene
    _setze(arm, act)
    tief, beine = {}, {}
    for f in _bilder(act):
        sc.frame_set(f)
        bpy.context.view_layer.update()
        tief[f] = _tief(_VORLAGE)
        beine[f] = {s: tuple(arm.pose.bones[b + s].head.copy() for b in ("upperleg", "lowerleg", "foot")) for s in (".l", ".r")}
    return tief, beine


def _beine_nachfuehren(arm, act, beine, l_alt):
    """Zweigelenk-IK: Jedes Bein zeigt in dieselbe Richtung und ist anteilig so weit gestreckt wie in der Vorlage, das Knie
    knickt in derselben Ebene, der Fuß behält seine Lage im Raum. So stehen beide Füße wieder gleich hoch, auch wenn
    Ober- und Unterschenkel jetzt anders lang sind als in der Vorlage."""
    sc = bpy.context.scene
    vl = bpy.context.view_layer
    _setze(arm, act)
    Y = Vector((0, 1, 0))
    davor = {}
    for f in _bilder(act):
        sc.frame_set(f)
        vl.update()
        for s in (".l", ".r"):
            up, lo, ft = (arm.pose.bones[b + s] for b in ("upperleg", "lowerleg", "foot"))
            U, L = up.bone.length, lo.bone.length
            h0, k0, a0 = beine[f][s]
            v = a0 - h0
            d = v.normalized()
            D = min(max(v.length / l_alt * (U + L), abs(U - L) + 1e-4), U + L - 1e-4)
            Ru, Rl, Rf = up.matrix.to_3x3(), lo.matrix.to_3x3(), ft.matrix.to_3x3()
            quer = (k0 - h0) - d * (k0 - h0).dot(d)
            if quer.length < 1e-4:
                quer = Ru @ Vector((0, 0, 1))
                quer = quer - d * quer.dot(d)
            quer.normalize()
            ca = (U * U + D * D - L * L) / (2 * U * D)
            sa = math.sqrt(max(0.0, 1.0 - ca * ca))
            hj = up.head.copy()
            kn = hj + (d * ca + quer * sa) * U
            an = hj + d * D
            for pb, R, von, nach in ((up, Ru, hj, kn), (lo, Rl, kn, an), (ft, Rf, an, None)):
                if nach is not None:
                    R = (R @ Y).normalized().rotation_difference((nach - von).normalized()).to_matrix() @ R
                M = R.to_4x4()
                M.translation = von
                pb.matrix = M
                pb.location = (0, 0, 0)
                q = pb.rotation_quaternion.copy()
                if pb.name in davor and davor[pb.name].dot(q) < 0:
                    q.negate()
                    pb.rotation_quaternion = q
                davor[pb.name] = q
                pb.keyframe_insert("rotation_quaternion", frame=f)
                vl.update()
    for fc in _kurven(act):
        if any(('"%s%s"' % (b, s)) in fc.data_path for b in ("upperleg", "lowerleg", "foot") for s in (".l", ".r")) and fc.data_path.endswith("rotation_quaternion"):
            for kp in list(fc.keyframe_points):
                if abs(kp.co.x - round(kp.co.x)) > 1e-3:
                    fc.keyframe_points.remove(kp)
                else:
                    kp.interpolation = 'LINEAR'
            fc.update()


def boden(arm, ob, k_luft=1.8, ohne=("handslot.l", "handslot.r")):
    """Stellt jede Bewegung auf den Boden: Je Bild wird das Becken so gehoben oder gesenkt, dass der tiefste Punkt des neuen
    Körpers dort liegt, wo der tiefste Punkt der Vorlage lag. Füße stehen, Liegende liegen, Sprünge bleiben Sprünge.
    Was in der Hand gehalten wird, zählt nicht mit (eine Schwertspitze darf den Boden berühren)."""
    sc = bpy.context.scene
    for a in bpy.data.actions:
        _setze(arm, a)
        neu = {}
        for f in _bilder(a):
            sc.frame_set(f)
            bpy.context.view_layer.update()
            neu[f] = _tief([ob], ohne)
        fc = next((c for c in _kurven(a) if c.data_path == 'pose.bones["hips"].location' and c.array_index == 1), None)
        if fc is None:
            print("ohne Beckenkurve:", a.name)
            continue
        for kp in fc.keyframe_points:
            f = min(max(int(round(kp.co.x)), min(neu)), max(neu))
            alt = _ALT[a.name][f]
            kp.co.y += (alt * k_luft if alt > 0 else alt) - neu[f]
            kp.interpolation = 'LINEAR'
        fc.update()
    _setze(arm, None)
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)
    sc.frame_set(0)
    bpy.context.view_layer.update()


def umbauen(arm, plan, k_weg, haltung=None):
    """Skelett auf neue Maße strecken und alle Bewegungen übertragen.
    plan: Knochen -> {"head": (x,y,z)} | {"an": True} | {"rel": (x,y,z)}, dazu "len". Richtungen und Rollwinkel bleiben,
    deshalb gelten alle Drehungen der Bewegungen unverändert weiter. k_weg streckt die Wege des Beckens."""
    acts = list(bpy.data.actions)
    beine = {}
    for a in acts:
        _ALT[a.name], beine[a.name] = _aufnahme(arm, a)
    for o in _VORLAGE:
        bpy.data.objects.remove(o, do_unlink=True)
    _VORLAGE.clear()
    l_alt = arm.data.bones["upperleg.l"].length + arm.data.bones["lowerleg.l"].length
    _setze(arm, None)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones

    def geh(b):
        s = plan.get(b.name)
        if s is None and b.name[-2:] == ".r":
            l = plan.get(b.name[:-2] + ".l")
            if l:
                s = {k: ((-v[0], v[1], v[2]) if k in ("head", "rel") else v) for k, v in l.items()}
        if s:
            d = (b.tail - b.head).normalized()
            b.use_connect = False
            if "head" in s:
                h = Vector(s["head"])
            elif "rel" in s:
                h = b.parent.head + Vector(s["rel"])
            else:
                h = b.parent.tail.copy()
            b.head = h
            b.tail = h + d * s.get("len", b.length)
        for c in b.children:
            geh(c)
    for b in [b for b in eb if b.parent is None]:
        geh(b)
    bpy.ops.object.mode_set(mode='OBJECT')
    for b in arm.data.bones:
        b.use_deform = b.name in DEFORM
    # Bewegungen: Wege von Becken und Wurzel strecken, Beine nachführen. Die Höhe über dem Boden stellt später boden() ein.
    for a in acts:
        for fc in _kurven(a):
            if fc.data_path in ('pose.bones["hips"].location', 'pose.bones["root"].location'):
                for kp in fc.keyframe_points:
                    kp.co.y *= k_weg
                    kp.handle_left.y *= k_weg
                    kp.handle_right.y *= k_weg
                fc.update()
        _beine_nachfuehren(arm, a, beine[a.name], l_alt)
    _setze(arm, None)
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()
    return {b.name: (b.head_local.copy(), b.tail_local.copy()) for b in arm.data.bones}


def neige(winkel):
    """Haltung ändern, ohne das Skelett anzufassen: dreht Knochen in jeder Bewegung um ihre Querachse (Grad, + = nach vorn).
    So bekommt ein Wesen einen Buckel oder einen vorgereckten Kopf, und alle Bewegungen gelten weiter."""
    from mathutils import Quaternion
    for a in bpy.data.actions:
        for name, grad in winkel.items():
            qh = Quaternion((1, 0, 0), math.radians(grad))
            fcs = {c.array_index: c for c in _kurven(a) if c.data_path == 'pose.bones["%s"].rotation_quaternion' % name}
            if len(fcs) < 4:
                continue
            for i in range(len(fcs[0].keyframe_points)):
                q = Quaternion([fcs[k].keyframe_points[i].co.y for k in range(4)]) @ qh
                for k in range(4):
                    kp = fcs[k].keyframe_points[i]
                    kp.co.y = q[k]
                    kp.interpolation = 'LINEAR'
            for k in range(4):
                fcs[k].update()


def _paar(x, cs):
    return (x[0] if cs >= 0 else x[1]) if isinstance(x, (tuple, list)) else x


def _spow(x, e):
    return math.copysign(abs(x) ** e, x)


def _lr(n):
    return n[:-2] + (".r" if n.endswith(".l") else ".l") if n[-2:] in (".l", ".r") else n


class Bau:
    """Sammelt Punkte, Flächen, Texturkoordinaten und Knochengewichte einer Figur."""

    def __init__(s, atlas=1024):
        s.v, s.uv, s.w, s.f = [], [], [], []
        s.atlas = atlas

    def punkt(s, p, uv, w):
        s.v.append(tuple(p))
        s.uv.append((uv[0] / s.atlas, 1.0 - uv[1] / s.atlas))
        s.w.append(dict(w))
        return len(s.v) - 1

    def loft(s, ringe, n, uv, mat, achse=(0, 0, 1), vorn=(0, -1, 0), start=math.pi, bogen=None, deckel=(False, False), p=2.0):
        """Körper aus Querschnitten. Ring: c Mitte, a Halbmesser nach vorn/hinten, b seitlich, w Gewichte (dict oder f(Winkel)),
        v Lage in der Textur 0..1, dz Versatz längs der Achse als f(Winkel), ax eigene Achse, p Eckigkeit.
        Winkel 0 zeigt nach `vorn`, 90° nach Achse × vorn. uv: (x0, y0, x1, y1) in Pixeln der Texturtafel."""
        m = n + 1
        erste = len(s.v)
        for ri, r in enumerate(ringe):
            ax = Vector(r.get("ax", achse)).normalized()
            e1 = Vector(r.get("vorn", vorn))
            e1 = (e1 - ax * e1.dot(ax)).normalized()
            e2 = ax.cross(e1)
            c = Vector(r["c"])
            vv = r.get("v", ri / max(1, len(ringe) - 1))
            pp = r.get("p", p)
            for i in range(m):
                t = i / n
                th = (start + t * 2 * math.pi) if bogen is None else (bogen[0] + t * (bogen[1] - bogen[0]))
                cs, sn = math.cos(th), math.sin(th)
                pos = c + e1 * (_paar(r["a"], cs) * _spow(cs, 2.0 / pp)) + e2 * (_paar(r["b"], sn) * _spow(sn, 2.0 / pp))
                if "dz" in r:
                    pos += ax * r["dz"](th)
                if "f" in r:
                    pos = r["f"](pos, th)
                w = r["w"](th) if callable(r["w"]) else r["w"]
                s.punkt(pos, (uv[0] + t * (uv[2] - uv[0]), uv[1] + vv * (uv[3] - uv[1])), w)
        for ri in range(len(ringe) - 1):
            for i in range(n):
                a = erste + ri * m + i
                s.f.append(((a, a + 1, a + m + 1, a + m), mat))
        for seite, ri in ((0, 0), (1, len(ringe) - 1)):
            if deckel[seite]:
                ids = [erste + ri * m + i for i in range(m)]
                c = sum((Vector(s.v[i]) for i in ids[:-1]), Vector()) / n
                w = {}
                for i in ids[:-1]:
                    for k, x in s.w[i].items():
                        w[k] = w.get(k, 0) + x / n
                uvm = (uv[0] + 0.5 * (uv[2] - uv[0]), uv[1] + ringe[ri].get("v", float(seite)) * (uv[3] - uv[1]))
                ci = s.punkt(c, uvm, w)
                for i in range(n):
                    s.f.append(((ids[i], ids[i + 1], ci), mat))

    def flaeche(s, pts, uvs, w, mat):
        """Einzelnes Vieleck (Feder, Klinge)."""
        ids = [s.punkt(p, uv, w if isinstance(w, dict) else w[i]) for i, (p, uv) in enumerate(zip(pts, uvs))]
        s.f.append((tuple(ids), mat))

    def spiegel(s, fn):
        """Baut ein Teil für die linke Seite und setzt es gespiegelt auch rechts an."""
        fn(s)
        t = Bau(s.atlas)
        fn(t)
        off = len(s.v)
        for v, uv, w in zip(t.v, t.uv, t.w):
            s.v.append((-v[0], v[1], v[2]))
            s.uv.append(uv)
            s.w.append({_lr(k): x for k, x in w.items()})
        for ids, mat in t.f:
            s.f.append((tuple(off + i for i in reversed(ids)), mat))

    def mesh(s, name, arm, mats):
        me = bpy.data.meshes.new(name)
        me.from_pydata(s.v, [], [f[0] for f in s.f])
        for m in mats:
            me.materials.append(m)
        uvl = me.uv_layers.new(name="UVMap")
        for poly, (ids, mat) in zip(me.polygons, s.f):
            poly.material_index = mat
            poly.use_smooth = True
            for li in poly.loop_indices:
                uvl.data[li].uv = s.uv[me.loops[li].vertex_index]
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        gruppen = {}
        for i, w in enumerate(s.w):
            tot = sum(w.values()) or 1.0
            for k, x in w.items():
                if x <= 0.0:
                    continue
                if k not in gruppen:
                    gruppen[k] = ob.vertex_groups.new(name=k)
                gruppen[k].add([i], x / tot, 'REPLACE')
        ob.parent = arm
        mod = ob.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm
        return ob


def material(name, bild, metall=0.0, rau=0.85, glut=0.0, beidseitig=True, glutbild=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bild
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = metall
    bsdf.inputs["Roughness"].default_value = rau
    if glut > 0.0:
        gt = tex
        if glutbild is not None:
            gt = nt.nodes.new("ShaderNodeTexImage")
            gt.image = glutbild
        nt.links.new(gt.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = glut
    m.use_backface_culling = not beidseitig
    return m


def ausgabe(pfad):
    bpy.ops.export_scene.gltf(filepath=pfad, export_format='GLB', export_animations=True, export_animation_mode='ACTIONS',
                              export_def_bones=True, export_image_format='WEBP', export_image_quality=88,
                              export_optimize_animation_size=True, export_skins=True, export_yup=True,
                              export_materials='EXPORT', export_apply=False)


def lerp(a, b, t):
    return Vector(a) + (Vector(b) - Vector(a)) * t
