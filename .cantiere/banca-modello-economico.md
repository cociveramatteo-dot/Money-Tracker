# Collegamento bancario: modello economico e decisioni (S-60 / S-61)

> Scritto il 2026-11-25 dal capocantiere (Claude Code · Sonnet 5.5) dopo la conversazione con Matteo. Integra `.cantiere/progetto-banca.md` (§12.2 Costi) e NON lo sostituisce.
> **Stato (2026-11-27): arrivata l'offerta di Enable Banking (§4, «Risposta»): canone 900–1.500 €/mese, troppo alto. In attesa di risposta a una controproposta e del preventivo Salt Edge.** Nessun codice scritto per S-60/S-61.

## 1. Sintesi in dieci righe
1. L'app resta **4,99 € una volta sola**, senza pubblicità e senza abbonamento. Il collegamento bancario è **facoltativo e separato**.
2. Il collegamento ha un **costo continuo** (Enable Banking fattura **a te**, ogni mese, per ogni conto collegato dai tuoi utenti, con un minimo mensile).
3. Decisione di Matteo (2026-11-25): chi vuole il collegamento paga un **abbonamento a parte**, due livelli: **fino a 2 banche** e **fino a 6 banche**.
4. Per ogni livello l'utente sceglie **mensile** o **annuale**; l'annuale ha **sconto** (circa 2 mesi gratis, cioè ≈ 10× il mensile).
5. Si paga solo tramite Apple e Google (acquisto in-app): niente Stripe/PayPal per questa funzione.
6. Il margine è **piccolo** (pochi centesimi al mese per utente): il collegamento serve a non rimetterci, non a guadagnare.
7. Prima di costruire qualunque cosa servono tre risposte: costo/minimo di Enable Banking, tipo di account Apple, parere del professionista.
8. Se una verifica va male, il collegamento resta spento e non si perde nulla: l'app funziona senza banca.
9. I prezzi veri si fissano **dopo** il preventivo, con la formula del §5.
10. Da verificare (non ancora fatto): se il sito o i social promettono già il collegamento bancario. Se sì, ridimensionare la promessa (consiglio del programmatore Maddy, 2026-11-25: testare prima 4-5 banche italiane reali).

## 2. Chi paga chi (il flusso dei soldi)
```
Utente ──4,99 € una volta──▶ Apple/Google ──▶ Matteo (≈ 3,48 € netti)
Utente ──abbonamento banca (mensile/annuale)──▶ Apple/Google ──▶ Matteo (≈ 69,7 % del prezzo)
Matteo ──fattura mensile (per conto collegato, con minimo)──▶ Enable Banking
```
- L'utente non ha alcun rapporto di pagamento con Enable Banking: il **cliente di Enable Banking è Matteo**.
- Gli store incassano, tolgono IVA e commissione (15 % con il programma piccoli sviluppatori) e pagano Matteo di norma una volta al mese.
- **Netto per ogni vendita dell'app:** 4,99 € ÷ 1,22 (IVA 22 %) = 4,09 € → × 0,85 (store 15 %) = **3,48 €**, una sola volta.
- **Netto per ogni euro di abbonamento:** × 0,85 ÷ 1,22 = **≈ 69,7 %** (da qui il fattore 1,435 nel §5).
- Apple e Google chiedono che i pagamenti per funzioni digitali passino da loro (acquisto in-app). Rimborsi e disdette li gestiscono gli store.
- Costi fissi degli store: Apple Developer 99 $/anno, Google Play 25 $ una tantum. Li coprono le **vendite dell'app** (servono ≈ 27 vendite per i 99 $), non l'abbonamento banca.

