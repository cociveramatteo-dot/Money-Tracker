---
name: checkpoint
description: Checkpoint del cantiere - collaudo, pulizia, magazzino, grafo graphify, guardiano, pagella misurata, verbale, commit e tag - per ripartire domani leggendo un solo file. Usala quando Matteo dice "facciamo il checkpoint", "checkpoint", "checkpoint veloce", "vado a dormire", "chiudiamo per oggi".
---
# Checkpoint

Obiettivo: cantiere pulito, funzionante, documentato. Chi riapre legge SOLO `.cantiere/CHECKPOINT.md`.
In Claude Code ogni fase va al subagente indicato (contesto separato: a te torna il riassunto).
Con altre IA esegui tu le fasi, nello stesso ordine. Ordine: si ripara → si pulisce → si rileva → si verbalizza.

## Completo
0. **Fermo lavori** (capocantiere): chiudi turni aperti; STATO = `CHECKPOINT dalle HH:MM`; individua il lavoro
   dall'ultimo tag: `git log --oneline <tag>..HEAD`, `git diff --stat <tag>..HEAD`.
1. **Collaudo** → `collaudatore`: `bash .cantiere/strumenti/collaudo.sh` + rilettura del diff + rapporto del
   guardiano (`.cantiere/guardiano/ULTIMO.md`, solo riassunto: se è più vecchio dell'ultimo push o manca, prima
   `bash .cantiere/strumenti/guardiano/scarica.sh`; un esito già nel rapporto NON si scrive come "da verificare") + `python3 .cantiere/strumenti/bilingue.py`
   se il sito ha più lingue. Bug piccoli (< 20 righe, causa chiara) si correggono; grandi → task.
2. **Pulizie** → `pulizie`: skill `pulizia` fase A.
3. **Magazzino** → `magazziniere`: skill `pulizia` fase B (catalogo incluso).
   Poi `python3 .cantiere/strumenti/biblioteca.py`: se ci sono fonti da aggiungere/ricaricare nel notebook, scrivi la
   voce in `.cantiere/PER-MATTEO.md` con le istruzioni che stampa (complete, da copiare).
4. **Rilievo** → `geometra`: `graphify update .` + 3–5 righe su cosa è cambiato. Se graphify manca: 🔴 e comando.
5. **Pagella misurata**: `python3 .cantiere/strumenti/pagella.py --misurata` (0 crediti di giudizio).
6. **Verbale** → `segretario`: riscrive `CHECKPOINT.md` col MODELLO (`MODELLO.md` in questa cartella, max 120 righe),
   copia in `.cantiere/archivio/checkpoint/AAAA-MM-GG_HHMM.md`, riga `== CHECKPOINT` nel DIARIO, CONSEGNA e PIANO aggiornati.
   Le voci ⏳ di APPROVAZIONI vanno tra le "Cose che deve fare Matteo".
7. **Sigillo** (capocantiere): STATO `In turno: nessuno` + ultimo checkpoint; `git add -A && git commit -m "== checkpoint AAAA-MM-GG HH:MM"`;
   `git tag checkpoint-AAAA-MM-GG-HHMM`; poi `bash .cantiere/strumenti/backup.sh` (push su GitHub + copia aggiornata
   nel magazzino + specchio verificato dei file fuori da git in `02_RISORSE/lavorate/fuori-git/`; se compare 🔴 «non allineato» il checkpoint NON è chiuso; se dice che serve Matteo, scrivi la voce in PER-MATTEO.md col comando che stampa).
   Rispondi in max 10 righe: salute, cosa è stato sistemato, prime 3 cose di domani, e le voci aperte di
   `PER-MATTEO.md` (ognuna con 📍 dove · ▶️ cosa · ↩️ cosa riportare).
   Chiudi con: "Puoi chiudere. Domani apri una sessione nuova e scrivi: riprendiamo."

## Veloce ("checkpoint veloce")
Niente subagenti, pochissimi crediti: fase 0 → `collaudo.sh` + `magazzino.py` + `spazio.sh` (solo esiti) →
`graphify update .` → `pagella.py --misurata` → `biblioteca.py` → aggiorna SOLO "Siamo qui", "Stato di salute", "Domani si riparte così"
→ riga `== CHECKPOINT (veloce)` → fase 7. Ogni 3 veloci, e sempre prima di una consegna, si fa il completo.
