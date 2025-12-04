# 🥟 Bun Security Guide

> **Proč Bun NENÍ bezpečnější — je to vektor útoku!**

Shai-Hulud 2.0 specificky instaluje Bun runtime jako **techniku úniku detekce**, protože většina bezpečnostních nástrojů monitoruje pouze Node.js procesy.

## ⚠️ Kritické varování

```
┌─────────────────────────────────────────────────────────────────┐
│  🚨 BUN JE POUŽÍVÁN SHAI-HULUD 2.0 K ÚNIKU DETEKCE 🚨          │
│                                                                 │
│  Malware instaluje Bun pro spuštění payloadu protože:           │
│  • Většina EDR/security nástrojů nemonitoruje Bun procesy       │
│  • Bun's .npmrc ignore-scripts=true je NESPOLEHLIVÉ             │
│  • Bun má interní trustedDependencies které přepisují configy   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Detekce

### Kontrola neautorizovaných instalací Bun

```bash
# Kontrola běžných lokací instalace Bun
ls -la ~/.bun 2>/dev/null
ls -la ~/.dev-env 2>/dev/null
ls -la /usr/local/bin/bun 2>/dev/null

# Kontrola zda byl Bun nainstalován nedávno (podezřelé pokud jste ho neinstalovali)
stat ~/.bun/bin/bun 2>/dev/null | grep -E "(Birth|Change)"

# Kontrola Bun procesů
ps aux | grep -i bun | grep -v grep

# Kontrola IOC souborů v Bun cache
find ~/.bun -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null
```

### Kontrola škodlivé Bun aktivity

```bash
# Hledání .truffler-cache (artefakt malwaru)
ls -la ~/.truffler-cache 2>/dev/null

# Kontrola podezřelých environment souborů
ls -la ~/.dev-env 2>/dev/null

# Kontrola Bun's global cache na IOCs
find ~/.bun/install/cache -name "*.js" -exec grep -l "Sha1-Hulud\|Second Coming" {} \; 2>/dev/null
```

## 🛡️ Hardening

### Bug v `.npmrc`

**Bun má známý bug**: Nastavení `.npmrc` `ignore-scripts=true` **NEFUNGUJE** spolehlivě!

Bun upřednostňuje interní `trustedDependencies` allowlist před `.npmrc` nastaveními.

```bash
# ❌ Toto NENÍ spolehlivé v Bun:
echo "ignore-scripts=true" >> .npmrc

# ✅ VŽDY použijte CLI flag:
bun install --ignore-scripts
```

### Bezpečný `bunfig.toml`

Vytvořte `bunfig.toml` v kořenu projektu:

```toml
[install]
# Zakázat lifecycle scripty (VAROVÁNÍ: nemusí být plně respektováno!)
ignoreScripts = true

# Použít přesné verze
exact = true

# Ověřit integritu balíčků
verify = true

# Zakázat optional dependencies
optional = false

# Zmrazit lockfile
frozenLockfile = true

[install.lockfile]
# Uložit lockfile v binárním formátu
saveBinaryLockfile = true
```

> **Poznámka**: I s tímto configem VŽDY používejte `bun install --ignore-scripts`!

### CI/CD konfigurace

```yaml
# GitHub Actions příklad
- name: Install dependencies (Bun)
  run: |
    # POVINNÉ: Vždy použijte --ignore-scripts flag
    bun install --ignore-scripts --frozen-lockfile

    # Ověřte že nebyly nainstalovány IOC soubory
    if find node_modules -name "setup_bun.js" -o -name "bun_environment.js" 2>/dev/null | grep -q .; then
      echo "🚨 Detekovány IOC soubory!"
      exit 1
    fi
```

## 🔒 Doporučené postupy

### 1. Audit zdroje instalace Bun

```bash
# Zkontrolujte jak byl Bun nainstalován
which bun
bun --version

# Ověřte hash Bun binárky (očekávaný hash získejte z bun.sh)
shasum -a 256 $(which bun)
```

### 2. Monitorování Bun procesů

```bash
# Přidejte do vašeho monitoringu/alertingu
# Alert pokud Bun běží mimo očekávané kontexty

# Příklad: Logování všech Bun spuštění
alias bun='echo "[$(date)] bun $@" >> ~/.bun-audit.log && command bun "$@"'
```

### 3. Uzamknutí `trustedDependencies`

Bun má interní allowlist. Zkontrolujte a auditujte ho:

```bash
# Zobrazit Bun's trusted dependencies (pokud je exponováno)
cat ~/.bun/install/trusted-dependencies.json 2>/dev/null
```

### 4. Inspekce Bun Lockfile

```bash
# Kontrola bun.lockb na podezřelé balíčky
# Poznámka: bun.lockb je binární, použijte bun pro inspekci
bun pm ls --all | grep -E "(posthog|@postman|@asyncapi|@zapier|@ensdomains)"
```

## 🚨 Pokud máte podezření na kompromitaci

### Okamžité akce

1. **NEZABÍJEJTE** Bun procesy pomocí `SIGKILL` (spustí wiper!)
2. **Zmrazte** proces nejdříve:
   ```bash
   # Najděte Bun PID
   pgrep -f bun

   # Zmrazte ho (SIGSTOP)
   kill -STOP <PID>
   ```

3. **Zálohujte** před jakýmkoli čištěním:
   ```bash
   # Vytvořte snapshot home adresáře
   tar -czf ~/backup-$(date +%Y%m%d).tar.gz ~/ --exclude=backup-*.tar.gz
   ```

4. **Zkontrolujte exfiltraci**:
   ```bash
   # Prohledejte váš GitHub na podezřelé repos
   gh repo list --json name,description | jq '.[] | select(.description | contains("Hulud"))'
   ```

### Čištění

```bash
# Kompletně odstraňte Bun (po záloze!)
rm -rf ~/.bun
rm -rf ~/.dev-env
rm -rf ~/.truffler-cache

# Odstraňte z PATH
# Editujte ~/.zshrc nebo ~/.bashrc a odstraňte Bun cesty

# Reinstalujte Bun z oficiálního zdroje pokud potřeba
curl -fsSL https://bun.sh/install | bash
```

## 📚 Související dokumentace

- [Hlavní detekční guide](../DETECTION.md)
- [Remediation guide](../REMEDIATION.md)
- [bunfig-secure.toml šablona](../../configs/bunfig-secure.toml)
- [Přehled hrozby](../THREAT-OVERVIEW.md)

## 🔗 Externí zdroje

- [Bun oficiální dokumentace](https://bun.sh/docs)
- [Datadog Shai-Hulud analýza](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)

---

> ⚠️ **Pamatujte**: Rychlost Bun přichází s bezpečnostními kompromisy. V kontextu Shai-Hulud 2.0 je Bun součástí útočného řetězce, ne obranou.
