# CONSEGNA — il biglietto per chi entra in turno

**Da:** collaudatore (Claude Code · Sonnet) **Il:** 2026-11-13 20:40 **Collaudato:** commit 535ccc1 (S-2b)

## Esito: ✅ S-2 e S-2b chiusi [x]
Le quattro correzioni sono conformi (i18n in 7 lingue, raggio hero 24, layout riga robusto a XL/tedesco, accessibilityValue reale). Build e 33 test verdi (dati dall'impresa e da Matteo).

## Aperto
- Preview non viste a schermo dal collaudo: Matteo può confermarle in Xcode (Canvas, Dynamic Type XL, lingua tedesco). Non blocca.
- Il raggio hero 24 è un letterale in `HeroCard.swift`: se serve altrove, farne un token (non ora).

## Prossimo passo
S-3 FloatingTabBar + FAB → capocantiere (Claude Code), come da PIANO.
