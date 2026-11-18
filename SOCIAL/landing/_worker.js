// Cloudflare Pages (modalità avanzata): riceve le iscrizioni alla lista d'attesa
// e le inserisce nella lista Brevo. La chiave sta nel segreto BREVO_API_KEY (mai nel codice).
const LIST_ID = 3; // lista «Bucktrail lancio»
const UTM = ["utm_source", "utm_medium", "utm_campaign"];

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

async function subscribe(request, env, ctx) {
  try {
    return await handle(request, env, ctx);
  } catch (e) {
    return json({ ok: false, error: "exception", detail: String(e && e.message || e).slice(0, 200) }, 424);
  }
}

async function handle(request, env, ctx) {
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

  // Con DOI_TEMPLATE_ID configurato l'iscritto riceve un'email e entra in lista solo dopo il clic (double opt-in).
  const doi = Number(env.DOI_TEMPLATE_ID) || 0;
  const lang = String(form.get("lang") || "it") === "en" ? "en" : "it";
  const send = (attrs) =>
    doi
      ? fetch("https://api.brevo.com/v3/contacts/doubleOptinConfirmation", {
          method: "POST",
          headers: { "api-key": env.BREVO_API_KEY, "content-type": "application/json", accept: "application/json" },
          body: JSON.stringify({
            email, attributes: attrs, includeListIds: [LIST_ID], templateId: doi,
            redirectionUrl: `https://bucktrailapp.com/${lang === "en" ? "confirmed" : "confermato"}`,
          }),
        })
      : call(attrs);

  let res = await send(attributes);
  if (res.status === 400) res = await send({}); // se un attributo non esiste ancora in Brevo, salva comunque l'email
  if (!res.ok) {
    const detail = (await res.text().catch(() => "")).slice(0, 300);
    return json({ ok: false, error: "upstream", status: res.status, detail }, 424);
  }

  if (env.NOTIFY_EMAIL && env.SENDER_EMAIL) {
    const note = fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: { "api-key": env.BREVO_API_KEY, "content-type": "application/json", accept: "application/json" },
      body: JSON.stringify({
        sender: { email: env.SENDER_EMAIL, name: "Bucktrail" },
        to: [{ email: env.NOTIFY_EMAIL }],
        subject: doi ? "Nuova iscrizione (da confermare)" : "Nuova iscrizione",
        textContent: `${email}\nProvenienza: ${attributes.UTM_SOURCE || "diretta"}${attributes.UTM_CAMPAIGN ? " / " + attributes.UTM_CAMPAIGN : ""}`,
      }),
    }).catch(() => {});
    ctx?.waitUntil?.(note);
  }
  return json({ ok: true, mode: doi ? "confirm" : "added" });
}

export default {
  async fetch(request, env, ctx) {
    if (new URL(request.url).pathname === "/api/subscribe") return subscribe(request, env, ctx);
    return env.ASSETS.fetch(request);
  },
};
