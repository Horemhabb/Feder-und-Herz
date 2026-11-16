// ===================== Herz und Feder: Action-Rollenspiel in Schrägansicht durch die zwölf Stunden der Duat =====================
// 01 · Werkzeuge und Spieldaten: Stunden der Nacht, Gegner, Klassen, Fähigkeiten, Gegenstände
const $ = (id) => document.getElementById(id);
const TAU = Math.PI * 2;
const rnd = (a, b) => a + Math.random() * (b - a), ri = (a, b) => Math.floor(rnd(a, b + 1)), pick = (a) => a[Math.floor(Math.random() * a.length)];
const clamp = (v, a, b) => Math.max(a, Math.min(b, v)), dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const angDiff = (a, b) => { let d = (a - b) % TAU; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; return Math.abs(d); };
const cv = $("cv"), g = cv.getContext("2d"), lc = document.createElement("canvas"), lg = lc.getContext("2d");
const mini = $("mini"), mg = mini.getContext("2d");
// SAVE_KEY und der Grafik-Schlüssel tragen noch den alten Arbeitstitel: so bleiben vorhandene Spielstände erhalten
const WORLD = { w: 2600, h: 2000 }, MELEE = 62, BAG_MAX = 32, GAMBLE = 25, SAVE_KEY = "akte-nebelmark-v1";
const C = { hero: "#e8b04a", wisp: "#8fe3e0", elite: "#f2d04b", shotE: "#e06bd0", shotH: "#ffe9a8", blood: "#c8443a", boss: "#b06be0" };
// Bilder: wird beim Bauen aus art/manifest.json gefüllt. Fehlt ein Bild, zeichnet das Spiel eine einfache Form.
const ART = /*ART*/{ sprite: {}, tex: {}, prop: {}, portrait: {} }/*ART*/;

// ---------- Gegner ----------
// Irrender Ba: Seele, die ihren Leib nicht mehr findet · Ruheloser: Leib, den sein Ba nicht mehr findet · Sebau: „Empörer“, die Brut des Apophis, ohne Herz
// Tefens Brut: Skorpione ohne Herrin (Tefen war einer der sieben Skorpione der Isis) · Erloschener: gefallener Unvergänglicher Stern · Herzloser: Toter, dem das Herz genommen wurde
// ai: swarm (läuft an und beißt), melee (holt sichtbar aus, dann Hieb), ranged (hält Abstand, schießt), slam (Aufschlag mit Ansage), boss
const ET = {
  wisp: { name: "Irrender Ba", ai: "swarm", look: "wisp", r: 10, hp: 22, dmg: 6, spd: 135, xp: 6, w: 1, atk: 0.9, drop: 0.1, col: "#8fe3e0", glow: 46 },
  skorp: { name: "Tefens Brut", ai: "swarm", look: "skorp", r: 12, hp: 32, dmg: 8, spd: 116, xp: 8, w: 1.2, atk: 1.1, drop: 0.12, col: "#b98a4a", animal: true },
  lance: { name: "Sebau-Krieger", ai: "melee", look: "snake", r: 14, hp: 62, dmg: 13, spd: 92, xp: 14, w: 2, atk: 1.9, drop: 0.2, col: "#c9a24e" },
  seer: { name: "Sebau-Priesterin", ai: "ranged", look: "seer", r: 13, hp: 38, dmg: 10, spd: 84, xp: 12, w: 1.6, range: 340, atk: 2.3, drop: 0.18, col: "#d9d2b8", shot: "#9be06b" },
  haut: { name: "Sebau-Koloss", ai: "slam", look: "giant", r: 26, hp: 170, dmg: 26, spd: 62, xp: 32, w: 4, atk: 3, drop: 0.45, col: "#8a7446" },
  guard: { name: "Ruheloser", ai: "melee", look: "guard", r: 15, hp: 82, dmg: 15, spd: 74, xp: 16, w: 2.2, atk: 2.1, drop: 0.22, col: "#8f8a6a", undead: true },
  fahl: { name: "Erloschener", ai: "ranged", look: "grey", r: 13, hp: 44, dmg: 12, spd: 88, xp: 14, w: 1.8, range: 360, atk: 2.1, drop: 0.2, col: "#a9b3b6", shot: "#e06bd0" },
  hohl: { name: "Herzloser", ai: "melee", look: "demon", r: 15, hp: 70, dmg: 16, spd: 112, xp: 16, w: 2.2, atk: 1.6, drop: 0.22, col: "#4a3434", demon: true, glow: 30 },
  boss: { name: "Der Sammler", ai: "boss", look: "sammler", r: 44, hp: 1500, dmg: 20, spd: 58, xp: 300, w: 0, atk: 0, drop: 1, col: "#b06be0", glow: 150 },
};
const ELITE = [{ id: "flink", name: "flink" }, { id: "zaeh", name: "zäh" }, { id: "wild", name: "rasend" }];
const pk = (s) => s.split(" ").flatMap((t) => { const [k, n] = t.split("*"); return Array(+n || 1).fill(k); });

