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

const endpoint = form.getAttribute("action");
const active = endpoint.startsWith("https://");
form.addEventListener("submit", (event) => {
  if (!active) event.preventDefault();
});
form.querySelector("button").disabled = !active;
document.querySelector("#waitlist-status").hidden = active;
