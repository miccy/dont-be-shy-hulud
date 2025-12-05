---
title: Čištění Systému
description: Odstranění artefaktů malwaru a obnovení integrity systému
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Čištění Systému

> Odstraňte všechny artefakty Shai-Hulud 2.0 z vašeho systému

## ⚠️ Před Čištěním

1. **Nejprve shromážděte důkazy** — Viz [Průvodce Nápravou](/cs/remediation/guide)
2. **Zmrazte procesy** — Použijte SIGSTOP, ne SIGKILL (dead man's switch!)
3. **Zálohujte důležitá data** — Malware může smazat $HOME, pokud nemůže exfiltrovat

## Odstranění IOC Souborů

```bash
# Odstraňte payload soubory
find ~ -name "setup_bun.js" -delete 2>/dev/null
find ~ -name "bun_environment.js" -delete 2>/dev/null

# Odstraňte staging adresář
rm -rf ~/.truffler-cache

# Odstraňte exfiltrované datové soubory
find ~ -name "actionsSecrets.json" -delete 2>/dev/null
find ~ -name "cloud.json" -delete 2>/dev/null
find ~ -name "npmrc.json" -delete 2>/dev/null
```

## Odstranění Škodlivé Instalace Bun

```bash
# Zkontrolujte, zda byl Bun nainstalován malwarem
if [ -d ~/.bun ] && [ -f ~/.bun/bin/bun ]; then
  # Zkontrolujte datum instalace
  stat ~/.bun/bin/bun

  # Pokud je podezřelý, odstraňte
  rm -rf ~/.bun
  rm -rf ~/.dev-env
fi

# Odstraňte z PATH
# Upravte ~/.zshrc nebo ~/.bashrc a odstraňte Bun cesty
```

## Vyčištění npm Cache

```bash
# Vyčistěte npm cache
npm cache clean --force

# Odstraňte node_modules v postižených projektech
find ~/Developer -name "node_modules" -type d -prune -exec rm -rf {} \;

# Přeinstalujte s ignore-scripts
npm ci --ignore-scripts
```

## Odstranění Škodlivých GitHub Workflows

```bash
# Najděte a odstraňte discussion.yaml
find ~/Developer -path "*/.github/workflows/discussion.yaml" -delete
find ~/Developer -path "*/.github/workflows/discussion.yml" -delete

# Zkontrolujte další podezřelé workflows
find ~/Developer -path "*/.github/workflows/*.yaml" -exec grep -l "curl\|wget" {} \;
```

## Vyčištění GitHub Repozitářů

```bash
# Vypište repozitáře s podezřelým popisem
gh repo list --json name,description | \
  jq '.[] | select(.description | contains("Hulud"))'

# Smažte škodlivé repozitáře (OPATRNĚ!)
# gh repo delete <repo-name> --yes
```

## Ověření Čištění

```bash
# Spusťte detekci znovu
npx hulud scan ~

# Zkontrolujte zbývající IOCs
find ~ -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
find ~ -name ".truffler-cache" -type d 2>/dev/null

# Zkontrolujte procesy
ps aux | grep -E "(bun|truffler|hulud)" | grep -v grep
```

## Kontrolní Seznam Po Čištění

- [ ] Všechny IOC soubory odstraněny
- [ ] Škodlivá instalace Bun odstraněna
- [ ] npm cache vyčištěna
- [ ] node_modules čistě přeinstalovány
- [ ] Škodlivé workflows odstraněny
- [ ] GitHub repozitáře vyčištěny
- [ ] Detekční sken prošel
- [ ] Přihlašovací údaje rotovány (viz [Rotace Přihlašovacích Údajů](/cs/remediation/credentials))
