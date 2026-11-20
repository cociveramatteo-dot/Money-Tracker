const campaign = new URLSearchParams(location.search);
const form = document.querySelector(".waitlist");
const fields = ["utm_source", "utm_medium", "utm_campaign", "utm_id", "utm_term", "utm_content",
  "utm_source_platform", "utm_creative_format", "utm_marketing_tactic"];

const attribution = new URLSearchParams();
for (const name of fields) {
  const value = campaign.get(name)?.trim().slice(0, 200);
  if (!value) continue;
  attribution.set(name, value);
  const field = document.createElement("input");
  field.type = "hidden";
  field.name = name;
  field.value = value;
  form.append(field);
}

for (const link of document.querySelectorAll("[data-language]")) {
  if (attribution.size) link.search = attribution.toString();
}

const it = document.documentElement.lang === "it";
const localPreview = ["localhost", "127.0.0.1", "[::1]"].includes(location.hostname);
const msg = {
  ok: it ? "Fatto: ti scriveremo il giorno del lancio." : "Done: we'll write to you on launch day.",
  confirm: it ? "Quasi fatto: ti abbiamo scritto, clicca il link nell'email per confermare (controlla anche la posta indesiderata)." : "Almost done: we've emailed you, click the link to confirm (check your spam folder too).",
  fail: it ? "Qualcosa non ha funzionato. Riprova tra poco o scrivi a bucktrailapp@gmail.com." : "Something went wrong. Try again soon or write to bucktrailapp@gmail.com.",
  preview: it ? "Anteprima locale. Per iscriverti e ricevere l’email, usa il sito pubblico bucktrailapp.com." : "Local preview. To sign up and receive an email, use the live site at bucktrailapp.com.",
  sending: it ? "Invio in corso…" : "Sending…",
};
const status = document.querySelector("#waitlist-status");
const button = form.querySelector("button");
button.disabled = false;
form.addEventListener("submit", async (event) => {
  event.preventDefault();
  status.hidden = false;
  if (localPreview) {
    status.textContent = msg.preview;
    return;
  }
  button.disabled = true;
  status.textContent = msg.sending;
  try {
    const body = new FormData(form);
    body.set("lang", document.documentElement.lang);
    const res = await fetch(form.action, { method: "POST", body });
    const data = await res.json();
    if (!data.ok) throw new Error(data.error);
    status.textContent = data.mode === "confirm" ? msg.confirm : msg.ok;
    form.reset();
  } catch {
    status.textContent = msg.fail;
    button.disabled = false;
  }
});
