# CHECKPOINT — MoneyTracker

**Data** 2026-11-21 09:53 · **Tag** `checkpoint-2026-11-21-0953` · **Ramo** `redesign-sentiero`

## Siamo qui

- **Android è il primo lavoro alla ripresa.** Matteo ha dato il via, poi ha chiesto di salvare prima di programmare. Sono stati scaricati JDK 17 e Android Command-Line Tools per Mac ARM in `/tmp/bucktrail-android`. La toolchain va ancora configurata. Il progetto Android è ancora da creare.
- **iOS** è il riferimento per la parità Android. S-41 mette le spese fisse singole nel mese di competenza. S-42 corregge l’annullamento dell’eliminazione delle serie e la sezione Ultimi movimenti.
- **Landing Bucktrail** online in italiano e inglese. Annuncia iPhone e Android e il collegamento bancario facoltativo dopo il lancio. Bio, post fissato e banner YouTube aggiornati. Email di lancio da preparare quando ci saranno i link degli store.
- **Social**. Post-1 e 2 pubblicati. Post-3–42 pronti nel Drive «Da postare», con 241 slide per piattaforma e 40 LEGGIMI. Guida in `SOCIAL/direttive-social.md`. Date da fissare in `SOCIAL/calendario-v1.md`.

## Stato di salute

| Verifica | Esito |
|---|---|
| iOS | 94 test unitari e 3 UI mirati a ricorrenze e Home verdi sul simulatore iPhone. Log `/tmp/mt-checkpoint-20261121-xcode.log`. |
| Landing | Controllo statico dedicato con 0 errori e 0 avvisi. Entrambe le pagine pubbliche verificano lingua, Android e collegamento bancario. |
| Controllo generale | 26 errori su riferimenti `file://` in HTML di lavorazione esclusi da Git. Il controllo bilingue generico non riconosce le coppie di pagine con i nomi attuali. I file di pubblicazione e le pagine online sono stati verificati direttamente. |
| Social e magazzino | 522 file verificati in «Da postare». Nel magazzino è stato aggiornato il catalogo e sono stati verificati 418 file di lavoro social nella copia `02_RISORSE/lavorate/fuori-git/SOCIAL/`. |
| Grafo | Aggiornato con 1.912 nodi, 3.490 archi e 318 comunità. |
| Pagella e guardiano | Pagella automatica parziale 99/100. Il guardiano dà 404 perché il workflow non è disponibile sul ramo predefinito `main`. Nessun nuovo dato di prestazioni o SEO. |
| Spazio | Circa 21 GiB liberi sul Mac. Conviene iniziare con gli strumenti da terminale e un telefono Android fisico, se disponibile. |

## Domani si riparte così

1. **Android**. Configurare JDK, SDK e Gradle da terminale. Creare il progetto Kotlin/Compose per VS Code. Usare l’iOS attuale come riferimento per la prima versione di Home, Conti e Movimenti. Poi provare su Supabase di test accesso con lo stesso profilo, spesa offline, sincronizzazione tra piattaforme e assenza di duplicati.
2. **Banca**. Confrontare TrueLayer e Yapily per l’accesso in sola lettura. Provare in sandbox e poi verificare copertura su conti italiani prioritari, tempi per movimenti in attesa e contabilizzati, recupero dopo disconnessione, rinnovo del consenso e costo. L’utente sceglie i singoli conti e può confermare l’abbinamento con una spesa già inserita a mano.
3. **Social e lancio**. Fissare le date e usare i LEGGIMI. Prima della pubblicazione verificare il doppio tocco del Post-12 e widget/Siri del Post-39 su iPhone fisico. Il Post-41 richiede la build con login Bucktrail e la prova reale di sincronizzazione iPhone–Android. Il Post-40 mostra il percorso alla cronologia e illustra le etichette con esempi.
4. **iOS**. Fare il controllo visivo di S-41 e chiudere S-36 e S-42 secondo il piano. Il merge su `main` resta una decisione separata.

## Cose che deve fare Matteo

- **Calendario social**. Apri Drive → «Da postare» e scrivi qui il giorno da cui vuoi partire.
- **App Store**. In `SOCIAL/testi-v1.md` controlla la scheda IT/EN e scrivi «testi App Store ok» o le correzioni. La landing e le bio hanno già la propria approvazione.
- **NotebookLM**. Nel notebook «MoneyTracker App» → «Aggiungi fonte» → «Google Drive», seleziona `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md`, poi scrivi «notebook ok». Le licenze facoltative sono in `PER-MATTEO.md`.

## Riferimenti

- `docs/MoneyTracker.md` e `docs/MoneyTracker.pdf`, aggiornati alla versione 3.22.
- `PIANO.md` e `PER-MATTEO.md` per le verifiche aperte. `MAPPA.md` per archivio e percorsi social.
