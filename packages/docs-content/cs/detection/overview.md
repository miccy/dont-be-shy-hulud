---
title: Přehled Detekce
description: Přehled metod detekce Shai-Hulud 2.0
sidebar:
  order: 0
lastUpdated: 2025-12-05
---

# Přehled Detekce

> Kompletní přehled metod pro detekci infekce Shai-Hulud 2.0

## Typy Detekce

| Metoda                                   | Popis                               | Rychlost  |
| ---------------------------------------- | ----------------------------------- | --------- |
| [Souborové IOC](/cs/detection/ioc-files) | Hledání známých škodlivých souborů  | ⚡ Rychlá  |
| [Behaviorální](/cs/detection/behavioral) | Analýza podezřelého chování procesů | 🔄 Střední |
| [Síťová](/cs/detection/network)          | Detekce C2 komunikace a exfiltrace  | 🔍 Pomalá  |

## Rychlý Sken

```bash
# Nejrychlejší způsob - použijte náš CLI
npx hulud scan .

# Nebo manuálně zkontrolujte IOC soubory
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
find ~ -name ".truffler-cache" -type d 2>/dev/null
```

## Co Hledat

### 🔴 Kritické Indikátory

- `setup_bun.js` — Loader skript
- `bun_environment.js` — Hlavní payload (~500KB)
- `.truffler-cache/` — Staging adresář pro exfiltraci
- `.github/workflows/discussion.yaml` — Backdoor workflow

### 🟠 Podezřelé Indikátory

- Neočekávaná instalace Bun runtime
- Procesy `bun` spuštěné z `node` nebo `npm`
- Síťová komunikace s neznámými doménami
- Nové GitHub repozitáře s podezřelými názvy

## Doporučený Postup

1. **Rychlý sken** — Spusťte `npx hulud scan`
2. **Kontrola procesů** — Zkontrolujte běžící procesy
3. **Síťová analýza** — Zkontrolujte aktivní spojení
4. **Audit závislostí** — Zkontrolujte package.json a lockfiles

## Další Kroky

- Pokud najdete IOC → [Okamžitá Reakce](/cs/remediation/immediate)
- Pro prevenci → [Průvodce Prevencí](/cs/hardening/prevention)
- Pro detailní sken → [Průvodce Detekcí](/cs/detection/guide)
