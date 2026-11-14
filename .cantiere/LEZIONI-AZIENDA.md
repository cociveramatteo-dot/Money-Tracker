# LEZIONI PER L'AZIENDA — da MoneyTracker (redesign Sentiero)

> Il capocantiere lo aggiorna a ogni lavoro chiuso o inciampo. Serve a Matteo quando aggiorna l'azienda a una versione nuova.
> Ogni voce: cosa è successo → cosa cambiare. Ultimo aggiornamento: 2026-11-14.

## Da cambiare nell'azienda (priorità alta)
1. **Mockup sempre.** Se esiste un mockup, ogni schermata va confrontata con quello su screenshot reali prima di dirla «conforme»: per chi esegue e per il collaudatore. S-5 è stato chiuso «ok» da me guardando solo test e funzioni, e Matteo ha trovato differenze. → Nelle schede e nella skill del collaudatore: «conforme» = elenco scritto delle differenze dal mockup (anche zero) + screenshot light/dark/XL/lingua lunga.
2. **Turno interrotto da fine quota.** Antigravity ha finito la quota a metà S-12, lasciando 14 file non committati e il turno aperto. → Procedura scritta: quota esaurita = chi se ne accorge libera il turno su ordine di Matteo, annota in DIARIO, il codice a metà resta non committato, un'altra impresa riprende leggendo `git diff`. Meglio: le imprese committano su ramo di lavoro a ogni passo verificato.
3. **Verifica «a vista» prevista dal piano ma non garantita.** Codex non l'ha potuta fare (controllo del Simulatore in timeout, runner test fermo). → Nel brief, un metodo che funziona sempre: `simctl shutdown all` + boot, e screenshot con UI test temporaneo (`--uitesting`, scrive il PNG su file, poi si cancella). Messo nei prompt di S-12.
4. **Le deroghe vanno scritte.** Le zone «intoccabili» (Domain, Models, Sync, test) bloccavano la correzione delle ricorrenze. Servono ok di Matteo scritto in DECISIONI (D-008, D-009) prima del lavoro. → Aggiungere alla scheda del task il campo «deroghe autorizzate».
5. **Un turno alla volta rallenta.** Mentre un'impresa lavora non si può collaudare né avviare l'altra. → Va bene per sicurezza; per i task su file diversi valutare turni paralleli espliciti (es. grafica vs dati) con elenco dei file riservati.
6. **I rapporti dei subagenti si verificano.** L'architetto ha dato una causa convincente (copie cancellate dal sync); l'ho controllata nel codice prima di riferirla. → Regola: la prova della conclusione principale si controlla sempre.

## Cosa va bene (da tenere)
- **Lettura a strati + graphify**: il capocantiere trova il punto giusto senza leggere il progetto.
- **Architetto prima del codice** su lavori che toccano dati/schema/sync: piano con rischi e domande per Matteo, senza modificare il repository.
- **Collaudatore che esegue davvero test e UI test** (27 unit + 12 UI) e non solo legge il diff.
- **Cartellino finale + CONSEGNA/PIANO/DIARIO**: permettono di riprendere dopo /clear o cambio d'impresa.
- **Decisioni scritte (DECISIONI.md)** con ok di Matteo: evitano di rimettere in discussione.

## Chi fa meglio cosa (osservazioni, non verità: aggiornare)
| IA | Bene | Male / attenzione |
|---|---|---|
| **Claude Code · Sonnet (capocantiere/collaudatore)** | coordinare, collaudare con test reali, riconoscere errori e scrivere decisioni | ha chiuso S-5 senza mockup (errore mio); ha detto che il Budget mancava mentre esisteva: prima verificare nel codice/documento master |
| **Architetto · Opus** | analisi di sistema, trovare cause profonde (sync), piani con sotto-task e rischi | costa: usarlo per dati/architettura, non per la grafica |
| **Codex** | restyling con grande attenzione a identificatori e test, build verde, i18n x7 | controllo del Simulatore instabile (timeout, runner fermo): ha consegnato senza verifica a vista |
| **Antigravity · Gemini Flash (piano starter)** | grande volume di modifiche UI in poco tempo, screenshot comparativi | quota esaurita in un solo lavoro (pausa di una settimana); consuma molto con tanti controlli ogni 15–25 secondi su test lunghi (meglio un'unica attesa); non ha chiuso il turno né confrontato il mockup prima di restare senza quota. Per lavori lunghi serve un piano più capiente o lavori spezzati |

## Suggerimenti per la versione successiva
- Scheda task con campi fissi: **mockup di riferimento**, **deroghe autorizzate**, **file riservati**, **come si verifica a vista**.
- Prima di assegnare grafica a un'impresa, controllare la quota residua; per task grossi spezzarli in passi che finiscono in un turno.
- Skill `collaudo-mockup`: apre il mockup, scatta gli screenshot (light/dark/XL/lingua lunga) e produce la tabella delle differenze.
- Tenere in ogni progetto le domande ricorrenti di Matteo («abbiamo davvero guardato il mockup?») come controlli automatici nella pagella.
- Nei prompt dare sempre il comando per liberare il runner del simulatore.
