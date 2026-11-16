// 02 · Ton, Zustand, Werte der Figur, Spielstand
let AC = null, muted = false, lastHit = 0;
function tone(f, d = 0.08, type = "square", vol = 0.05, slide = 0, delay = 0) {
  if (muted || !AC) return;
  try {
    const t = AC.currentTime + delay, o = AC.createOscillator(), gn = AC.createGain();
    o.type = type; o.frequency.setValueAtTime(f, t); if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(30, f + slide), t + d);
    gn.gain.setValueAtTime(vol, t); gn.gain.exponentialRampToValueAtTime(0.0001, t + d);
    o.connect(gn).connect(AC.destination); o.start(t); o.stop(t + d + 0.02);
  } catch (e) { /* ohne Ton weiter */ }
}
const SFX = {
  swing: () => tone(190, 0.06, "triangle", 0.035, -90),
  hit: (crit) => { const n = performance.now(); if (n - lastHit < 45) return; lastHit = n; crit ? tone(520, 0.1, "square", 0.05, -260) : tone(130, 0.07, "square", 0.045, -60); },
  hurt: () => tone(95, 0.16, "sawtooth", 0.06, -45),
  pick: () => tone(660, 0.07, "sine", 0.05, 240),
  legend: () => [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.22, "triangle", 0.06, 0, i * 0.09)),
  level: () => [392, 523, 659].forEach((f, i) => tone(f, 0.2, "triangle", 0.06, 0, i * 0.1)),
  bolt: () => tone(900, 0.1, "sine", 0.035, -520),
  pulse: () => tone(70, 0.45, "sine", 0.09, 220),
  dash: () => tone(300, 0.12, "sine", 0.04, 500),
  boss: () => tone(55, 0.9, "sawtooth", 0.07, 30),
  drink: () => tone(420, 0.18, "sine", 0.05, 180),
  chant: () => [196, 247, 294].forEach((f, i) => tone(f, 0.5, "sine", 0.05, 0, i * 0.05)),
  block: () => tone(240, 0.12, "triangle", 0.06, 300),
  gate: () => [98, 147, 196].forEach((f, i) => tone(f, 1.1, "sine", 0.06, 40, i * 0.22)),
};

