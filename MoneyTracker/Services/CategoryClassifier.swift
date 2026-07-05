import Foundation

/// On-device auto-categorization via keyword/stem matching.
/// Returns a category NAME string — must match an existing Category.name in the DB.
/// Falls back to "Altro" if nothing matches.
///
/// HOW STEMS WORK
/// The algorithm uses String.contains(), so a stem like "pizz" matches:
///   "pizza", "pizzeria", "pizzata", "la pizzata di sabato" — all → Cibo
/// Use stems for word families; use full strings for brands/proper nouns.
///
/// SCORING
/// Each match adds word.count points, so longer (more specific) matches win.
/// E.g. "esselunga" (9 pts) beats "bar" (3 pts) on the same input.
///
/// LANGUAGES COVERED
/// 🇮🇹 Italiano · 🇬🇧 English · 🇩🇪 Deutsch · 🇫🇷 Français · 🇪🇸 Español
/// 🇵🇹 Português · 🇷🇴 Română · 🇵🇱 Polski · 🇳🇱 Nederlands · 🇭🇷 Hrvatski · 🇦🇱 Shqip
///
/// NEW CATEGORIES (work when user creates a matching Category in the app)
/// "Stipendio", "Bollette", "Animali", "Bambini"
struct CategoryClassifier {

