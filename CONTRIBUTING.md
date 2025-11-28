# Contributing to Hunting Worms Guide

First off, thank you for considering contributing! This guide helps developers protect themselves from supply chain attacks.

## How to Contribute

### Reporting New IOCs

If you discover new indicators of compromise:

1. **DO NOT** create a public issue with sensitive data
2. Open a PR adding the IOC to the appropriate list
3. Include:
   - Package name and version
   - File hashes (SHA-256)
   - Source/reference

### Adding Detection Improvements

1. Fork the repo
2. Create a branch: `git checkout -b feature/detection-improvement`
3. Test your changes
4. Submit a PR

### Documentation

- Fix typos and unclear explanations
- Add translations
- Improve examples
- Add new tool configurations

## Guidelines

### Code Style

- Bash scripts: Use `shellcheck`
- Markdown: Use consistent formatting
- JSON: Validate with `jq`

### Commit Messages

```
type(scope): description

Examples:
feat(detect): add yarn.lock scanning
fix(script): handle spaces in paths
docs(readme): update IOC list
```

### Pull Request Process

1. Update README.md if needed
2. Update CHANGELOG.md
3. Test on macOS and Linux
4. Request review

## Priority Areas

- [ ] More IOCs from vendor reports
- [ ] Yarn Berry (PnP) support
- [ ] pnpm lockfile parsing
- [ ] Windows support
- [ ] Docker container scanning
- [ ] CI/CD examples (GitLab CI, CircleCI, etc.)
- [ ] Translations (Czech, German, etc.)

## Questions?

Open a discussion or reach out on Twitter/X.

## License

By contributing, you agree that your contributions will be licensed under MIT.
