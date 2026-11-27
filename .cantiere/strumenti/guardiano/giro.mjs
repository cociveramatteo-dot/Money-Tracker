// Guardiano notturno — giro completo del sito con Playwright.
// Uso: node giro.mjs --base http://localhost:8080 --out ../../guardiano/ultimo [--precedente dir] [--monkey 60] [--pagine /a,/b]
// Produce: <out>/risultati.json, <out>/screenshot/*.png. Non usa IA: 0 crediti.
import { chromium, devices } from "playwright";
import fs from "node:fs/promises";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { PNG } from "pngjs";
import pixelmatch from "pixelmatch";

const require = createRequire(import.meta.url);
const AXE = readFileSync(require.resolve("axe-core/axe.min.js"), "utf8");
const GREMLINS = readFileSync(path.join(path.dirname(require.resolve("gremlins.js/package.json")), "dist/gremlins.min.js"), "utf8");

// ---------- argomenti ----------
const arg = (nome, def = "") => {
  const i = process.argv.indexOf(`--${nome}`);
  return i > -1 && process.argv[i + 1] ? process.argv[i + 1] : def;
};
const BASE = arg("base").replace(/\/$/, "");
const OUT = path.resolve(arg("out", "guardiano-out"));
const PRECEDENTE = arg("precedente") ? path.resolve(arg("precedente")) : "";
const MONKEY_S = Number(arg("monkey", "60"));
// dominio definitivo del sito (es. https://cliente.it): finché si lavora sull'anteprima i link assoluti verso di
// lui (canonical, hreflang, og:url…) si controllano sull'anteprima, non sul vecchio sito ancora online
const PRODUZIONE = arg("produzione").replace(/\/$/, "");
const EXTRA = arg("pagine").split(",").map((s) => s.trim()).filter(Boolean);
const MAX_PAGINE = 40;
const MAX_SCREENSHOT_PAGINE = 10;
const MAX_CLIC = 40;
if (!BASE) {
  console.error("Manca --base");
  process.exit(2);
}

const DISPOSITIVI = [
  { nome: "iphone-se", larghezza: 375, altezza: 667, mobile: true, scala: 2 },
  { nome: "iphone", larghezza: 393, altezza: 852, mobile: true, scala: 3 },
  { nome: "android", larghezza: 412, altezza: 915, mobile: true, scala: 2.6 },
  { nome: "ipad", larghezza: 768, altezza: 1024, mobile: true, scala: 2 },
  { nome: "ipad-orizzontale", larghezza: 1024, altezza: 768, mobile: true, scala: 2 },
  { nome: "laptop", larghezza: 1280, altezza: 800, mobile: false, scala: 1 },
  { nome: "desktop", larghezza: 1440, altezza: 900, mobile: false, scala: 1 },
  { nome: "schermo-grande", larghezza: 1920, altezza: 1080, mobile: false, scala: 1 },
];

const problemi = []; // { gravita: "errore"|"avviso", tipo, pagina, dispositivo, dettaglio }
const segnala = (gravita, tipo, pagina, dispositivo, dettaglio) =>
  problemi.push({ gravita, tipo, pagina, dispositivo, dettaglio: String(dettaglio).slice(0, 300) });

const stessoSito = (u) => {
  try {
    return new URL(u).origin === new URL(BASE).origin;
  } catch {
    return false;
  }
};
const normalizza = (u) => {
  const x = new URL(u, BASE + "/");
  x.hash = "";
  x.search = "";
  return x.pathname;
};
const nomeFile = (pagina) => (pagina === "/" ? "home" : pagina.replace(/^\/|\/$/g, "").replace(/[^a-z0-9]+/gi, "-")) || "home";

