// 07 · Anzeige, Tasche, Eingabe, Klassenwahl
const hudCache = {};
function setTxt(id, v) { if (hudCache[id] !== v) { hudCache[id] = v; $(id).textContent = v; } }
function setW(id, p, prop = "width") { const v = Math.round(clamp(p, 0, 1) * 1000) / 10 + "%"; if (hudCache[id] !== v) { hudCache[id] = v; $(id).style[prop] = v; } }
let skBtn = {}, skIds = [];
function buildSkills() {
  const c = CLS[hero.cls]; skIds = [...c.sk, c.rmb, "potion"];
  $("skills").innerHTML = skIds.map((id, i) => {
    const s = SK[id], key = i < 4 ? String(i + 1) : i === 4 ? "RM" : "Q", tip = `${s.name}${s.cost ? ` (${s.cost} ${c.res})` : ""}${SK_TXT[id] ? `: ${SK_TXT[id]}` : ""}`;
    return `<button class="sk${id === "potion" ? " potion" : ""}${i === 4 ? " gap" : ""}" type="button" data-sk="${id}" aria-label="${tip}" title="${tip}"><svg viewBox="0 0 56 56" aria-hidden="true">${s.ic}</svg><span class="cd"></span><kbd>${key}</kbd>${id === "potion" ? '<span class="pots" id="potN"></span>' : ""}</button>`;
  }).join("");
  skBtn = Object.fromEntries([...document.querySelectorAll(".sk")].map((b) => [b.dataset.sk, b]));
  const orb = document.querySelector(".orb.en"); orb.setAttribute("aria-label", c.res); orb.title = c.res; $("enFill").style.background = `linear-gradient(180deg, ${c.rc[0]}, ${c.rc[1]})`;
  Object.keys(hudCache).forEach((k) => { delete hudCache[k]; });
}
function hud() {
  const h = hero;
  setW("hpFill", h.hp / h.maxHp, "height"); setTxt("hpTxt", String(Math.ceil(h.hp)));
  setW("enFill", h.en / 100, "height"); setTxt("enTxt", String(Math.floor(h.en)));
  setW("xpFill", h.xp / xpNeed(h.lvl)); setTxt("lvlTxt", `Stufe ${h.lvl}`);
  const p = st.progress / st.need; setW("trackFill", p);
  setTxt("trackL", st.portal ? "Die Pforte steht offen. Tritt hinein, wenn du so weit bist." : st.boss ? `${st.boss.name} ist hier.` : p >= 1 && st.bossRef ? `Der Hüter der Stunde wartet: ${st.bossRef.name}. Folge dem Pfeil.` : `Isfet zurückgedrängt: ${Math.floor(clamp(p, 0, 1) * 100)} %`);
  if (st.boss) setW("bossFill", st.boss.hp / st.boss.maxHp);
  for (const id of skIds) {
    const s = SK[id], b = skBtn[id], cd = Math.max(0, h.cd[id] || 0), v = Math.round(clamp(cd / s.cd, 0, 1) * 100) + "%";
    if (hudCache["cd" + id] !== v) { hudCache["cd" + id] = v; b.firstElementChild.nextElementSibling.style.height = v; }
    const poor = id === "potion" ? h.pots <= 0 : h.en < s.cost * (id === skIds[0] && h.leg.s1 ? 0.5 : 1); if (hudCache["po" + id] !== poor) { hudCache["po" + id] = poor; b.classList.toggle("poor", poor); }
  }
  setTxt("potN", String(h.pots));
  setTxt("buffs", [h.buff.oath > 0 ? `Eid der Maat ${Math.ceil(h.buff.oath)}` : "", h.buff.mantra > 0 ? `Kreis des Ka ${Math.ceil(h.buff.mantra)}` : "", st.pet && st.pet.rage > 0 ? `Fuchs hetzt ${Math.ceil(st.pet.rage)}` : "", h.leg.skin && h.skinT <= 0 ? "Mehen wacht" : ""].filter(Boolean).join(" · "));
  const nw = h.newItems > 0; if (hudCache.nw !== nw) { hudCache.nw = nw; $("invBtn").classList.toggle("has-new", nw); }
  const tp = treePoints(h) > 0; if (hudCache.tp !== tp) { hudCache.tp = tp; $("treeBtn").classList.toggle("has-new", tp); }
}

