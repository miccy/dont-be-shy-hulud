---
title: Síťová Detekce
description: Detekce C2 komunikace a exfiltrace dat
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Síťová Detekce

> Identifikace škodlivé síťové komunikace

## Známé C2 Domény

```
shaihulud-c2.io
shai-hulud.net
hulud-update.com
npm-security-check.io
```

## Kontrola Aktivních Spojení

```bash
# Zobrazit všechna aktivní spojení
netstat -an | grep ESTABLISHED

# Zobrazit spojení s procesy
lsof -i -P | grep ESTABLISHED

# Hledat spojení z node/bun procesů
lsof -i | grep -E "(node|bun)"
```

## Kontrola DNS

```bash
# Zkontrolovat DNS cache (macOS)
sudo dscacheutil -cachedump 2>/dev/null | grep -E "(hulud|truffler)"

# Sledovat DNS dotazy v reálném čase
sudo tcpdump -i any port 53 2>/dev/null | grep -E "(hulud|truffler)"
```

## Detekce Exfiltrace

### GitHub Exfiltrace

Shai-Hulud 2.0 exfiltruje data přes veřejné GitHub repozitáře:

```bash
# Zkontrolovat vaše repozitáře
gh repo list --json name,description | \
  jq '.[] | select(.description | contains("Hulud"))'

# Hledat repozitáře s podezřelými názvy
gh repo list --json name | \
  jq '.[] | select(.name | test("security-update-|npm-audit-"))'
```

### Indikátory Exfiltrace

- Repozitáře s popisem: `"Sha1-Hulud: The Second Coming"`
- Názvy repozitářů: `security-update-*`, `npm-audit-*`
- Náhodné 18-znakové názvy: `[0-9a-z]{18}`

## Firewall Pravidla

### Blokování Známých C2

```bash
# macOS: Přidat do /etc/hosts
echo "127.0.0.1 shaihulud-c2.io" | sudo tee -a /etc/hosts
echo "127.0.0.1 shai-hulud.net" | sudo tee -a /etc/hosts
echo "127.0.0.1 hulud-update.com" | sudo tee -a /etc/hosts
```

### Monitoring Odchozího Provozu

```bash
# Sledovat odchozí HTTPS provoz
sudo tcpdump -i any port 443 -n | grep -v "known-good-domains"
```

## Síťové IOC

| Indikátor                 | Typ      | Riziko     |
| ------------------------- | -------- | ---------- |
| Spojení na C2 domény      | DNS/HTTP | 🔴 Kritické |
| Neočekávaný HTTPS z node  | Spojení  | 🟠 Vysoké   |
| Upload na GitHub API      | HTTP     | 🟡 Střední  |
| Base64 data v požadavcích | Payload  | 🟠 Vysoké   |

## Automatická Detekce

```bash
# Síťový audit
npx hulud audit --full

# Pouze síťová kontrola
lsof -i | grep -E "(shaihulud|hulud|truffler)"
```
