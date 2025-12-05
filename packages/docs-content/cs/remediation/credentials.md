---
title: Rotace Přihlašovacích Údajů
description: Jak rotovat všechny potenciálně kompromitované přihlašovací údaje
sidebar:
  order: 2
  badge:
    text: Kritické
    variant: danger
lastUpdated: 2025-12-05
---

# Rotace Přihlašovacích Údajů

> Rotujte VŠECHNY přihlašovací údaje, které mohly být vystaveny Shai-Hulud 2.0

## ⚠️ Kritické Varování

Shai-Hulud 2.0 sbírá přihlašovací údaje z:
- `~/.npmrc` (npm tokeny)
- `~/.netrc` (GitHub tokeny)
- Proměnné prostředí (AWS, GCP, Azure klíče)
- GitHub Actions secrets
- SSH klíče

**Předpokládejte, že VŠECHNY přihlašovací údaje jsou kompromitovány, pokud jste našli IOC soubory.**

## npm Tokeny

```bash
# 1. Vypište všechny tokeny
npm token list

# 2. Zrušte VŠECHNY tokeny
npm token revoke <token-id>
# Opakujte pro každý token

# 3. Vytvořte nový token s omezeními
npm token create --read-only --cidr=<vaše-ip>/32

# 4. Povolte 2FA
npm profile enable-2fa auth-and-writes
```

## GitHub Tokeny

### Personal Access Tokeny

1. Jděte na https://github.com/settings/tokens
2. **Zrušte VŠECHNY existující tokeny**
3. Vytvořte nové fine-grained tokeny s:
   - Minimálním přístupem k repozitářům
   - Krátkou expirací (30 dní)
   - IP omezeními pokud možno

### SSH Klíče

```bash
# 1. Vypište SSH klíče
ls -la ~/.ssh/

# 2. Vygenerujte nový klíč
ssh-keygen -t ed25519 -C "vas-email@example.com"

# 3. Přidejte na GitHub
cat ~/.ssh/id_ed25519.pub
# Vložte na https://github.com/settings/ssh/new

# 4. Odstraňte staré klíče z GitHubu
# https://github.com/settings/keys
```

## Přihlašovací Údaje Cloud Providerů

### AWS

```bash
# 1. Vypište přístupové klíče
aws iam list-access-keys

# 2. Vytvořte nový klíč
aws iam create-access-key

# 3. Smažte starý klíč
aws iam delete-access-key --access-key-id <stary-key-id>

# 4. Aktualizujte ~/.aws/credentials
```

### GCP

```bash
# 1. Vypište klíče service accountu
gcloud iam service-accounts keys list --iam-account=<sa-email>

# 2. Vytvořte nový klíč
gcloud iam service-accounts keys create new-key.json \
  --iam-account=<sa-email>

# 3. Smažte staré klíče
gcloud iam service-accounts keys delete <key-id> \
  --iam-account=<sa-email>
```

### Azure

```bash
# 1. Vypište service principals
az ad sp list --show-mine

# 2. Resetujte přihlašovací údaje
az ad sp credential reset --id <app-id>
```

## Proměnné Prostředí

```bash
# Zkontrolujte odhalené secrets
env | grep -iE "(token|key|secret|password|auth)"

# Aktualizujte .env soubory
# Aktualizujte CI/CD secrets
# Aktualizujte deployment konfigurace
```

## Kontrolní Seznam

- [ ] npm tokeny rotovány
- [ ] GitHub PATs zrušeny a znovu vytvořeny
- [ ] SSH klíče přegenerovány
- [ ] AWS přihlašovací údaje rotovány
- [ ] GCP service account klíče rotovány
- [ ] Azure přihlašovací údaje resetovány
- [ ] CI/CD secrets aktualizovány
- [ ] .env soubory aktualizovány
- [ ] Tým informován o změnách přihlašovacích údajů
