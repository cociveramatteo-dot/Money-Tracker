// Guardiano notturno — riassunto finale.
// Uso: node riassunto.mjs --out <cartella risultati> [--soglie '{"prestazioni":85,...}']
// Unisce risultati.json e i rapporti Lighthouse (lighthouse/*.json), scrive RAPPORTO.md
// (le prime 5 righe sono il riassunto letto da "riprendiamo") e aggiorna risultati.json.
// Exit code: 0 = 🟢/🟡, 1 = 🔴 (così GitHub manda l'email di allarme).
import fs from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const arg = (n, d = "") => {
  const i = process.argv.indexOf(`--${n}`);
  return i > -1 && process.argv[i + 1] ? process.argv[i + 1] : d;
};
const OUT = path.resolve(arg("out", "guardiano-out"));
const SOGLIE = { prestazioni: 85, accessibilita: 90, seo: 90, buone_pratiche: 90, ...JSON.parse(arg("soglie", "{}")) };
const r = JSON.parse(await fs.readFile(path.join(OUT, "risultati.json"), "utf8"));

// ---------- Lighthouse ----------
const CATEGORIE = { performance: "prestazioni", accessibility: "accessibilita", seo: "seo", "best-practices": "buone_pratiche" };
const lh = { pagine: [], medie: {}, lcp_ms: null, cls: null, peso_kb: null };
const dirLh = path.join(OUT, "lighthouse");
if (existsSync(dirLh)) {
  for (const f of (await fs.readdir(dirLh)).filter((x) => x.endsWith(".json")).sort()) {
    try {
      const j = JSON.parse(await fs.readFile(path.join(dirLh, f), "utf8"));
      const voti = {};
      for (const [k, it] of Object.entries(CATEGORIE)) voti[it] = j.categories?.[k]?.score != null ? Math.round(j.categories[k].score * 100) : null;
      lh.pagine.push({
        file: f,
        url: j.finalDisplayedUrl || j.requestedUrl,
        modalita: f.includes("__desktop") ? "desktop" : "telefono",
        ...voti,
        lcp_ms: j.audits?.["largest-contentful-paint"]?.numericValue ?? null,
        cls: j.audits?.["cumulative-layout-shift"]?.numericValue ?? null,
        peso_kb: j.audits?.["total-byte-weight"]?.numericValue != null ? Math.round(j.audits["total-byte-weight"].numericValue / 1024) : null,
      });
    } catch (e) {
      r.problemi.push({ gravita: "avviso", tipo: "lighthouse", pagina: f, dispositivo: "-", dettaglio: `rapporto illeggibile: ${e.message}` });
    }
  }
  const media = (k) => {
    const v = lh.pagine.map((p) => p[k]).filter((x) => x != null);
    return v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
  };
  for (const it of Object.values(CATEGORIE)) lh.medie[it] = media(it) != null ? Math.round(media(it)) : null;
  const peggiore = (k) => {
    const v = lh.pagine.filter((p) => p.modalita === "telefono").map((p) => p[k]).filter((x) => x != null);
    return v.length ? Math.max(...v) : null;
  };
  lh.lcp_ms = peggiore("lcp_ms") != null ? Math.round(peggiore("lcp_ms")) : null;
  lh.cls = peggiore("cls") != null ? Number(peggiore("cls").toFixed(3)) : null;
  lh.peso_kb = peggiore("peso_kb");
  for (const [k, soglia] of Object.entries(SOGLIE)) {
    const v = lh.medie[k];
    if (v != null && v < soglia) {
      r.problemi.push({ gravita: v < soglia - 10 ? "errore" : "avviso", tipo: "lighthouse", pagina: "media", dispositivo: "-", dettaglio: `${k} ${v} (soglia ${soglia})` });
    }
  }
}
r.lighthouse = lh;
r.errori = r.problemi.filter((p) => p.gravita === "errore").length;
r.avvisi = r.problemi.filter((p) => p.gravita === "avviso").length;
r.semaforo = r.errori ? "🔴" : r.avvisi ? "🟡" : "🟢";
await fs.writeFile(path.join(OUT, "risultati.json"), JSON.stringify(r, null, 2));