// ---------- Pforte: Rückblick auf die Stunde, Bestätigung, langsame Blende und eine Tafel für die nächste ----------
let travel = null;   // läuft gerade ein Stundenwechsel? { n }
const clock = (t) => `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, "0")}`;
function showGate() {
  const n = st.fall, d = st.def, nx = caseDef(n + 1), open = st.chests.filter((c) => c.open).length, left = st.chests.length - open;
  $("gateStamp").textContent = `${caseNo(n)} · VOLLENDET`; $("gateTitle").textContent = d.name; $("gateEpi").textContent = d.epi || "";
  const rows = [[clock(st.t), "Zeit"], [st.kills, "Besiegte"], [`${open} von ${st.chests.length}`, "Truhen geöffnet"], [`${hero.evid.length} von ${EVID.length}`, "Buchseiten"]];
  if (st.deaths) rows.push([st.deaths, st.deaths === 1 ? "Rückschlag" : "Rückschläge"]);
  $("gateStats").innerHTML = rows.map(([v, l]) => `<li><b>${v}</b><small>${l}</small></li>`).join("");
  $("gateNextNo").textContent = hourOf(n) === HOURS ? `DIE NÄCHSTE NACHT · ${caseNo(n + 1)}` : `HINTER DER PFORTE · ${caseNo(n + 1)}`;
  $("gateNext").textContent = nx.name; $("gateLead").textContent = nx.lead;
  $("gateNote").textContent = `${left === 1 ? "Hier steht noch eine ungeöffnete Truhe. " : left > 1 ? `Hier stehen noch ${left} ungeöffnete Truhen. ` : ""}Die Pforte bleibt offen, solange du willst.`;
  $("gate").hidden = false; paused = true; ptr.down = ptr.rdown = false; hero.tgt = null; Object.keys(keys).forEach((k) => { keys[k] = false; }); $("gateGo").focus();
}
function closeGate() { $("gate").hidden = true; paused = !started || anyPanel(); }
// instant: ohne Blende und Tafel (für Tests)
function gateGo(instant) {
  if (travel || !st.portal) return; const n = st.fall + 1; $("gate").hidden = true;
  if (instant === true) { newFall(n); paused = !started || anyPanel(); return; }
  travel = { n }; paused = true; SFX.gate();
  const f = $("fade"); $("chap").classList.remove("on"); f.hidden = false; void f.offsetWidth; f.classList.add("on");
  setTimeout(() => { newFall(n, true); showChapter(n); }, 1000);
}
// Schwarze Tafel mit Stunde, Namen und Lage. Erst „Eintreten“ gibt das Spiel frei.
function showChapter(n, cut) {
  const d = caseDef(n), f = $("fade"), b = $("chapGo"); travel = { n }; paused = true; f.classList.toggle("cut", !!cut);   // cut: sofort schwarz, ohne Abblenden
  $("chapNo").textContent = caseNo(n); $("chapName").textContent = d.name; $("chapLead").textContent = d.lead; $("chapBrief").textContent = d.brief || "";
  f.hidden = false; f.classList.add("on"); b.disabled = true; void f.offsetWidth; $("chap").classList.add("on");
  setTimeout(() => { b.disabled = false; b.focus(); }, 900);   // kurze Sperre, damit niemand die Tafel versehentlich wegdrückt
}
function enterChapter() {
  if (!travel || $("chapGo").disabled) return; const n = travel.n; travel = null;
  const f = $("fade"); f.classList.remove("cut"); void f.offsetWidth; $("chap").classList.remove("on"); f.classList.remove("on"); paused = !started || anyPanel(); banner(caseDef(n).name, caseNo(n));
  setTimeout(() => { if (!travel) $("fade").hidden = true; }, 1000);
}
$("gateGo").addEventListener("click", () => gateGo());
$("gateStay").addEventListener("click", closeGate);
$("chapGo").addEventListener("click", enterChapter);

// ---------- Tasche, Material, Schmied ----------
let selItem = null;
const icoPos = (i) => `background-position:${(i % 6) * 20}% ${Math.floor(i / 6) * 20}%`;
const icon = (it) => ART.icons ? `<span class="ico" style="${icoPos(iconOf(it))}"></span>` : `<svg viewBox="0 0 52 52" aria-hidden="true">${SLOT[it.slot].ic}</svg>`;
const affLine = (k, v) => `+${v}${AFF[k].unit} ${AFF[k].name}`;
const costTxt = (c) => Object.entries(c).map(([k, n]) => `${n} ${MATS[k].name}`).join(", ");
const canPay = (c) => Object.entries(c).every(([k, n]) => hero.mats[k] >= n);
const REROLL = { staub: 4 }, REROLL_SHARDS = 8;
const itName = (it) => it.name + (it.up ? ` +${it.up}` : "");
function anyPanel() { return !$("inv").hidden || !$("tree").hidden || !$("intro").hidden || !$("dead").hidden || !$("chestPop").hidden || !$("gate").hidden || !!travel; }