## 3. Perché serve un abbonamento: il problema dei costi
L'incasso dell'app è **una volta sola**, il costo della banca è **ogni mese per sempre** finché l'utente tiene il conto collegato.
- Esempio inventato per capire: `c` = 0,20 €, 100 utenti con un conto → 20 €/mese. Quei 100 utenti hanno portato 348 € una volta: dopo ≈ 17 mesi sono finiti e si continua a pagare.
- Utente che non collega la banca: costo zero. Per questo la funzione è facoltativa.
- Pareggio dell'app senza abbonamento (incasso 3,48 € ÷ costo mensile): con 1,5 conti medi e `c` = 0,10 € → ≈ 23 mesi; con `c` = 0,30 € → ≈ 8 mesi; con 4 conti e `c` = 0,10 € ≈ 9 mesi, con `c` = 0,30 € ≈ 3 mesi.
- **Rinnovo del consenso ogni 180 giorni** (alcune banche CBI Globe chiedono una SCA in più oltre i 90): non costa niente, perché una nuova autorizzazione sullo stesso conto non conta come conto nuovo (Knowledge Base di Enable Banking). Per l'utente è un minuto, due volte l'anno per banca.

## 4. Cosa sappiamo e cosa NO su Enable Banking
Verificato il 2026-11-25 su `enablebanking.com/docs/faq/` e `/knowledge-base`:
- **Non ci sono prezzi pubblici** né una pagina `/pricing`. Frasi ufficiali: «Our pricing is volume based»; «There is a minimum invoicing per month which includes a certain amount of accounts and payments»; «You pay for two things: each connected bank account per month, and each payment you successfully initiate»; «For a quota please contact sales at info@enablebanking.com».
- Letture e chiamate extra non costano di più; rinnovare lo stesso conto non costa di più.
- Il preventivo si chiede con il modulo «Get a Quote» (volumi previsti al 1°, 12° e 24° mese) o per email.
- **Non dichiarato:** se sandbox e modalità ristretta (propri conti) siano gratuite in produzione; il progetto lo dava per «gratis», va confermato. I Termini dicono che l'uso in produzione per un'app commerciale richiede un accordo a parte.
- **Ignoti:** prezzo per conto (`c`), importo e contenuto della fattura minima mensile, se accettano una persona fisica senza P.IVA.

### Risposta di Enable Banking (2026-11-27, offerta «Startup», PDF in Download di Matteo)
- **Canone di licenza mensile, conti inclusi:** 1° anno 900 €/mese (1.800 conti), 2° anno 1.200 € (2.400), dal 3° 1.500 € (3.000). Listino pieno 1.500 €/mese. Conti oltre gli inclusi: 0,50 € (0–5.000), 0,30 € (5.001–50.000), 0,20 € (oltre).
- Si paga solo dal go-live; sandbox e produzione con i propri conti **gratis**. Si opera sotto la loro licenza AISP.
- **Si fattura ogni conto condiviso** (accessibile col consenso e letto una volta), anche se poi non lo si usa. Molte banche grandi condividono tutti i conti senza scelta → i livelli «2 / 6 banche» vanno ripensati in conti o con un tetto.
- Consenso 180 giorni; senza utente presente max 4 letture al giorno; storico lungo solo nella prima ora dopo il consenso, poi spesso 90 giorni.
- **Senza risposta:** persona senza P.IVA, Banca d'Italia, ruolo GDPR/DPA, copertura Revolut/PayPal/Trade Republic/Fineco/N26/Hype, elenco sessioni.
- **Conti (capocantiere):** solo il canone del 1° anno = 10.800 €. Pareggio sul solo canone: ≈ 520 abbonati a 2,49 €/mese (netto 1,73 €) o ≈ 215 a 5,99 € (netto 4,17 €); dal 3° anno ≈ 870 / 360. Con «qualche centinaio di conti» il costo vero è ≈ 3 € per conto al mese. **Così non sta in piedi.**
- **Prossimi passi (2026-11-27):** risposta a Enable Banking chiedendo un pay-as-you-go senza canone + domande aperte; richiesta preventivo a Salt Edge (modulo saltedge.com/contact_sales o sales@saltedge.com). Collegamento bancario fermo finché un'offerta non regge.

### Le quattro banche di Matteo (UniCredit, PayPal, Revolut, Trade Republic)
| Conto | Cosa risulta (changelog di Enable Banking) | Certezza |
|---|---|---|
| UniCredit | Supportata in Italia | alta |
| Revolut | Supportata in circa 30 paesi europei, non nella pagina Italia | media, da provare |
| Trade Republic | Aggiunta come banca tedesca nel changelog di luglio 2026 (date dei changelog incoerenti) | media, da provare |
| PayPal | Citata nel changelog di giugno 2025, nessun aggiornamento più recente trovato | **bassa**, da provare |
Prova definitiva: sandbox, richiesta `GET /aspsps?country=IT` (e `DE`, `LT`). Fino ad allora non si promette nessuna oltre UniCredit. Il limite attuale del progetto (2 banche per utente) va superato dal livello «fino a 6».

