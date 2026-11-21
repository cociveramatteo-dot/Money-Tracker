#!/usr/bin/env python3
"""Compone i caroselli e le istruzioni della prima serie Bucktrail."""
from datetime import datetime
from pathlib import Path
import re
from functools import lru_cache

from PIL import Image, ImageColor, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "landing/fonts"
CLIPS = ROOT / "clip-social"
SCREENS = ROOT / "schermate-app/prima-serie"
HERE = Path(__file__).parent
# Carta, testo, accento, tinta chiara, fondo scuro e due colori della sfumatura.
PALETTES = (
    ("#F6F6F2", "#12241C", "#21604A", "#E5EEE7", "#0E1311", "#0E3829", "#3C2611"),
    ("#F0F4FF", "#17274A", "#264BA4", "#DCE7FD", "#111933", "#285BC6", "#212A74"),
    ("#FFF4ED", "#421E18", "#A23927", "#FADFCC", "#301919", "#A33D29", "#733025"),
    ("#F8F2FF", "#362244", "#74459E", "#EEDFFA", "#25152F", "#7440A4", "#662950"),
    ("#EEF9F5", "#122F2B", "#197163", "#D4EEE5", "#102A2B", "#007F79", "#244C73"),
    ("#FFF8E9", "#392B15", "#81540D", "#F9E9C2", "#2A2016", "#906014", "#734023"),
    ("#FFF1F5", "#42222F", "#984266", "#F9DEE9", "#311B2E", "#A9396E", "#602B54"),
    ("#EDF7FA", "#173042", "#22687F", "#D8EDF4", "#142535", "#257E9E", "#233B74"),
)
INK, ACCENT, SOFT = PALETTES[0][1:4]
MUTED = "#45504C"
MINT = "#E9F0E9"
AMBER = "#FFC786"
SIZE = (1080, 1350)


FALLBACKS = {
    "home": CLIPS / "post-2/materiale/home-pulita.png",
    "recent": SCREENS / "recent.png",
    "mov": CLIPS / "post-1/materiale/IMG_7916.PNG",
    "accounts": CLIPS / "post-1/materiale/IMG_7954.PNG",
    "add": CLIPS / "post-1/materiale/IMG_7925.PNG",
    "rules": CLIPS / "post-2/materiale/IMG_8003.PNG",
    "ruleedit": CLIPS / "post-1/materiale/IMG_7922.PNG",
    "budget": CLIPS / "post-2/materiale/budget-pulito.png",
    "goals": CLIPS / "post-1/materiale/IMG_7919.PNG",
    "stats": CLIPS / "post-1/materiale/IMG_7920.PNG",
    "shortcuts": ROOT / "landing/assets/comandi.webp",
    "add-options": ROOT / "landing/assets/aggiungi.webp",
}
FIXED_TAB = {"home", "recent", "mov", "accounts", "rules", "goals", "stats", "budget", "accounts-wallet", "goals-weekend", "goal-result", "accounts-excluded", "accounts-archived", "wallet-result", "transfer-list"}


@lru_cache
def font(size, bold=True):
    name = "SpaceGrotesk-Bold.ttf" if bold else "Inter_18pt-Regular.ttf"
    return ImageFont.truetype(FONTS / name, size)


def lines_for(draw, content, face, maximum):
    lines = []
    for paragraph in content.splitlines():
        line = ""
        for word in paragraph.split():
            proposal = f"{line} {word}".strip()
            if line and draw.textlength(proposal, font=face) > maximum:
                lines.append(line)
                line = word
            else:
                line = proposal
        lines.append(line)
    return lines


def text(im, content, x, y, size, width, *, color=None, bold=True, max_lines=3):
    draw = ImageDraw.Draw(im)
    for actual in range(size, max(19, size - 29), -1):
        face = font(actual, bold)
        lines = lines_for(draw, content, face, width)
        if len(lines) <= max_lines and all(draw.textlength(line, font=face) <= width for line in lines):
            break
    else:
        raise ValueError(f"Testo fuori formato: {content}")
    leading = round(actual * 1.19)
    assert y + len(lines) * leading < im.height - 35, content
    for i, line in enumerate(lines):
        draw.text((x, y + i * leading), line, font=face, fill=color or INK, anchor="lt")
    return y + len(lines) * leading


