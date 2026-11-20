# Direttive social Bucktrail

**Lettura obbligatoria all’inizio di ogni lavoro social.** Questo è il riferimento operativo. Il [manuale strategico](Bucktrail_Manuale_Strategico_v2.pdf) resta la fonte per idee, format, hook, metriche e cautele (§1.3, §4, §6, §9, §12). Per le funzioni verificare il [documento prodotto](../docs/MoneyTracker.md) e la build corrente. Il [calendario](calendario-v1.md) contiene proposte, approvazioni e storico.

## Prima di preparare ogni nuovo post

1. Aprire e guardare **tutte le slide e tutti i video dei post precedenti**, incluse copertine, chiusure e varianti per canale. Usare i file finali in `clip-social/post-N/pronto/` o recuperare gli export/storico. Registrare nella lavorazione del nuovo post quali numeri e varianti si sono visti, eventuali file mancanti e correzioni emerse. Una lettura dei testi o del codice di generazione da sola non vale come controllo visivo.
2. Confrontare tema, esempio, hook, inquadrature e invito all’azione con lo storico. Correggere gli asset precedenti ancora in lavorazione o destinati al riuso e applicare tutte le correzioni permanenti alla nuova esportazione. Registrare i difetti dei post già usciti e mantenere una copia storica dell’export pubblicato. Eventuali interventi su post online li decide Matteo.
3. Consultare [schermate-app](schermate-app/README.md) e verificare sulla build il percorso e il risultato promesso. **Per ogni post e ogni altro materiale social, se serve una schermata, un importo, uno stato o un’inquadratura diversi, aprire il simulatore, preparare i dati fittizi nell’app e catturare direttamente quello che serve.** Vale anche quando Matteo ha già fornito screenshot. Usare dati coerenti fra le slide, lasciare intatti gli originali e salvare le nuove catture nell’archivio condiviso o nel materiale del post. Coinvolgere Matteo solo se il materiale richiede davvero un dispositivo fisico o il simulatore non permette di produrlo.

## Tre rubriche

- **Guida alle schermate.** Copertina ricorrente «Guida: HOME», «Guida: MOVIMENTI», ecc. Mostrare dove si trovano i comandi e a cosa serve la schermata. Raccogliere le guide in [guida](guida/README.md).
- **Tutorial di una funzione.** Mostrare partenza, tocchi e risultato. Dedicare un post ai flussi articolati. Raggruppare le funzioni brevi quando risolvono lo stesso problema, come lingue disponibili e percorso per cambiarle.
- **Educazione finanziaria.** Partire da una situazione concreta di gestione di entrate, spese o budget. Chiudere mostrando la schermata o l’azione utile in Bucktrail. Dichiarare gli esempi. Evitare investimenti, consigli personalizzati e promesse di risparmio.

## Grafica e controllo prima della consegna

- Prendere come riferimento i post 1 e 2. Caroselli puliti, titoli grandi, fondo chiaro per la spiegazione, apertura e chiusura scure quando aiutano. Mani e iPhone nei video, niente volto né voce. La musica viene scelta da Matteo in piattaforma.
- Usare l’iPhone a metà per ingrandire una sola zona e intero quando contano percorso o navigazione. Usare schemi o numeri in grafica quando spiegano meglio della schermata. La copertina è ricorrente per le guide e facoltativa per gli altri post.
- Rimuovere ogni icona, banner o badge «MODALITÀ DEMO» visibile nelle catture pubblicate. Mantenere il logo Bucktrail. Usare solo dati di esempio, eliminare notifiche, nomi, email e altri dati personali. Scrivere «Dati di esempio» anche in copertina quando si vedono importi dimostrativi dell’app. Conservare intatti gli screenshot sorgente.
- Controllare barra di stato coerente nel carosello (9:41, segnale, 5G e batteria 59% come riferimento), tab bar al fondo del telefono intero con il solo margine di sicurezza e ritagli intenzionali. Usare la stessa schermata solo se serve a dimostrare un passaggio diverso.
- Aprire ogni export sul formato di destinazione. Controllare ordine, testi e importi leggibili, margini, ritaglio della griglia Instagram, CTA e link di ciascun canale. Le schermate devono rispecchiare la build reale. «Cambio valuta» va spiegato secondo il comportamento verificato, senza implicare conversioni automatiche.
- Posizionamento Bucktrail: conti e movimenti personali in un’unica app, design Sentiero, sezioni chiare e pagamento una tantum. Se si cita €4,99 prima della disponibilità, usare «prezzo di lancio previsto». Evitare «definitiva», concorrenti per nome e affermazioni non verificate su cloud, privacy o IA. Adeguare la CTA alla disponibilità effettiva dell’app e al link attivo sul canale.

## Comunicazione sul lancio

- Nelle caption e nelle chiusure dei prossimi post di lancio usare «In arrivo su iPhone e Android. Iscriviti alla lista d’attesa.». Identificare le catture come anteprima iPhone quando la piattaforma è rilevante. Verificare il link della lista d’attesa su ciascun profilo.
- Il collegamento bancario è una funzione prevista dopo il lancio, facoltativa per conto e limitata alle banche supportate. Sui social si può proporre un sondaggio sulle banche da valutare. La versione web resta fuori dalla comunicazione corrente.

## Calendario, approvazione e consegna

- Alternare guide, tutorial ed educazione. Pianificare 1–2 post per giorno di pubblicazione. Quando ce ne sono due, usare rubriche e argomenti diversi. Un post extra entra solo su richiesta di Matteo.
- Il 20/11 Matteo ha approvato il piano in blocco a condizione che copra tutta l’app. Preparare le scalette e i materiali senza chiedere un nuovo ok per ogni post. Usare la mappa di copertura del calendario, verificare funzioni e catture sulla build e registrare lo stato. Concordare con Matteo date, slot e pubblicazione.
- Preparare `istruzioni-post/post-N.txt` con data, orari locali per canale, giorni esclusi, ordine, titolo per TikTok, caption, 5–6 hashtag per piattaforma, link e passi di pubblicazione. Omettere la musica dalle istruzioni: ci pensa Matteo. Esportare con `python3 SOCIAL/esporta-post.py N` in «Il mio Drive/Da postare/post-N/». Verificare che contenga solo i file da pubblicare e il LEGGIMI. Matteo pubblica. Registrare link e metriche nel diario.
