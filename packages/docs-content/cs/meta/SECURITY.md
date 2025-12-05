# Bezpečnostní politika

## Podporované verze

Vydáváme opravy pro bezpečnostní zranitelnosti. Následující verze jsou aktuálně podporovány bezpečnostními aktualizacemi.

| Verze | Podporováno        |
| ----- | ------------------ |
| 1.x.x | :white_check_mark: |
| < 1.0 | :x:                |

## Nahlášení zranitelnosti

**Prosím, nenahlašujte bezpečnostní zranitelnosti prostřednictvím veřejných GitHub issues.**

Místo toho je prosím nahlaste jedním z následujících způsobů:

### Soukromé bezpečnostní upozornění (Preferováno)

1. Přejděte na stránku [Security Advisories](https://github.com/miccy/dont-be-shy-hulud/security/advisories)
2. Klikněte na "New draft security advisory"
3. Vyplňte podrobnosti

### E-mail

Pošlete e-mail na: **support@miccy.dev** nebo vytvořte soukromé upozornění výše.

### Co uvést

Prosím, uveďte co nejvíce z následujících informací:

- Typ problému (např. přetečení vyrovnávací paměti, SQL injection, cross-site scripting atd.)
- Úplné cesty ke zdrojovým souborům souvisejícím s projevem problému
- Umístění dotčeného zdrojového kódu (tag/větev/commit nebo přímá URL)
- Jakákoli speciální konfigurace vyžadovaná pro reprodukci problému
- Pokyny krok za krokem pro reprodukci problému
- Proof-of-concept nebo exploit kód (pokud je to možné)
- Dopad problému, včetně toho, jak by jej mohl útočník zneužít

### Časový rámec odezvy

- **Počáteční reakce**: Do 48 hodin
- **Aktualizace stavu**: Do 7 dnů
- **Časový rámec opravy**: Závisí na závažnosti (Kritické: 24-48h, Vysoká: 1 týden, Střední: 2 týdny)

## Co očekávat

1. **Potvrzení**: Potvrdíme přijetí vašeho hlášení o zranitelnosti
2. **Vyšetřování**: Problém prošetříme a ověříme
3. **Vývoj opravy**: Vyvineme opravu
4. **Koordinované zveřejnění**: Zkoordinujeme s vámi veřejné zveřejnění
5. **Uvedení zásluh**: Uvedeme vás v bezpečnostním upozornění (pokud nepreferujete anonymitu)

## Bezpečnostní opatření v tomto repozitáři

Tento repozitář implementuje několik bezpečnostních opatření:

### Bezpečnost kódu

- **Skenování závislostí**: Automatizováno pomocí Dependabot
- **Skenování tajných údajů**: Povoleno
- **Skenování kódu**: Analýza CodeQL
- **Integrace Socket.dev**: Monitorování bezpečnosti dodavatelského řetězce

### Vývojové postupy

- **Podepsané commity**: Vyžadováno pro správce
- **Ochrana větví**: Vynuceno na hlavní větvi
- **Vyžadované revize**: Všechny PR vyžadují revizi
- **Bezpečnost CI/CD**: Minimální oprávnění, žádná tajemství v logách

### Bezpečnost dodavatelského řetězce

- **Ověření lockfile**: Všechny závislosti jsou fixovány
- **Audit skriptů**: Instalační skripty jsou ve výchozím nastavení zakázány
- **Monitorování IOC**: Pravidelné aktualizace od bezpečnostních dodavatelů
- **Ověření dodavatelů**: Všechny IOC jsou křížově odkazovány

## Rozsah

### V rozsahu

- Detekční skripty (falešná pozitiva, falešná negativa)
- Přesnost databáze IOC
- Bezpečnostní pokyny v dokumentaci
- Konfigurační šablony
- Infrastruktura repozitáře

### Mimo rozsah

- Zranitelnosti v nástrojích třetích stran (Socket.dev, npm atd.)
- Problémy v balíčcích uvedených v databázi IOC (nahlaste npm/dodavatelům)
- Útoky sociálního inženýrství
- Fyzická bezpečnost

## Bezpečnostní doporučení pro uživatele

Při používání tohoto repozitáře:

1. **Ověřujte IOC**: Křížově odkazujte s oficiálními zdroji dodavatelů
2. **Kontrolujte skripty**: Před spuštěním se zvýšenými oprávněními zkontrolujte skripty
3. **Pravidelně aktualizujte**: Často stahujte nejnovější aktualizace IOC
4. **Nahlašujte zjištění**: Pomozte nám zlepšovat se nahlášením falešných pozitiv/negativ
5. **Zabezpečte své přihlašovací údaje**: Postupujte podle průvodce nápravou pro rotaci přihlašovacích údajů

## Program odměn za chyby (Bug Bounty)

V současné době **nemáme** program odměn za chyby. Hluboce si však vážíme bezpečnostních výzkumníků, kteří dodržují postupy odpovědného zveřejňování, a jejich příspěvky viditelně oceníme.

## Kontakt

- **Bezpečnostní problémy**: Použijte GitHub Security Advisory nebo e-mail
- **Obecné dotazy**: Otevřete GitHub Discussion
- **X/Twitter**: [@miccycz](https://x.com/miccycz)
- **Bluesky**: [@miccy-dev](https://bsky.app/profile/miccy-dev.bsky.social)
- **Mastodon**: [@miccy](https://mastodon.social/@miccy)
- **Email**: [support@miccy.dev](mailto:support@miccy.dev)

## PGP Klíč

Pokud chcete zašifrovat své bezpečnostní hlášení:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[Zde vložte svůj PGP klíč, pokud jej máte]
-----END PGP PUBLIC KEY BLOCK-----
```

---

## Právní

Nebudeme podnikat právní kroky proti výzkumníkům, kteří:

- Vynaloží úsilí v dobré víře, aby se vyhnuli porušení soukromí, zničení dat a přerušení služeb
- Interagují pouze s účty, které vlastní, nebo s výslovným svolením
- Nezneužijí zranitelnost nad rámec toho, co je nutné k potvrzení její existence
- Nahlásí zranitelnost neprodleně
- Udrží zranitelnost v tajnosti, dokud nebudeme mít přiměřený čas na její opravu

Děkujeme, že pomáháte udržovat Don't Be Shy, Hulud a naše uživatele v bezpečí! 🛡️
