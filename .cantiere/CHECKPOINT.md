# CHECKPOINT — MoneyTracker

> Il file per ripartire. Chi riapre il cantiere legge SOLO questo per capire dove siamo.
> Gli storici stanno in `.cantiere/archivio/checkpoint/`.

**Data:** 2026-11-19 01:38 · **Tag:** non creato (lo mette il capocantiere al commit) · **Fatto da:** segretario (Claude Code · Haiku 5.5)

## Siamo qui
Ramo `redesign-sentiero` (merge su `main` solo con l'ok di Matteo). Fix della curva Home (S-36, commit 829c6a0): Matteo l'ha verificata su screenshot, collaudo 10/10 dei 6 giudici, build e test verdi; resta [~] finché non la collauda il collaudatore o Matteo.
Progetto SOCIAL: formato nuovo deciso da Matteo, niente voce né volto (mani+iPhone o caroselli bianchi). Post 1 (carosello di 9 slide + copertina) pronto e approvato; pubblicazione gio 19/11 ore 13:00 a cura di Matteo.
Da fare: post 2 (ven 20/11 ore 18:30, serve il video mani+telefono di F1), testi SC-3 da rivedere nel formato nuovo, chiarire cosa intendeva Matteo con «soldi dati alle IA».

## Fatto dall'ultimo checkpoint
| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-18 14:30 | capocantiere (Claude Code · Sonnet) | SC-1: profili IG, TikTok, YouTube con bio, link, foto e banner. Landing approvata da Matteo |
| 2026-11-19 00:30 | Matteo (decisione) | Formato social ispirato a @easlonotes: mai voce né volto; mani+iPhone o caroselli bianchi con titolo grande; musica TikTok. F8 «Giorno 1» a voce sospeso (DECISIONI) |
| 2026-11-19 | Matteo (decisione) | Messaggio di brand: 5 temi in REGOLE-PROGETTO. Niente «definitiva», niente confronti per nome, niente promesse su cloud, privacy o IA finché non verificate |
| 2026-11-19 | Matteo (regola) | Negli screen si toglie SEMPRE «modalità demo». Barra di stato 9:41 con segnale, 5G e batteria 59% veri. «Dati di esempio» solo su Home, Movimenti, Statistiche |
| 2026-11-19 | Matteo (scelta) | Prima slide del post 1: «Ogni conto al suo posto. Ogni euro in chiaro.». Scartata «Arrivi a fine mese?». Tenuta per altri post: «Chiudi Excel. I tuoi conti sono già qui.» |
| 2026-11-19 | capocantiere + redattore | Post 1 pronto: carosello 4:5 di 9 slide + copertina 9:16 (`SOCIAL/caroselli/presentazione-v1/build.py`). Grafica, testi e caption approvati da Matteo («testi ok») |
| 2026-11-19 | capocantiere | Consegna senza AirDrop: cartella Drive «Da postare/post-N/» con `python3 SOCIAL/esporta-post.py N` (commit 961fa2c, 30bd070) |
| 2026-11-19 | capocantiere | Calendario: gio 19/11 13:00 post 1; ven 20/11 18:30 post 2; sab 21/11 storie con sondaggio; dom nessun post. Gate Apple dom 06/12; lancio target 12/01/2027 |
| 2026-11-19 | capocantiere | S-36: curva Home non allineata. Causa: `BalanceTrail.projected` partiva da oggi includendo i pianificati di oggi. Fix solo di vista in `TrailView.swift` (829c6a0). Dominio non toccato |
| 2026-11-19 | capocantiere | Pulizia: `.pyc` tolti da git e aggiunti a `.gitignore`; 7 `.DS_Store` e 4 log tolti; 3 screen superati cancellati da `post-1/materiale`; vecchio `prova-01` spostato nel magazzino |
| 2026-11-19 | capocantiere | `docs/MoneyTracker.md` v3.21 e PDF rigenerato. Manuale strategico PDF invariato (il formato nuovo prevale) |

## Stato di salute
| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | `collaudo.sh` verde. Dopo S-36 build e `BalanceTrailTests` verdi |
| Guardiano notturno | 🟡 | Non ancora attivo: parte al primo push. Ultimo giro: nessuno |
| Pagella (misurata) | 🟡 | 99/100 misurata. Non consegnabile: mancano giudici e guardiano. Categoria più bassa: non indicata |
| Lingue allineate | non verificato | Nessun testo app nuovo oggi (S-36 solo vista) |
| Sicurezza | non verificato | Solo: `.pyc` fuori da git |
| Ordine e spazio | 🟡 | Pulizie fatte. Restano 3 copie di `prova-01` nel magazzino e cartelle di prova da decidere. Peso sul Mac: non verificato |
| Grafo aggiornato | 🟢 | 1822 nodi, 3330 archi, 311 comunità |

## Bug
- Risolti: curva Home non allineata (S-36, 829c6a0), verificata da Matteo su screenshot.
- Aperti: nessun bug nuovo. Da chiudere: S-36 [~] → collaudatore o Matteo.

## Cantiere
- Spostati: vecchio carosello `prova-01` nel magazzino (3 copie, da ridurre a una).
- Eliminati: 3 screen superati in `post-1/materiale`; 7 `.DS_Store`; 4 log; `.pyc` da git. Vecchi PNG di `SOCIAL/caroselli/prova-01` non più in git.
- Da confermare (Matteo): `.cantiere/tmp/` (19 PNG di collaudo e cartelle `review-*`); quale copia di `prova-01` tenere; `.Rhistory` e `.agent/` in radice.
- Tenuto per altro post: screen `IMG_7924` («benzina → suggerita»).

## Struttura (dal grafo)
- `graphify-out/` aggiornato: 1822 nodi, 3330 archi, 311 comunità.
- Social: `SOCIAL/caroselli/presentazione-v1/build.py` (generatore post 1); `SOCIAL/clip-social/post-N/{materiale,pronto}` (fuori da git); `SOCIAL/istruzioni-post/post-N.txt`; `SOCIAL/esporta-post.py`.
- App: `MoneyTracker/Views/Components/TrailView.swift` (curva Home, S-36).

## Domani si riparte così
1. Nuova sessione nella cartella MoneyTracker, poi scrivi «riprendiamo».
2. Matteo pubblica il post 1 (gio 19/11 ore 13:00) e scrive «pubblicato» + link. Prompt: «Matteo ha pubblicato il post 1 del progetto SOCIAL di MoneyTracker. Leggi .cantiere/CHECKPOINT.md, sezione Siamo qui. Registra data, ora, piattaforma e link in SOCIAL/diario-metriche.csv (SC-6). Ricorda di chiedere a Matteo view, salvataggi e commenti dopo 24 ore.»
3. Post 2 (ven 20/11 ore 18:30, F1 «Questa linea tratteggiata…»). Prompt: «Prepara il post 2 del progetto SOCIAL di MoneyTracker. Formato: niente voce né volto; solo mani e iPhone con l'app, o caroselli bianchi con titolo grande; musica TikTok. Leggi .cantiere/CHECKPOINT.md (Siamo qui e Cose che deve fare Matteo) e il messaggio di brand in .cantiere/REGOLE-PROGETTO.md. Prima dì a Matteo cosa girare: inquadratura, luce, cosa toccare, 10-15 s verticali 9:16. Il materiale va in SOCIAL/clip-social/post-2/materiale. Poi montaggio, SOCIAL/istruzioni-post/post-2.txt e python3 SOCIAL/esporta-post.py 2. Togli «modalità demo» dagli screen; «Dati di esempio» solo su Home, Movimenti, Statistiche. Nessun claim non verificato. Se il materiale non arriva in tempo: storie con sondaggio (sab 21/11).»
4. Chiarire «IA». Prompt: «Chiedi a Matteo cosa intende con «soldi dati alle IA» (REGOLE-PROGETTO, Messaggio di brand). Poi verifica nel codice con graphify query se e come l'app manda dati a Supabase, e riporta i fatti. Nessun claim su cloud, privacy o IA finché non è verificato.»
5. S-36: collaudo. Prompt per il collaudatore: «Collauda S-36 di MoneyTracker: fix della curva Home in MoneyTracker/Views/Components/TrailView.swift, commit 829c6a0. Leggi solo il diff. Verifica: nessuna modifica a Domain; BalanceTrailTests verdi; tratteggio dal punto reale di oggi, con e senza pianificati di oggi. Se è ok, chiudi S-36 in .cantiere/PIANO.md con data ed esito.»
6. Poi: SC-3 (testi bio, landing, App Store) da rivedere per il formato nuovo, con il redattore; poi decisioni di pulizia e NotebookLM (sotto).

## Cose che deve fare Matteo
- [ ] **Pubblicare il post 1** (gio 19/11 ore 13:00, TikTok e Instagram).
  📍 iPhone: File → Google Drive → Da postare → post-1. Se la cartella non c'è, chiedi al capocantiere.
  ▶️ Apri `TikTok/` (poi `Instagram/`), tieni premute le immagini → «Salva immagini». Pubblica dall'app con la musica che scegli. Descrizioni e hashtag: nel file «00 LEGGIMI - POST 1.txt».
  ↩️ Scrivi «pubblicato» con i link.
- [ ] **Nome TikTok dal 24/11.**
  📍 TikTok → Modifica profilo → Nome.
  ▶️ Scrivi `Bucktrail · budget`. Dopo il primo post: account Business e sito `https://bucktrailapp.com/?utm_source=tiktok&utm_medium=bio`.
  ↩️ Scrivi «nome TikTok fatto».
- [ ] **Materiale post 2** (ven 20/11 ore 18:30).
  📍 iPhone con l'app in modalità demo, «Non disturbare», batteria piena.
  ▶️ Il capocantiere ti dice inquadratura e cosa toccare. Video mani+telefono 10-15 s, verticale, senza volto né voce. Salva in `SOCIAL/clip-social/post-2/materiale` (fuori da git).
  ↩️ Scrivi «materiale pronto».
- [ ] **Pulizie (sì/no):** 1) `.cantiere/tmp/`: sposta nel magazzino o cancella? 2) `prova-01`: tieni una copia sola? 3) radice: togli `.Rhistory` e `.agent/`?
  📍 In chat, quando riprendiamo.
  ↩️ Scrivi «tmp: sposta/cancella · prova: tieni una · radice: togli/lascia».
