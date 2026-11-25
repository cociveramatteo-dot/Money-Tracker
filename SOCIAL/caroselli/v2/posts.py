from layouts import *
DE = "Dati di esempio"
ES = "Esempio illustrativo"

POSTS = []

# ============================================================ POST 5 · BUDGET
POSTS.append(dict(n=5, slug="budget-mangiare-fuori", pal=1, tag="IMPARA",
 slides=[
  (*hook(True, "Budget", "Quanto spendi <em>per mangiare fuori?</em>", "Scoprilo prima. Poi scegli un tetto che riesci a rispettare davvero.", "v2/budget-light", size=116, ph_w=680, ph_x=340, ph_y=760),),
  concept(False, "Parti dalla tua media, <em>non da un numero a caso.</em>", bars([("Set", 160), ("Ott", 190), ("Nov", 175)], top=520, h=330)
          + col('<div class="card" style="display:flex;justify-content:space-between;align-items:center"><div><div class="lbl">Media mensile</div></div><div class="num" style="font-size:80px;color:var(--hi)">175 €</div></div>', 990)
          + col(tease("Ora scegli il tetto"), 1160), size=84) + (ES,),
  (*side(True, "Apri <em>Pianifica</em>, tocca +", "Nuovo budget: scegli la categoria da tenere sotto controllo.", "v2/budget-form-light", badge="1", nxt="Poi scegli il limite"), DE),
  (*duo(True, "Categoria e limite", "Esempio: Cibo con 150 €, un po’ meno della media.", "v2/d-budget-cibo-light", "v2/d-budget-150-light", labels=["Categoria Cibo","Limite 150 €"]), DE),
  (*peek(True, "La barra lavora <em>per te</em>", "Verde finché sei tranquillo, avviso all’80%, rosso se sfori.", "v2/budget-light", size=88),),
  concept(False, "Leggi la barra <em>prima di ordinare</em>", cards([
      ("Sotto l’80%", "Sei tranquillo: puoi uscire senza pensieri.", "Verde"),
      ("Soglia 80%", "Hai usato quasi tutto: rallenta per il resto del mese.", "Ambra"),
      ("Sforato", "Hai superato il limite. Lo vedi subito, con quanto sei oltre.", "Rosso")], top=470, gap=22, h=235), size=84),
  concept(True, "Fine mese: <em>3 domande</em>", steps([
      "Sono rimasto nel limite?|Controlla la barra Cibo in Pianifica.",
      "Il netto del mese è positivo?|Lo leggi in Statistiche.",
      "Cosa cambio il mese dopo?|Tieni premuto sul budget per modificarlo o eliminarlo."], top=470), size=92),
  final(True, "v2/home-light"),
 ]))

def DEF(): return DE

