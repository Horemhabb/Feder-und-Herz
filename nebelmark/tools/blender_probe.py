# Machbarkeitstest für eine kostenlose Bildfabrik: freies CC0-Modell (KayKit Knight, github.com/KayKit-Game-Assets) mit Blender als Python-Modul
# (pip install bpy) aus der Spielkamera rendern, mit echten Bewegungsphasen. Aufruf im Ordner mit dl/Knight.glb: python blender_probe.py AUSGABEORDNER
import bpy, math, time, sys
t0 = time.time(); OUT = sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="dl/Knight.glb")
acts = sorted(a.name for a in bpy.data.actions); print(len(acts), "Bewegungen:", ", ".join(acts[:80]))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
s = bpy.context.scene; s.render.engine = "CYCLES"; s.cycles.samples = 24; s.cycles.device = "CPU"; s.cycles.use_denoising = False
s.render.resolution_x = s.render.resolution_y = 320; s.render.film_transparent = True; s.view_settings.view_transform = "Standard"
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); s.collection.objects.link(cam); s.camera = cam
cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.6
el = math.radians(35); d = 12
cam.location = (0, -d * math.cos(el), 1.05 + d * math.sin(el)); cam.rotation_euler = (math.radians(90) - el, 0, 0)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); s.collection.objects.link(sun); sun.data.energy = 3.2; sun.data.color = (0.75, 0.82, 1.0); sun.rotation_euler = (math.radians(50), 0, math.radians(-135))
fill = bpy.data.objects.new("fill", bpy.data.lights.new("fill", "SUN")); s.collection.objects.link(fill); fill.data.energy = 1.0; fill.data.color = (1.0, 0.72, 0.45); fill.rotation_euler = (math.radians(60), 0, math.radians(60))
w = bpy.data.worlds.new("w"); s.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.1, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
def pick(*keys):
    for k in keys:
        for a in acts:
            if k.lower() in a.lower(): return a
shots = [(pick("Idle"), 0.0), (pick("Walking_A", "Walk"), 0.15), (pick("Walking_A", "Walk"), 0.4), (pick("Walking_A", "Walk"), 0.65), (pick("Walking_A", "Walk"), 0.9), (pick("2H_Melee_Attack_Slice", "Melee_Attack_Slice", "Attack"), 0.3), (pick("2H_Melee_Attack_Slice", "Melee_Attack_Slice", "Attack"), 0.55), (pick("Death_A", "Death"), 0.95)]
arm.animation_data_create()
for i, (name, ph) in enumerate(shots):
    act = bpy.data.actions[name]; arm.animation_data.action = act
    try: arm.animation_data.action_slot = act.slots[0]
    except Exception: pass
    f0, f1 = act.frame_range; s.frame_set(int(f0 + (f1 - f0) * ph))
    arm.rotation_mode = "XYZ"; arm.rotation_euler = (0, 0, math.radians(45 if i < 8 else 0))   # Blick nach rechts unten im Bild
    s.render.filepath = f"{OUT}/k{i}.png"; bpy.ops.render.render(write_still=True)
print("fertig in", round(time.time() - t0, 1), "s; je Bild", round((time.time() - t0) / len(shots), 2), "s;", [n for n, _ in shots])
