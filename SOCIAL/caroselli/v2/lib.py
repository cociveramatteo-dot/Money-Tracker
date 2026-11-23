#!/usr/bin/env python3
"""Libreria grafica v2 dei caroselli Bucktrail (1080x1350, un solo set per Instagram e TikTok).
HTML/CSS composto da Python e reso con Chrome headless. Sfondi = gradienti esatti delle palette v1."""
import subprocess, shutil, html, hashlib
from pathlib import Path
from functools import lru_cache
from PIL import Image, ImageColor, ImageDraw

ROOT = Path(__file__).resolve().parents[2]          # SOCIAL/
HERE = Path(__file__).parent
WORK = HERE / "_work"                               # file intermedi (non in git)
FONTS = ROOT / "landing/fonts"
SHOTS = ROOT / "schermate-app/v2"                   # catture nuove (simulatore)
LEGACY = ROOT / "schermate-app/prima-serie"         # catture della prima serie
LOGO = ROOT / "landing/assets/icon-192.png"
LANDING = ROOT / "schermate-app/landing-desktop.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Palette v1 invariate: carta, testo, accento, tinta chiara, fondo scuro, sfumatura alta, sfumatura bassa.
PALETTES = {
    1: ("#F0F4FF", "#17274A", "#264BA4", "#DCE7FD", "#111933", "#285BC6", "#212A74"),   # cobalto
    2: ("#FFF4ED", "#421E18", "#A23927", "#FADFCC", "#301919", "#A33D29", "#733025"),   # terracotta
    3: ("#F8F2FF", "#362244", "#74459E", "#EEDFFA", "#25152F", "#7440A4", "#662950"),   # prugna
    4: ("#EEF9F5", "#122F2B", "#197163", "#D4EEE5", "#102A2B", "#007F79", "#244C73"),   # petrolio
    5: ("#FFF8E9", "#392B15", "#81540D", "#F9E9C2", "#2A2016", "#906014", "#734023"),   # ocra
}
AMBER = "#FFC786"
SIZE = (1080, 1350)


@lru_cache
def background(pal, dark):
    out = WORK / f"bg-{pal}-{'dark' if dark else 'light'}.png"
    if out.exists():
        return out
    paper, _, _, soft, base, upper, lower = PALETTES[pal]
    canvas = Image.new("RGB", (108, 135))
    start = ImageColor.getrgb(base if dark else paper)
    first = ImageColor.getrgb(upper if dark else "#FFFFFF")
    second = ImageColor.getrgb(lower if dark else soft)
    for y in range(canvas.height):
        for x in range(canvas.width):
            top = max(0, 1 - (((x - 108) / 121) ** 2 + ((y - 3) / 112) ** 2)) ** 1.65
            bottom = max(0, 1 - (((x - 2) / 118) ** 2 + ((y - 137) / 113) ** 2)) ** 2.1
            if not dark:
                bottom *= .75
            canvas.putpixel((x, y), tuple(
                round(c + (u - c) * top + (l - c) * bottom * (1 - top))
                for c, u, l in zip(start, first, second)))
    WORK.mkdir(exist_ok=True)
    canvas.resize(SIZE, Image.Resampling.BICUBIC).save(out)
    return out


# ---------------------------------------------------------------- schermate
@lru_cache
def screen(name):
    """Restituisce il PNG pulito (senza badge demo) della cattura `name`.
    name: 'v2/home-light' (catture nuove) oppure 'old/rules' (prima serie)."""
    kind, key = name.split("/", 1)
    out = WORK / f"scr-{kind}-{key}.png"
    if out.exists():
        return out
    WORK.mkdir(exist_ok=True)
    src = (SHOTS if kind == "v2" else LEGACY) / f"{key}.png"
    im = Image.open(src).convert("RGB")
    w, h = im.size
    if kind == "old":
        im = _clean_legacy(im)
    else:
        _strip_banner(im)
        im = _unify_status(im)
    im.save(out)
    return out


def _strip_banner(im):
    """Cancella il capsula «MODALITÀ DEMO» (arancio, in alto al centro) copiando il colore di fondo a sinistra."""
    w, h = im.size
    px = im.load()
    xs, ys = [], []
    for y in range(int(h * .08), int(h * .16)):
        for x in range(int(w * .25), int(w * .75), 2):
            r, g, b = px[x, y]
            if r - b > 26 and r >= g:
                xs.append(x); ys.append(y)
    if len(xs) < 30:
        return
    x0, x1, y0, y1 = min(xs) - 34, max(xs) + 34, min(ys) - 30, max(ys) + 46
    d = ImageDraw.Draw(im)
    for y in range(y0, y1 + 1):
        d.line((x0, y, x1, y), fill=px[24, y])