// ---------- Fundmeldungen: erscheinen links, verschwinden nach ein paar Sekunden von selbst ----------
const icoBox = (i) => ART.icons && i !== undefined ? `<span class="ico" style="${icoPos(i)}"></span>` : "";
function itemSub(it) {
  const cur = hero.eq[it.slot], diff = Math.round(itemScore(it) - itemScore(cur));
  const main = it.dmg ? `${itDmg(it)} Schaden` : it.armor ? `${itArm(it)} Rüstung` : `${Object.keys(it.aff).length} Eigenschaften`;
  const cmp = !cur || cur === it ? "" : diff > 0 ? ` · ▲ besser als angelegt (+${diff})` : "";
  return { txt: `${RAR[it.rar].name} · ${SLOT[it.slot].name} · ${main}${cmp}${it.leg && LEG[it.leg] ? ` · ${LEG[it.leg].txt}` : ""}`, up: diff > 0 && !!cur && cur !== it };
}
function toast(o) {
  const box = $("toasts"), el = document.createElement("div"); el.className = "toast"; el.style.setProperty("--tc", o.col || "var(--line)");
  el.innerHTML = `${o.ic !== undefined && ART.icons ? `<span class="ti">${icoBox(o.ic)}</span>` : ""}<div><b></b><small class="${o.up ? "up" : ""}"></small></div>`;
  el.querySelector("b").textContent = o.name; el.querySelector("small").textContent = o.sub || "";
  box.prepend(el); while (box.children.length > 5) box.lastChild.remove();
  const life = o.long ? 6500 : 4000;
  setTimeout(() => { el.classList.add("out"); setTimeout(() => el.remove(), 550); }, life);
}
function toastItem(it, worn) { const s = itemSub(it); toast({ ic: iconOf(it), name: itName(it), sub: worn ? `${RAR[it.rar].name} · direkt angelegt` : s.txt, up: s.up, col: RAR[it.rar].col, long: it.rar >= 2 }); }
function toastMat(k, n) {   // gleiche Materialien kurz hintereinander werden zu einer Meldung zusammengezählt
  const box = $("toasts"), old = box.querySelector(`[data-mat="${k}"]:not(.out)`);
  if (old) { old.dataset.n = +old.dataset.n + n; old.querySelector("b").textContent = `+${old.dataset.n} ${MATS[k].name}`; old.querySelector("small").textContent = `jetzt ${hero.mats[k]} im Vorrat`; return; }
  toast({ ic: ICON[k], name: `+${n} ${MATS[k].name}`, sub: `jetzt ${hero.mats[k]} im Vorrat`, col: MATS[k].col });
  const el = box.firstChild; el.dataset.mat = k; el.dataset.n = n;
}