## 5. Il modello scelto (decisione di Matteo, 2026-11-25)
- **Due livelli:** fino a **2 banche** e fino a **6 banche**. (Valutato e scartato: 2-3-5-10, troppo complicato per i negozi e per i testi; valutato come alternativa: un livello intermedio da 4 banche, se `c` è alto.)
- **Due durate per livello:** **mensile** (si rinnova da solo) e **annuale** con **sconto ≈ 2 mesi gratis** (prezzo annuale ≈ 10 × mensile).
- **Mese gratis:** gli store permettono solo una prova gratuita **uguale per tutti**, non condizionata ai ricavi. Se c'è, si decide al lancio. Non c'è nessun «mese gratis solo se copriamo Apple e Google».
- **Acquisto:** in-app su iOS (StoreKit) e Android (Play Billing); il server (Supabase) deve sapere che l'account ha il Pass perché un acquisto su iPhone non vale su Android da solo. Verifica lato server degli acquisti: lavoro in più, da progettare in S-61.
- **Formula del prezzo minimo** (pareggio, tutte le banche del livello usate): `prezzo = banche × c ÷ 0,697 ≈ banche × c × 1,435`. Per l'annuale si moltiplica per 12 e si sconta di circa il 17 %: il margine annuale scende (vedi tabelle).
- **Margini:** calcolati nel caso peggiore (tutte le banche del livello usate). Chi usa meno banche rende di più. **Non includono la fattura minima mensile**, che con pochi abbonati può azzerare il margine.
- **Freni già nel progetto S-60:** tetto globale di collegamenti attivi (`max_active_links`, parte da 50), limite per utente, aggiornamenti al massimo ogni 6 ore, interruttore spento di default.
- **Messaggio di brand da correggere sul sito se si procede:** «senza abbonamento» → «l'app si paga una volta; il collegamento bancario è facoltativo e a parte». Il testo si scrive con Matteo e va in `.cantiere/APPROVAZIONI.md` (AGENTS.md §6.6).

## 6. Tabelle con `c` variabile
### Pareggio (prezzo minimo per non rimetterci, caso peggiore: tutte le banche del livello usate)

| `c` (costo per conto al mese) | Costo/mese 2 banche | Prezzo minimo/mese 2 | Prezzo minimo/anno 2 | Costo/mese 6 banche | Prezzo minimo/mese 6 | Prezzo minimo/anno 6 |
|---|---|---|---|---|---|---|
| 0,10 € | 0,20 € | 0,29 € | 3,44 € | 0,60 € | 0,86 € | 10,33 € |
| 0,20 € | 0,40 € | 0,57 € | 6,89 € | 1,20 € | 1,72 € | 20,67 € |
| 0,30 € | 0,60 € | 0,86 € | 10,33 € | 1,80 € | 2,58 € | 31,00 € |
| 0,50 € | 1,00 € | 1,44 € | 17,22 € | 3,00 € | 4,31 € | 51,67 € |

### Esempi di prezzo, netto e margine (illustrativi: i prezzi veri si fissano dopo il preventivo)

Netto = prezzo × 0,85 ÷ 1,22 (≈ 69,7 %). Per l'annuale il netto e il margine sono divisi su 12 mesi. Costo = banche × `c`. Il margine NON include la fattura minima mensile di Enable Banking.

