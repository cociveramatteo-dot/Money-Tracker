---
name: stress-test
description: Prova il progetto sui limiti con simulatore, input estremi, stati vuoti, reti lente o assenti, dati grandi e casi di guasto. Usala dopo lavori rischiosi, prima delle consegne e quando serve cercare bug difficili da trovare con i test normali.
---
# Stress test

Obiettivo: cercare errori reali oltre il percorso normale, senza modificare il progetto per inventare capacità inesistenti.

## Quando usarla
- Prima delle consegne al cliente.
- Dopo modifiche a dati, pagamenti, autorizzazioni, API, import/export, ricerca, cache o stati asincroni.
- Quando il progetto ha limiti numerici, testi lunghi, allegati, rete intermittente o grande quantità di dati.
- Dopo un bug difficile: verificare il limite che lo ha fatto riapparire e i casi adiacenti.

## Procedura
1. Leggi solo il task in PIANO.md, il diff del lavoro e la sezione "Come si costruisce" in MAPPA.md.
2. Nel progetto avvia il simulatore già previsto. Se non esiste uno dei test normali va scritto come nuovo task, non inventato al momento.
3. Definisci una matrice minima:
   - input vuoto, nullo, minimo, massimo e formato inatteso;
   - testi molto lunghi, caratteri Unicode, HTML/URL sospetti;
   - rete lenta, timeout, assenza di rete, risposta parziale o duplicata;
   - 0 record, 1 record, molti record e record al limite;
   - sessione scaduta, permessi mancanti, refresh, doppio invio e riprovamenti;
   - dati concorrenti, interruzione a metà operazione e ripartenza.
4. Esegui i casi nel simulatore o nel browser integrato. Per ogni caso registra risultato atteso, risultato reale, passi per riprodurlo e gravità.
5. Correggi solo bug piccoli con causa chiara. Bug grandi, fallimenti di architettura o limiti non definiti diventano task `[!]` o `[?]` in PIANO.md.
6. Ripeti il caso fallito e i casi adiacenti finché passano. Non dichiarare valido un programma se il caso limite non è riprodotto in modo verificabile.
7. Aggiorna CONSEGNA e DIARIO, quindi chiudi il turno con il formato normale.

## Esito
Restituisci al massimo:
- Tabella: Dati / Input / Rete / Limiti / Concorrenza / Recupero / Sicurezza.
- Bug riprodotti e corretti.
- Bug aperti con gravità e task.
- Limiti non testati e cosa serve per testarli.

Ultima riga: `➡️ Prossimo: <task o collaudo o consegna o Matteo>`.
