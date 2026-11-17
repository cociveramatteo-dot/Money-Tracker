---
name: consegna
description: Prepara la consegna di una versione al cliente - controlla pagella, approvazioni e guardiano, crea il pacchetto e il messaggio per il cliente. Usala quando Matteo dice "prepariamo la consegna", "consegniamo", "mandiamo al cliente", "pubblichiamo".
---
# Consegna

Niente arriva al cliente senza aver superato i controlli. Se un controllo fallisce ti FERMI e dici cosa manca.

1. **Checkpoint completo** (skill `checkpoint`), se l'ultimo ha più di un giorno o è veloce.
2. **Guardiano** fresco (skill `guardiano`): non deve essere 🔴.
3. **Pagella completa** con 2 giudici (skill `pagella`): deve risultare consegnabile ✅.
3b. **Controllo sul sito pubblicato, in una finestra in incognito** (telefono e computer): il guardiano prova la
   build locale, non vede quello che aggiunge l'hosting. Cerca badge o barre di terzi (es. "Powered by Netlify":
   si spegne in Project configuration → General) che coprono pulsanti fissi (WhatsApp, menu, cookie), e controlla
   che il `noindex` dell'anteprima sia tolto solo al lancio.
4. **Approvazioni**: in `.cantiere/APPROVAZIONI.md` tutte le voci della versione devono essere ✅.
   Mancano? Prepara per Matteo il messaggio per il cliente (breve, elenco numerato, niente soldi).
5. **Pacchetto** in `04_CONSEGNE/AAAA-MM-GG_v<N>/` (nel magazzino):
   - `NOTE.md`: cosa c'è di nuovo, link al sito/anteprima, cosa resta da fare, dati mancanti dal cliente;
   - copia della pagella (`.cantiere/archivio/pagelle/…`) e 3 screenshot (telefono, tablet, desktop);
   - se richiesto, l'archivio del sito (`zip`), mai i file sorgente originali del cliente.
6. **Tag** `consegna-AAAA-MM-GG-v<N>` + push. Riga in DIARIO e in APPROVAZIONI ("consegnata v<N>").
7. **Messaggio per il cliente** pronto da copiare (tono del cliente, link, cosa deve controllare lui).
8. Cartellino con `➡️ PROSSIMO: Matteo — invia il messaggio al cliente`.

Pubblicare online (es. Netlify in produzione, dominio) è un'azione da confermare SEMPRE con Matteo prima.