@lru_cache
def _status_mask():
    from PIL import ImageFont  # noqa
    src = ROOT / "clip-social/post-2/materiale/home-pulita.png"
    with Image.open(src) as s:
        n = s.convert("L").resize((780, 1688), Image.Resampling.LANCZOS)
    strip = n.crop((0, 20, 780, 89))
    return strip.point(lambda v: min(255, max(0, round((239 - v) * 255 / 231))))


def _unify_status(im):
    """Barra di stato identica al Post-2 (9:41, segnale, 5G, batteria 59%), chiara o scura a seconda del fondo."""
    shot = im.resize((780, 1688), Image.Resampling.LANCZOS)
    d = ImageDraw.Draw(shot)
    for y in range(20, 89):
        d.line((0, y, 779, y), fill=shot.getpixel((20, y)))
    lum = sum(shot.getpixel((20, 40))) / 3
    shot.paste("#080808" if lum > 128 else "#F4F4F4", (0, 20, 780, 89), _status_mask())
    return shot


def _clean_legacy(im):
    """Catture della prima serie: toglie badge demo e riscrive la barra di stato (9:41, 5G, 59%)."""
    shot = im.resize((780, 1688), Image.Resampling.LANCZOS)
    d = ImageDraw.Draw(shot)
    for y in range(112, 180):
        d.line((220, y, 560, y), fill=shot.getpixel((18, y)))
    for y in range(20, 89):
        d.line((0, y, 779, y), fill=shot.getpixel((20, y)))
    shot.paste("#080808", (0, 20, 780, 89), _status_mask())
    return shot


# ---------------------------------------------------------------- componenti
CSS = """
@font-face{font-family:SG;src:url('FONTS/SpaceGrotesk-Bold.ttf');font-weight:700}
@font-face{font-family:IN;src:url('FONTS/Inter_18pt-Regular.ttf');font-weight:400}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:1080px;height:1350px;overflow:hidden}
.slide{color:var(--fg);position:relative;width:1080px;height:1350px;overflow:hidden;font-family:IN,sans-serif;background-size:cover}
.slide.dark{--fg:#fff;--fg2:rgba(255,255,255,.78);--hi:%(amber)s;--card:rgba(255,255,255,.10);--line:rgba(255,255,255,.22)}
.slide.light{--fg:var(--ink);--fg2:color-mix(in srgb,var(--ink) 72%%,transparent);--hi:var(--accent);--card:#fff;--line:color-mix(in srgb,var(--ink) 16%%,transparent)}
.sg{font-family:SG,sans-serif;font-weight:700;letter-spacing:-.025em}
.top{position:absolute;left:84px;right:110px;top:62px}
.prog{display:flex;gap:7px;height:7px}
.prog i{flex:1;border-radius:4px;background:var(--line)}
.prog i.on{background:var(--fg)}
.brand{display:flex;align-items:center;gap:14px;margin-top:22px;color:var(--fg)}
.brand img{width:46px;height:46px;border-radius:11px}
.brand b{font-family:SG;font-size:27px;letter-spacing:.02em}
.brand span{margin-left:auto;font-family:SG;font-size:23px;letter-spacing:.08em;padding:8px 16px;border-radius:30px;background:var(--card);color:var(--fg)}
.slide.light .brand span{background:var(--soft);color:var(--accent)}
h1,h2{font-family:SG;font-weight:700;letter-spacing:-.03em;color:var(--fg);line-height:1.0}
em{font-style:normal;color:var(--hi)}
p{color:var(--fg2);font-size:40px;line-height:1.34}
p b{color:var(--fg);font-family:SG}
.abs{position:absolute}
.pill{display:inline-flex;align-items:center;gap:12px;font-family:SG;font-size:30px;padding:16px 28px;border-radius:60px;background:var(--hi);color:#161616}
.slide.light .pill{color:#fff}
.chip{display:inline-block;font-family:SG;font-size:28px;padding:12px 22px;border-radius:40px;background:var(--card);color:var(--fg)}
.foot{position:absolute;left:84px;bottom:64px;font-size:22px;color:var(--fg2);opacity:.8}
.card{background:var(--card);border-radius:34px;padding:34px 38px;color:var(--fg)}
.slide.light .card{box-shadow:0 14px 40px rgba(20,30,60,.08)}
.lbl{font-family:SG;font-size:25px;letter-spacing:.09em;color:var(--hi);text-transform:uppercase}
.num{font-family:SG;letter-spacing:-.04em;line-height:1}
.badge{width:72px;height:72px;border-radius:50%%;background:var(--hi);color:#161616;font-family:SG;font-size:38px;display:flex;align-items:center;justify-content:center}
.slide.light .badge{color:#fff}
.tease{font-family:SG;font-size:34px;color:var(--hi);display:flex;align-items:center;gap:12px}
/* telefono */
.phone{position:absolute;background:#0b0c0c;box-shadow:0 0 0 2px #2c3230,0 50px 90px rgba(0,0,0,.38),0 18px 30px rgba(0,0,0,.25)}
.phone img{display:block;width:100%%}
.phone .isl{position:absolute;left:50%%;transform:translateX(-50%%);background:#000;border-radius:50px}
.phone .btn{position:absolute;background:#1b201f;border-radius:3px}
"""


