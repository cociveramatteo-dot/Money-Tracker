# CONSEGNA — SC-5 / SC-6 · 2026-11-17 21:21

Pipeline in [SOCIAL/montaggio](../SOCIAL/montaggio/README.md). FFmpeg era presente in `/opt/homebrew/bin/ffmpeg` senza libass. Installata la formula Homebrew `ffmpeg-full`, rilevata automaticamente dallo script. Test di fumo ASS e SRT superati su clip sintetica con tagli e accelerazione 2×. Verificati 1080×1920, 30 fps, H.264, 15–20 Mbps, Rec.709 e audio opzionale. Verificata anche la conversione di una clip HDR PQ sintetica in Rec.709. Da collaudare su riprese vere F1 e F4, inclusa leggibilità in safe zone.

Fuori dal commit: `Claude outputs/`, le modifiche di altri a `.cantiere/DECISIONI.md` e quelle relative a SC-1 in `.cantiere/PER-MATTEO.md`.

## SC-4 · Landing e scelta del servizio

Landing statica in `SOCIAL/landing/`, in italiano e inglese, con font locali e informativa italiana da far rivedere a Matteo. Test JavaScript superati per l'inoltro dei campi UTM, il cambio lingua e il blocco dell'invio finché l'azione è segnaposto. Restano la verifica visiva del collaudatore e la prova di iscrizione con il servizio effettivo.

## Opzioni per Matteo

- **Brevo Free** · 300 invii al giorno. Offre registri del consenso e mette a disposizione un DPA. Dichiara hosting dei dati in Francia e Germania per l'offerta transazionale. Per il modulo scelto verificare subfornitori e trasferimenti, disattivare il tracciamento e verificare che il POST conservi consenso e campi UTM. [Piano](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan) · [Registri](https://www.brevo.com/products/marketing-platform/) · [Hosting](https://www.brevo.com/products/transactional-email/) · [DPA](https://help.brevo.com/hc/en-us/articles/15403782599570-Where-can-I-find-the-Data-Processing-Agreement-DPA)
- **MailerLite Free** · 250 iscritti attivi e 2.500 invii al mese. DPA disponibile e archiviazione nei Paesi Bassi per il servizio attuale. Il DPA disciplina anche i trasferimenti internazionali. Verificare le condizioni applicabili all'account italiano e che il modulo accetti campi nascosti senza script di tracciamento. [Piano](https://www.mailerlite.com/help/free-plan-update-faq) · [DPA](https://www.mailerlite.com/legal/data-processing-agreement)

Prima dell'attivazione scegliere hosting e servizio, compilare e approvare l'informativa (art. 13 GDPR), configurare un endpoint HTTPS per il POST, mappare i campi email, consenso e UTM e usare la conferma del redattore dopo l'accettazione effettiva. Configurare cancellazione e prova del consenso. [GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/)

## SC-6 · Diario delle metriche

Creati `SOCIAL/diario-metriche.csv` e `SOCIAL/diario-metriche.md`. Il CSV contiene le 15 intestazioni richieste e una sola riga chiaramente segnata `ESEMPIO`, senza valori numerici reali. Il Markdown documenta compilazione, mediana settimanale degli ultimi 10 video per piattaforma, promozione/abbandono dei format e formula dell'engagement rate.