// ---------- Die Nacht hat zwölf Stunden (Amduat). Die ersten fünf erzählen die Geschichte, sechs bis zwölf bringen die Barke bis zum Morgen. Danach beginnt die nächste Nacht. ----------
// lead: ein Satz zur Stunde · brief: was du weißt, wenn du sie betrittst · epi: was du weißt, wenn ihr Hüter gefallen ist
const ACT = [
  { name: "Das Tor des Westens", legs: ["lantern", "sight"], lead: "Über Sandtor ziehen Lichter gegen den Wind. Es sind Seelen, und niemand holt sie ab.", tex: "T01", mix: [["rock",7],["needle",3]], mote: "#bcd0e8", mood: "dust",
    brief: "Folge den Lichtern hinab. Halte die Laterne hoch. In ihr brennt ein Funke des Re, und was Isfet ist, weicht vor ihm zurück oder greift ihn an.",
    epi: "Mahaf war der Fährmann. Seit die Waage stillsteht, darf er niemanden mehr übersetzen, also führte er die Seelen im Kreis. Sein Licht brennt jetzt in deiner Laterne, und es zeigt nach unten.",
    pal: { ground: "#5a5547", dune: "#6d6756", rock: "#6f6657", rockL: "#91876f" },
    packs: ["wisp*6", "skorp*4 wisp*2", "lance*2 wisp*3", "skorp*5", "lance*3", "wisp*8"],
    boss: { name: "Mahaf, das Leitlicht", look: "wisp", col: "#8fe3e0", r: 30, hp: 0.7, say: "Der Fährmann, der hinter sich schaut. Er hat seine Fähre verloren und setzt trotzdem über." } },
  { name: "Die Felder von Wernes", dungeon: "ruin", legs: ["skin", "shards"], lead: "Wo die Gerechtfertigten Korn schnitten, häutet sich die Brut des Apophis. Jede Haut macht sie größer.", tex: "T03", mix: [["rock",4],["needle",5],["ruin",1]], mote: "#d8c9a0", mood: "dust",
    brief: "Mahafs Licht führt in die Felder, die einmal die Seligen ernährten. Die Sebau fürchten keine Waage, denn sie haben kein Herz. Jemand muss ihnen den Weg hierher geöffnet haben.",
    epi: "Unter ihrer letzten Haut lag kein Leib, nur Sand und der Abdruck eines Siegels: ein Königsring ohne Namen darin. Was Apophis gebiert, kann man nicht wiegen. Also braucht er jemanden, der die Waage für ihn anhält.",
    pal: { ground: "#4d5450", dune: "#5f6964", rock: "#5f6661", rockL: "#7f8a83" },
    packs: ["lance*3 seer", "seer*2 lance*2", "haut skorp*3", "lance*4", "haut seer*2", "skorp*6"],
    boss: { name: "Die Mutter der Häute", look: "mutter", col: "#c9a24e", r: 46, hp: 0.9, say: "Sie hat schon viele Häute getragen. Diese ist ihre zwölfte." } },
  { name: "Der König ohne Namen", dungeon: "tomb", legs: ["heavy", "potion"], lead: "Am Wasser des Osiris liegt ein König, dessen Name aus jeder Wand geschlagen ist. Er hält ein Schwert aus dem Gold der Tagesbarke.", tex: "T04", mix: [["ruin",5],["tomb",5],["rock",1]], mote: "#ffb060", mood: "ember",
    brief: "Wer keinen Namen hat, den kann Thot nicht aufrufen, und wer nicht aufgerufen wird, kommt nie vor die Waage. Die Toten in diesen Gräbern liegen wach. Ihr Ba findet nicht mehr zu ihnen zurück.",
    epi: "Er hat seinen Namen verkauft. Der Käufer versprach ihm dafür, dass sein Herz nie auf die Waage kommt. Im Sarkophag liegt die Quittung: ein versiegelter Krug. Er ist warm, und er schlägt.",
    pal: { ground: "#47423f", dune: "#57514c", rock: "#5d564f", rockL: "#7b7268" },
    packs: ["guard*3", "guard*2 wisp*3", "hohl*2 wisp*3", "guard*4", "wisp*8", "haut guard*2"],
    boss: { name: "Der König ohne Namen", look: "koenig", col: "#d8b04a", r: 40, hp: 1, say: "Frag ihn nicht, wie er heißt. Er weiß es nicht mehr.", undead: true } },
  { name: "Rosetau", dungeon: "glass", legs: ["mirror", "star"], lead: "Sokars Land, „der auf seinem Sand ist“. Hier wird die Barke gezogen, nicht gerudert. Die sie zogen, stehen erloschen an den Wegen.", tex: "T02", mix: [["ruin",4],["star",4],["needle",2]], mote: "#8fe3e0", mood: "glass",
    brief: "Der Krug aus dem Sarkophag schlägt in deiner Tasche wie ein zweites Herz, und er zieht nach Westen. In Rosetau gibt es kein Wasser. Seit die Sterne erloschen sind, zieht niemand mehr die Barke über den Sand.",
    epi: "Die Erloschenen waren Unvergängliche Sterne. Sie zogen die Barke, bis jemand ihnen das Herz nahm. Hinter dem Tor liegt das Zugseil. Es führt in eine Höhle, und es ist straff gespannt.",
    pal: { ground: "#434a52", dune: "#535b65", rock: "#535a63", rockL: "#737c88" },
    packs: ["fahl*4", "fahl*2 hohl*2", "hohl*3", "haut fahl*2", "wisp*8", "guard*2 fahl*2"],
    boss: { name: "Der Stumme Türhüter", look: "grey", col: "#a9b3b6", r: 38, hp: 1.1, say: "Wer seinen Namen nennt, darf durch. Es kennt ihn keiner mehr." } },
  { name: "Die Höhle des Sokar", dungeon: "vault", legs: ["greed", "critres"], lead: "Tausend Krüge, und in jedem schlägt es. In ihrer Mitte liegt die Nachtbarke auf dem Trockenen.", tex: "T02", mix: [["star",3],["ruin",2],["tomb",2],["needle",2],["rock",1]], mote: "#c9a8ff", mood: "glass",
    brief: "Der Sammler saß einmal selbst zu Gericht, als einer der Zweiundvierzig. Er weiß, was die Waage findet. Sein eigenes Herz ist ihm zu schwer geworden, also hat er beschlossen, dass sie nie wieder etwas findet.",
    epi: "Die Krüge zerspringen, einer nach dem anderen. Die Herzen finden heim, die Waage bewegt sich, und Thot taucht die Binse ein. Die Barke hebt sich vom Sand. Sieben Stunden bleiben bis zum Morgen, und in der siebten wartet Apophis.",
    pal: { ground: "#4a4452", dune: "#5b5465", rock: "#58515f", rockL: "#7a7186" },
    packs: ["fahl*3 hohl", "lance*3 seer", "guard*3", "haut hohl*2", "wisp*8", "seer*2 fahl*2", "skorp*6"],
    boss: { name: "Der Sammler", look: "sammler", col: "#b06be0", r: 44, hp: 1.3, say: "Er hat auch für dich einen Krug." } },
];
// Stunden sechs bis zwölf: base = Landschaft einer der fünf ersten Stunden, boss = dessen Gestalt
const OPEN = [
  { name: "Der Leib des Osiris", base: 2, boss: 2, bossName: "Der falsche Osiris", say: "Er liegt, wo ein anderer liegen sollte.",
    lead: "Die tiefste Stunde. Hier ruht, was von Osiris blieb, und Re muss es berühren, um wieder jung zu werden.",
    brief: "Die Barke fährt wieder, aber sie ist schwach. Um Mitternacht müssen Re und Osiris einander begegnen. Auf dem Lager des Osiris liegt jemand, der dort nicht hingehört.",
    epi: "Der Platz ist wieder frei. Für einen Atemzug sind Re und Osiris eins, und der Funke in deiner Laterne wird heller." },
  { name: "Die Sandbank des Apophis", base: 0, boss: 1, bossName: "Eine Windung des Apophis", say: "Das ist nur eine Windung. Der Rest liegt unter der Sandbank.",
    lead: "Eine Sandbank, so lang wie er selbst. Er hat das Wasser unter der Barke ausgetrunken.",
    brief: "Seth steht am Bug mit dem Speer. Isis spricht die Worte, Selket hält die Fessel. Dir bleibt das Messer.",
    epi: "Isis hat ihn besprochen, Selket hat ihn gebunden, du hast das Messer geführt. Er ist nicht tot, er ist nie tot. Aber das Wasser kommt zurück, und die Barke fährt." },
  { name: "Die Grüfte der Götter", base: 3, boss: 3, bossName: "Der Hüter ohne Stimme", say: "Aus seiner Gruft kommt kein Laut.",
    lead: "Aus den Grüften antwortet es, wenn Re vorüberfährt. Heute antwortet etwas anderes.",
    brief: "Wenn Re ruft, sollen die Stimmen aus den Grüften klingen wie ein Kater und wie ein Schwarm Bienen. Hör hin, ob sie es noch tun.",
    epi: "Es summt wieder in den Grüften, und irgendwo schreit ein Kater. So soll es sein." },
  { name: "Die Ruderer", base: 4, boss: 0, bossName: "Der zwölfte Ruderer", say: "Sein Ba hat die Bank nicht mehr gefunden.",
    lead: "Zwölf Ruderer hat die Barke. Elf sitzen auf ihren Bänken.",
    brief: "Mit elf Rudern kommt die Barke nicht gegen die Strömung an. Der zwölfte irrt als Licht durch die Gänge.",
    epi: "Zwölf Ruder tauchen ein. Zum ersten Mal in dieser Nacht hörst du Wasser." },
  { name: "Die Ertrunkenen im Nun", base: 1, boss: 2, bossName: "Der Ertrunkene König", say: "Er hält sich am Grund fest.",
    lead: "Wer im Fluss blieb, bekam kein Grab. Horus zieht sie hier ans Ufer, damit auch sie gewogen werden.",
    brief: "Auch wer kein Grab bekam, hat ein Recht auf die Waage. Einer will nicht an Land.",
    epi: "Horus ruft sie beim Namen, und sie kommen ans Ufer, einer nach dem anderen." },
  { name: "Die Feuergruben", base: 2, boss: 1, bossName: "Die Entronnene", say: "Sie ist aus der Grube gekrochen.",
    lead: "Gruben voll Feuer, und an jedem Rand eine Göttin mit dem Messer. Hier endet, wer gegen die Ordnung stand.",
    brief: "Geh nicht zu nah an den Rand. Etwas ist herausgekommen.",
    epi: "Die Grube ist wieder voll. Am Rand des Himmels wird es grau." },
  { name: "Das Tor des Ostens", base: 0, boss: 4, bossName: "Der Schatten des Sammlers", say: "Sein Herz ist gewogen. Sein Schatten wusste nichts davon.",
    lead: "Die letzte Stunde. Re geht durch den Leib der Schlange „Leben der Götter“ und kommt als Chepri wieder heraus. Etwas steht davor.",
    brief: "Hinter dem Tor wartet Schu mit erhobenen Armen, um die Sonne zu heben. Vor dem Tor wartet jemand, den du schon einmal besiegt hast.",
    epi: "Schu hebt die Sonne über den Horizont. Thot schreibt diese Nacht in sein Buch und schlägt eine neue Seite auf. Apophis kommt jede Nacht wieder, und jede Nacht braucht es jemanden mit einer Laterne." },
];
const HOURS = 12, ORD = ["Erste", "Zweite", "Dritte", "Vierte", "Fünfte", "Sechste", "Siebte", "Achte", "Neunte", "Zehnte", "Elfte", "Zwölfte"];
const hourOf = (n) => (n - 1) % HOURS + 1, nightOf = (n) => Math.floor((n - 1) / HOURS) + 1;
const hourTxt = (n) => `${nightOf(n) > 1 ? `${nightOf(n)}. Nacht, ` : ""}${ORD[hourOf(n) - 1]} Stunde`;
const caseNo = (n) => nightOf(n) > 1 ? `${nightOf(n)}. NACHT · ${ORD[hourOf(n) - 1].toUpperCase()} STUNDE` : `${ORD[hourOf(n) - 1].toUpperCase()} STUNDE DER NACHT`;
function caseDef(n) {
  const h = hourOf(n);
  if (h <= ACT.length) return ACT[h - 1];
  const o = OPEN[h - ACT.length - 1], b = ACT[o.base];
  return { ...b, name: o.name, lead: o.lead, brief: o.brief, epi: o.epi, packs: ACT.flatMap((a) => a.packs), boss: { ...ACT[o.boss].boss, name: o.bossName, say: o.say, hp: 1.3 } };
}