    private static let keywords: [String: [String]] = [

        // ─────────────────────────────────────────────────────────────
        // CIBO  🍕🛒
        // ─────────────────────────────────────────────────────────────
        "Cibo": [
            // 🇮🇹 Supermercati & insegne
            "supermercato", "ipermercato", "minimarket", "alimentari",
            "spesa", "mercato", "market", "discount", "coop", "esselunga",
            "pam", "conad", "lidl", "eurospin", "aldi", "carrefour",
            "simply", "gs supermercati", "famila", "interspar", "spar",
            "penny market", "md discount", "bennet", "tosano", "tigros",
            "dem", "ipercoop", "pak", "cadoro", "sigma", "despar",
            "eurospar", "naturasì", "naturasi", "natura si", "il gigante",
            "iperal", "unes", "basko", "punto simply", "conad city",
            "pam local", "in's discount", "prèmiata", "grosmarket",
            "multicedi", "rinal", "ok market", "risparmio casa",
            "keystore", "coalvi", "galassia", "maxì", "maxi supermercati",
            "italmark", "vegé", "elite supermercati",
            // 🇮🇹 Macellerie / Pescherie / Specializzati
            "macelleria", "macell", "macellaio", "norcineria",
            "salumeria", "pescheria", "peschet", "fruttivendolo",
            "ortofrutta", "frutteria", "gastronomia", "rosticceria",
            "friggitoria", "caseificio", "latteria", "erboristeria",
            "drogheria", "bottega alimentari", "bottega",
            "negozio bio", "negozio biologico", "biologico",
            // 🇮🇹 Panetterie / Pasticcerie
            "panetteria", "panetter", "panificio", "forno",
            "pasticceria", "pasticcer", "confetteria", "biscottificio",
            "gelateria", "gelater", "cremeria", "cioccolateria",
            // 🇮🇹 Bar & caffetterie
            "bar", "caffè", "caffe", "caffetteria", "cornetto",
            "cappuccino", "espresso", "starbucks", "lavazza", "illy",
            "nespresso", "vergnano", "nero caffè", "caffè nero",
            "torrefazione", "coffee shop",
            // 🇮🇹 Ristoranti & locali
            "ristorante", "trattoria", "osteria", "locanda",
            "agriturismo", "brasseria", "birreria", "paninoteca",
            "tavola calda", "mensa", "self service", "fast food",
            "fastfood", "street food", "food truck", "chiosco",
            // 🇮🇹 Pizze & derivati (stem)
            "pizz", "pizza", "pizzeria", "piadina", "piadineria",
            "focacceria", "focaccia", "schiacciata",
            // 🇮🇹 Hamburger & catene
            "hamburger", "burger", "burger king", "burgerking",
            "mcdonald", "mc donald", "kfc", "subway", "dominos",
            "pizza hut", "pizzahut", "wendy", "five guys",
            "old wild west", "spizzico", "alice pizza",
            "panino giusto", "autogrill", "chef express",
            "wagamama", "nando", "the fork",
            // 🇮🇹 Cucina etnica
            "sushi", "susheria", "giapponese", "cinese", "cina",
            "wok", "ramen", "noodle", "dim sum", "indiano",
            "curry", "messicano", "tex mex", "tacos", "burrito",
            "kebab", "kebabb", "doner", "döner", "turco",
            "arabo", "libanese", "greco", "gyros", "thai",
            "vietnamita", "coreano", "etnico", "orientale",
            "poke", "pokeria", "hawaiano",
            // 🇮🇹 Momenti pasto
            "cena", "pranzo", "colazione", "brunch", "aperitivo",
            "aperi", "merenda", "spuntino", "buffet", "degustazione",
            "ristoro", "pausa pranzo",
            // 🇮🇹 Delivery & asporto
            "just eat", "justeat", "glovo", "uber eats", "ubereats",
            "deliveroo", "foodora", "consegna a domicilio",
            "asporto", "take away", "takeaway", "delivery",
            // 🇮🇹 Prodotti alimentari (stems e nomi)
            "carne", "bistecca", "pollo", "maiale", "agnello",
            "pesce", "salmone", "tonno", "gamberi", "frutti di mare",
            "verdura", "ortaggi", "frutta", "fresco", "biologico",
            "pane", "latte", "uova", "formaggio", "salumi",
            "prosciutto", "bresaola", "mortadella", "salsiccia",
            "pancetta", "guanciale", "pecorino", "grana",
            "parmigiano", "gorgonzola", "mozzarella",
            "pasta", "riso", "olio", "vino", "birra",
            "acqua minerale", "succo", "tè", "cioccolato",
            "dolce", "torta", "gelato", "snack", "merendina",
            "biscotti", "yogurt", "burro", "panna", "farina",
            "zucchero", "sale", "spezie", "condimento", "salsa",
            "sugo", "ragù", "pomodoro", "conserva",
            // 🇮🇹 Brand specifici
            "gran caffè", "gambrinus", "zucchero", "eataly",
            "biocoop", "natura e futuro", "il biologico",
            // 🇬🇧 English — supermarkets & chains
            "grocery", "groceries", "supermarket", "food",
            "convenience store", "corner shop", "food store",
            "deli", "delicatessen", "butcher", "fishmonger",
            "bakery uk", "whole foods", "waitrose", "tesco",
            "sainsbury", "marks spencer", "iceland uk", "asda",
            "morrisons", "co-op uk", "spar uk",
            // 🇬🇧 English — restaurants & fast food
            "restaurant", "cafe", "coffee shop", "coffee",
            "diner", "bistro", "canteen", "cafeteria", "snack bar",
            "takeout", "takeaway uk", "meal", "lunch uk",
            "dinner uk", "breakfast uk", "brunch uk",
            "pret", "greggs", "nandos", "wagamama uk",
            "costa coffee", "eat uk", "itsu", "leon uk",
            "five guys uk", "burger uk", "sandwich",
            // 🇩🇪 Deutsch — Supermärkte
            "supermarkt", "lebensmittel", "einkaufen",
            "rewe", "edeka", "kaufland", "real markt",
            "tegut", "norma", "netto", "hit markt",
            "bäckerei", "konditorei", "metzgerei", "fleischer",
            // 🇩🇪 Deutsch — Essen & Produkte
            "restaurant de", "gaststätte", "gasthaus",
            "mittagessen", "abendessen", "frühstück", "café de",
            "kaffee de", "bier de", "wurst", "kartoffel",
            "brot", "brötchen", "kuchen", "gemüse", "obst",
            "fleisch de", "fisch de", "käse", "milch",
            "eier", "nudeln", "reis de", "imbiss",
            "döner de", "currywurst", "bratwurst", "schnitzel",
            "hunger de", "mahlzeit", "speise", "gericht",
            // 🇫🇷 Français — supermarchés
            "supermarché", "épicerie", "epicerie", "alimentation fr",
            "leclerc", "intermarché", "auchan", "monoprix",
            "franprix", "casino fr", "picard", "leader price",
            // 🇫🇷 Français — alimentation
            "boulangerie", "pâtisserie", "boucherie",
            "poissonnerie", "fromagerie", "charcuterie", "primeur",
            "déjeuner", "dîner", "petit-déjeuner", "café fr",
            "croissant", "baguette", "fromage", "vin fr",
            "bière fr", "viande fr", "poisson fr", "légumes",
            "fruits fr", "pain fr", "lait fr", "oeufs",
            "crêperie", "crêpe", "bistrot fr",
            // 🇪🇸 Español — supermercados
            "supermercado", "mercadona", "alcampo", "dia es",
            "eroski", "consum es", "ahorramas", "hipercor",
            // 🇪🇸 Español — comida
            "restaurante es", "cafetería es", "panadería",
            "pastelería es", "carnicería", "pescadería",
            "frutería", "colmado", "bodega es",
            "almuerzo", "cena es", "desayuno", "comida es",
            "café es", "cerveza es", "tapas", "bocadillo",
            "bocata", "pincho", "menú del día",
            "hamburguesería", "pizzería es", "churrería",
            "heladería",
            // 🇵🇹 Português
            "continente", "pingo doce", "minipreço",
            "padaria", "pastelaria", "talho", "peixaria",
            "mercearia", "almoço", "jantar pt", "petisco",
            "tasca", "café pt", "cerveja pt",
            // 🇷🇴 Română
            "kaufland ro", "mega image", "profi ro",
            "penny ro", "cafenea", "brutărie", "patiserie",
            "măcelar", "pescărie", "mâncare", "prânz",
            "cină ro", "mic dejun", "restaurant ro",
            "piață", "magazin alimentar", "lapte ro",
            // 🇳🇱 Nederlands
            "albert heijn", "jumbo nl", "plus nl",
            "dirk", "aldi nl", "lidl nl", "ekoplaza",
            "bakker nl", "slager nl", "brood",
            "kaas", "boodschappen", "eten nl",
            "lunch nl", "diner nl", "ontbijt",
            "snackbar", "frituur",
            // 🇵🇱 Polski
            "biedronka", "kaufland pl", "auchan pl",
            "carrefour pl", "żabka", "dino", "netto pl",
            "lewiatan", "restauracja", "kawiarnia",
            "piekarnia", "cukiernia", "rzeźnik",
            "sklep spożywczy", "zakupy", "jedzenie",
            "obiad", "kolacja", "śniadanie", "lunch pl",
            // 🇭🇷 Hrvatski
            "konzum", "spar hr", "lidl hr", "kaufland hr",
            "tommy", "restoran", "kafić", "pekara",
            "tržnica", "hrana", "ručak", "večera hr",
            // 🇦🇱 Shqip
            "restorant", "kafene", "market al",
            "dyqan ushqimor", "bukëtore", "ushqim",
            "drekë", "darkë", "mëngjes",
        ],

        // ─────────────────────────────────────────────────────────────
        // TRASPORTI  🚗✈️
        // ─────────────────────────────────────────────────────────────
        "Trasporti": [
            // 🇮🇹 Carburante — distributori
            "benzina", "gasolio", "diesel", "gpl", "metano auto",
            "carburante", "rifornimento", "distributore",
            "pompa benzina", "stazione servizio",
            "q8", "eni", "agip", "esso", "shell", "bp",
            "ip carburanti", "api carburanti", "tamoil",
            "beyfin", "repsol it", "total", "star service",
            "gulf", "kukar", "retitalia",
            // 🇮🇹 Auto — assicurazione, bollo, manutenzione
            "assicurazione auto", "rc auto", "rca",
            "bollo auto", "bollo moto", "revisione",
            "collaudo", "tagliando", "officina", "carrozzeria",
            "gommista", "pneumatici", "gomme invernali",
            "gomme estive", "gomme auto", "meccanico",
            "targa", "patente", "rinnovo patente",
            "multa", "verbale", "sanzione", "ztl",
            "autovelox", "infrazione",
            "carro attrezzi", "traino", "soccorso stradale",
            "aci", "aci global", "europ assistance auto",
            // 🇮🇹 Parcheggio
            "parcheggio", "sosta", "parchimetro",
            "garage", "box auto", "posto auto",
            "parkeggio", "parcometro", "strisce blu",
            "easypark", "telepass park", "mypay parcheggio",
            // 🇮🇹 Autostrade & pedaggi
            "autostrada", "telepass", "casello", "pedaggio",
            "tangenziale", "raccordo", "a1", "a4", "a8",
            "a9", "a7", "a26", "a14", "a22", "autovie",
            "sat autostrade", "cav veneto",
            // 🇮🇹 Taxi & ridesharing
            "taxi", "uber", "bolt", "free now", "itaxi",
            "mytaxi", "radiotaxi", "radiotax", "cab",
            "ncc", "noleggio conducente", "chauffeur",
            // 🇮🇹 Treni
            "trenitalia", "italo", "frecciarossa",
            "frecciargento", "frecciabianca", "intercity",
            "regionale", "treno", "biglietto treno",
            "abbonamento treno", "ntv", "itabus",
            "pendolino", "alta velocità",
            // 🇮🇹 Trasporto pubblico urbano
            "metro", "metropolitana", "autobus", "tram",
            "bus", "pullman", "filobus",
            "atm", "atac", "gtt", "amt genova", "ctm",
            "anm", "apam", "actv", "seta", "tper",
            "mobilità angioina", "amc", "gtm",
            "biglietto bus", "biglietto metro",
            "abbonamento metro", "abbonamento bus",
            "mensile trasporti", "carnet biglietti",
            "grattino", "pass trasporti",
            // 🇮🇹 Bici, monopattini, micro-mobilità
            "bicicletta", "e-bike", "ebike",
            "monopattino elettrico", "monopattino",
            "lime", "helbiz", "bird monopattino",
            "bit mobility", "mobike", "bike sharing",
            "ciclomotore", "scooter elettrico",
            // 🇮🇹 Moto
            "moto", "motorino", "scooter", "yamaha",
            "honda moto", "piaggio", "vespa", "kawasaki",
            "ducati", "bmw moto", "suzuki moto",
            "assicurazione moto", "tagliando moto",
            // 🇮🇹 Veicoli elettrici
            "auto elettrica", "ricarica elettrica",
            "colonnina", "enel x", "be charge",
            "free to x", "ionity", "tesla supercharger",
            // 🇮🇹 Noleggio auto
            "noleggio auto", "car sharing", "carsharing",
            "enjoy", "share now", "sixt share",
            "hertz", "avis", "europcar", "maggiore",
            "sixt", "localiza", "budget rent a car",
            "enterprise rent", "thrifty",
            // 🇮🇹 Aerei
            "volo", "aereo", "aeroporto",
            "ryanair", "easyjet", "ita airways",
            "vueling", "wizzair", "volotea",
            "blu express", "lufthansa it", "alitalia",
            "biglietto aereo", "imbarco", "check-in",
            // 🇮🇹 Traghetti & navi
            "traghetto", "ferry", "grimaldi",
            "moby lines", "tirrenia", "gnv",
            "corsica ferries", "snav", "grandi navi veloci",
            "porto", "nave", "aliscafo",
            // 🇮🇹 Bus a lunga percorrenza
            "flixbus", "megabus it", "blablacar",
            "bus turistico", "pullman turistico",
            // 🇮🇹 Guida & istruzione
            "autoscuola", "patente b", "lezioni guida",
            "esame guida", "revisione patente",
            // 🇬🇧 English
            "gas station", "petrol", "fuel", "gasoline",
            "diesel uk", "bp uk", "shell uk",
            "transport", "transportation", "commute",
            "train uk", "bus uk", "subway uk",
            "underground", "tube", "tram uk",
            "taxi uk", "cab uk", "uber uk", "lyft",
            "car rental", "parking uk", "highway",
            "toll uk", "motorway", "oyster card",
            "railcard", "season ticket", "bus pass",
            "national rail", "tfl", "crossrail",
            "flixbus uk", "megabus", "greyhound",
            "car service uk", "mot test",
            "insurance car uk", "road tax", "breakdown",
            // 🇩🇪 Deutsch
            "tankstelle", "benzin de", "diesel de",
            "kraftstoff", "aral", "esso de", "shell de",
            "total de", "jet tankstelle",
            "bahn", "deutsche bahn", "db bahn", "s-bahn",
            "u-bahn", "straßenbahn", "bus de",
            "hvv", "mvv", "vvs", "vgn", "vrr",
            "taxi de", "parkhaus", "parkplatz",
            "maut", "autobahn de", "hauptbahnhof", "hbf",
            "fahrkarte", "monatskarte", "kfz", "werkstatt",
            "tüv", "versicherung auto de",
            "öbb", "oebb", "wiener linien", "mvg",
            // 🇫🇷 Français
            "essence fr", "gazole fr", "carburant",
            "station service fr", "total fr", "bp fr",
            "train fr", "sncf", "ter fr", "tgv",
            "ouigo", "metro fr", "bus fr", "ratp",
            "tcl lyon", "tbm bordeaux", "tisseo toulouse",
            "taxi fr", "blablacar fr", "parking fr",
            "péage", "autoroute fr", "assurance voiture fr",
            // 🇪🇸 Español
            "gasolina", "gasóleo", "gasolinera",
            "repsol es", "cepsa", "bp es",
            "tren es", "renfe", "cercanías", "metro es",
            "bus es", "taxi es", "parking es",
            "autopista es", "peaje es",
            // 🇷🇴 Română
            "benzinărie", "benzina ro", "diesel ro",
            "tren ro", "cfr", "metrou",
            "autobuz ro", "taxi ro", "parcare",
            // 🇵🇱 Polski
            "paliwo", "benzyna pl", "diesel pl",
            "stacja paliw", "pociąg", "pkp", "metro pl",
            "autobus pl", "taxi pl", "parking pl",
            "autostrada pl",
            // 🇳🇱 Nederlands
            "benzine nl", "diesel nl", "tankstation",
            "trein", "ns nl", "metro nl", "bus nl",
            "tram nl", "taxi nl", "parkeren", "fiets nl",
        ],

        // ─────────────────────────────────────────────────────────────
        // SVAGO  🎬🎮
        // ─────────────────────────────────────────────────────────────
        "Svago": [
            // 🇮🇹 Video streaming
            "netflix", "amazon prime", "disney plus", "disney+",
            "apple tv+", "appletv", "hbo", "hbo max", "now tv",
            "dazn", "sky sport", "sky cinema", "sky abbonamento",
            "mediaset infinity", "infinity tv", "rai play",
            "discovery plus", "discovery+", "paramount plus",
            "paramount+", "crunchyroll", "mubi",
            "apple one", "google tv",
            // 🇮🇹 Musica streaming
            "spotify", "apple music", "youtube music",
            "tidal", "deezer", "soundcloud", "amazon music",
            "youtube premium", "youtube",
            // 🇮🇹 Live streaming
            "twitch", "mixer", "kick streaming",
            // 🇮🇹 Cinema
            "cinema", "multisala", "uci cinema",
            "the space cinema", "notorious cinema",
            "odeon cinema", "medusa cinema",
            "nexo digital", "biglietto cinema",
            // 🇮🇹 Teatro & cultura
            "teatro", "opera", "spettacolo", "musical",
            "concerto", "festival", "evento", "biglietto",
            "prevendita", "ticketmaster", "ticketone",
            "eventbrite", "dice app", "vivaticket",
            "mailticket", "go2", "ciaotickets",
            // 🇮🇹 Videogiochi — console
            "playstation", "ps4", "ps5", "xbox",
            "nintendo", "nintendo switch",
            "steam", "epic games", "origin",
            "battle net", "ubisoft", "ea play",
            "xbox gamepass", "game pass",
            "ps plus", "playstation plus", "psn",
            "playstation store", "nintendo eshop",
            "videogame", "videogioco", "gioco", "gaming",
            // 🇮🇹 App store
            "app store", "google play", "in-app",
            "acquisto in app", "itunes", "mac app store",
            "google play pass",
            // 🇮🇹 Palestra & sport praticato
            "palestra", "gym", "fitness center",
            "crossfit", "yoga", "pilates", "spinning",
            "zumba", "functional training",
            "piscina", "nuoto", "acquaticità",
            "tennis", "circolo tennis", "padel",
            "calcio", "calcetto", "soccer",
            "basket", "pallacanestro", "volley",
            "pallavolo", "rugby", "football americano",
            "boxe", "kick boxing", "muay thai",
            "arti marziali", "karate", "judo", "jiu jitsu",
            "krav maga", "MMA",
            "arrampicata", "boulder", "climbing",
            "corsa", "atletica", "maratona",
            "ciclismo sport", "mountain bike",
            "sci", "snowboard", "ski pass",
            "equitazione", "golf", "tiro a segno",
            "surf", "windsurf", "kitesurf", "canoa",
            "kayak", "vela", "barca sport",
            "bouldering", "free climbing",
            "Virgin Active", "Fitness First",
            // 🇮🇹 Hobby & attività creative
            "hobby", "modellismo", "pittura", "fotografia",
            "camera fotografica", "stampa foto",
            "musica", "strumento musicale", "chitarra",
            "pianoforte", "violino", "batteria",
            "lezioni musica", "corso musica",
            "escape room", "bowling", "biliardo",
            "go kart", "karting", "paintball",
            "laser tag", "parco divertimenti",
            "gardaland", "mirabilandia", "leolandia",
            "movieland", "luna park", "giostra",
            "zoo", "acquario", "museo", "mostra",
            "esposizione", "gita culturale",
            "escursione", "trekking", "hiking",
            // 🇮🇹 Lettura
            "libro", "fumetto", "manga", "graphic novel",
            "giornale", "rivista", "edicola",
            // 🇮🇹 Giochi & scommesse
            "scommessa", "superenalotto", "lotto",
            "gratta e vinci", "sisal", "snai",
            "planetwin", "eurobet", "bet", "casinò",
            "poker", "casino online",
            // 🇬🇧 English
            "entertainment", "cinema uk", "theatre uk",
            "museum uk", "exhibition uk", "concert uk",
            "festival uk", "ticket uk", "event uk",
            "gaming uk", "steam uk", "playstation uk",
            "xbox uk", "netflix uk", "spotify uk",
            "amazon prime uk",
            "gym uk", "fitness uk", "yoga uk",
            "pilates uk", "sport uk", "swimming uk",
            "tennis uk", "golf uk",
            "book uk", "magazine uk", "newspaper uk",
            "escape room uk", "bowling uk", "theme park",
            "alton towers", "thorpe park",
            // 🇩🇪 Deutsch
            "kino", "theater de", "konzert de",
            "museum de", "ausstellung", "fitness de",
            "sportstudio", "schwimmbad", "netflix de",
            "spotify de", "steam de", "buch de",
            "zeitschrift de", "kiosk de", "spielhalle",
            // 🇫🇷 Français
            "cinéma fr", "théâtre fr", "concert fr",
            "musée fr", "spectacle fr", "netflix fr",
            "spotify fr", "sport fr", "salle de sport",
            "piscine fr", "livre fr",
            // 🇪🇸 Español
            "cine es", "teatro es", "concierto es",
            "museo es", "deporte es", "gimnasio",
            "netflix es", "spotify es",
            // 🇷🇴 Română
            "cinema ro", "teatru ro", "concert ro",
            "sala fitness", "netflix ro", "spotify ro",
            "carte ro", "jocuri",
            // 🇵🇱 Polski
            "kino pl", "teatr", "koncert pl", "muzeum",
            "siłownia", "netflix pl", "spotify pl",
            "książka", "gra pl",
            // 🇳🇱 Nederlands
            "bioscoop", "theater nl", "concert nl",
            "museum nl", "sportschool", "zwembad nl",
            "netflix nl", "spotify nl", "game nl",
            // 🇭🇷 Hrvatski
            "kino hr", "kazalište", "koncert hr",
            "teretana", "netflix hr", "igra",
            // 🇦🇱 Shqip
            "kinema", "palestër", "muzikë", "lojë",
            // 🇮🇹 Sport — catene palestre
            "mcfit", "anytime fitness", "vivfit",
            "wellness lab", "curves", "energym",
            "total fitness", "just fit", "world gym",
            "la sportiva", "centro sportivo",
            "associazione sportiva", "polisportiva",
            "campo sportivo", "stadio", "palasport",
            "piscina olimpionica", "wellness club",
            // 🇮🇹 Sport — attrezzatura & abbigliamento sport
            "abbigliamento sportivo", "tuta", "felpa sport",
            "shorts sport", "reggiseno sportivo",
            "scarpe running", "scarpe calcio",
            "scarpe basket", "tacchetti",
            "attrezzatura sport", "racchetta",
            "pallone", "rete da tennis", "rete da padel",
            "mazza golf", "bastoni sci",
            "tavola snowboard", "wakeboard",
            "muta subacquea", "pinne",
            // 🇮🇹 Gaming — accessori & periferiche
            "controller", "gamepad", "joystick",
            "cuffia gaming", "mouse gaming",
            "tastiera gaming", "monitor gaming",
            "rog gaming", "razer gaming",
            "steelseries", "corsair gaming",
            "logitech gaming", "hyperx",
            // 🇮🇹 Giochi da tavolo & hobby
            "gioco da tavolo", "boardgame",
            "dungeons dragons", "warhammer",
            "giochi di ruolo", "gdr", "card game",
            "magic the gathering", "pokemon card",
            "puzzle", "scacchi", "biliardo club",
            // 🇮🇹 Parchi & attrazioni italiane
            "oltrepo mantovano", "fiabilandia",
            "edenlandia", "cavallino matto",
            "movie land", "parco delle fiabe",
            "zoo safari", "safari park",
            "parco acquatico", "aquafan", "caneva",
            "zoomarine", "italiainminiatura",
            // 🇮🇹 Cultura
            "pinacoteca", "galleria arte",
            "palazzo reale", "palazzo ducale",
            "fiera libro", "salone del libro",
            "comicon", "romics", "expocartoon",
            // 🇮🇹 Scommesse & giochi aggiuntivi
            "william hill", "bet365", "betfair",
            "bwin", "888sport", "lottomatica",
            "sisal matchpoint", "pokerstars",
            "goldbet", "admiralbet",
        ],

        // ─────────────────────────────────────────────────────────────
        // SHOPPING  🛍️
        // ─────────────────────────────────────────────────────────────
        "Shopping": [
            // 🇮🇹 E-commerce generici
            "amazon", "amzn", "amazon.it", "amazon eu",
            "ebay", "aliexpress", "wish", "shein", "asos",
            "zalando", "about you", "vinted", "depop",
            "subito.it", "etsy", "farfetch", "yoox",
            "net-a-porter", "mytheresa", "luisaviaroma",
            "privalia", "veepee", "saldiprivati",
            "brandalley", "venteprivee",
            // 🇮🇹 Abbigliamento & moda
            "vestiti", "abbigliamento", "abiti", "moda",
            "zara", "h&m", "hm", "primark", "bershka",
            "stradivarius", "mango", "pull&bear",
            "massimo dutti", "calzedonia", "intimissimi",
            "tezenis", "yamamay", "luisa spagnoli",
            "liu jo", "max mara", "pinko", "patrizia pepe",
            "elisabetta franchi", "guess", "ralph lauren",
            "tommy hilfiger", "lacoste", "gant",
            "hugo boss", "armani", "versace", "gucci",
            "prada", "louis vuitton", "hermes", "chanel",
            "dior", "fendi", "burberry", "michael kors",
            "coach", "furla", "coccinelle", "pollini",
            "tod's", "tods", "ferragamo",
            // 🇮🇹 Scarpe
            "scarpe", "calzature", "stivali", "sneaker",
            "sneakers", "scarpe da ginnastica",
            "geox", "hogan", "frau", "clarks",
            "converse", "vans", "nike", "adidas",
            "puma", "reebok", "new balance",
            "under armour", "fila", "diadora",
            "saucony", "asics", "brooks running",
            // 🇮🇹 Accessori
            "borse", "borsa", "zaino", "valigia", "bagaglio",
            "portafoglio", "cintura", "cappello",
            "sciarpa", "guanti", "occhiali", "gioielli",
            "orologio", "bracciale", "collana", "anello",
            "orecchini",
            // 🇮🇹 Elettronica
            "mediaworld", "media world", "unieuro",
            "euronics", "expert", "trony",
            "telefono", "smartphone", "iphone",
            "samsung galaxy", "huawei", "xiaomi",
            "oppo", "oneplus", "motorola", "sony xperia",
            "computer", "laptop", "notebook", "pc",
            "mac", "imac", "macbook", "macbook pro",
            "dell", "hp", "lenovo", "asus", "acer",
            "tablet", "ipad", "kindle",
            "cuffie", "auricolari", "airpods", "headphones",
            "tv", "televisore", "monitor", "schermo",
            "fotocamera", "reflex", "mirrorless", "gopro",
            "cover telefono", "caricatore", "cavo usb",
            "accessori elettronici",
            // 🇮🇹 Casa & arredamento
            "ikea", "maisons du monde", "mondo convenienza",
            "leroy merlin", "leroymerlin", "brico",
            "castorama", "obi", "bricofer", "bricocenter",
            "bricoman", "bricoman it",
            "arredamento", "mobili", "divano",
            "letto", "armadio", "cucina componibile",
            "lampada", "tappeto", "cuscino",
            // 🇮🇹 Sport & outdoor
            "decathlon", "sportler", "intersport",
            "cisalfa", "columbia", "north face",
            "patagonia", "quechua", "domyos",
            // 🇮🇹 Profumeria & bellezza
            "profumeria", "sephora", "douglas",
            "marionnaud", "kiko", "mac cosmetics",
            "nyx", "benefit", "urban decay",
            "profumo", "eau de toilette",
            "cosmetica", "trucco", "make-up",
            "rossetto", "mascara", "fondotinta",
            "crema viso", "siero", "skincare",
            "shampoo", "balsamo", "prodotti capelli",
            // 🇬🇧 English
            "shopping", "store", "shop", "online shopping",
            "amazon uk", "ebay uk", "asos uk", "next uk",
            "primark uk", "topshop", "river island",
            "john lewis", "boots uk", "argos", "currys",
            "pc world", "apple store uk",
            "clothes uk", "clothing uk",
            "shoes uk", "trainers uk", "fashion uk",
            "electronics uk", "gadget", "appliance",
            "furniture uk",
            // 🇩🇪 Deutsch
            "online shop de", "otto shop", "zalando de",
            "amazon de", "ebay de", "mediamarkt",
            "saturn markt", "douglas de",
            "kleidung", "schuhe de", "sport de",
            "möbel", "baumarkt",
            // 🇫🇷 Français
            "boutique fr", "vêtements fr", "chaussures fr",
            "mode fr", "fnac", "darty", "boulanger fr",
            "amazon fr", "cdiscount", "rueducommerce",
            // 🇪🇸 Español
            "tienda es", "ropa es", "zapatos es",
            "amazon es", "pccomponentes",
            "el corte inglés", "mediamarkt es",
            // 🇷🇴 Română
            "emag", "fashion days ro", "flanco",
            "altex", "haine ro", "pantofi ro",
            // 🇵🇱 Polski
            "allegro", "amazon pl", "empik",
            "media expert", "rtv euro agd",
            "ubrania", "buty pl",
            // 🇳🇱 Nederlands
            "bol.com", "coolblue nl", "amazon nl",
            "kleding nl", "schoenen nl",
            "mediamarkt nl", "hema nl",
            // 🇭🇷 Hrvatski
            "shopping hr", "odjeća", "obuća hr",
            // 🇦🇱 Shqip
            "dyqan al", "rroba al",
            // 🇮🇹 Abbigliamento aggiuntivo
            "ovs", "orsay", "bonprix", "promod",
            "kiabi", "terranova", "subdued", "alcott",
            "champion brand", "fendi sport",
            "north sails", "woolrich", "stone island",
            "cp company", "a.p.c.", "acne studios",
            "arc'teryx", "salewa", "mammut", "marmot",
            "kathmandu", "rab brand",
            "levi's", "wrangler", "lee jeans",
            "diesel jeans", "replay jeans", "g-star raw",
            "calvin klein jeans", "tommy jeans",
            "polo ralph lauren",
            // 🇮🇹 Lingerie & intimo
            "intimo", "lingerie", "reggiseno",
            "mutande", "boxer", "calze", "collant",
            "pigiama", "vestaglie",
            "triumph", "la perla", "cosabella",
            // 🇮🇹 Bambini shopping (abiti/giochi)
            "vestiti bimbo", "abbigliamento neonato",
            // 🇮🇹 Gioiellerie & orologi
            "gioielleria", "orologeria", "pandora",
            "swarovski", "tiffany", "cartier gioielli",
            "bulgari", "damiani", "pomellato",
            "rolex", "omega orologio", "tissot",
            "casio", "fossil orologio", "hamilton watch",
            // 🇮🇹 Librerie & cartolerie
            "feltrinelli shop", "mondadori store",
            "book shop", "cartoleria shop",
            "buffetti", "stabilo", "moleskine",
            // 🇮🇹 Profumerie & cosmetica
            "profumeria shop", "kiko milano",
            "sephora shop", "douglas shop",
            "marionnaud shop", "nyx cosmetics",
            "benefit cosmetics", "mac cosmetics shop",
            "urban decay shop", "nars", "charlotte tilbury",
            "the ordinary", "cerave", "la roche-posay",
            "vichy shop", "avène shop", "bioderma",
            // 🇮🇹 Elettronica aggiuntiva
            "apple store", "apple.com", "apple it",
            "google store", "samsung store",
            "fnac it", "teknozone", "punto informatico",
            "pixmania", "coolshop",
            "batteria portatile", "powerbank",
            "adattatore hdmi", "cavo lightning",
            "smart tv", "soundbar", "proiettore",
            "drone", "action cam",
            // 🇮🇹 Ferramenta & bricolage
            "ferramenta", "castorama shop",
            "brico io", "leroy shop",
            "pennello", "vernice shop", "trapano",
            "vite", "bullone", "colla shop",
            // 🇮🇹 Giocattoli & hobby shop
            "giocattoli shop", "toys shop",
            "hobby shop", "modellismo shop",
        ],

        // ─────────────────────────────────────────────────────────────
        // SALUTE  🏥💊
        // ─────────────────────────────────────────────────────────────
        "Salute": [
            // 🇮🇹 Farmacia & parafarmacia (stems)
            "farmac", "farmacia", "parafarmacia", "parafarmacie",
            "lloyds farmacia", "lloyds",
            "farmacie riunite", "farmacia comunale",
            // 🇮🇹 Medicinali & prodotti OTC
            "medicinale", "medicina", "farmaco", "pillola",
            "compressa", "bustina", "sciroppo", "pomata",
            "unguento", "cerotto", "supposte", "gocce",
            "spray nasale", "collirio", "lozione",
            "tachipirina", "moment", "brufen", "nurofen",
            "aspirina", "paracetamolo", "ibuprofene",
            "amoxicillina", "antibiotico", "antibiotici",
            "antinfiammatorio", "antipiretico", "antidolorifico",
            "cortisone", "antistaminico", "antiallergico",
            "oki", "aulin", "voltaren", "efferalgan",
            "bentelan", "maalox", "gaviscon", "nexium",
            "omeprazolo", "lanzoprazolo", "lucen",
            "fermenti lattici", "probiotico", "prebiotico",
            "vitamina c", "vitamina d", "zinco", "magnesio",
            "omega 3", "integratore", "multivitaminico",
            "collagene", "acido ialuronico", "melatonina",
            // 🇮🇹 Medici & specialisti
            "medico", "dottore", "visita medica",
            "specialista", "consulto medico", "ambulatorio",
            "poliambulatorio", "clinica", "day hospital",
            "guardia medica", "medico di base", "mmg",
            "pronto soccorso", "ospedale", "policlinico",
            "dentista", "odontoiatra", "odontoiatria",
            "ortodonzia", "igienista dentale", "protesi dentale",
            "oculista", "optometrist", "ortopedico",
            "fisioterapia", "fisioterapista",
            "osteopata", "chiropratico",
            "psicologo", "psicoterapia", "psichiatra",
            "nutrizionista", "dietologo", "dietista",
            "dermatologo", "cardiologo", "gastroenterologo",
            "ginecologo", "urologo", "endocrinologo",
            "reumatologo", "neurologo", "pediatra",
            "otorino", "otorinolaringoiatra",
            "pneumologo", "oncologo", "ematologo",
            "nefrologo", "chirurgo",
            // 🇮🇹 Analisi & diagnostica
            "analisi del sangue", "esame del sangue",
            "laboratorio analisi", "prelievo", "emocromo",
            "radiografia", "rx", "ecografia", "risonanza",
            "risonanza magnetica", "tac", "pet scan",
            "colonscopia", "gastroscopia", "endoscopia",
            "mammografia", "pap test", "ecg",
            "elettrocardiogramma", "spirometria",
            "audiometria", "dermatoscopia",
            "scintigrafia", "biopsia",
            // 🇮🇹 Cure & terapie
            "vaccino", "vaccinazione", "booster",
            "fisioterapia", "riabilitazione", "logopedia",
            "agopuntura", "ozonoterapia", "infiltrazione",
            "iniezione", "infusione", "flebo",
            "terapia occupazionale", "osteopatia",
            // 🇮🇹 Ottica
            "ottica", "occhiali da vista", "lenti a contatto",
            "lenti", "montatura", "grand ottico",
            "luxottica", "safilo", "visione ottica",
            // 🇮🇹 Benessere & cura del corpo
            "parrucchiere", "barbiere", "barber",
            "hair salon", "hair stylist",
            "estetista", "estetica", "centro estetico",
            "spa", "beauty center",
            "manicure", "pedicure", "unghie", "nail art",
            "nail salon", "ceretta", "depilazione",
            "epilazione laser", "laser estetico",
            "massaggio", "massaggio relax", "shiatsu",
            "reflexologia", "trattamento viso",
            "trattamento corpo", "bagno turco", "sauna",
            "tatuaggio", "piercing",
            // 🇬🇧 English
            "pharmacy uk", "chemist uk", "boots pharmacy",
            "lloyds pharmacy", "superdrug",
            "doctor uk", "gp uk", "hospital uk",
            "clinic uk", "dentist uk", "optician uk",
            "physio uk", "physiotherapy uk", "osteopath uk",
            "chiropractor uk", "psychologist uk",
            "therapy uk", "counselling",
            "blood test uk", "scan uk", "mri", "xray",
            "ultrasound uk", "vaccination uk",
            "prescription", "medicine uk", "vitamins uk",
            "supplement uk", "health food uk",
            "hairdresser uk", "barber uk", "beauty uk",
            "spa uk", "massage uk", "nail salon uk",
            // 🇩🇪 Deutsch
            "apotheke", "arzt de", "zahnarzt",
            "krankenhaus", "klinik de", "physiotherapie de",
            "osteopathie de", "augenarzt", "brille de",
            "medikament", "rezept de",
            "vitamine de", "gesundheit", "friseur",
            "friseursalon", "kosmetik de", "wellness de",
            "massage de", "nagelstudio",
            // 🇫🇷 Français
            "pharmacie fr", "médecin fr", "hôpital fr",
            "clinique fr", "dentiste fr", "kiné",
            "ostéopathe fr", "opticien fr",
            "médicament fr", "ordonnance",
            "vitamines fr", "santé fr", "coiffeur",
            "esthétique fr", "spa fr", "massage fr",
            // 🇪🇸 Español
            "farmacia es", "médico es", "hospital es",
            "dentista es", "óptico", "medicamento",
            "receta médica", "vitaminas es", "salud",
            "peluquería", "estética es", "spa es",
            // 🇷🇴 Română
            "farmacie ro", "medic ro", "spital",
            "stomatolog ro", "analize ro",
            "medicament ro", "vitamina ro",
            "sănătate", "coafor", "salon frumusete",
            // 🇵🇱 Polski
            "apteka", "lekarz pl", "szpital pl",
            "dentysta pl", "fizjoterapeuta",
            "lek pl", "recepta pl", "witaminy pl",
            "zdrowie", "fryzjer", "salon urody",
            // 🇩🇪/🇦🇹 drogerie
            "drogerieMarkt", "dm drogerie", "rossmann",
            "müller drogerie",
            // 🇳🇱 Nederlands
            "apotheek nl", "huisarts nl", "tandarts nl",
            "fysiotherapeut nl", "ziekenhuis nl",
            "kapper nl", "schoonheidsspecialiste",
            // 🇭🇷 Hrvatski
            "ljekarma", "liječnik", "bolnica hr",
            "frizer hr", "kozmetika hr",
            // 🇦🇱 Shqip
            "farmaci al", "mjek al", "spital al",
            "berber al",
            // 🇮🇹 Farmaci aggiuntivi per nome
            "normix", "augmentin", "zitromax",
            "pantorc", "lansox", "nexium it",
            "tecta", "esomeprazolo", "omeprazolo",
            "entact", "sertralin", "paroxetin",
            "ritalin", "concerta", "lexotan",
            "xanax", "en", "rivotril",
            "cardioaspirina", "eliquis", "xarelto",
            "warfarin", "coumadin",
            "insulina", "metformina", "atorvastatina",
            "lisinopril", "ramipril", "amlodipina",
            "losartan", "levotiroxina", "eutirox",
            "calcio vitamina d", "alendronate",
            // 🇮🇹 Visite mediche & check-up
            "check-up medico", "visita di controllo",
            "visita sportiva", "idoneità sportiva",
            "certificato medico", "referto medico",
            "teleconsulto", "video visita",
            "medico online", "consulto online",
            // 🇮🇹 Cure estetiche mediche
            "botox", "botulino", "filler",
            "acido ialuronico medico",
            "laser dermatologico", "peeling chimico",
            "mesoterapia", "radiofrequenza",
            "pressoterapia", "linfodrenaggio",
            "cavitazione", "criolipolisi",
            "trattamento anticellulite",
            // 🇮🇹 Protesi & ausili
            "protesi dentale", "impianto dentale",
            "apparecchio denti", "invisalign",
            "lente a contatto morbida",
            "lente a contatto rigida",
            "occhiali progressivi", "occhiali sole vista",
            "apparecchio acustico", "protesi acustica",
            "stampella", "deambulatore", "sedia rotelle",
            // 🇮🇹 Prodotti sanitari
            "misuratore pressione", "sfigmomanometro",
            "glucometro", "strisce glicemia",
            "termometro", "saturimetro",
            "nebulizzatore", "aerosol",
            "cerotto post-op", "garza sterile",
            "siringhe", "aghi insulina",
            // 🇮🇹 Benessere avanzato
            "centro benessere", "centro termale",
            "terme", "acqua termale",
            "idromassaggio", "vasca idromassaggio",
            "hammam", "bagno di vapore",
            "riflessologia plantare",
            "agopuntura cinese", "naturopatia",
            "aromaterapia", "cristalloterapia",
            "iridologia",
        ],

        // ─────────────────────────────────────────────────────────────
        // CASA  🏠
        // ─────────────────────────────────────────────────────────────
        "Casa": [
            // 🇮🇹 Affitto & mutuo
            "affitto", "canone locazione", "canone di affitto",
            "mutuo", "rata mutuo", "ipoteca",
            "condominio", "spese condominiali",
            "amministratore di condominio",
            "caparra", "deposito cauzionale",
            "agenzia immobiliare", "immobile",
            // 🇮🇹 Utenze casa
            "luce", "elettricità", "corrente",
            "enel", "a2a", "acea", "iren", "hera",
            "dolomiti energia", "edison", "eni gas e luce",
            "e.on", "illumia", "sorgenia", "green network",
            "plenitude", "axpo", "engie",
            "gas", "gas naturale", "metano casa",
            "italgas", "2i rete gas",
            "acqua", "acquedotto", "servizio idrico",
            "tim casa", "vodafone casa", "windtre casa",
            "fastweb casa", "iliad fibra",
            "fibra", "adsl", "internet casa",
            "eolo", "linkem", "tiscali",
            "telefono fisso", "telefonia fissa",
            // 🇮🇹 Manutenzione & riparazioni
            "idraulico", "elettricista", "muratore",
            "imbianchino", "falegname", "serraturiere",
            "giardiniere", "pulizie", "colf", "domestica",
            "badante", "assistente familiare",
            "riparazione", "manutenzione", "intervento",
            "caldaia", "boiler", "riscaldamento",
            "termosifone", "radiatore",
            "climatizzatore", "condizionatore",
            "aria condizionata", "pompa di calore",
            "lavatrice", "lavastoviglie", "frigorifero",
            "forno elettrico", "microonde", "piano cottura",
            "lavello", "miscelatore", "rubinetto",
            "scarico intasato", "perdita acqua",
            "tegola", "grondaia", "impermeabilizzazione",
            "intonaco", "pavimento", "parquet",
            "piastrelle", "rivestimento", "vernice",
            "pittura casa", "impianto elettrico",
            "impianto idraulico", "sostituzione serratura",
            // 🇮🇹 Assicurazioni casa
            "assicurazione casa", "polizza casa",
            "rc casa", "assicurazione incendio",
            "assicurazione furto", "assicurazione danni",
            "generali casa", "allianz casa",
            "unipolsai casa", "groupama casa",
            // 🇮🇹 Tasse & tributi
            "imu", "tari", "tassa rifiuti",
            "imposta municipale", "tributo comunale",
            "comune di", "agenzia entrate",
            // 🇮🇹 Sicurezza domestica
            "allarme", "sistema sicurezza",
            "verisure", "securitas", "sicuritalia",
            "telecamera", "videosorveglianza",
            "videocitofono", "citofono",
            // 🇮🇹 Elettrodomestici & arredo
            "ikea casa", "elettrodomestico",
            "samsung elettrod", "bosch", "whirlpool",
            "indesit", "candy", "miele", "smeg",
            "de longhi", "breville", "kitchenaid",
            // 🇬🇧 English
            "rent uk", "mortgage uk", "utility uk",
            "utilities uk", "electricity uk",
            "gas uk", "water uk", "broadband uk",
            "internet uk", "council tax",
            "home insurance", "contents insurance",
            "plumber", "electrician uk", "builder uk",
            "handyman", "cleaning uk", "cleaner uk",
            "maintenance uk", "repair uk", "boiler uk",
            "heating uk", "air conditioning uk",
            "appliance uk", "furniture home uk",
            "home improvement", "decoration uk",
            // 🇩🇪 Deutsch
            "miete", "kaltmiete", "warmmiete",
            "nebenkosten", "strom de", "gas de",
            "wasser de", "internet de", "telefon fest",
            "versicherung haus", "hausrat",
            "klempner", "elektriker de",
            "handwerker", "reinigung de",
            "heizung de", "möbel de", "renovierung",
            // 🇫🇷 Français
            "loyer fr", "charges fr", "électricité fr",
            "gaz fr", "eau fr", "internet fr",
            "assurance habitation", "plombier fr",
            "électricien fr", "femme de ménage",
            "chauffage fr", "meubles fr", "rénovation fr",
            // 🇪🇸 Español
            "alquiler es", "hipoteca es",
            "electricidad es", "gas es", "agua es",
            "internet es", "seguro hogar",
            "fontanero", "electricista es",
            "limpieza es", "muebles es",
            // 🇷🇴 Română
            "chirie ro", "ipotecar", "curent ro",
            "gaz ro", "apă ro", "internet ro",
            "reparație", "curățenie ro",
            // 🇵🇱 Polski
            "czynsz", "rachunki pl", "prąd pl",
            "gaz pl", "woda pl", "internet pl",
            "naprawa", "sprzątanie pl",
        ],

        // ─────────────────────────────────────────────────────────────
        // ABBONAMENTI  📱
        // ─────────────────────────────────────────────────────────────
        "Abbonamenti": [
            // 🇮🇹 Termini generici
            "abbonamento", "subscription", "mensile",
            "annuale", "annuo", "renewal", "rinnovo",
            "piano mensile", "piano annuale", "abbonamento premium",
            // 🇮🇹 Cloud storage & productivity
            "icloud", "icloud+", "google one",
            "dropbox", "onedrive", "box cloud",
            "pcloud", "mega cloud",
            "adobe", "creative cloud", "photoshop",
            "illustrator", "premiere pro", "after effects",
            "lightroom", "acrobat",
            "microsoft 365", "office 365", "microsoft",
            "google workspace", "gsuite",
            "notion", "evernote", "todoist",
            "trello", "asana", "monday.com",
            "slack", "zoom", "teams microsoft",
            "meet google", "webex",
            "canva pro", "figma", "sketch app",
            "invision", "grammarly",
            "1password", "lastpass", "dashlane",
            "bitwarden",
            // 🇮🇹 VPN & sicurezza
            "vpn", "nordvpn", "expressvpn",
            "surfshark", "protonvpn", "cyberghost",
            "tunnelbear", "avast", "norton", "kaspersky",
            "bitdefender", "avg", "mcafee",
            "malwarebytes", "intego",
            // 🇮🇹 Developer & cloud
            "github", "gitlab", "bitbucket",
            "aws", "amazon web services", "azure",
            "google cloud", "heroku", "digitalocean",
            "cloudflare", "netlify", "vercel",
            "jetbrains", "xcode developer",
            // 🇮🇹 Musica & podcast
            "spotify premium", "apple music sub",
            "youtube premium sub", "tidal sub",
            "deezer premium", "audioboom", "audible",
            "storytel",
            // 🇮🇹 Video streaming (abbonamento)
            "netflix abbonamento", "disney plus sub",
            "amazon prime sub", "dazn abbonamento",
            "sky abbonamento", "apple tv plus",
            "paramount plus sub", "mubi sub",
            "crunchyroll sub", "now tv sub",
            // 🇮🇹 News & lettura
            "corriere della sera abbonamento",
            "la repubblica abbonamento",
            "sole 24 ore", "gazzetta sport",
            "kindle unlimited", "scribd", "storytel",
            // 🇮🇹 Fitness & benessere apps
            "fitbit premium", "strava premium",
            "myfitnesspal premium", "nike training",
            "peloton app", "headspace", "calm app",
            "whoop", "garmin connect",
            // 🇮🇹 Dating & social
            "tinder gold", "tinder plus",
            "bumble premium", "hinge premium",
            "meetic", "parship", "match",
            "twitter blue", "x premium",
            "linkedin premium",
            // 🇬🇧 English
            "subscription uk", "monthly plan",
            "annual plan uk", "renewal uk",
            "icloud uk", "dropbox uk", "adobe uk",
            "microsoft uk", "norton uk", "vpn uk",
            "notion uk", "zoom uk",
            // 🇩🇪 Deutsch
            "abo", "abonnement de", "jahresabo",
            "monatsabo",
            // 🇫🇷 Français
            "abonnement fr", "mensualité fr",
            "renouvellement fr",
            // 🇪🇸 Español
            "suscripción", "renovación es",
            "mensual es",
            // Common
            "premium plan", "pro plan",
            "business plan", "family plan",
            "student plan", "upgrade",
        ],

        // ─────────────────────────────────────────────────────────────
        // LAVORO  💼
        // ─────────────────────────────────────────────────────────────
        "Lavoro": [
            // 🇮🇹 Cancelleria & forniture ufficio
            "cancelleria", "cartoleria", "forniture ufficio",
            "stampante", "toner", "cartuccia stampante",
            "carta a4", "penna", "matita", "evidenziatore",
            "quaderno", "agenda", "calendario da tavolo",
            "binder", "spillatrice", "post-it", "folder",
            "busta da lettera", "scotch", "colla",
            "forbici ufficio",
            // 🇮🇹 Hardware & postazione lavoro
            "scrivania", "sedia ergonomica", "monitor ufficio",
            "tastiera", "mouse", "webcam",
            "microfono pc", "hard disk esterno",
            "chiavetta usb", "hub usb",
            "schermo esterno", "docking station",
            // 🇮🇹 Formazione professionale
            "formazione", "corso professionale",
            "corso online", "conferenza", "convegno",
            "seminario", "workshop", "fiera",
            "master professionale", "certificazione",
            "esame certificazione", "udemy business",
            "coursera lavoro", "linkedin learning",
            "pluralsight", "oreilly",
            // 🇮🇹 Trasferta & rappresentanza
            "trasferta", "rimborso spese", "nota spese",
            "hotel lavoro", "volo lavoro",
            "treno lavoro", "taxi lavoro",
            "pranzo lavoro", "cena lavoro",
            "cliente pranzo", "meeting cena",
            "spese rappresentanza", "riunione esterna",
            // 🇮🇹 Servizi professionali
            "commercialista", "studio commercialista",
            "avvocato", "notaio", "consulente",
            "consulenza professionale",
            "partita iva", "inps autonomi", "inail",
            "contributi previdenziali",
            "f24", "modello f24", "irpef", "iva",
            "tasse commercialista", "dichiarazione redditi",
            "fattura professionale", "parcella",
            // 🇮🇹 Software gestionale & business
            "fatture in cloud", "fattureincloud",
            "aruba", "aruba pagopa", "pagopa",
            "gestionale", "crm", "erp",
            "software contabilità", "metatasse",
            "zucchetti", "teamsystem", "esatto",
            "fiscozen",
            // 🇮🇹 Varie lavoro
            "firma digitale", "spid", "caf",
            "patronato", "consulente del lavoro",
            "busta paga elaborazione",
            // 🇬🇧 English
            "office supplies uk", "stationery uk",
            "work expense", "business trip uk",
            "conference uk", "training uk",
            "accountant uk", "lawyer uk",
            "consulting uk", "invoice uk",
            "tax uk work", "business cost",
            // 🇩🇪 Deutsch
            "bürobedarf", "arbeit de", "dienstreise",
            "fortbildung de", "steuerberater",
            "rechnung de", "buchhaltung",
            // 🇫🇷 Français
            "fournitures bureau fr", "travail fr",
            "déplacement pro", "formation pro",
            "comptable fr", "facture fr",
            // 🇪🇸 Español
            "material oficina", "trabajo es",
            "viaje negocio", "formación es",
            "asesor", "factura es",
        ],

        // ─────────────────────────────────────────────────────────────
        // ISTRUZIONE  📚
        // ─────────────────────────────────────────────────────────────
        "Istruzione": [
            // 🇮🇹 Università & scuola
            "università", "tasse universitarie",
            "immatricolazione", "iscrizione scuola",
            "retta scolastica", "retta università",
            "tassa scolastica", "contributo universitario",
            "studente", "facoltà", "ateneo",
            "politecnico", "bicocca", "sapienza",
            "bocconi", "cattolica", "statale",
            "scuola media", "scuola superiore",
            "liceo", "liceo classico", "liceo scientifico",
            "istituto tecnico", "professionale",
            "scuola privata", "scuola paritaria",
            "scuola materna", "asilo nido", "asilo",
            "nido", "elementare", "primaria",
            // 🇮🇹 Materiale scolastico
            "libro scolastico", "libri scolastici",
            "zaino scuola", "materiale didattico",
            "diario scolastico", "astuccio",
            "compasso", "calcolatrice scientifica",
            "dizionario scolastico", "atlante",
            "cartina geografica",
            // 🇮🇹 Corsi privati & ripetizioni
            "ripetizioni", "doposcuola",
            "lezione privata", "insegnante privato",
            "tutor", "tutoraggio",
            // 🇮🇹 Corsi di lingua
            "corso di lingua", "inglese",
            "tedesco", "spagnolo", "francese",
            "cinese mandarin", "russo", "arabo",
            "british council", "cambridge english",
            "ielts", "toefl", "goethe institut",
            "alliance française", "cervantes",
            "american corner",
            // 🇮🇹 Formazione online
            "udemy", "coursera", "edx", "skillshare",
            "linkedin learning", "pluralsight",
            "domestika", "masterclass",
            "khan academy", "duolingo plus",
            "babbel", "busuu", "memrise",
            "italki", "preply",
            // 🇮🇹 Scuola di guida
            "autoscuola", "scuola guida",
            "lezioni guida", "esame teoria",
            "esame pratico patente",
            // 🇮🇹 Accademie & conservatori
            "accademia belle arti", "conservatorio",
            "liceo musicale", "scuola di danza",
            "accademia di danza",
            // 🇮🇹 Librerie scolastiche
            "feltrinelli", "mondadori", "rizzoli",
            "hoepli", "ibs", "libreria", "edicola scuola",
            // 🇬🇧 English
            "school fees uk", "university uk",
            "college uk", "tuition fees uk",
            "student loan", "course uk edu",
            "textbook uk", "school supplies uk",
            "private tuition uk", "language course uk",
            "driving school uk", "exam fee uk",
            // 🇩🇪 Deutsch
            "schule de", "universität de",
            "studiengebühren", "nachhilfe",
            "sprachkurs de", "prüfungsgebühr",
            "schulbuch", "lernmaterial de",
            "volkshochschule", "vhs kurs",
            // 🇫🇷 Français
            "école fr", "université fr",
            "frais de scolarité", "cours particuliers",
            "cours de langue fr", "fournitures scolaires fr",
            // 🇪🇸 Español
            "escuela es", "universidad es",
            "matrícula es", "clases particulares",
            "curso de idiomas es", "material escolar",
            // 🇷🇴 Română
            "scoala ro", "universitate ro",
            "taxe scolare ro", "meditații ro",
            "curs limbi straine",
            // 🇵🇱 Polski
            "szkoła pl", "uczelnia pl", "czesne",
            "korepetycje", "kurs językowy pl",
            "podręcznik pl",
        ],

        // ─────────────────────────────────────────────────────────────
        // VIAGGI  ✈️🏨
        // ─────────────────────────────────────────────────────────────
        "Viaggi": [
            // 🇮🇹 Voli & compagnie aeree
            "volo", "aereo", "aeroporto",
            "biglietto aereo", "check-in", "imbarco",
            "ryanair", "easyjet", "ita airways",
            "vueling", "wizzair", "volotea",
            "blu express", "lufthansa", "air france",
            "klm", "british airways", "emirates",
            "qatar airways", "turkish airlines",
            "delta airlines", "american airlines",
            "united airlines", "swiss air",
            "tap portugal", "iberia", "finnair",
            "norwegian air", "wizz air",
            "wizz", "flybe",
            // 🇮🇹 Ricerca voli & OTA
            "skyscanner", "kayak", "google flights",
            "momondo", "edreams", "opodo",
            "lastminute", "volagratis", "bravofly",
            "kiwi.com",
            // 🇮🇹 Hotel & alloggi
            "hotel", "albergo", "b&b",
            "bed and breakfast", "pensione",
            "ostello", "hostel", "resort",
            "villagio vacanze", "glamping",
            "camping", "campeggio", "bungalow",
            "agriturismo vacanza", "country house",
            "airbnb", "booking", "booking.com",
            "expedia", "hotels.com", "trivago",
            "trip.com", "agoda",
            "hilton", "marriott", "accor",
            "sheraton", "radisson", "ibis",
            "nh hotels", "best western",
            // 🇮🇹 Traghetti & crociere
            "traghetto", "ferry vacanza",
            "crociera", "nave crociera", "porto imbarco",
            "grimaldi lines", "moby lines",
            "tirrenia", "gnv", "corsica ferries",
            "snav", "grandi navi veloci",
            "costa crociere", "msc crociere",
            "norwegian cruise", "royal caribbean",
            // 🇮🇹 Noleggio vacanza
            "noleggio auto vacanza", "car rental vacation",
            "hertz vacation", "avis vacation",
            "europcar vacation",
            // 🇮🇹 Bus & treni per vacanza
            "flixbus vacanza", "blablacar",
            "itabus vacanza", "eurostar",
            "thalys", "ouigo", "renfe vacanza",
            // 🇮🇹 Attività turistiche
            "vacanza", "viaggio", "gita",
            "tour operator", "agenzia viaggi",
            "tui", "alpitour", "club med",
            "eden viaggi", "hotelplan", "nicolaus",
            "visita guidata", "escursione",
            "safari", "crociera fluviale",
            "biglietto ingresso", "attrazione turistica",
            "parco nazionale", "sito UNESCO",
            "biglietto museo vacanza",
            // 🇮🇹 Assicurazione viaggio
            "assicurazione viaggio", "polizza viaggio",
            "cancellazione volo", "rimborso viaggio",
            "generali travel", "allianz travel",
            "axa travel",
            // 🇮🇹 Mete (stem: città/paese)
            "parigi", "londra", "barcellona",
            "madrid", "amsterdam", "berlino",
            "vienna", "praga", "budapest",
            "dubai", "tokyo", "bali",
            "new york", "miami", "cancun",
            "maldive", "mykonos", "santorini",
            "ibiza", "sharm el sheikh", "hurghada",
            "zanzibar", "capo verde",
            "los angeles", "san francisco",
            // 🇬🇧 English
            "holiday uk", "vacation uk", "flight uk",
            "hotel uk", "hostel uk", "airbnb uk",
            "booking uk", "travel uk", "cruise uk",
            "tour uk", "trip uk", "sightseeing",
            "tourist uk", "excursion uk",
            "travel insurance uk", "visa fees",
            // 🇩🇪 Deutsch
            "urlaub", "reise de", "flug de",
            "hotel de", "unterkunft",
            "ferienwohnung", "kreuzfahrt",
            "ausflug de", "touristik",
            "pauschalreise", "reisebüro",
            // 🇫🇷 Français
            "vacances fr", "voyage fr", "vol fr",
            "hôtel fr", "hébergement fr",
            "croisière fr", "excursion fr",
            "agence de voyage fr",
            // 🇪🇸 Español
            "vacaciones es", "vuelo es", "hotel es",
            "alojamiento es", "crucero es",
            "excursión es", "agencia viajes",
            // 🇷🇴 Română
            "vacanță ro", "zbor ro", "hotel ro",
            "cazare", "croazieră ro",
            // 🇵🇱 Polski
            "wakacje pl", "lot pl", "hotel pl",
            "nocleg", "wycieczka",
        ],

        // ─────────────────────────────────────────────────────────────
        // REGALI  🎁
        // ─────────────────────────────────────────────────────────────
        "Regali": [
            // 🇮🇹
            "regalo", "regali", "dono", "omaggio",
            "compleanno", "buon compleanno",
            "festa compleanno", "anniversario",
            "onomastico", "natale", "babbo natale",
            "epifania", "befana", "capodanno",
            "pasqua", "san valentino", "festa mamma",
            "festa papà", "laurea", "matrimonio",
            "battesimo", "comunione", "cresima",
            "nascita", "baby shower", "nascita bambino",
            "pensionamento", "promosso",
            "carta regalo", "confezionamento",
            "fiocco regalo", "nastro regalo",
            "fiori", "bouquet", "mazzo di fiori",
            "fiorista", "florist", "rose", "tulipani",
            "orchidea", "girasoli", "calla",
            "cioccolatini regalo", "vino regalo",
            "cesto natalizio", "panettone regalo",
            "buono regalo", "gift card",
            "voucher regalo", "gift voucher",
            "amazon gift card", "itunes gift card",
            "playstation gift card",
            "netflix gift card", "spotify gift card",
            // 🇬🇧 English
            "gift uk", "present uk",
            "birthday gift uk", "christmas gift uk",
            "anniversary gift uk", "wedding gift uk",
            "flowers uk", "gift card uk", "voucher uk",
            // 🇩🇪 Deutsch
            "geschenk de", "geburtstag de",
            "weihnachten de", "blumen de",
            "gutschein de",
            // 🇫🇷 Français
            "cadeau fr", "anniversaire fr",
            "noël fr", "fleurs fr", "bon cadeau",
            // 🇪🇸 Español
            "regalo es", "cumpleaños es",
            "navidad es", "flores es",
            // 🇷🇴 Română
            "cadou ro", "zi nastere", "craciun ro",
            "flori ro",
            // 🇵🇱 Polski
            "prezent pl", "urodziny pl",
            "boże narodzenie", "kwiaty pl",
        ],

        // ─────────────────────────────────────────────────────────────
        // GIROCONTO  🔄
        // ─────────────────────────────────────────────────────────────
        "Giroconto": [
            "giroconto", "giro conto", "bonifico",
            "wire transfer", "trasferimento",
            "trasferimento fondi", "tra conti",
            "spostamento fondi", "ricarica conto",
            "ricarica prepagata",
            "ricarica satispay", "satispay",
            "postepay", "postepay evolution",
            "paypal transfer", "paypal invio",
            "revolut transfer", "revolut send",
            "n26 transfer", "wise transfer",
            "paypal me", "ricarica paypal",
            "virement", "virement bancaire",
            "überweisung", "übertrag",
            "transferencia", "traspaso",
            "from account", "to account",
            "internal transfer", "between accounts",
            "own transfer", "self transfer",
            "move money", "move funds",
        ],

        // ─────────────────────────────────────────────────────────────
        // STIPENDIO  💰  (entrate di qualsiasi tipo)
        // ─────────────────────────────────────────────────────────────
        "Stipendio": [
            // 🇮🇹 Stipendio & lavoro dipendente
            "stipendio", "stipend", "busta paga",
            "bustapaga", "accredito stipendio",
            "accredito salario", "salario", "paga",
            "remunerazione", "retribuzione",
            "mensilità", "tredicesima", "quattordicesima",
            "bonus stipendio", "premio di produzione",
            "incentivo", "indennità",
            "tfr", "liquidazione", "buonuscita",
            // 🇮🇹 Welfare & benefit
            "buoni pasto", "welfare aziendale",
            "rimborso spese dipendente",
            "indennità trasferta", "diaria",
            // 🇮🇹 Pensione & ammortizzatori
            "pensione", "assegno pensione", "pensione inps",
            "pensione anticipata", "reversibilità",
            "inps accredito", "naspi",
            "cassa integrazione", "cig",
            "assegno famigliare", "assegno unico",
            "reddito di cittadinanza", "supporto formazione",
            "disoccupazione", "sussidio", "indennità malattia",
            // 🇮🇹 Lavoro autonomo & freelance
            "fattura incassata", "pagamento cliente",
            "acconto fattura", "saldo fattura",
            "provvigione", "commissione agenzia",
            "parcella incassata", "onorario",
            "lavoro freelance", "compenso",
            // 🇮🇹 Redditi da capitale & patrimonio
            "affitto incassato", "canone locazione entrata",
            "dividendo", "cedola", "interesse bancario",
            "rendita", "plusvalenza",
            "rimborso fiscale", "rimborso 730",
            "accredito bonus stato", "superbonus",
            "bonus 110", "cashback stato",
            // 🇬🇧 English
            "salary uk", "wage uk", "payslip",
            "paycheck", "income uk", "payroll",
            "bonus uk income", "commission income",
            "dividend uk", "pension uk income",
            "benefit uk income", "allowance uk",
            "grant uk", "freelance payment uk",
            "invoice paid uk",
            // 🇩🇪 Deutsch
            "gehalt", "lohn de", "gehaltseingang",
            "bonus de income", "rente income",
            "arbeitslosengeld", "einkommen",
            // 🇫🇷 Français
            "salaire fr", "virement salaire",
            "prime fr income", "retraite fr",
            "chômage fr", "revenu fr",
            // 🇪🇸 Español
            "salario es", "nómina", "sueldo",
            "paga es income", "jubilación es",
            "pensión es", "ingreso es",
            // 🇷🇴 Română
            "salariu ro", "pensie ro", "venit ro",
            // 🇵🇱 Polski
            "wynagrodzenie", "pensja pl",
            "premia pl income", "emerytura",
            "zasiłek", "dochód pl",
        ],

        // ─────────────────────────────────────────────────────────────
        // BOLLETTE  💡  (utenze, separato da Casa)
        // ─────────────────────────────────────────────────────────────
        "Bollette": [
            // 🇮🇹 Energia elettrica
            "bolletta luce", "bolletta elettrica",
            "bolletta energia", "bolletta enel",
            "bolletta a2a", "bolletta acea",
            "bolletta iren", "bolletta hera",
            "bolletta edison", "enel energia",
            "a2a luce", "acea luce", "iren luce",
            "dolomiti energia", "eni gas e luce bolletta",
            "e.on bolletta", "illumia", "sorgenia",
            "green network energia", "plenitude bolletta",
            "axpo energia", "engie bolletta",
            "consumo luce", "kwh", "contatore luce",
            // 🇮🇹 Gas
            "bolletta gas", "gas naturale bolletta",
            "italgas bolletta", "2i rete gas",
            "a2a gas", "iren gas", "hera gas",
            "acea gas", "consumo gas",
            "contatore gas", "mc gas",
            // 🇮🇹 Acqua
            "bolletta acqua", "acquedotto bolletta",
            "servizio idrico integrato",
            "cap srl", "cap holding", "brianzacque",
            "mm acqua", "abc napoli", "sii siena",
            "consumo acqua", "contatore acqua",
            // 🇮🇹 Telefonia mobile
            "bolletta tim", "bolletta vodafone",
            "bolletta wind", "bolletta windtre",
            "bolletta iliad", "bolletta fastweb mobile",
            "very mobile bolletta", "ho mobile bolletta",
            "kena mobile", "spusu", "lycamobile",
            "ricarica telefonica", "ricarica sim",
            "piano tariffario mobile",
            // 🇮🇹 Internet & fibra
            "bolletta fibra", "bolletta internet",
            "tim fibra bolletta", "vodafone casa bolletta",
            "windtre casa bolletta", "fastweb bolletta",
            "iliad fibra bolletta", "eolo bolletta",
            "linkem bolletta", "tiscali bolletta",
            "modem affitto", "router",
            // 🇬🇧 English
            "electricity bill uk", "gas bill uk",
            "water bill uk", "utility bill uk",
            "phone bill uk", "broadband bill uk",
            "bt bill", "sky broadband bill",
            "virgin media bill", "eon uk bill",
            "edf energy bill", "british gas bill",
            "severn trent bill", "anglian water bill",
            // 🇩🇪 Deutsch
            "stromrechnung", "gasrechnung de",
            "wasserrechnung de", "telefonrechnung de",
            "internetrechnung de",
            "enbw", "rwe", "vattenfall de",
            // 🇫🇷 Français
            "facture électricité fr", "facture gaz fr",
            "facture eau fr", "facture téléphone fr",
            "facture internet fr", "edf fr",
            "engie fr", "orange fr bill",
            "sfr fr bill", "bouygues fr bill",
            // 🇪🇸 Español
            "factura luz es", "factura gas es",
            "factura agua es", "factura teléfono es",
            "factura internet es", "endesa bill",
            "iberdrola bill", "naturgy",
            "movistar bill", "vodafone es bill",
            "orange es bill",
            // 🇷🇴 Română
            "factură curent ro", "factură gaz ro",
            "factură apă ro", "factură telefon ro",
            "factură internet ro",
            // 🇵🇱 Polski
            "rachunek prąd", "rachunek gaz pl",
            "rachunek woda pl", "rachunek telefon pl",
            "rachunek internet pl",
        ],

        // ─────────────────────────────────────────────────────────────
        // ANIMALI  🐾
        // ─────────────────────────────────────────────────────────────
        "Animali": [
            // 🇮🇹 Veterinario
            "veterinario", "vet", "veterinaria",
            "clinica veterinaria", "visita veterinaria",
            "pronto soccorso veterinario",
            "ospedale veterinario", "ambulatorio vet",
            // 🇮🇹 Animali domestici
            "cane", "gatto", "coniglio", "criceto",
            "pappagallo", "uccello", "canarino",
            "pesce acquario", "rettile", "tartaruga",
            "furetto", "iguana", "serpente",
            "pet", "animale domestico",
            // 🇮🇹 Alimentazione animali
            "cibo per cani", "cibo per gatti",
            "crocchette", "mangime", "pappe animale",
            "snack cane", "snack gatto",
            "croccantini", "umido gatto", "umido cane",
            "bocconcini", "mangime uccelli",
            "mangime pesci", "acquario",
            // 🇮🇹 Negozi & e-commerce pet
            "petshop", "pet shop", "negozio animali",
            "zooplus", "arcaplanet", "maxi zoo",
            "maxizoo", "isola dei tesori",
            "naturally happy", "zoo facile",
            "animalis", "fressnapf", "zoo&co",
            // 🇮🇹 Accessori & prodotti
            "guinzaglio", "collare cane", "collare gatto",
            "cuccia", "gabbia", "trasportino",
            "lettiera", "sabbia gatto", "coperta cane",
            "giocattolo cane", "giocattolo gatto",
            "ciotola", "abbeveratoio", "fontanella gatto",
            "graffiatoio", "albero gatto",
            "pettorina", "museruola", "cappottino cane",
            // 🇮🇹 Antiparassitari & cure
            "antiparassitario", "pipette antiparassitarie",
            "advantix", "frontline", "bravecto",
            "nexgard", "seresto collare",
            "vermifugo", "sverminazione",
            "vaccino animale", "microchip",
            "sterilizzazione", "castrazione",
            "medicazione ferita",
            // 🇮🇹 Servizi
            "toelettatura", "grooming cane",
            "toeletta gatto", "dog sitter",
            "cat sitter", "pet sitter",
            "pensione per cani", "dog hotel",
            "cat hotel", "pensione animali",
            "dog walker", "addestramento cane",
            "scuola cinofila",
            // 🇮🇹 Assicurazione pet
            "assicurazione animale", "assicurazione pet",
            // 🇬🇧 English
            "vet uk", "pet food uk", "dog food uk",
            "cat food uk", "pet shop uk",
            "pets at home", "animal supplies uk",
            "pet insurance uk", "dog grooming uk",
            "cat grooming uk", "dog walker uk",
            "kennel", "cattery",
            "flea treatment uk", "worming uk",
            "vaccination pet uk",
            // 🇩🇪 Deutsch
            "tierarzt", "tierfutter de",
            "hundepension", "katzenfutter",
            "tierbedarf", "zoohandlung",
            "tierversicherung",
            // 🇫🇷 Français
            "vétérinaire fr", "animalerie fr",
            "nourriture chat fr", "nourriture chien fr",
            "pension animaux fr", "assurance animaux fr",
            // 🇪🇸 Español
            "veterinario es", "tienda animales es",
            "comida perro es", "comida gato es",
            "residencia animales es",
            // 🇷🇴 Română
            "veterinar ro", "hrana animale ro",
            "magazin animale ro",
            // 🇵🇱 Polski
            "weterynarz pl", "karma dla psa",
            "karma dla kota", "sklep zoologiczny",
            "pensjonat dla zwierząt",
        ],

        // ─────────────────────────────────────────────────────────────
        // BAMBINI  👶
        // ─────────────────────────────────────────────────────────────
        "Bambini": [
            // 🇮🇹 Neonato & prima infanzia
            "pediatra", "neonatologo", "neonato",
            "bebè", "bebe", "bambino", "bimbo", "infante",
            "pannolino", "pampers", "huggies",
            "lines baby", "dodot", "salviettine baby",
            "crema neonato", "bagnetto neonato",
            "latte artificiale", "latte formulato",
            "pappa bambino", "omogeneizzato",
            "pappe pronte", "mellin", "nestlé junior",
            "merit baby", "humana latte",
            // 🇮🇹 Abbigliamento bambini
            "vestiti bambino", "abbigliamento bambino",
            "tutina neonato", "body bimbo",
            "pigiama bambino", "scarpe bambino",
            "zara kids", "h&m bambini", "okaidi",
            "prénatal", "prenatal", "chicco",
            "zippy kids", "carter's", "gap kids",
            "name it", "orchestra moda bimbi",
            // 🇮🇹 Giocattoli
            "giocattolo", "giochi bambini",
            "toy", "lego", "playmobil", "barbie",
            "hot wheels", "paw patrol", "frozen toy",
            "peppa pig", "dinosauri gioco",
            "costruzioni", "puzzle bambini",
            // 🇮🇹 Asilo & scuola
            "asilo nido", "nido", "scuola materna",
            "materna", "scuola infanzia",
            "retta asilo", "retta nido",
            "mensa scolastica bambini",
            "gita scolastica", "escursione scuola",
            "doposcuola", "dopostuola bambini",
            // 🇮🇹 Attività extrascolastiche
            "calcio bambini", "danza bambini",
            "nuoto bambini", "musica bambini",
            "scuola musica bimbi", "arte bambini",
            "scout", "oratorio", "campo estivo",
            "summer camp bambini", "colonia estiva",
            // 🇮🇹 Puericultura
            "passeggino", "carrozzina",
            "seggiolino auto bambino",
            "seggiolone", "lettino bambino",
            "culla neonato", "baby monitor",
            "tiralatte", "sterilizzatore biberon",
            "biberon", "ciuccio", "fasciatoio",
            "marsupio portabebè", "sdraietta",
            // 🇬🇧 English
            "baby uk", "toddler uk", "children uk",
            "kids uk", "nappies uk", "diapers uk",
            "baby food uk", "formula uk",
            "nursery uk", "childcare uk",
            "babysitter uk", "school trip uk",
            "kids clothing uk", "toy uk",
            "playgroup uk", "after school uk",
            // 🇩🇪 Deutsch
            "baby de", "kind de", "kinder de",
            "windeln", "babynahrung",
            "kita", "kindertagesstätte",
            "kindergarten de", "spielzeug de",
            // 🇫🇷 Français
            "bébé fr", "enfant fr", "couche fr",
            "nourriture bébé fr", "crèche",
            "garde enfant fr", "jouet fr",
            // 🇪🇸 Español
            "bebé es", "niño", "niña", "pañal",
            "leche bebé es", "guardería",
            "cuidado niños es", "juguete es",
            // 🇷🇴 Română
            "copil ro", "bebeluș ro", "scutec",
            "lapte bebe ro", "creșă", "jucărie ro",
            // 🇵🇱 Polski
            "dziecko pl", "niemowlę pl",
            "pieluszka pl", "jedzenie dziecka pl",
            "żłobek", "przedszkole pl", "zabawka pl",
        ],
    ]

