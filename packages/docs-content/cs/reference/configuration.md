---
title: Reference Konfigurace
description: Možnosti konfigurace pro bezpečnostní zpevnění
sidebar:
  order: 4
lastUpdated: 2025-12-05
---

# Reference Konfigurace

> Šablony a možnosti bezpečnostní konfigurace

## Dostupné Konfigurace

Toolkit poskytuje předkonfigurované bezpečnostní šablony v `packages/configs/`:

| Soubor                   | Účel                      |
| ------------------------ | ------------------------- |
| `.npmrc-secure`          | Zpevněná npm konfigurace  |
| `bunfig-secure.toml`     | Zpevněná Bun konfigurace  |
| `renovate-defense.json`  | Anti-worm Renovate konfig |
| `renovate-hardened.json` | Striktní Renovate konfig  |
| `socket.yml`             | Socket.dev konfigurace    |

## npm Konfigurace

### `.npmrc-secure`

```ini
# Zakázat lifecycle skripty (KRITICKÉ!)
ignore-scripts=true

# Bezpečnostní nastavení
audit=true
audit-level=moderate

# Zakázat telemetrii
fund=false
update-notifier=false

# Nastavení lockfile
package-lock=true
save-exact=true
```

### Použití

```bash
# Zkopírovat do domovského adresáře
cp packages/configs/.npmrc-secure ~/.npmrc

# Nebo použít náš skript
npx hulud harden
```

## Bun Konfigurace

### `bunfig-secure.toml`

```toml
[install]
# Zakázat lifecycle skripty
lifecycle = false

# Použít lockfile
frozen = true

# Bezpečnost
audit = true
```

### Použití

```bash
cp packages/configs/bunfig-secure.toml ~/bunfig.toml
```

## Renovate Konfigurace

### `renovate-defense.json`

Anti-worm konfigurace která:
- Připíná všechny závislosti na přesné verze
- Vyžaduje manuální schválení aktualizací
- Blokuje známé škodlivé balíčky
- Povoluje pouze bezpečnostní aktualizace

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "rangeStrategy": "pin",
  "automerge": false,
  "prCreation": "immediate",
  "vulnerabilityAlerts": {
    "enabled": true
  }
}
```

### Použití

```bash
cp packages/configs/renovate-defense.json renovate.json
```

## Socket.dev Konfigurace

### `socket.yml`

```yaml
version: 2
projectIgnorePaths:
  - "node_modules/**"
  - ".git/**"

issueRules:
  criticalCVE:
    action: error
  highCVE:
    action: warn
  installScripts:
    action: error
  networkAccess:
    action: warn
```

### Použití

```bash
cp packages/configs/socket.yml socket.yml
```

## Proměnné Prostředí

| Proměnná                    | Výchozí     | Popis                |
| --------------------------- | ----------- | -------------------- |
| `NPM_CONFIG_IGNORE_SCRIPTS` | `false`     | Zakázat npm skripty  |
| `NPM_CONFIG_AUDIT`          | `true`      | Povolit npm audit    |
| `HULUD_IOC_URL`             | (vestavěná) | Vlastní IOC databáze |

## CI/CD Integrace

### GitHub Actions

```yaml
- name: Nastavit bezpečné npm
  run: |
    npm config set ignore-scripts true
    npm config set audit true
```

### GitLab CI

```yaml
before_script:
  - npm config set ignore-scripts true
  - npm ci --ignore-scripts
```
