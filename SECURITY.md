# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

### Private Security Advisory (Preferred)

1. Go to the [Security Advisories page](https://github.com/miccy/dont-be-shy-hulud/security/advisories)
2. Click "New draft security advisory"
3. Fill in the details

### Email

Send an email to: **support@miccy.dev** or create a private advisory as above.

### What to Include

Please include as much of the following information as possible:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (Critical: 24-48h, High: 1 week, Medium: 2 weeks)

## What to Expect

1. **Acknowledgment**: We'll confirm receipt of your vulnerability report
2. **Investigation**: We'll investigate and validate the issue
3. **Fix Development**: We'll develop a fix
4. **Coordinated Disclosure**: We'll coordinate the public disclosure with you
5. **Credit**: We'll credit you in the security advisory (unless you prefer anonymity)

## Security Measures in This Repository

This repository implements several security measures:

### Code Security

- **Dependency Scanning**: Automated with Dependabot
- **Secret Scanning**: Enabled
- **Code Scanning**: CodeQL analysis
- **Socket.dev Integration**: Supply-chain security monitoring

### Development Practices

- **Signed Commits**: Required for maintainers
- **Branch Protection**: Enforced on main branch
- **Required Reviews**: All PRs require review
- **CI/CD Security**: Minimal permissions, no secrets in logs

### Supply Chain Security

- **Lockfile Verification**: All dependencies pinned
- **Script Auditing**: Install scripts disabled by default
- **IOC Monitoring**: Regular updates from security vendors
- **Vendor Verification**: All IOCs cross-referenced

## Scope

### In Scope

- Detection scripts (false positives, false negatives)
- IOC database accuracy
- Documentation security guidance
- Configuration templates
- Repository infrastructure

### Out of Scope

- Vulnerabilities in third-party tools (Socket.dev, npm, etc.)
- Issues in packages listed in IOC database (report to npm/vendors)
- Social engineering attacks
- Physical security

## Security Best Practices for Users

When using this repository:

1. **Verify IOCs**: Cross-reference with official vendor sources
2. **Review Scripts**: Inspect scripts before running with elevated privileges
3. **Update Regularly**: Pull latest IOC updates frequently
4. **Report Findings**: Help us improve by reporting false positives/negatives
5. **Secure Your Credentials**: Follow the remediation guide for credential rotation

## Bug Bounty Program

We currently **do not** have a bug bounty program. However, we deeply appreciate security researchers who follow responsible disclosure practices and will acknowledge contributions prominently.

## Contact

- **Security Issues**: Use GitHub Security Advisory or email
- **General Questions**: Open a GitHub Discussion
- **X/Twitter**: [@miccycz](https://x.com/miccycz)
- **Bluesky**: [@miccy-dev](https://bsky.app/profile/miccy-dev.bsky.social)
- **Mastodon**: [@miccy](https://mastodon.social/@miccy)
- **Email**: [support@miccy.dev](mailto:support@miccy.dev)


## PGP Key

If you'd like to encrypt your security report:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[Add your PGP key if you have one]
-----END PGP PUBLIC KEY BLOCK-----
```

---

## Legal

We will not pursue legal action against researchers who:

- Make a good faith effort to avoid privacy violations, data destruction, and service interruption
- Only interact with accounts you own or with explicit permission
- Do not exploit a vulnerability beyond what is necessary to confirm its existence
- Report the vulnerability promptly
- Keep the vulnerability confidential until we've had a reasonable time to fix it

Thank you for helping keep Don't Be Shy, Hulud and our users safe! 🛡️