// ---------- scoperta pagine ----------
async function scopriPagine(contesto) {
  const daVisitare = ["/", ...EXTRA];
  try {
    const r = await contesto.request.get(`${BASE}/sitemap.xml`, { timeout: 15000 });
    if (r.ok()) {
      for (const m of (await r.text()).matchAll(/<loc>\s*([^<\s]+)\s*<\/loc>/g)) {
        // la sitemap può contenere il dominio di produzione: si tiene solo il percorso
        try { daVisitare.push(new URL(m[1]).pathname); } catch { /* ignora */ }
      }
    }
  } catch { /* sitemap assente: si va avanti col giro dei link */ }
  const visti = new Set();
  const pagine = [];
  const p = await contesto.newPage();
  while (daVisitare.length && pagine.length < MAX_PAGINE) {
    const percorso = normalizza(daVisitare.shift());
    if (visti.has(percorso) || /\.(pdf|jpg|jpeg|png|webp|svg|zip|xml|txt|json)$/i.test(percorso)) continue;
    visti.add(percorso);
    try {
      const r = await p.goto(BASE + percorso, { waitUntil: "domcontentloaded", timeout: 30000 });
      if (!r || r.status() >= 400) {
        // le pagine trovate seguendo i link sono già segnalate dal controllo dei link
        if (percorso === "/" || EXTRA.includes(percorso))
          segnala("errore", "pagina-irraggiungibile", percorso, "-", `HTTP ${r ? r.status() : "nessuna risposta"}`);
        continue;
      }
      if (!(r.headers()["content-type"] || "").includes("html")) continue;
      pagine.push(percorso);
      const link = await p.$$eval("a[href]", (as) => as.map((a) => a.href));
      for (const l of link) if (stessoSito(l)) daVisitare.push(l);
    } catch (e) {
      segnala("errore", "pagina-irraggiungibile", percorso, "-", e.message);
    }
  }
  await p.close();
  return pagine;
}

// ---------- controllo link (una volta per sito) ----------
async function controllaLink(contesto, pagine) {
  const tutti = new Map(); // url -> pagina dove compare
  const p = await contesto.newPage();
  for (const pagina of pagine) {
    await p.goto(BASE + pagina, { waitUntil: "domcontentloaded" }).catch(() => {});
    const link = await p.$$eval("a[href], link[href], img[src], script[src], source[srcset]", (els) =>
      els.flatMap((e) => {
        const v = e.getAttribute("href") || e.getAttribute("src") || (e.getAttribute("srcset") || "").split(",")[0].trim().split(" ")[0];
        try { return v ? [new URL(v, location.href).href] : []; } catch { return []; }
      }),
    ).catch(() => []);
    for (let l of link) {
      if (PRODUZIONE && (l === PRODUZIONE || l.startsWith(PRODUZIONE + "/") || l.startsWith(PRODUZIONE + "#")))
        l = BASE + l.slice(PRODUZIONE.length);
      if (!tutti.has(l)) tutti.set(l, pagina);
    }
  }
  await p.close();
  let controllati = 0;
  for (const [url, pagina] of tutti) {
    if (url.startsWith("mailto:")) {
      if (!/^mailto:[^@\s]+@[^@\s]+\.[a-z]{2,}/i.test(url)) segnala("errore", "link-rotto", pagina, "-", `mailto malformato: ${url}`);
      continue;
    }
    if (url.startsWith("tel:")) {
      if (!/^tel:\+?[0-9 ()-]{6,}$/.test(decodeURIComponent(url))) segnala("errore", "link-rotto", pagina, "-", `tel malformato: ${url}`);
      continue;
    }
    if (/wa\.me|whatsapp\.com/.test(url)) {
      if (!/^https:\/\/wa\.me\/\d{8,15}(\?text=.*)?$|^https:\/\/api\.whatsapp\.com\/send\?phone=\d{8,15}/.test(url))
        segnala("errore", "link-rotto", pagina, "-", `link WhatsApp malformato: ${url.slice(0, 120)}`);
      continue;
    }
    if (!/^https?:/.test(url)) continue;
    const ancora = new URL(url).hash;
    try {
      controllati++;
      const r = await contesto.request.get(url, { timeout: 20000, maxRedirects: 5, failOnStatusCode: false });
      const st = r.status();
      if (st === 404 || st === 410 || st >= 500) segnala("errore", "link-rotto", pagina, "-", `${st} ${url}`);
      else if (st >= 400) segnala("avviso", "link-dubbio", pagina, "-", `${st} ${url} (il sito potrebbe bloccare i controlli automatici)`);
      else if (ancora && stessoSito(url) && (r.headers()["content-type"] || "").includes("html")) {
        const id = decodeURIComponent(ancora.slice(1));
        const html = await r.text();
        if (id && !html.includes(`id="${id}"`) && !html.includes(`id='${id}'`) && !html.includes(`name="${id}"`))
          segnala("errore", "ancora-rotta", pagina, "-", `${url} (manca id="${id}")`);
      }
    } catch (e) {
      segnala(stessoSito(url) ? "errore" : "avviso", "link-irraggiungibile", pagina, "-", `${url}: ${e.message.split("\n")[0]}`);
    }
  }
  return { totali: tutti.size, controllati };
}