// ---------- Fähigkeiten ----------
const SK = {
  // Eidträger
  whirl: { name: "Falkenkreis", cost: 25, cd: 0.5, ic: '<circle cx="28" cy="28" r="15" fill="none" stroke="#e8b04a" stroke-width="4" stroke-dasharray="60 34"/><path d="M41 15l5-9 3 10z" fill="#e8b04a"/>' },
  dash: { name: "Sturz des Falken", cost: 0, cd: 5, ic: '<path d="M10 40L30 20M22 44L42 24" stroke="#8fe3e0" stroke-width="4" stroke-linecap="round"/><circle cx="42" cy="15" r="6" fill="#8fe3e0"/>' },
  oath: { util: true, name: "Eid der Maat", cost: 0, cd: 18, ic: '<path d="M28 8l16 6v12c0 10-7 17-16 21-9-4-16-11-16-21V14z" fill="none" stroke="#e8b04a" stroke-width="4"/><path d="M28 18v16M20 26h16" stroke="#e8b04a" stroke-width="4" stroke-linecap="round"/>' },
  pulse: { name: "Blick des Udjat", cost: 0, cd: 14, ic: '<circle cx="28" cy="28" r="6" fill="#c06be0"/><circle cx="28" cy="28" r="13" fill="none" stroke="#c06be0" stroke-width="3"/><circle cx="28" cy="28" r="21" fill="none" stroke="#c06be0" stroke-width="2" opacity=".6"/>' },
  bolt: { name: "Strahl des Re", cost: 14, cd: 0.35, ic: '<path d="M10 28H38" stroke="#ffe9a8" stroke-width="5" stroke-linecap="round"/><path d="M36 18l12 10-12 10z" fill="#ffe9a8"/>' },
  // Wüstenjägerin
  salve: { name: "Neiths Fächer", cost: 22, cd: 0.4, ic: '<path d="M10 28L44 12M10 28H46M10 28L44 44" stroke="#7ad08a" stroke-width="4" stroke-linecap="round"/>' },
  roll: { util: true, name: "Sprung der Gazelle", cost: 0, cd: 4, ic: '<path d="M12 38a16 16 0 1 1 26 4" fill="none" stroke="#7ad08a" stroke-width="4" stroke-linecap="round"/><path d="M44 36l-4 12-9-8z" fill="#7ad08a"/>' },
  hetz: { name: "Upuauts Hatz", cost: 0, cd: 9, ic: '<circle cx="28" cy="35" r="9" fill="#7ad08a"/><circle cx="13" cy="25" r="5" fill="#7ad08a"/><circle cx="23" cy="15" r="5" fill="#7ad08a"/><circle cx="35" cy="15" r="5" fill="#7ad08a"/><circle cx="44" cy="25" r="5" fill="#7ad08a"/>' },
  rain: { name: "Sieben Pfeile der Sachmet", cost: 0, cd: 12, ic: '<circle cx="28" cy="36" r="15" fill="none" stroke="#7ad08a" stroke-width="3"/><path d="M18 8v18M28 6v22M38 8v18" stroke="#d8ffd8" stroke-width="3" stroke-linecap="round"/>' },
  pierce: { name: "Pfeil der Neith", cost: 18, cd: 0.5, ic: '<path d="M6 28H42" stroke="#d8ffd8" stroke-width="6" stroke-linecap="round"/><path d="M38 16l14 12-14 12z" fill="#d8ffd8"/><path d="M6 20l8 8-8 8" fill="none" stroke="#7ad08a" stroke-width="3"/>' },
  // Sternleserin
  chain: { name: "Zorn des Seth", cost: 16, cd: 0.35, ic: '<path d="M8 14l14 12-8 4 16 10-6 4 20 6" fill="none" stroke="#e2b8ff" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>' },
  blink: { util: true, name: "Schritt durch die Duat", cost: 0, cd: 4, ic: '<circle cx="14" cy="40" r="6" fill="none" stroke="#c06be0" stroke-width="3" stroke-dasharray="4 4"/><circle cx="40" cy="16" r="8" fill="#c06be0"/><path d="M20 34l12-12" stroke="#c06be0" stroke-width="3" stroke-dasharray="3 5" stroke-linecap="round"/>' },
  glass: { util: true, name: "Seschats Maß", cost: 20, cd: 8, ic: '<path d="M16 8h24M16 48h24M19 8c0 12 18 12 18 20s-18 8-18 20M37 8c0 12-18 12-18 20s18 8 18 20" fill="none" stroke="#8fe3e0" stroke-width="3" stroke-linecap="round"/>' },
  nova: { name: "Hu, das Machtwort", cost: 0, cd: 10, ic: '<circle cx="28" cy="28" r="6" fill="#8fe3e0"/><path d="M28 6v10M28 40v10M6 28h10M40 28h10M12 12l7 7M37 37l7 7M44 12l-7 7M19 37l-7 7" stroke="#8fe3e0" stroke-width="3" stroke-linecap="round"/>' },
  meteor: { name: "Fallender Stern der Nut", cost: 35, cd: 1, ic: '<path d="M42 6L24 30" stroke="#ffd75e" stroke-width="6" stroke-linecap="round"/><circle cx="22" cy="34" r="9" fill="#ffd75e"/><ellipse cx="24" cy="48" rx="16" ry="4" fill="none" stroke="#ffd75e" stroke-width="2"/>' },
  // Priester des Schu
  flurry: { name: "Fäuste des Month", cost: 24, cd: 0.8, ic: '<path d="M8 18h20M8 28h28M8 38h20" stroke="#efe6cf" stroke-width="5" stroke-linecap="round"/><circle cx="38" cy="18" r="5" fill="#efe6cf"/><circle cx="46" cy="28" r="5" fill="#efe6cf"/><circle cx="38" cy="38" r="5" fill="#efe6cf"/>' },
  step: { name: "Schritt des Schu", cost: 0, cd: 4.5, ic: '<path d="M8 36q14-14 28-8M14 46q14-12 26-6" fill="none" stroke="#efe6cf" stroke-width="4" stroke-linecap="round"/><circle cx="42" cy="16" r="6" fill="#efe6cf"/>' },
  mantra: { util: true, name: "Kreis des Ka", cost: 0, cd: 16, ic: '<circle cx="28" cy="28" r="21" fill="none" stroke="#efe6cf" stroke-width="2" stroke-dasharray="3 5"/><circle cx="28" cy="28" r="12" fill="none" stroke="#efe6cf" stroke-width="3"/><circle cx="28" cy="28" r="4" fill="#efe6cf"/>' },
  palm: { name: "Gebs Lachen", cost: 0, cd: 12, ic: '<path d="M16 48V24l6-2V10h5v12h3V8h5v14h3V12h5v20c0 8-5 16-13 16z" fill="#efe6cf"/>' },
  wave: { name: "Atem des Schu", cost: 18, cd: 0.6, ic: '<path d="M12 12q16 16 0 32M24 10q20 18 0 36M36 8q24 20 0 40" fill="none" stroke="#efe6cf" stroke-width="4" stroke-linecap="round"/>' },
  potion: { name: "Rotbier der Sachmet", cost: 0, cd: 1, ic: '<path d="M23 10h10v9l8 14a9 9 0 0 1-8 13H23a9 9 0 0 1-8-13l8-14z" fill="#c8443a" stroke="#e6dfc8" stroke-width="2"/>' },
};
const SK_TXT = {
  whirl: "Rundumschlag um dich herum. Der Falke kreist, bevor er stößt.", dash: "Sprung zum Ziel mit Aufprall.", oath: "Du schwörst auf die Feder: 6 Sekunden lang 30 % mehr Schaden, 20 % weniger erlittener Schaden.", pulse: "Das heile Auge des Horus öffnet sich. Betäubt alles im Umkreis und löscht Geschosse.", bolt: "Licht aus der Laterne, das mehrere Gegner durchschlägt.",
  salve: "Fünf Pfeile im Fächer.", roll: "Sprung aus der Gefahr.", hetz: "Dein Fuchs springt das Ziel an und beißt 5 Sekunden lang schneller. Feindliche Tiere in der Nähe fliehen.", rain: "Sachmets Pfeile regnen auf eine Fläche.", pierce: "Ein Pfeil durch die ganze Reihe.",
  chain: "Seths Gewitter springt von Gegner zu Gegner.", blink: "Ein Schritt durch die Unterwelt versetzt dich ein Stück weit.", glass: "Seschat misst die Zeit, und hier misst sie knapp: ein Feld, in dem Gegner nur noch kriechen.", nova: "Ein gesprochenes Wort, das gilt. Der Ring betäubt lange.", meteor: "Ein Stern löst sich vom Leib der Nut. Trifft spät und hart.",
  flurry: "Fünf schnelle Schläge nach vorn.", step: "Schritt durch die Gegner mit Treffer.", mantra: "Kreis für 7 Sekunden: Deine Lebenskraft heilt dich, Gegner darin treffen schwächer.", palm: "Wenn Geb lacht, bebt die Erde. Getroffene zerbersten, wenn sie fallen, und reißen Nachbarn mit.", wave: "Ein Atemstoß, der alles zurückwirft.",
};
// Vier Klassen. sk: Tasten 1 bis 4 = [Verbraucher, Ausweichen, Hilfsfähigkeit, starke Fähigkeit]; rmb: rechte Maustaste (zweiter Verbraucher)
const CLS = {
  ermittler: { name: "Eidträger", art: "K01", face: "F01", like: "Nahkampf mit dem Zweihänder", txt: "Hat auf die Feder der Maat geschworen. Hält viel aus und steht mitten im Getümmel.", col: "#e8b04a", colD: "#8a6420", res: "Eidkraft", rc: ["#3f7fd6", "#152c52"], basic: "melee", range: 62, sk: ["whirl", "dash", "oath", "pulse"], rmb: "bolt", hp: 1.2, red: 0.15, spd: 1, regen: 4 },
  moench: { name: "Priester des Schu", art: "K02", face: "F02", like: "Fäuste, Schlagfolgen, Kreise", txt: "Kämpft mit bloßen Händen und dem Atem des Luftgottes. Jeder dritte Schlag trifft doppelt so weit und härter.", col: "#efe6cf", colD: "#8d8672", res: "Atem", rc: ["#d9a04a", "#4a3312"], basic: "melee", combo: true, range: 58, sk: ["flurry", "step", "mantra", "palm"], rmb: "wave", hp: 1.05, red: 0.1, spd: 1.1, regen: 5 },
  jaegerin: { name: "Wüstenjägerin", art: "K03", face: "F03", like: "Bogen und ein Wüstenfuchs", txt: "Schülerin der Neith. Schießt aus der Ferne. Ihr Fuchs, der Wegöffner, kämpft mit und verjagt feindliche Tiere.", col: "#7ad08a", colD: "#2f6b3c", res: "Instinkt", rc: ["#3fa86a", "#123a22"], basic: "shot", range: 400, sk: ["salve", "roll", "hetz", "rain"], rmb: "pierce", pet: true, hp: 0.9, red: 0, spd: 1.08, regen: 5 },
  forensiker: { name: "Sternleserin", art: "K04", face: "F04", like: "Heka: Magie aus Wort und Stern", txt: "Schreiberin der Seschat. Empfindlich, aber sie bestimmt, wo gekämpft wird: Sturm, Maß und fallende Sterne.", col: "#c06be0", colD: "#5a2a78", res: "Heka", rc: ["#9a5fe0", "#2c1552"], basic: "spark", range: 360, sk: ["chain", "blink", "glass", "nova"], rmb: "meteor", hp: 0.82, red: 0, spd: 1, regen: 8 },
};
const POTS = 4;
// Material zum Sammeln: fällt je nach Gegnerart, wird beim Aufwerten und Neuwürfeln verbraucht
const MATS = {
  staub: { name: "Fayencestaub", col: "#8fe3e0", txt: "Türkis wie die Grabbeigaben. Von fast allem, was in der Duat umgeht. Grundstoff fürs Aufwerten." },
  leder: { name: "Schlangenhaut", col: "#c9a24e", txt: "Von den Sebau, der Brut des Apophis. Für Rüstung ab Stufe +3." },
  eisen: { name: "Sethknochen", col: "#aab3bd", txt: "So nennen die Priester das Eisen. Von Ruhelosen und Herzlosen. Für Waffen und Schmuck ab Stufe +3." },
  stern: { name: "Himmelseisen", col: "#e9fffd", txt: "Eisen, das vom Himmel fiel. Von Erloschenen und Hütern der Stunden. Für die letzte Stufe +5." },
};
const MAT_OF = { snake: "leder", seer: "leder", giant: "leder", mutter: "leder", guard: "eisen", demon: "eisen", koenig: "eisen", grey: "stern", sammler: "stern" };
const UP_MAX = 5;
// Kosten der nächsten Aufwertung eines Teils
function upCost(it) { const u = it.up || 0, c = { staub: 3 * (u + 1) }; if (u >= 2) c[SLOT[it.slot].arm ? "leder" : "eisen"] = u - 1; if (u >= 4) c.stern = 1; return c; }
const upMul = (it) => 1 + 0.12 * (it.up || 0);
const itDmg = (it) => Math.round(it.dmg * upMul(it)), itArm = (it) => Math.round(it.armor * upMul(it)), itAff = (it, k) => Math.round(it.aff[k] * (1 + 0.06 * (it.up || 0)));
// Schwierigkeit: zähere, härtere Gegner, dafür mehr Erfahrung und mehr Legendäres
// pack: Anteil der Rudelgröße · slots: so viele Nahkämpfer greifen gleichzeitig an, die übrigen halten Abstand und warten
// gap: Mindestabstand zwischen zwei Schüssen der Gegner (Sekunden) · alarm: rufen Rudel ihre Nachbarn herbei?
const DIFF = [
  { name: "Normal", txt: "kleinere Rudel, höchstens zwei Gegner greifen gleichzeitig an, die übrigen warten auf Abstand; Treffer sind schwach", hp: 0.65, dmg: 0.5, xp: 1.15, leg: 1, pack: 0.6, slots: 2, gap: 1.1, alarm: false, spd: 0.88, sight: 0.85 },
  { name: "Schwer", txt: "größere Rudel, bis zu vier Angreifer zugleich, Nachbarrudel kommen zu Hilfe, mehr Legendäres", hp: 1.3, dmg: 1.2, xp: 1.3, leg: 1.6, pack: 0.85, slots: 4, gap: 0.45, alarm: true, spd: 1, sight: 1 },
  { name: "Albtraum", txt: "volle Rudel, die dich einkreisen; für eingespielte Figuren mit guter Ausrüstung", hp: 2.5, dmg: 2, xp: 1.7, leg: 2.4, pack: 1, slots: 6, gap: 0.15, alarm: true, spd: 1.05, sight: 1.1 },
];

