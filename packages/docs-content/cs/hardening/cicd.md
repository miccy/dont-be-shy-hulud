---
title: Bezpečnost CI/CD Pipeline
description: Zabezpečte vaše CI/CD pipeline proti supply chain útokům
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# Bezpečnost CI/CD Pipeline

> Chraňte vaše build a deployment pipeline před supply chain útoky

## Klíčové Principy

1. **Minimální Oprávnění** — CI joby by měly mít minimální oprávnění
2. **Připnuté Závislosti** — Používejte přesné verze a lockfiles
3. **Izolovaná Prostředí** — Oddělte build od deploy
4. **Auditní Stopy** — Logujte všechny akce pro forenzní analýzu

## GitHub Actions Bezpečnost

Viz [Zpevnění GitHub Actions](/cs/hardening/github-actions) pro detailní konfiguraci.

## Obecná CI/CD Doporučení

### Instalace Závislostí

```yaml
# ✅ Dobře: Použít lockfile, ignorovat skripty
- run: npm ci --ignore-scripts

# ❌ Špatně: Umožňuje spuštění libovolného kódu
- run: npm install
```

### Proměnné Prostředí

```yaml
# ✅ Dobře: Použít GitHub Secrets
env:
  NPM_TOKEN: ${{ secrets.NPM_TOKEN }}

# ❌ Špatně: Hardcoded tokeny
env:
  NPM_TOKEN: "npm_abc123..."
```

### Připnutí Actions

```yaml
# ✅ Dobře: Připnout na SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11

# ⚠️ Přijatelné: Připnout na verzi
- uses: actions/checkout@v4

# ❌ Špatně: Plovoucí tag
- uses: actions/checkout@main
```

## Izolace Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  BUILD PROSTŘEDÍ (Nízká Důvěra)                              │
│  • Instalace závislostí                                      │
│  • Spuštění testů                                            │
│  • Build artefaktů                                           │
│  • ŽÁDNÝ přístup k produkčním secrets                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  DEPLOY PROSTŘEDÍ (Vysoká Důvěra)                            │
│  • Ověření podpisů artefaktů                                 │
│  • Deploy do produkce                                        │
│  • Přístup k produkčním secrets                              │
│  • Vyžaduje schválení                                        │
└─────────────────────────────────────────────────────────────┘
```

## Monitoring

- Povolte GitHub Advanced Security
- Použijte Socket.dev nebo Snyk v CI
- Nastavte alerty pro selhané bezpečnostní kontroly
- Kontrolujte aktualizace závislostí před mergem