// ---------- controlli di layout per pagina e dispositivo ----------
async function controllaPagina(contesto, pagina, disp, conScreenshot) {
  const p = await contesto.newPage();
  const errori = [];
  const inLocale = /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/i.test(BASE);
  // "Failed to load resource" è già coperto dal controllo delle risposte 4xx/5xx
  // Il beacon di Cloudflare Web Analytics (/cdn-cgi/rum) fallisce sempre per CORS quando il sito gira in locale (127.0.0.1): non è un errore del sito.
  p.on("console", (m) => {
    if (m.type() !== "error") return;
    const t = m.text();
    if (/Failed to load resource/i.test(t)) return;
    if (inLocale && /cloudflareinsights\.com/i.test(t) && /CORS/i.test(t)) return;
    errori.push(`console: ${t}`);
  });
  p.on("pageerror", (e) => errori.push(`errore JS: ${e.message}`));
  p.on("requestfailed", (r) => {
    const f = r.failure()?.errorText || "";
    if (f.includes("ERR_ABORTED")) return;
    if (inLocale && /^https:\/\/([^/]+\.)?cloudflareinsights\.com\/cdn-cgi\/rum(\?|$)/i.test(r.url()) && f.includes("ERR_FAILED")) return;
    errori.push(`richiesta fallita: ${r.url()} (${f})`);
  });
  p.on("response", (r) => r.status() >= 400 && stessoSito(r.url()) && errori.push(`risorsa ${r.status()}: ${r.url()}`));
  try {
    await p.goto(BASE + pagina, { waitUntil: "networkidle", timeout: 45000 });
  } catch (e) {
    segnala("errore", "caricamento", pagina, disp.nome, e.message.split("\n")[0]);
    await p.close();
    return;
  }
  // scorre fino in fondo (carica le immagini lazy)
  await p.evaluate(async () => {
    for (let y = 0; y < document.body.scrollHeight; y += Math.max(200, innerHeight * 0.8)) {
      scrollTo(0, y);
      await new Promise((r) => setTimeout(r, 120));
    }
    scrollTo(0, 0);
  });
  await p.waitForTimeout(400);
  const esito = await p.evaluate(() => {
    const W = document.documentElement.clientWidth;
    // un elemento fuori schermo ma "ritagliato" da un contenitore (menu a scomparsa, caroselli) non è un difetto
    const ritagliato = (el) => {
      for (let a = el.parentElement; a && a !== document.documentElement; a = a.parentElement) {
        const s = getComputedStyle(a);
        if (["hidden", "clip"].includes(s.overflowX) || s.position === "fixed" || a.getAttribute("aria-hidden") === "true" || a.inert) return true;
        if (s.transform && s.transform !== "none" && a.getBoundingClientRect().left >= W - 1) return true;
      }
      return false;
    };
    const fuori = [];
    for (const el of document.querySelectorAll("body *")) {
      const s = getComputedStyle(el);
      if (s.display === "none" || s.visibility === "hidden" || s.position === "fixed") continue;
      const r = el.getBoundingClientRect();
      if (r.width > 0 && r.height > 0 && r.right > W + 2 && !ritagliato(el)) {
        fuori.push(`${el.tagName.toLowerCase()}${el.id ? "#" + el.id : ""}${el.className && typeof el.className === "string" ? "." + el.className.trim().split(/\s+/).slice(0, 2).join(".") : ""} (+${Math.round(r.right - W)}px)`);
      }
    }
    const tagliati = [...document.querySelectorAll("h1,h2,h3,p,a,button,li,span")].filter((el) => {
      const s = getComputedStyle(el);
      return s.overflow === "hidden" && el.scrollWidth > el.clientWidth + 2 && s.textOverflow !== "ellipsis";
    }).length;
    const immaginiRotte = [...document.images].filter((i) => i.complete && i.naturalWidth === 0 && i.src).map((i) => i.src);
    // WCAG 2.5.8: i link dentro un testo (in linea) sono esclusi dalla misura minima di 24px
    const piccoli = [...document.querySelectorAll("a, button, [role=button], input, select")].filter((el) => {
      const r = el.getBoundingClientRect();
      const s = getComputedStyle(el);
      const inLinea = el.tagName === "A" && s.display === "inline" && el.parentElement && /^(P|LI|SPAN|SMALL|TD|DD|LABEL|EM|STRONG)$/.test(el.parentElement.tagName);
      return !inLinea && r.width > 0 && r.height > 0 && (r.width < 24 || r.height < 24) && s.visibility !== "hidden" && !ritagliato(el);
    }).length;
    return {
      scrollOrizzontale: document.documentElement.scrollWidth > W + 1,
      larghezzaPagina: document.documentElement.scrollWidth,
      fuori: fuori.slice(0, 5),
      nFuori: fuori.length,
      tagliati,
      immaginiRotte,
      piccoli,
      font: document.fonts ? document.fonts.status : "n/d",
    };
  });
  if (esito.scrollOrizzontale)
    segnala("errore", "scorrimento-orizzontale", pagina, disp.nome, `pagina larga ${esito.larghezzaPagina}px su ${disp.larghezza}px · ${esito.fuori.join(", ")}`);
  else if (esito.nFuori) segnala("avviso", "elementi-fuori-schermo", pagina, disp.nome, esito.fuori.join(", "));
  if (esito.tagliati) segnala("avviso", "testo-tagliato", pagina, disp.nome, `${esito.tagliati} elementi con testo tagliato`);
  for (const src of esito.immaginiRotte) segnala("errore", "immagine-rotta", pagina, disp.nome, src);
  if (disp.mobile && esito.piccoli > 3) segnala("avviso", "tocco-difficile", pagina, disp.nome, `${esito.piccoli} elementi cliccabili più piccoli di 24px`);
  if (esito.font !== "loaded" && esito.font !== "n/d") segnala("avviso", "font", pagina, disp.nome, `font non caricati (${esito.font})`);
  for (const e of [...new Set(errori)].slice(0, 10)) segnala("errore", "errore-console", pagina, disp.nome, e);

  if (conScreenshot) {
    const file = path.join(OUT, "screenshot", `${nomeFile(pagina)}__${disp.nome}.png`);
    await p.screenshot({ path: file, fullPage: true, animations: "disabled" }).catch(() => {});
    if (PRECEDENTE) confrontaScreenshot(file, pagina, disp.nome);
    // "prima schermata": quello che si vede appena aperta la pagina, a piena risoluzione (per i giudici)
    await p.evaluate(() => window.scrollTo(0, 0)).catch(() => {});
    await p.screenshot({ path: path.join(OUT, "screenshot", "prima-schermata", `${nomeFile(pagina)}__${disp.nome}.png`),
                         fullPage: false, animations: "disabled" }).catch(() => {});
  }
  await p.close();
}

