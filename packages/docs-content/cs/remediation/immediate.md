---
title: Okamžitá Reakce
description: První kroky při zjištění infekce Shai-Hulud 2.0
sidebar:
  order: 0
  badge:
    text: URGENTNÍ
    variant: danger
lastUpdated: 2025-12-05
---

# Okamžitá Reakce

> **⏱️ Časově kritické akce při zjištění infekce**

## 🚨 STOP — NEDĚLEJTE:

- ❌ Nespouštějte `npm install` nebo `bun install`
- ❌ Nezabíjejte procesy pomocí `kill -9` (spustí dead man's switch!)
- ❌ Neodpojujte se okamžitě od sítě
- ❌ Nemažte soubory před sběrem důkazů

## Krok 1: Zmrazte Škodlivé Procesy (30 sekund)

```bash
# Najděte podezřelé procesy
ps aux | grep -E "(bun_environment|trufflehog|setup_bun)" | grep -v grep

# ZMRAZTE je (NE kill!)
# Použijte SIGSTOP pro pozastavení bez spuštění dead man's switch
kill -STOP <PID>

# Ověřte, že jsou zastaveny
ps aux | grep <PID>  # Měl by ukazovat stav 'T'
```

## Krok 2: Sbírejte Důkazy (2 minuty)

```bash
# Vytvořte složku pro důkazy
mkdir -p ~/evidence/shai-hulud-$(date +%Y%m%d-%H%M)
cd ~/evidence/shai-hulud-$(date +%Y%m%d-%H%M)

# Uložte seznam procesů
ps aux > processes.txt

# Uložte síťová spojení
netstat -an > netstat.txt
lsof -i > network-connections.txt

# Zkopírujte IOC soubory (ještě nemažte!)
cp ~/.truffler-cache/* . 2>/dev/null
find ~ -name "setup_bun.js" -exec cp {} . \; 2>/dev/null
find ~ -name "bun_environment.js" -exec cp {} . \; 2>/dev/null
find ~ -name "actionsSecrets.json" -exec cp {} . \; 2>/dev/null

# Uložte prostředí
env > environment.txt
```

## Krok 3: Vyhodnoťte Rozsah (1 minuta)

```bash
# Zkontrolujte, jaké přihlašovací údaje mohly být odhaleny
cat ~/.npmrc 2>/dev/null
cat ~/.netrc 2>/dev/null
ls -la ~/.aws/credentials 2>/dev/null
ls -la ~/.config/gcloud/ 2>/dev/null

# Zkontrolujte exfiltrační repozitáře
gh repo list --json name,description 2>/dev/null | \
  grep -i "hulud"
```

## Krok 4: Informujte Tým

**Okamžitě informujte:**
- Bezpečnostní tým
- DevOps/Platform tým
- Správce dotčených projektů

**Uveďte:**
- Časové razítko objevení
- Seznam postižených strojů
- Shromážděné důkazy
- Přihlašovací údaje, které mohly být kompromitovány

## Krok 5: Zahajte Nápravu

Po sběru důkazů:

1. [Rotace Přihlašovacích Údajů](/cs/remediation/credentials) — Rotujte VŠECHNY údaje
2. [Čištění Systému](/cs/remediation/cleanup) — Odstraňte artefakty malwaru
3. [Kompletní Průvodce Nápravou](/cs/remediation/guide) — Úplná obnova

## Nouzové Kontakty

- **npm Security**: security@npmjs.com
- **GitHub Security**: security@github.com
- **NÚKIB**: https://nukib.cz/cs/infoservis/hlasenky/

## Časová Osa

| Čas    | Akce               |
| ------ | ------------------ |
| 0:00   | Objevení           |
| 0:30   | Zmrazení procesů   |
| 2:30   | Důkazy shromážděny |
| 3:30   | Rozsah vyhodnocen  |
| 5:00   | Tým informován     |
| 10:00+ | Zahájení nápravy   |
