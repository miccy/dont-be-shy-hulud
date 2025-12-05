---
title: Rychlý Start
description: Začněte s detekcí Shai-Hulud za méně než 5 minut
sidebar:
  order: 1
  badge:
    text: Začněte Zde
    variant: success
lastUpdated: 2025-12-05
---

# Rychlý Start

Skenujte váš systém na indikátory Shai-Hulud 2.0 za méně než 5 minut.

## Možnost 1: NPX (Doporučeno)

```bash
npx hulud scan .
```

## Možnost 2: Manuální Kontrola

```bash
# Zkontrolovat IOC soubory
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Zkontrolovat staging adresář
find ~ -name ".truffler-cache" -type d 2>/dev/null

# Zkontrolovat procesy
ps aux | grep -E "(bun_environment|setup_bun)" | grep -v grep
```

## Co Dělat Dál

### ✅ Pokud Nic Nenajdete

1. Zpevněte vaši konfiguraci: `npx hulud harden`
2. Přečtěte si [Průvodce Prevencí](/cs/hardening/prevention)

### 🚨 Pokud Najdete IOC

1. **NEZABÍJEJTE procesy** — Použijte `kill -STOP <PID>`
2. Přečtěte si [Okamžitá Reakce](/cs/remediation/immediate)
3. Rotujte přihlašovací údaje

## Další Kroky

- [Instalace](/cs/getting-started/installation) — Kompletní instalační možnosti
- [Přehled Hrozby](/cs/getting-started/threat-overview) — Pochopte útok
- [Průvodce Detekcí](/cs/detection/guide) — Detailní detekce
