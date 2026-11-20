# Diario delle metriche social

## Uso

Una riga del file `diario-metriche.csv` corrisponde a una pubblicazione. Compila una riga per ogni video dopo la pubblicazione, usando:

- `data` nel formato `AAAA-MM-GG`
- `ora` nel formato `HH:MM`
- `piattaforma` con il nome della piattaforma
- `codice_format` e `variante_hook` per identificare format e variante
- tutti i campi numerici in cifre, senza unità aggiunte

Lascia vuoti i dati non ancora disponibili o non esposti dalla piattaforma. Non usare la riga `ESEMPIO` nei dati reali: va sostituita o rimossa quando si iniziano a registrare pubblicazioni effettive.

## Calcolo settimanale

Ogni domenica, per ogni piattaforma, calcola la mediana degli ultimi 10 video. Usa la mediana, non la media.

## Decisione sui format

- Promuovi un format quando 2 varianti su 3 superano la mediana.
- Abbandona un format dopo 6 pubblicazioni che restano sotto la mediana.

## Engagement rate

Calcola l'engagement rate con:

`engagement rate = interazioni totali / copertura × 100`

In questo diario, considera `copertura` uguale a `view` e `interazioni totali` come somma delle metriche interattive disponibili tra invii, salvataggi, commenti, visite profilo, click link e iscritti landing.

## Post 1 · Instagram

[Ogni conto al suo posto. Ogni euro in chiaro.](https://www.instagram.com/p/Df7CraSked_/) · rilevamento 2026-11-20 alle 15:13.

- 35 visualizzazioni, 48,6% da non follower. Provenienza: 22 dalla home e 13 dal profilo.
- 8 mi piace, 8 account che hanno interagito, 0 commenti, 0 salvataggi e 0 condivisioni.
- 4 visite al profilo, 1 tocco sul link esterno e 0 follow.
- Gli Insights mostrano anche 19 con la stessa etichetta «Visualizzazioni», 17 sotto «Interazioni» e 0 sotto «Interazioni con i post». Copertura ed engagement rate da verificare.
