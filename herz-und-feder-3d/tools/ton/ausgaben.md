# Ausgaben bei ElevenLabs (Fassung 4.3, Ton)

Budget dieses Durchgangs: höchstens **6.500 Credits** (freigegeben 10.000; 3.500 bleiben für die Sprechzeilen der Geschichte).

**Kontostand:** Der Connector verweigert `account_get_usage` („requires additional permissions … reconnect it“).
Der Anfangsstand ist darum unbekannt. Gezählt wird hier nach den Preisen, die ElevenLabs für jede einzelne
Erzeugung meldet (`price.credits` im Ergebnis von `creative_get_flow_run_status`).

**Preise, gemessen:** Geräusche (Sound Effects v3) kosten **3,33 Credits je Sekunde und Fassung**; die Schätzung
(`estimate_only`) nennt das Dreifache (10 je Sekunde) – sie liegt zu hoch. Sprache (Eleven v3) kostet 1 Credit je
Zeichen und Fassung, Standard sind zwei Fassungen, also 2 Credits je Zeichen.

Ab vier gleichzeitigen Fassungen je Knoten lehnt ElevenLabs die vierte ab (zu viele Erzeugungen in der Warteschlange,
nicht berechnet). Darum hat jeder Knoten hier drei Fassungen.

| Block | Was | Modell | Fassungen × Sekunden/Zeichen | Credits | Dateien (tools/ton/roh/…) |
|---|---|---|---|---|---|
| 0 | Probe: Oud-Ton | Sound Effects v3 | 4 × 3 s | 40 | instr/oud_1–4 |
| 1 | 16 Instrumente (Ney, Harfe, Rahmentrommel tief/Rand, Darbuka Dum/Tek, Sistrum, Mizmar, Chor, Zimbeln, Tempeltrommel, Rebab, Glocke, Arghul, Qanun, Frauenstimme) | Sound Effects v3 | 3 × 50,4 s | 504 | instr/… |
