# 🗺️ Roadmapa projektu

> **Stav:** Aktivní vývoj
> **Poslední aktualizace:** 2025-12-04
> **Maintainer:** [@miccy](https://github.com/miccy)

Tato roadmapa je založena na komplexních bezpečnostních auditech od více AI modelů (Claude Opus 4.5, GPT-5.1-Pro, Grok-4.1, Perplexity, Proton-Lumo, Gemini-3-Pro) a zpětné vazbě komunity. Jsme transparentní ohledně toho, co je hotové a co ještě potřebuje práci.

**Chcete pomoci?** Vyberte si jakoukoliv nezaškrtnutou položku a pošlete PR! Viz [CONTRIBUTING.md](CONTRIBUTING.md) pro pokyny.

---

## 📊 Přehled pokroku

| Kategorie                                     | Pokrok | Priorita |
| --------------------------------------------- | ------ | -------- |
| [Jádro detekce](#-jádro-detekce)              | 🟢 85%  | P0       |
| [IOC databáze](#-ioc-databáze)                | 🟡 60%  | P0       |
| [Dokumentace](#-dokumentace)                  | 🟢 90%  | P1       |
| [Automatizace & CI/CD](#-automatizace--cicd)  | 🟡 50%  | P1       |
| [Nástroje](#-nástroje)                        | 🔴 20%  | P2       |
| [Komunita & Ekosystém](#-komunita--ekosystém) | 🔴 10%  | P2       |

---

## 🎯 Jádro detekce

### Skripty & Nástroje

- [x] `detect.sh` - Hlavní detekční skript
  - [x] Detekce IOC souborů (`setup_bun.js`, `bun_environment.js`, `bundle.js`)
  - [x] Detekce škodlivých workflow
  - [x] Skenování lockfilů na kompromitované balíčky
  - [x] Inspekce npm cache
  - [x] Verbose mód a CI-friendly exit kódy
  - [x] Barevný výstup
  - [x] **SIGSTOP mód** - Zmrazení procesů místo ukončení (zabrání spuštění wiperu)
  - [ ] Příznaky scan módu (`--lockfiles-only`, `--filesystem-only`, `--full`)
  - [ ] JSON/SARIF výstupní formát
  - [ ] Paralelní skenování pro velké monorepa
  - [ ] Hloubková inspekce Bun lockfile (`bun.lockb`)

- [x] `quick-audit.sh` - Rychlá předběžná kontrola
- [x] `full-audit.sh` - Kompletní systémový audit
- [x] `check-github-repos.sh` - Kontrola exfiltračních repozitářů
  - [ ] Dávkové zpracování pro organizace
  - [ ] Detekce self-hosted runnerů (`SHA1HULUD`)
  - [ ] Detekce injection do workflow

- [x] **`suspend-malware.sh`** - Bezpečné pozastavení procesu (P0 - Kritické) ✅ Přidáno v v1.5.0
  ```bash
  # Používá SIGSTOP místo SIGKILL k prevenci aktivace wiperu
  kill -STOP $PID  # Zmrazit, ne zabít!
  ```
  - [x] Automatická detekce škodlivých procesů
  - [ ] Vytvoření memory dumpu před pozastavením
  - [x] Pokyny pro síťovou izolaci (v dokumentaci)
  - [x] `--dry-run` mód
  - [x] `--resume` mód pro odmrazení
  - [x] State file tracking

- [x] **`gh-scan-exfil.sh`** - GitHub API skener pro exfiltrační repozitáře ✅ Přidáno
  - [x] Vyhledávání repozitářů podle vzoru popisu (`Sha1-Hulud: The Second Coming`)
  - [x] Detekce náhodných 18-znakových názvů repozitářů (`[0-9a-z]{18}`)
  - [x] Seznam self-hosted runnerů
  - [x] Audit nedávných změn workflow

### Detekční schopnosti

- [x] Párování názvů balíčků
- [x] Párování vzorů souborů
- [ ] **Ověření hash souborů** (SHA256)
  - [ ] Známé hashe `setup_bun.js`
  - [ ] Známé hashe `bun_environment.js`
  - [ ] v1 hashe `bundle.js` (7 variant)
- [x] **Detekce síťových IOC** ✅ Přidáno `ioc/network.json` v v1.5.0
  - [x] Monitoring C2 domén
  - [x] Vzory exfiltračních webhooků
  - [x] Vzory zneužití GitHub API
  - [x] Detekce zneužití cloud metadata
  - [x] Doporučení pro firewall pravidla
  - [ ] Upozornění na podezřelá odchozí připojení (real-time)
- [ ] **Behaviorální analýza**
  - [ ] Detekce neočekávané instalace Bun
  - [ ] Detekce stahování TruffleHog
  - [ ] Detekce hromadného npm publish

---

## 📦 IOC databáze

### Aktuální stav: ~9 balíčků
### Cílový stav: 800+ balíčků s kompletními metadaty

### Seznamy balíčků

- [x] `ioc/malicious-packages.json` - Základní vysoce rizikové balíčky
  - [ ] Rozšířit na kompletní seznam 800+ balíčků
  - [ ] Přidat rozsahy verzí (nejen konkrétní verze)
  - [ ] Přidat data kompromitace
  - [ ] Přidat skóre rizika
  - [ ] Přidat stav remediace (opraveno/staženo/aktivní)

- [ ] **`ioc/packages-v1.json`** - Balíčky ze zářijové vlny 2025
  - [ ] ~500 balíčků z CISA alertu
  - [ ] `@ctrl/tinycolor`, `@crowdstrike/*`, atd.

- [ ] **`ioc/packages-v2.json`** - Balíčky z listopadové vlny 2025
  - [ ] 800+ balíčků z Datadog/Wiz
  - [ ] `@postman/*`, `@asyncapi/*`, `@zapier/*`, `@ensdomains/*`, `posthog-*`

- [ ] **`ioc/packages-maven.json`** - Maven Central crossover
  - [ ] `org.mvnpm:posthog-node:4.18.1`
  - [ ] Další npm-to-Maven mirrory

### Hash souborů

- [x] **`ioc/hashes.json`** - Známé hashe škodlivých souborů ✅ Přidáno

### Síťové IOC

- [ ] **`ioc/network.json`** - C2 a exfiltrační indikátory
  ```json
  {
    "c2_domains": [
      "shaihulud-c2.io",
      "shai-hulud.net"
    ],
    "c2_ips": ["185.199.108.153"],
    "exfil_webhooks": [
      "webhook.site/*bb8ca5f6-4175-45d2-b042-fc9ebb8170b7*"
    ],
    "github_patterns": [
      "description:Sha1-Hulud: The Second Coming",
      "description:Shai-Hulud Migration"
    ]
  }
  ```

### Behaviorální vzory

- [x] Vzory popisů GitHub repozitářů
- [x] Vzory workflow souborů
- [ ] Signatury chování procesů
- [ ] Artefakty souborového systému (`~/.dev-env/`, `.truffler-cache/`)

### Integrace IOC od vendorů

- [ ] **`ioc/vendor/`** - Snapshoty od bezpečnostních vendorů
  - [ ] Integrace Datadog IOC feedu
  - [ ] Wiz IOC seznam
  - [ ] Tenable seznam balíčků
  - [ ] SafeDep indikátory
  - [ ] Socket.dev alerty

- [x] **`scripts/update-iocs.sh`** - Auto-update z vendor zdrojů ✅ Přidáno
  - [x] Stahování nejnovějších dat z GitHub repozitářů (Datadog, Wiz, Tenable)
  - [x] Sloučení a deduplikace
  - [x] Generování changelogu

---

## 📚 Dokumentace

### Základní dokumenty

- [x] `README.md` - Přehled projektu
  - [x] Diagram toku útoku
  - [x] Příkazy pro rychlý start
  - [x] Porovnávací tabulka v1 vs v2
  - [x] Aktualizovat metriky (800+ balíčků, 1200+ organizací, 25k+ repozitářů)
  - [x] Přidat regex pro vzor názvu repozitáře `[0-9a-z]{18}`
  - [x] Mermaid diagram pro tok útoku

- [x] `docs/DETECTION.md` - Průvodce detekcí
- [x] `docs/REMEDIATION.md` - Kroky čištění
  - [ ] Přidat rozšíření GitHub Token Revocation Plan
  - [ ] Přidat sekci auditu OAuth Apps
  - [ ] Přidat průvodce obnovy "Co když se aktivoval wiper"

- [x] `docs/PREVENTION.md` - Průvodce hardeningem
- [x] `docs/GITHUB-HARDENING.md` - GitHub-specific bezpečnost
- [x] `docs/THREAT-OVERVIEW.md` - Threat intelligence
- [x] `docs/MACOS-AUDIT.md` - macOS-specific pokyny

### Stack-Specific dokumentace ✅ KOMPLETNÍ

- [x] **`docs/stacks/EXPO-REACT-NATIVE.md`** ✅ Přidáno
  - [x] Rizika z kompromitace `posthog-react-native`
  - [x] Expozice Metro bundleru
  - [x] Attack surface Expo CLI
  - [x] Doporučeno: `--ignore-scripts` v mobile CI
  - [x] Strategie pinningu analytics SDK

- [x] **`docs/stacks/BUN.md`** ✅ Přidáno
  - [x] Proč Bun NENÍ bezpečnější (je to attack vektor!)
  - [x] Hardening `bunfig.toml`
  - [x] Detekce neautorizovaných instalací Bun
  - [x] Inspekce `~/.bun` a `~/.dev-env`

- [x] **`docs/stacks/TYPESCRIPT-ASTRO.md`** ✅ Přidáno
  - [x] Rizika build pipeline
  - [x] Expozice Vite pluginů
  - [x] Dopad `@asyncapi/*`

- [x] **`docs/stacks/RUST-GO-TAURI.md`** ✅ Přidáno
  - [x] Cross-language krádež credentials
  - [x] Sdílená CI/CD rizika
  - [x] Expozice `node-gyp`, `wasm-pack`
  - [x] Doporučení pro izolaci Tauri buildů
  - [x] Ochrana signing klíčů

- [x] **`docs/stacks/MONOREPO.md`** ✅ Přidáno
  - [x] Rizika Turborepo/Nx workspace
  - [x] Expozice sdílených tokenů
  - [x] Strategie skenování per-package

### Překlady

- [x] Čeština (`cs/`) - Kompletní překlad
  - [x] README.md
  - [x] docs/* (všechny soubory)
  - [x] ROADMAP.md (tento soubor)

- [ ] Další jazyky (příspěvky komunity vítány)
  - [ ] Němčina (`de/`)
  - [ ] Španělština (`es/`)
  - [ ] Japonština (`ja/`)

---

## ⚙️ Automatizace & CI/CD

### GitHub Actions Workflow

- [x] `ci.yml` - Základní CI
- [x] `supply-chain-security.yml` - Security scanning
- [x] `release.yml` - Release automatizace
- [x] `set-language.yml` - Přepínání jazyka
- [x] `pr-changelog.yml` - Generování changelogu PR

- [ ] **`ioc-update.yml`** - Automatické aktualizace IOC
  - [ ] Denní/týdenní cron job
  - [ ] Stahování z vendor zdrojů
  - [ ] Auto-PR se změnami
  - [ ] Generování changelogu

- [ ] **`community-scan.yml`** - Umožnit uživatelům spouštět skeny
  - [ ] Workflow dispatch s URL repozitáře jako vstupem
  - [ ] Výsledky jako PR komentář nebo artefakt

### Konfigurační šablony

- [x] `configs/renovate-secure.json` - Bezpečná Renovate konfigurace
- [x] `configs/renovate-hardened.json` - Hardened konfigurace
- [x] `configs/renovate-lockdown.json` - Maximální bezpečnost

- [x] **`configs/renovate-defense.json`** - Anti-worm specifická pravidla ✅ Přidáno

- [x] `configs/dependabot.yml` - Dependabot konfigurace
- [x] `configs/socket.yml` - Socket.dev policy
- [x] `configs/.npmrc-secure` - Bezpečná npm konfigurace

- [x] **`configs/bunfig-secure.toml`** - Bun security konfigurace ✅ Přidáno
  - [x] Vypnutí postinstall ve výchozím stavu
  - [x] Ověření integrity

- [x] **`configs/pnpm-workspace-secure.yaml`** - pnpm bezpečnost ✅ Přidáno
  - [x] Omezení lifecycle skriptů

### Výstupní formáty

- [x] Prostý text s barvami
- [x] **JSON výstup** (`--format json`) ✅ Přidáno
- [x] **SARIF výstup** (`--format sarif`) ✅ Přidáno
  - [x] Integrace s GitHub Security tabem
  - [x] CodeQL kompatibilita
- [ ] **Markdown report** (`--format md`)
- [ ] **HTML report** (`--format html`)

---

## 🔧 Nástroje

### Vylepšení CLI

- [x] **npx podpora** - `npx hulud scan .`
  - [x] `bin/cli.js` entry point
  - [x] `package.json` bin pole
  - [x] Cross-platform kompatibilita

- [ ] **Interaktivní mód** - Průvodce remediací
  - [ ] Step-by-step wizard
  - [ ] Potvrzovací prompty pro destruktivní akce

- [ ] **Whitelist/Ignore** funkcionalita
  - [ ] `--ignore <package>` příznak
  - [ ] Podpora `.shyhulud-ignore` souboru
  - [ ] Hlášení false positive

### Kontejnerizace

- [x] **Dockerfile** - Izolované skenovací prostředí ✅ Přidáno
  - [x] Alpine-based minimální image
  - [x] Non-root uživatel pro bezpečnost
  - [x] Volume mounting pro cílové adresáře
  - [ ] Multi-arch podpora (amd64, arm64)

- [x] **Docker Compose** - Kompletní skenovací stack ✅ Přidáno
  - [x] Scanner service
  - [x] Interaktivní shell service
  - [x] Batch scanner service
  - [ ] Databáze výsledků
  - [ ] Web dashboard (budoucnost)

### IDE Integrace

- [x] VS Code tasks (`tasks.json`)
- [x] VS Code workspace nastavení
- [ ] **VS Code extension** (budoucnost)
  - [ ] Real-time skenování
  - [ ] Inline varování
  - [ ] Quick fixes

### Monitoring & Alerting

- [ ] **Webhook integrace**
  - [ ] Slack notifikace
  - [ ] Discord notifikace
  - [ ] Microsoft Teams
  - [ ] Generický webhook endpoint

- [ ] **GitHub App** (budoucnost)
  - [ ] Automatické PR skenování
  - [ ] Org-wide monitoring
  - [ ] Plánované audity

---

## 🌐 Komunita & Ekosystém

### Projektová infrastruktura

- [x] MIT Licence
- [x] Code of Conduct
- [x] Contributing guidelines
- [x] Security policy
- [x] Issue templates
- [x] PR template
- [ ] **GitHub Discussions** - Povolit a nastavit kategorie
- [ ] **GitHub Sponsors** - Funding tiers
- [ ] **Open Collective** - Alternativní funding

### Obsah & Outreach

- [ ] **Série článků** (5-dílný plán)
  - [ ] Část 1: Přehled & Timeline
  - [ ] Část 2: Technický Deep-Dive
  - [ ] Část 3: Hands-on Remediation
  - [ ] Část 4: Prevence & Hardening
  - [ ] Část 5: Nástroje & Automatizace

- [ ] **Blog posty**
  - [ ] dev.to
  - [ ] Hashnode
  - [ ] Medium

- [ ] **Sociální média**
  - [ ] Twitter/X oznámení
  - [ ] LinkedIn post
  - [ ] Reddit (r/javascript, r/node, r/netsec)
  - [ ] Hacker News

### Integrace

- [ ] **Socket.dev** - Oficiální integrační průvodce
- [ ] **Snyk** - Policy šablony
- [ ] **Dependabot** - Alert korelace
- [ ] **GitHub Advisory Database** - CVE submissions (pokud je to relevantní)

### Uznání

- [x] Sekce credits v README
- [ ] Stránka přispěvatelů
- [ ] Uznání bezpečnostním výzkumníkům
- [ ] Atribuce vendorů (Datadog, Wiz, SafeDep, atd.)

---

## 🚨 Kritické bezpečnostní poznámky

### Varování Dead Man's Switch

> ⚠️ **KRITICKÉ**: Malware Shai-Hulud 2.0 obsahuje destruktivní "dead man's switch". Pokud exfiltrace nebo propagace selže, pokusí se **smazat celý `$HOME` adresář**.

**Bezpečné postupy manipulace:**

1. **NEUKONČUJTE** škodlivé procesy pomocí `SIGKILL` nebo `SIGTERM`
2. **POUŽIJTE** `SIGSTOP` k zmrazení procesů nejprve
3. **VYTVOŘTE** snapshoty/zálohy před jakoukoliv akcí
4. **NEODPOJUJTE** síť dokud není proces zmrazen
5. **MĚJTE** připravený plán obnovy

### Doporučení pro testování

Pro přispěvatele testující detekční schopnosti:

| Metoda                     | Úroveň bezpečnosti | Poznámky                     |
| -------------------------- | ------------------ | ---------------------------- |
| VM (UTM/Parallels/VMware)  | ✅ Nejbezpečnější   | Plná izolace                 |
| Docker container           | ✅ Bezpečné         | Dobré pro testování skriptů  |
| Separátní uživatelský účet | ⚠️ Částečné         | `$HOME` stále v riziku       |
| Produkční stroj            | ❌ Nebezpečné       | Nikdy netestujte na produkci |

**Vždy:**
- Mějte připravený Time Machine / zálohu
- Testujte nejprve v izolovaném prostředí
- Zkontrolujte skripty před spuštěním

---

## 📅 Release milníky

### v1.5.0 (Vydáno)
- [x] SIGSTOP suspend script
- [x] Rozšířená IOC databáze (100+ balíčků)
- [x] Síťové IOC
- [x] Ověření hash souborů
- [x] Stack-specific dokumentace (všech 5!)

### v1.2.0
- [ ] Kompletní IOC databáze (500+ balíčků)
- [ ] JSON/SARIF výstup
- [ ] GitHub API skener
- [ ] Automatické IOC aktualizace

### v1.3.0
- [ ] npx podpora
- [ ] Docker image
- [ ] Webhook notifikace
- [ ] Interaktivní mód

### v2.0.0 (Budoucnost)
- [ ] GitHub App
- [ ] Web dashboard
- [ ] VS Code extension
- [ ] Enterprise funkce

---

## 🤝 Jak přispět

1. **Vyberte si nezaškrtnutou položku** z této roadmapy
2. **Otevřete issue** k diskuzi o přístupu (volitelné ale doporučené)
3. **Forkněte a implementujte**
4. **Pošlete PR** s odkazem na položku roadmapy
5. **Nechte se zrevidovat a mergovat**

### Good First Issues

Hledejte položky s nízkým úsilím:
- Vylepšení dokumentace
- Pomoc s překlady
- Rozšíření IOC seznamu (manuální výzkum)
- Tvorba konfiguračních šablon

### High Impact příspěvky

- SIGSTOP suspend script
- GitHub API skener
- SARIF výstupní formát
- Stack-specific dokumentace

---

## 📖 Reference & Zdroje

### Reporty bezpečnostních vendorů
- [Wiz - Shai-Hulud 2.0 Analysis](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [Datadog - NPM Worm Technical Analysis](https://securitylabs.datadoghq.com/articles/shai-hulud-2-0-npm-worm/)
- [Check Point - The Second Coming](https://blog.checkpoint.com/research/shai-hulud-2-0-inside-the-second-coming/)
- [Unit 42 - Supply Chain Attack](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [SafeDep - Technical Analysis](https://safedep.io/shai-hulud-second-coming-supply-chain-attack/)

### Oficiální doporučení
- [CISA - Widespread Supply Chain Compromise](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)
- [npm Security Advisory](https://github.blog/security/)

### Komunitní zdroje
- [Cobenian/shai-hulud-detect](https://github.com/Cobenian/shai-hulud-detect)
- [GrzechuG/compromised-npm-shai-hulud](https://github.com/GrzechuG/compromised-npm-shai-hulud)

---

<p align="center">
  <i>Tato roadmapa je živý dokument. Poslední aktualizace: 2025-12-04</i>
</p>
