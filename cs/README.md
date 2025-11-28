# 🪱 Don't Be Shy, Hulud

![Don't Be Shy, Hulud Banner](../assets/banner.png)

> **Praktický průvodce detekcí a ochranou proti npm supply-chain útokům**
> Zaměřeno na Shai-Hulud 2.0 (listopad 2025) a podobné hrozby

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## ⚡ TL;DR – Co dělat HNED

```bash
# 1. Stáhni tento repo
git clone https://github.com/miccy/dont-be-shy-hulud.git
cd dont-be-shy-hulud

# 2. Spusť rychlý audit (macOS/Linux)
chmod +x scripts/*.sh
./scripts/quick-audit.sh

# 3. Pokud jsi kompromitovaný, rotuj VŠECHNY credentials
./scripts/rotate-credentials.sh --help
```

## 📋 Obsah

- [Přehled hrozby](#-přehled-hrozby)
- [Detekce](#-detekce)
- [Remediation](#-remediation)
- [Prevence](#-prevence)
- [Common Issues](#-common-issues)
- [Case Study](#-case-study)
- [Scripty](#-scripty)
- [Konfigurace](#-konfigurace)
- [IOC databáze](#-ioc-databáze)

## 🎯 Přehled hrozby

### Shai-Hulud 2.0 (Listopad 2025)

| Vlastnost | Hodnota |
|-----------|---------|
| **Typ** | Self-propagating npm worm |
| **Kompromitované packages** | 796+ unique, 1092+ versions |
| **Zasažené GitHub repos** | 25,000+ |
| **Weekly downloads zasažených** | 20+ milionů |
| **Exfiltrované credentials** | 775+ GitHub, 373 AWS, 300 GCP, 115 Azure |

**Klíčové vlastnosti:**
- ⚡ Exekuce v **preinstall** fázi (ne postinstall)
- 🔄 Samoreplikace až 100 packages/infection
- 💀 Dead-man switch – destrukce dat při selhání exfiltrace
- 🚪 Persistent backdoor přes GitHub Discussions
- 🐳 Docker privilege escalation

**Payload soubory:**
- `setup_bun.js` – loader
- `bun_environment.js` – hlavní obfuskovaný payload

**Exfiltrované soubory:**
- `cloud.json`, `contents.json`, `environment.json`, `truffleSecrets.json`

➡️ [Podrobná analýza](docs/THREAT-OVERVIEW.md)

## 🔍 Detekce

### Rychlá kontrola

```bash
# Kontrola známých IOC souborů
find ~/Developer -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null

# Kontrola podezřelých GitHub workflows
find ~/Developer -path "*/.github/workflows/*" -name "discussion.yaml" 2>/dev/null

# Kontrola .truffler-cache
ls -la ~/.truffler-cache 2>/dev/null

# Kontrola GitHub repos s Shai-Hulud description
gh repo list --json name,description | jq '.[] | select(.description | contains("Hulud"))'
```

### Automatizovaný audit

```bash
./scripts/full-audit.sh
```

➡️ [Kompletní detekční guide](docs/DETECTION.md)

## 🔧 Remediation

### Okamžité kroky

1. **Freeze npm/bun updates**
2. **Rotace credentials** (npm, GitHub, AWS, GCP, Azure)
3. **Smazání node_modules a cache**
4. **Reinstalace z čistých verzí**

```bash
# Kompletní čištění projektu
rm -rf node_modules
npm cache clean --force
# nebo
rm -rf node_modules bun.lockb
bun pm cache rm

# Reinstalace s disabled scripts
npm install --ignore-scripts
```

➡️ [Kompletní remediation guide](docs/REMEDIATION.md)

## 🛡️ Prevence

### Doporučené nástroje

| Nástroj | Účel | Cena |
|---------|------|------|
| [Socket.dev](https://socket.dev) | Supply-chain security | Free / Paid |
| [Snyk](https://snyk.io) | Vulnerability scanning | Free / Paid |
| [npm audit](https://docs.npmjs.com/cli/v10/commands/npm-audit) | Built-in audit | Free |
| [Renovate](https://renovatebot.com) | Dependency updates | Free |
| [Datadog SCFW](https://github.com/DataDog/supply-chain-firewall) | Firewall | Free (OSS) |

### Klíčová opatření

```bash
# Disable lifecycle scripts globálně
npm config set ignore-scripts true

# Nebo per-project v .npmrc
echo "ignore-scripts=true" >> .npmrc
```

➡️ [Kompletní prevention guide](docs/PREVENTION.md)

## 🔧 Common Issues

Časté nálezy ze security scanů:

| Issue | Příčina | Řešení |
|-------|---------|--------|
| Transitivní CVE | Stará závislost v dependency tree | `npm ls package` → update parent |
| Špatný package name | `biome` místo `@biomejs/biome` | Přeinstaluj správný package |
| `unstableOwnership` | Změna maintainera | Často false positive (Google, Biome) |
| `obfuscatedFile` | Minifikovaný kód | Ověř na npm/GitHub |

➡️ [Kompletní common issues guide](docs/COMMON-ISSUES.md)

## 📈 Case Study

Praktický příklad analýzy 78 alertů ze Socket.dev:

- 2 Critical → opraveno (špatný `biome` package)
- 39 High → 30 false positives (workbox, biomejs)
- Čas na analýzu: 30 minut
- Čas na opravu: 10 minut

➡️ [Kompletní case study](docs/CASE-STUDY-SOCKET-ANALYSIS.md)

## 📜 Scripty

| Script | Účel |
|--------|------|
| [`quick-audit.sh`](../scripts/quick-audit.sh) | Rychlý security audit (5 min) |
| [`full-audit.sh`](../scripts/full-audit.sh) | Kompletní audit s IOC skenováním |
| [`scan-node-modules.sh`](../scripts/scan-node-modules.sh) | Skenování node_modules ve všech projektech |
| [`check-github-repos.sh`](../scripts/check-github-repos.sh) | Kontrola GitHub repos na kompromitaci |
| [`rotate-credentials.sh`](../scripts/rotate-credentials.sh) | Asistovaná rotace credentials |
| [`harden-npm.sh`](../scripts/harden-npm.sh) | Hardening npm/bun konfigurace |

## ⚙️ Konfigurace

| Soubor | Účel |
|--------|------|
| [`renovate-lockdown.json`](../configs/renovate-lockdown.json) | Renovate config pro krizový lockdown |
| [`renovate-hardened.json`](../configs/renovate-hardened.json) | Renovate config pro běžný provoz |
| [`socket.yml`](../configs/socket.yml) | Socket.dev konfigurace |
| [`.npmrc-secure`](../configs/.npmrc-secure) | Bezpečná .npmrc template |

## 📊 IOC databáze

Aktualizované seznamy IOC (Indicators of Compromise):

- [`malicious-packages.json`](../ioc/malicious-packages.json) – Seznam kompromitovaných packages
- [`malicious-hashes.json`](../ioc/malicious-hashes.json) – SHA hashes malicious payloads
- [`github-repos.json`](../ioc/github-repos.json) – Známé exfiltration repos

**Zdroje IOC:**
- [Tenable IOC List](https://github.com/tenable/shai-hulud-second-coming-affected-packages)
- [Datadog IOC List](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0)
- [SafeDep Response](https://github.com/safedep/shai-hulud-migration-response)
- [Wiz IOC CSV](https://github.com/wiz-sec-public/wiz-research-iocs)

## 🤝 Contributing

PRs jsou vítány! Zejména:
- Nové detekční scripty
- Aktualizace IOC
- Dokumentace pro specifické platformy
- Překlady

## 📚 Reference

- [HackerOne Blog](https://www.hackerone.com/blog/shai-hulud-2-npm-worm-supply-chain-attack)
- [Socket.dev Analysis](https://socket.dev/blog/shai-hulud-strikes-again-v2)
- [Palo Alto Unit 42](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [CISA Alert](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)

## 📄 License

MIT – viz [LICENSE](../LICENSE)

---

> 💡 **Tip:** Přidej ⭐ pokud ti tento guide pomohl!

> ⚠️ **Disclaimer:** Tento guide je poskytován "as is". Autoři nenesou odpovědnost za škody způsobené použitím nebo nepoužitím těchto informací.

---

<div align="center">
  <p>🛠 Od <a href="https://github.com/miccy">@miccy</a> z nenávisti k Červům 🤬</p>
</div>