def rounded(im, image, x, y, radius):
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius, fill=255)
    im.paste(image, (x, y), mask)


@lru_cache
def background(dark, palette):
    paper, _, _, soft, base, upper, lower = palette
    canvas = Image.new("RGB", (108, 135))
    original = palette == PALETTES[0]
    if original and not dark:
        return Image.new("RGB", SIZE, paper)
    start = ImageColor.getrgb(base if dark else paper)
    first = ImageColor.getrgb(upper if dark else "#FFFFFF")
    second = ImageColor.getrgb(lower if dark else soft)
    for y in range(canvas.height):
        for x in range(canvas.width):
            if original:
                top = max(0, 1 - (((x - 100) / 100) ** 2 + (y / 95) ** 2) ** .5)
                bottom = max(0, 1 - ((x / 80) ** 2 + ((y - 135) / 75) ** 2) ** .5)
            else:
                top = max(0, 1 - (((x - 108) / 121) ** 2 + ((y - 3) / 112) ** 2)) ** 1.65
                bottom = max(0, 1 - (((x - 2) / 118) ** 2 + ((y - 137) / 113) ** 2)) ** 2.1
                if not dark:
                    bottom *= .75
            canvas.putpixel((x, y), tuple(
                round(channel + (upper_channel - channel) * top +
                      (lower_channel - channel) * bottom * (1 - top))
                for channel, upper_channel, lower_channel in zip(start, first, second)
            ))
    return canvas.resize(SIZE, Image.Resampling.BICUBIC)


@lru_cache
def screen(key):
    fresh = SCREENS / f"{key}.png"
    source = fresh if fresh.is_file() else FALLBACKS[key]
    with Image.open(source) as image:
        shot = image.convert("RGB").resize((780, 1688), Image.Resampling.LANCZOS)
    if key not in {"shortcuts", "add-options", "add", "expense-example", "transfer-form",
                   "goal-weekend", "goal-update", "account-type", "account-wallet",
                   "ruleedit", "recurrence-following", "recurrence-all"} and not source.stem.endswith("pulita"):
        draw = ImageDraw.Draw(shot)
        for y in range(105, 207):
            draw.line((220, y, 560, y), fill=shot.getpixel((18, y)))
    if key in FIXED_TAB:
        shot = shot.crop((0, 0, 780, 1620))
    return shot


def load_phones():
    phones = {}
    for line in (HERE / "telefoni.txt").read_text().splitlines():
        if line and not line.startswith("#"):
            slide, assets, label = line.split("|")
            phones[tuple(map(int, slide.split(":")))] = (assets, label)
    return phones


def resolve_phone(asset):
    key, section = asset.split(":")
    if (SCREENS / f"{key}.png").is_file() or key in FALLBACKS:
        return key, section
    fallbacks = {
        "account-type": ("account-editor", "top"),
        "account-wallet": ("account-editor", "top"),
        "accounts-wallet": ("accounts", "list"),
        "settings-shortcuts": ("shortcuts", "prompt"),
        "transfer-form": ("mov", "filters"),
        "goal-weekend": ("goal-editor", "top"),
        "goals-weekend": ("goals", "list"),
        "goal-update": ("goals", "list"),
        "goal-result": ("goals-weekend", "list"),
        "accounts-excluded": ("accounts", "list"),
        "accounts-archived": ("accounts", "bottom"),
        "recurrence-following": ("ruleedit", "top"),
        "recurrence-all": ("ruleedit", "top"),
        "wallet-result": ("account-wallet", "form"),
        "transfer-list": ("mov", "filters"),
    }
    return fallbacks[key]


