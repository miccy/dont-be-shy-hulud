# Přispívání do Hunting Worms Guide

Děkujeme za zájem o přispívání! Tento průvodce pomáhá vývojářům chránit se před supply chain útoky.

## Jak přispět

### Hlášení nových IOC

Pokud objevíš nové indikátory kompromitace:

1. **NEVYTVÁŘEJ** veřejný issue s citlivými daty
2. Otevři PR s přidáním IOC do příslušného seznamu
3. Zahrň:
   - Název a verze package
   - File hashes (SHA-256)
   - Zdroj/reference

### Přidání vylepšení detekce

1. Forkni repo
2. Vytvoř branch: `git checkout -b feature/detection-improvement`
3. Otestuj své změny
4. Odešli PR

### Dokumentace

- Oprav překlepy a nejasná vysvětlení
- Přidej překlady
- Vylepši příklady
- Přidej konfigurace nových nástrojů

## Pravidla

### Styl kódu

- Bash scripty: Používej `shellcheck`
- Markdown: Používej konzistentní formátování
- JSON: Validuj pomocí `jq`

### Commit zprávy

```
type(scope): popis

Příklady:
feat(detect): přidat skenování yarn.lock
fix(script): zpracovat mezery v cestách
docs(readme): aktualizovat IOC list
```

### Proces Pull Requestu

1. Aktualizuj README.md pokud potřeba
2. Aktualizuj CHANGELOG.md
3. Testuj na macOS a Linux
4. Požádej o review

## Prioritní oblasti

- [ ] Více IOC z vendor reportů
- [ ] Podpora Yarn Berry (PnP)
- [ ] Parsování pnpm lockfile
- [ ] Podpora Windows
- [ ] Skenování Docker containerů
- [ ] Příklady CI/CD (GitLab CI, CircleCI, atd.)
- [ ] Překlady (čeština, němčina, atd.)

## Otázky?

Otevři diskusi nebo se ozvi na Twitteru/X.

## License

Přispěním souhlasíš, že tvé příspěvky budou licencovány pod MIT.
