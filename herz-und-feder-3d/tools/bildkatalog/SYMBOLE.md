# symbole.bat: Probelauf und Nachtschicht

Ein Skript für alle Symbole, mit dem laufenden ComfyUI (Z-Image Turbo). Alle Texte stehen in `symbole_plan.json`, das Skript enthält keine.

## Einrichten (einmal)
1. `symbole.bat` und `symbole_plan.json` in den ComfyUI-Ordner `C:\CF` legen (neben `start.bat`).
2. ComfyUI starten (`start.bat`) oder das Skript starten lassen, es versucht es selbst.

## Läufe
| Aufruf | Bilder | Zweck |
|---|---|---|
| `symbole.bat probe` | 20 | die 10 bisherigen Symbole, **alter Stil gegen ägyptischen Stil** (gleicher Seed) |
| `symbole.bat probe_breit` | 40 | wie oben, dazu `positiv` (nur Verneinungen umformuliert) und `frei` (ohne Namen fremder Spiele) |
| `symbole.bat rest` | 22 | die 11 übrigen Fähigkeiten, je zwei Varianten |
| `symbole.bat nacht` | 132 | alle Fähigkeiten und Baumzeichen, je vier Varianten (a bis d) |
| `symbole.bat aeste` | 48 | die zwölf Astzeichen, je vier Varianten |

Ohne Namen erscheint ein Menü. Zusätze: `--weiter` (Fehlendes nachholen, ohne Rückfrage), `--neu` (neuer Ordner), `--trocken` (nur `prompts.txt` schreiben, ohne ComfyUI).

## Was dabei herauskommt
Ordner `ComfyUI\output\symbole\<lauf>\`: die Bilder, `uebersicht_01.jpg` (je Symbol alle Varianten nebeneinander), `leiste_64px.jpg` (Spielgröße), `manifest.json` (Seed, Prompt, Dauer je Bild), `prompts.txt`, `protokoll.txt`.

## Wichtige Erfahrung: keine Zahlen im Prompt
Z-Image malt Zahlen und Prozentzeichen gern als **Schrift ins Bild**. Aus „filling about 80% of the square“ wurden „%“, „0%“ und „9%“ als Bildmotiv. Darum steht jetzt „most of the square“ in allen Stilen, und das Skript warnt vor dem Lauf, wenn Zahlen im Prompt stehen. Ziffern aus den Namen fremder Spiele („Diablo 4“, „Baldur's Gate 3“) lösen die Warnung aus. Der Stil `frei` hat sie nicht.

## Probelauf richtig lesen
- Der Stil `alt` ist **Wort für Wort** der Stil aus `symbole_2.bat` mit denselben Seeds, **nach** der Korrektur „about 80% of the square“ zu „most of the square“. Er dient als Kontrolle. Dass Bilder auf deiner Karte exakt gleich herauskommen, ist nicht garantiert.
- `aegypt` ändert **zwei Dinge zugleich** (positive Formulierung und ägyptische Merkmale). Ob es am einen oder am anderen liegt, zeigt erst `probe_breit`.
- Bewerte zuerst nach Gefühl und decke die Beschriftung ab. Zehn Vergleiche sind ein Hinweis, kein Beweis. Prüfe auch `leiste_64px.jpg`: erkennt man die Symbole in Spielgröße?
- Die Prompts sind lang. Falls das Ende (die Stilvorgabe) abgeschnitten wirkt, sag Bescheid.

## Nachtschicht
- Den Standardstil legt die Zeile `"standardstil"` im Plan fest. Nach dem Probelauf dort `alt`, `positiv`, `aegypt` oder `frei` eintragen.
- Reihenfolge: erst alle Symbole in Variante a, dann b, c, d. Bei einem Abbruch liegt also ein vollständiger Satz vor.
- Das Skript hält den Rechner wach, versucht jedes Bild zweimal und überspringt Fertiges. Stürzt ComfyUI ab, startet es `start.bat` neu (höchstens dreimal). Nach drei Fehlern in Folge hält es an.
- Die Dauer je Bild steht nach den ersten Bildern im Fenster (mit Restzeit). Als Anhaltspunkt: etwa 2,5 Minuten je Bild (Schätzung aus einem früheren Lauf, nicht gemessen), also `probe` knapp 1 Stunde, `nacht` etwa 5,5 Stunden.
- Nie zwei Läufe gleichzeitig auf derselben Karte starten (Grafikspeicher).
- Windows-Energiesparen: Das Skript schaltet es für die Laufzeit aus. Lege den Rechner trotzdem nicht in den Ruhezustand.

## Bekannte Grenzen
- Getestet nur gegen eine Attrappe von ComfyUI (Fehler, Absturz, Weitermachen, Tafeln), nicht auf Windows und nicht mit echter Grafikkarte.
- Neustart und Wachhalten arbeiten nur unter Windows.
- Bildgröße 1024 und Entschlüsseln in Kacheln (512) sind absichtlich so gewählt (AMD-Treiber-Zeitüberschreitung).
