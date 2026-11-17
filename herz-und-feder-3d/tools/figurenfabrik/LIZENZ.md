# Lizenz der Figurenfabrik

Die Skripte in diesem Ordner (`fabrik.py`, `malen.py`, `gemalt.py`, `mensch.py`, `figuren.py`, `eidtraeger.py`, `hohler.py`) rufen die Python-Schnittstelle von
Blender (`bpy`) auf. Blender steht unter der GNU General Public License. Laut Blender Foundation müssen Skripte, die diese
Schnittstelle benutzen, unter einer GPL-verträglichen Lizenz stehen, sobald man sie veröffentlicht. Deshalb gilt für diese
Skripte: **GPL-3.0-or-later**.

Das betrifft nur die Werkzeuge. Was sie erzeugen, gehört dir:

- Die erzeugten Modelle (`models/chars/Eidtraeger.glb`, `models/chars/Hohler.glb`) und ihre Texturtafeln sind Ausgaben
  des Programms. Die Blender Foundation schreibt dazu: „What you create with Blender is your sole property.“
- Das Spiel selbst (Godot-Projekt, GDScript) benutzt Blender nicht und bleibt von der GPL unberührt.
- `probe.gd` und `probe.tscn` sind Godot-Dateien ohne Blender-Aufrufe.

Quellen: https://www.blender.org/about/license/ und https://www.blender.org/support/faq/ (Abschnitt „What about add-ons
or my Python scripts?“).

Skelett und Bewegungen stammen aus den KayKit-Figuren von Kay Lousberg (Adventurers, Skeletons), Lizenz CC0 1.0:
frei für jede Nutzung, auch gewerblich, ohne Namensnennung.
Die beiden Quelldateien dafür liegen unter `rigs/` (`Abenteurer.glb`, `Skelett.glb`) und werden nicht ins Spiel gepackt.
