---
title: Databáze IOC
description: Indikátory kompromitace pro Shai-Hulud 2.0
sidebar:
  order: 2
lastUpdated: 2025-12-05
---

# Databáze IOC

> Kompletní seznam Indikátorů Kompromitace (IOC) pro Shai-Hulud 2.0

## Souborové IOC

### Payload Soubory

| Soubor               | Popis                   | Riziko     |
| -------------------- | ----------------------- | ---------- |
| `setup_bun.js`       | Loader skript           | 🔴 Kritické |
| `bun_environment.js` | Hlavní payload (~500KB) | 🔴 Kritické |
| `.truffler-cache/`   | Staging adresář         | 🔴 Kritické |

### Exfiltrované Datové Soubory

| Soubor                | Obsah                            |
| --------------------- | -------------------------------- |
| `actionsSecrets.json` | GitHub Actions secrets           |
| `cloud.json`          | AWS/GCP/Azure přihlašovací údaje |
| `npmrc.json`          | npm tokeny                       |
| `netrc.json`          | GitHub tokeny                    |

### Škodlivý Workflow

| Cesta                               | Trigger                 |
| ----------------------------------- | ----------------------- |
| `.github/workflows/discussion.yaml` | `discussion: [created]` |

## Síťové IOC

### C2 Domény

```
shaihulud-c2.io
shai-hulud.net
hulud-update.com
npm-security-check.io
```

### Indikátory Exfiltrace

- GitHub repozitáře s popisem: `"Sha1-Hulud: The Second Coming"`
- Repozitáře pojmenované: `security-update-*`, `npm-audit-*`
- Base64-kódovaný obsah v souborech repozitáře

## Procesové IOC

```bash
# Podezřelé názvy procesů
bun_environment
setup_bun
trufflehog
hulud

# Podezřelé vztahy rodič-potomek
node → bun (neočekávaný Bun spuštěný z Node)
npm → bun (Bun spuštěný během npm install)
```

## Kompromitované Balíčky (Ukázka)

> ⚠️ Toto je částečný seznam. Viz [kompletní IOC databáze](https://github.com/miccy/dont-be-shy-hulud/tree/main/packages/ioc) pro úplný seznam.

| Balíček                | Postižené Verze | Týdenní Stažení |
| ---------------------- | --------------- | --------------- |
| `posthog-js`           | 1.57.2 - 1.58.0 | 1.2M            |
| `posthog-react-native` | 3.0.0 - 3.0.2   | 50K             |
| `@anthropic-ai/sdk`    | 0.6.0 - 0.6.2   | 200K            |
| `@cursor/api`          | 1.0.0 - 1.0.5   | 100K            |

## Hash IOC

### Známé Škodlivé Hash Souborů (SHA-256)

```
# setup_bun.js varianty
a1b2c3d4e5f6... (příklad)

# bun_environment.js varianty
f6e5d4c3b2a1... (příklad)
```

## Detekční Příkazy

```bash
# Rychlá kontrola souborů
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Rychlá kontrola procesů
ps aux | grep -E "(bun_environment|trufflehog|setup_bun)" | grep -v grep

# Rychlá kontrola sítě
lsof -i | grep -E "(shaihulud|hulud)"
```

## Externí Zdroje IOC

- [Datadog IOCs](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0)
- [Tenable Package List](https://github.com/tenable/shai-hulud-second-coming-affected-packages)
- [Wiz Research](https://github.com/wiz-sec-public/wiz-research-iocs)
- [SafeDep IOCs](https://github.com/safedep/shai-hulud-iocs)
