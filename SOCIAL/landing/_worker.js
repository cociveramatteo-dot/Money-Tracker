// Cloudflare Pages (modalità avanzata): riceve le iscrizioni alla lista d'attesa
// e le inserisce nella lista Brevo. La chiave sta nel segreto BREVO_API_KEY (mai nel codice).
const LIST_ID = 3; // lista «Bucktrail lancio»
const UTM = ["utm_source", "utm_medium", "utm_campaign"];

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

async function subscribe(request, env) {
  if (request.method !== "POST") return json({ ok: false }, 405);
  const origin = request.headers.get("origin");
  if (origin && new URL(origin).host !== new URL(request.url).host) return json({ ok: false }, 403);
  if (!env.BREVO_API_KEY) return json({ ok: false, error: "config" }, 500);

  let form;
  try { form = await request.formData(); } catch { return json({ ok: false, error: "bad" }, 400); }

  if (form.get("website")) return json({ ok: true }); // trappola per i bot: finge di riuscire
  const email = String(form.get("email") || "").trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) return json({ ok: false, error: "email" }, 400);
  if (!form.get("consent")) return json({ ok: false, error: "consent" }, 400);

  const attributes = { CONSENSO: `${form.get("consent")} ${new Date().toISOString()}` };
  for (const k of UTM) {
    const v = String(form.get(k) || "").trim().slice(0, 200);
    if (v) attributes[k.toUpperCase()] = v;
  }

  const call = (attrs) =>
    fetch("https://api.brevo.com/v3/contacts", {
      method: "POST",
      headers: { "api-key": env.BREVO_API_KEY, "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({ email, listIds: [LIST_ID], updateEnabled: true, attributes: attrs }),
    });

  let res = await call(attributes);
  if (res.status === 400) res = await call({}); // se un attributo non esiste ancora in Brevo, salva comunque l'email
  return res.ok ? json({ ok: true }) : json({ ok: false, error: "upstream" }, 502);
}

export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname === "/api/subscribe") return subscribe(request, env);
    return env.ASSETS.fetch(request);
  },
};