// ---------- clic su tutti gli elementi cliccabili ----------
async function cliccaTutto(contesto, pagina, disp) {
  const p = await contesto.newPage();
  const errori = [];
  p.on("pageerror", (e) => errori.push(e.message));
  await p.goto(BASE + pagina, { waitUntil: "networkidle", timeout: 45000 }).catch(() => {});
  const n = await p.locator("button, [role=button], summary, a[href^='#'], details > summary, [aria-controls]").count();
  let cliccati = 0;
  for (let i = 0; i < Math.min(n, MAX_CLIC); i++) {
    const el = p.locator("button, [role=button], summary, a[href^='#'], details > summary, [aria-controls]").nth(i);
    try {
      if (!(await el.isVisible())) continue;
      const href = await el.getAttribute("href");
      await el.click({ timeout: 3000, noWaitAfter: true });
      cliccati++;
      await p.waitForTimeout(150);
      if (href && href.length > 1 && href.startsWith("#")) {
        const ok = await p.evaluate((id) => !!document.getElementById(decodeURIComponent(id)), href.slice(1));
        if (!ok) segnala("errore", "ancora-rotta", pagina, disp.nome, `clic su ${href}: sezione inesistente`);
      }
      if (new URL(p.url()).pathname !== new URL(BASE + pagina).pathname) {
        await p.goto(BASE + pagina, { waitUntil: "domcontentloaded" });
      }
    } catch {
      // elemento coperto o sparito dopo un altro clic (es. menu chiuso): non è un errore
    }
  }
  for (const e of [...new Set(errori)].slice(0, 5)) segnala("errore", "errore-al-clic", pagina, disp.nome, e);
  await p.close();
  return cliccati;
}

