#!/usr/bin/env python3
"""Genera il carosello 4:5 dal materiale demo del post 2."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

SOCIAL = Path(__file__).resolve().parents[2]
POST = SOCIAL / "clip-social/post-2"
OUT = POST / "pronto"
FONTS = SOCIAL / "landing/fonts"
PAPER = "#F6F6F2"
INK = "#12241C"
GREEN = "#21604A"
AMBER = "#FFC786"

OUT.mkdir(parents=True, exist_ok=True)


def slide(dark=False):
    canvas = Image.new("RGB", (1080, 1350), PAPER)
    if dark:
        gradient = Image.new("RGB", (108, 135))
        for y in range(135):
            for x in range(108):
                green = max(0, 1 - (((x - 100) / 100) ** 2 + (y / 95) ** 2) ** .5)
                amber = max(0, 1 - ((x / 80) ** 2 + ((y - 135) / 75) ** 2) ** .5)
                gradient.putpixel((x, y), (14 + int(46 * amber), 19 + int(37 * green + 19 * amber), 17 + int(24 * green)))
        canvas = gradient.resize(canvas.size, Image.Resampling.BICUBIC)
    mark = Image.open(SOCIAL / "landing/assets/icon-192.png").convert("RGBA")
    mark.thumbnail((52, 52))
    canvas.paste(mark, (76, 72), mark)
    return canvas


def text(canvas, y, content, size, color=INK, bold=True, x=76):
    face = "SpaceGrotesk-Bold.ttf" if bold else "Inter_18pt-Regular.ttf"
    font = ImageFont.truetype(FONTS / face, size)
    draw = ImageDraw.Draw(canvas)
    lines = content.splitlines()
    for index, line in enumerate(lines):
        assert x + draw.textlength(line, font=font) <= 1004, line
        draw.text((x, y + index * round(size * 1.16)), line, font=font, fill=color, anchor="lt")


def shadow(canvas, box, radius, opacity=65):
    layer = Image.new("L", canvas.size)
    left, top, right, bottom = box
    ImageDraw.Draw(layer).rounded_rectangle((left, top + 16, right, bottom + 16), radius, fill=opacity)
    canvas.paste("#070E0A", (0, 0, *canvas.size), layer.filter(ImageFilter.GaussianBlur(26)))


def inset(canvas, visual, x, y, radius):
    mask = Image.new("L", visual.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, visual.width - 1, visual.height - 1), radius, fill=255)
    canvas.paste(visual, (x, y), mask)


def phone(canvas, name, x, y, width, source_bottom=2532):
    with Image.open(POST / "materiale" / name) as source:
        screen = source.convert("RGB").crop((0, 138, source.width, source_bottom))
    edge = max(7, width // 52)
    screen_width = width - 2 * edge
    screen = screen.resize((screen_width, round(screen.height * screen_width / screen.width)), Image.Resampling.LANCZOS)
    box = (x, y, x + width, y + screen.height + 2 * edge)
    radius = width // 8
    shadow(canvas, box, radius)
    ImageDraw.Draw(canvas).rounded_rectangle(box, radius, fill="#090F0D", outline="#36433E", width=2)
    inset(canvas, screen, x + edge, y + edge, radius - edge)


def laptop(canvas, name, x, y, width):
    with Image.open(POST / "materiale" / name) as source:
        screen = ImageOps.fit(source.convert("RGB"), (width - 28, round(width * .60)), Image.Resampling.LANCZOS)
    bottom = y + screen.height + 37
    box = (x, y, x + width, bottom)
    shadow(canvas, box, 26, opacity=130)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(box, 25, fill="#111518", outline="#76817E", width=3)
    inset(canvas, screen, x + 14, y + 17, 11)
    draw.rounded_rectangle((x - 32, bottom - 4, x + width + 32, bottom + 15), 7, fill="#A4AEAC")
    draw.rounded_rectangle((x + width // 2 - 57, bottom - 4, x + width // 2 + 57, bottom + 5), 4, fill="#525B5A")


def card(canvas, name, crop, y):
    with Image.open(POST / "materiale" / name) as source:
        detail = source.convert("RGB").crop(crop)
    detail = detail.resize((850, round(detail.height * 850 / detail.width)), Image.Resampling.LANCZOS)
    shadow(canvas, (115, y, 965, y + detail.height), 35, opacity=40)
    inset(canvas, detail, 115, y, 35)


def editorial(label):
    canvas = slide()
    text(canvas, 83, label, 32, GREEN, x=148)
    return canvas


def save(canvas, number, variant=""):
    canvas.save(OUT / f"slide-{number:02d}{variant}.png", optimize=True)


first = slide(dark=True)
text(first, 83, "BUCKTRAIL", 34, PAPER, x=148)
text(first, 84, "Scorri →", 31, "#D7DFD9", bold=False, x=853)
text(first, 195, "Hai 1.000 €", 112, AMBER)
text(first, 330, "sul conto.", 105, PAPER)
text(first, 481, "Quanto puoi\ndavvero spendere?", 87, PAPER)
text(first, 731, "Prima guarda cosa deve ancora uscire.", 44, "#D7DFD9", bold=False)
phone(first, "IMG_8003.PNG", 290, 846, 500)
save(first, 1)

fixed = editorial("SPESE FISSE")
text(fixed, 180, "Cosa paghi\nogni mese?", 99)
text(fixed, 443, "Affitto, rate, canoni: spesso sai già\nquanto pagherai e quando.", 44, bold=False)
text(fixed, 580, "Mettili in conto prima che escano.", 42, GREEN)
phone(fixed, "IMG_8003.PNG", 242, 687, 596)
save(fixed, 2)

variable = editorial("SPESE VARIABILI")
text(variable, 181, "Cosa cambia\nda un mese all’altro?", 83)
text(variable, 422, "Supermercato e carburante si ripetono.\nA cambiare è quanto spendi.", 45, bold=False)
text(variable, 561, "Per prevederle, parti da una media.", 42, GREEN)
phone(variable, "IMG_8006.PNG", 230, 677, 620)
save(variable, 3)

example = editorial("ESEMPIO · PRIMA DEL PROSSIMO STIPENDIO")
text(example, 183, "Fai il conto prima.", 91)
draw = ImageDraw.Draw(example)
for y, label, amount in (
    (415, "Saldo di oggi", "1.000 €"),
    (560, "Uscite già previste", "−650 €"),
):
    draw.line((76, y - 35, 1004, y - 35), fill="#CBD8D0", width=2)
    text(example, y, label, 48, bold=False)
    text(example, y, amount, 60, x=765)
draw.rounded_rectangle((76, 720, 1004, 1110), 46, fill="#184231")
text(example, 773, "Ti restano", 47, "#DFEBE1", bold=False, x=128)
text(example, 858, "350 €", 135, PAPER, x=128)
text(example, 1025, "Da lì devi ancora coprire le altre spese.", 38, PAPER, bold=False, x=128)
text(example, 1180, "Quanto vuoi tenere per gli imprevisti?", 43, GREEN)
save(example, 4)

choice = editorial("RIGUARDA LE USCITE")
text(choice, 181, "Quali pagheresti\nanche oggi?", 91)
text(choice, 424, "Tieni ciò che ti serve o che usi davvero.\nPoi cerca cosa si rinnova per abitudine.", 45, bold=False)
card(choice, "IMG_8009.PNG", (54, 1595, 1116, 1958), 590)
text(choice, 966, "Quell’abbonamento lo rifaresti oggi?", 43, GREEN)
text(choice, 1055, "Se la risposta è no, controlla\nil prossimo rinnovo.", 49, bold=False)
save(choice, 5)

annual = editorial("ESEMPIO · UN RINNOVO")
text(annual, 175, "Quanto ti costa\nlasciarlo attivo?", 90)
card(annual, "IMG_8011.PNG", (54, 1199, 1116, 1564), 430)
text(annual, 778, "15,99 € al mese × 12", 47, GREEN)
text(annual, 860, "191,88 € l’anno", 104)
text(annual, 1040, "Se disdici in tempo per evitare 12 rinnovi,\nquei soldi puoi usarli per altro.", 44, bold=False)
save(annual, 6)

app = editorial("RICORRENTI IN BUCKTRAIL")
text(app, 183, "Controlla importi\ne prossime date.", 86)
text(app, 426, "Vedi quanto paghi e quando si rinnova.\nPoi decidi cosa tenere e cosa disdire.", 44, bold=False)
phone(app, "IMG_8001.PNG", 225, 589, 630)
save(app, 7)

for platform in ("tiktok", "instagram"):
    close = slide(dark=True)
    text(close, 83, "BUCKTRAIL", 34, PAPER, x=148)
    text(close, 183, "L’app è in arrivo.", 100, PAPER)
    text(close, 337, "Tutti i tuoi conti in un’unica app.", 47, "#D7DFD9", bold=False)
    text(close, 410, "Senza abbonamento.", 54, AMBER)
    laptop(close, "landing.png", 291, 595, 632)
    phone(close, "IMG_8001.PNG", 122, 541, 235, source_bottom=2440)
    text(close, 1092, "Iscriviti alla lista d’attesa.", 60, PAPER)
    cta = "Cerca bucktrailapp.com" if platform == "tiktok" else "Apri il link in bio"
    text(close, 1183, cta, 52, AMBER)
    save(close, 8, f"-{platform}")