// ---------- Truhenfenster ----------
let chestNow = null;
function showChest(c, got) {
  chestNow = { c, got }; const h = hero, free = BAG_MAX - h.bag.length - got.filter((g) => g.item && h.eq[g.item.slot]).length;
  $("chestTitle").textContent = CHEST[c.tier].name; $("chestStamp").textContent = c.tier === 2 ? "PRUNKFUND" : "FUND";
  $("chestList").innerHTML = got.map((g) => {
    if (g.item) { const s = itemSub(g.item); return `<li style="--tc:${RAR[g.item.rar].col}"><span class="ti">${icoBox(iconOf(g.item))}</span><div><b>${itName(g.item)}</b><small class="${s.up ? "up" : ""}">${s.txt}</small></div></li>`; }
    if (g.shard) return `<li style="--tc:var(--spectral)"><span class="ti">${icoBox(ICON.shard)}</span><div><b>${g.shard} Scherben</b><small>Vom Sammler zerbrochene Krüge. Für den Grabräuber, das Neuwürfeln und das Zurücksetzen des Baums</small></div></li>`;
    return `<li style="--tc:${MATS[g.mat].col}"><span class="ti">${icoBox(ICON[g.mat])}</span><div><b>${g.n} ${MATS[g.mat].name}</b><small>${MATS[g.mat].txt}</small></div></li>`;
  }).join("");
  $("chestNote").textContent = free < 0 ? "Die Tasche ist zu voll für alles. Was nicht hineinpasst, bleibt neben der Truhe liegen." : "";
  $("chestPop").hidden = false; paused = true; ptr.down = ptr.rdown = false; $("chestTake").focus();
}
function closeChest(take) {
  if (!chestNow) return; const { c, got } = chestNow, h = hero, a0 = Math.atan2(h.y - c.y, h.x - c.x); let k = 0; chestNow = null;
  for (const g of got) {
    if (take && g.shard) { h.shards += g.shard; continue; }
    if (take && g.mat) { h.mats[g.mat] += g.n; continue; }
    if (take && g.item && (!h.eq[g.item.slot] || h.bag.length < BAG_MAX)) { if (!h.eq[g.item.slot]) h.eq[g.item.slot] = g.item; else { h.bag.push(g.item); h.newItems++; } continue; }
    const a = a0 + (k++ - 1.5) * 0.55, x = c.x + Math.cos(a) * 54, y = c.y + Math.sin(a) * 54;   // liegen lassen: neben der Truhe
    if (g.item) dropItem(c.x, c.y, g.item, a, 58); else if (g.shard) st.loot.push({ x, y, shard: g.shard, t: 0 }); else dropMat(x, y, g.mat, g.n);
  }
  if (take) { calcStats(); SFX.pick(); toast({ ic: ICON.shard, name: `${CHEST[c.tier].name} geleert`, sub: "Alles liegt in der Tasche", col: "#ffd75e" }); }
  persist(); $("chestPop").hidden = true; paused = !started || anyPanel();
}
$("chestTake").addEventListener("click", () => closeChest(true));
$("chestLeave").addEventListener("click", () => closeChest(false));
function renderInv() {
  const h = hero;
  $("eqBox").innerHTML = Object.keys(SLOT).map((s) => { const it = h.eq[s]; return it ? `<button type="button" class="it${selItem === it ? " sel" : ""}" data-eq="${s}" style="border-color:${RAR[it.rar].col};color:${RAR[it.rar].col}" aria-label="${SLOT[s].name}: ${itName(it)}">${icon(it)}<small>${SLOT[s].name}${it.up ? ` +${it.up}` : ""}</small></button>` : `<div class="it empty"><small>${SLOT[s].name}</small></div>`; }).join("");
  $("statBox").innerHTML = [["Schaden", Math.round(h.dmg)], ["Leben", h.maxHp], ["Rüstung", `${h.armor} · −${Math.round(h.red * 100)} %`], ["Krit. Chance", `${h.crit} %`], ["Krit. Schaden", `+${h.critDmg} %`], ["Angriffe/s", h.rate.toFixed(2)], ["Lauftempo", Math.round(h.speed)], [`${CLS[h.cls].res}/s`, h.regen], ["Dornen", h.thorns], ["Beuteglück", `+${Math.round((h.find - 1) * 100)} %`]].map(([k, v]) => `<span>${k}<b>${v}</b></span>`).join("");
  $("matBox").innerHTML = Object.entries(MATS).map(([k, m]) => `<span title="${m.txt}">${ART.icons ? `<span class="ico" style="${icoPos(ICON[k])}"></span>` : ""}<b style="color:${m.col}">${h.mats[k]}</b> ${m.name}</span>`).join("") + `<span>${ART.icons ? `<span class="ico" style="${icoPos(ICON.shard)}"></span>` : ""}<b style="color:var(--spectral)">${h.shards}</b> Scherben</span>`;
  $("bagTitle").textContent = `Tasche (${h.bag.length} von ${BAG_MAX})`;
  $("bagBox").innerHTML = h.bag.map((it, i) => `<button type="button" class="it${selItem === it ? " sel" : ""}" data-bag="${i}" style="border-color:${RAR[it.rar].col};color:${RAR[it.rar].col}" aria-label="${itName(it)}, ${RAR[it.rar].name}">${icon(it)}${itemScore(it) > itemScore(h.eq[it.slot]) ? '<span class="up" aria-label="besser als das Angelegte">▲</span>' : ""}</button>`).join("") || '<span class="note">Leer. Besiegte Gegner und Truhen geben Ausrüstung.</span>';
  $("gambleBtn").textContent = `Beim Grabräuber tauschen: ${GAMBLE} Scherben gegen ein unbekanntes Teil`; $("gambleBtn").disabled = h.shards < GAMBLE || h.bag.length >= BAG_MAX;
  $("gambleNote").textContent = `Du hast ${h.shards} Scherben.`;
  $("evidTitle").textContent = `Buch des Thot (${h.evid.length} von ${EVID.length} Seiten)`;
  $("evidBox").innerHTML = EVID.map(([t, txt], i) => h.evid.includes(i) ? `<li class="got"><b>${t}</b>${txt}</li>` : `<li>Noch nicht gefunden. Elite-Gegner und die Hüter der Stunden tragen Seiten bei sich.</li>`).filter((x, i, a) => x.includes("got") || a.findIndex((y) => !y.includes("got")) === i).join("");
  const it = selItem, d = $("detail");
  if (!it) { d.innerHTML = '<span class="note">Tipp ein Teil an, um es anzusehen, aufzuwerten oder eine Eigenschaft neu zu würfeln.</span>'; return; }
  const worn = h.eq[it.slot] === it, cur = h.eq[it.slot], diff = Math.round(itemScore(it) - itemScore(cur)), up = it.up || 0, uc = upCost(it), rr = canPay(REROLL) && h.shards >= REROLL_SHARDS;
  d.innerHTML = `<div class="nm" style="color:${RAR[it.rar].col}">${itName(it)}</div><div class="note">${RAR[it.rar].name} · ${SLOT[it.slot].name} · Stufe ${it.ilvl}${worn ? " · angelegt" : ""}</div>
    <ul>${it.dmg ? `<li><b>${itDmg(it)}</b> Waffenschaden</li>` : ""}${it.armor ? `<li><b>${itArm(it)}</b> Rüstung</li>` : ""}${Object.keys(it.aff).map((k) => `<li><button type="button" class="affb" data-reroll="${k}" ${rr ? "" : "disabled"} title="Neu würfeln: ${costTxt(REROLL)}, ${REROLL_SHARDS} Scherben"><i>↻</i>${affLine(k, itAff(it, k))}</button></li>`).join("")}${it.leg && LEG[it.leg] ? `<li class="pow">${LEG[it.leg].txt}</li>` : ""}</ul>
    ${Object.keys(it.aff).length ? `<div class="note">↻ würfelt diese Eigenschaft neu: ${costTxt(REROLL)} und ${REROLL_SHARDS} Scherben.</div>` : ""}
    ${worn ? "" : `<div class="${diff > 0 ? "good" : diff < 0 ? "bad" : "note"}">${cur ? (diff > 0 ? `Besser als ${itName(cur)} (+${diff} Wertung)` : diff < 0 ? `Schwächer als ${itName(cur)} (${diff} Wertung)` : "Gleich gut wie das Angelegte") : "Dieser Platz ist noch frei."}</div>`}
    <div class="row">${worn ? "" : '<button class="go" type="button" id="equipBtn">Anlegen</button>'}<button class="ghost" type="button" id="upBtn" ${up < UP_MAX && canPay(uc) ? "" : "disabled"}>${up >= UP_MAX ? "Höchste Stufe erreicht" : `Aufwerten auf +${up + 1}: ${costTxt(uc)}`}</button>${worn ? "" : '<button class="ghost" type="button" id="dropBtn">Wegwerfen</button>'}</div>`;
}
function openInv(open) { $("inv").hidden = !open; if (open) { hero.newItems = 0; selItem = null; $("resetAsk").hidden = true; renderInv(); $("invClose").focus(); } paused = !started || anyPanel(); ptr.down = ptr.rdown = false; }
$("inv").addEventListener("click", (e) => {
  const b = e.target.closest("button"); if (!b) return; const h = hero;
  if (b.dataset.bag !== undefined) selItem = h.bag[+b.dataset.bag];
  else if (b.dataset.eq) selItem = h.eq[b.dataset.eq];
  else if (b.dataset.reroll && selItem) {   // eine Eigenschaft gegen eine andere tauschen, die das Teil noch nicht hat
    const it = selItem, k = b.dataset.reroll; if (!canPay(REROLL) || h.shards < REROLL_SHARDS || !(k in it.aff)) return;
    Object.entries(REROLL).forEach(([m, n]) => { h.mats[m] -= n; }); h.shards -= REROLL_SHARDS;
    const nk = pick(Object.keys(AFF).filter((x) => !(x in it.aff))); delete it.aff[k]; it.aff[nk] = AFF[nk].v(it.ilvl); calcStats(); persist(); tone(700, 0.1, "sine", 0.05, 300);
  }
  else if (b.id === "upBtn" && selItem) { const it = selItem, c = upCost(it); if ((it.up || 0) >= UP_MAX || !canPay(c)) return; Object.entries(c).forEach(([m, n]) => { h.mats[m] -= n; }); it.up = (it.up || 0) + 1; calcStats(); persist(); SFX.level(); }
  else if (b.id === "equipBtn" && selItem) { const it = selItem, i = h.bag.indexOf(it), old = h.eq[it.slot]; if (i >= 0) { h.bag.splice(i, 1); if (old) h.bag.push(old); h.eq[it.slot] = it; calcStats(); persist(); tone(500, 0.08, "triangle", 0.05, 200); } }
  else if (b.id === "dropBtn" && selItem) { const i = h.bag.indexOf(selItem); if (i >= 0) h.bag.splice(i, 1); selItem = null; persist(); }
  else if (b.id === "gambleBtn") { if (h.shards >= GAMBLE && h.bag.length < BAG_MAX) { h.shards -= GAMBLE; const it = makeItem(st.fall, 1); h.bag.push(it); selItem = it; persist(); it.rar === 3 ? SFX.legend() : SFX.pick(); } }
  else if (b.id === "junkBtn") { h.bag = h.bag.filter((it) => it.rar > 0); selItem = null; persist(); }
  else if (b.id === "invClose") { openInv(false); return; }
  else if (b.id === "fallBtn") { $("inv").hidden = true; showIntro(false); return; }
  else if (b.id === "resetBtn") { $("resetAsk").hidden = false; return; }
  else if (b.id === "resetNo") { $("resetAsk").hidden = true; return; }
  else if (b.id === "resetYes") { $("inv").hidden = true; started = false; showIntro(true); return; }
  else return;
  renderInv();
});