// ---------- monkey test ----------
async function monkey(contesto, disp, secondi) {
  if (secondi <= 0) return 0;
  const p = await contesto.newPage();
  const errori = [];
  p.on("pageerror", (e) => errori.push(e.message));
  // gremlins in ogni pagina in cui il monkey test finisce; i link esterni vengono bloccati
  await p.addInitScript({ content: GREMLINS });
  await p.route("**/*", (r) => (stessoSito(r.request().url()) ? r.continue() : r.abort()));
  await p.goto(BASE + "/", { waitUntil: "networkidle" }).catch(() => {});
  const fine = Date.now() + secondi * 1000;
  let giri = 0;
  while (Date.now() < fine) {
    giri++;
    await p
      .evaluate(() =>
        window.gremlins &&
        window.gremlins
          .createHorde({ randomizer: new window.gremlins.Chance(42), strategies: [window.gremlins.strategies.distribution({ delay: 20, nb: 150 })] })
          .unleash(),
      )
      .catch((e) => errori.push(`gremlins: ${e.message}`));
    if (!stessoSito(p.url())) await p.goto(BASE + "/", { waitUntil: "domcontentloaded" }).catch(() => {});
    await p.waitForLoadState("domcontentloaded").catch(() => {});
  }
  const unici = [...new Set(errori)].filter((e) => !/gremlins:.*(context|destroyed|navigat|Target)/i.test(e));
  for (const e of unici.slice(0, 5)) segnala("errore", "monkey-test", "/", disp.nome, e);
  await p.close();
  return giri;
}

// ---------- accessibilità (axe) ----------
async function accessibilita(contesto, pagina, disp) {
  const p = await contesto.newPage();
  await p.goto(BASE + pagina, { waitUntil: "networkidle" }).catch(() => {});
  await p.addScriptTag({ content: AXE });
  const r = await p.evaluate(async () => {
    const res = await window.axe.run(document, { resultTypes: ["violations"] });
    return res.violations.map((v) => ({ id: v.id, impatto: v.impact, nodi: v.nodes.length, aiuto: v.help }));
  }).catch(() => []);
  for (const v of r) {
    const grave = v.impatto === "critical" || v.impatto === "serious";
    segnala(grave ? "errore" : "avviso", "accessibilita", pagina, disp.nome, `${v.id} (${v.impatto}, ${v.nodi} elementi): ${v.aiuto}`);
  }
  await p.close();
  return r.length;
}

