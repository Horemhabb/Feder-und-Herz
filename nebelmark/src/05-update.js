// 05 · Ein Zeitschritt: Eingabe, Held, Begleittier, Gegner, Geschosse, Beute
// Gegner unter dem Zeiger: gemessen an der stehenden Figur im Bild, nicht nur am Fußpunkt
function enemyAt(bx, by) {
  let best = null, bd = 1e9;
  for (const e of st.en) {
    if (e.hidden) continue;
    const ex = px(e.x, e.y), ey = py(e.x, e.y), tall = e.r * 2.8 + 10;
    if (Math.abs(bx - ex) < e.r + 16 && by > ey - tall && by < ey + e.r * 0.6 + 8) { const d = Math.abs(bx - ex) + Math.abs(by - (ey - tall / 2)); if (d < bd) { bd = d; best = e; } }
  }
  return best;
}
// Was ein Gegner tut, solange er die Figur nicht bemerkt hat: lauern, Wache stehen, umherstreifen, seine Strecke ablaufen.
// Bemerkt wird man nach vorn auf weite, im Rücken nur auf kurze Entfernung; dazwischen liegt ein Augenblick des Stutzens.
function idleFoe(e, dt, h) {
  const d = dist(e, h); e.dx = e.dy = 0; if (d > 1000) return;
  if (e.hidden) { if (d < 150 && los(e, h)) wakePack(e.pack); return; }
  if (d < 420 && los(e, h)) {
    const front = angDiff(e.face, Math.atan2(h.y - e.y, h.x - e.x)) < 1.25;
    if (d < (front ? 350 : 180) * DIFF[hero.diff].sight) { e.alert = (e.alert || 0) + dt; e.face = Math.atan2(h.y - e.y, h.x - e.x); if (e.alert > 0.45) wakePack(e.pack); return; }
  }
  e.alert = 0;
  const P = st.packs[e.pack], move = (a, f) => { e.dx = Math.cos(a); e.dy = Math.sin(a); e.face = a; e.x += e.dx * e.spd * f * dt; e.y += e.dy * e.spd * f * dt; pushOut(e, e.dx, e.dy, e.spd * f * dt); };
  if (e.idle === "patrol" && P && P.way) {
    const wp = P.way[P.wi]; if (!P.field || P.fi !== P.wi) { P.field = flood(Math.floor(wp.x / CELL), Math.floor(wp.y / CELL)); P.fi = P.wi; }
    if (!P.leader || !st.en.includes(P.leader)) P.leader = e;
    const dw = Math.hypot(wp.x - e.x, wp.y - e.y);
    if (P.leader === e) { P.x = e.x; P.y = e.y; if (P.rest > 0) P.rest -= dt; else if (dw < 55) { P.wi = (P.wi + 1) % P.way.length; P.rest = rnd(1.5, 4); } }
    if (!(P.rest > 0) && dw > 60) move(fieldDir(P.field, e, Math.atan2(wp.y - e.y, wp.x - e.x)), 0.4);
  } else if (e.idle === "wander") {
    if ((e.wt -= dt) <= 0) { e.wt = rnd(2, 6); e.wm = rnd(0.5, 1.4); e.wa = Math.hypot(e.x - e.ox, e.y - e.oy) > 110 ? Math.atan2(e.oy - e.y, e.ox - e.x) : rnd(0, TAU); }
    if (e.wm > 0) { e.wm -= dt; move(e.wa, 0.3); }
  }
}
function update(dt) {
  const h = hero, c = CLS[h.cls]; st.t += dt;
  // Zielen und Laufen. Tasten bewegen in Bildrichtung: W ist oben im Bild, nicht „Norden“ der Welt.
  ptr.bx = view.ox + ptr.x / view.zoom; ptr.by = view.oy + ptr.y / view.zoom;
  const pw = toWorld(ptr.bx, ptr.by); ptr.wx = pw.x; ptr.wy = pw.y;
  const kx = (keys.d ? 1 : 0) - (keys.a ? 1 : 0), ky = (keys.s ? 1 : 0) - (keys.w ? 1 : 0);
  let mx = 0, my = 0;
  if (ptr.mouse && ptr.seen) h.ang = Math.atan2(ptr.wy - h.y, ptr.wx - h.x);
  let attackAng = null;
  if (kx || ky) {
    const v = toWorld(kx, ky * 0.5), l = Math.hypot(v.x, v.y); mx = v.x / l; my = v.y / l; h.kbT = 0.4;
    if (!ptr.mouse) h.ang = Math.atan2(my, mx); if (ptr.down) attackAng = h.ang;
  } else {
    h.kbT -= dt;
    if (ptr.down && h.kbT <= 0) {
      h.tgt = enemyAt(ptr.bx, ptr.by);
      const tx = h.tgt ? h.tgt.x : ptr.wx, ty = h.tgt ? h.tgt.y : ptr.wy, d = Math.hypot(tx - h.x, ty - h.y), a = Math.atan2(ty - h.y, tx - h.x);
      const clear = !h.tgt || los(h, h.tgt);   // ein Gegner hinter der Ecke wird nicht durch die Mauer beschossen: die Figur läuft erst um die Ecke
      if (h.tgt && clear && d < c.range + h.tgt.r - 6) { attackAng = a; h.ang = a; }
      else if (d > 8) { const am = clear ? a : wayTo(tx, ty); mx = Math.cos(am); my = Math.sin(am); if (!ptr.mouse || h.tgt) h.ang = am; }
    } else if (ptr.down) attackAng = h.ang;
    else { const e = nearest(c.range - 6); if (e && los(h, e) && (e.active || c.basic === "melee")) attackAng = Math.atan2(e.y - h.y, e.x - h.x); }   // ist ein Gegner in Reichweite, greifst du von selbst an
  }
  if (h.flurry) mx = my = 0;   // wer schlägt, steht
  const bx0 = h.x, by0 = h.y;
  // Anlaufen und Abbremsen statt sofort voller Geschwindigkeit; der Schrittzähler treibt die Laufbewegung
  const acc = Math.min(1, dt * (mx || my ? 11 : 16)); h.vx = (h.vx || 0) + (mx * h.speed - (h.vx || 0)) * acc; h.vy = (h.vy || 0) + (my * h.speed - (h.vy || 0)) * acc;
  const vh = Math.hypot(h.vx, h.vy); if (vh < 4) h.vx = h.vy = 0; h.step = ((h.step || 0) + vh * dt / 62) % 2;
  h.x += h.vx * dt; h.y += h.vy * dt; h.mvx = h.vx / h.speed; h.mvy = h.vy / h.speed; mx = h.mvx; my = h.mvy; pushOut(h, mx, my, h.speed * dt);
  if ((mx || my) && Math.hypot(h.x - bx0, h.y - by0) < h.speed * dt * 0.5 && st.obst.some((o) => o.brk && dist(o, h) < o.r + h.r + 6)) { smashAround(h.x + mx * 18, h.y + my * 18, 16); h.atkA = 0.2; }
  h.atkT -= dt; if (attackAng !== null && h.atkT <= 0 && !h.flurry) basicAttack(attackAng);
  if (ptr.rdown) cast(c.rmb, false);
  if (h.swing && (h.swing.t -= dt) <= 0) h.swing = null;
  if (h.flurry) { const f = h.flurry; if ((f.t -= dt) <= 0) { f.t = 0.11; f.n--; h.swing = { ang: f.ang, t: 0.09, r: 100, arc: 0.9 }; h.atkA = 0.15; SFX.swing(); each((e) => { const d = dist(e, h); if (d < 92 + e.r && (d < e.r + h.r + 6 || angDiff(Math.atan2(e.y - h.y, e.x - h.x), f.ang) < 0.9)) hit(e, 0.62, { kb: 30, pow: f.pow }); }); if (f.n <= 0) h.flurry = null; } }
  Object.keys(h.cd).forEach((k) => { if (h.cd[k] > 0) h.cd[k] -= dt; });
  Object.keys(h.buff).forEach((k) => { if (h.buff[k] > 0) h.buff[k] -= dt; });
  if (h.buff.mantra > 0) h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.04 * dt);
  h.en = Math.min(100, h.en + h.regen * dt); h.inv -= dt; h.hurtT -= dt; h.atkA -= dt; h.skinT -= dt;

  // Gegner. Im Dungeon wird alle Viertelsekunde der kürzeste Weg zur Figur neu berechnet.
  if (st.grid && (st.flowT -= dt) <= 0) { st.flowT = 0.25; st.flow = flood(Math.floor(h.x / CELL), Math.floor(h.y / CELL)); }
  for (const c of st.chests) if (!c.open && dist(c, h) < c.r + h.r + 16) openChest(c);
  const act = [], sep = [], DF = DIFF[h.diff];
  // Angriffsplätze: nur die nächsten Nahkämpfer dürfen heran, die anderen umkreisen die Figur auf Abstand, bis ein Platz frei wird
  const mel = st.en.filter((e) => e.active && e.type !== "boss" && ET[e.type].ai !== "ranged" && !(e.fear > 0)).map((e) => [dist(e, h) - (e.slot ? 45 : 0), e]).sort((p, q) => p[0] - q[0]);
  mel.forEach(([, e], i) => { e.slot = i < DF.slots; e.ring = 150 + (i % 3) * 28; });
  st.shotT = (st.shotT || 0) - dt;
  for (const q of st.packs) if (q.alarm > 0 && (q.alarm -= dt) <= 0 && !q.awake) wakePack(q.id);
  for (const e of st.en) {
    if (!e.active) { idleFoe(e, dt, h); if (!e.active) { if (e.dx || e.dy) sep.push(e); continue; } }
    act.push(e); sep.push(e); e.seenT -= dt;
    e.flash -= dt; e.cdT -= dt; e.strike -= dt; e.mark -= dt;
    if (e.kx || e.ky) { const kp = freePath(e.x, e.y, e.x + e.kx * dt * 6, e.y + e.ky * dt * 6); e.x = kp.x; e.y = kp.y; } e.kx *= Math.pow(0.0001, dt); e.ky *= Math.pow(0.0001, dt); if (Math.abs(e.kx) + Math.abs(e.ky) < 1) e.kx = e.ky = 0;
    e.dx = e.dy = 0;
    if (e.stun > 0) { e.stun -= dt; e.pre = 0; pushOut(e); continue; }
    if (e.wait > 0) { e.wait -= dt; e.face = Math.atan2(h.y - e.y, h.x - e.x); continue; }
    const T = ET[e.type], sp = e.slow > 0 ? 0.4 : 1; e.slow -= dt;
    const d = dist(e, h), a0 = Math.atan2(h.y - e.y, h.x - e.x), see = los(e, h), a = (see && los(e, h, true)) || !st.flow ? a0 : fieldDir(st.flow, e, a0), go = (dir, f = 1) => { e.dx = Math.cos(dir); e.dy = Math.sin(dir); e.face = dir; e.x += e.dx * e.spd * f * sp * DF.spd * dt; e.y += e.dy * e.spd * f * sp * DF.spd * dt; };
    e.face = a;
    if (e.fear > 0) { e.fear -= dt; go(a + Math.PI, 1.15); }
    else if (e.slot === false && T.ai !== "ranged" && e.type !== "boss" && !(e.pre > 0) && !(e.wind > 0)) {   // kein Angriffsplatz frei: Abstand halten und lauern
      if (!see) go(a, 0.8); else if (d < e.ring - 18) go(a + Math.PI, 0.6); else if (d > e.ring + 30) go(a, 0.85); else { go(a0 + Math.PI / 2 * (e.ox % 2 > 1 ? 1 : -1), 0.3); e.face = a0; }
    }
    else if (T.ai === "swarm") {
      if (d > e.r + h.r + 4) go(a + Math.sin(st.t * 3 + e.ox) * 0.5); else if (e.cdT <= 0) { e.cdT = T.atk; e.strike = 0.15; hurt(e.dmg, e); }
    } else if (T.ai === "melee") {   // holt sichtbar aus: wer rechtzeitig einen Schritt zurück macht, wird nicht getroffen
      const reach = e.r + h.r + 16;
      if (e.pre > 0) { if ((e.pre -= dt) <= 0) { e.strike = 0.18; if (d < reach + 14) hurt(e.dmg, e); } }
      else if (d < reach && e.cdT <= 0) { e.pre = 0.5; e.cdT = T.atk; }
      else if (d > reach - 8) go(a);
    } else if (T.ai === "ranged") {
      if (d > 300) go(a); else if (d < 170) go(a + Math.PI, 0.9); else go(a + Math.PI / 2 * (e.ox % 2 > 1 ? 1 : -1), 0.45);
      if (see && e.cdT <= 0 && st.shotT <= 0 && d < T.range + 40) { st.shotT = DF.gap; st.shots.push({ x: e.x, y: e.y, vx: Math.cos(a0) * 215, vy: Math.sin(a0) * 215, r: 6, dmg: e.dmg, life: 2.6, col: T.shot, src: e }); e.cdT = T.atk * rnd(0.8, 1.2); e.strike = 0.2; e.face = a0; }
    } else if (T.ai === "slam") {
      if (e.wind > 0) { e.wind -= dt; if (e.wind <= 0) { ringFx(e.x, e.y, 92, C.blood, 0.25); st.shake = Math.max(st.shake, 7); e.strike = 0.2; if (dist(e, h) < 92 + h.r) hurt(e.dmg, e); } }
      else if (d < 96 && e.cdT <= 0) { e.wind = 0.8; e.cdT = T.atk; } else if (d > e.r + h.r) go(a);
    } else bossAI(e, d, a, dt, go);
    pushOut(e, e.dx, e.dy, e.spd * dt);
  }
  for (let i = 0; i < sep.length; i++) for (let j = i + 1; j < sep.length; j++) {   // Gegner schieben sich auseinander
    const p = sep[i], q = sep[j], dx = q.x - p.x, dy = q.y - p.y, d = Math.hypot(dx, dy), m = p.r + q.r;
    if (d < m && d > 0.01) { const f = (m - d) / d / 2; p.x -= dx * f; p.y -= dy * f; q.x += dx * f; q.y += dy * f; }
  }
  for (const e of sep) pushWalls(e);   // niemand wird dabei in eine Mauer geschoben

  // Begleittier der Waldläuferin: bleibt bei ihr, beißt, was ihr zu nahe kommt
  const p = st.pet, pk2 = h.tree.key && h.cls === "jaegerin";
  if (p) {
    p.cd -= dt; p.rage -= dt; p.bite -= dt;
    let t = p.tgt && st.en.includes(p.tgt) && dist(p.tgt, h) < 440 ? p.tgt : null;
    if (!t) { let bd = 300; for (const e of act) { const d = dist(e, h); if (d < bd) { bd = d; t = e; } } }
    p.tgt = t;
    const gx = t ? t.x : h.x - Math.cos(h.ang) * 46, gy = t ? t.y : h.y - Math.sin(h.ang) * 46, d = Math.hypot(gx - p.x, gy - p.y), reach = t ? t.r + 12 : 12;
    p.mv = d > reach;
    if (p.mv) { const v = Math.min(d - reach + 1, 280 * dt); p.face = Math.atan2(gy - p.y, gx - p.x); p.x += (gx - p.x) / d * v; p.y += (gy - p.y) / d * v; }
    if (t && d <= reach + 8 && p.cd <= 0) { p.cd = (p.rage > 0 ? 0.4 : 0.85) * (pk2 ? 0.7 : 1); p.bite = 0.12; hit(t, 0.45 * (pk2 ? 2 : 1), { from: p, kb: 20, noLoh: true }); }
    pushWalls(p);
    if (dist(p, h) > 720 || (st.grid && dist(p, h) > 260 && !los(p, h))) { p.x = h.x; p.y = h.y; p.tgt = null; }
  }

  // Geschosse
  st.shots = st.shots.filter((s) => {
    s.x += s.vx * dt; s.y += s.vy * dt; s.life -= dt;
    if (s.life <= 0 || s.x < 0 || s.y < 0 || s.x > WORLD.w || s.y > WORLD.h) return false;
    if (blindAt(s.x, s.y)) { burst(s.x, s.y, s.col || C.shotE, 4, 80); return false; }
    if (!s.hero && st.obst.some((o) => Math.hypot(o.x - s.x, o.y - s.y) < o.r)) { burst(s.x, s.y, s.col || C.shotE, 4, 80); return false; }   // Felsen sind Deckung: nur gegnerische Geschosse prallen ab
    if (s.hero) {
      for (const e of [...st.en]) if (!s.seen.has(e) && dist(e, s) < e.r + s.r) { s.seen.add(e); hit(e, s.mult, { kb: s.kb || 50, stun: s.stun, pow: s.pow }); if (s.gen) { h.en = Math.min(100, h.en + s.gen); s.gen = 0; } if (--s.pierce < 0) return false; }
    } else if (dist(s, h) < h.r + s.r) {
      if (h.leg.mirror && h.inv <= 0 && Math.random() < 0.25) { s.hero = true; s.vx *= -1.6; s.vy *= -1.6; s.mult = 1.6; s.seen = new Set(); s.pierce = 0; s.col = "#c9fffb"; s.life = 1.6; SFX.block(); return true; }
      hurt(s.dmg, s.src); return false;
    }
    return true;
  });

  // Flächen (Pfeilhagel, Zeitglas) und verzögerte Einschläge (Sternsplitter)
  st.zones = st.zones.filter((z) => { z.life -= dt; if (z.slow) for (const e of st.en) if (dist(e, z) < z.r + e.r) e.slow = 0.3; if ((z.tick -= dt) <= 0) { z.tick = z.every; each((e) => { if (dist(e, z) < z.r + e.r) hit(e, z.mult, { kb: 8, noLoh: true, pow: z.pow }); }); } return z.life > 0; });
  st.late = st.late.filter((m) => { if ((m.t -= dt) > 0) return true; ringFx(m.x, m.y, m.r, "#ffd75e", 0.35); burst(m.x, m.y, "#ffd75e", 26, 260); st.shake = Math.max(st.shake, 10); SFX.pulse(); each((e) => { if (dist(e, m) < m.r + e.r) hit(e, m.mult, { kb: 180, pow: m.pow }); }); return false; });
  // Beute, Pforte, Hüter der Stunde
  st.fullT -= dt;
  st.loot = st.loot.filter((l) => {
    l.t += dt; if (l.t < 0.25) return true;
    const d = dist(l, h);
    if (!l.item && d < h.pick && d > 30) { const v = 420 * dt / d; l.x += (h.x - l.x) * v; l.y += (h.y - l.y) * v; }   // Ring des Sammlers zieht an
    if (d > 34) return true;
    if (l.globe) { h.hp = Math.min(h.maxHp, h.hp + h.maxHp * (h.leg.caravan ? 0.3 : 0.15)); h.pots = Math.min(POTS, h.pots + 1); num(h.x, h.y, "+1 Rotbier", "#7ad08a", false, 104); SFX.drink(); return false; }
    if (l.mat) { h.mats[l.mat] += l.n; toastMat(l.mat, l.n); SFX.pick(); persist(); return false; }
    if (l.shard) { h.shards += l.shard; num(h.x, h.y, `+${l.shard} Scherben`, "#8fe3e0", false, 104); SFX.pick(); return false; }
    if (l.evid !== undefined) { if (!h.evid.includes(l.evid)) h.evid.push(l.evid); h.newItems++; banner(EVID[l.evid][0], `BUCH DES THOT · SEITE ${h.evid.length} VON ${EVID.length}`); toast({ ic: ICON.evid, name: EVID[l.evid][0], sub: "Seite aus dem Buch des Thot, in der Tasche nachzulesen", col: "#f4ecd2" }); SFX.legend(); persist(); return false; }
    if (h.bag.length >= BAG_MAX) { if (st.fullT <= 0) { toast({ name: "Tasche voll", sub: "Wirf in der Tasche etwas weg (Taste I)", col: "#ff6b5e" }); st.fullT = 4; } return true; }
    const it = l.item; SFX.pick();
    toastItem(it, !h.eq[it.slot]);
    if (!h.eq[it.slot]) { h.eq[it.slot] = it; calcStats(); } else { h.bag.push(it); h.newItems++; }
    persist(); return false;
  });
  // Pforte: Wer hineintritt, wird gefragt. Wer bleibt, wird erst wieder gefragt, wenn er ein Stück weg war.
  if (st.portal) { const p = st.portal, d = dist(p, h); p.t += dt; if (d > 90) p.ask = true; if (d < 34 && p.t > 1.4 && p.ask !== false) { p.ask = false; showGate(); return; } }
  st.dead = st.dead.filter((d) => (d.t += dt) < 9);
  st.fx = st.fx.filter((f) => { f.life -= dt; if (f.k === "p") { f.x += f.vx * dt; f.y += f.vy * dt; f.vx *= 0.92; f.vy *= 0.92; } return f.life > 0; });
  st.nums = st.nums.filter((n) => { n.life -= dt; n.lift += 46 * dt; return n.life > 0; });
  st.shake = Math.max(0, st.shake - dt * 30);
}
function spawnBoss() {
  st.bossSpawned = true; let x = hero.x, y = hero.y; const B = st.def.boss;
  for (let i = 0; i < 40; i++) { const a = rnd(0, TAU); x = clamp(hero.x + Math.cos(a) * 430, 80, WORLD.w - 80); y = clamp(hero.y + Math.sin(a) * 430, 80, WORLD.h - 80); if (freeSpot(x, y, 60) && Math.hypot(x - hero.x, y - hero.y) > 300 && !wallAt(x, y) && los(hero, { x, y })) break; if (i === 39) { x = hero.x; y = hero.y; } }
  if (st.grid) for (let i = 0; i < 60; i++) { const a = rnd(0, TAU), d = rnd(180, 420), tx = hero.x + Math.cos(a) * d, ty = hero.y + Math.sin(a) * d; if (!wallAt(tx, ty) && los(hero, { x: tx, y: ty }) && ![[-50, 0], [50, 0], [0, -50], [0, 50]].some(([dx, dy]) => wallAt(tx + dx, ty + dy))) { x = tx; y = ty; break; } }
  const b = spawn("boss", x, y, -1, { active: true, t1: 2, t2: 6, t3: 4, charge: null, look: B.look, col: B.col, undead: B.undead });
  b.name = B.name; b.r = B.r; b.hp = b.maxHp = b.hp * B.hp; st.boss = b;
  $("boss").hidden = false; $("bossN").textContent = b.name; st.shake = 12; SFX.boss();
  banner(B.say, b.name.toUpperCase());
}
function bossAI(e, d, a, dt, go) {
  const fast = e.hp < e.maxHp * 0.3 ? 0.65 : 1, h = hero;
  if (e.charge) {
    const c = e.charge; e.face = c.ang;
    if (c.wind > 0) { c.wind -= dt; if (c.wind <= 0) c.run = 0.85; }
    else { const cp = freePath(e.x, e.y, e.x + Math.cos(c.ang) * 620 * dt, e.y + Math.sin(c.ang) * 620 * dt); e.x = cp.x; e.y = cp.y; e.dx = Math.cos(c.ang); e.dy = Math.sin(c.ang); c.run -= dt; if (!c.hit && dist(e, h) < e.r + h.r + 6) { hurt(e.dmg * 1.6, e); c.hit = true; } if (c.run <= 0) e.charge = null; }
    return;
  }
  if (d > 150) go(a);
  if ((e.t1 -= dt) <= 0) { e.t1 = 2.8 * fast; e.strike = 0.25; const n = 12 + Math.min(10, st.fall), off = rnd(0, TAU); for (let i = 0; i < n; i++) { const an = off + i / n * TAU; st.shots.push({ x: e.x, y: e.y, vx: Math.cos(an) * 170, vy: Math.sin(an) * 170, r: 7, dmg: e.dmg * 0.8, life: 3.4, col: e.col, src: e }); } tone(140, 0.2, "sawtooth", 0.04, -60); }
  if ((e.t2 -= dt) <= 0) { e.t2 = 10 * fast; const adds = pk(st.def.packs[0]).slice(0, 3); adds.forEach((type) => { const an = rnd(0, TAU), ap = freePath(e.x, e.y, e.x + Math.cos(an) * 70, e.y + Math.sin(an) * 70), w = spawn(type, ap.x, ap.y, -1, { active: true }); w.x = w.ox = ap.x; w.y = w.oy = ap.y; w.w = 0; w.xp = 0; }); }
  if ((e.t3 -= dt) <= 0 && d < 560) { e.t3 = 7 * fast; e.charge = { wind: 0.9, ang: a, run: 0, hit: false }; }
}