// ---------- Gegenstände ----------
const RAR = [{ name: "Gewöhnlich", col: "#b9b3a0", aff: [0, 0], mult: 1 }, { name: "Magisch", col: "#6fa8ff", aff: [1, 2], mult: 1.15 }, { name: "Selten", col: "#f2d04b", aff: [3, 4], mult: 1.3 }, { name: "Legendär", col: "#ff8a3c", aff: [4, 4], mult: 1.5 }];
const SLOT = {
  waffe: { name: "Waffe", bases: ["Chepesch", "Streitaxt", "Kompositbogen", "Was-Zepter", "Faustbinden", "Feuersteinmesser", "Birnenkeule", "Harpune"], ic: '<path d="M8 40L36 12l6-2-2 6L12 44z" fill="currentColor"/><path d="M10 30l14 14" stroke="currentColor" stroke-width="4"/>' },
  nebenhand: { name: "Nebenhand", arm: 0.5, bases: ["Tempellampe", "Fellschild", "Hathorspiegel", "Sistrum", "Schreibpalette", "Räucherarm"], ic: '<circle cx="26" cy="28" r="15" fill="none" stroke="currentColor" stroke-width="5"/><circle cx="26" cy="28" r="5" fill="currentColor"/>' },
  helm: { name: "Kopf", arm: 0.6, bases: ["Nemes-Tuch", "Chepresch", "Geierhaube", "Totenmaske", "Leinenkappe", "Stirnband mit Uräus"], ic: '<path d="M8 34a18 18 0 0 1 36 0v4H8z" fill="currentColor"/><path d="M4 40h44" stroke="currentColor" stroke-width="5" stroke-linecap="round"/>' },
  ruestung: { name: "Rüstung", arm: 1, bases: ["Leinenschurz", "Priestergewand", "Leopardenfell", "Lederkoller", "Schuppenpanzer", "Goldpektoral"], ic: '<path d="M26 6l16 6v14c0 10-7 17-16 20C17 43 10 36 10 26V12z" fill="currentColor"/>' },
  handschuhe: { name: "Hände", arm: 0.4, bases: ["Leinenbinden", "Schützenhandschuhe", "Bronzefäustlinge", "Armschienen"], ic: '<path d="M14 46V22l6-2V8h5v12h3V6h5v14h3V10h5v20c0 8-5 16-13 16z" fill="currentColor"/>' },
  stiefel: { name: "Füße", arm: 0.4, bases: ["Papyrussandalen", "Ledersandalen", "Reiseschuhe", "Beinschienen"], ic: '<path d="M16 6h14v26l14 6v8H12V32z" fill="currentColor"/>' },
  amulett: { name: "Amulett", bases: ["Udjat-Auge", "Anch", "Djed-Pfeiler", "Isisknoten", "Herzskarabäus", "Schen-Schleife"], ic: '<path d="M12 8q14 16 28 0" fill="none" stroke="currentColor" stroke-width="3"/><path d="M26 22l9 10-9 12-9-12z" fill="currentColor"/>' },
  ring: { name: "Ring", bases: ["Fayencering", "Siegelring", "Kartuschenring", "Skarabäusring", "Uräus-Ring", "Schen-Ring"], ic: '<circle cx="26" cy="30" r="12" fill="none" stroke="currentColor" stroke-width="5"/><path d="M26 6l6 8-6 6-6-6z" fill="currentColor"/>' },
};
// Sachmet: Zorn · Chnum formt den Leib · Bes schützt · Horus: Falkenauge · Seth: Gewalt · Schu: Wind · Month: Kampf · Thot: Klarheit · Isis: Heilung · Selket: Skorpion · Seschat: Lernen · Renenutet: Ernteglück
const AFF = {
  dmgPct: { name: "Schaden", unit: " %", v: (l) => ri(5 + l, 9 + l * 2), w: 1.2, suf: "der Sachmet" },
  hp: { name: "Leben", unit: "", v: (l) => ri(10 + l * 6, 20 + l * 10), w: 0.12, suf: "des Chnum" },
  armor: { name: "Rüstung", unit: "", v: (l) => ri(4 + l * 2, 8 + l * 4), w: 0.35, suf: "des Bes" },
  crit: { name: "Kritische Trefferchance", unit: " %", v: () => ri(2, 5), w: 2.2, suf: "des Horus" },
  critDmg: { name: "Kritischer Schaden", unit: " %", v: (l) => ri(10, 22) + l, w: 0.45, suf: "des Seth" },
  speed: { name: "Lauftempo", unit: " %", v: () => ri(3, 7), w: 1, suf: "des Schu" },
  as: { name: "Angriffstempo", unit: " %", v: () => ri(3, 8), w: 1.3, suf: "des Month" },
  regen: { name: "Kraft pro Sekunde", unit: "", v: () => ri(1, 3), w: 1.5, suf: "des Thot" },
  loh: { name: "Leben pro Treffer", unit: "", v: (l) => ri(1 + l, 2 + l * 2), w: 0.8, suf: "der Isis" },
  thorns: { name: "Dornen (Schaden an Angreifern)", unit: "", v: (l) => ri(4 + l * 3, 8 + l * 5), w: 0.25, suf: "der Selket" },
  xp: { name: "Erfahrung", unit: " %", v: () => ri(4, 10), w: 0.6, suf: "der Seschat" },
  find: { name: "Beuteglück", unit: " %", v: () => ri(5, 14), w: 0.5, suf: "der Renenutet" },
};
const RARE_NAMES = ["Nachtfahrt", "Zweiter Tod", "Wahr an Stimme", "Millionen Jahre", "Feuersee", "Binsengefilde", "Herz auf der Waage", "Westwind", "Erstes Mal", "Rosetau"];
// Legendäre Kräfte: zwei je Ausrüstungsplatz
const LEGS = [
  { id: "critres", slot: "waffe", name: "Harpune des Horus", txt: "Mit ihr traf er Seth. Jeder kritische Treffer gibt dir 5 deiner Kraft zurück." },
  { id: "sun", slot: "waffe", quest: true, name: "Sonnenrichter", txt: "Zweihänder aus dem Gold der Tagesbarke. 60 % mehr Schaden gegen Ruhelose und Herzlose." },
  { id: "lantern", slot: "nebenhand", name: "Lampe der Maat", txt: "Im Licht der Wahrheit steht jeder da, wie er ist. Gegner in deinem Lichtkegel erleiden 25 % mehr Schaden." },
  { id: "mirror", slot: "nebenhand", name: "Spiegel der Hathor", txt: "Jedes vierte Geschoss, das dich träfe, fliegt zum Schützen zurück." },
  { id: "potion", slot: "helm", name: "Löwenhaube der Sachmet", txt: "Die Göttin, die Seuchen schickt, heilt sie auch. Rotbier heilt dich vollständig." },
  { id: "sight", slot: "helm", name: "Maske des Anubis", txt: "Der Balsamierer sieht im Dunkeln. Dein Lichtkegel reicht ein Drittel weiter." },
  { id: "s4", slot: "ruestung", name: "Fell des Sem-Priesters", txt: "Er öffnet den Toten den Mund. Deine vierte Fähigkeit lädt doppelt so schnell." },
  { id: "skin", slot: "ruestung", name: "Haut des Mehen", txt: "Die Schlange, die sich um Re legt. Alle 8 Sekunden prallt ein Treffer ganz an dir ab." },
  { id: "shards", slot: "handschuhe", name: "Hände des Grabräubers", txt: "Gegner lassen doppelt so viele Scherben fallen." },
  { id: "heavy", slot: "handschuhe", name: "Fäuste des Namenlosen", txt: "Jeder vierte Standardangriff trifft doppelt und betäubt kurz." },
  { id: "s2", slot: "stiefel", name: "Sandalen des Upuaut", txt: "Der Wegöffner geht voran. Deine Ausweichfähigkeit lädt doppelt so schnell." },
  { id: "caravan", slot: "stiefel", name: "Sandalen des Sinuhe", txt: "Er lief bis Retjenu und kam doch heim. 15 % mehr Lauftempo. Isisblut (rote Kugeln) heilt doppelt." },
  { id: "s1", slot: "amulett", name: "Feder der Maat", txt: "Was leicht ist, kostet wenig. Deine erste Fähigkeit kostet nur die Hälfte." },
  { id: "star", slot: "amulett", name: "Splitter des Mesechtiu", txt: "Himmelseisen aus dem Sternbild des Stierschenkels. 15 % mehr kritische Trefferchance." },
  { id: "leech", slot: "ring", name: "Ring der Ammit", txt: "Die Fresserin verschlingt, was zu schwer wiegt. Jeder besiegte Gegner heilt dich um 3 % deines Lebens." },
  { id: "greed", slot: "ring", name: "Ring des Sammlers", txt: "Scherben, Isisblut und Buchseiten fliegen dir aus großer Entfernung zu." },
];
const LEG = Object.fromEntries(LEGS.map((l) => [l.id, l]));
// Das Buch des Thot: zwölf verstreute Seiten. Elite-Gegner und Hüter tragen sie bei sich, und Seite für Seite erzählen sie, warum die Waage stillsteht.
const EVID = [
  ["Die Lichter über Sandtor", "Die Lichter über Sandtor sind keine Irrlichter. Es sind die Toten der Stadt. Sie finden den Weg nicht, denn unten ruft niemand mehr ihre Namen."],
  ["Die leere Schale", "In der Halle der Beiden Wahrheiten hängt die Waage still. Auf der einen Schale liegt die Feder der Maat. Auf der anderen hat lange kein Herz mehr gelegen."],
  ["Von der Häutung", "Apophis wird nicht geboren, er häutet sich. Was er abstreift, steht auf und folgt ihm. So wächst seine Brut, solange die Sonne schwach ist."],
  ["Der fünfte Krug", "Vier Krüge kennt der Balsamierer: für Leber, Lunge, Magen und Gedärm. Das Herz bleibt im Leib, damit es gewogen werden kann. Der Sammler hat einen fünften Krug erfunden."],
  ["Vom Namen", "Was keinen Namen hat, kann Thot nicht aufrufen, und wer nicht aufgerufen wird, kommt nie vor die Waage. Darum schlagen Feinde die Namen aus dem Stein."],
  ["Spruch für das Herz", "„Mein Herz meiner Mutter, steh nicht gegen mich auf.“ So beten die Toten vor der Waage. Doch ein Herz, das in einem Krug liegt, spricht weder für noch gegen sie."],
  ["Der Handel des Königs", "Ein König gab dem Sammler seinen Namen. Dafür sollte sein Herz niemals gewogen werden. Seitdem liegt er wach in seinem Grab, und keiner weiß mehr, wie er hieß."],
  ["Das Zugseil", "In Sokars Land fährt die Barke nicht, sie wird über den Sand gezogen. Ziehen dürfen nur die Gerechtfertigten. Ist keiner mehr gerechtfertigt, bleibt das Seil liegen."],
  ["Die Unvergänglichen", "Die Sterne im Norden gehen niemals unter. Doch der Sammler nahm auch ihnen das Herz, und sie fielen erloschen in den Sand von Rosetau."],
  ["Der Richter, der ging", "Zweiundvierzig Richter sitzen in der Halle, und jeder kennt eine Sünde. Einer kannte seine eigene zu gut. Er stand auf, ging hinaus und kam als der Sammler wieder."],
  ["Lied der Klagefrauen", "„Sieben Stunden bis zum Morgen, und in der siebten liegt der, der das Wasser trinkt. Wer zieht die Barke, wenn keiner gerechtfertigt ist?“"],
  ["Der Krug mit deinem Namen", "Tief in Sokars Höhle steht ein leerer Krug. Auf seinem Siegel steht dein Name, in sauberer Schrift. Er wartet schon lange."],
];
// Symbole aus dem Bildbogen (6 x 6; Feld 35, das versiegelte Buch, steht für eine Seite aus dem Buch des Thot): welche Felder zu welchem Ausrüstungsplatz gehören
const ICON = { waffe: [0, 1, 2, 3, 4, 5], nebenhand: [6, 7], helm: [8, 9, 10, 11], ruestung: [12, 13, 14, 15], handschuhe: [16, 17], stiefel: [18, 19, 20], amulett: [21, 22, 23], ring: [24, 25, 26], potion: 29, staub: 30, leder: 31, eisen: 32, stern: 33, shard: 34, evid: 35 };
// Symbol passend zum Namen (Beil zeigt ein Beil, Maske eine Maske); nur wo nichts passt, entscheidet der Zufall des Teils
const ICON_BY_NAME = [[/beil|axt/i, 1], [/bogen/i, 2], [/stab|zepter|keule/i, 3], [/wickel|faust|binden/i, 4], [/dolch|messer/i, 5], [/klinge|schwert|säbel|speer|richter|dreigestirn|chepesch|harpune/i, 0],
  [/laterne|lampe|räucher/i, 6], [/schild|spiegel|mappe|sandglas|sistrum|palette/i, 7], [/maske/i, 11], [/geier|löwe/i, 10], [/helm|chepresch/i, 9], [/haube|kapuze|turban|hut|reif|nemes|kappe|stirnband/i, 8],
  [/robe|burnus|mantel|rock|schurz|gewand/i, 12], [/wams|haut|fell|koller/i, 13], [/kettenhemd|schuppenpanzer/i, 14], [/pektoral/i, 15], [/handschuh|leinenbinden|hände/i, 16], [/fäustling|fäuste|armschiene/i, 17], [/sandal/i, 18], [/stiefel|läufer|schuh/i, 19], [/beinschiene/i, 20],
  [/sonne|anch|skarabäus|isisknoten/i, 22], [/glas|splitter|stern|djed|feder|schleife/i, 23], [/marke|auge|talisman|siegelstein|sternkarte/i, 21], [/siegelring|mondring|kartusche|skarabäusring/i, 25], [/schlange|uräus/i, 26], [/fayence|schen/i, 24]];