// ---------- RAPPORTO.md ----------
// lo stesso problema su più dispositivi diventa una riga sola con l'elenco dei dispositivi
const raggruppati = new Map();
for (const p of r.problemi) {
  const dettaglio = p.dettaglio.replace(/pagina larga \d+px su \d+px/, "pagina più larga dello schermo").replace(/\(\+\d+px\)/g, "");
  const k = `${p.gravita}|${p.tipo}|${p.pagina}|${dettaglio}`;
  if (!raggruppati.has(k)) raggruppati.set(k, { ...p, dettaglio: p.dettaglio, dispositivi: [] });
  if (p.dispositivo !== "-") raggruppati.get(k).dispositivi.push(p.dispositivo);
}
const perTipo = {};
for (const p of raggruppati.values()) (perTipo[`${p.gravita === "errore" ? "🔴" : "🟡"} ${p.tipo}`] ??= []).push(p);
r.problemi_unici = raggruppati.size;
const lhRiga = lh.pagine.length
  ? `Lighthouse (media): prestazioni ${lh.medie.prestazioni} · accessibilità ${lh.medie.accessibilita} · SEO ${lh.medie.seo} · buone pratiche ${lh.medie.buone_pratiche} · LCP ${lh.lcp_ms ?? "?"} ms · peso ${lh.peso_kb ?? "?"} KB`
  : "Lighthouse: non eseguito";
const principali = Object.entries(perTipo)
  .sort((a, b) => (a[0] < b[0] ? -1 : 1))
  .slice(0, 3)
  .map(([t, l]) => `${t} ×${l.length}`)
  .join(" · ");
const data = new Date(r.data).toLocaleString("it-IT", { timeZone: "Europe/Rome" });
const righe = [
  `# 🌙 Guardiano ${r.semaforo} — ${data}`,
  `${r.pagine.length} pagine × ${r.dispositivi.length} dispositivi · ${r.link.totali} link · ${r.clic} clic · monkey ${r.giri_monkey} giri · ${r.problemi_unici} problemi distinti (${r.errori} errori, ${r.avvisi} avvisi)`,
  lhRiga,
  `Principali: ${principali || "nessun problema"}`,
  `Cambiamenti visivi: ${r.differenze_visive.length ? r.differenze_visive.map((d) => `${d.pagina} ${d.disp} ${d.percento != null ? d.percento + "%" : ""}${d.nota ? " (" + d.nota + ")" : ""}`).slice(0, 4).join(", ") : r.confronti_visivi ? `nessuno (${r.confronti_visivi} schermate confrontate)` : "confronto non fatto (manca il giro precedente)"}`,
  "",
  "---",
  "",
  "## Problemi",
  "",
];
if (!r.problemi.length) righe.push("Nessun problema trovato. 🟢");
for (const [tipo, lista] of Object.entries(perTipo).sort()) {
  righe.push(`### ${tipo} (${lista.length})`);
  for (const p of lista.slice(0, 15)) {
    const dove = p.dispositivi.length ? (p.dispositivi.length >= 8 ? "tutti i dispositivi" : p.dispositivi.join(", ")) : "—";
    righe.push(`- \`${p.pagina}\` · ${dove} — ${p.dettaglio}`);
  }
  if (lista.length > 15) righe.push(`- … e altri ${lista.length - 15}`);
  righe.push("");
}
if (lh.pagine.length) {
  righe.push("## Lighthouse per pagina", "", "| Pagina | Modalità | Prest. | Access. | SEO | Buone pr. | LCP ms | Peso KB |", "|---|---|---|---|---|---|---|---|");
  for (const p of lh.pagine) righe.push(`| ${p.url} | ${p.modalita} | ${p.prestazioni} | ${p.accessibilita} | ${p.seo} | ${p.buone_pratiche} | ${Math.round(p.lcp_ms ?? 0)} | ${p.peso_kb} |`);
  righe.push("");
}
righe.push("## Pagine visitate", "", ...r.pagine.map((p) => `- ${p}`), "", `Screenshot: \`screenshot/\` (${r.dispositivi.join(", ")})`);
await fs.writeFile(path.join(OUT, "RAPPORTO.md"), righe.join("\n") + "\n");
console.log(righe.slice(0, 5).join("\n"));
process.exit(r.semaforo === "🔴" ? 1 : 0);