| `c` | Livello | Formula | Prezzo | Mi resta netto | Costo/mese (caso peggiore) | **Margine al mese** | Margine all'anno |
|---|---|---|---|---|---|---|---|
| 0,10 € | fino a 2 banche | mensile | 0,99 € | 0,69 € | 0,20 € | **0,49 €** | 5,88 € |
| 0,10 € | fino a 2 banche | annuale | 9,99 € | 6,96 € (=0,58 €/mese) | 0,20 € | **0,38 €** | 4,56 € |
| 0,10 € | fino a 6 banche | mensile | 1,49 € | 1,04 € | 0,60 € | **0,44 €** | 5,26 € |
| 0,10 € | fino a 6 banche | annuale | 14,99 € | 10,44 € (=0,87 €/mese) | 0,60 € | **0,27 €** | 3,24 € |
| 0,20 € | fino a 2 banche | mensile | 0,99 € | 0,69 € | 0,40 € | **0,29 €** | 3,48 € |
| 0,20 € | fino a 2 banche | annuale | 9,99 € | 6,96 € (=0,58 €/mese) | 0,40 € | **0,18 €** | 2,16 € |
| 0,20 € | fino a 6 banche | mensile | 2,49 € | 1,73 € | 1,20 € | **0,53 €** | 6,42 € |
| 0,20 € | fino a 6 banche | annuale | 24,99 € | 17,41 € (=1,45 €/mese) | 1,20 € | **0,25 €** | 3,01 € |
| 0,30 € | fino a 2 banche | mensile | 1,49 € | 1,04 € | 0,60 € | **0,44 €** | 5,26 € |
| 0,30 € | fino a 2 banche | annuale | 14,99 € | 10,44 € (=0,87 €/mese) | 0,60 € | **0,27 €** | 3,24 € |
| 0,30 € | fino a 6 banche | mensile | 3,99 € | 2,78 € | 1,80 € | **0,98 €** | 11,76 € |
| 0,30 € | fino a 6 banche | annuale | 39,99 € | 27,86 € (=2,32 €/mese) | 1,80 € | **0,52 €** | 6,26 € |
| 0,50 € | fino a 2 banche | mensile | 2,49 € | 1,73 € | 1,00 € | **0,73 €** | 8,82 € |
| 0,50 € | fino a 2 banche | annuale | 24,99 € | 17,41 € (=1,45 €/mese) | 1,00 € | **0,45 €** | 5,41 € |
| 0,50 € | fino a 6 banche | mensile | 5,99 € | 4,17 € | 3,00 € | **1,17 €** | 14,08 € |
| 0,50 € | fino a 6 banche | annuale | 59,99 € | 41,80 € (=3,48 €/mese) | 3,00 € | **0,48 €** | 5,80 € |

