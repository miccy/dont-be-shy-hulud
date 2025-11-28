# Průvodce pro AI Asistenty

> Pokyny pro AI asistenty pracující s tímto repozitářem

## Přehled projektu

**Don't Be Shy, Hulud** je průvodce incident response a ochranou proti npm supply chain útokům, konkrétně zaměřený na Shai-Hulud 2.0 worm (listopad 2025) a podobné hrozby.

### Účel repozitáře

Tento repozitář poskytuje:
- Detekční skripty pro supply chain malware
- Remediation workflows
- Best practices pro prevenci
- IOC (Indicators of Compromise) databáze
- Šablony bezpečnostních konfigurací

### Cílové publikum

- JavaScript/TypeScript vývojáři
- DevOps inženýři
- Security týmy
- Organizace používající npm/bun ekosystém

## Struktura repozitáře

```
dont-be-shy-hulud/
├── docs/
│   ├── en/          # Anglická dokumentace
│   └── cs/          # Česká dokumentace
├── scripts/         # Detekční a audit skripty
├── configs/         # Šablony bezpečnostních konfigurací
├── ioc/             # Databáze indikátorů kompromitace
└── .agents/         # Nástroje a workflows pro AI asistenty
```

## Jazyková podpora

Tento repozitář je **dvojjazyčný (EN/CS)**:
- **Primární**: Angličtina (EN)
- **Sekundární**: Čeština (CS)

### Dokumentační soubory
- Všechny `.md` soubory v `docs/` mají EN i CS verze
- Root README: `README.md` (EN), `README-cs.md` (CS)
- CONTRIBUTING: `CONTRIBUTING.md` (EN), `CONTRIBUTING-cs.md` (CS)

### Kódové soubory
- Skripty (`.sh`): Pouze anglické komentáře
- Konfigurace (`.json`, `.yml`): Pouze anglické komentáře
- Budoucnost: i18n podpora pro zprávy ve skriptech

## Technický kontext

### Shai-Hulud 2.0 útok

Tento malware je self-propagating worm, který:
1. Spouští se přes `preinstall` lifecycle skripty
2. Sbírá credentials (npm, GitHub, AWS, GCP, Azure)
3. Exfiltruje přes GitHub repos
4. Self-propaguje do npm packages oběti
5. Instaluje Bun runtime k vyhnutí detekci

**Klíčové IOC soubory:**
- `setup_bun.js` - Loader
- `bun_environment.js` - Hlavní payload (~500KB obfuskovaný)
- `.truffler-cache` adresář
- GitHub repos s popisem: "Sha1-Hulud: The Second Coming"

### Detekční nástroje

Primární nástroje odkazované:
- Socket.dev (supply-chain security)
- npm audit (vestavěný)
- Renovate (dependency updates)
- Snyk (vulnerability scanning)

## Pokyny pro AI Asistenty

### Při pomoci uživatelům

1. **Security First**: Toto je security-sensitive práce. Buď přesný a důkladný.

2. **Zkontroluj jazykovou preferenci**: 
   - Pokud uživatel píše česky, odpovídej česky
   - Pokud uživatel píše anglicky, odpovídej anglicky
   - Oba jazyky by měly mít feature parity

3. **Udržuj dvojjazyčnou konzistenci**:
   - Při aktualizaci docs, aktualizuj OBA jazyky
   - Technické termíny (CVE, IOC, atd.) zůstávají anglicky v obou verzích
   - Kódové příklady by měly být identické

4. **Úpravy skriptů**:
   - Testuj že skripty jsou bezpečné před navrhováním
   - Používej shellcheck pro validaci
   - Zvaž macOS I Linux kompatibilitu

5. **Aktualizace dokumentace**:
   - Následuj existující markdown styl
   - Zahrň kódové příklady kde vhodné
   - Linkuj na oficiální vendor dokumentaci

### Priorit úkolů

Při provádění změn, priorizuj v tomto pořadí:

1. ✅ **Kritické security aktualizace** (nové IOC, opravy zranitelností)
2. ✅ **Rozbitá funkcionalita** (skripty, odkazy)
3. ✅ **Přesnost dokumentace** (zastaralé info)
4. ⚠️ **Vylepšení** (nové funkce, refactoring)
5. ℹ️ **Styl/formátování** (kosmetické změny)

### Zakázané akce

❌ **NIKDY**:
- Auto-spouštět security skripty bez potvrzení uživatele
- Commitovat citlivá data (credentials, tokeny)
- Upravovat IOC listy bez verifikace
- Dělat breaking changes v public API (rozhraní skriptů)
- Odstraňovat safety checky z detekčních skriptů

### Časté úkoly

#### Přidání nového IOC

1. Ověř IOC z oficiálního zdroje
2. Přidej do `ioc/malicious-packages.json`
3. Aktualizuj dokumentaci pokud potřeba
4. Commitni s message: `feat(ioc): add [package-name] IOC`

#### Aktualizace dokumentace

1. Zkontroluj zda změna ovlivňuje EN i CS
2. Aktualizuj obě verze
3. Ověř že všechny odkazy fungují
4. Commitni s scope: `docs(en)` nebo `docs(cs)` nebo `docs(all)`

#### Přidání detekční logiky

1. Přidej do příslušného skriptu v `scripts/`
2. Testuj na macOS
3. Ověř pomocí shellcheck
4. Dokumentuj v příslušném průvodci (DETECTION.md)
5. Aktualizuj CHANGELOG.md

## Skills a nástroje

Umístěné v `.agents/skills/`:

- `shai-hulud-detector.json` - Automatizace detekce
- `shai-hulud-remediation.json` - Remediation workflows

Viz `.agents/README.md` pro instrukce použití.

## Reference

### Externí dokumentace
- [npm Security Best Practices](https://docs.npmjs.com/packages-and-modules/securing-your-code)
- [Socket.dev Documentation](https://socket.dev/docs)
- [CISA Alert](https://www.cisa.gov/news-events/alerts/2025/09/23/widespread-supply-chain-compromise-impacting-npm-ecosystem)

### Vendor IOC listy
- [Datadog IOCs](https://github.com/DataDog/indicators-of-compromise/tree/main/shai-hulud-2.0)
- [Tenable Package List](https://github.com/tenable/shai-hulud-second-coming-affected-packages)
- [Wiz Research](https://github.com/wiz-sec-public/wiz-research-iocs)

## Informace o verzi

- **Repozitář**: https://github.com/miccy/dont-be-shy-hulud
- **License**: MIT
- **Maintainer**: @miccy
- **Status**: Aktivní vývoj (příprava na public release)

---

**Pro AI Asistenty**: Pokud si nejsi jistý, zeptej se uživatele. Security práce vyžaduje spolupráci a verifikaci.
