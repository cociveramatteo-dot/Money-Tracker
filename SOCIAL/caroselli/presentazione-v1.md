# Carosello di presentazione — «Bucktrail: tutta l'app in 8 slide» (v1)

Stato: BOZZA, ⏳ da approvare da Matteo. Nulla è da pubblicare.
Montaggio 2026-11-19: 9 slide 4:5 (1080×1350) generate da `SOCIAL/caroselli/presentazione-v1/build.py` con gli screenshot di Matteo (banner «modalità demo» tolto, status bar 9:41, nota «Dati di esempio»). Uscite in `SOCIAL/clip-social/uscite/presentazione-v1/` (fuori da git). Hook A scelto come predefinito; Obiettivi su slide separata. Screen «Aggiungi spesa» e Ricorrenze rifatti da Matteo (IMG_7921, IMG_7922) e montati.
Formato: faceless (DECISIONI 2026-11-19). Nessuna voce, volto, persona, «io». Voce di brand «Bucktrail».
Piattaforme: TikTok photo mode + Instagram carosello. Lingua: italiano.
Stile: slide bianche pulite (stile @easlonotes), titolo grande + una frase corta (max 5 parole per riga, max ~12 parole totali), mockup iPhone con lo screenshot indicato.
Prezzo: sempre «prezzo di lancio previsto». L'app NON è sull'App Store: mai «scarica».

---

## Slide

### Slide 1 — Titolo (hook)
- Titolo (variante A, consigliata): **Bucktrail: il budget senza abbonamenti**
- Titolo (variante B): **Questa linea tratteggiata dice se arrivi a fine mese**
  (se si usa B, il titolo «Bucktrail: il budget senza abbonamenti» passa a sottotitolo piccolo)
- Sottotitolo: Tutta l'app in 8 slide
- Screenshot: nessuno (solo testo e logo). Con la variante B: lo screenshot Home (slide 2) ritagliato sulla curva.

### Slide 2 — Home
- Titolo: **La Home**
- Frase: La linea tratteggiata dice / se arrivi a fine mese
- Screenshot: Home con la curva del mese corrente (tratto verde reale + tratto ambra tratteggiato di proiezione) e il saldo atteso visibili. Modalità chiara.

### Slide 3 — Aggiungi spesa
- Titolo: **Aggiungi una spesa**
- Frase: Importo, categoria, fatto
- Screenshot: schermata di inserimento di una nuova spesa, con importo e categoria compilati.

### Slide 4 — Movimenti
- Titolo: **Movimenti**
- Frase: Tutto quello che entra e esce / in un elenco
- Screenshot: lista Movimenti con alcune voci (spese ed entrate).

### Slide 5 — Ricorrenti
- Titolo: **Ricorrenti**
- Frase: Affitto e abbonamenti / entrano nel mese prima
- Screenshot: schermata Ricorrenti con 2-3 voci fisse.

### Slide 6 — Budget e obiettivi
- Titolo: **Budget e obiettivi**
- Frase: Avviso all'80% / prima di sforare
- Screenshot: schermata Budget per categoria con una barra vicina alla soglia; se possibile affiancare gli Obiettivi con avanzamento (due mockup, oppure due slide separate se non entrano).

### Slide 7 — Statistiche
- Titolo: **Statistiche**
- Frase: Capisci dove vanno i soldi
- Screenshot: schermata Statistiche con grafico e categorie.

### Slide 8 — Chiusura
- Titolo: **Seguici per altro**
- Elementi: logo Bucktrail al centro, poi:
  - Riga 1: **Lista d'attesa: link in bio** (versione Instagram)
  - Riga 1 TikTok: **Lista d'attesa: bucktrailapp.com** (regola TikTok: finché non c'è il campo link, «link in bio» diventa «lista d'attesa su bucktrailapp.com»)
  - Riga 2: **4,99 € una volta** (piccolo: «prezzo di lancio previsto»)
- Screenshot: nessuno. Serve il logo.
- Nota: le slide 8 di TikTok e Instagram sono due file diversi.

---

## Screenshot da fornire (elenco)
1. Home con curva verde + ambra tratteggiata e saldo atteso (slide 2, e slide 1 se variante B)
2. Aggiungi spesa, compilata (slide 3)
3. Movimenti, con voci (slide 4)
4. Ricorrenti, con voci (slide 5)
5. Budget (+ Obiettivi) (slide 6)
6. Statistiche (slide 7)
7. Logo Bucktrail, file pulito (slide 1 e 8)

Regole screenshot: dati di esempio verosimili ma dichiarati come tali [DA COMPLETARE: Matteo prepara i dati demo]; nessuna scritta «modalità demo» visibile (regola social); niente nomi o dati personali reali; modalità chiara su tutti.

---

## Caption

### TikTok
> Bucktrail: l'app di budget per iPhone senza abbonamento. Home con la linea che mostra come finisce il mese, spese veloci, ricorrenti, budget, obiettivi e statistiche. Prezzo di lancio previsto: 4,99 € una volta. Lista d'attesa su bucktrailapp.com
> #bucktrail #budget #appiphone #finanzapersonale

### Instagram
> Bucktrail: l'app di budget per iPhone senza abbonamento. Home con la linea che mostra come finisce il mese, spese veloci, ricorrenti, budget, obiettivi e statistiche. Prezzo di lancio previsto: 4,99 € una volta. Lista d'attesa: link in bio.
> #bucktrail #budget #appiphone #finanzapersonale #appbudget

(5 hashtag su Instagram, 4 su TikTok. Niente promesse su cloud/sincronizzazione, niente promesse di risparmio, niente nomi di concorrenti.)

---

## Musica TikTok (solo mood)
Strumentale, calma e pulita: lo-fi leggero o pianoforte morbido, ritmo lento, senza voce cantata né parlato. Scegliere dalla libreria TikTok tra i suoni in tendenza al momento della pubblicazione, che non siano parlati: [DA COMPLETARE: Matteo sceglie il suono al momento]. Su Instagram: musica dalla libreria IG, stesso mood.

---

## Dubbi (verificati sul codice dal capocantiere, 2026-11-19)
1. **Avviso all'80%: confermato.** `NotificationManager.swift` manda una notifica quando la spesa raggiunge almeno l'80% del limite mensile del budget. La frase della slide 6 è corretta.
2. **Budget e Obiettivi sono due schermate separate** (due segmenti dentro la tab Pianifica). Slide 6 = Budget; gli Obiettivi vanno su una slide 7 separata (le slide diventano 9) oppure si affiancano due mockup. Scelta di Matteo.
3. **Titolo slide 3:** non risulta un nome fisso «Aggiungi una spesa» nel codice: allineare al titolo reale vedendo lo screenshot.
4. **Variante hook A o B:** [DA SCEGLIERE: Matteo].
5. **Dati demo:** li prepara Matteo (app in modalità demo); la scritta «modalità demo» si toglie nel montaggio.
