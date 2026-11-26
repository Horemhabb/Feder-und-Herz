# Feder und Herz: Übergabeseite für Sitzungen

Kurz halten und aktuell halten. Wer hier etwas ändert, das nicht mehr stimmt, berichtigt es sofort.

## Was wo liegt

- `herz-und-feder-3d/`: **das Spiel** (Godot 4.7.2, GDScript, Renderer GL Compatibility, Web-Export ohne Threads).
- `nebelmark/`: die frühere HTML-Fassung. Nur Herkunft, nicht weiterentwickeln.
- `herz-und-feder-3d/FAHRPLAN.md`: **was als Nächstes dran ist** und was bewusst nicht getan wird. Vor neuer Arbeit lesen.
- `herz-und-feder-3d/BILDWERK.md`: Bilder aus ComfyUI (Werkzeuge in `tools/bildwerk/`, laufen auf dem Windows-PC des Auftraggebers unter `C:\CF`).
- `herz-und-feder-3d/NACHTSCHICHTEN.md`: die geplanten ComfyUI-Nächte (`bildwerk.bat nacht <n>`), Befehle in Häppchen, offene Einbaustellen im Spiel.
- `herz-und-feder-3d/WERKSTATT.md`: Figurenfabrik (Blender-Python, `tools/figurenfabrik/`).
- `herz-und-feder-3d/GEGNERFABRIK.md`: vom ComfyUI-Entwurf zum 3D-Gegner (Vorlagenbogen, Bild-zu-3D, `tools/gegnerfabrik/aus_netz.py`). Bild-zu-3D ist auf der AMD-Karte noch ungeprüft.
- `herz-und-feder-3d/BEWEGUNGSWERK.md`: neue Bewegungen (CC0-Bibliothek, Umrechner in `tools/bewegung/`, fertige Sätze in `models/anim/`, eingehängt über `scripts/bewegungen.gd`).
- `herz-und-feder-3d/SPEC_4.0.md`, `LIESMICH.md`: Stand der Fassung 4.0 und Verlauf.
- `herz-und-feder-3d/GESCHICHTE.md`: die Geschichte (Neufassung 4.3 als Thriller: Bauplan, Stunden, Entscheidungen, Enden); `SZENEN.md`: Drehbuch der Zwischensequenzen.

## Aufbau des Codes (`herz-und-feder-3d/scripts/`)

Alles wird im Code gebaut, `main.tscn` enthält nur einen Knoten. Seit 4.2: Hüterkämpfe in `hueter.gd` (Angriffsfolge Ansage → Ausführung → Erholung), Eigenschaften der Champions in `affixe.gd`, Körperschicht (Neigen, Haltung, Blick) in `koerper.gd`, Ragdoll und Scherben in `physik.gd`, Bewegungsprofile je Klasse in `klassen.gd › GANG`. Oberfläche seit 4.3 als Gestaltungssystem in `zier.gd` (Rahmen, Knöpfe, Kartusche, Zierleisten; Grafiken erzeugt `tools/ui/zier.py` nach `ui/zier/`, gemalte Flächen nach `tools/bildwerk/wunsch_ui.md`). Kleintiere und Vögel seit 4.3 in `tiere.gd` (Gestalt), `tier.gd` (Verhalten), `tiere.gdshader` (Bewegung), Zubehör und Körperschicht der Leute in `leute.gd` (siehe `WERKSTATT.md` 3e). Große Dateien: `main.gd` (2.400 Zeilen, soll zerlegt werden), `hud.gd`, `foe.gd`, `orte.gd`. Texte der Geschichte: `geschichte.gd`, `stunden.gd`, `worte.gd`; Zwischensequenzen: `szene.gd` (Ablauf, Ersatz ohne Bild), Daten in `szenen.gd`, Bilder unter `ui/szenen/`, Fotos mit `-- --neu --szenenfotos --aus=/pfad`. Die Skripte greifen über `game` (untypisiert) auf `main.gd` zu: Tippfehler fallen erst zur Laufzeit auf, darum immer den Spieltest laufen lassen.

## Prüfen

```
bash herz-und-feder-3d/tools/hol_godot.sh        # lädt Godot nach herz-und-feder-3d/.godot-bin (einmal)
cd herz-und-feder-3d
.godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --import
.godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path . -- --neu --playtest --seed=1
```

Erwartet: `SPIELTEST: … ok, 0 Fehler`, Rückgabewert 0, kein `SCRIPT ERROR` (etwa 75 Sekunden). Derselbe Test läuft in `.github/workflows/bauen.yml` bei jedem Pull Request und vor jeder Veröffentlichung. Laufen mehrere Godot-Läufe zugleich (mehrere Agenten), teilen sie sich den Spielstandordner und stören einander: dann jeden Lauf mit eigenem `XDG_DATA_HOME=/tmp/…` starten. Der Bosstest ist unter Last wacklig (einzelne Prüfungen scheitern, wenn mehrere Godot-Läufe zugleich rechnen): in Ruhe wiederholen, Teile mit `--nur=mahaf,koenig,…`. Weitere Läufe: `--klassentest`, `--bosstest`, `--autotest` (brauchen einen Bildschirm: `xvfb-run -a … --rendering-driver opengl3`).

## Regeln

- Der Auftraggeber ist kein Programmierer und hat wenig Zeit: kleine Schritte, Deutsch, klare Anweisungen zum Ausprobieren.
- Jede Änderung als Pull Request. `main` veröffentlicht sofort auf GitHub Pages.
- Der Windows-PC lädt über `tools/sync.bat` auf den Zweig `mac-pc` hoch.
- Prompts für ComfyUI: keine Ziffern, Licht nur als Farbe, weitere Regeln in `BILDWERK.md`.
- Neue Kommentare und Texte im Spiel auf Deutsch, im Ton der vorhandenen.
- Bei jeder Änderung, die man im Spiel merkt, `Spiel.FASSUNG` (`scripts/spiel.gd`) erhöhen. Sie steht auf dem Titel und im Menü, dahinter der Bau (GitHub) oder „eigener Stand“ (PC).
