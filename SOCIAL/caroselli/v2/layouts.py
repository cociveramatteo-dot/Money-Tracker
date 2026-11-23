"""Layout riusabili delle slide v2. Ogni funzione restituisce (dark, body_html)."""
from lib import phone, phone_h, laptop, icon, LOGO

def col(inner, top=190, left=84, w=886):
    return f'<div class="abs" style="left:{left}px;top:{top}px;width:{w}px">{inner}</div>'

def H(t, size=96, mb=26):
    return f'<h1 style="font-size:{size}px;margin-bottom:{mb}px">{t}</h1>'

def P(t, size=40, mb=0, w=None):
    ww = f"max-width:{w}px;" if w else ""
    return f'<p style="font-size:{size}px;margin-bottom:{mb}px;{ww}">{t}</p>'

DE = '<div style="font-size:23px;opacity:.7;margin-top:26px;color:var(--fg2)">Dati di esempio</div>'

def tease(t):
    return f'<div class="tease">{t} {icon("arrow", 38, 2.6)}</div>'

def lbl(t, mb=22):
    return f'<div class="lbl" style="margin-bottom:{mb}px">{t}</div>'

# ------------------------------------------------------------------ con telefono
def hook(dark, kicker, title, sub, shot, size=120, ph_w=640, ph_x=370, ph_y=830, sub_size=42, top=205):
    return dark, (col(lbl(kicker) + H(title, size, 26) + P(sub, sub_size) + DE, top)
                  + phone(shot, ph_w, ph_x, ph_y, cut=True)
                  + '<div class="abs" style="left:84px;top:1100px"><div class="pill" style="font-size:30px;padding:14px 26px">Scorri ' + icon('arrow', 30, 2.8) + '</div></div>')

def side(dark, title, body, shot, right=True, size=80, ph_w=440, ph_y=190, badge=None, text_w=None, body_size=38, extra="", top=210, nxt=None):
    px = 1080 - 84 - ph_w + 14 if right else 70
    tx = 84 if right else 70 + ph_w + 50
    if text_w is None:
        text_w = 450 if right else 410
    if not right:
        size = min(size, 70)
    b = f'<div class="badge" style="margin-bottom:34px">{badge}</div>' if badge else ""
    n = col(tease(nxt), 1070, tx, text_w) if nxt else ''
    return dark, (col(b + H(title, size, 28) + P(body, body_size) + extra, top, tx, text_w) + n
                  + phone(shot, ph_w, px, ph_y))

def peek(dark, title, body, shot, size=84, ph_w=700, ph_y=640, ph_x=190, body_size=40, extra="", top=190):
    return dark, (col(H(title, size, 22) + P(body, body_size) + extra + DE, top, 84, 886)
                  + phone(shot, ph_w, ph_x, ph_y, cut=True))

def duo(dark, title, body, shot_a, shot_b, size=66, ph_w=320, y_a=520, y_b=450, body_size=34, labels=None, top=185):
    out = col(H(title, size, 14) + P(body, body_size), top, 84, 886)
    out += phone(shot_a, ph_w, 130, y_a) + phone(shot_b, ph_w, 1080 - 130 - ph_w, y_b)
    if labels:
        out += (f'<div class="abs sg" style="left:130px;top:{y_a-58}px;width:{ph_w}px;font-size:30px;text-align:center;color:var(--hi)">{labels[0]}</div>'
                f'<div class="abs sg" style="left:{1080-130-ph_w}px;top:{y_b-58}px;width:{ph_w}px;font-size:30px;text-align:center;color:var(--hi)">{labels[1]}</div>')
    return dark, out

# ------------------------------------------------------------------ concetti
def concept(dark, title, inner, size=88, body=None, top=190, inner_top=None):
    out = col(H(title, size, 24) + (P(body, 40) if body else ""), top)
    return dark, out + (inner if inner_top is None else col(inner, inner_top))

