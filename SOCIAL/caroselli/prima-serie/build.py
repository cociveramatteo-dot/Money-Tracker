#!/usr/bin/env python3
"""Compone i caroselli e le istruzioni della prima serie Bucktrail."""
from datetime import datetime
from pathlib import Path
import re
from functools import lru_cache

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "landing/fonts"
CLIPS = ROOT / "clip-social"
SCREENS = ROOT / "schermate-app/prima-serie"
HERE = Path(__file__).parent
PAPER = "#F6F6F2"
INK = "#182922"
GREEN = "#21604A"
MUTED = "#455B50"
MINT = "#B8EAD1"
AMBER = "#FFC786"
SIZE = (1080, 1350)

# Limiti di ritaglio riferiti alle catture normalizzate (UI, non al mockup).
CROPS = {
    "top": (.13, .45), "hero": (.12, .50), "curve": (.20, .47),
    "accounts": (.44, .66), "fixed": (.60, .85), "bottom": (.65, .95),
    "recent": (.39, .77), "list": (.29, .77), "planned": (.20, .61),
    "daily": (.44, .80), "filters": (.13, .37), "form": (.14, .62),
    "chart": (.38, .64), "categories": (.65, .90), "prompt": (.08, .37),
    "choice": (.174, .278), "currency": (.52, .66), "shortcut": (.66, .91),
    "options": (.665, .956),
}
FOCUSED_CROPS = {
    ("home", "top"): (.125, .20), ("home", "hero"): (.12, .515),
    ("home", "curve"): (.196, .516), ("home", "accounts"): (.54, .69),
    ("home", "fixed"): (.705, .84), ("home", "bottom"): (.70, .98),
    ("recent", "recent"): (.418, .80),
    ("mov", "planned"): (.357, .663), ("mov", "daily"): (.68, .80),
    ("mov", "filters"): (.12, .351),
    ("accounts", "hero"): (.115, .36), ("accounts", "list"): (.375, .79),
    ("accounts", "bottom"): (.665, .98),
    ("rules", "top"): (.122, .564), ("ruleedit", "top"): (.145, .385),
    ("settings", "top"): (.245, .647),
    ("budget", "top"): (.109, .282), ("budget", "list"): (.295, .775),
    ("goals", "top"): (.11, .245), ("goals", "list"): (.247, .81),
    ("stats", "hero"): (.113, .293),
    ("expense-example", "form"): (.174, .56), ("expense-example", "top"): (.172, .51),
    ("account-editor", "top"): (.65, .992), ("goal-editor", "top"): (.59, .99),
    ("settings", "bottom"): (.699, .941), ("settings-lower", "list"): (.471, .833),
    ("settings-shortcuts", "shortcut"): (.361, .605),
    ("account-type", "form"): (.174, .553), ("account-wallet", "form"): (.228, .488),
    ("goal-weekend", "form"): (.384, .663), ("transfer-form", "form"): (.394, .682),
    ("goals-weekend", "list"): (.502, .684), ("accounts-wallet", "list"): (.35, .81),
    ("goal-update", "form"): (.400, .665), ("goal-result", "list"): (.54, .691),
    ("accounts-excluded", "list"): (.558, .663),
    ("accounts-archived", "bottom"): (.508, .746),
    ("recurrence-following", "top"): (.162, .423), ("recurrence-all", "top"): (.162, .423),
    ("wallet-result", "list"): (.589, .725), ("transfer-list", "daily"): (.245, .553),
    ("add-options", "form"): (.42, .96), ("budget", "bottom"): (.755, .979),
    ("goals", "bottom"): (.755, .979),
}

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


def text(im, content, x, y, size, width, *, color=INK, bold=True, max_lines=3):
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
        draw.text((x, y + i * leading), line, font=face, fill=color, anchor="lt")
    return y + len(lines) * leading


def rounded(im, image, x, y, radius):
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius, fill=255)
    im.paste(image, (x, y), mask)