def phone(im, key, center, top, width, max_height, *, peek=False):
    shot = screen(key)
    edge = max(9, width // 38)
    inner = min(width - edge*2, round((max_height-edge*2)*shot.width/shot.height))
    shot = shot.resize((inner, round(shot.height*inner/shot.width)), Image.Resampling.LANCZOS)
    w, h = shot.width+edge*2, shot.height+edge*2
    x = center-w//2
    assert 30 < x and x+w < 1050, (key, x, w)
    assert (top+h > 1350 if peek else top+h < 1245), (key, top, h, peek)
    layer = Image.new("L", im.size)
    ImageDraw.Draw(layer).rounded_rectangle((x,top+14,x+w,top+h+14), w//8, fill=52)
    im.paste("#0D1414", (0,0,*im.size), layer.filter(ImageFilter.GaussianBlur(24)))
    ImageDraw.Draw(im).rounded_rectangle((x,top,x+w,top+h), w//8, fill="#111916", outline="#536360", width=2)
    rounded(im, shot, x+edge, top+edge, w//8-edge)


def panels(im, spec, x, y, width, max_height):
    entries = [piece.split("~", 1) for piece in spec.removeprefix("=").split(";")]
    gap = 16
    cap = {1: 246, 2: 202}.get(len(entries), 172)
    card_h = min(cap, (max_height - gap * (len(entries) - 1)) // len(entries))
    assert card_h >= 115
    d = ImageDraw.Draw(im)
    for i, (label, value) in enumerate(entries):
        yy = y + (card_h + gap) * i
        fill = SOFT if i % 2 == 0 else "#FFFFFF"
        d.rounded_rectangle((x, yy, x + width, yy + card_h), 27, fill=fill)
        compact = width < 460
        inset = 23 if compact else 35
        text(im, label, x + inset, yy + 24, 24 if compact else 27, width - 2 * inset, color=ACCENT, max_lines=1)
        numeric = bool(re.fullmatch(r"[+−-]?[0-9.,]+\s?[%€£]", value))
        size = (48 if numeric else 31) if compact else ((78 if len(entries) < 3 else 54) if numeric else (48 if len(value) < 24 else 38))
        max_lines = 2 if card_h < 160 else 3
        end = text(im, value, x + inset, yy + (57 if compact else 70), size, width - 2 * inset, max_lines=max_lines)
        assert end <= yy + card_h - 5, value


def brand(im, label, index, count, dark=False):
    fill = "#E3EFE7" if dark else ACCENT
    text(im, label, 144, 91, 27, 580, color=fill, max_lines=1)
    text(im, f"{index:02} / {count:02}", 873, 93, 24, 125, color=fill, max_lines=1)
    with Image.open(ROOT / "landing/assets/icon-192.png") as image:
        mark = image.convert("RGBA").resize((46, 46), Image.Resampling.LANCZOS)
    im.paste(mark, (77, 80), mark)


def infographic(im, visual, y):
    draw = ImageDraw.Draw(im)
    if visual.startswith("+"):
        values = [int(value) for value in visual[1:].split(",")]
        for i, value in enumerate(values):
            top = y + 128 * i
            text(im, f"Mese {i + 1}", 98, top, 33, 280, max_lines=1)
            text(im, f"{value} €", 809, top, 39, 175, color=ACCENT, max_lines=1)
            draw.rounded_rectangle((98, top + 56, 983, top + 77), 11, fill=SOFT)
            draw.rounded_rectangle((98, top + 56, 98 + round(885 * value / max(values)), top + 77), 11, fill=ACCENT)
    else:
        for i in range(12):
            x = 80 + (i % 4) * 233
            top = y + (i // 4) * 136
            draw.rounded_rectangle((x, top, x + 212, top + 116), 23, fill=SOFT)
            text(im, f"MESE {i + 1:02}", x + 20, top + 17, 24, 171, color=ACCENT, max_lines=1)
            text(im, "40 €", x + 20, top + 50, 43, 171, max_lines=1)


def frame(label, number, count, palette, dark=False):
    im = background(dark, palette).copy()
    brand(im, label, number, count, dark)
    return im


def refs(reference, visual):
    if reference:
        return [resolve_phone(asset) for asset in reference[0].split("+")]
    return [] if visual.startswith(("=", "+", ":")) else [resolve_phone(visual)]


def diagram(im, visual, end):
    y = max(end+72, 530)
    if visual.startswith("="):
        panels(im, visual, 79, y, 922, 1200-y)
    else:
        infographic(im, visual, y)
    text(im, "Esempio illustrativo", 80, 1245, 25, 900, color=ACCENT, bold=False, max_lines=1)


def body_slide(post, label, number, count, title, body, visual, reference, palette):
    key_in_series = (post["id"], number)
    look = sum(key_in_series) % 4
    im = frame(label, number, count, palette)
    screens = refs(reference, visual)
    is_diagram = visual.startswith(("=", "+", ":"))
    centered = key_in_series in {(3, 3), (6, 5), (8, 3), (11, 4), (13, 4),
                                 (16, 4), (18, 4), (21, 4), (22, 5)} and not is_diagram
    if not screens:
        end = text(im, title, 79, 184, 75, 920, max_lines=3)
        end = text(im, body, 80, end+34, 42, 900, color=MUTED, bold=False, max_lines=4)
        diagram(im, visual, end)
        return im
    # Le schermate che contengono la modalità demo nelle impostazioni
    # entrano dal bordo basso, così rimangono visibili solo le sezioni utili.
    mode_key = screens[0][0]
    peek_settings = mode_key == "settings-lower"
    if len(screens) > 1:
        end = text(im, title, 79, 184, 68, 920, max_lines=2)
        end = text(im, body, 80, end+32, 40, 900, color=MUTED, bold=False, max_lines=4)
        start = max(462, end+35)
        for index, (key, _) in enumerate(screens):
            phone(im, key, 336+index*407, start, 300, 1215-start)
    elif centered:
        end = text(im, title, 79, 184, 75, 920, max_lines=2)
        end = text(im, body, 80, end+34, 42, 900, color=MUTED, bold=False, max_lines=4)
        start = max(461, end+32)
        key, _ = screens[0]
        phone(im, key, 540, start, 450, 1215-start)
    elif peek_settings or (look == 2 and not is_diagram and mode_key in {"home", "stats", "accounts", "mov", "rules", "budget", "goals"} and screens[0][1] in {"top", "hero", "filters"}):
        end = text(im, title, 79, 184, 76, 920, max_lines=2)
        end = text(im, body, 80, end+34, 40, 900, color=MUTED, bold=False, max_lines=4)
        start = max(end+55, 559 if peek_settings else 600)
        key, _ = screens[0]
        phone(im, key, 540, start, 555, 1350, peek=True)
        text(im, "Dati di esempio", 80, start-43, 23, 320, color=ACCENT, max_lines=1)
        return im
    else:
        right = look != 0
        tx = 79 if right else 535
        center = 788 if right else 277
        end = text(im, title, tx, 252, 69, 456, max_lines=4)
        end = text(im, body, tx, end+37, 39, 449, color=MUTED, bold=False, max_lines=7)
        start = 260 if look in (0,1) else 316
        key, _ = screens[0]
        phone(im, key, center, start, 400, 1200-start)
        if is_diagram and visual.startswith("="):
            pos = max(end+44, 670)
            panels(im, visual, tx, pos, 430, 1205-pos)
        if key_in_series in {(12, 3), (12, 5)}:
            text(im, "Anteprima del comando in azione", tx, 1109, 24, 430, color=ACCENT, bold=False, max_lines=2)
    legend = "Esempio illustrativo · schermate con dati dimostrativi" if is_diagram else "Dati di esempio"
    text(im, legend, 80, 1250, 25, 920, color=ACCENT, bold=False, max_lines=1)
    return im


def opener(post, label, count, reference, palette):
    im = frame(label, 1, count, palette, True)
    hero, hook, _, _ = post["editorial"]
    key, _ = refs(reference, post["visual"]+(":full" if not post["visual"].startswith("=") else ""))[0]
    if post["id"] % 3 == 0:
        if post["id"] == 3:
            head, tail = hero.split(", ", 1)
            end = text(im, head + ",", 78, 185, 92, 930, color="#FAFAF4", max_lines=1)
            end = text(im, tail, 78, end, 92, 930, color=AMBER, max_lines=1)
        else:
            end = text(im, hero, 78, 185, 92, 930, color="#FAFAF4", max_lines=3)
        end = text(im, hook, 80, end+33, 40, 900, color=MINT, bold=False, max_lines=4)
        y = max(665,end+68)
        text(im, "Scorri →", 80, y-53, 29, 500, color=AMBER, max_lines=1)
        phone(im, key, 551, y, 547, 1300, peek=True)
    else:
        right = post["id"] % 3 == 1
        x = 79 if right else 547
        end = text(im, hero, x, 240, 80, 450, color="#FAFAF4", max_lines=5)
        end = text(im, hook, x, end+34, 38, 440, color=MINT, bold=False, max_lines=6)
        text(im, "Scorri →", x, end+51, 29, 410, color=AMBER, max_lines=1)
        phone(im, key, 798 if right else 273, 260, 400, 912)
    text(im, "Dati di esempio", 79, 1250, 24, 410, color=MINT, bold=False, max_lines=1)
    return im


def closer(post, label, count, channel, reference, palette):
    im = frame(label, count, count, palette, True)
    cta = "Link in bio" if channel == "Instagram" else "bucktrailapp.com"
    end = text(im, post["editorial"][2], 78, 235, 84, 930, color="#FAFAF4", max_lines=3)
    x = 79
    if reference:
        key, _ = refs(reference, "=")[0]
        base = max(565, end+60)
        phone(im, key, 789, base, 339, 1195-base)
        width = 495
        y = max(620,end+80)
    else:
        width = 913
        y = max(615,end+110)
    y = text(im, "In arrivo su iPhone e Android.", x, y, 45, width, color=MINT, max_lines=2)
    y = text(im, "Iscriviti alla lista d’attesa.", x, y+25, 42, width, color="#F6F8F2", max_lines=2)
    text(im, cta, x, y+29, 38, width, color=AMBER, max_lines=1)
    if post["id"] == 4:
        text(im, "Per i soldi ricevuti, scegli «Entrata».", 79, 1128, 30, 480, color=MINT, max_lines=2)
    if post["id"] in {7, 13, 21}:
        text(im, "4,99 € una volta sola\nPrezzo di lancio previsto", 79, 1046, 31, 490, color=MINT, max_lines=2)
    if reference:
        text(im, "Dati di esempio", 79, 1250, 24, 410, color=MINT, bold=False, max_lines=1)
    return im


def load_posts():
    editorials = {}
    for line in (HERE / "editoriale.txt").read_text().splitlines():
        if line and not line.startswith("#"):
            number, *copy = line.split("|")
            editorials[int(number)] = copy
    posts = []
    for line in (HERE / "scalette.txt").read_text().splitlines():
        if line.startswith("@"):
            number, title, lead, tiktok, visual, tags = line.lstrip("@").split("|")
            posts.append(dict(id=int(number), title=title, lead=lead, tiktok=tiktok, visual=visual, tags=tags.split(), slides=[], editorial=editorials[int(number)]))
        elif line:
            posts[-1]["slides"].append(line.split("|"))
    return posts


SOURCES = (
    "https://buffer.com/resources/when-is-the-best-time-to-post-on-instagram/",
    "https://buffer.com/resources/best-time-to-post-on-tiktok/",
    "https://sproutsocial.com/insights/best-times-to-post-on-tiktok/",
)
IG = ("19:00", "19:00", "12:00", "09:00", "22:00", "21:00", "21:00")
TT = ("13:00", "06:00", "22:00", "13:00", "18:00", "17:00", "09:00")
DAY = ("lunedì", "martedì", "mercoledì", "giovedì", "venerdì", "sabato", "domenica")


def write_instructions(post, count):
    calendar = (ROOT / "calendario-v1.md").read_text()
    pattern = rf"^\| Post-{post['id']} \| (\d{{2}}/\d{{2}}/\d{{4}}) \| (\d)"
    match = re.search(pattern, calendar, re.M)
    assert match, post["id"]
    day = datetime.strptime(match[1], "%d/%m/%Y").weekday()
    later = match[2] == "2"
    double = f" | {match[1]} | 2 |" in calendar
    ig = IG[day]
    if double:
        if day == 1:
            ig = "19:00" if later else "15:00"
        elif day == 3:
            ig = "18:00" if later else "09:00"
    tt = ({1: "22:00", 3: "22:00"}.get(day, TT[day]) if later else TT[day])
    tags = " ".join(f"#{tag}" for tag in dict.fromkeys(["bucktrail", "appfinanze", *post["tags"]]))
    if tags.count("#") < 5:
        tags += " #gestionedenaro"
    assert tags.count("#") in (5, 6)
    _, hook, payoff, caption = post["editorial"]
    takeaways = f"{hook} {caption} {payoff}"
    price = " Prezzo di lancio previsto: 4,99 € una volta sola." if post["id"] in {7, 13, 21} else ""
    content = f"""POST {post['id']:02} — {post['title']}

DATA E ORARI (Europe/Rome)
Data indicativa: {DAY[day]} {match[1]} · slot {match[2]}. Pubblica solo dopo l’ok alla prima serie e dopo aver fissato le date.
Instagram: {ig}
TikTok: {tt}
Esclusi dal piano: domeniche, 24 e 25 dicembre, 1 gennaio. Venerdì e sabato sono più deboli per Instagram nei benchmark; mantienili solo quando serve il ritmo previsto. Su TikTok il sabato è un test, perché gli studi divergono.
Benchmark di partenza per il pubblico italiano, in ora locale. Quando disponibili, dai la precedenza agli Insights di @bucktrailapp. Nelle giornate da due post gli slot sono separati per piattaforma.
Instagram: {SOURCES[0]}
TikTok: {SOURCES[1]}
Confronto TikTok: {SOURCES[2]}

TIKTOK — FOTO / CAROSELLO
Apri Da postare → post-{post['id']} → TikTok. Salva e seleziona le foto da 01.png a {count:02}.png, in quest’ordine. Verifica le miniature, mantieni le proporzioni e usa la slide 01 come copertina.
Titolo da copiare:
{post['editorial'][0]}

Descrizione e hashtag da copiare:
{takeaways}{price}
In arrivo su iPhone e Android. Iscriviti alla lista d’attesa su bucktrailapp.com.
{tags}

INSTAGRAM — POST / CAROSELLO
Apri Da postare → post-{post['id']} → Instagram. Salva e seleziona da 01.png a {count:02}.png. Mantieni il 4:5 e verifica che il titolo della prima slide sia leggibile nel ritaglio profilo. Usa la slide 01 come copertina.
Descrizione e hashtag da copiare:
{post['editorial'][0]}
{takeaways}{price}
In arrivo su iPhone e Android. Iscriviti alla lista d’attesa dal link in bio.
{tags}

DOPO LA PUBBLICAZIONE
Controlla ordine, ritaglio, descrizione e link del profilo. Registra piattaforma, data, ora e link nel diario metriche. Dopo 24 ore rileva visualizzazioni, salvataggi, condivisioni, commenti e visite profilo, quando disponibili.
"""
    (ROOT / f"istruzioni-post/post-{post['id']}.txt").write_text(content)


def main():
    global INK, ACCENT, SOFT
    phones = load_phones()
    supported = 0
    total = 0
    for post in load_posts():
        out = CLIPS / f"post-{post['id']}/pronto"
        out.mkdir(parents=True, exist_ok=True)
        count = len(post["slides"]) + 2
        label = f"BUCKTRAIL  /  {post['title'].upper()}" if post["title"].startswith("Guida:") else "BUCKTRAIL"
        key = post["id"]
        palette = PALETTES[(key-1)//3]
        INK, ACCENT, SOFT = palette[1:4]
        reference = lambda number: phones.get((key, number))
        opener(post, label, count, reference(1), palette).save(out / "slide-01.png", optimize=True)
        shown = int(bool(reference(1)) or not post["visual"].startswith("="))
        for i, (title, body, visual) in enumerate(post["slides"], 2):
            if not reference(i) and visual.startswith(("=", "+", ":")):
                next_visual = post["slides"][i - 1][2] if i < count - 1 else "="
                assert reference(i + 1) or not next_visual.startswith(("=", "+", ":")), (key, i)
            body_slide(post, label, i, count, title, body, visual, reference(i), palette).save(out / f"slide-{i:02}.png", optimize=True)
            shown += int(bool(reference(i)) or not visual.startswith(("=", "+", ":")))
        for channel in ("Instagram", "TikTok"):
            closer(post, label, count, channel, reference(count), palette).save(out / f"slide-{count:02}-{channel.lower()}.png", optimize=True)
        shown += int(bool(reference(count)))
        write_instructions(post, count)
        supported += shown
        total += count
        print(f"Post-{key}: {shown}/{count} con schermata Bucktrail", flush=True)
    assert supported / total > .80
    print(f"Schermate Bucktrail: {supported}/{total} ({supported / total:.1%})")


if __name__ == "__main__":
    main()