const iconOf = (it) => {
  const a = ICON[it.slot]; for (const [re, i] of ICON_BY_NAME) if (re.test(it.name) && a.includes(i)) return i;
  return a[(it.ic === undefined ? it.id : it.ic) % a.length];
};

// ---------- Fähigkeitenbaum ----------
// Jede Stufe gibt einen Punkt. Ränge verstärken eine Fähigkeit, ab Rang 2 wählt man eine von zwei Ausprägungen.
const SK_RANKS = 5;
const AUGS = { wucht: { name: "Wucht", txt: "25 % mehr Wirkung" }, eile: { name: "Eile", txt: "25 % schneller bereit, 25 % günstiger" } };
const PASSIVES = [
  { id: "zaeh", name: "Starker Ka", txt: "Der Ka ist die Lebenskraft. 6 % mehr Leben je Rang" },
  { id: "scharf", name: "Auge des Horus", txt: "2 % mehr kritische Trefferchance je Rang" },
  { id: "flink", name: "Flügel des Ba", txt: "Der Ba fliegt, wohin er will. 3 % mehr Lauftempo je Rang" },
  { id: "kraft", name: "Fülle des Hapi", txt: "Wie die Nilflut: 1 Kraft pro Sekunde mehr je Rang" },
  { id: "hieb", name: "Hand des Month", txt: "8 % mehr Schaden des Standardangriffs je Rang" },
  { id: "jaeger", name: "Speer des Seth", txt: "Seth steht am Bug und sticht nach der Schlange. 8 % mehr Schaden gegen Elite und Hüter der Stunden je Rang" },
];
const KEYSTONE = {
  ermittler: { name: "Wahr an Stimme", txt: "Wer gerechtfertigt ist, fällt nicht leicht. Unter 35 % Leben erleidest du 30 % weniger Schaden." },
  moench: { name: "Hauch des Schu", txt: "Der dritte Schlag jeder Folge gibt 10 Atem zurück und heilt 2 % deines Lebens." },
  jaegerin: { name: "Upuauts Rudel", txt: "Dein Fuchs beißt doppelt so hart und ein Drittel schneller." },
  forensiker: { name: "Wort des Thot", txt: "Jede fünfte Fähigkeit kostet nichts und wirkt um die Hälfte stärker." },
};
const KEY_NEED = 8;
function treeSpent(h) { const t = h.tree; return Object.values(t.r).reduce((s, v) => s + v, 0) + Object.keys(t.a).length + Object.values(t.p).reduce((s, v) => s + v, 0) + (t.key ? 1 : 0); }
const treePoints = (h) => h.lvl - treeSpent(h);
const respecCost = (h) => 10 + 3 * h.lvl;
let itemId = 1;
function makeItem(ilvl, minRar = 0, force = {}) {
  const roll = Math.random() / (hero ? DIFF[hero.diff].leg : 1), rar = Math.max(minRar, roll < 0.045 ? 3 : roll < 0.16 ? 2 : roll < 0.5 ? 1 : 0), R = RAR[rar];
  const slot = force.slot || pick(Object.keys(SLOT)), it = { id: itemId++, slot, rar, ilvl, aff: {}, ic: force.leg === "sun" ? 0 : ri(0, 59) };
  if (slot === "waffe") it.dmg = Math.round((5 + ilvl * 3.2) * R.mult * rnd(0.88, 1.12));
  if (SLOT[slot].arm) it.armor = Math.round((8 + ilvl * 5) * SLOT[slot].arm * R.mult * rnd(0.88, 1.12));
  const keys = Object.keys(AFF).sort(() => Math.random() - 0.5).slice(0, ri(R.aff[0], R.aff[1]));
  keys.forEach((k) => { it.aff[k] = AFF[k].v(ilvl); });
  const base = pick(SLOT[slot].bases);
  if (rar === 3) { const L = force.leg ? LEG[force.leg] : pick(LEGS.filter((l) => l.slot === slot && !l.quest)); it.leg = L.id; it.name = L.name; }
  else it.name = rar === 2 ? `${base} „${pick(RARE_NAMES)}“` : rar === 1 ? `${base} ${AFF[keys[0]].suf}` : base;
  return it;
}
const itemScore = (it) => !it ? 0 : (it.dmg ? itDmg(it) : 0) * 1.5 + (it.armor ? itArm(it) : 0) * 0.35 + Object.keys(it.aff).reduce((s, k) => s + itAff(it, k) * AFF[k].w, 0) + (it.leg ? 15 + it.ilvl * 2 : 0);
