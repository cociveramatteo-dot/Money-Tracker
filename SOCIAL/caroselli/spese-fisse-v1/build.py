#!/usr/bin/env python3
"""Genera il carosello 4:5 dal materiale demo del post 2."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

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
    canvas = Image.new("RGB", (1080, 1350), INK if dark else PAPER)
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


def screenshot(canvas, name, box, y, width=928):
    with Image.open(POST / "materiale" / name) as source:
        fragment = source.convert("RGB").crop(box)
    fragment = fragment.resize((width, round(fragment.height * width / fragment.width)), Image.Resampling.LANCZOS)
    mask = Image.new("L", fragment.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, fragment.width - 1, fragment.height - 1), 28, fill=255)
    canvas.paste(fragment, ((canvas.width - width) // 2, y), mask)


def save(canvas, number):
    canvas.save(OUT / f"slide-{number:02d}.png", optimize=True)


first = slide(dark=True)
text(first, 82, "BUCKTRAIL", 34, PAPER, x=148)
text(first, 273, "Hai sul conto", 86, PAPER)
text(first, 390, "1.000 €", 210, AMBER)
text(first, 690, "Quanto puoi\ndavvero spendere?", 89, PAPER)
text(first, 1030, "Fai il conto con un esempio →", 41, "#DCE8DF", bold=False)
save(first, 1)

second = slide()
text(second, 82, "ESEMPIO", 34, GREEN, x=148)
text(second, 240, "Cosa deve\nancora uscire?", 94)
for y, label, amount in (
    (586, "Affitto", "550 €"),
    (705, "Bollette stimate", "84,01 €"),
    (824, "Streaming video", "15,99 €"),
):
    ImageDraw.Draw(second).line((76, y - 32, 1004, y - 32), fill="#CED9D0", width=2)
    text(second, y, label, 49, bold=False)
    text(second, y, amount, 50, x=750)
text(second, 1045, "650 € già impegnati.", 75, GREEN)
save(second, 2)

third = slide()
text(third, 82, "ESEMPIO", 34, GREEN, x=148)
text(third, 235, "1.000 € − 650 €", 99)
text(third, 435, "350 €", 207, GREEN)
text(third, 694, "Prima delle altre spese.", 69)
text(third, 851, "Da qui decidi quanto destinare\na spesa, imprevisti e risparmi.", 50, bold=False)
save(third, 3)

fourth = slide()
text(fourth, 82, "ESEMPIO IN APP", 34, GREEN, x=148)
text(fourth, 206, "Lo usi ancora?", 101)
screenshot(fourth, "IMG_8011.PNG", (53, 1194, 1117, 1570), 377)
text(fourth, 800, "191,88 € l’anno", 106, GREEN)
text(fourth, 965, "Se disdici e salti 12 rinnovi,\npuoi usare quei soldi per altro.", 50, bold=False)
save(fourth, 4)

last = slide()
text(last, 82, "BUCKTRAIL", 34, GREEN, x=148)
text(last, 197, "Vedi cosa esce.\nDecidi cosa tenere.", 84)
text(last, 434, "In Ricorrenti trovi importi e date.", 46, bold=False)
screenshot(last, "IMG_8001.PNG", (53, 808, 1117, 1780), 540, width=730)
text(last, 1257, "Un’unica app, senza abbonamento.", 45, GREEN)
save(last, 5)
