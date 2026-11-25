"""Serie «problema prima» (dal 25/11/2026): post 10–24. Slide 1 = situazione con un numero, poi soluzione con l'app,
slide «Da salvare», chiusura. Palette: 3 (prugna 10–12) · 4 (petrolio 13–15) · 6 fucsia (16–18) · 7 ocra (19–21) · 8 lime (22–24)."""
from layouts import *
DE = "Dati di esempio"
ES = "Esempio illustrativo"
NEW = []


def save(title, inner, dark=True, tail=None, size=80):
    """Slide «Da salvare»: etichetta + titolo + schema riassuntivo (+ invito a mandarlo a qualcuno)."""
    d, h = concept(dark, title, inner, size=size, top=235)
    h = col(lbl("Da salvare"), 172) + h
    if tail:
        h += col(tease(tail), 1190)
    return d, h


# ============================================================ POST 10 · SALDO O NETTO (prugna)
NEW.append(dict(n=10, slug="saldo-o-netto-del-mese", pal=3, tag="IMPARA", slides=[
  (*hook(True, "Statistiche", "+150&nbsp;€ sul conto. <em>Hai risparmiato davvero?</em>", "Saldo e netto non sono la stessa cosa. Ecco la differenza.", "v2/stats-light", size=104, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Il saldo è <em>il punto d’arrivo</em>", equation([("800&nbsp;€|a inizio mese", "n"), ("+", "op"), ("150&nbsp;€|netto del mese", "n"), ("=", "op"), ("950&nbsp;€|saldo attuale", "res")], top=470, size=92)
          + col('<div style="display:flex;height:70px;border-radius:36px;overflow:hidden;gap:6px"><div style="flex:800;background:var(--line);display:flex;align-items:center;padding-left:28px;font-family:SG;font-size:28px;color:var(--fg)">800&nbsp;€</div><div style="flex:150;background:var(--hi);display:flex;align-items:center;justify-content:center;font-family:SG;font-size:26px;color:#fff">150</div></div>', 800)
          + col(P("Il netto dice cosa ha aggiunto (o tolto) il mese. Il saldo è il risultato finale.", 40), 940), size=84) + (ES,),
  (*side(True, "Netto = entrate − uscite", "Lo leggi in alto, in Statistiche: Uscite, Entrate e Netto.", "v2/stats-light", badge="1", nxt="Poi l’andamento"), DE),
  (*side(False, "Andamento: <em>6M o 12M</em>", "Le barre mostrano entrate e uscite mese per mese.", "v2/stats-dark", right=False, badge="2"), DE),
  concept(True, "Un mese anomalo <em>sposta la media</em>", bars([("Ago", 900), ("Set", 950), ("Ott", 920), ("Nov", 1900)], hi=[3], top=520, h=290)
          + col('<div style="display:flex;gap:22px"><div class="card" style="flex:1"><div class="lbl" style="font-size:22px">Media con il picco</div><div class="num" style="font-size:58px;margin-top:8px">1.168&nbsp;€</div></div><div class="card" style="flex:1"><div class="lbl" style="font-size:22px">Senza il picco</div><div class="num" style="font-size:58px;margin-top:8px;color:var(--hi)">923&nbsp;€</div></div></div>', 1010), size=80) + (ES,),
  (*side(False, "Quanto pesa <em>ogni categoria?</em>", "Ogni barra è una quota delle uscite: parti da quella più grande.", "v2/stats-2-light", badge="3"), DE),
  save("Saldo o netto? <em>Ricordalo così</em>", cards([
      ("Saldo", "Quanto hai adesso: il punto d’arrivo.", "Dove sei"),
      ("Netto", "Entrate − uscite del mese: cosa ha aggiunto o tolto.", "Come è andato"),
      ("Mese anomalo", "Guarda la media senza il picco prima di giudicare.", "Attenzione")], top=520, gap=22, h=215), tail="Mandalo a chi controlla solo il saldo"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 11 · FISSI E RICORRENZE (prugna)
NEW.append(dict(n=11, slug="ricorrenze-affitto-abbonamenti", pal=3, tag="IMPARA", slides=[
  (*hook(True, "Spese fisse", "<em>841&nbsp;€</em> escono prima che tu spenda.", "Affitto, streaming, palestra: scrivili una volta e non pensarci più.", "old/rules", size=112, ph_w=680, ph_x=340, ph_y=800),),
  concept(False, "I fissi <em>non li vedi,</em> ma ci sono", equation([("780&nbsp;€|affitto", "n"), ("+", "op"), ("16&nbsp;€|streaming", "n"), ("+", "op"), ("45&nbsp;€|palestra", "n")], top=470, size=76)
          + col('<div class="card" style="display:flex;justify-content:space-between;align-items:center"><div class="lbl">Ogni mese, già spesi</div><div class="num" style="font-size:84px;color:var(--hi)">≈ 841&nbsp;€</div></div>', 800)
          + col(tease("Poi: come non dimenticarli"), 1010), size=84) + (ES,),
  (*side(False, "Tutto in una lista", "Ogni serie mostra la prossima data e l’importo.", "old/rules", badge="1", nxt="Come la crei?"), DE),
  (*side(True, "Dal modulo di aggiunta", "Scegli «Ricorrenza»: settimanale, mensile o annuale. Poi salva.", "v2/f-rec-menu-light", badge="2"), DE),
  concept(False, "Modifichi: <em>quanto cambia?</em>", cards([
      ("Solo questa", "Una scadenza diversa, la serie resta com’è."),
      ("Questa e successive", "Dal prossimo rinnovo in poi."),
      ("Tutte", "Cambia l’intera serie.")], top=430, gap=26, h=265), size=88),
  (*duo(True, "L’ambito della modifica", "Solo questa, questa e le successive, oppure tutte.", "v2/r-scope-form-light", "v2/r-scope-menu-light", labels=["Apri la serie","Scegli l’ambito"]), DE),
  save("I fissi <em>in 3 mosse</em>", steps([
      "Elenca i fissi|Affitto, bollette, abbonamenti.",
      "Sommali|Quello che esce prima che tu spenda.",
      "Scrivili una volta|Ricorrenza: poi li trovi in «In arrivo»."], top=520, gap=40, size=44), tail="Mandalo a chi scorda le scadenze"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 12 · CURVA DELLA HOME (prugna)
NEW.append(dict(n=12, slug="home-su-misura", pal=3, tag="IMPARA", slides=[
  (*hook(True, "Home", "Stipendio il 27, affitto il 1°: <em>quando tocchi il minimo?</em>", "La curva della Home te lo fa vedere prima.", "v2/home-light", size=96, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Leggi <em>la curva</em>", curve(640) + col(P("Prima e dopo la data di un’entrata il saldo cambia: cerca il punto più basso.", 38), 330), size=96) + (ES,),
  (*side(False, "Verde: già successo. <em>Ambra: previsto.</em>", "Il tratto tratteggiato usa i movimenti che hai pianificato.", "v2/home-dark", size=68, nxt="Poi personalizza"), DE),
  (*duo(True, "Scegli cosa vedere", "Ordina i conti in Home e mostra o nascondi i riquadri dei fissi.", "old/second-home-order", "old/second-audit-settings", labels=["Conti in Home","Riquadri fissi"]), DE),
  (*side(False, "Importi <em>al riparo da sguardi</em>", "Tocca l’occhio: gli importi diventano puntini.", "old/second-hidden", right=True, badge="👁"), DE),
  save("La curva <em>in 3 domande</em>", steps([
      "Dov’è il punto più basso?|Cerca la discesa più marcata.",
      "Quando arriva lo stipendio?|Se è dopo, aspetta a spendere.",
      "Cosa può aspettare?|Rimanda una spesa non urgente."], top=520, gap=40, size=44), tail="Mandalo a chi finisce lo stipendio il 20"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 13 · 50/30/20 (petrolio)
NEW.append(dict(n=13, slug="regola-50-30-20", pal=4, tag="IMPARA", slides=[
  (*hook(True, "Budget", "1.200&nbsp;€ al mese. <em>Quanti per uscire?</em>", "Una regola semplice per dividerli, senza fogli di calcolo.", "v2/budget-light", size=112, ph_w=680, ph_x=340, ph_y=800),),
  concept(False, "Prima i bisogni, <em>poi il resto</em>", cards([
      ("50% · Necessità", "Affitto, bollette, spesa, trasporti.", "Servono"),
      ("30% · Desideri", "Uscire, hobby, shopping.", "Piacciono"),
      ("20% · Risparmio", "Obiettivi e imprevisti.", "Costruiscono")], top=470, gap=22, h=215)
      + col(tease("Poi: la cifra che cercavi"), 1190), size=84) + ("Regola indicativa: adattala alla tua situazione",),
  concept(True, "1.200&nbsp;€ <em>in tre parti</em>", equation([("600&nbsp;€|necessità", "n"), ("+", "op"), ("360&nbsp;€|desideri", "n"), ("+", "op"), ("240&nbsp;€|risparmio", "res")], top=520, size=84)
          + col(P("Per uscire ne hai <b>360&nbsp;€</b> al mese: circa 12&nbsp;€ al giorno.", 42), 860), size=88) + (ES,),
  (*side(False, "Il 30% è <em>un budget</em>", "In Pianifica tocca +: scegli la categoria (es. Svago) e il limite di 360&nbsp;€.", "v2/budget-form-light", badge="1", nxt="Poi il risparmio"), DE),
  (*side(True, "Il 20% è <em>un obiettivo</em>", "Metti da parte 240&nbsp;€ al mese su un obiettivo e guarda la barra riempirsi.", "v2/c3-goal-list-light", badge="2"), DE),
  (*peek(True, "Controlla la barra <em>prima di uscire</em>", "Verde se sei tranquillo, avviso all’80%, rosso se sfori.", "v2/budget-light", size=84),),
  save("50 / 30 / 20 <em>su 1.200&nbsp;€</em>", cards([
      ("600&nbsp;€", "Necessità (50%)"), ("360&nbsp;€", "Desideri (30%)"), ("240&nbsp;€", "Risparmio (20%)")], top=520, gap=22, h=170),
       tail="Mandalo a chi non sa quanto può spendere") + ("Regola indicativa: cambia le percentuali in base alla tua vita",),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 14 · FONDO EMERGENZA (petrolio)
NEW.append(dict(n=14, slug="fondo-emergenza", pal=4, tag="IMPARA", slides=[
  (*hook(True, "Obiettivi", "Spese 900&nbsp;€ al mese. <em>Quanti mesi reggi</em> se si ferma tutto?", "Un imprevisto non avvisa. Il calcolo per prepararti.", "v2/c3-goal-list-light", size=96, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Parti da <em>quanto spendi,</em> non da quanto guadagni", equation([("900&nbsp;€|spese al mese", "n"), ("×", "op"), ("3|mesi di scorta", "n"), ("=", "op"), ("2.700&nbsp;€|il traguardo", "res")], top=520, size=84)
          + col(tease("Poi: come arrivarci"), 900), size=78) + (ES,),
  concept(True, "100&nbsp;€ al mese? <em>27 mesi.</em> 300&nbsp;€? <em>9.</em>", bars([("100&nbsp;€/mese", 27), ("200&nbsp;€/mese", 14), ("300&nbsp;€/mese", 9)], hi=[2], top=520, h=330, unit="mesi")
          + col(P("Il tempo cambia in fretta con pochi euro in più.", 38), 1010), size=76) + ("Esempio illustrativo: 2.700&nbsp;€ di traguardo",),
  (*side(False, "Crea <em>l’obiettivo</em>", "Nome, importo e, se vuoi, una scadenza: per esempio «Fondo emergenza».", "v2/c3-goal-filled-light", badge="1", nxt="Poi versa ogni mese"), DE),
  (*side(True, "Versa <em>quando puoi</em>", "Tocca + sull’obiettivo e aggiungi quanto accantoni: la barra si aggiorna.", "v2/g-after-0-light", badge="2"), DE),
  save("Il tuo fondo <em>in 3 passi</em>", steps([
      "Spese mensili × 3|Il traguardo minimo da cui partire.",
      "Scegli una cifra mensile|Anche piccola, ma costante.",
      "Crea l’obiettivo|E aggiorna la barra ogni mese."], top=520, gap=40, size=44), tail="Mandalo a chi vive di imprevisti"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 15 · DOPPIO TOCCO (petrolio)
NEW.append(dict(n=15, slug="spesa-con-doppio-tocco", pal=4, tag="TUTORIAL", slides=[
  (*hook(True, "Comandi rapidi", "Ieri hai speso 8,50&nbsp;€. <em>Te lo ricordi?</em>", "Due tocchi sul retro dell’iPhone e la spesa è salvata.", "v2/add-empty-light", size=112, ph_w=680, ph_x=340, ph_y=800),),
  (*side(False, "1. Parti da <em>Impostazioni</em>", "Sotto «Siri e Shortcut» trovi «Apri Shortcut»: lì crei il comando «Aggiungi spesa».", "old/settings-shortcuts", right=True, size=66, nxt="Poi assegnalo al retro"), DE),
  concept(True, "2. Assegnalo <em>al retro</em>", steps([
      "Impostazioni → Accessibilità|Poi Tocco → Tocco posteriore.",
      "Scegli «Tocco doppio»|Seleziona il comando creato.",
      "Prova: due tocchi sul retro|Tocco posteriore: iPhone 8 e successivi."], top=480, gap=50, size=46), size=90),
  (*side(False, "Inserisci <em>nome e importo</em>", "Si apre il modulo di Bucktrail: scrivi e salva.", "v2/add-filled-light", right=False, badge="3"), DE),
  (*side(True, "Ritrovala in <em>Movimenti</em>", "La spesa è già nella lista, con la sua categoria.", "v2/mov-light", badge="4"), DE),
  save("Il comando <em>in 3 mosse</em>", steps([
      "Crea «Aggiungi spesa»|In Comandi, con nome e importo.",
      "Tocco posteriore → Tocco doppio|Impostazioni → Accessibilità.",
      "Due tocchi, scrivi, salva|La spesa entra subito nei conti."], top=520, gap=40, size=44), tail="Salva il tutorial per dopo"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 16 · STIPENDIO FINITO IL 20 (fucsia)
NEW.append(dict(n=16, slug="stipendio-finito-il-20", pal=6, tag="IMPARA", slides=[
  (*hook(True, "Stipendio", "1.100&nbsp;€ al mese. <em>Il&nbsp;20 sei già a zero.</em>", "Succede quando i fissi li scopri dopo. Come invertire l’ordine.", "v2/home-light", size=104, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Prima escono <em>i fissi</em>", bars([("Affitto", 450), ("Spesa", 250), ("Bollette e abb.", 120), ("Resto", 280)], hi=[3], top=520, h=330)
          + col(tease("Poi: il numero che conta"), 1130), size=88) + (ES,),
  concept(True, "Quel che resta, <em>al giorno</em>", equation([("280&nbsp;€|resto del mese", "n"), ("÷", "op"), ("30|giorni", "n"), ("=", "op"), ("≈ 9&nbsp;€|al giorno", "res")], top=520, size=84)
          + col(P("Con 9&nbsp;€ al giorno una pizza fuori è già un’eccezione. Meglio saperlo prima.", 40), 880), size=88) + (ES,),
  (*side(False, "Scrivi i fissi <em>una volta sola</em>", "Affitto, bollette e abbonamenti come ricorrenze: non li dimentichi più.", "old/rules", badge="1", nxt="Poi guarda la curva"), DE),
  (*side(True, "La Home mostra <em>il resto del mese</em>", "La curva usa i movimenti pianificati: vedi il saldo previsto a fine mese.", "v2/home-light", badge="2"), DE),
  (*peek(False, "Metti un tetto <em>al resto</em>", "Un budget per categoria: la barra ti avvisa all’80%.", "v2/budget-light", size=84),),
  save("Quanto puoi spendere? <em>La formula</em>", steps([
      "Stipendio − fissi|Quello che resta davvero.",
      "Dividi per i giorni del mese|Il tuo budget giornaliero.",
      "Controlla la curva|Prima di uscire, non dopo."], top=520, gap=40, size=44), tail="Mandalo a chi finisce lo stipendio il 20"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 17 · ABBONAMENTI (fucsia)
NEW.append(dict(n=17, slug="abbonamenti-dimenticati", pal=6, tag="IMPARA", slides=[
  (*hook(True, "Abbonamenti", "<em>87&nbsp;€</em> al mese. <em>1.044&nbsp;€</em> l’anno. Li usi tutti?", "Gli abbonamenti dimenticati costano in silenzio.", "old/rules", size=100, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Ne hai <em>più di quanti pensi</em>", cards([
      ("Palestra", "50&nbsp;€ al mese"), ("Streaming video", "13&nbsp;€ al mese"), ("Musica", "11&nbsp;€ al mese"), ("App allenamento", "10&nbsp;€ al mese"), ("Cloud", "3&nbsp;€ al mese"),
      ("Totale", "87&nbsp;€ al mese")], top=470, cols=2, gap=22, h=190), size=84) + (ES,),
  concept(True, "Piccole cifre, <em>grande somma</em>", equation([("87&nbsp;€|al mese", "n"), ("×", "op"), ("12|mesi", "n"), ("=", "op"), ("1.044&nbsp;€|l’anno", "res")], top=520, size=84)
          + col(tease("Poi: come fare pulizia"), 880), size=88) + (ES,),
  (*side(False, "Tutti in <em>una lista</em>", "Ogni abbonamento mostra la prossima data e l’importo.", "old/rules", badge="1", nxt="Poi chi non usi più"), DE),
  (*side(True, "Non lo usi? <em>Termina</em>", "Salta un mese, termina la serie da qui o eliminala.", "old/second-recurrence-actions", badge="2"), DE),
  (*peek(False, "La spesa futura <em>è già visibile</em>", "In «In arrivo» vedi cosa pagherai nei prossimi giorni.", "v2/mov-light", size=84),),
  save("Pulizia abbonamenti <em>in 3 passi</em>", steps([
      "Elencali tutti|Guarda gli ultimi 3 mesi di estratto conto.",
      "Chiediti: l’ho usato questo mese?|Se no, è un candidato.",
      "Terminalo|E nota quanto risparmi all’anno."], top=520, gap=40, size=44), tail="Mandalo a chi ha troppi abbonamenti"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 18 · SPESE PICCOLE (fucsia)
NEW.append(dict(n=18, slug="aperitivo-3-volte-a-settimana", pal=6, tag="IMPARA", slides=[
  (*hook(True, "Spese piccole", "Aperitivo 12&nbsp;€ × 3 a settimana = <em>?</em>", "Il totale dell’anno ti sorprenderà.", "v2/mov-light", size=100, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Sembra <em>poco</em>", equation([("12&nbsp;€|un aperitivo", "n"), ("×", "op"), ("3|a settimana", "n"), ("=", "op"), ("36&nbsp;€|a settimana", "res")], top=520, size=84)
          + col(tease("Poi: la moltiplicazione"), 880), size=96) + (ES,),
  concept(True, "In un anno: <em>1.872&nbsp;€</em>", equation([("36&nbsp;€|a settimana", "n"), ("×", "op"), ("52|settimane", "n"), ("=", "op"), ("1.872&nbsp;€|l’anno", "res")], top=520, size=80), size=96) + (ES,),
  (*side(False, "Ritrovale <em>con la ricerca</em>", "Scrivi il nome: restano solo le spese giuste.", "v2/b2-search-light", badge="1", nxt="Poi filtra"), DE),
  (*duo(True, "Mese e categoria", "Tocca «Categoria», scegli: la lista si restringe.", "v2/e-cat-menu-light", "v2/e-cat-result-light", labels=["Scegli","Risultato"]), DE),
  (*side(False, "Quanto pesa <em>la categoria?</em>", "Le barre mostrano la quota di ogni categoria sulle uscite.", "v2/stats-2-light", badge="2"), DE),
  save("Il conto delle piccole spese <em>in 3 mosse</em>", steps([
      "Importo × volte a settimana|Quanto spendi ogni settimana.",
      "× 52|Il costo di un anno intero.",
      "Decidi: ne vale la pena?|Anche solo una volta in meno conta."], top=560, gap=40, size=44), tail="Mandalo a chi non sa dove vanno i soldi", size=72),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 19 · TREDICESIMA (ocra)
NEW.append(dict(n=19, slug="tredicesima-prima-che-sparisca", pal=7, tag="IMPARA", slides=[
  (*hook(True, "Tredicesima", "Tredicesima <em>1.400&nbsp;€.</em> Dove sono a gennaio?", "Decidi prima dove vanno, prima che spariscano.", "v2/c3-goal-list-light", size=104, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Dividi <em>1.400&nbsp;€</em> prima di toccarli", bars([("Regali e viaggi", 400), ("Spese annuali", 300), ("Obiettivo", 700)], hi=[2], top=520, h=330)
          + col(tease("Poi: dove metterli"), 1130), size=84) + (ES,),
  (*side(True, "Un obiettivo <em>per ogni parte</em>", "Nome, importo e, se vuoi, una scadenza.", "v2/c3-goal-filled-light", badge="1", nxt="Poi versa subito"), DE),
  (*side(False, "Versa <em>appena arriva</em>", "Tocca + sull’obiettivo e aggiungi quanto accantoni.", "v2/g-after-0-light", badge="2"), DE),
  (*side(True, "Una barra <em>per ogni scopo</em>", "Vedi a colpo d’occhio quanto manca a ogni traguardo.", "v2/c3-goal-list-dark", badge="3"), DE),
  save("La tredicesima <em>in 3 mosse</em>", steps([
      "Elenca cosa ti aspetta|Regali, assicurazione, bollo.",
      "Assegna una cifra a ognuno|Prima di spendere.",
      "Crea un obiettivo e versa subito|Così non si confonde col resto."], top=520, gap=40, size=44), tail="Mandalo a chi riceve la tredicesima"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 20 · REGALI DI NATALE (ocra)
NEW.append(dict(n=20, slug="regali-di-natale", pal=7, tag="IMPARA", slides=[
  (*hook(True, "Regali", "Regali di Natale: <em>300&nbsp;€.</em> Da dove li togli?", "Se non decidi il tetto, lo decide l’ultimo giorno.", "v2/budget-form-light", size=104, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Parti dal <em>tetto,</em> non dal regalo", equation([("300&nbsp;€|tetto totale", "n"), ("÷", "op"), ("6|persone", "n"), ("=", "op"), ("50&nbsp;€|a testa", "res")], top=520, size=84)
          + col(tease("Poi: come tenerlo"), 880), size=92) + (ES,),
  (*side(True, "Crea il <em>budget Regali</em>", "In Pianifica tocca +: categoria e limite, per esempio 300&nbsp;€.", "v2/budget-form-light", badge="1", nxt="Poi guarda la barra"), DE),
  (*side(False, "La barra <em>ti avvisa</em>", "Verde finché sei tranquillo, avviso all’80%, rosso se sfori.", "v2/budget-light", badge="2"), DE),
  concept(True, "Prima di comprare, <em>una domanda</em>", cards([
      ("Quanto è rimasto?", "Guarda la barra del budget Regali."),
      ("Quanto manca ai prossimi?", "Dividi il resto per le persone rimaste.")], top=470, gap=26, h=260), size=84),
  save("Regali senza sorprese <em>a gennaio</em>", steps([
      "Fissa il tetto|Un numero solo, per tutti.",
      "Dividilo per persona|Sai quanto spendere per ognuno.",
      "Registra ogni acquisto subito|La barra resta vera."], top=520, gap=40, size=44), tail="Mandalo a chi fa troppi regali"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 21 · AFFITTO SU STIPENDIO (ocra)
NEW.append(dict(n=21, slug="affitto-su-stipendio", pal=7, tag="IMPARA", slides=[
  (*hook(True, "Affitto", "Affitto <em>450&nbsp;€</em> su 1.100&nbsp;€ di stipendio. È troppo?", "Il calcolo in 10 secondi.", "v2/stats-2-light", size=100, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Quanto pesa <em>davvero</em>", equation([("450&nbsp;€|affitto", "n"), ("÷", "op"), ("1.100&nbsp;€|stipendio", "n"), ("=", "op"), ("41%|del tuo stipendio", "res")], top=520, size=80)
          + col(tease("Poi: è tanto o poco?"), 880), size=92) + (ES,),
  concept(True, "Tre fasce <em>indicative</em>", cards([
      ("Sotto il 30%", "Spazio per il resto del mese.", "Comodo"),
      ("Tra 30% e 40%", "Fai attenzione alle altre spese.", "Da tenere d’occhio"),
      ("Oltre il 40%", "Il resto va dosato con cura.", "Stretto")], top=470, gap=22, h=215), size=88) + ("Soglie indicative, non consigli personali",),
  (*side(False, "Guarda il peso <em>della Casa</em>", "In Statistiche ogni categoria ha la sua quota sulle uscite.", "v2/stats-2-light", badge="1"), DE),
  (*side(True, "Affitto come <em>ricorrenza</em>", "Una volta sola: la prossima data e l’importo sempre in vista.", "old/rules", badge="2"), DE),
  save("Il peso dell’affitto <em>in 3 mosse</em>", steps([
      "Affitto ÷ stipendio × 100|La percentuale sul tuo stipendio.",
      "Confrontala con 30% e 40%|Come riferimento, non come regola.",
      "Controlla in Statistiche|Quanto pesa la Casa sul mese."], top=520, gap=40, size=44), tail="Mandalo al tuo coinquilino"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 22 · SALDI (lime)
NEW.append(dict(n=22, slug="saldi-3-domande", pal=8, tag="IMPARA", slides=[
  (*hook(True, "Saldi", "Saldi: <em>3 domande</em> prima di pagare.", "Lo sconto non è un risparmio se non ti serviva.", "v2/budget-light", size=112, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Hai risparmiato <em>48&nbsp;€?</em> No: ne hai spesi 72", equation([("120&nbsp;€|prezzo pieno", "n"), ("−", "op"), ("40%|sconto", "n"), ("=", "op"), ("72&nbsp;€|ne spendi", "res")], top=560, size=84)
          + col(P("Se non ti serviva, non hai risparmiato: hai fatto una spesa in più.", 42), 880), size=80) + (ES,),
  concept(True, "Regola 1: <em>aspetta 24 ore</em>", col(P("Se domani lo vuoi ancora, è un bisogno. Se l’hai dimenticato, era un impulso.", 46), 520)
          + col(tease("Poi: le altre due"), 1060), size=96),
  (*side(False, "Domanda 2: <em>ho il budget?</em>", "Guarda la barra della categoria: vicino all’80%, rallenta.", "v2/budget-light", badge="2"), DE),
  (*side(True, "Domanda 3: <em>vale un obiettivo?</em>", "Un acquisto grande? Mettilo da parte come obiettivo e versa un po’ al mese.", "v2/c3-goal-list-light", badge="3"), DE),
  save("Le 3 domande <em>dei saldi</em>", steps([
      "Aspetto 24 ore?|Se lo voglio ancora, passo alla 2.",
      "Ho il budget?|La barra della categoria lo dice.",
      "Lo comprerei a prezzo pieno?|Se no, non è un affare."], top=520, gap=40, size=44), tail="Mandalo a chi non resiste ai saldi"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 23 · DOVE SONO FINITI 200&nbsp;€ (lime)
NEW.append(dict(n=23, slug="dove-sono-finiti-200-euro", pal=8, tag="IMPARA", slides=[
  (*hook(True, "Movimenti", "Dove sono finiti <em>200&nbsp;€</em> di questo mese?", "Ricostruiscilo in 3 passi, anche se non ricordi niente.", "v2/mov-light", size=108, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Il conto <em>non torna</em>", equation([("1.100&nbsp;€|entrate", "n"), ("−", "op"), ("900&nbsp;€|spese ricordate", "n"), ("=", "op"), ("200&nbsp;€|dove sono?", "res")], top=520, size=80)
          + col(tease("Poi: i 3 passi"), 880), size=92) + (ES,),
  (*side(True, "1. Apri <em>Movimenti</em>", "Tutto in ordine di giorno, con il subtotale di ogni giorno.", "v2/mov-light", badge="1", nxt="Poi filtra"), DE),
  (*duo(False, "2. Filtra <em>per categoria</em>", "Tocca «Categoria», scegli: la lista si restringe.", "v2/e-cat-menu-light", "v2/e-cat-result-light", labels=["Scegli","Risultato"]), DE),
  (*side(True, "3. Guarda <em>quale pesa</em>", "In Statistiche la categoria più grande è il primo indiziato.", "v2/stats-2-light", badge="3"), DE),
  save("Ricostruisci il mese <em>in 3 mosse</em>", steps([
      "Apri Movimenti|Scorri il mese giorno per giorno.",
      "Filtra per categoria|Cerca le spese che non ricordavi.",
      "Guarda le Statistiche|La quota più grande spiega la differenza."], top=520, gap=40, size=44), tail="Mandalo a chi chiede «dove sono finiti i soldi?»"),
  final(True, "v2/home-light"),
]))

# ============================================================ POST 24 · TUTTO IN UN'APP (lime)
NEW.append(dict(n=24, slug="basta-fogli-excel", pal=8, tag="IMPARA", slides=[
  (*hook(True, "Un’app sola", "Excel, note, app della banca: <em>3 posti per i soldi.</em>", "Troppi posti, nessun quadro completo.", "v2/home-light", size=96, ph_w=680, ph_x=340, ph_y=830),),
  concept(False, "Tre posti, <em>nessun quadro</em>", cards([
      ("Fogli Excel", "Da compilare a mano, sempre indietro."),
      ("Note del telefono", "Cifre sparse, nessun totale."),
      ("App della banca", "Vedi solo un conto alla volta.")], top=470, gap=22, h=215)
      + col(tease("Poi: tutto insieme"), 1190), size=88),
  (*side(True, "Tutti i conti <em>in un posto</em>", "Contanti, carta e banca con il patrimonio totale in alto.", "v2/accounts-light", badge="1"), DE),
  (*duo(False, "7 lingue, chiaro o scuro", "Italiano, English, Deutsch, Español, Français, <span style=\"white-space:nowrap\">日本語</span>, <span style=\"white-space:nowrap\">简体中文</span>: segue la lingua e il tema di iOS.", "v2/home-light", "v2/home-dark", labels=["Chiaro","Scuro"]), DE),
  (*side(True, "Un file <em>quando serve</em>", "PDF del mese da Statistiche; CSV per Excel o Numbers e JSON del profilo dalle Impostazioni.", "v2/stats-light", badge="2"), DE),
  save("Tutto in un’app <em>in 3 mosse</em>", steps([
      "Metti i conti in un posto|Patrimonio sempre in chiaro.",
      "Scrivi fissi e budget|Una volta sola.",
      "Esporta solo se serve|PDF, CSV o JSON."], top=520, gap=40, size=44), tail="Mandalo a chi usa ancora Excel"),
  final(True, "v2/home-light"),
]))
