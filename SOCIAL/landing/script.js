document.documentElement.classList.add("js");

// Telefono sticky: cambia schermata in base al passo visibile
const shots = [...document.querySelectorAll(".sticky-phone img")];
const steps = [...document.querySelectorAll(".step")];
if (shots.length && "IntersectionObserver" in window) {
  const show = (i) => shots.forEach((img, n) => img.classList.toggle("on", n === i));
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) if (e.isIntersecting) show(steps.indexOf(e.target));
  }, { rootMargin: "-45% 0px -45% 0px" });
  steps.forEach((s) => io.observe(s));
}

// Tab «Ogni funzione»
for (const box of document.querySelectorAll(".tabs")) {
  const tabs = [...box.querySelectorAll('[role="tab"]')];
  const select = (t, focus) => {
    tabs.forEach((x) => {
      const on = x === t;
      x.setAttribute("aria-selected", on);
      x.tabIndex = on ? 0 : -1;
      document.getElementById(x.getAttribute("aria-controls")).hidden = !on;
    });
    if (focus) t.focus();
  };
  tabs.forEach((t, i) => {
    t.addEventListener("click", () => select(t));
    t.addEventListener("keydown", (e) => {
      const k = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[e.key];
      if (k) { e.preventDefault(); select(tabs[(i + k + tabs.length) % tabs.length], true); }
      if (e.key === "Home") { e.preventDefault(); select(tabs[0], true); }
      if (e.key === "End") { e.preventDefault(); select(tabs[tabs.length - 1], true); }
    });
  });
}

// Animazione della curva «Perché Bucktrail»
const bento = document.querySelector(".bento");
if (bento && "IntersectionObserver" in window) {
  const io2 = new IntersectionObserver((e) => { if (e[0].isIntersecting) { bento.classList.add("in"); io2.disconnect(); } }, { threshold: .3 });
  io2.observe(bento);
} else if (bento) bento.classList.add("in");

// Link interni senza #sezione nell'indirizzo: scorre alla sezione e lascia l'URL pulito
const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
for (const a of document.querySelectorAll('a[href^="#"]')) {
  a.addEventListener("click", (e) => {
    const id = a.getAttribute("href").slice(1);
    const target = id === "top" ? document.body : document.getElementById(id);
    if (!target) return;
    e.preventDefault();
    target.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: id === "top" ? "start" : "start" });
    if (id !== "main") target.setAttribute("tabindex", "-1"), target.focus({ preventScroll: true });
  });
}