@lru_cache
def background(dark):
    if not dark:
        return Image.new("RGB", SIZE, PAPER)
    im = Image.new("RGB", (108, 135))
    pixels = im.load()
    for y in range(im.height):
        for x in range(im.width):
            glow = max(0, 1 - (((x - 105) / 99) ** 2 + (y / 98) ** 2) ** .5)
            ember = max(0, 1 - ((x / 88) ** 2 + ((y - 134) / 70) ** 2) ** .5)
            pixels[x, y] = (13 + int(35 * ember), 19 + int(38 * glow + 16 * ember), 16 + int(23 * glow))
    return im.resize(SIZE, Image.Resampling.BICUBIC)


@lru_cache
def screen(key):
    fresh = SCREENS / f"{key}.png"
    source = fresh if fresh.is_file() else FALLBACKS[key]
    with Image.open(source) as image:
        shot = image.convert("RGB").resize((780, 1688), Image.Resampling.LANCZOS)
    if key in FIXED_TAB:
        # Il badge è sovrapposto al centro della fascia superiore in demo.
        # Campioniamo la stessa fascia fuori dal badge senza alterare il contenuto.
        if not source.stem.endswith("pulita"):
            draw = ImageDraw.Draw(shot)
            for y in range(105, 207):
                draw.line((220, y, 560, y), fill=shot.getpixel((18, y)))
        if not source.stem.endswith("pulita"):
            with Image.open(FALLBACKS["home"]) as status_source:
                status_bar = status_source.convert("RGB").resize((780, 1688), Image.Resampling.LANCZOS)
                shot.paste(status_bar.crop((0, 0, 780, 91)), (0, 0))
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
    key, crop = asset.split(":")
    if (SCREENS / f"{key}.png").is_file() or key in FALLBACKS:
        return key, None if crop == "full" else crop
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


def show_reference(im, reference, x, width, start, max_height, *, dark=False):
    visual, label = reference
    ink = MINT if dark else GREEN
    parts = visual.split("+")
    y = start
    for asset in parts:
        key, crop = resolve_phone(asset)
        box = phone(im, key, x, y, width, min(max_height, 435) if len(parts) > 1 else max_height, crop)
        y = box[3] + 32
    text(im, label, x + 8, min(y, 1190), 23, width - 15, color=ink, max_lines=2)


def box_shadow(im, box, radius):
    mask = Image.new("L", im.size)
    x, y, xx, yy = box
    ImageDraw.Draw(mask).rounded_rectangle((x, y + 15, xx, yy + 15), radius, fill=56)
    im.paste("#08150D", (0, 0, *im.size), mask.filter(ImageFilter.GaussianBlur(21)))


def phone(im, key, x, y, width, max_height, crop=None):
    shot = screen(key)
    if crop:
        first, last = FOCUSED_CROPS.get((key, crop), CROPS[crop])
        shot = shot.crop((12, round(first * shot.height), shot.width - 12, round(last * shot.height)))
    shot.thumbnail((width - 18, max_height - 18), Image.Resampling.LANCZOS)
    if shot.width < width - 18 and shot.height < max_height - 18:
        factor = min((width - 18) / shot.width, (max_height - 18) / shot.height)
        shot = shot.resize((round(shot.width * factor), round(shot.height * factor)), Image.Resampling.LANCZOS)
    w, h = shot.width + 18, shot.height + 18
    x += (width - w) // 2
    r = 31 if crop else 45
    box = (x, y, x + w, y + h)
    assert box[2] <= 1010 and box[3] <= 1230, (key, box)
    box_shadow(im, box, r)
    draw = ImageDraw.Draw(im)
    if crop and h > 150:
        # Piccoli pulsanti laterali sulla cornice del mockup, fuori dal contenuto.
        draw.rounded_rectangle((x - 3, y + 32, x + 3, y + 65), 3, fill="#33443A")
        draw.rounded_rectangle((x + w - 3, y + 46, x + w + 3, y + 88), 3, fill="#33443A")
    draw.rounded_rectangle(box, r, fill="#111A15")
    rounded(im, shot, x + 9, y + 9, r - 9)
    if key == "goal-update" and crop == "form":
        top = y + 9 + round(shot.height * .63)
        draw.rounded_rectangle((x + 26, top, x + round(w * .51), y + h - 16), 14, outline=GREEN, width=4)
    return box


