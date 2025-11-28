# 🔧 Common Issues & False Positives

> Common findings from security scans and how to resolve them

## Contents

- [Transitive Dependencies](#transitive-dependencies)
- [Similarly Named Packages](#similarly-named-packages)
- [False Positives](#false-positives)
- [Deprecated Packages](#deprecated-packages)

---

## Transitive Dependencies

### Problem: Old version of a package you don't directly use

Socket/Snyk/npm audit reports a vulnerability in a package that's not in your `package.json`.

**Example:**
```
CRITICAL: lodash@3.10.1 has known vulnerabilities
```

But you don't have lodash in package.json!

### Solution

1. **Find where it comes from:**
   ```bash
   # npm
   npm ls lodash
   
   # bun
   bun pm why lodash
   
   # yarn
   yarn why lodash
   ```

2. **Output shows dependency tree:**
   ```
   legenda-bar@0.0.1
   └─┬ biome@0.3.3
     └── lodash@3.10.1
   ```

3. **Solution depends on situation:**
   - Update parent package
   - Replace parent package with alternative
   - Use `overrides` (npm) or `resolutions` (yarn)

### Force newer version (npm overrides)

```json
{
  "overrides": {
    "lodash": "^4.17.21"
  }
}
```

### Force newer version (yarn resolutions)

```json
{
  "resolutions": {
    "lodash": "^4.17.21"
  }
}
```

---

## Similarly Named Packages

### 🚨 DANGER: Typosquatting

Attackers register packages with names similar to popular libraries.

### Example: `biome` vs `@biomejs/biome`

| Package | Status | Description |
|---------|--------|-------------|
| `biome` | ❌ WRONG | Old, deprecated package, has old dependencies |
| `@biomejs/biome` | ✅ CORRECT | Official Biome linter/formatter |

**How it happens:**
```bash
# Person types
npm install biome  # ❌ Wrong package!

# Should have typed
npm install @biomejs/biome  # ✅ Correct package
```

### Other known cases

| Wrong | Correct |
|-------|---------|
| `lodash.js` | `lodash` |
| `react-js` | `react` |
| `node-fetch` | `node-fetch` (but watch versions) |
| `colors` (>=1.4.1) | `colors` (<=1.4.0) or `picocolors` |

### How to verify a package

```bash
# Check metadata
npm view biome
npm view @biomejs/biome

# Compare:
# - Author/organization
# - Download count
# - Last update
# - Repository URL
```

---

## False Positives

### `unstableOwnership` for large projects

**Packages that often trigger false positives:**

| Package | Reason |
|---------|--------|
| `workbox-*` | Google internal processes, frequent ownership changes |
| `@biomejs/*` | Active development, reorganization |
| `@babel/*` | Large team, maintainer changes |
| `@types/*` | DefinitelyTyped has many contributors |

**Action:** You can ignore, but monitor changelogs.

### `obfuscatedFile` for legitimate packages

Some packages have minified code that looks like obfuscation:

- `safer-buffer` - legitimate, but has minified test
- `registry-auth-token` - legitimate

**Action:** Check on npm/GitHub, if it's a known package, you can ignore it.

### `gitHubDependency`

Package depends directly on GitHub repo instead of npm registry.

```json
{
  "dependencies": {
    "some-pkg": "github:user/repo#branch"
  }
}
```

**Risks:**
- Repo can be deleted
- Commit can be rewritten
- More difficult to audit

**Action:** Prefer npm registry, or pin to specific commit SHA.

---

## Deprecated Packages

### How to find deprecated packages

```bash
npm outdated
npm audit
```

### Common deprecated packages and their replacements

| Deprecated | Replacement |
|------------|-------------|
| `request` | `node-fetch`, `axios`, `got` |
| `node-uuid` | `uuid` |
| `istanbul` | `nyc` or `c8` |
| `tslint` | `eslint` + `@typescript-eslint` |
| `moment` | `date-fns`, `dayjs`, `luxon` |
| `faker` | `@faker-js/faker` |
| `colors` (compromised) | `picocolors`, `chalk` |

### Automatic detection

```bash
# npm
npx npm-check -u

# or
npx depcheck
```

---

## Practical Example: Fixing legenda-bar

### Problem

Socket.dev reports:
```
CRITICAL: lodash@3.10.1 - multiple CVEs
CRITICAL: form-data@2.3.3 - CVE
```

But these packages aren't in package.json!

### Diagnosis

```bash
cd legenda-bar

# Find dependencies
npm ls lodash
# Output:
# └─┬ biome@0.3.3
#   └── lodash@3.10.1

npm ls form-data
# Output:
# └─┬ biome@0.3.3
#   └─┬ some-dep
#     └── form-data@2.3.3
```

### Cause

`biome@0.3.3` is the **wrong package** - should be `@biomejs/biome`.

### Fix

```bash
# 1. Remove wrong package
npm uninstall biome

# 2. Install correct one
npm install -D @biomejs/biome

# 3. Clean up
rm -rf node_modules package-lock.json
npm install

# 4. Verify
npm ls lodash  # Should be empty
npm audit      # Should be clean
```

### Updated package.json

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

## Checklist for New Project

- [ ] Am I using correct package names (with @scope where needed)?
- [ ] Do I have current versions of all dependencies?
- [ ] Did I run `npm audit` before first deploy?
- [ ] Do I have any deprecated packages?
- [ ] Did I check transitive dependencies?
