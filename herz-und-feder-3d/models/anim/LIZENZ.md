# Lizenz der Bewegungssätze (`models/anim/`)

| Datei | Bewegungen | Herkunft | Lizenz |
|---|---|---|---|
| `eidtraeger.res`, `priester.res`, `jaegerin.res`, `sternleserin.res`, `gemeinsam.res`, `boss.res` | 42 (Liste in `BEWEGUNGSWERK.md`) | Quaternius, *Universal Animation Library* 1 und 2 (Standardfassung), übertragen mit `tools/bewegung/umrechnen.gd` | **CC0 1.0** (gemeinfrei): frei für jede Nutzung, auch gewerblich, Weitergabe und Veränderung erlaubt, ohne Namensnennung |

- Quaternius nennt die Lizenz auf der Seite des Pakets (quaternius.com/packs/universalanimationlibrary.html und
  …/universalanimationlibrary2.html, abgerufen über die Websuche am 25.11.2026) und auf OpenGameArt.
- Die Quelldateien (`UAL1_Standard.glb`, `UAL2_Standard.glb`) liegen **nicht** im Repo (je rund 8 MB, und das Spiel
  braucht nur die übertragenen Bewegungen). Geladen wurden sie in der Cloud-Sitzung über zwei voneinander unabhängige
  öffentliche Spiegel auf GitHub, weil quaternius.com und itch.io dort gesperrt waren; beide Spiegel lieferten Byte für
  Byte dieselbe Datei (SHA-256 `69591853…7997` und `8cee20ab…88a8`). Wer sie neu baut, lädt sie besser vom Original
  (quaternius.com, itch.io: „name your own price“, 0 € geht).
- Freiwilliger Dank, keine Pflicht: „Animationen: Quaternius (quaternius.com), CC0“.

Nicht eingecheckt und nicht einzuchecken: Mixamo-Bewegungen (Adobe verbietet die Weitergabe der Rohdateien),
Bandai-Namco-Datensatz (CC BY-NC 4.0, keine gewerbliche Nutzung), Bewegungen aus Modellen mit nicht-kommerziellen
Gewichten (GVHMR, Kimodo-SMPLX, HY-Motion außerhalb der EU) ohne eigene Prüfung. Siehe `BEWEGUNGSWERK.md`, Abschnitt 5.

Die Werkzeuge in `tools/bewegung/` (GDScript, Python ohne Blender) stehen unter derselben Lizenz wie das Spiel.
`pose_zu_bvh.py` benutzt MediaPipe (Google, Apache 2.0) nur beim Bauen.