def panels(im, spec, x, y, width, max_height):
    entries = [piece.split("~", 1) for piece in spec.removeprefix("=").split(";")]
    gap = 16
    cap = {1: 246, 2: 202}.get(len(entries), 172)
    card_h = min(cap, (max_height - gap * (len(entries) - 1)) // len(entries))
    assert card_h >= 115
    d = ImageDraw.Draw(im)
    for i, (label, value) in enumerate(entries):
        yy = y + (card_h + gap) * i
        fill = "#E4F0E7" if i % 2 == 0 else "#F1E7D9"
        d.rounded_rectangle((x, yy, x + width, yy + card_h), 27, fill=fill)
        compact = width < 460
        inset = 23 if compact else 35
        text(im, label, x + inset, yy + 24, 24 if compact else 27, width - 2 * inset, color=GREEN, max_lines=1)
        numeric = bool(re.fullmatch(r"[+−-]?[0-9.,]+\s?[%€£]", value))
        size = (48 if numeric else 31) if compact else ((78 if len(entries) < 3 else 54) if numeric else (48 if len(value) < 24 else 38))
        max_lines = 2 if card_h < 160 else 3
        end = text(im, value, x + inset, yy + (57 if compact else 70), size, width - 2 * inset, max_lines=max_lines)
        assert end <= yy + card_h - 5, value


def brand(im, label, index, count, dark=False):
    fill = "#E3EFE7" if dark else GREEN
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
            text(im, f"{value} €", 809, top, 39, 175, color=GREEN, max_lines=1)
            draw.rounded_rectangle((98, top + 56, 983, top + 77), 11, fill="#DFE7E0")
            draw.rounded_rectangle((98, top + 56, 98 + round(885 * value / max(values)), top + 77), 11, fill=GREEN)
    else:
        for i in range(12):
            x = 80 + (i % 4) * 233
            top = y + (i // 4) * 136
            draw.rounded_rectangle((x, top, x + 212, top + 116), 23, fill="#E4F0E7")
            text(im, f"MESE {i + 1:02}", x + 20, top + 17, 24, 171, color=GREEN, max_lines=1)
            text(im, "40 €", x + 20, top + 50, 43, 171, max_lines=1)


def body_slide(label, number, count, title, body, visual, reference):
    im = background(False).copy()
    brand(im, label, number, count)
    if reference and visual.startswith(("=", "+", ":")):
        end = text(im, title, 79, 184, 67, 924, max_lines=2)
        end = text(im, body, 80, end + 45, 38, 910, color=MUTED, bold=False, max_lines=3)
        start = max(end + 50, 532)
        if visual.startswith("="):
            panels(im, visual, 79, start, 393, 1160 - start)
        else:
            raise ValueError("Grafici composti da impaginare separatamente.")
        show_reference(im, reference, 505, 500, start, 1160 - start)
        text(im, "Esempio a sinistra · schermata Bucktrail a destra", 79, 1250, 25, 905, color=MUTED, bold=False, max_lines=1)
    elif visual.startswith(("=", "+", ":")):
        end = text(im, title, 79, 200, 75, 915, max_lines=2)
        end = text(im, body, 79, end + 40, 39, 905, color=MUTED, bold=False, max_lines=4)
        y = max(end + 82, 563)
        if visual.startswith("="):
            panels(im, visual, 79, y, 922, 1190 - y)
        else:
            infographic(im, visual, y)
        legend = "Dati di esempio · schema illustrativo" if not visual.startswith("=") or re.search(r"[€£]|[0-9]%", visual) else "Schema illustrativo"
        text(im, legend, 79, 1250, 25, 800, color=MUTED, bold=False, max_lines=1)
    else:
        key, crop = visual.split(":")
        if crop == "full":
            bottom = text(im, title, 79, 263, 70, 490, max_lines=3)
            text(im, body, 79, bottom + 46, 40, 485, color=MUTED, bold=False, max_lines=6)
            phone(im, key, 590, 235, 400, 915)
        else:
            end = text(im, title, 79, 190, 75, 925, max_lines=2)
            end = text(im, body, 79, end + 38, 39, 910, color=MUTED, bold=False, max_lines=4)
            y = max(555, end + 55)
            phone(im, key, 100, y, 880, 1200 - y, crop)
        text(im, "Dati di esempio", 79, 1250, 25, 800, color=MUTED, bold=False, max_lines=1)
    return im


def opener(post, label, count, reference):
    im = background(True).copy()
    brand(im, label, 1, count, True)
    title, body, visual = post["title"], post["lead"], post["visual"]
    if visual.startswith("=") and reference:
        end = text(im, title, 79, 230, 74, 910, color="#FAFAF4", max_lines=3)
        end = text(im, body, 79, end + 35, 39, 885, color="#D9E9DF", bold=False, max_lines=3)
        y = max(end + 65, 655)
        panels(im, visual, 79, y, 393, 1130 - y)
        show_reference(im, reference, 504, 500, y, 1150 - y, dark=True)
    elif visual.startswith("="):
        end = text(im, title, 80, 245, 103, 915, color="#FAFAF4", max_lines=3)
        end = text(im, body, 80, end + 39, 43, 875, color="#E1EEE5", bold=False, max_lines=3)
        panels(im, visual, 80, max(end + 100, 790), 880, 305)
    else:
        end = text(im, title, 79, 268, 83, 505, color="#FAFAF4", max_lines=4)
        text(im, body, 79, end + 44, 39, 490, color="#D9E9DF", bold=False, max_lines=5)
        crop = "top" if visual in {"settings", "ruleedit", "shortcuts", "add", "account-editor", "goal-editor", "expense-example"} else None
        if visual == "shortcuts":
            crop = "prompt"
        phone(im, visual, 590, 245 if not crop else 420, 415, 920 if not crop else 525, crop)
    legend = "Esempio a sinistra · app a destra" if visual.startswith("=") and reference else "Dati di esempio"
    text(im, legend, 81, 1250, 25, 600, color=MINT, bold=False, max_lines=1)
    text(im, "Scorri →", 865, 1250, 26, 135, color=MINT, max_lines=1)
    return im


def closer(post, label, count, channel, reference):
    im = background(True).copy()
    brand(im, label, count, count, True)
    headlines = {
        4: "Dalla spesa all’entrata.",
        5: "Controlla prima della prossima cena.",
        8: "Saldo in Home. Netto in Statistiche.",
        11: "Quale spesa annuale prepari oggi?",
        12: "Salva i passaggi per il tuo iPhone.",
        18: "Guarda cosa ha mosso la media.",
        21: "Quale ti serve oggi?",
    }
    headline = headlines.get(post["id"], "Salva questa guida." if post["title"].startswith("Guida:") else "Salva il post per dopo.")
    text(im, headline, 78, 255 if reference else 338, 82 if reference else 89, 920, color="#FAFAF4", max_lines=2)
    column = 428 if reference else 920
    text(im, "In arrivo su iPhone e Android.", 78, 637, 50, column, color=MINT, max_lines=2)
    text(im, "Iscriviti alla lista d’attesa.", 78, 771 if reference else 747, 43, column, color="#F6F8F2", max_lines=2)
    cta = "Link in bio" if channel == "Instagram" else "bucktrailapp.com"
    text(im, cta, 78, 908 if reference else 844, 39, column, color=AMBER, max_lines=1)
    if reference:
        show_reference(im, reference, 520, 485, 580, 510, dark=True)
        text(im, "Dati di esempio", 79, 1220, 24, 400, color=MINT, bold=False, max_lines=1)
    if post["id"] == 12:
        text(im, "Tutorial iPhone", 80, 1125, 30, 900, color=MINT, max_lines=1)
    elif post["id"] == 4:
        text(im, "Per i soldi ricevuti, scegli «Entrata».", 80, 1080, 35, 915, color=MINT, max_lines=2)
    return im


def load_posts():
    posts = []
    for line in (HERE / "scalette.txt").read_text().splitlines():
        if line.startswith("@"):
            number, title, lead, tiktok, visual, tags = line.lstrip("@").split("|")
            posts.append(dict(id=int(number), title=title, lead=lead, tiktok=tiktok, visual=visual, tags=tags.split(), slides=[]))
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
    takeaways = " ".join(slide[1] for slide in post["slides"][:2])
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
{post['tiktok']}

Descrizione e hashtag da copiare:
{post['lead']} {takeaways}
In arrivo su iPhone e Android. Iscriviti alla lista d’attesa su bucktrailapp.com.
{tags}

INSTAGRAM — POST / CAROSELLO
Apri Da postare → post-{post['id']} → Instagram. Salva e seleziona da 01.png a {count:02}.png. Mantieni il 4:5 e verifica che il titolo della prima slide sia leggibile nel ritaglio profilo. Usa la slide 01 come copertina.
Descrizione e hashtag da copiare:
{post['title']}
{takeaways}
In arrivo su iPhone e Android. Iscriviti alla lista d’attesa dal link in bio.
{tags}

DOPO LA PUBBLICAZIONE
Controlla ordine, ritaglio, descrizione e link del profilo. Registra piattaforma, data, ora e link nel diario metriche. Dopo 24 ore rileva visualizzazioni, salvataggi, condivisioni, commenti e visite profilo, quando disponibili.
"""
    (ROOT / f"istruzioni-post/post-{post['id']}.txt").write_text(content)


def main():
    phones = load_phones()
    supported = 0
    total = 0
    for post in load_posts():
        out = CLIPS / f"post-{post['id']}/pronto"
        out.mkdir(parents=True, exist_ok=True)
        count = len(post["slides"]) + 2
        label = "BUCKTRAIL  /  GUIDA" if post["title"].startswith("Guida:") else "BUCKTRAIL"
        key = post["id"]
        reference = lambda number: phones.get((key, number))
        opener(post, label, count, reference(1)).save(out / "slide-01.png", optimize=True)
        shown = int(bool(reference(1)) or not post["visual"].startswith("="))
        for i, (title, body, visual) in enumerate(post["slides"], 2):
            if not reference(i) and visual.startswith(("=", "+", ":")):
                next_visual = post["slides"][i - 1][2] if i < count - 1 else "="
                assert reference(i + 1) or not next_visual.startswith(("=", "+", ":")), (key, i)
            body_slide(label, i, count, title, body, visual, reference(i)).save(out / f"slide-{i:02}.png", optimize=True)
            shown += int(bool(reference(i)) or not visual.startswith(("=", "+", ":")))
        for channel in ("Instagram", "TikTok"):
            closer(post, label, count, channel, reference(count)).save(out / f"slide-{count:02}-{channel.lower()}.png", optimize=True)
        shown += int(bool(reference(count)))
        write_instructions(post, count)
        supported += shown
        total += count
        print(f"Post-{key}: {shown}/{count} con schermata Bucktrail", flush=True)
    assert supported / total > .80
    print(f"Schermate Bucktrail: {supported}/{total} ({supported / total:.1%})")


if __name__ == "__main__":
    main()
