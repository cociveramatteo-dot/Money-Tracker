# CONSEGNA — il biglietto per chi entra in turno

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 01:30 · S-12 collaudato, [x]

## Esito
- Confronto col mockup (`Movimenti.dc.html` renderizzato + DESIGN_HANDOFF §4) su screenshot reali: titolo grande con filtri e impostazioni, ricerca, chip tipo, riga mese/categoria/filtri attivi tratteggiata, «In arrivo · pianificati» ambra con totale, card per giorno, swipe verde «Conferma»: **conformi**. Dark, XL e tedesco ok; totale a XL su una riga; banner demo non copre più il titolo.
- Pagina unica verificata: Tutti/Fisse/Trasf./Uscite/Entrate non aprono pagine; solo Ricorrenti è a sé, coerente con i token.
- Prove rieseguite da me: **27 unit + 12 UI verdi** (simulatore 37445D1E). 7 lingue: plutil ok. Nessun file di Domain/, Models/, Sync/, Auth/, Intents/, Export/ toccato. Nessuna asserzione dei test rimossa (solo l'helper `openTransactionsSection` adattato).

## Differenze residue accettate
Dati/contenuti demo e dimensioni dispositivo diversi dal mockup; impostazioni, chip Ricorrenti e banner demo non disegnati nel mockup ma da mantenere; icone categoria dell'app invece delle iniziali; swipe nativo iOS. Ricorrenti non ha mockup.

## Aperto
- Tab bar a XL con etichette troncate → S-10 (collaudo finale).
- Ricorrenti: nessun difetto grafico grave; il chip «Tutte le categorie» è più alto dei chip di Movimenti (ritocco opzionale) e i testi «3 volte · dal 19 ago» dipendono dal vecchio motore → S-13.
- Il collaudo non ha ricontrollato schermata per schermata gli altri dispositivi/lingue oltre quelle fotografate.

## Prossimo passo
Codex: S-13a + S-13b (prompt già dato a Matteo). Poi S-6, S-14, S-7, S-8, S-9, S-10.
