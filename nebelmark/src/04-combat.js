// 04 · Kampf: Treffer, Tod und Beute, Angriffe, Fähigkeiten
function num(x, y, txt, col, big, lift = 34) { st.nums.push({ x: x + rnd(-8, 8), y, txt, col, life: 0.8, big, lift }); }
function burst(x, y, col, n, spd = 160) { for (let i = 0; i < n; i++) { const a = rnd(0, TAU), v = rnd(spd * 0.3, spd); st.fx.push({ k: "p", x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: rnd(0.25, 0.6), col, lift: rnd(6, 26) }); } }
const ringFx = (x, y, r, col, life = 0.22) => { st.fx.push({ k: "ring", x, y, r, life, max: life, col }); smashAround(x, y, r); };
let curPow = 1;
const skRank = (id) => hero.tree.r[id] || 0, skAug = (id) => hero.tree.a[id];
const skPow = (id) => 1 + 0.12 * skRank(id) + (skAug(id) === "wucht" ? 0.25 : 0);
function dropMat(x, y, kind, n = 1) { st.loot.push({ x, y, mat: kind, n, t: 0 }); }
// Ein Rudel bemerkt die Figur: Versteckte springen hervor, Rudel in Rufweite werden kurz darauf ebenfalls aufmerksam
function wakePack(id) {
  let k = 0;   // die Mitglieder setzen sich nacheinander in Bewegung, nicht alle im selben Augenblick
  st.en.forEach((e) => { if (e.pack !== id || e.active) return; e.active = true; e.seenT = 0.8; e.wait = k++ * 0.35; if (e.hidden) { e.hidden = false; e.stun = Math.max(e.stun, 0.45); burst(e.x, e.y, "#c9b48a", 12, 150); } });
  if (id < 0) { bossWake(); return; }
  const p = st.packs[id]; if (!p || p.awake) return; p.awake = true;
  if (DIFF[hero.diff].alarm) for (const q of st.packs) if (!q.awake && q.alive > 0 && q.alarm <= 0 && dist(p, q) < 330 && los(p, q)) q.alarm = 1.2;
}
function hit(e, mult, opts = {}) {
  const h = hero, T = ET[e.type], src = opts.from || h, crit = Math.random() * 100 < h.crit, a = Math.atan2(e.y - src.y, e.x - src.x);
  let amt = h.dmg * mult * (crit ? 1 + h.critDmg / 100 : 1) * rnd(0.9, 1.1);
  if (h.leg.lantern && angDiff(Math.atan2(e.y - h.y, e.x - h.x), h.ang) < 0.5) amt *= 1.25;
  if (h.leg.sun && (T.undead || T.demon || e.undead)) amt *= 1.6;
  if (h.buff.oath > 0) amt *= 1.3;
  amt *= opts.pow || curPow; if (e.elite || e.type === "boss") amt *= 1 + 0.08 * (h.tree.p.jaeger || 0);
  e.hp -= amt; e.flash = 0.12; if (!e.active) wakePack(e.pack); e.active = true;
  const kb = (opts.kb || 90) / (e.type === "boss" ? 8 : T.ai === "slam" ? 3 : 1);
  e.kx += Math.cos(a) * kb; e.ky += Math.sin(a) * kb;
  if (opts.stun) e.stun = Math.max(e.stun, e.type === "boss" ? opts.stun * 0.3 : opts.stun);
  if (opts.mark) e.mark = opts.mark;
  num(e.x, e.y, Math.round(amt), crit ? "#ffd75e" : "#e6dfc8", crit, e.r * 5.6 + 6); SFX.hit(crit); burst(e.x, e.y, crit ? "#ffd75e" : "#ffe9a8", crit ? 12 : 4, crit ? 200 : 120);
  if (crit) { st.shake = Math.max(st.shake, 4); if (h.leg.critres) h.en = Math.min(100, h.en + 5); }
  if (h.loh && !opts.noLoh) h.hp = Math.min(h.maxHp, h.hp + h.loh);
  if (e.hp <= 0) kill(e);
  return amt;
}
const owns = (leg) => Object.values(hero.eq).some((it) => it && it.leg === leg) || hero.bag.some((it) => it.leg === leg);
function kill(e) {
  const i = st.en.indexOf(e); if (i < 0) return; st.en.splice(i, 1);
  const h = hero, T = ET[e.type], boss = e.type === "boss"; if (!boss) st.kills++;
  const sk = spriteKey(e); if (sk && ART.sprite[sk] && ART.sprite[sk].cells.down) { st.dead.push({ x: e.x, y: e.y, key: sk, face: e.face, tall: foeTall(e), t: 0 }); if (st.dead.length > 40) st.dead.shift(); }
  burst(e.x, e.y, e.col || T.col, boss ? 60 : e.elite ? 24 : 10, boss ? 320 : 170);
  st.progress += e.w; if (st.packs[e.pack]) st.packs[e.pack].alive--;
  if (h.leg.leech) h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.03);
  gainXp(e.xp * h.xpMul);
  if (e.mark > 0 && !boss) { ringFx(e.x, e.y, 115, "#efe6cf", 0.3); st.shake = Math.max(st.shake, 5); each((x) => { if (dist(x, e) < 115 + x.r) hit(x, 1.5, { from: e, kb: 130, noLoh: true }); }); }   // Erschütternde Hand: der Fall reißt Nachbarn mit
  if (e.w > 0 && Math.random() < 0.45) st.loot.push({ x: e.x + rnd(-16, 16), y: e.y + rnd(-16, 16), shard: ri(1, 3) * (e.elite ? 4 : 1) * (h.leg.shards ? 2 : 1), t: 0 });
  if ((e.elite && Math.random() < 0.4) || boss) { const open = EVID.map((_, i) => i).filter((i) => !h.evid.includes(i) && !st.loot.some((l) => l.evid === i)); if (open.length) st.loot.push({ x: e.x + rnd(-24, 24), y: e.y + rnd(-24, 24), evid: open[0], t: 0 }); }
  const mk = MAT_OF[e.look || T.look];
  if (e.w > 0 && Math.random() < (e.elite ? 1 : 0.12)) dropMat(e.x + rnd(-18, 18), e.y + rnd(-18, 18), "staub", e.elite ? ri(2, 3) : 1);
  if (mk && !boss && e.w > 0 && Math.random() < (e.elite ? 0.6 : mk === "stern" ? 0.05 : 0.1)) dropMat(e.x + rnd(-18, 18), e.y + rnd(-18, 18), mk, 1);
  if (boss) {
    dropMat(e.x - 34, e.y + 20, "staub", ri(4, 6)); dropMat(e.x - 20, e.y + 44, mk || "stern", mk === "stern" ? 2 : 3); if (mk !== "stern") dropMat(e.x + 6, e.y + 52, "stern", 1);
    st.loot.push({ x: e.x + 30, y: e.y + 30, shard: 25 * (h.leg.shards ? 2 : 1), t: 0 });
    const sun = e.look === "koenig" && !owns("sun");   // der König ohne Namen gibt beim ersten Mal das goldene Schwert her
    for (let k = 0; k < 4; k++) dropItem(e.x, e.y, k === 0 && sun ? makeItem(st.fall + 1, 3, { slot: "waffe", leg: "sun" }) : k === 1 && st.def.legs && Math.random() < 0.4 ? bossLeg() : makeItem(st.fall + 1, k === 0 && Math.random() < 0.6 ? 3 : 2), k / 4 * TAU + 0.6, 84);
    st.boss = null; st.bossRef = null; $("boss").hidden = true; st.portal = { x: e.x, y: e.y, t: 0 }; st.shake = 14;
    st.en = st.en.filter((x) => { if (dist(x, e) > 700) return true; burst(x.x, x.y, C.wisp, 8); return false; });   // was in seiner Nähe war, löst sich auf
    banner(hourOf(st.fall) === ACT.length ? "Die Krüge zerspringen. Die Waage bewegt sich wieder." : hourOf(st.fall) === HOURS ? "Die Sonne geht auf." : "Die Stunde ist vollendet. Eine Pforte steht offen.", "DER HÜTER IST GEFALLEN"); SFX.legend();
    return;
  }
  if (Math.random() < (e.elite ? 1 : T.drop * h.find)) dropItem(e.x, e.y, makeItem(st.fall, e.elite ? 1 : 0));
  if (e.elite && Math.random() < 0.5) dropItem(e.x, e.y, makeItem(st.fall, 0));
  if (e.elite && Math.random() < 0.08) dropItem(e.x, e.y, makeItem(st.fall, 3));
  if (Math.random() < (T.ai === "slam" ? 0.3 : e.elite ? 0.5 : 0.07)) st.loot.push({ x: e.x + rnd(-14, 14), y: e.y + rnd(-14, 14), globe: true, t: 0 });
}
// Jeder Endgegner hat zwei legendäre Teile, die bei ihm deutlich häufiger fallen: ein Grund, einen Fall zu wiederholen
function bossLeg() { const L = LEG[pick(st.def.legs)]; return makeItem(st.fall + 1, 3, { slot: L.slot, leg: L.id }); }
function dropItem(x, y, it, ang, far) {
  const a = ang === undefined ? rnd(0, TAU) : ang, d = far || rnd(18, 54), p = freePath(x, y, clamp(x + Math.cos(a) * d, 20, WORLD.w - 20), clamp(y + Math.sin(a) * d, 20, WORLD.h - 20)); st.loot.push({ x: p.x, y: p.y, item: it, t: 0 });
  if (it.rar === 3) { SFX.legend(); st.shake = Math.max(st.shake, 6); }
}
function gainXp(x) {
  const h = hero; h.xp += x;
  while (h.xp >= xpNeed(h.lvl)) {
    h.xp -= xpNeed(h.lvl); h.lvl++; calcStats(); h.hp = h.maxHp; h.en = 100;
    banner(`Stufe ${h.lvl}`, "STUFENAUFSTIEG"); SFX.level(); burst(h.x, h.y, C.hero, 30, 240); persist();
  }
}
function hurt(dmg, src) {
  const h = hero; if (h.inv > 0 || paused) return;
  if (h.leg.skin && h.skinT <= 0) { h.skinT = 8; num(h.x, h.y, "abgeprallt", "#c9fffb", false, 100); SFX.block(); return; }
  if (src && h.thorns && st.en.includes(src)) { src.hp -= h.thorns; src.flash = 0.1; num(src.x, src.y, h.thorns, "#d9b36c", false, src.r * 2.6); if (src.hp <= 0) kill(src); }
  const amt = dmg * (1 - h.red) * rnd(0.9, 1.1) * (h.buff.oath > 0 ? 0.8 : 1) * (h.buff.mantra > 0 ? 0.7 : 1) * (h.tree.key && h.cls === "ermittler" && h.hp < h.maxHp * 0.35 ? 0.7 : 1); h.hp -= amt; h.hurtT = 0.25; st.shake = Math.max(st.shake, 5);
  num(h.x, h.y, Math.round(amt), "#ff6b5e", false, 98); SFX.hurt();
  if (h.hp <= 0) {
    h.hp = 0; paused = true; st.deaths++; $("dead").hidden = false;
    $("deadTxt").textContent = h.hc ? `Hardcore: ${CLS[h.cls].name}, Stufe ${h.lvl}, gefallen in „${st.def.name}“. Dieses Herz liegt jetzt auf der Waage. Ausrüstung und Erfahrung sind verloren.` : "Dein Ba hat den Weg zurück in den Leib gefunden, und die Laterne brennt noch. Was dich angegriffen hat, ist noch dort. Deine Ausrüstung und deine Erfahrung behältst du.";
    $("reviveBtn").textContent = h.hc ? "Neue Figur anlegen" : "Zurück in die Stunde";
    if (h.hc) { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* egal */ } }
    $("reviveBtn").focus();
  }
}
const each = (fn) => [...st.en].forEach(fn);   // Kopie: Gegner können währenddessen sterben
function swingAt(ang, mult = 1, reach = MELEE, arc = 1.05, opts = {}) {
  const h = hero; h.swing = { ang, t: 0.14, r: reach + 10, arc }; SFX.swing();
  let n = 0;
  each((e) => { const d = dist(e, h); if (d < reach + e.r + 8 && (d < e.r + h.r + 6 || angDiff(Math.atan2(e.y - h.y, e.x - h.x), ang) < arc)) { hit(e, mult, opts); n++; } });
  smashAround(h.x + Math.cos(ang) * reach * 0.6, h.y + Math.sin(ang) * reach * 0.6, reach * 0.55);
  if (n) h.en = Math.min(100, h.en + 5 + Math.min(4, n - 1));
}
// Standardangriff je Klasse: Hieb, Faust, Pfeil oder Funke. Er kostet nichts und füllt die Kraft auf.
function basicAttack(ang) {
  const h = hero, c = CLS[h.cls]; h.atkT = 1 / h.rate; h.ang = ang; h.atkA = 0.22; h.hits++;
  const heavy = h.leg.heavy && h.hits % 4 === 0, hm = (heavy ? 2 : 1) * (1 + 0.08 * (h.tree.p.hieb || 0)), ho = heavy ? { stun: 0.6 } : {};
  if (c.basic === "melee") {
    if (c.combo && ++h.combo >= 3) { h.combo = 0; if (h.tree.key) { h.en = Math.min(100, h.en + 10); h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.02); } swingAt(ang, 1.9 * hm, c.range * 1.6, 1.35, { ...ho, kb: 150 }); st.shake = Math.max(st.shake, 3); tone(110, 0.12, "sine", 0.06, 60); }   // dritter Schlag der Folge
    else swingAt(ang, hm, c.range, 1.05, ho);
    return;
  }
  const shot = c.basic === "shot", v = shot ? 720 : 540;
  st.shots.push({ x: h.x, y: h.y, vx: Math.cos(ang) * v, vy: Math.sin(ang) * v, r: shot ? 4 : 6, mult: (shot ? 1 : 0.95) * hm, pow: 1, stun: ho.stun, hero: true, life: shot ? 0.6 : 0.7, pierce: shot ? 0 : 1, seen: new Set(), col: shot ? "#d8ffd8" : "#e2b8ff", gen: 4 });
  SFX.bolt();
}
function nearest(range, from = hero) { let best = null, bd = range; st.en.forEach((e) => { if (e.hidden) return; const d = dist(e, from) - e.r; if (d < bd) { bd = d; best = e; } }); return best; }
// Fähigkeit auslösen. auto = vom Knopf (Finger): zielt selbst auf den nächsten Gegner
function cast(id, auto) {
  const h = hero, s = SK[id], c = CLS[h.cls], slot = c.sk.indexOf(id); if (paused || !s || (h.cd[id] || 0) > 0) return false;
  const eile = skAug(id) === "eile", free = h.tree.key && h.cls === "forensiker" && id !== "potion" && (h.casts + 1) % 5 === 0;   // Überladung: jede fünfte Fähigkeit ist gratis und stärker
  const cost = free ? 0 : s.cost * (slot === 0 && h.leg.s1 ? 0.5 : 1) * (eile ? 0.75 : 1); if (h.en < cost) return false;
  if (id === "potion") {
    if (h.pots <= 0 || h.hp >= h.maxHp) return false;
    h.pots--; h.cd.potion = s.cd; h.hp = Math.min(h.maxHp, h.hp + h.maxHp * (h.leg.potion ? 1 : 0.6)); burst(h.x, h.y, C.blood, 16, 120); SFX.drink(); return true;
  }
  let ang = h.ang, tx, ty; const near = nearest(520);
  if (auto || !ptr.mouse) { if (near) { ang = Math.atan2(near.y - h.y, near.x - h.x); tx = near.x; ty = near.y; } else { tx = h.x + Math.cos(ang) * 220; ty = h.y + Math.sin(ang) * 220; } }
  else { tx = ptr.wx; ty = ptr.wy; ang = Math.atan2(ty - h.y, tx - h.x); }
  let first = null;
  if (id === "chain" || id === "hetz") {
    if (id === "hetz" && !st.pet) return false;
    first = st.en.filter((e) => dist(e, h) < (id === "chain" ? 470 : 520)).sort((a, b) => Math.hypot(a.x - tx, a.y - ty) - Math.hypot(b.x - tx, b.y - ty))[0]; if (!first) return false;
  }
  h.en -= cost; h.cd[id] = s.cd * ((slot === 1 && h.leg.s2) || (slot === 3 && h.leg.s4) ? 0.5 : 1) * (eile ? 0.75 : 1) * (s.util ? 1 - 0.06 * skRank(id) : 1); h.ang = ang; h.atkA = 0.22; h.casts++;
  const pw = skPow(id) * (free ? 1.5 : 1), upw = s.util ? 1 + (skAug(id) === "wucht" ? 0.25 : 0) : pw; curPow = pw;
  if (free) { ringFx(h.x, h.y, 60, "#ffd75e", 0.3); tone(1400, 0.1, "sine", 0.04, 300); }
  const shoot = (a, o) => st.shots.push({ x: h.x, y: h.y, vx: Math.cos(a) * o.v, vy: Math.sin(a) * o.v, r: o.r || 6, mult: o.mult, pow: pw, kb: o.kb, hero: true, life: o.life || 0.9, pierce: o.pierce || 0, seen: new Set(), col: o.col });
  const jump = (maxD, dmg) => {   // Sprung, Rolle, Schritt: zum Ziel versetzen, kurz unverwundbar
    const d = clamp(Math.hypot(tx - h.x, ty - h.y) - (auto && dmg ? 40 : 0), 60, maxD), ox = h.x, oy = h.y, a = auto && !dmg && near ? ang + Math.PI : ang;   // ohne Schaden weicht der Knopf vom Gegner weg aus
    const fp = freePath(h.x, h.y, clamp(h.x + Math.cos(a) * d, 20, WORLD.w - 20), clamp(h.y + Math.sin(a) * d, 20, WORLD.h - 20)); h.x = fp.x; h.y = fp.y; pushOut(h);
    h.inv = Math.max(h.inv, 0.45); st.fx.push({ k: "line", x: ox, y: oy, x2: h.x, y2: h.y, life: 0.25, max: 0.25, col: c.col }); SFX.dash();
    if (dmg) { ringFx(h.x, h.y, 75, c.col, 0.2); each((e) => { if (dist(e, h) < 75 + e.r) hit(e, dmg, { kb: 160 }); }); }
  };
  if (id === "whirl") { ringFx(h.x, h.y, 95, C.hero); SFX.swing(); each((e) => { if (dist(e, h) < 95 + e.r) hit(e, 1.7, { kb: 140 }); }); }
  else if (id === "dash") jump(270, 1.5);
  else if (id === "bolt") { shoot(ang, { v: 620, mult: 2.2, pierce: 3, col: C.shotH }); SFX.bolt(); }
  else if (id === "oath") { h.buff.oath = 6 * upw; ringFx(h.x, h.y, 120, C.hero, 0.4); SFX.chant(); }
  else if (id === "pulse" || id === "nova") {
    const R = id === "pulse" ? 230 : 210, col = id === "pulse" ? "#c06be0" : C.wisp; ringFx(h.x, h.y, R, col, 0.4); st.shake = 8; SFX.pulse();
    each((e) => { if (dist(e, h) < R + e.r) hit(e, id === "pulse" ? 2.5 : 1.8, { kb: 60, stun: id === "pulse" ? 2 : 2.6 }); });
    st.shots = st.shots.filter((p) => p.hero || dist(p, h) > R);
  }
  else if (id === "salve") { [-0.36, -0.18, 0, 0.18, 0.36].forEach((o) => shoot(ang + o, { v: 700, mult: 1.15, r: 4, life: 0.6, col: "#d8ffd8" })); SFX.bolt(); }
  else if (id === "roll") jump(230 * upw, 0);
  else if (id === "pierce") { shoot(ang, { v: 860, mult: 3.2, r: 8, pierce: 99, life: 0.8, col: "#d8ffd8" }); SFX.bolt(); st.shake = Math.max(st.shake, 3); }
  else if (id === "rain") { const d = Math.min(420, Math.hypot(tx - h.x, ty - h.y)); st.zones.push({ x: h.x + Math.cos(ang) * d, y: h.y + Math.sin(ang) * d, r: 125, life: 3.2, tick: 0, every: 0.35, mult: 0.85, pow: pw, col: "#7ad08a", rain: true }); tone(600, 0.3, "sawtooth", 0.03, -300); }
  else if (id === "hetz") {
    const p = st.pet; st.fx.push({ k: "line", x: p.x, y: p.y, x2: first.x, y2: first.y, life: 0.25, max: 0.25, col: "#f0c98a" });
    p.x = first.x - Math.cos(ang) * (first.r + 8); p.y = first.y - Math.sin(ang) * (first.r + 8); p.tgt = first; p.rage = 5; p.cd = 0.3; p.bite = 0.15;
    each((e) => { if (ET[e.type].animal && !e.elite && dist(e, p) < 280) e.fear = 4; });   // feindliche Tiere nehmen Reißaus
    hit(first, 3, { from: h, kb: 120 }); tone(500, 0.15, "sawtooth", 0.04, 300);
  }
  else if (id === "blink") jump(330 * upw, 0);
  else if (id === "glass") { const d = Math.min(440, Math.hypot(tx - h.x, ty - h.y)); st.zones.push({ x: h.x + Math.cos(ang) * d, y: h.y + Math.sin(ang) * d, r: 140, life: 5 * upw, tick: 0, every: 0.5, mult: 0.35, pow: 1 + 0.12 * skRank(id), col: "#8fe3e0", slow: true }); tone(300, 0.5, "sine", 0.04, -150); }
  else if (id === "meteor") { const d = Math.min(460, Math.hypot(tx - h.x, ty - h.y)); st.late.push({ x: h.x + Math.cos(ang) * d, y: h.y + Math.sin(ang) * d, r: 115, t: 0.7, max: 0.7, mult: 4.5, pow: pw }); tone(900, 0.7, "sine", 0.04, -820); }
  else if (id === "chain") {
    const seen = new Set(); let from = h, e = first;
    for (let i = 0; i < 5 && e; i++) {
      seen.add(e); st.fx.push({ k: "line", x: from.x, y: from.y, x2: e.x, y2: e.y, life: 0.18, max: 0.18, col: "#e2b8ff" }); const pos = { x: e.x, y: e.y }; hit(e, 1.6, { kb: 30 });
      from = pos; e = st.en.filter((x) => !seen.has(x) && dist(x, pos) < 190).sort((a, b) => dist(a, pos) - dist(b, pos))[0];
    }
    tone(1200, 0.12, "square", 0.03, -700);
  }
  else if (id === "flurry") h.flurry = { n: 5, t: 0, ang, pow: pw };
  else if (id === "step") jump(250, 1.1);
  else if (id === "mantra") { h.buff.mantra = 7 * upw; ringFx(h.x, h.y, 180, "#efe6cf", 0.5); SFX.chant(); }
  else if (id === "palm") {
    h.swing = { ang, t: 0.2, r: 160, arc: 0.95 }; st.shake = 9; SFX.pulse(); ringFx(h.x + Math.cos(ang) * 70, h.y + Math.sin(ang) * 70, 80, "#efe6cf", 0.3);
    each((e) => { const d = dist(e, h); if (d < 150 + e.r && (d < e.r + h.r + 8 || angDiff(Math.atan2(e.y - h.y, e.x - h.x), ang) < 0.95)) hit(e, 3.2, { kb: 200, mark: 6, stun: 0.5 }); });
  }
  else if (id === "wave") { shoot(ang, { v: 520, mult: 2, r: 16, pierce: 99, life: 0.42, col: "#efe6cf", kb: 230 }); tone(160, 0.2, "sine", 0.06, 120); }
  curPow = 1;
  return true;
}
function pushOut(o, mx = 0, my = 0, step = 0) {
  for (const b of st.obst) {
    const dx = o.x - b.x, dy = o.y - b.y, d = Math.hypot(dx, dy), m = b.r + o.r; if (d >= m || d < 0.01) continue;
    const nx = dx / d, ny = dy / d; o.x = b.x + nx * m; o.y = b.y + ny * m;
    const into = -(mx * nx + my * ny);
    if (step && into > 0.2) { const side = mx * -ny + my * nx >= 0 ? 1 : -1; o.x += -ny * side * step * into; o.y += nx * side * step * into; }
  }
  o.x = clamp(o.x, o.r, WORLD.w - o.r); o.y = clamp(o.y, o.r, WORLD.h - o.r); pushWalls(o);
}
