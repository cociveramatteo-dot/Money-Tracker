# CHECKPOINT — MoneyTracker

> Il file per ripartire. Chi riapre il cantiere legge SOLO questo per capire dove siamo.
> Gli storici stanno in `.cantiere/archivio/checkpoint/`.

**Data:** 2026-11-18 13:35 · **Tag git:** checkpoint-2026-11-18-1335 · **Fatto da:** capocantiere (Claude Code · Sonnet) · veloce

## Siamo qui
Ramo `redesign-sentiero`. **Landing online su https://bucktrailapp.com** (IT/EN, Cloudflare Pages, dominio Aruba con DNS Cloudflare). Lista d'attesa attiva: form → `_worker.js` → Brevo (lista ID 3) con double opt-in (modello ID 1, tag `optin`), notifica a Gmail, mittente `ciao@bucktrailapp.com`, logo nell'email. Privacy completa e approvata. Sicurezza: intestazioni (CSP, HSTS, X-Frame-Options ecc.) impostate dal `_worker.js`; favicon su ogni pagina; link interni senza `#sezione` nell'indirizzo (`script.js`). Progetto SOCIAL in corso: gate Apple il 06/12.

## Stato di salute
🟢 collaudo.sh. Pagella misurata 99 (non consegnabile: 1 approvazione grafica, giudici e guardiano mancanti). Form provato end-to-end con email vera. Contatti di prova cancellati. Fuori posto in radice: `screenshot app/`, `Claude outputs/` (da spostare nel magazzino).

## Domani si riparte così
1. Matteo: approvare la grafica della landing (APPROVAZIONI) e completare i punti SC-1 (bio/foto, TikTok 24/11) e SC-2 (clip).
2. Link in bio → https://bucktrailapp.com con UTM; poi misurare iscritti (soglia: 40 organici, 200 visite, ~5%).
3. Ogni modifica alla landing: ricaricare la cartella `SOCIAL/landing` su Cloudflare (Create deployment). Portare `redesign-sentiero` su `main` solo con l'ok di Matteo.
