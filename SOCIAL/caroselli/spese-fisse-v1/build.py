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


def text(canvas, y, content, size, color=INK, bold=True, x=76, right=1004):
    face = "SpaceGrotesk-Bold.ttf" if bold else "Inter_18pt-Regular.ttf"
    font = ImageFont.truetype(FONTS / face, size)
    draw = ImageDraw.Draw(canvas)
    lines = content.splitlines()
    for index, line in enumerate(lines):
        assert x + draw.textlength(line, font=font) <= right, line
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


def phone(canvas, name, x, y, width):
    with Image.open(POST / "materiale" / name) as source:
        screen = source.convert("RGB")
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


def editorial(label):
    canvas = slide()
    text(canvas, 83, label, 32, GREEN, x=148)
    return canvas


def save(canvas, number, variant=""):
    canvas.save(OUT / f"slide-{number:02d}{variant}.png", optimize=True)


def left(canvas, y, content, size, color=INK, bold=True):
    text(canvas, y, content, size, color, bold, right=536)


def right_phone(canvas, name):
    phone(canvas, name, 563, 208, 436)


first = slide(dark=True)
text(first, 83, "BUCKTRAIL", 34, PAPER, x=148)
text(first, 84, "Scorri →", 31, "#D7DFD9", bold=False, x=853)
left(first, 327, "Hai 1.000 €", 83, AMBER)
left(first, 429, "sul conto.", 78, PAPER)
left(first, 574, "Quanto puoi\ndavvero\nspendere?", 73, PAPER)
left(first, 884, "Prima guarda cosa\ndeve ancora uscire.", 43, "#D7DFD9", bold=False)
right_phone(first, "IMG_8003.PNG")
save(first, 1)

fixed = editorial("SPESE FISSE")
left(fixed, 332, "Cosa paghi\nogni mese?", 77)
left(fixed, 576, "Affitto, rate, canoni.\nSpesso sai già quanto\npagherai e quando.", 43, bold=False)
left(fixed, 805, "Mettili in conto\nprima che escano.", 43, GREEN)
right_phone(fixed, "IMG_8003.PNG")
save(fixed, 2)

variable = editorial("SPESE VARIABILI")
left(variable, 300, "Cosa cambia\nda un mese\nall’altro?", 73)
left(variable, 607, "Supermercato e\ncarburante si ripetono.\nA cambiare è quanto\nspendi.", 42, bold=False)
left(variable, 879, "Per stimarle, parti\nda una media.", 42, GREEN)
right_phone(variable, "IMG_8006.PNG")
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
left(choice, 287, "Quali\npagheresti\nanche oggi?", 72)
left(choice, 611, "Tieni ciò che ti serve\no che usi davvero.\nPoi cerca cosa si\nrinnova per abitudine.", 42, bold=False)
left(choice, 878, "Quell’abbonamento\nlo rifaresti oggi?", 41, GREEN)
right_phone(choice, "IMG_8004.PNG")
save(choice, 5)

annual = editorial("ESEMPIO · UN RINNOVO")
left(annual, 248, "Lo usi\nancora?", 82)
left(annual, 485, "15,99 € al mese × 12", 42, GREEN)
left(annual, 594, "191,88 €", 95)
left(annual, 712, "l’anno", 59)
left(annual, 843, "Se eviti 12 rinnovi,\npuoi usare quei soldi\nper altro.", 42, bold=False)
right_phone(annual, "IMG_8011.PNG")
save(annual, 6)

app = editorial("RICORRENTI IN BUCKTRAIL")
left(app, 307, "Importi e\nprossime\ndate.", 78)
left(app, 618, "Vedi quanto paghi\ne quando si rinnova.", 43, bold=False)
left(app, 806, "Poi decidi cosa tenere\ne cosa disdire.", 41, GREEN)
right_phone(app, "IMG_8001.PNG")
save(app, 7)

for platform in ("tiktok", "instagram"):
    close = slide(dark=True)
    text(close, 83, "BUCKTRAIL", 34, PAPER, x=148)
    left(close, 280, "L’app è\nin arrivo.", 88, PAPER)
    left(close, 536, "Tutti i tuoi conti\nin un’unica app.", 43, "#D7DFD9", bold=False)
    left(close, 672, "Senza abbonamento.", 39, AMBER)
    laptop(close, "landing.png", 540, 371, 462)
    phone(close, "IMG_8001.PNG", 763, 686, 222)
    left(close, 875, "Iscriviti alla\nlista d’attesa.", 61, PAPER)
    cta = "Cerca bucktrailapp.com" if platform == "tiktok" else "Apri il link in bio"
    left(close, 1065, cta, 36, AMBER)
    save(close, 8, f"-{platform}")
