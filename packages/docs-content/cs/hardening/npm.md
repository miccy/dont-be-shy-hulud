---
title: Bezpečnostní Konfigurace npm
description: Zpevněte vaši npm konfiguraci proti supply chain útokům
sidebar:
  order: 5
  badge:
    text: Základní
    variant: tip
lastUpdated: 2025-12-05
---

# Bezpečnostní Konfigurace npm

> Základní npm nastavení pro ochranu proti supply chain útokům

## Rychlé Zpevnění

```bash
# Spusťte náš zpevňovací skript
npx hulud harden

# Nebo manuálně:
npm config set ignore-scripts true
npm config set audit true
npm config set fund false
```

## Konfigurace .npmrc

Vytvořte nebo aktualizujte `~/.npmrc`:

```ini
# Zakázat lifecycle skripty (KRITICKÉ!)
ignore-scripts=true

# Povolit bezpečnostní funkce
audit=true
audit-level=moderate

# Zakázat telemetrii
fund=false
update-notifier=false

# Použít lockfile
package-lock=true
save-exact=true

# Bezpečnost registru (volitelné: použít privátní registr)
# registry=https://vas-privatni-registr.com
```

## Projektový .npmrc

Vytvořte `.npmrc` v kořenu projektu:

```ini
# Dědit z uživatelské konfigurace
# Přidat projektově specifická nastavení

# Striktní kontrola engine
engine-strict=true

# Pouze přesné verze
save-exact=true

# Vyžadovat lockfile
package-lock=true
```

## Bezpečnost Tokenů

### Pravidelně Rotujte Tokeny

```bash
# Vypsat aktuální tokeny
npm token list

# Zrušit staré tokeny
npm token revoke <token-id>

# Vytvořit nový token s omezeným rozsahem
npm token create --read-only --cidr=<vase-ci-ip>/32
```

### Použijte Fine-Grained Tokeny

1. Jděte na https://www.npmjs.com/settings/~/tokens
2. Vytvořte "Granular Access Token"
3. Nastavte:
   - **Expirace**: 30-90 dní
   - **Balíčky**: Pouze balíčky které potřebujete
   - **Oprávnění**: Read-only pro CI
   - **IP Allowlist**: Vaše CI IP rozsahy

## Konfigurace 2FA

```bash
# Povolit 2FA pro všechny operace
npm profile enable-2fa auth-and-writes

# Zkontrolovat stav 2FA
npm profile get
```

## Audit Příkazy

```bash
# Zkontrolovat zranitelnosti
npm audit

# Opravit automaticky (použijte s opatrností)
npm audit fix

# Vygenerovat report
npm audit --json > audit-report.json
```

## Bezpečnost Publikování Balíčků

```bash
# Zkontrolovat co bude publikováno
npm pack --dry-run

# Ověřit obsah balíčku
npm publish --dry-run

# Použít provenance (npm 9.5+)
npm publish --provenance
```

## Doporučené Nástroje

| Nástroj    | Účel                               |
| ---------- | ---------------------------------- |
| Socket.dev | Real-time monitoring supply chain  |
| Snyk       | Skenování zranitelností            |
| npm audit  | Vestavěná kontrola zranitelností   |
| Renovate   | Automatické aktualizace závislostí |