def esc(t):
    return t  # il testo è già HTML (usa <em>, <br>)


def phone(shot, w, x, y, cut=False):
    """iPhone intero verticale (cut=False) o che spunta dal bordo inferiore (cut=True: y è il bordo alto)."""
    b = round(w * .022)
    iw = w - 2 * b
    ih = round(iw * 2622 / 1206)
    h = ih + 2 * b
    r = round(w * .16)
    ri = r - b
    isl_w, isl_h, isl_t = round(iw * .31), round(iw * .092), b + round(iw * .027)
    src = screen(shot)
    return (f'<div class="phone" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;border-radius:{r}px;padding:{b}px">'
            f'<img src="{src}" style="border-radius:{ri}px;width:{iw}px;height:{ih}px">'
            f'<div class="isl" style="width:{isl_w}px;height:{isl_h}px;top:{isl_t}px"></div>'
            f'<div class="btn" style="left:-5px;top:{round(h*.2)}px;width:5px;height:{round(h*.05)}px"></div>'
            f'<div class="btn" style="left:-5px;top:{round(h*.27)}px;width:5px;height:{round(h*.08)}px"></div>'
            f'<div class="btn" style="right:-5px;top:{round(h*.25)}px;width:5px;height:{round(h*.11)}px"></div></div>')


def phone_h(w):
    b = round(w * .022)
    return round((w - 2 * b) * 2622 / 1206) + 2 * b


def laptop(x, y, w):
    ih = round((w - 28) / 1.6)
    return (f'<div class="abs" style="left:{x}px;top:{y}px;width:{w}px">'
            f'<div style="background:#0b0c0c;border-radius:26px 26px 6px 6px;padding:14px 14px 18px;box-shadow:0 0 0 2px #2c3230,0 50px 80px rgba(0,0,0,.35)">'
            f'<img src="{LANDING}" style="display:block;width:100%;border-radius:10px"></div>'
            f'<div style="height:20px;margin:0 -{round(w*.06)}px;background:linear-gradient(#d9dcdb,#9ea3a1);border-radius:0 0 40px 40px;box-shadow:0 22px 30px rgba(0,0,0,.3)"></div></div>')


def header(i, n, tag, ):
    segs = "".join(f'<i class="{"on" if k < i else ""}"></i>' for k in range(n))
    return (f'<div class="top"><div class="prog">{segs}</div><div class="brand">'
            f'<img src="{LOGO}"><b>BUCKTRAIL</b><span>{tag}</span></div></div>')


def wrap(body, pal, dark, bg_extra=""):
    paper, ink, acc, soft, *_ = PALETTES[pal]
    bg = background(pal, dark)
    return (f'<!doctype html><meta charset="utf-8"><style>{CSS.replace("FONTS", str(FONTS)) % {"amber": AMBER}}</style>'
            f'<div class="slide {"dark" if dark else "light"}" style="--ink:{ink};--accent:{acc};--soft:{soft};--paper:{paper};'
            f'background-image:url(\'{bg}\')">{body}</div>')


ICON = {
    "heart": '<path d="M12 21s-7.5-4.6-9.6-9.1C.9 8.6 2.6 5 6 5c2 0 3.2 1 4 2.3C10.8 6 12 5 14 5c3.4 0 5.100 3.600 3.600 6.900C19.500 16.400 12 21 12 21z" transform="translate(1.500 0) scale(.92)"/>',
    "send": '<path d="M21 3 3 10.500l6.500 2.500L12 20l9-17zM9.500 13 21 3"/>',
    "save": '<path d="M6 3h12v18l-6-4.500L6 21z"/>',
    "user": '<circle cx="10" cy="8" r="4"/><path d="M2 21c0-4 3.500-7 8-7s8 3 8 7M19 6v6M16 9h6"/>',
    "arrow": '<path d="M4 12h16M14 6l6 6-6 6"/>',
}


def icon(name, size=44, stroke=2, fill="none"):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="{fill}" stroke="currentColor" '
            f'stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">{ICON[name]}</svg>')


def render(html_text, out_png, key):
    WORK.mkdir(exist_ok=True)
    f = WORK / f"{key}.html"
    f.write_text(html_text)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-sandbox",
                    "--force-device-scale-factor=1", "--window-size=1080,1600", "--virtual-time-budget=2500",
                    f"--screenshot={out_png}", f"file://{f}"], check=True, capture_output=True)
    im = Image.open(out_png).convert("RGB")
    im.crop((0, 0, 1080, 1350)).save(out_png)
    return out_png