Lettura rapida: con `c` fino a 0,30 € il margine resta tra circa 0,2 e 1 € al mese per utente (pochi euro all'anno). Con 100 abbonati al livello 2 banche, mensile, `c` = 0,30 € → ≈ 44 € al mese lordi del minimo di Enable Banking.

## 7. Problemi e soluzioni
| Problema | Rischio | Soluzione |
|---|---|---|
| Apple può rifiutare un'app di finanza inviata da un account **Individual** (linea guida 5.1.1(ix)) | rifiuto, il più serio | verifica 1 di S-60t; chiedere ad Apple prima dell'invio; in alternativa una società (srl semplificata) |
| Enable Banking potrebbe non accettare una persona fisica senza P.IVA | blocco totale | domanda 1 della mail; verifica L3 |
| Registrazione presso Banca d'Italia / obblighi di legge | blocco | professionista, verifica L2/L4 |
| Fattura minima mensile alta con pochi abbonati | perdita | tetto `max_active_links`, interruttore spento, quota del livello in base al preventivo |
| `c` alto | prezzi troppo cari | livello da 4 banche invece di 6 |
| PayPal / Revolut / Trade Republic / Fineco / N26 / Hype non supportate | promessa non mantenibile | provare in sandbox prima di nominarle sul sito |
| Pagamenti ricorrenti senza P.IVA | da chiarire | domanda al professionista (vedi §8) |
| Recensioni negative per rinnovo ogni 180 giorni | reputazione | testi chiari (B06, B30–B32 già scritti in S-60), avviso 7 giorni prima |

## 8. Domande per il professionista (avvocato/consulente fintech/commercialista)
1. Registrazione presso Banca d'Italia (AISP/agente) se si usa la licenza di Enable Banking? (L2, testo esatto in `progetto-banca.md` §9)
2. Registro dei trattamenti per il collegamento bancario, DPA con Supabase ed Enable Banking, serve una DPIA? (L4)
3. **Nuova:** posso vendere un'app e un abbonamento tramite gli store senza P.IVA? Fino a quale soglia, e con quali adempimenti fiscali?
4. **Nuova:** Enable Banking mi fattura: serve una P.IVA o una società per essere loro cliente?

## 9. Mail da inviare a Enable Banking (info@enablebanking.com)
**Oggetto:** Pricing and eligibility: personal finance app (read-only), individual developer in Italy

**Corpo:**
```
Hello,

I'm Matteo Cocivera, an independent developer based in Italy. I'm building Bucktrail, a personal finance app for iOS and Android. The app is a one-time paid app, and I'd like to offer an optional, read-only bank connection (account information only, no payments) as a separate paid add-on, so that users can import their own balances and transactions.

Before going further I have a few questions:

1. Eligibility. Do you accept as a customer an individual (a natural person or a sole proprietor) based in Italy, or do you require a registered company? I don't currently have a VAT number.

2. Pricing. What is the price per connected account per month at low volumes? What is the minimum monthly invoice and how many accounts does it include? Is there any free or reduced tier for a small launch, and are the sandbox and the restricted production mode (my own accounts) free?

3. Production use. Is a separate agreement required for a commercial app, and what does it involve?

4. Regulatory role. I plan to use your AISP licence rather than apply for my own. Do I need any registration with Banca d'Italia or another body as the app publisher?

5. Data protection. Are you a joint controller or a processor for the data I receive? Is a DPA available? Where is the data processed?

6. Coverage. Are UniCredit, PayPal, Revolut and Trade Republic supported for account information, for users based in Italy? Your Italy page doesn't list Revolut, PayPal or Trade Republic. Are Fineco, N26 and Hype supported?

7. Consent. For Italian banks that require an extra authentication after 90 days, how many times a year does an end user typically have to renew? Can I list all active sessions of my application through the API?

Expected volume: a few hundred linked accounts in the first year, possibly growing. I would offer two plans (up to 2 and up to 6 linked banks per user), so I'd also like to know whether volume tiers apply.

Thank you,
Matteo Cocivera
```
Note per Matteo: il volume («qualche centinaio di conti nel primo anno») è una stima prudente scritta dal capocantiere, non un dato tuo: cambialo se pensi a un altro numero.

## 10. Cosa fare, in ordine
1. ✅ FATTO 2026-11-25 (Matteo): **non ha ancora un account Apple Developer Program** (pagina «Iscriviti all'Apple Developer Program»; solo Apple Account gratuito). Nessun pagamento fatto: il tipo si sceglie all'iscrizione. Scelta realistica senza P.IVA: **Individual**, app pubblicata **senza** collegamento bancario; la banca resta in coda. Prima di costruire S-60 chiedere ad Apple (Contact Us → App Review, con account attivo) se un'app di finanza personale con AISP terzo può uscire da un account individuale (linea guida 5.1.1(ix)); se no, srl semplificata (e P.IVA). Non pagare i 99 $ prima del gate del 6 dicembre del piano social.
2. (Matteo) Inviare la mail del §9 e incollare la risposta al capocantiere.
3. (Matteo) Porre le domande del §8 al professionista.
4. Con le risposte: rifare le tabelle del §6 con `c` e minimo veri; scegliere prezzi, durata dello sconto annuale, eventuale livello da 4 banche; aggiornare `progetto-banca.md` §12.2 e DECISIONI.md.
5. Solo allora: S-60 (collegamento, 19 task, dopo S-50) e S-61 (acquisti in-app e verifica lato server). Niente codice prima.

## 11. Fonti
- Enable Banking, [FAQ](https://enablebanking.com/docs/faq/), [Knowledge Base](https://enablebanking.com/knowledge-base), [Termini](https://enablebanking.com/terms/), [changelog](https://enablebanking.com/blog)
- Linee guida App Store 5.1.1(ix), 3.2.1(viii): vedi `progetto-banca.md` §9
- Progetto tecnico: `.cantiere/progetto-banca.md`