- [ ] **NotebookLM, 6 fonti** (bibliotecario).
  📍 notebooklm.google.com → notebook «MoneyTracker App».
  ▶️ «Aggiungi fonte» → «Google Drive» → `MAGAZZINO/CANTIERI/moneytracker/`. Aggiungi `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md`. Le licenze dei font sono facoltative.
  ↩️ Scrivi «notebook ok».
- [ ] **«Soldi dati alle IA»** (messaggio di brand): dimmi in parole tue cosa intendi.
  📍 In chat. ↩️ Il capocantiere verifica prima di usarlo in un post.
- [ ] **SC-3 testi** ⏳ in APPROVAZIONI: vanno rivisti per il formato nuovo. Non serve nulla da te adesso.

## Suggerimenti · Rischi
- Post 1: il prezzo «4,99 € una volta» è «di lancio previsto». Confermalo prima del lancio (non verificato).
- Claim vietati finché non verificati: «definitiva», confronti per nome, cloud, privacy e IA. L'app sincronizza con Supabase.
- Gli screen di riferimento di Easlo non sono stati trovati: `02_RISORSE/originali/social-riferimento-easlo` è vuota.
- PIANO: il fix della curva è stato rinumerato S-36 (S-35 era già il refactor di TransactionsView); i commit 829c6a0 ed e19a39d citano ancora «S-35».
- APPROVAZIONI: SC-7 ha intestazione ⏳ ma riga di stato ✅. Da allineare.
- PER-MATTEO da aggiornare: la voce del post 1 parla ancora di AirDrop (ora Drive); S-21, S-33, S-30 e traduzioni sono vecchie.
- Git: molte modifiche non committate (`docs/`, `.cantiere/`, `graphify-out/`, `SOCIAL/caroselli/prova-01`). Cartella `graphify-out/2026-11-19/` non tracciata. Il capocantiere decide cosa committare.
- Date: gate Apple dom 06/12/2026; lancio target 12/01/2027. Antigravity non disponibile fino al 2026-11-20 (lavori a Codex).
- Manuale `SOCIAL/Bucktrail_Manuale_Strategico_v2.pdf` resta valido (strategia, claim vietati, gate, soglie). Il formato nuovo prevale (DECISIONI).
