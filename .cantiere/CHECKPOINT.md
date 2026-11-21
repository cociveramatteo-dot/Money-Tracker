# CHECKPOINT — MoneyTracker

**Data** 2026-11-21 10:30 · **Tag** `checkpoint-2026-11-21-1030` · **Ramo** `redesign-sentiero`

## Siamo qui

- **Android**. Prima build Kotlin/Compose in `03_CODICE/bucktrail-android`: Home, Conti e Movimenti con salvataggio locale Room. Aggiunti data, modifica, stato pianificato ed effettuato. Emulator Pixel `Bucktrail_API_36`. Supabase rinviato da Matteo.
- **iOS** è il riferimento per la parità Android. S-41 mette le spese fisse singole nel mese di competenza. S-42 corregge l’annullamento dell’eliminazione delle serie e la sezione Ultimi movimenti.
- **Landing Bucktrail** online in italiano e inglese. Annuncia iPhone e Android e il collegamento bancario facoltativo dopo il lancio. Bio, post fissato e banner YouTube aggiornati. Email di lancio da preparare quando ci saranno i link degli store.
- **Social**. Post-1 e 2 pubblicati e Post-3–42 in Drive «Da postare», come verificato nel checkpoint delle 09:53. Calendario e pubblicazione affidati direttamente a Matteo.

## Stato di salute

| Verifica | Esito |
|---|---|
| Android | Build APK e lint senza errori. 4 test JVM verdi. Migrazione Room v1 → v2 verificata su emulatore: dati precedenti integri, spesa di dicembre da 30 € salvata e modificata, saldo di novembre fermo a 80,50 €. Verificata anche la conferma di un movimento in data odierna e il passaggio dalla previsione al saldo. |
| iOS | Risultato del checkpoint delle 09:53: 94 test unitari e 3 UI mirati a ricorrenze e Home verdi sul simulatore iPhone. Log `/tmp/mt-checkpoint-20261121-xcode.log`. |
| Landing | Controllo statico dedicato con 0 errori e 0 avvisi. Ultima verifica alle 09:53 su entrambe le pagine pubbliche. |
| Controllo generale | 26 errori su riferimenti `file://` in HTML di lavorazione esclusi da Git. Il controllo bilingue generico non riconosce le coppie di pagine con i nomi attuali. I file di pubblicazione e le pagine online sono stati verificati direttamente. |
| Social e magazzino | 522 file verificati in «Da postare». Nel magazzino è stato aggiornato il catalogo e sono stati verificati 418 file di lavoro social in `02_RISORSE/lavorate/fuori-git/SOCIAL/` al checkpoint precedente. APK debug e due schermate Android verificate in `02_RISORSE/lavorate/fuori-git/ANDROID/`. |
| Grafo | Aggiornato anche per la pianificazione Android e i relativi test. |
| Pagella e guardiano | Pagella automatica parziale 98/100. Il guardiano dà 404 perché il workflow non è disponibile sul ramo predefinito `main`. Nessun nuovo dato di prestazioni o SEO. |
| Spazio | JDK, SDK, Gradle ed emulatore già installati. I file di build e le cache restano locali. |

## Domani si riparte così

1. **Android**. Aprire `03_CODICE/bucktrail-android` in VS Code. Riprendere la parità locale con iOS da categorie e filtri di Movimenti, poi trasferimenti, ricorrenze, Pianifica e Statistiche. Riprendere Supabase solo dopo la decisione di Matteo.
2. **Banca**. Confrontare TrueLayer e Yapily per l’accesso in sola lettura. Provare in sandbox e poi verificare copertura su conti italiani prioritari, tempi per movimenti in attesa e contabilizzati, recupero dopo disconnessione, rinnovo del consenso e costo. L’utente sceglie i singoli conti e può confermare l’abbinamento con una spesa già inserita a mano.
3. **Social**. Matteo gestisce calendario e pubblicazione. Il materiale resta nel Drive e nel magazzino.
4. **iOS**. Fare il controllo visivo di S-41 e chiudere S-36 e S-42 secondo il piano. Il merge su `main` resta una decisione separata.

## Cose che deve fare Matteo

- **App Store**. In `SOCIAL/testi-v1.md` controlla la scheda IT/EN e scrivi «testi App Store ok» o le correzioni. La landing e le bio hanno già la propria approvazione.
- **NotebookLM**. Nel notebook «MoneyTracker App» → «Aggiungi fonte» → «Google Drive», seleziona `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md`, poi scrivi «notebook ok». Le licenze facoltative sono in `PER-MATTEO.md`.

## Riferimenti

- `docs/MoneyTracker.md` e `docs/MoneyTracker.pdf`, aggiornati alla versione 3.23.
- `PIANO.md` e `PER-MATTEO.md` per le verifiche aperte. `MAPPA.md` per archivio e percorsi social.
