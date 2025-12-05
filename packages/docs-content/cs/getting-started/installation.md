---
title: Instalace
description: Instalace detekčního toolkitu Shai-Hulud
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Instalace

Několik způsobů instalace a použití detekčního toolkitu.

## NPX (Bez Instalace)

Spusťte přímo bez instalace:

```bash
npx hulud scan .
npx hulud audit
npx hulud harden
```

## Globální Instalace

```bash
# npm
npm install -g dont-be-shy-hulud

# bun
bun add -g dont-be-shy-hulud

# Pak použijte
hulud scan .
```

## Projektová Závislost

```bash
# npm
npm install --save-dev dont-be-shy-hulud

# bun
bun add -d dont-be-shy-hulud
```

Pak přidejte do `package.json`:

```json
{
  "scripts": {
    "security:scan": "hulud scan .",
    "security:audit": "hulud audit",
    "security:harden": "hulud harden"
  }
}
```

## Docker

```bash
# Stáhnout image
docker pull ghcr.io/miccy/dont-be-shy-hulud:latest

# Spustit sken
docker run -v $(pwd):/app ghcr.io/miccy/dont-be-shy-hulud scan /app
```

## Ověření Instalace

```bash
# Zkontrolovat verzi
hulud --version

# Spustit rychlý test
hulud scan --dry-run
```

## Požadavky

- Node.js 18+ nebo Bun 1.0+
- macOS, Linux nebo Windows (WSL)

## Další Kroky

- [Rychlý Start](/cs/getting-started/quickstart) — První sken
- [Reference CLI](/cs/reference/cli) — Všechny příkazy
