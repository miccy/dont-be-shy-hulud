---
title: Reference CLI
description: Reference příkazového řádku pro hulud
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Reference CLI

> Kompletní reference pro nástroj příkazového řádku `hulud`

## Instalace

```bash
# Spuštění bez instalace
npx hulud <příkaz>

# Nebo globální instalace
npm install -g dont-be-shy-hulud
```

## Příkazy

### `scan`

Skenuje adresář na indikátory Shai-Hulud 2.0.

```bash
hulud scan [cesta] [možnosti]
```

**Argumenty:**
- `cesta` — Adresář ke skenování (výchozí: aktuální adresář)

**Možnosti:**
- `--deep` — Hluboký sken včetně node_modules
- `--json` — Výstup výsledků jako JSON
- `--quiet` — Potlačit výstup průběhu

**Příklady:**
```bash
# Skenovat aktuální adresář
hulud scan

# Skenovat konkrétní cestu
hulud scan ~/Developer/muj-projekt

# Hluboký sken s JSON výstupem
hulud scan --deep --json > vysledky.json
```

### `audit`

Spustí komplexní bezpečnostní audit.

```bash
hulud audit [možnosti]
```

**Možnosti:**
- `--full` — Plný audit včetně síťových kontrol
- `--quick` — Rychlý audit (pouze soubory)

**Příklady:**
```bash
# Rychlý audit
hulud audit --quick

# Plný audit
hulud audit --full
```

### `harden`

Aplikuje bezpečnostní zpevnění na npm konfiguraci.

```bash
hulud harden [možnosti]
```

**Možnosti:**
- `--dry-run` — Zobrazit změny bez aplikace
- `--force` — Přepsat existující konfiguraci

**Příklady:**
```bash
# Náhled změn
hulud harden --dry-run

# Aplikovat zpevnění
hulud harden
```

### `check`

Zkontroluje konkrétní balíček na známé kompromitace.

```bash
hulud check <balíček> [verze]
```

**Příklady:**
```bash
# Zkontrolovat balíček
hulud check posthog-js

# Zkontrolovat konkrétní verzi
hulud check posthog-js 1.57.2
```

## Návratové Kódy

| Kód | Význam            |
| --- | ----------------- |
| 0   | Žádné problémy    |
| 1   | Detekováno IOC    |
| 2   | Chyba během skenu |

## Proměnné Prostředí

| Proměnná         | Popis                     |
| ---------------- | ------------------------- |
| `HULUD_NO_COLOR` | Zakázat barevný výstup    |
| `HULUD_VERBOSE`  | Povolit podrobné logování |
| `HULUD_IOC_URL`  | Vlastní URL IOC databáze  |

## Konfigurace

Vytvořte `.huludrc.json` ve vašem projektu:

```json
{
  "scan": {
    "exclude": ["node_modules", ".git"],
    "deep": false
  },
  "audit": {
    "level": "moderate"
  }
}
```