    // MARK: - Public API

    /// Lista piatta pre-normalizzata (lowercase + diacritici rimossi), ordinata per lunghezza desc.
    /// Costruita una sola volta al primo accesso.
    private static let flatKeywords: [(word: String, cat: String)] = {
        var pairs: [(word: String, cat: String)] = []
        pairs.reserveCapacity(keywords.values.reduce(0) { $0 + $1.count })
        for (cat, words) in keywords {
            for word in words {
                let norm = word.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                pairs.append((norm, cat))
            }
        }
        return pairs.sorted { $0.word.count > $1.word.count }
    }()

    // MARK: - Result cache (avoids re-classifying identical inputs during typing debounce)
    // countLimit + totalCostLimit prevengono crescita illimitata dell'heap.
    // Con stringhe medie di ~20 char (40 byte UTF-16) il limite di 512 KB copre
    // ~6.400 entry come coppie chiave+valore, molto più del caso d'uso reale.
    private static let resultCache: NSCache<NSString, NSString> = {
        let c = NSCache<NSString, NSString>()
        c.countLimit      = 2_000    // max 2 k entry uniche
        c.totalCostLimit  = 512_000  // max 512 KB totali
        return c
    }()

    /// Classifica il testo dell'utente e ritorna la categoria migliore, o "Altro".
    ///
    /// Algoritmo a 5 livelli (peso decrescente):
    ///   T1 – Match esatto parola         ×4.0
    ///   T2 – Prefisso input→keyword      ×2.5  (utente sta ancora scrivendo)
    ///   T3 – Prefisso keyword→input      ×3.0  (keyword è radice della parola scritta)
    ///   T4 – Stem italiano               ×2.0  (plurali, coniugazioni, desinenze)
    ///   T5 – Fuzzy edit-distance 1       ×1.5  (typo recovery, solo per ≥5 char)
    ///
    /// Keyword multi-parola ("penny market") vengono cercate come frase nel testo intero ×3.0.
    /// Confidence threshold: punteggio totale ≥ 6 per evitare match su parole irrilevanti.
    static func classify(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Altro" }

        // Return cached result if available
        let cacheKey = trimmed as NSString
        if let cached = resultCache.object(forKey: cacheKey) { return cached as String }

        // Normalizza: lowercase + rimuovi diacritici
        let norm = trimmed.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Token dell'input: solo lettere, min 2 char (ignora articoli/preposizioni brevi)
        let inputWords = norm
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 2 }