// ---------- Fähigkeitenbaum ----------
function renderTree() {
  const h = hero, c = CLS[h.cls], t = h.tree, pts = treePoints(h), ids = [...c.sk, c.rmb], keyName = (i) => i < 4 ? `Taste ${i + 1}` : "rechte Maustaste";
  $("treePts").innerHTML = `<b style="color:var(--lantern)">${pts}</b> ${pts === 1 ? "Punkt" : "Punkte"} frei. Jede Stufe gibt einen Punkt. Ab Rang 2 wählst du für eine Fähigkeit Wucht oder Eile.`;
  const pips = (n, max) => `<span class="pips" aria-hidden="true">${Array.from({ length: max }, (_, i) => `<i class="${i < n ? "f" : ""}"></i>`).join("")}</span>`;
  $("treeSk").innerHTML = ids.map((id, i) => {
    const s = SK[id], r = t.r[id] || 0, a = t.a[id], eff = s.util ? `Jeder Rang: 6 % schneller bereit (jetzt ${r * 6} %).` : `Jeder Rang: 12 % mehr Schaden (jetzt +${Math.round((skPow(id) - 1) * 100)} %).`;
    return `<div class="tcard${r ? " on" : ""}"><div class="thead"><span class="tic"><svg viewBox="0 0 56 56" aria-hidden="true">${s.ic}</svg></span><div><b>${s.name}</b><small>${keyName(i)} · Rang ${r} von ${SK_RANKS}</small>${pips(r, SK_RANKS)}</div><button type="button" class="plus" data-rank="${id}" aria-label="${s.name} verstärken" ${pts > 0 && r < SK_RANKS ? "" : "disabled"}>+</button></div>
      <p>${SK_TXT[id]} ${eff}</p><div class="row">${Object.entries(AUGS).map(([k, A]) => `<button type="button" class="ghost aug" data-aug="${id}:${k}" aria-pressed="${a === k}" title="${A.txt}" ${r >= 2 && (a || pts > 0) ? "" : "disabled"}>${A.name}: ${A.txt}</button>`).join("")}</div></div>`;
  }).join("");
  const K = KEYSTONE[h.cls], spent = treeSpent(h);
  $("treePa").innerHTML = PASSIVES.map((p) => { const r = t.p[p.id] || 0; return `<div class="tcard${r ? " on" : ""}"><div class="thead"><div><b>${p.name}</b><small>Rang ${r} von ${SK_RANKS}</small>${pips(r, SK_RANKS)}</div><button type="button" class="plus" data-pas="${p.id}" aria-label="${p.name} verstärken" ${pts > 0 && r < SK_RANKS ? "" : "disabled"}>+</button></div><p>${p.txt}.</p></div>`; }).join("") +
    `<div class="tcard${t.key ? " on" : ""}"><div class="thead"><div><b>${K.name}</b><small>Meisterschaft der Klasse${t.key ? " · erlernt" : ""}</small></div><button type="button" class="plus" data-key="1" aria-label="${K.name} erlernen" ${!t.key && pts > 0 && spent >= KEY_NEED ? "" : "disabled"}>+</button></div><p>${K.txt}${t.key ? "" : ` Braucht ${KEY_NEED} verteilte Punkte (du hast ${spent}).`}</p></div>`;
  $("respecBtn").textContent = `Alles zurücksetzen: ${respecCost(h)} Scherben`; $("respecBtn").disabled = spent === 0 || h.shards < respecCost(h);
}
function openTree(open) { $("tree").hidden = !open; if (open) { renderTree(); $("treeClose").focus(); } paused = !started || anyPanel(); ptr.down = ptr.rdown = false; }
$("tree").addEventListener("click", (e) => {
  const b = e.target.closest("button"); if (!b || b.disabled) return; const h = hero, t = h.tree, pts = treePoints(h);
  if (b.id === "treeClose") { openTree(false); return; }
  if (b.dataset.rank && pts > 0 && (t.r[b.dataset.rank] || 0) < SK_RANKS) t.r[b.dataset.rank] = (t.r[b.dataset.rank] || 0) + 1;
  else if (b.dataset.aug) { const [id, k] = b.dataset.aug.split(":"); if ((t.r[id] || 0) < 2 || (!t.a[id] && pts < 1)) return; t.a[id] = k; }
  else if (b.dataset.pas && pts > 0 && (t.p[b.dataset.pas] || 0) < SK_RANKS) t.p[b.dataset.pas] = (t.p[b.dataset.pas] || 0) + 1;
  else if (b.dataset.key && pts > 0 && !t.key && treeSpent(h) >= KEY_NEED) t.key = true;
  else if (b.id === "respecBtn" && h.shards >= respecCost(h)) { h.shards -= respecCost(h); h.tree = { r: {}, a: {}, p: {}, key: false }; }
  else return;
  tone(620, 0.08, "triangle", 0.05, 200); calcStats(); persist(); renderTree();
});
$("treeBtn").addEventListener("click", () => openTree(true));

