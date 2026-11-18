#!/usr/bin/env python3
"""Carosello di presentazione Bucktrail (4:5, 1080x1350).
Uso (dalla radice del repo): python3 SOCIAL/caroselli/presentazione-v1/build.py
Entrata: SOCIAL/clip-social/IMG_79xx.PNG (screenshot dell'iPhone, fuori da git)
Uscita:  SOCIAL/clip-social/uscite/presentazione-v1/slide-XX.png (fuori da git)
Pulizia screenshot: via il banner «MODALITÀ DEMO», status bar rifatta pulita (9:41)."""
import subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
IN = ROOT / "SOCIAL/clip-social"
OUT = IN / "uscite/presentazione-v1"
WORK = OUT / "_lavoro"
FONTS = ROOT / "SOCIAL/landing/fonts"
ICON = ROOT / "MoneyTracker/Assets.xcassets/AppIcon.appiconset"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WORK.mkdir(parents=True, exist_ok=True)

# (file, titolo, frase, ha_banner_demo)
SLIDES = [
    ("IMG_7914.PNG", "La Home", "La linea tratteggiata dice se arrivi a fine mese", True),
    ("IMG_7915.PNG", "Aggiungi una spesa", "Importo, categoria, conto: fatto", False),
    ("IMG_7916.PNG", "Movimenti", "Tutto ciò che entra ed esce", True),
    ("IMG_7917.PNG", "Ricorrenze", "Salta un mese o termina quando vuoi", False),
    ("IMG_7918.PNG", "Budget", "Avviso all'80%, prima di sforare", True),
    ("IMG_7919.PNG", "Obiettivi", "Metti da parte, un passo alla volta", True),
    ("IMG_7920.PNG", "Statistiche", "Capisci dove vanno i soldi", True),
]

def pulisci(nome, banner):
    im = Image.open(IN / nome).convert("RGB")
    d = ImageDraw.Draw(im)
    for y in range(0, 136):                          # via la status bar vera
        d.line([(0, y), (im.width, y)], fill=im.getpixel((600, y)))
    if banner:                                       # via «MODALITÀ DEMO» (+ ombra)
        for y in range(136, 258):                    # riga per riga: fondo continuo
            d.line([(300, y), (880, y)], fill=im.getpixel((10, y)))
    f = ImageFont.truetype(str(FONTS / "SpaceGrotesk-Bold.ttf"), 54)
    d.text((88, 80), "9:41", font=f, fill=(17, 17, 17), anchor="lm")
    d.rounded_rectangle([465, 46, 705, 112], radius=33, fill=(8, 8, 8))   # isola
    for i, h in enumerate((16, 24, 32, 40)):                                # segnale
        d.rounded_rectangle([862 + i * 17, 100 - h, 874 + i * 17, 100], radius=4, fill=(17, 17, 17))
    d.rounded_rectangle([945, 62, 1040, 98], radius=11, outline=(17, 17, 17), width=4)
    d.rounded_rectangle([951, 68, 1030, 92], radius=6, fill=(17, 17, 17))
    d.rounded_rectangle([1046, 72, 1054, 88], radius=3, fill=(17, 17, 17))
    p = WORK / ("pulito-" + nome.lower())
    im.save(p)
    return p

CSS = f"""
@font-face{{font-family:SG;src:url('file://{FONTS}/SpaceGrotesk-Bold.ttf');font-weight:700}}
@font-face{{font-family:IN;src:url('file://{FONTS}/Inter_18pt-Regular.ttf')}}
*{{box-sizing:border-box;margin:0}}
body{{width:1080px;height:1350px;background:#F6F6F2;position:relative;overflow:hidden;font-family:IN}}
.meta{{position:absolute;top:52px;left:64px;right:64px;display:flex;justify-content:space-between;font-size:26px;color:#8a8f8c}}
h1{{position:absolute;top:120px;left:64px;right:64px;font-family:SG;font-weight:700;font-size:96px;line-height:1.02;color:#121614;letter-spacing:-2px}}
p.f{{position:absolute;top:250px;left:64px;width:900px;text-wrap:balance;font-size:46px;line-height:1.25;color:#3c423f}}
.phone{{position:absolute;left:50%;transform:translateX(-50%);top:480px;width:650px;height:1200px;border-radius:100px;background:#0b0e0d;padding:15px;box-shadow:0 30px 80px rgba(0,0,0,.18)}}
.phone img{{width:100%;display:block;border-radius:86px 86px 0 0}}
.c{{text-align:center}}
.logo{{width:190px;height:190px;border-radius:44px;box-shadow:0 14px 40px rgba(0,0,0,.15)}}
"""