def bars(items, hi=None, top=560, h=420, unit="€", w=886, line=None):
    mx = max(v for _, v in items)
    n = len(items)
    gap = 26
    bw = (w - gap * (n - 1)) // n
    cols = ""
    for i, (lab, v) in enumerate(items):
        bh = round(h * v / mx)
        on = hi is None or i in hi
        bg = "var(--hi)" if on else "var(--line)"
        cols += (f'<div style="width:{bw}px;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:{h+60}px">'
                 f'<div class="num" style="font-size:42px;color:var(--fg);margin-bottom:12px">{v} {unit}</div>'
                 f'<div style="width:100%;height:{bh}px;background:{bg};border-radius:22px 22px 8px 8px"></div></div>')
    labs = "".join(f'<div style="width:{bw}px;text-align:center;font-size:30px;color:var(--fg2)">{l}</div>' for l, _ in items)
    return col(f'<div style="display:flex;gap:{gap}px;align-items:flex-end">{cols}</div>'
               f'<div style="display:flex;gap:{gap}px;margin-top:16px">{labs}</div>', top, 84, w)

def equation(parts, top=620, size=150):
    """parts: lista di (testo, tipo) tipo in 'n' numero, 'op' operatore, 'res' risultato; testo piccolo sotto con '|'."""
    cells = ""
    for t, k in parts:
        if k == "op":
            cells += f'<div class="num" style="font-size:{size*0.55}px;color:var(--fg2);padding:{size*0.2}px 4px 0">{t}</div>'
        else:
            big, _, small = t.partition("|")
            c = "var(--hi)" if k == "res" else "var(--fg)"
            cells += (f'<div style="text-align:center;white-space:nowrap"><div class="num" style="font-size:{size}px;color:{c}">{big}</div>'
                      f'<div style="font-size:30px;color:var(--fg2);margin-top:14px">{small}</div></div>')
    return col(f'<div style="display:flex;align-items:flex-start;justify-content:space-between">{cells}</div>', top, 84, 886)

def cards(items, top=520, cols=1, gap=22, h=None, w=886):
    """items: (titolo, testo, etichetta_colore opz.)"""
    cw = (w - gap * (cols - 1)) // cols
    out = ""
    for it in items:
        t, b = it[0], it[1]
        tag = f'<div class="lbl" style="margin-bottom:10px;font-size:23px">{it[2]}</div>' if len(it) > 2 else ""
        hh = f"min-height:{h}px;" if h else ""
        out += (f'<div class="card" style="width:{cw}px;{hh}">{tag}<div class="sg" style="font-size:44px;margin-bottom:10px;line-height:1.05">{t}</div>'
                f'<div style="font-size:33px;line-height:1.3;color:var(--fg2)">{b}</div></div>')
    return col(f'<div style="display:flex;flex-wrap:wrap;gap:{gap}px">{out}</div>', top, 84, w)

def steps(items, top=470, gap=34, size=40):
    out = ""
    for i, it in enumerate(items, 1):
        t, _, b = it.partition("|")
        sub = f'<div style="font-size:34px;color:var(--fg2);margin-top:6px;line-height:1.25">{b}</div>' if b else ""
        out += (f'<div style="display:flex;gap:28px;align-items:flex-start;margin-bottom:{gap}px">'
                f'<div class="badge" style="flex:none">{i}</div><div><div class="sg" style="font-size:{size}px;line-height:1.1;margin-top:8px">{t}</div>{sub}</div></div>')
    return col(out, top, 84, 886)

def progress(pct, label_l, label_r, top=700, big=None):
    return col((f'<div class="num" style="font-size:210px;color:var(--hi);margin-bottom:30px">{big}</div>' if big else "") +
               f'<div style="height:54px;border-radius:30px;background:var(--line);overflow:hidden"><div style="width:{pct}%;height:100%;background:var(--hi);border-radius:30px"></div></div>'
               f'<div style="display:flex;justify-content:space-between;margin-top:18px;font-size:36px;color:var(--fg2)"><span>{label_l}</span><span>{label_r}</span></div>', top)