// ---------- Eingabe ----------
function ptrPos(e) { const r = cv.getBoundingClientRect(); ptr.x = e.clientX - r.left; ptr.y = e.clientY - r.top; ptr.seen = true; ptr.mouse = e.pointerType === "mouse"; }
cv.addEventListener("pointerdown", (e) => {
  ptrPos(e); if (e.button === 2) ptr.rdown = true; else if (e.button === 0) ptr.down = true; else return;
  try { cv.setPointerCapture(e.pointerId); } catch (err) { /* egal */ } e.preventDefault();
});
cv.addEventListener("pointermove", ptrPos);
cv.addEventListener("pointerup", (e) => { if (e.button === 2) ptr.rdown = false; else { ptr.down = false; hero.tgt = null; } });
cv.addEventListener("pointercancel", () => { ptr.down = ptr.rdown = false; hero.tgt = null; });
cv.addEventListener("contextmenu", (e) => e.preventDefault());
$("skills").addEventListener("pointerdown", (e) => { const b = e.target.closest("[data-sk]"); if (b) { e.preventDefault(); cast(b.dataset.sk, e.pointerType !== "mouse"); } });
$("skills").addEventListener("contextmenu", (e) => e.preventDefault());
addEventListener("keydown", (e) => {
  if (e.ctrlKey || e.metaKey || e.altKey) return; const k = e.key.toLowerCase();
  if (travel) { if (k === "e" || k === "enter") { e.preventDefault(); enterChapter(); } return; }
  if (!$("gate").hidden) { if (k === "e" || k === "enter") { e.preventDefault(); gateGo(); } else if (k === "escape") closeGate(); return; }
  if (k === "i" || k === "tab") { if (started && $("dead").hidden && $("tree").hidden && $("intro").hidden) { e.preventDefault(); openInv($("inv").hidden); } return; }
  if (k === "k") { if (started && $("dead").hidden && $("inv").hidden && $("intro").hidden) openTree($("tree").hidden); return; }
  if (!$("chestPop").hidden) { if (k === "e" || k === "enter") { e.preventDefault(); closeChest(true); } else if (k === "escape") closeChest(false); return; }
  if (k === "escape" && !$("inv").hidden) { openInv(false); return; }
  if (k === "escape" && !$("tree").hidden) { openTree(false); return; }
  if (k === "m") { toggleMute(); return; }
  if (k === "f") { $("fps").hidden = !$("fps").hidden; return; }
  if (k === "g") { const order = ["auto", "2", "1", "0"]; setGfx(order[(order.indexOf(GMODE) + 1) % 4]); toast({ name: `Grafik: ${GMODE === "auto" ? "Automatisch" : GFX[GQ].name}`, sub: "G wechselt die Stufe, F zeigt die Bildrate", col: "#e8b04a" }); return; }
  if ("1234".includes(k) && k.length === 1) { if (started) cast(skIds[+k - 1], false); return; }
  if (k === "q") { if (started) cast("potion", false); return; }
  if ("wasd".includes(k) && k.length === 1) keys[k] = true;
});
addEventListener("keyup", (e) => { const k = e.key.toLowerCase(); if ("wasd".includes(k) && k.length === 1) keys[k] = false; });
addEventListener("blur", () => { ptr.down = ptr.rdown = false; Object.keys(keys).forEach((k) => { keys[k] = false; }); });
function toggleMute() { muted = !muted; $("muteBtn").textContent = muted ? "Ton aus" : "Ton an"; persist(); }
$("muteBtn").addEventListener("click", toggleMute);
$("invBtn").addEventListener("click", () => openInv(true));

