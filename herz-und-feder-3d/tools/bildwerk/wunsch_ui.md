# Wunschliste: gemalte Flächen für die Oberfläche (Fassung 4.3)

Die Oberfläche ist seit 4.3 ein Gestaltungssystem (`scripts/zier.gd`, Grafiken aus `tools/ui/zier.py` in `ui/zier/`).
Gold, Rahmen, Knöpfe und Ornamente werden im Code-Werkzeug gezeichnet und sind fertig. Was ein Werkzeug nicht gut
kann, sind **gemalte Flächen**: Leder mit Narben, Lapislazuli mit Goldadern, gehämmertes Gold, altes Pergament.
Diese Liste ist für eine Nachtschicht in ComfyUI gedacht (Regeln aus `BILDWERK.md`: keine Ziffern, Licht nur als
Farbe, Hintergrund immer „dark …“, keine Wörter, die Rahmen oder Schrift locken).

**Einbau:** Die Datei unter `ui/zier/gemalt/<name>.webp` (oder `.png`) ablegen, Godot importiert sie beim nächsten
Öffnen. `Zier.tex()` nimmt eine gemalte Fassung, sobald es sie gibt (`ResourceLoader.exists`), sonst die erzeugte.
Nichts im Code muss sich ändern. Ohne die Dateien sieht alles so aus wie heute.

Alle Motive sind **randlose Flächen** (kein Rahmen, keine Ecken: die Fassung legt das Spiel darüber). Kachelbare
Motive bitte mit der Naht-Glättung aus `einbauen.bat texturen` behandeln (siehe BILDWERK.md, Abschnitt Texturen).

| Name | Zweck, wo es erscheint | Größe | kachelbar | Wirkung im Code |
|---|---|---|---|---|
| `grund_dunkel` | Grund aller dunklen Fenster: Menü, Tasche, Fähigkeitenbaum, Karte, Pforte, Truhe, Titel | 1024 × 1024 | nein (wird gestreckt) | ersetzt das erzeugte Leder; die Goldfassung `rahmen_dunkel` wird darübergezeichnet |
| `karte_grund` | Grund der großen Karte (Taste Tab) | 1024 × 640 | nein | ersetzt das dunkle Blau unter der Karte |
| `sterne` | Himmel der Nut hinter dem Fähigkeitenbaum | 512 × 512 | **ja** | ersetzt den erzeugten Sternenhimmel (wird gekachelt) |
| `papyrus` | alle Schriftstücke: Aufgaben, Gespräche, Kapiteltafeln, Lexikon, Buch des Thot | 768 × 768 | nein | ersetzt `ui/papyrus.webp`; die äußeren vierzig Pixel sind der Rand (ausgefranst, dunkler), sie werden nicht gestreckt |

## Prompts (Englisch, nach den Regeln aus BILDWERK.md)

### grund_dunkel: dunkles Leder mit Prägung
- **Prompt:** `close-up of dark brown tooled leather, fine grain and soft creases, faint embossed lotus pattern pressed into the leather, very dark umber surface, subtle warm amber sheen in the middle fading to near black at the edges, flat even surface seen straight from above, ancient Egyptian craftsmanship, highly detailed texture`
- **Gegen:** `text, letters, frame, border, corners, gold, metal, objects, light source, lamp, sun, vignette shapes`
- **Variante B (Lapislazuli):** `polished dark lapis lazuli slab, deep midnight blue stone with fine golden pyrite flecks and thin pale veins, very dark surface, faint cool blue sheen in the middle, seen straight from above, highly detailed texture`
- **Variante C (dunkles Holz):** `dark ebony wood panel, tight straight grain, oiled surface, very dark brown almost black, faint warm amber sheen, seen straight from above, highly detailed texture`
- Auswahl: eine der drei. Wichtig ist, dass die Mitte ruhig bleibt: Text steht darauf (heller Text, also dunkel genug).

### karte_grund: Kartenpergament
- **Prompt:** `aged dark papyrus sheet seen from above, crossed reed fibres, ink stains and faint smudged lines of an old survey, warm umber and dark ochre, darkened edges, very dark overall so that pale golden marks stay readable, highly detailed texture`
- **Gegen:** `text, letters, numbers, frame, border, map symbols, compass, objects`

### sterne: der Leib der Nut
- **Prompt:** `deep night sky over the desert, dense small pale stars, faint violet and indigo haze like a milky band, very dark blue black, painterly, seamless texture`
- **Gegen:** `moon, planet, horizon, ground, trees, text, frame, bright light source`

### papyrus: Blatt für Schriftstücke
- **Prompt:** `single sheet of ancient Egyptian papyrus seen from above, crossed horizontal and vertical reed fibres clearly visible, warm light beige and honey colour, darker frayed irregular edges, a few soft brown stains, empty surface without any writing, highly detailed texture on dark background`
- **Gegen:** `text, hieroglyphs, letters, drawings, frame, border, objects, hands, table`
- Nach der Auswahl auf 768 × 768 zuschneiden, so dass das Blatt randlos bis an die Bildkante reicht (die ausgefransten
  Kanten liegen in den äußeren vierzig Pixeln).

## Später, wenn das Freistellen geht

Ornamente (Flügelsonne, Udjat, Lotos, Skarabäus) sind heute erzeugt. Gemalte Fassungen wären reicher, brauchen aber
einen **durchsichtigen Hintergrund**. Kann der PC freistellen (z. B. ein Knoten „remove background“), dann lassen sich
diese Dateien unter denselben Namen ablegen, sie ersetzen dann die erzeugten:

| Name | Größe (Seitenverhältnis wie heute) | Prompt |
|---|---|---|
| `fluegelsonne` | 400 × 96 | `ancient Egyptian winged sun disk carved in polished gold, two rearing cobras beside the disk, outstretched feathered wings, raised relief with fine engraved feathers, isolated on plain black background` |
| `udjat` | 192 × 128 | `eye of Horus amulet in polished gold with lapis lazuli inlay, raised relief, isolated on plain black background` |
| `lotos` | 128 × 128 | `Egyptian blue lotus flower in profile cast in polished gold, fan of pointed petals, raised relief, isolated on plain black background` |
| `skarabaeus` | 128 × 128 | `golden scarab beetle amulet seen from above, lapis lazuli wing cases, fine engraving, isolated on plain black background` |

Die 9-Feld-Rahmen (`tafel_dunkel`, `knoepfe`, `platz`, `kartusche`, `bildrahmen`) bitte **nicht** malen lassen: Ihre
Ränder müssen pixelgenau zu `scripts/zier.gd › RAND` passen.