// ---------- confronto visivo con il giro precedente ----------
const differenze = [];
let confronti = 0;
function confrontaScreenshot(file, pagina, disp) {
  const vecchio = path.join(PRECEDENTE, "screenshot", path.basename(file));
  if (!PRECEDENTE || !existsSync(vecchio)) return;
  confronti++;
  try {
    let a = PNG.sync.read(readFileSync(vecchio));
    let b = PNG.sync.read(readFileSync(file));
    if (a.width !== b.width) {
      differenze.push({ pagina, disp, percento: null, nota: `larghezza cambiata ${a.width}→${b.width}px` });
      return;
    }
    // altezza diversa (pagina più lunga o più corta): si confronta comunque la parte comune in alto
    let nota = "";
    if (a.height !== b.height) {
      const delta = b.height - a.height;
      nota = `pagina ${delta > 0 ? "più lunga" : "più corta"} di ${Math.abs(delta)} px`;
      const h = Math.min(a.height, b.height);
      const taglia = (img) => {
        const t = new PNG({ width: img.width, height: h });
        img.data.copy(t.data, 0, 0, img.width * h * 4);
        return t;
      };
      a = taglia(a);
      b = taglia(b);
    }
    const diff = new PNG({ width: a.width, height: a.height });
    const n = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: 0.15 });
    const percento = (100 * n) / (a.width * a.height);
    if (percento > 0.5 || nota) {
      differenze.push({ pagina, disp, percento: Number(percento.toFixed(2)), ...(nota && { nota }) });
      const fileDiff = file.replace(/\.png$/, "__diff.png");
      import("node:fs").then((f) => f.writeFileSync(fileDiff, PNG.sync.write(diff)));
    }
  } catch (e) {
    differenze.push({ pagina, disp, percento: null, nota: `confronto non riuscito: ${e.message}` });
  }
}

// ---------- giro principale ----------
await fs.rm(OUT, { recursive: true, force: true });
await fs.mkdir(path.join(OUT, "screenshot", "prima-schermata"), { recursive: true });
const inizio = Date.now();
const browser = await chromium.launch();
const contestoBase = await browser.newContext({ ignoreHTTPSErrors: false, userAgent: devices["Desktop Chrome"].userAgent + " CantiereGuardiano" });

const pagine = await scopriPagine(contestoBase);
const link = await controllaLink(contestoBase, pagine);

let clic = 0;
let axe = 0;
for (const disp of DISPOSITIVI) {
  const ctx = await browser.newContext({
    viewport: { width: disp.larghezza, height: disp.altezza },
    deviceScaleFactor: disp.mobile ? 2 : 1,
    isMobile: disp.mobile,
    hasTouch: disp.mobile,
    reducedMotion: "reduce",
  });
  for (const [i, pagina] of pagine.entries()) {
    await controllaPagina(ctx, pagina, disp, i < MAX_SCREENSHOT_PAGINE);
    if (disp.nome === "iphone" || disp.nome === "laptop") {
      clic += await cliccaTutto(ctx, pagina, disp);
      axe += await accessibilita(ctx, pagina, disp);
    }
  }
  await ctx.close();
}

let giriMonkey = 0;
for (const nome of ["iphone", "laptop"]) {
  const disp = DISPOSITIVI.find((d) => d.nome === nome);
  const ctx = await browser.newContext({ viewport: { width: disp.larghezza, height: disp.altezza }, isMobile: disp.mobile, hasTouch: disp.mobile });
  giriMonkey += await monkey(ctx, disp, Math.round(MONKEY_S / 2));
  await ctx.close();
}
await browser.close();

const conta = (g) => problemi.filter((x) => x.gravita === g).length;
const risultati = {
  data: new Date().toISOString(),
  base: BASE,
  durata_s: Math.round((Date.now() - inizio) / 1000),
  pagine,
  dispositivi: DISPOSITIVI.map((d) => d.nome),
  link,
  clic,
  violazioni_axe: axe,
  giri_monkey: giriMonkey,
  differenze_visive: differenze,
  confronti_visivi: confronti,
  errori: conta("errore"),
  avvisi: conta("avviso"),
  problemi,
};
await fs.writeFile(path.join(OUT, "risultati.json"), JSON.stringify(risultati, null, 2));
console.log(`Giro finito: ${pagine.length} pagine × ${DISPOSITIVI.length} dispositivi · ${link.totali} link · ${clic} clic · errori ${risultati.errori} · avvisi ${risultati.avvisi}`);