// ---------- Klassenwahl: bei einem Spielstand wird weitergespielt, sonst (oder auf Wunsch) eine neue Figur angelegt ----------
let pickCls = "ermittler", newChar = false;
function showIntro(fresh) {
  newChar = fresh; $("classPick").hidden = !fresh; $("newCharBtn").hidden = fresh;
  $("startBtn").textContent = fresh ? "Die Nacht betreten" : "Weiterspielen";
  $("resumeNote").textContent = fresh ? "" : `Spielstand: ${CLS[hero.cls].name}${hero.hc ? " (Hardcore)" : ""}, Stufe ${hero.lvl}, ${hourTxt(st.fall)}: ${st.def.name}.`;
  $("classBox").innerHTML = Object.entries(CLS).map(([id, c]) => `<button type="button" class="cls" data-cls="${id}" aria-pressed="${id === pickCls}" style="--cc:${c.col}">${ART.portrait[c.face] ? `<img src="${ART.portrait[c.face]}" alt="">` : ""}<b>${c.name}</b><small>${c.like}</small><span>${c.txt}</span><span class="note">${[...c.sk, c.rmb].map((k) => SK[k].name).join(" · ")}</span></button>`).join("");
  renderGfx();
  pickDiff = hero.diff; $("hcLabel").hidden = !fresh; $("hcBox").checked = false; renderDiff();
  pickFall = st.fall; $("fallPick").hidden = fresh || hero.maxFall < 2; renderFalls();
  $("intro").hidden = false; paused = true; $("startBtn").focus();
}
let pickDiff = 0, pickFall = 1;
function renderGfx() {
  const opts = [["auto", "Automatisch"], ["2", "Hoch"], ["1", "Mittel"], ["0", "Niedrig"]];
  $("gfxBox").innerHTML = opts.map(([v, n]) => `<button type="button" class="ghost dif" data-gfx="${v}" aria-pressed="${GMODE === v}">${n}</button>`).join("");
  $("gfxNote").textContent = `Jetzt: ${GFX[GQ].name}, ${FPS} Bilder pro Sekunde. Ruckelt es, stell auf Niedrig: ohne Nebel, Schein und Mauertextur, mit weniger Bildpunkten.`;
}
$("gfxBox").addEventListener("click", (e) => { const b = e.target.closest("[data-gfx]"); if (!b) return; setGfx(b.dataset.gfx); renderGfx(); });
// Stundenwahl: jede schon erreichte Stunde lässt sich wiederholen, um dort gezielt Material und Beute zu sammeln
function fallLoot(n) { const d = caseDef(n), mats = [...new Set(d.packs.flatMap((p) => pk(p)).map((t) => MAT_OF[ET[t].look]).filter(Boolean))]; return `${d.dungeon ? "Gewölbe" : "Unter freiem Himmel"} · Hüter: ${d.boss.name} · Material: ${[MATS.staub.name, ...mats.map((m) => MATS[m].name)].join(", ")} · Beim Hüter häufiger: ${(d.legs || []).map((l) => LEG[l].name).join(", ")}`; }
function renderFalls() {
  const max = hero.maxFall, list = []; for (let n = 1; n <= Math.min(max, HOURS); n++) list.push(n); if (max > HOURS) list.push(max);
  $("fallBox").innerHTML = list.map((n) => `<button type="button" class="ghost dif" data-fall="${n}" aria-pressed="${n === pickFall}">${n <= HOURS ? `${n} · ${caseDef(n).name}` : `${hourTxt(n)} · ${caseDef(n).name}`}</button>`).join("");
  $("fallNote").textContent = fallLoot(pickFall) + (pickFall !== st.fall ? ". Die Stunde beginnt von vorn." : ".");
}
$("fallBox").addEventListener("click", (e) => { const b = e.target.closest("[data-fall]"); if (!b) return; pickFall = +b.dataset.fall; renderFalls(); });
function renderDiff() {
  $("diffBox").innerHTML = DIFF.map((d, i) => `<button type="button" class="ghost dif" data-diff="${i}" aria-pressed="${i === pickDiff}">${d.name}</button>`).join("");
  $("diffNote").textContent = `${DIFF[pickDiff].name}: ${DIFF[pickDiff].txt}.${!newChar && pickDiff !== hero.diff ? " Die laufende Stunde beginnt damit von vorn." : ""}`;
}
$("diffBox").addEventListener("click", (e) => { const b = e.target.closest("[data-diff]"); if (!b) return; pickDiff = +b.dataset.diff; renderDiff(); });
$("classBox").addEventListener("click", (e) => { const b = e.target.closest("[data-cls]"); if (!b) return; pickCls = b.dataset.cls; document.querySelectorAll(".cls").forEach((x) => x.setAttribute("aria-pressed", String(x === b))); });
$("newCharBtn").addEventListener("click", () => showIntro(true));
$("startBtn").addEventListener("click", () => {
  try { AC = AC || new (window.AudioContext || window.webkitAudioContext)(); if (AC.state === "suspended") AC.resume(); } catch (e) { AC = null; }
  if (newChar) { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* egal */ } hero = freshHero(); hero.cls = pickCls; hero.diff = pickDiff; hero.hc = $("hcBox").checked; calcStats(); newFall(1); }
  else if (pickDiff !== hero.diff || pickFall !== st.fall) { hero.diff = pickDiff; newFall(pickFall); }
  buildSkills(); $("intro").hidden = true; started = true; paused = false;
  if (newChar) { $("bannerBox").innerHTML = ""; showChapter(1, true); }   // die Nacht beginnt mit ihrer ersten Tafel
});
$("reviveBtn").addEventListener("click", () => {
  const h = hero;
  if (h.hc) { $("dead").hidden = true; started = false; hero = freshHero(); calcStats(); hero.hp = hero.maxHp; newFall(1); $("bannerBox").innerHTML = ""; try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* egal */ } showIntro(true); return; } h.x = st.start.x; h.y = st.start.y; h.hp = h.maxHp; h.en = 60; h.inv = 2.5; h.pots = Math.max(h.pots, 2); h.buff = {}; h.flurry = null; st.shots = [];
  if (st.pet) { st.pet.x = h.x - 30; st.pet.y = h.y + 20; st.pet.tgt = null; }
  st.en.forEach((e) => { e.x = e.ox; e.y = e.oy; e.active = false; e.wind = 0; e.pre = 0; e.alert = 0; e.charge = null; });
  st.packs.forEach((q) => { q.awake = false; q.alarm = 0; }); st.boss = null; $("boss").hidden = true;
  $("dead").hidden = true; paused = false;
});
addEventListener("resize", resize);