def html(corpo):
    return f"<!doctype html><meta charset=utf-8><style>{CSS}</style><body>{corpo}</body>"

def slide_app(n, tot, img, titolo, frase):
    return html(f"""<div class=meta><span>{n:02d} / {tot:02d}</span><span>Dati di esempio</span></div>
<h1>{titolo}</h1><p class=f>{frase}</p>
<div class=phone><img src="file://{img}"></div>""")

def slide_titolo(tot):
    return html(f"""<div class=meta><span>01 / {tot:02d}</span><span></span></div>
<div class=c style="position:absolute;top:250px;left:0;right:0">
<img class=logo src="file://{ICON}/AppIcon_light_1024.png"
 onerror="this.style.display='none'">
<h1 style="position:static;margin:60px 70px 0;font-size:112px">Bucktrail: il budget senza abbonamenti</h1>
<p class=f style="position:static;width:auto;margin-top:40px;font-size:48px;color:#3c423f">Il giro completo dell'app</p></div>
<svg style="position:absolute;left:0;bottom:120px" width=1080 height=200 viewBox="0 0 1080 200">
<path d="M60 120 L330 150 L560 110" stroke="#2CB98A" stroke-width="10" fill="none" stroke-linecap="round"/>
<circle cx=560 cy=110 r=16 fill="#2CB98A"/>
<path d="M560 110 L1010 60" stroke="#F0A050" stroke-width="10" stroke-dasharray="2 26" stroke-linecap="round" fill="none"/>
<circle cx=1010 cy=60 r=16 fill="#F0A050"/></svg>""")

def slide_fine(tot, tiktok):
    riga = "Lista d'attesa: bucktrailapp.com" if tiktok else "Lista d'attesa: link in bio"
    return html(f"""<div class=meta><span>{tot:02d} / {tot:02d}</span><span></span></div>
<div class=c style="position:absolute;top:300px;left:0;right:0">
<img class=logo src="file://{ICON}/AppIcon_light_1024.png" onerror="this.style.display='none'">
<h1 style="position:static;margin:60px 70px 0;font-size:104px">Seguici per altro</h1>
<p class=f style="position:static;width:auto;margin-top:50px;font-size:54px;color:#121614">{riga}</p>
<p class=f style="position:static;width:auto;margin-top:36px;font-size:54px;color:#1E7F4F">4,99 € una volta</p>
<p class=f style="position:static;width:auto;margin-top:6px;font-size:30px;color:#8a8f8c">prezzo di lancio previsto</p></div>""")

def render(corpo, out):
    h = WORK / (out.stem + ".html")
    h.write_text(corpo, encoding="utf-8")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--window-size=1080,1350",
                    "--virtual-time-budget=3000", f"--screenshot={out}", f"file://{h}"],
                   check=True, capture_output=True)

if __name__ == "__main__":
    tot = len(SLIDES) + 2
    render(slide_titolo(tot), OUT / "slide-01.png")
    for i, (f, t, fr, b) in enumerate(SLIDES, start=2):
        render(slide_app(i, tot, pulisci(f, b), t, fr), OUT / f"slide-{i:02d}.png")
    render(slide_fine(tot, False), OUT / f"slide-{tot:02d}-instagram.png")
    render(slide_fine(tot, True), OUT / f"slide-{tot:02d}-tiktok.png")
    print("ok", sorted(p.name for p in OUT.glob("slide-*.png")))
