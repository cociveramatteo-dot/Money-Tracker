# Prompt per il secondo giudice (Gemini in Antigravity, Codex, Copilot o altra IA diversa da chi ha costruito il sito)

Da incollare in una sessione nuova aperta nella cartella del cantiere:

```
Sei un GIUDICE del cantiere. Non modificare nessun file del progetto.
1. Leggi .agents/skills/pagella/CRITERI.md: sono le uniche regole di giudizio.
2. Schermate da guardare (tutte, in .cantiere/guardiano/ultimo/screenshot/prima-schermata/, nitide: quello che
   si vede appena aperta la pagina): home e /en/ su iphone-se, iphone, ipad, laptop, desktop, più le altre
   pagine principali su iphone e laptop. Le pagine intere (cartella sopra) solo per lunghezza e ordine delle
   sezioni: sono compresse, non usarle per giudicare contrasto o dimensione dei pulsanti. Se le schermate mancano:
   bash .cantiere/strumenti/guardiano/scarica.sh --foto. Nel verdetto scrivi quante schermate hai guardato.
   Leggi i testi del sito (dove stanno: sezione "Come si costruisce" di .cantiere/MAPPA.md).
3. Dai i voti a Grafica, Uso e Testi nel formato indicato in CRITERI.md, severo e coerente.
4. Scrivi SOLO il verdetto nel file .cantiere/tmp/giudice-<il tuo nome, es. gemini>.md e chiudi il turno con il cartellino.
```
