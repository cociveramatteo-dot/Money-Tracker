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

# ============================================================ POST 10 · STATISTICHE
POSTS.append(dict(n=10, slug="saldo-o-netto-del-mese", pal=3, tag="IMPARA",
 slides=[
  (*hook(True, "Statistiche", "Saldo <em>21.973 €.</em> Netto <em>+1.190 €.</em>", "Non sono la stessa cosa. Ecco la differenza.", "v2/stats-light", size=124, ph_w=680, ph_x=340, ph_y=800),),
  concept(False, "Il saldo è <em>il punto d’arrivo</em>", equation([("800 €|a inizio mese", "n"), ("+", "op"), ("150 €|netto del mese", "n"), ("=", "op"), ("950 €|saldo attuale", "res")], top=470, size=92)
          + col('<div style="display:flex;height:70px;border-radius:36px;overflow:hidden;gap:6px"><div style="flex:800;background:var(--line);display:flex;align-items:center;padding-left:28px;font-family:SG;font-size:28px;color:var(--fg)">800 €</div><div style="flex:150;background:var(--hi);display:flex;align-items:center;justify-content:center;font-family:SG;font-size:26px;color:#fff">150</div></div>', 800)
          + col(P("Il netto dice cosa ha aggiunto (o tolto) il mese. Il saldo è il risultato finale.", 40), 940), size=84) + (ES,),
  (*side(True, "Netto = entrate − uscite", "Lo leggi in alto, in Statistiche: Uscite, Entrate e Netto.", "v2/stats-light", badge="1", nxt="Poi l’andamento"), DE),
  (*side(False, "Andamento: <em>6M o 12M</em>", "Le barre mostrano entrate e uscite mese per mese.", "v2/stats-dark", right=False, badge="2"), DE),
  concept(True, "Un mese anomalo <em>sposta la media</em>", bars([("Ago", 900), ("Set", 950), ("Ott", 920), ("Nov", 1900)], hi=[3], top=520, h=290)
          + col('<div style="display:flex;gap:22px"><div class="card" style="flex:1"><div class="lbl" style="font-size:22px">Media con il picco</div><div class="num" style="font-size:58px;margin-top:8px">1.168 €</div></div><div class="card" style="flex:1"><div class="lbl" style="font-size:22px">Senza il picco</div><div class="num" style="font-size:58px;margin-top:8px;color:var(--hi)">923 €</div></div></div>', 1010), size=80) + (ES,),
  (*side(False, "Quanto pesa <em>ogni categoria?</em>", "Ogni barra è una quota delle uscite: parti da quella più grande.", "v2/stats-2-light", badge="3"), DE),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 11 · RICORRENZE
POSTS.append(dict(n=11, slug="ricorrenze-affitto-abbonamenti", pal=3, tag="TUTORIAL",
 slides=[
  (*hook(True, "Ricorrenze", "Scrivile <em>una volta.</em>", "Affitto, bollette, abbonamenti: Bucktrail li mette nei mesi che arrivano.", "old/rules", size=140, ph_w=680, ph_x=340, ph_y=780),),
  (*side(False, "Tutto in una lista", "Ogni serie mostra la prossima data e l’importo.", "old/rules", badge="1", nxt="Come la crei?"), DE),
  (*side(True, "Dal modulo di aggiunta", "Scegli «Ricorrenza»: settimanale, mensile o annuale. Poi salva.", "v2/f-rec-menu-light", badge="2"), DE),
  concept(False, "Modifichi: <em>quanto cambia?</em>", cards([
      ("Solo questa", "Una scadenza diversa, la serie resta com’è."),
      ("Questa e successive", "Dal prossimo rinnovo in poi."),
      ("Tutte", "Cambia l’intera serie.")], top=430, gap=26, h=265), size=88),
  (*duo(True, "L’ambito della modifica", "Solo questa, questa e le successive, oppure tutte.", "v2/r-scope-form-light", "v2/r-scope-menu-light", labels=["Apri la serie","Scegli l’ambito"]), DE),
  (*side(False, "Salta, termina, <em>elimina</em>", "Salta un mese, termina la serie da qui o eliminala.", "old/second-recurrence-actions", badge="3"), DE),
  (*peek(True, "Il mese dopo <em>è già nei conti</em>", "Le scadenze future stanno in «In arrivo»: conferma, ripianifica o elimina.", "v2/mov-light", size=80), ),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 12 · HOME
POSTS.append(dict(n=12, slug="home-su-misura", pal=3, tag="GUIDA",
 slides=[
  (*hook(True, "Home", "Il punto più basso del mese <em>non è a fine mese.</em>", "Stipendio il 27, affitto il 1°: la curva te lo fa vedere prima.", "v2/home-light", size=100, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Leggi <em>la curva</em>", curve(640) + col(P("Prima e dopo la data di un’entrata il saldo cambia: cerca il punto più basso.", 38), 330), size=96) + (ES,),
  (*side(False, "Verde: già successo. <em>Ambra: previsto.</em>", "Il tratto tratteggiato usa i movimenti che hai pianificato.", "v2/home-dark", size=68, nxt="Poi personalizza"), DE),
  (*duo(True, "Scegli cosa vedere", "Ordina i conti in Home e mostra o nascondi i riquadri dei fissi.", "old/second-home-order", "old/second-audit-settings", labels=["Conti in Home","Riquadri fissi"]), DE),
  (*side(False, "Importi <em>al riparo da sguardi</em>", "Tocca l’occhio: gli importi diventano puntini.", "old/second-hidden", right=True, badge="👁"), DE),
  concept(True, "3 modi di <em>personalizzare</em>", steps([
      "Ordina i conti|Gestisci, poi scegli quali mostrare.",
      "Mostra o nascondi i riquadri|Impostazioni → Home.",
      "Oscura gli importi|Con l’occhio in alto."], top=480, gap=50, size=46), size=92),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 13 · IMPOSTAZIONI
POSTS.append(dict(n=13, slug="impostazioni-lingue-tema", pal=4, tag="GUIDA",
 slides=[
  (*hook(True, "Impostazioni", "<em>7 lingue.</em> Un’app sola.", "Lingua, valuta, tema e Face ID: cambi tutto in un minuto.", "v2/b2-settings-light", size=128, ph_w=680, ph_x=340, ph_y=800),),
  concept(False, "Le <em>7 lingue</em> di Bucktrail", chips(["Italiano", "English", "Deutsch", "Español", "Français", "日本語", "简体中文"], top=480)
          + col(steps(["Impostazioni → Lingua|Tocca «Apri Impostazioni iOS».", "Scegli la lingua di Bucktrail|L’app segue la preferenza di sistema."], top=0, gap=34, size=42), 880), size=92),
  (*side(True, "Il simbolo <em>della valuta</em>", "Scegli € o £: cambia il simbolo, non la cifra. Nessuna conversione automatica.", "v2/b2-settings-light", badge="1", size=70, nxt="Poi chiaro o scuro"), DE),
  (*duo(False, "Chiaro o scuro", "Bucktrail segue il tema di iOS: Impostazioni → Schermo e luminosità.", "v2/home-light", "v2/home-dark", labels=["Chiaro","Scuro"]), DE),
  (*side(True, "Avvisi e <em>Face ID</em>", "Avvisi su budget e scadenze, blocco con Face ID, report mensile in PDF.", "v2/b2-settings-2-dark", badge="2", size=74), DE),
  (*side(False, "Vuoi solo <em>provarla?</em>", "«Attiva modalità demo»: dati di esempio. I tuoi restano intatti: spegni l’interruttore e torni a casa.", "v2/b2-settings-3-dark", right=False, size=68), DE),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 14 · DATI
POSTS.append(dict(n=14, slug="esporta-pdf-csv-json", pal=4, tag="TUTORIAL",
 slides=[
  (*hook(True, "Dati", "Tre file. <em>Quale ti serve?</em>", "Report, elenco o profilo completo: li esporti da Bucktrail. Basta Excel da compilare a mano.", "v2/stats-light", size=124, ph_w=680, ph_x=340, ph_y=830, sub_size=38),),
  concept(False, "Tre formati, <em>tre usi</em>", cards([
      ("PDF", "Il report del mese da Statistiche, pronto da condividere."),
      ("CSV", "L’elenco dei movimenti, per Excel o Numbers."),
      ("JSON", "L’intero profilo: conti, budget e movimenti in un file.")], top=430, gap=26, h=265), size=92),
  (*side(False, "PDF dal mese", "In Statistiche tocca PDF: anteprima e condivisione.", "v2/stats-dark", badge="1", nxt="Poi CSV e JSON"), DE),
  (*side(True, "<em>CSV</em> e <em>JSON</em>", "«Genera CSV» per i movimenti, «Esporta tutti i dati» per il profilo.", "v2/b2-settings-2-light", right=True, badge="2"), DE),
  (*duo(False, "Ritrova le <em>modifiche</em>", "La cronologia modifiche, in Impostazioni, ricorda cosa è stato fatto.", "old/second-audit-settings", "old/second-audit-log", labels=["Impostazioni","Cronologia"]), DE),
  final(True, "v2/home-light"),
 ]))

# ============================================================ POST 15 · COMANDI RAPIDI
POSTS.append(dict(n=15, slug="spesa-con-doppio-tocco", pal=4, tag="TUTORIAL",
 slides=[
  (*hook(True, "Comandi rapidi", "Due tocchi. <em>Spesa salvata.</em>", "Sul retro dell’iPhone, senza cercare l’app.", "v2/add-empty-light", size=124, ph_w=680, ph_x=340, ph_y=800),),
  (*side(False, "1. Parti da <em>Impostazioni</em>", "Sotto «Siri e Shortcut» trovi «Apri Shortcut»: lì crei il comando «Aggiungi spesa».", "old/settings-shortcuts", right=True, size=66, nxt="Poi assegnalo al retro"), DE),
  concept(True, "2. Assegnalo <em>al retro</em>", steps([
      "Impostazioni → Accessibilità|Poi Tocco → Tocco posteriore.",
      "Scegli «Tocco doppio»|Seleziona il comando creato.",
      "Prova: due tocchi sul retro|Tocco posteriore: iPhone 8 e successivi."], top=480, gap=50, size=46), size=90),
  (*side(False, "Inserisci <em>nome e importo</em>", "Si apre il modulo di Bucktrail: scrivi e salva.", "v2/add-filled-light", right=False, badge="3"), DE),
  (*side(True, "Ritrovala in <em>Movimenti</em>", "La spesa è già nella lista, con la sua categoria.", "v2/mov-light", badge="4"), DE),
  concept(False, "Registra subito, <em>ricorda meglio</em>", cards([
      ("Due campi", "Nome e importo: il resto lo propone Bucktrail."),
      ("Categoria", "«Ultima usata»: la suggerisce dalla seconda volta."),
      ("Budget e saldo", "La nuova spesa entra subito nei tuoi conti.")], top=430, gap=26, h=215)
      + col(tease("Salva il tutorial per dopo"), 1190), size=84),
  final(True, "v2/home-light"),
 ]))
