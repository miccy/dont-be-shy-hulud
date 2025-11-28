# 🔧 Common Issues & False Positives

> Časté nálezy ze security scanů a jak je řešit

## Obsah

- [Transitivní závislosti](#transitivní-závislosti)
- [Podobně pojmenované packages](#podobně-pojmenované-packages)
- [False Positives](#false-positives)
- [Deprecated packages](#deprecated-packages)

---

## Transitivní závislosti

### Problém: Stará verze package, kterou přímo nepoužíváš

Socket/Snyk/npm audit hlásí zranitelnost v package, který není v tvém `package.json`.

**Příklad:**
```
CRITICAL: lodash@3.10.1 has known vulnerabilities
```

Ale v package.json lodash nemáš!

### Řešení

1. **Zjisti odkud přichází:**
   ```bash
   # npm
   npm ls lodash
   
   # bun
   bun pm why lodash
   
   # yarn
   yarn why lodash
   ```

2. **Výstup ukáže dependency tree:**
   ```
   legenda-bar@0.0.1
   └─┬ biome@0.3.3
     └── lodash@3.10.1
   ```

3. **Řešení podle situace:**
   - Updatuj parent package
   - Nahraď parent package alternativou
   - Použij `overrides` (npm) nebo `resolutions` (yarn)

### Vynucení novější verze (npm overrides)

```json
{
  "overrides": {
    "lodash": "^4.17.21"
  }
}
```

### Vynucení novější verze (yarn resolutions)

```json
{
  "resolutions": {
    "lodash": "^4.17.21"
  }
}
```

---

## Podobně pojmenované packages

### 🚨 NEBEZPEČÍ: Typosquatting

Útočníci registrují packages s podobnými názvy jako populární knihovny.

### Příklad: `biome` vs `@biomejs/biome`

| Package | Status | Popis |
|---------|--------|-------|
| `biome` | ❌ ŠPATNĚ | Starý, deprecated package, má staré závislosti |
| `@biomejs/biome` | ✅ SPRÁVNĚ | Oficiální Biome linter/formatter |

**Jak se to stane:**
```bash
# Člověk napíše
npm install biome  # ❌ Špatný package!

# Měl napsat
npm install @biomejs/biome  # ✅ Správný package
```

### Další známé případy

| Špatně | Správně |
|--------|---------|
| `lodash.js` | `lodash` |
| `react-js` | `react` |
| `node-fetch` | `node-fetch` (ale pozor na verze) |
| `colors` (>=1.4.1) | `colors` (<=1.4.0) nebo `picocolors` |

### Jak ověřit package

```bash
# Zkontroluj metadata
npm view biome
npm view @biomejs/biome

# Porovnej:
# - Autor/organizace
# - Počet stažení
# - Poslední update
# - Repository URL
```

---

## False Positives

### `unstableOwnership` pro velké projekty

**Packages které často hlásí false positive:**

| Package | Důvod |
|---------|-------|
| `workbox-*` | Google interní procesy, časté změny ownership |
| `@biomejs/*` | Aktivní vývoj, reorganizace |
| `@babel/*` | Velký tým, změny maintainerů |
| `@types/*` | DefinitelyTyped má mnoho kontributorů |

**Akce:** Můžeš ignorovat, ale sleduj changelogy.

### `obfuscatedFile` pro legitimní packages

Některé packages mají minifikovaný kód, který vypadá jako obfuskace:

- `safer-buffer` - legitimní, ale má minifikovaný test
- `registry-auth-token` - legitimní

**Akce:** Zkontroluj na npm/GitHub, pokud je to známý package, můžeš ignorovat.

### `gitHubDependency` 

Package závisí přímo na GitHub repo místo npm registry.

```json
{
  "dependencies": {
    "some-pkg": "github:user/repo#branch"
  }
}
```

**Rizika:**
- Repo může být smazáno
- Commit může být přepsán
- Obtížnější audit

**Akce:** Preferuj npm registry, nebo pin na konkrétní commit SHA.

---

## Deprecated packages

### Jak najít deprecated packages

```bash
npm outdated
npm audit
```

### Běžné deprecated packages a jejich náhrady

| Deprecated | Náhrada |
|------------|---------|
| `request` | `node-fetch`, `axios`, `got` |
| `node-uuid` | `uuid` |
| `istanbul` | `nyc` nebo `c8` |
| `tslint` | `eslint` + `@typescript-eslint` |
| `moment` | `date-fns`, `dayjs`, `luxon` |
| `faker` | `@faker-js/faker` |
| `colors` (compromised) | `picocolors`, `chalk` |

### Automatická detekce

```bash
# npm
npx npm-check -u

# nebo
npx depcheck
```

---

## Praktický příklad: Oprava legenda-bar

### Problém

Socket.dev hlásí:
```
CRITICAL: lodash@3.10.1 - multiple CVEs
CRITICAL: form-data@2.3.3 - CVE
```

Ale v package.json tyto packages nejsou!

### Diagnostika

```bash
cd legenda-bar

# Zjisti závislosti
npm ls lodash
# Výstup:
# └─┬ biome@0.3.3
#   └── lodash@3.10.1

npm ls form-data
# Výstup:
# └─┬ biome@0.3.3
#   └─┬ some-dep
#     └── form-data@2.3.3
```

### Příčina

`biome@0.3.3` je **špatný package** - měl být `@biomejs/biome`.

### Oprava

```bash
# 1. Odstraň špatný package
npm uninstall biome

# 2. Nainstaluj správný
npm install -D @biomejs/biome

# 3. Vyčisti
rm -rf node_modules package-lock.json
npm install

# 4. Ověř
npm ls lodash  # Mělo by být prázdné
npm audit      # Mělo by být clean
```

### Aktualizovaný package.json

```json
{
  "devDependencies": {
    "@biomejs/biome": "^2.3.4",
    "@types/react": "^19.2.6",
    "@types/react-dom": "^19.2.3"
  }
}
```

---

## Checklist pro nový projekt

- [ ] Používám správné názvy packages (s @scope kde je potřeba)?
- [ ] Mám aktuální verze všech dependencies?
- [ ] Spustil jsem `npm audit` před prvním deployem?
- [ ] Nemám deprecated packages?
- [ ] Zkontroloval jsem transitivní závislosti?
