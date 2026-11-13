# Personal Finance Tracker

A cross-platform iOS app for personal finance management, built with Swift and backed by Supabase for real-time multi-device sync.

## Features

- **Multi-account tracking** — add multiple bank accounts/balances, with automatic net-balance calculation after fixed monthly expenses
- **Smart categorization** — transactions are automatically sorted into categories via keyword-based matching on transaction descriptions; categories are fully customizable (add/edit/remove)
- **Budgeting** — set budgets per category, per account, or both
- **Savings goals** — track progress toward savings targets with completion percentages
- **Visual insights** — color-coded charts (green/red) for at-a-glance financial health
- **Multi-language** — available in 7 languages
- **Multi-device sync** — real-time sync across devices via Supabase, with secure user authentication (sign-up/login)
- **Demo mode** — try the full app without creating an account

## Tech Stack

- **Frontend:** Swift, Xcode
- **Backend:** Supabase (PostgreSQL, Auth, Row Level Security)

## Security

User data is protected via Supabase Row Level Security (RLS) policies, ensuring each user can only access their own records.

## Cantiere di sviluppo

Progetto organizzato col **modello Cantiere** di Matteo Cocivera.

- Regolamento, squadra e frasi-comando: `AGENTS.md`
- Dove siamo: `.cantiere/CHECKPOINT.md` · Piano: `.cantiere/PIANO.md`
- Materiale: magazzino su Google Drive (`00_CLIENTE`, `02_RISORSE`, `04_CONSEGNE`)

Per riprendere il lavoro: apri Claude Code (o Antigravity, o Codex) in questa cartella e scrivi **"riprendiamo"**.