let hero = null, st = null, paused = true, started = false;
const keys = {}, ptr = { down: false, rdown: false, x: 0, y: 0, wx: 0, wy: 0, bx: 0, by: 0, mouse: false, seen: false };
// Schrägansicht: Welt (x, y) liegt auf dem Boden, das Bild zeigt bx = (x − y)·ISO, by = (x + y)·ISO/2
const ISO = Math.SQRT1_2, px = (x, y) => (x - y) * ISO, py = (x, y) => (x + y) * ISO * 0.5;
const toWorld = (bx, by) => { const a = bx / ISO, b = 2 * by / ISO; return { x: (a + b) / 2, y: (b - a) / 2 }; };
const view = { w: 800, h: 600, zoom: 1, dpr: 1, ox: 0, oy: 0 };
function freshHero() { return { x: 0, y: 0, r: 14, ang: 0.6, lvl: 1, xp: 0, hp: 1, en: 60, eq: {}, bag: [], cd: {}, buff: {}, atkT: 0, atkA: 0, inv: 0, hurtT: 0, swing: null, flurry: null, tgt: null, kbT: 0, mvx: 0, mvy: 0, combo: 0, hits: 0, skinT: 0, newItems: 0, shards: 0, evid: [], cls: "ermittler", pots: POTS, diff: 0, hc: false, mats: { staub: 0, leder: 0, eisen: 0, stern: 0 }, tree: { r: {}, a: {}, p: {}, key: false }, casts: 0, maxFall: 1 }; }
function calcStats() {
  const h = hero, a = { dmgPct: 0, hp: 0, armor: 0, crit: 0, critDmg: 0, speed: 0, as: 0, regen: 0, loh: 0, thorns: 0, xp: 0, find: 0 }, leg = {};
  Object.values(h.eq).forEach((it) => { if (!it) return; Object.keys(it.aff).forEach((k) => { a[k] += itAff(it, k); }); if (it.armor) a.armor += itArm(it); if (it.leg) leg[it.leg] = true; });
  h.leg = leg;
  const c = CLS[h.cls];
  const P = h.tree.p;
  h.dmg = ((h.eq.waffe ? itDmg(h.eq.waffe) : 4) + 3 + h.lvl * 1.2) * 1.2 * (1 + a.dmgPct / 100);
  h.maxHp = Math.round((110 + h.lvl * 20 + a.hp) * c.hp * (1 + 0.06 * (P.zaeh || 0))); h.hp = Math.min(h.hp, h.maxHp);
  h.armor = a.armor; h.red = 1 - (1 - a.armor / (a.armor + 100)) * (1 - c.red);
  h.crit = Math.min(60, 5 + a.crit + (leg.star ? 15 : 0) + 2 * (P.scharf || 0)); h.critDmg = 50 + a.critDmg;
  // bedächtiger als im ersten Prototyp: langsamer laufen, seltener und dafür härter zuschlagen
  h.speed = 205 * c.spd * (1 + Math.min(45, a.speed + (leg.caravan ? 15 : 0) + 3 * (P.flink || 0)) / 100); h.rate = 1.75 * (1 + a.as / 100);
  h.regen = c.regen + a.regen + (P.kraft || 0); h.loh = a.loh; h.thorns = a.thorns; h.xpMul = 1 + a.xp / 100; h.find = 1 + a.find / 100;
  h.cone = leg.sight ? 1.35 : 1; h.pick = leg.greed ? 170 : 34;
}
const xpNeed = (l) => Math.round(60 * Math.pow(l, 1.6));
function persist() {
  try { localStorage.setItem(SAVE_KEY, JSON.stringify({ v: 1, fall: st ? st.fall : 1, lvl: hero.lvl, xp: hero.xp, eq: hero.eq, bag: hero.bag, muted, itemId, shards: hero.shards, evid: hero.evid, cls: hero.cls, diff: hero.diff, hc: hero.hc, mats: hero.mats, tree: hero.tree, maxFall: hero.maxFall })); } catch (e) { /* kein Speicher: dann eben ohne */ }
}
// Name eines gewöhnlichen, magischen oder seltenen Teils nach den heutigen Listen. Passt der Grundname nicht mehr,
// wird ein heutiger gewählt, möglichst einer mit demselben Symbol. Für Teile mit heutigem Namen ändert sich nichts.
function freshName(it) {
  const S = SLOT[it.slot], keys = Object.keys(it.aff || {}), was = iconOf(it);
  let base = S.bases.find((b) => it.name === b || it.name.startsWith(b + " "));
  if (!base) { const same = S.bases.filter((b) => iconOf({ ...it, name: b }) === was), list = same.length ? same : S.bases; base = list[it.id % list.length]; }
  if (it.rar === 2) { const q = (it.name.match(/„(.+)“/) || [])[1]; return `${base} „${RARE_NAMES.includes(q) ? q : RARE_NAMES[it.id % RARE_NAMES.length]}“`; }
  if (it.rar === 1 && keys.length) return `${base} ${AFF[keys[0]].suf}`;
  return base;
}
function restore() {
  try {
    const s = JSON.parse(localStorage.getItem(SAVE_KEY) || "null");
    if (!s || s.v !== 1 || !CLS[s.cls]) return null;
    hero.cls = s.cls; hero.diff = clamp(s.diff | 0, 0, DIFF.length - 1); hero.hc = !!s.hc;
    hero.lvl = clamp(s.lvl | 0, 1, 99); hero.xp = Math.max(0, +s.xp || 0);
    const ok = (it) => it && SLOT[it.slot] && RAR[it.rar] && it.aff && typeof it.name === "string" && (!it.leg || LEG[it.leg]);
    Object.keys(SLOT).forEach((k) => { if (ok(s.eq && s.eq[k])) hero.eq[k] = s.eq[k]; });
    hero.bag = (Array.isArray(s.bag) ? s.bag : []).filter(ok).slice(0, BAG_MAX);
    [...Object.values(hero.eq), ...hero.bag].forEach((it) => { if (it) it.name = it.leg ? LEG[it.leg].name : freshName(it); });   // alte Namen aus früheren Fassungen bekommen die heutigen
    muted = !!s.muted; itemId = Math.max(itemId, (s.itemId | 0) || 1);
    hero.shards = Math.max(0, s.shards | 0); hero.evid = (Array.isArray(s.evid) ? s.evid : []).filter((i) => Number.isInteger(i) && EVID[i]);
    if (s.mats) Object.keys(MATS).forEach((k) => { hero.mats[k] = Math.max(0, s.mats[k] | 0); });
    if (s.tree && typeof s.tree === "object") hero.tree = { r: { ...(s.tree.r || {}) }, a: { ...(s.tree.a || {}) }, p: { ...(s.tree.p || {}) }, key: !!s.tree.key };
    hero.maxFall = clamp(Math.max(s.maxFall | 0, s.fall | 0), 1, 999);
    return { fall: clamp(s.fall | 0, 1, 999) };
  } catch (e) { return null; }
}
