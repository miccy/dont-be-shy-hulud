---
title: Behaviorální Detekce
description: Detekce podezřelého chování procesů
sidebar:
  order: 2
lastUpdated: 2025-12-05
---

# Behaviorální Detekce

> Identifikace podezřelého chování procesů a systému

## Podezřelé Procesy

### Kontrola Běžících Procesů

```bash
# Hledat podezřelé názvy procesů
ps aux | grep -E "(bun_environment|setup_bun|trufflehog)" | grep -v grep

# Hledat Bun procesy (pokud jste ho neinstalovali)
ps aux | grep -i bun | grep -v grep

# Zobrazit strom procesů
pstree -p | grep -E "(bun|node|npm)"
```

### Podezřelé Vztahy Rodič-Potomek

```
⚠️ PODEZŘELÉ:
node → bun (Bun spuštěný z Node.js)
npm → bun (Bun spuštěný během npm install)
preinstall → bun (Bun spuštěný z lifecycle skriptu)
```

## Kontrola Systémových Změn

### Změny v Konfiguračních Souborech

```bash
# Zkontrolovat nedávné změny v .npmrc
ls -la ~/.npmrc
cat ~/.npmrc

# Zkontrolovat .netrc (GitHub tokeny)
ls -la ~/.netrc
cat ~/.netrc 2>/dev/null

# Zkontrolovat změny v shell konfiguraci
grep -i bun ~/.zshrc ~/.bashrc 2>/dev/null
```

### Nové Cron Joby

```bash
# Zkontrolovat crontab
crontab -l

# Zkontrolovat systémové cron
ls -la /etc/cron.d/
```

## Monitoring v Reálném Čase

### Sledování Procesů

```bash
# Sledovat nové procesy
watch -n 1 'ps aux | grep -E "(bun|node|npm)" | grep -v grep'

# Použít htop s filtrem
htop -F bun
```

### Sledování Souborového Systému

```bash
# macOS: Sledovat změny v domovském adresáři
fswatch -r ~ | grep -E "(setup_bun|bun_environment|truffler)"
```

## Indikátory Kompromitace

| Chování                       | Riziko     | Akce             |
| ----------------------------- | ---------- | ---------------- |
| Bun proces bez vaší instalace | 🔴 Kritické | Okamžitě zmrazit |
| Neznámé síťové spojení z node | 🟠 Vysoké   | Vyšetřit         |
| Nové soubory v ~/.bun         | 🟠 Vysoké   | Zkontrolovat     |
| Změny v .npmrc                | 🟡 Střední  | Ověřit           |

## Automatická Detekce

```bash
# Kompletní behaviorální audit
npx hulud audit --full
```
