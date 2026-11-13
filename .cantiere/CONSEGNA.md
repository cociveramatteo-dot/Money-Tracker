# CONSEGNA — il biglietto per chi entra in turno

**Da:** collaudatore (Claude Code · Sonnet) **Il:** 2026-11-13 20:20 **Collaudato:** commit 63113b4 (S-2)

## Esito: ❌ S-2 NON chiuso → [!], serve rilavorazione S-2b
Conformi: sette componenti, 14 preview light/dark, solo file nuovi, solo token `DS`/`CategoryTint`, nessun `preferredColorScheme`, tap target 44, font con `relativeTo:`, nessuna vista esistente toccata. Build + 33 test verdi (dato dall'impresa e da Matteo).

## Difetti da correggere (solo `Views/Components/` + le 7 `Localizable.strings`)
1. `BudgetStatus.swift:24-25`: chiavi `"Sforato"` e `"Soglia 80%"` assenti in tutti i 7 `Localizable.strings` (esiste solo `"Sforato di"`). Aggiungerle in it/en/de/es/fr/ja/zh-Hans (de: «Überschritten», «Schwelle 80 %»).
2. `HeroCard.swift:24`: raggio 16; handoff §2 chiede 24–26 per la hero. Usare un raggio hero (24) senza cambiare `cardRadius`.
3. Minori: `MovementRow` importo con `.fixedSize`/`layoutPriority` e `lineLimit` sul nome (XL + tedesco); `ProgressBar` accessibilityValue con progress>1 dica il valore reale.

## Limiti del collaudo
Preview non viste a schermo (nessun renderer): controllo statico. Dynamic Type XL e tedesco da riverificare a vista dopo S-2b (in Xcode: preview con Dynamic Type XL e lingua de).

## Prossimo passo
S-2b a Codex, poi ricollaudo. S-3 resta bloccato fino alla chiusura di S-2.