        guard !inputWords.isEmpty else { return "Altro" }

        var scores: [String: Double] = [:]

        for pair in flatKeywords {
            let kw = pair.word
            let kwParts = kw.components(separatedBy: " ").filter { !$0.isEmpty }

            let matchScore: Double
            if kwParts.count > 1 {
                // ── Keyword multi-parola: cerca la frase intera nel testo ─────────
                matchScore = norm.contains(kw) ? Double(kw.count) * 3.0 : 0
            } else {
                // ── Keyword singola: confronta con ogni token dell'input ──────────
                let best = inputWords.reduce(0.0) { best, word in
                    max(best, singleWordScore(input: word, keyword: kw))
                }
                matchScore = best * Double(kw.count)
            }

            if matchScore > 0 {
                scores[pair.cat, default: 0.0] += matchScore
            }
        }

        // Soglia minima di confidenza
        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= 6.0 else {
            resultCache.setObject("Altro" as NSString, forKey: cacheKey)
            return "Altro"
        }

        let result = best.key
        resultCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }

    // MARK: - Matching tiers

    /// Ritorna un moltiplicatore [0, 4] per quanto bene `input` matcha `keyword`.
    private static func singleWordScore(input: String, keyword: String) -> Double {

        // T1 – Match esatto ──────────────────────────────────────── ×4.0
        if input == keyword { return 4.0 }

        // T2 – Input è prefisso di keyword (utente sta scrivendo)
        //      "pizz" → "pizza" (4/5=80% ≥60%) → match
        //      "sup"  → "supermercato" (3/13=23% <60%, ma ≥5 char → parziale)
        if keyword.hasPrefix(input) && input.count >= 3 {
            let ratio = Double(input.count) / Double(keyword.count)
            if ratio >= 0.60 { return 2.5 }
            if input.count >= 5 { return 1.5 }  // abbastanza specifico anche con ratio bassa
            return 0
        }

        // T3 – Keyword è prefisso dell'input (forma estesa della keyword)
        //      "pizzer"  → input "pizzeria"   (6/8=75% ≥60%) → match
        //      "pizz"    → input "pizzicotto"  (4/10=40% <60%) → no match ✓
        if input.hasPrefix(keyword) {
            let ratio = Double(keyword.count) / Double(input.count)
            if ratio >= 0.60 { return 3.0 }
            return 0
        }

        // T4 – Stem italiano (plurali, coniugazioni, desinenze)
        //      "panetterie" → stem "panetter" == stem di "panetteria" → Cibo
        let iStem = italianStem(input)
        let kStem = italianStem(keyword)
        if iStem.count >= 3 && iStem == kStem { return 2.0 }
        // Prova anche il confronto input→stem(keyword) e stem(input)→keyword
        if iStem.count >= 3 && (input == kStem || iStem == keyword) { return 2.0 }

        // T5 – Fuzzy: edit distance 1 (typo recovery)
        //      Solo per parole ≥5 char per evitare falsi positivi su parole brevi
        if input.count >= 5 && keyword.count >= 5 &&
           abs(input.count - keyword.count) <= 2 &&
           levenshtein(input, keyword) == 1 { return 1.5 }

        return 0
    }

    // MARK: - Italian stemmer (suffix stripping)

    private static let italianSuffixes: [String] = [
        // ordinati dal più lungo al più corto per applicare sempre il suffisso più specifico
        "abilita", "abilità", "issimo", "issima", "issimi", "issime",
        "azione", "azioni", "amento", "amenti", "imento", "imenti",
        "mente", "arsi", "ersi", "irsi",
        "ando", "endo",
        "are", "ere", "ire",
        "ato", "ata", "ati", "ate",
        "uto", "uta", "uti", "ute",
        "ito", "ita", "iti", "ite",
        "eria", "erie", "ario", "aria",
        "ino", "ina", "ini", "ine",
        "one", "oni", "gli", "he", "hi",
        "le", "li", "i", "e", "a", "o",
    ]

    private static func italianStem(_ word: String) -> String {
        for suffix in italianSuffixes {
            if word.hasSuffix(suffix) && word.count - suffix.count >= 3 {
                return String(word.dropLast(suffix.count))
            }
        }
        return word
    }

    // MARK: - Levenshtein distance (O(n) space)

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var curr = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                curr[j] = a[i-1] == b[j-1]
                    ? prev[j-1]
                    : 1 + min(prev[j-1], prev[j], curr[j-1])
            }
            prev = curr
        }
        return prev[b.count]
    }

}
