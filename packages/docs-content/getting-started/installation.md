---
title: Installation
description: Install the Shai-Hulud detection toolkit
sidebar:
  order: 3
lastUpdated: 2025-12-05
---

# Installation

Multiple ways to install and use the detection toolkit.

## NPX (No Installation)

Run directly without installing:

```bash
npx hulud scan .
npx hulud scan --all
npx hulud scan --system
```

## Global Installation

```bash
npm install -g dont-be-shy-hulud
# or
bun add -g dont-be-shy-hulud
```

Then use anywhere:

```bash
hulud scan .
hulud scan ~/projects
```

## Local Installation

Add to your project:

```bash
npm install --save-dev dont-be-shy-hulud
# or
bun add -d dont-be-shy-hulud
```

Add to `package.json` scripts:

```json
{
  "scripts": {
    "security:scan": "hulud scan .",
    "security:audit": "hulud audit"
  }
}
```

## Docker

Run in an isolated container:

```bash
docker run --rm -v $(pwd):/target ghcr.io/miccy/hulud-scanner
```

Or build locally:

```bash
git clone https://github.com/miccy/dont-be-shy-hulud.git
cd dont-be-shy-hulud
docker build -t hulud-scanner .
docker run --rm -v $(pwd):/target hulud-scanner
```

## Shell Scripts Only

If you only need the shell scripts:

```bash
# Download detect.sh
curl -O https://raw.githubusercontent.com/miccy/dont-be-shy-hulud/main/scripts/detect.sh
chmod +x detect.sh
./detect.sh
```

## Requirements

- **Node.js** 18+ (for CLI)
- **Bash** 4+ (for shell scripts)
- **jq** (optional, for JSON output)
- **gh** (optional, for GitHub scanning)
