---
title: Detekce IOC Souborů
description: Jak najít škodlivé soubory Shai-Hulud 2.0
sidebar:
  order: 1
  badge:
    text: Základní
    variant: tip
lastUpdated: 2025-12-05
---

# Detekce IOC Souborů

> Hledání známých škodlivých souborů na vašem systému

## Hlavní IOC Soubory

| Soubor               | Popis           | Umístění             |
| -------------------- | --------------- | -------------------- |
| `setup_bun.js`       | Loader skript   | node_modules, ~/.bun |
| `bun_environment.js` | Hlavní payload  | node_modules, ~/.bun |
| `.truffler-cache/`   | Staging adresář | ~                    |

## Rychlá Kontrola

```bash
# Najít payload soubory
find ~ -name "setup_bun.js" 2>/dev/null
find ~ -name "bun_environment.js" 2>/dev/null

# Najít staging adresář
find ~ -name ".truffler-cache" -type d 2>/dev/null

# Najít exfiltrované soubory
find ~ -name "actionsSecrets.json" 2>/dev/null
find ~ -name "cloud.json" 2>/dev/null
find ~ -name "npmrc.json" 2>/dev/null
```

## Kontrola node_modules

```bash
# Prohledat všechny node_modules
find ~/Developer -path "*/node_modules/*" \
  \( -name "setup_bun.js" -o -name "bun_environment.js" \) \
  2>/dev/null
```

## Kontrola Bun Instalace

```bash
# Zkontrolovat Bun adresář
ls -la ~/.bun 2>/dev/null

# Zkontrolovat datum instalace
stat ~/.bun/bin/bun 2>/dev/null | grep -E "(Birth|Change)"

# Pokud jste Bun neinstalovali sami, je to podezřelé!
```

## Kontrola GitHub Workflows

```bash
# Najít podezřelé workflow soubory
find ~/Developer -path "*/.github/workflows/discussion.yaml" 2>/dev/null
find ~/Developer -path "*/.github/workflows/discussion.yml" 2>/dev/null

# Zkontrolovat obsah workflows
grep -r "discussion:" ~/Developer/.github/workflows/ 2>/dev/null
```

## Automatická Detekce

```bash
# Použijte náš CLI nástroj
npx hulud scan ~

# Nebo s JSON výstupem
npx hulud scan ~ --json > scan-results.json
```

## Co Dělat Když Najdete IOC

1. **NEZABÍJEJTE procesy** — Použijte `kill -STOP` místo `kill -9`
2. **Shromážděte důkazy** — Zkopírujte soubory před smazáním
3. **Viz** [Okamžitá Reakce](/cs/remediation/immediate)
