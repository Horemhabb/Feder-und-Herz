# Feder und Herz: Übergabeseite für Sitzungen

Kurz halten und aktuell halten. Wer hier etwas ändert, das nicht mehr stimmt, berichtigt es sofort.

## Was wo liegt

- `herz-und-feder-3d/`: **das Spiel** (Godot 4.7.2, GDScript, Renderer GL Compatibility, Web-Export ohne Threads).
- `nebelmark/`: die frühere HTML-Fassung. Nur Herkunft, nicht weiterentwickeln.
- `herz-und-feder-3d/FAHRPLAN.md`: **was als Nächstes dran ist** und was bewusst nicht getan wird. Vor neuer Arbeit lesen.
- `herz-und-feder-3d/BILDWERK.md`: Bilder aus ComfyUI (Werkzeuge in `tools/bildwerk/`, laufen auf dem Windows-PC des Auftraggebers unter `C:\CF`).
- `herz-und-feder-3d/WERKSTATT.md`: Figurenfabrik (Blender-Python, `tools/figurenfabrik/`).
- `herz-und-feder-3d/SPEC_4.0.md`, `LIESMICH.md`: Stand der Fassung 4.0 und Verlauf.

## Aufbau des Codes (`herz-und-feder-3d/scripts/`)

Alles wird im Code gebaut, `main.tscn` enthält nur einen Knoten. Große Dateien: `main.gd` (2.400 Zeilen, soll zerlegt werden), `hud.gd`, `foe.gd`, `orte.gd`. Licht, Farbe und Luft je Stunde: `bild.gd` (Tabelle `STUNDE`; `-- --webbild` zeigt am Desktop das Bild der Webfassung). Texte der Geschichte: `geschichte.gd`, `stunden.gd`, `worte.gd`. Die Skripte greifen über `game` (untypisiert) auf `main.gd` zu: Tippfehler fallen erst zur Laufzeit auf, darum immer den Spieltest laufen lassen.

## Prüfen

```
bash herz-und-feder-3d/tools/hol_godot.sh        # lädt Godot nach herz-und-feder-3d/.godot-bin (einmal)
cd herz-und-feder-3d
.godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --import
.godot-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --path . -- --neu --playtest --seed=1
```

Erwartet: `SPIELTEST: … ok, 0 Fehler`, Rückgabewert 0, kein `SCRIPT ERROR` (etwa 75 Sekunden). Derselbe Test läuft in `.github/workflows/bauen.yml` bei jedem Pull Request und vor jeder Veröffentlichung. Laufen mehrere Godot-Läufe zugleich (mehrere Agenten), teilen sie sich den Spielstandordner und stören einander: dann jeden Lauf mit eigenem `XDG_DATA_HOME=/tmp/…` starten. Weitere Läufe: `--klassentest`, `--bosstest`, `--autotest` (brauchen einen Bildschirm: `xvfb-run -a … --rendering-driver opengl3`).

## Regeln

- Der Auftraggeber ist kein Programmierer und hat wenig Zeit: kleine Schritte, Deutsch, klare Anweisungen zum Ausprobieren.
- Jede Änderung als Pull Request. `main` veröffentlicht sofort auf GitHub Pages.
- Der Windows-PC lädt über `tools/sync.bat` auf den Zweig `mac-pc` hoch.
- Prompts für ComfyUI: keine Ziffern, Licht nur als Farbe, weitere Regeln in `BILDWERK.md`.
- Neue Kommentare und Texte im Spiel auf Deutsch, im Ton der vorhandenen.