# ============================================================ POST 6 · OBIETTIVI
POSTS.append(dict(n=6, slug="obiettivi-spesa-annuale", pal=1, tag="IMPARA",
 slides=[
  (*hook(True, "Obiettivi", "480 € <em>tra 12 mesi.</em>", "L’assicurazione auto arriva una volta l’anno. Preparati un mese alla volta.", "v2/c3-goal-list-light", size=124, ph_w=680, ph_x=340, ph_y=800),),
  concept(False, "12 mesi × 40 € = <em>480&nbsp;€</em>", grid12(470) + col(tease("Ora crealo in Bucktrail"), 1150), size=92) + (ES,),
  (*side(True, "Crea l’obiettivo", "Nome, importo e, se vuoi, una data di scadenza.", "v2/c3-goal-filled-light", badge="1", nxt="Poi guarda la barra"), DE),
  (*side(False, "Guarda <em>la barra</em> riempirsi", "Ogni obiettivo mostra quanto hai già messo da parte.", "v2/c3-goal-list-dark", right=False, badge="2"), DE),
  concept(True, "Dopo 3 mesi: <em>120 €</em> su 480 €", progress(25, "120 € accantonati", "360 € mancano", top=560, big="25%")
          + col(P("L’importo si aggiorna a mano: aggiungi quanto accantoni, quando vuoi.", 38), 1040), size=88) + (ES,),
  (*side(False, "Aggiorna quando <em>accantoni</em>", "Tocca + sull’obiettivo e aggiungi quanto accantoni: la barra si aggiorna.", "v2/g-after-0-light", badge="3"), DE),
  concept(True, "Budget o obiettivo? <em>Due domande diverse.</em>", cards([
      ("Budget", "Quanto posso spendere in questa categoria?", "Limite"),
      ("Obiettivo", "Quanto voglio mettere da parte per qualcosa?", "Traguardo")], top=470, gap=30, h=300)
      + col(tease("Salva il post: ti servirà a fine mese"), 1130), size=80),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 7 · MOVIMENTI
POSTS.append(dict(n=7, slug="trova-un-movimento", pal=2, tag="TUTORIAL",
 slides=[
  (*hook(True, "Movimenti", "Quella spesa da <em>40 €:</em> dov’è finita?", "Cerca, filtra, ritrova. In tre tocchi.", "v2/mov-light", size=118, ph_w=680, ph_x=340, ph_y=800),),
  (*side(False, "Giorno per giorno, <em>in ordine</em>", "In alto «In arrivo», poi ogni giorno con il suo subtotale.", "v2/mov-dark"), DE),
  (*side(True, "Cerca per nome", "Scrivi «Farmacia»: restano solo le spese giuste.", "v2/b2-search-light", badge="1", nxt="Poi mese e categoria"), DE),
  (*duo(False, "Mese e categoria", "Tocca «Categoria», scegli: la lista si restringe.", "v2/e-cat-menu-light", "v2/e-cat-result-light", labels=["Scegli","Risultato"]), DE),
  (*duo(True, "Importo da… a…", "Intervallo di importo: da 40 a 45 €.", "old/second-filters-detail", "old/second-filter-result", labels=["Imposta","Risultato"]), DE),
  concept(False, "Le piccole spese <em>pesano</em>", bars([("Sett. 1", 12), ("Sett. 2", 14), ("Sett. 3", 11), ("Sett. 4", 11)], top=520, h=300)
          + col('<div class="card" style="display:flex;justify-content:space-between;align-items:center"><div class="lbl">Totale del mese</div><div class="num" style="font-size:76px;color:var(--hi)">48 €</div></div>', 1010)
          + col(P("Filtra per categoria e leggi il totale.", 36), 1160), size=84) + (ES,),
  (*side(True, "La categoria? <em>Ultima usata</em>", "Dalla seconda volta Bucktrail ti suggerisce quella giusta. Cambiala quando vuoi.", "v2/add-filled-light"), DE),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 8 · CONTI
POSTS.append(dict(n=8, slug="conti-escludi-archivia", pal=2, tag="TUTORIAL",
 slides=[
  (*hook(True, "Conti", "Contanti, carta, banca: <em>tutto nello stesso posto.</em>", "Aggiungi un conto in due passi e tieni in ordine il patrimonio.", "v2/b2-account-list-light", size=102, ph_w=680, ph_x=340, ph_y=800),),
  (*side(False, "Patrimonio <em>a colpo d’occhio</em>", "La somma dei conti inclusi, con i gruppi sotto.", "v2/accounts-dark", nxt="Ora aggiungi un conto"), DE),
  (*duo(True, "Nuovo conto in 2 passi", "Scegli il tipo, poi nome e saldo.", "v2/account-form-light", "v2/b2-account-85-light", labels=["Tipo","Nome e saldo"]), DE),
  (*side(False, "Eccolo <em>nell’elenco</em>", "Portafoglio da 85 €, già dentro il patrimonio.", "v2/b2-account-list-dark", right=True), DE),
  concept(True, "Tre azioni, <em>tre effetti</em>", cards([
      ("Escludi", "Resta in elenco, ma non conta nel patrimonio totale."),
      ("Archivia", "Esce dall’elenco e va in «Archiviati»."),
      ("Ripristina", "Torna tra i conti attivi, quando ti serve di nuovo.")], top=430, gap=26, h=265), size=88),
  (*duo(False, "Escluso e archiviato", "Li riconosci subito: etichetta «Escluso dal totale» e sezione «Archiviati».", "old/S8-excluded-XL", "old/S8-archived-expanded-XL", labels=["Escluso","Archiviati"]), DE),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 9 · RICONCILIAZIONE E TRASFERIMENTI
POSTS.append(dict(n=9, slug="riconcilia-e-trasferimenti", pal=2, tag="IMPARA",
 slides=[
  (lambda r: (r[0], r[1] + col(lbl("Il saldo non torna?"), 150, 84, 450), "Dati di esempio"))(side(True, "App: <em>13.120 €.</em> Banca: <em>13.099 €.</em>", "Una differenza di 21 €. Come la trovi, come la sistemi.", "v2/accounts-light", size=72, scorri=True)),
  concept(False, "Prima confronta, <em>poi correggi</em>", steps([
      "Apri l’estratto conto|Leggi il saldo reale.",
      "Confrontalo con Bucktrail|Cerca il movimento mancante.",
      "Non lo trovi? Modifica il saldo|Bucktrail registra la differenza."], top=480, gap=46, size=44), size=92),
  (*duo(True, "Modifica il saldo", "Apri il conto, scrivi il saldo reale e salva.", "old/second-reconcile", "old/second-reconcile-filled", labels=["Saldo attuale","Saldo reale"]), DE),
  (*side(False, "La rettifica <em>resta tracciata</em>", "La ritrovi in Movimenti: la differenza è una riga, non un mistero.", "old/second-reconciled", badge="✓"), DE),
  concept(True, "Spostare soldi <em>non cambia il patrimonio</em>", before_after(520), size=76) + (ES,),
  (*duo(False, "Trasferisci o programma", "Scegli da quale conto a quale, importo e se è già fatto.", "v2/transfer-light", "old/second-transfer-planned", labels=["Da → A","Già fatto?"]), DE),
  (*side(True, "Due voci, <em>un solo giro</em>", "Il trasferimento crea due movimenti collegati: uscita da un conto, entrata nell’altro.", "old/transfer-list"), DE),
  final(True, "v2/home-light"),
 ]))

# Post 10-24: serie «problema prima» in posts_s.py
from posts_s import NEW
POSTS.extend(NEW)