# ------------------------------------------------------------------ chiusura
def final(dark, shot):
    out = col('<div class="lbl" style="margin-bottom:16px">Presto su</div><h1 style="font-size:116px;line-height:.94">iOS e Android<em>.</em></h1>', 178, 84, 886)
    out += '<div class="abs" style="left:84px;top:392px"><div class="pill" style="font-size:38px;padding:20px 38px">bucktrailapp.com</div></div>'
    out += laptop(300, 520, 690)
    out += phone(shot, 270, 84, 500)
    ic = lambda n, t: (f'<div style="text-align:center;width:130px"><div style="width:84px;height:84px;margin:0 auto 8px;border-radius:50%;background:var(--card);'
                       f'display:flex;align-items:center;justify-content:center;color:var(--fg)">{icon(n, 40, 2)}</div><div style="font-size:25px;color:var(--fg)">{t}</div></div>')
    out += (f'<div class="abs" style="left:84px;top:1090px;width:886px;display:flex;justify-content:space-between;align-items:center">'
            f'<div style="width:290px;font-family:SG;font-size:32px;line-height:1.12;color:var(--fg)">Iscriviti alla<br><em>lista d’attesa</em></div>'
            f'{ic("user","Segui")}{ic("heart","Mi piace")}{ic("send","Condividi")}{ic("save","Salva")}</div>')
    return dark, out, "Dati di esempio · anteprima iPhone"


def grid12(top=480):
    cells = ""
    for i in range(12):
        cells += (f'<div class="card" style="width:206px;padding:34px 24px"><div class="lbl" style="font-size:22px;margin-bottom:12px">Mese {i+1:02d}</div>'
                  f'<div class="num" style="font-size:62px">40 €</div></div>')
    return col(f'<div style="display:flex;flex-wrap:wrap;gap:20px">{cells}</div>', top, 84, 886)


def curve(top=560):
    path = [(60, 170), (330, 400), (570, 400), (826, 70)]
    d = "M " + " L ".join(f"{x} {y}" for x, y in path)
    svg = (f'<svg width="886" height="560" viewBox="0 0 886 560" style="overflow:visible"><path d="{d}" fill="none" stroke="var(--hi)" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>')
    for x, y in [path[0], path[1], path[3]]:
        svg += f'<circle cx="{x}" cy="{y}" r="17" fill="var(--hi)" stroke="#fff" stroke-width="5"/>'
    def t(x, y, a, b, anchor):
        return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="SG" font-size="26" letter-spacing="2" fill="var(--hi)">{a}</text>'
                f'<text x="{x}" y="{y+54}" text-anchor="{anchor}" font-family="SG" font-size="54" fill="var(--fg)">{b}</text>')
    svg += t(30, 60, "OGGI", "500 €", "start") + t(330, 470, "AFFITTO", "50 €", "middle") + t(740, 30, "STIPENDIO", "1.250 €", "end")
    return col(svg + '</svg>', top, 84, 886)


def chips(items, top=520, size=44):
    c = "".join(f'<div class="card sg" style="padding:22px 34px;font-size:{size}px">{t}</div>' for t in items)
    return col(f'<div style="display:flex;flex-wrap:wrap;gap:20px">{c}</div>', top, 84, 886)


def before_after(top=470):
    def row(lbl, a, b, tot):
        return (f'<div class="card" style="margin-bottom:22px"><div class="lbl" style="margin-bottom:14px">{lbl}</div>'
                f'<div style="display:flex;align-items:baseline;gap:18px;flex-wrap:wrap"><span class="num" style="font-size:66px">{a}</span><span class="num" style="font-size:44px;color:var(--fg2)">+</span>'
                f'<span class="num" style="font-size:66px">{b}</span><span class="num" style="font-size:44px;color:var(--fg2)">=</span><span class="num" style="font-size:78px;color:var(--hi)">{tot}</span></div></div>')
    mid = ('<div class="sg" style="text-align:center;font-size:36px;color:var(--hi);margin:2px 0 20px">▼ Trasferisci 100 € dal conto A al conto B</div>')
    return col(row("Prima · conto A + conto B", "500 €", "300 €", "800 €") + mid + row("Dopo · conto A + conto B", "400 €", "400 €", "800 €"), top, 84, 886)
