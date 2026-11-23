#!/usr/bin/env python3
"""Compone i post v2. Uso: python3 SOCIAL/caroselli/v2/build.py [N ...]  (senza argomenti: tutti)"""
import sys, importlib
from pathlib import Path
from lib import header, wrap, render, WORK, HERE
import posts

OUT = HERE / "_out"

def build(post, only=None):
    d = OUT / f'Post-{post["n"]:02d}-{post["slug"]}'
    d.mkdir(parents=True, exist_ok=True)
    slides = post["slides"]
    n = len(slides)
    for i, (dark, body, *foot) in enumerate(slides, 1):
        if only and i not in only:
            continue
        foot_html = f'<div class="foot">{foot[0]}</div>' if foot and foot[0] else ""
        html = wrap(header(i, n, post["tag"]) + body + foot_html, post["pal"], dark)
        render(html, d / f"slide-{i:02d}.png", f'p{post["n"]}-{i:02d}')
    return d

if __name__ == "__main__":
    args = sys.argv[1:]
    only = None
    nums = []
    for a in args:
        if ":" in a:
            p, s = a.split(":"); nums.append(int(p)); only = {int(x) for x in s.split(",")}
        else:
            nums.append(int(a))
    for p in posts.POSTS:
        if not nums or p["n"] in nums:
            print(build(p, only))
