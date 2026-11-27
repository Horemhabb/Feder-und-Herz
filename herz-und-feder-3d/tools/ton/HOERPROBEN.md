# Hörproben und Höraufträge (Fassung 4.3, Ton)

Alles hier ist **gemessen, nicht gehört**: Lautheit, Spitzen, Länge, Nähte der Schleifen, Sprechtempo. Ob es gut
klingt, entscheidet erst ein Ohr. Bitte die Proben mit Kopfhörern **und** einmal auf dem iPhone-Lautsprecher anhören.

## Vorführungen (zum Durchhören, nicht im Spiel)

Liegen im Arbeitsordner der Sitzung, `…/scratchpad/ton/` (vollständige Pfade im Abschlussbericht). Neu bauen mit
`python3 tools/ton/hoerproben.py`.

| Datei | Was man hört |
|---|---|
| vorfuehrung_akt1.ogg | Akt 1 (D-Hijaz, 76 Schläge): erst nur Grund, dann Melodie, Spannung, Kampf, zurück, Nachklang |
| vorfuehrung_akt2.ogg | Akt 2 (A-Kurd, 60 Schläge), gleicher Ablauf |
| vorfuehrung_akt3.ogg | Akt 3 (G-mixolydisch, 88 Schläge), gleicher Ablauf |
| musik_akt1–3.ogg, musik_hueter.ogg | die Schichten einzeln hintereinander; Hüter: Grund, Phase 1, 2, 3 |
| reihe_musik_titel_nachklang.ogg | Titelmusik, danach die drei Nachklänge |
| reihe_klassen.ogg | je Klasse: Hieb, Treffer, Schmerz, Tod (Ermittler, Mönch, Jägerin, Forensikerin) |
| reihe_gegner.ogg | je Gegnerart: Erwachen, Tod; Hüter-Ansage und -Schlag |
| reihe_champions.ogg | die elf Eigenschaften der Champions |
| reihe_welt_oberflaeche.ogg | Knöpfe (auch Goldknopf), Fenster, Belohnung, Legendär, Stufe, Herzschlag, Welt-Ereignisse |
| reihe_kulisse.ogg | die Kulissen je Ort (je 20 s) |
| reihe_geschichte_akt1.ogg | Sprechzeilen Auftakt, 1. und 4. Stunde, Ende Akt 1, in Spielreihenfolge |
| reihe_geschichte_akt2_finale.ogg | 5. Stunde, Mitte der Nacht, Akt 2, vertonte Teile des Finales |
| stimmen/*.ogg | die Stimmproben des ersten Durchgangs (Nils, Samuel, Leander, Brako, Moreana, Piero, Mona) |

## Im Spiel ausprobieren

1. Neues Spiel beginnen: Der Auftakt ist vertont (Erzähler, Priester, Ba). Die Musik soll unter der Stimme leiser
   werden und danach wiederkommen.
2. Durch die erste Stunde gehen: erst ruhige Musik, nahe Gegner bringen die Spannungsschicht, Kampf die Trommeln.
   Nach dem Kampf etwa 18 Sekunden nur Grund und Nachklang.
3. Den Hüter wecken: eigene Hütermusik, mit jeder Phase dichter.
4. Einen Champion mit „Sturm“ suchen: das Sturmgeräusch soll an ihm hängen und mit ihm wandern.
5. Leben unter 30 %: Herzschlag zur pulsierenden Kugel. **Auf dem iPhone prüfen**, ob er dort überhaupt hörbar ist
   (viel Tiefe, kleine Lautsprecher geben sie kaum wieder).
6. Menü: Goldknöpfe klingen metallisch, Fenster öffnen sich mit einem Rascheln, legendäre Funde mit Glanz.

## Höraufträge (bitte ankreuzen)

- [ ] **Aussprache der Namen.** Eleven v3 spricht deutsch; ungeprüft ist, wie es diese Namen betont: Nebet,
      Haremhab, Chaemwese, Duat, Maat, Apophis, Rosetau, Sokar, Mahaf, Sandtor, Wernes, Merit. Fundstellen:
      vo_sz_auftakt_03, vo_sz_h03_nach_04 („Nebet.“), vo_sz_mitte_03, vo_sz_h02_nach_03, vo_sz_h01_nach_01 (Mahaf).
      Klingt ein Name falsch, die Zeile im nächsten Durchgang mit Lautschrift im Text neu erzeugen (z. B. „Ne-bet“).
- [ ] **Schnittstellen.** Jede Aufnahme enthielt mehrere Zeilen und wurde an den Pausen zerlegt. Auffällig im
      Tempo und darum besonders anhören: vo_sz_auftakt_02 und _04 (schnell, 18–20 Zeichen/s), vo_sz_h03_nach_02
      (langsam, 7 Zeichen/s), vo_sz_akt1_04 bis _06 (Schnitt mit Vorrang der Zeichenzahl gesetzt), vo_sz_h05_vor_01
      und _02. Fehlt ein Wort am Anfang oder hängt ein Wort der nächsten Zeile am Ende, ist der Schnitt falsch.
- [ ] **Stimmungen.** Die Regie steckt in Tags ([softly], [firm], [whispers] …). Passen Ba (Jule), Haremhab (Joerg),
      Thot (Leander), Isis (Irene), Sammler (M. Danisch), Türhüter und Mahaf (Brako, mit großem Raum)?
- [ ] **Erzähler.** Geblieben ist Samuel Storm, damit eine Stimme durchs ganze Spiel führt (alle älteren Ansagen
      sind von ihm). Gemessen ausdrucksvoller war Nils Parler (Proben stimmen/nils_*.ogg). Wer Nils lieber hört,
      müsste alle Erzählerzeilen neu erzeugen lassen (etwa 5.000 Credits).
- [ ] **Musik.** Klingen die Akte unterscheidbar (Akt 1 drängend, Akt 2 klagend und langsam, Akt 3 heller)? Ist die
      Melodie nach zehn Minuten noch erträglich (sie pausiert jede dritte Runde)?
- [ ] **Schleifen.** Kulissen und Musik sind nahtlos gemessen; ein Knacken an der Naht wäre ein Fehler.
- [ ] **Lautstärke** zwischen Stimme, Musik und Kampf auf dem iPhone.

## Was fehlt (nicht vertont, Budget erschöpft)

39 der 120 Sprechzeilen haben keine Aufnahme; das Spiel zeigt dort nur den Text (szene.gd spielt nichts, wenn die
Datei fehlt). Epiloge ohne neue Aufnahme spielen einmalig die allgemeine Ansage vo_epi, wie bisher.

- Stunde 7: vo_sz_h07_vor_01, vo_sz_h07_vor_02, vo_sz_h07_nach_01, vo_sz_h07_nach_02
- Stunde 8: vo_sz_h08_vor_01
- Akt 2: vo_sz_akt2_04, vo_sz_akt2_05
- Epiloge: vo_h05_epi2, vo_h06_epi2, vo_h07_epi2, vo_h08_epi2, vo_h09_epi2, vo_h10_epi2, vo_h11_epi2
- Stunden 9–12: vo_sz_h09_vor_01, vo_sz_h10_vor_01, vo_sz_h10_vor_02, vo_sz_h10_vor_03, vo_sz_h11_vor_01,
  vo_sz_h12_vor_01, vo_sz_h12_vor_02
- Finale: vo_sz_finale_03, _06, _07, _08, _09, _11, _13, _15, _17, _18, _19, _20 (Nebet), _21, _22, _23, _24, _25, _26

Nachholen: `python3 tools/ton/sprechen.py plan` zeigt die Gruppen 42–62 mit Stimme und Text (zusammen 4.168
Zeichen samt Regie-Tags, also gut 4.200 Credits bei einer Fassung). Erzeugen mit Eleven v3, dann
`python3 tools/ton/sprechen.py schneiden <gruppe> <aufnahme.mp3>` und Godot einmal mit `--import` starten.
