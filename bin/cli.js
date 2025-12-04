#!/usr/bin/env node

/**
 * 🪱 hulud CLI
 * npm supply chain attack detection toolkit
 *
 * Usage:
 *   npx hulud [command] [options]
 *
 * Commands:
 *   scan [path]     Scan directory for Shai-Hulud 2.0 IOCs (default: current dir)
 *   check           Quick check of current project
 *   full [mode]     Comprehensive system scan (quick|full|projects)
 *   suspend         Safely suspend malicious processes (SIGSTOP)
 *   info            Show attack information and IOCs
 *
 * Options:
 *   --help, -h      Show this help
 *   --version, -v   Show version
 *   --verbose       Verbose output
 *   --json          Output as JSON (for CI/CD)
 *   --parallel N    Number of parallel jobs (default: 4)
 */

import { spawn } from 'child_process'
import { existsSync, readFileSync } from 'fs'
import { dirname, join, resolve } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const ROOT = join(__dirname, '..')

// Colors for terminal
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
}

const c = (color, text) => `${colors[color]}${text}${colors.reset}`

// ASCII Banner
const banner = `
${c('magenta', '    ╭─────────────────────────────────────────────────╮')}
${c('magenta', '    │')}  ${c('cyan', '🪱 hulud')}                                      ${c('magenta', '│')}
${c('magenta', '    │')}  ${c('yellow', 'npm supply chain attack detection toolkit')}     ${c('magenta', '│')}
${c('magenta', '    ╰─────────────────────────────────────────────────╯')}
`

// Help text
const helpText = `
${banner}
${c('bright', 'USAGE:')}
  npx hulud [command] [options]

${c('bright', 'COMMANDS:')}
  ${c('cyan', 'scan')} [path]     Scan directory for Shai-Hulud 2.0 IOCs
                   Default: current directory

  ${c('cyan', 'check')}           Quick check of current project
                   (alias for: scan .)

  ${c('cyan', 'full')} [mode]     Comprehensive system scan
                   Modes: quick (default), full, projects
                   Scans multiple critical locations in parallel

  ${c('cyan', 'suspend')}         Safely suspend malicious processes
                   Uses SIGSTOP to freeze without triggering wiper

  ${c('cyan', 'info')}            Show attack information and known IOCs

${c('bright', 'OPTIONS:')}
  ${c('yellow', '--help, -h')}      Show this help message
  ${c('yellow', '--version, -v')}   Show version number
  ${c('yellow', '--verbose')}       Enable verbose output
  ${c('yellow', '--json')}          Output results as JSON (for CI/CD)
  ${c('yellow', '--output')} FILE   Write results to file
  ${c('yellow', '--parallel')} N    Parallel jobs for full scan (default: 4)
  ${c('yellow', '--dry-run')}       Show what would be scanned (full command)

${c('bright', 'EXAMPLES:')}
  ${c('green', '# Scan current directory')}
  npx hulud

  ${c('green', '# Scan specific project')}
  npx hulud scan ~/my-project

  ${c('green', '# Quick check with verbose output')}
  npx hulud check --verbose

  ${c('green', '# CI/CD integration')}
  npx hulud scan . --json --output results.json

  ${c('green', '# Full system scan (quick mode)')}
  npx hulud full

  ${c('green', '# Full system scan (all projects)')}
  npx hulud full projects --parallel 8

${c('bright', 'CRITICAL WARNING:')}
  ${c('red', '⚠️  DO NOT kill suspicious processes with kill -9!')}
  ${c('red', '    Use "suspend" command or kill -STOP to freeze them.')}
  ${c('red', '    The malware has a wiper that triggers on termination.')}

${c('bright', 'MORE INFO:')}
  GitHub: ${c('blue', 'https://github.com/miccy/dont-be-shy-hulud')}
  Docs:   ${c('blue', 'https://github.com/miccy/dont-be-shy-hulud#readme')}
`

// Attack info
const infoText = `
${banner}
${c('bright', '📊 SHAI-HULUD 2.0 ATTACK SUMMARY')}
${c('bright', '═══════════════════════════════════════════════════════')}

${c('yellow', 'Timeline:')}
  • Nov 21, 2025 - Attack begins
  • Nov 24, 2025 - First detection (AsyncAPI packages)
  • Nov 25, 2025 - Peak: 1,000 new repos every 30 minutes
  • Nov 26, 2025 - GitHub reduces malicious repos to ~300
  • ${c('red', 'Dec 9, 2025')}  - ${c('red', 'npm legacy token revocation deadline')}

${c('yellow', 'Scale:')}
  • 800+ packages compromised
  • 20M+ weekly downloads affected
  • 1,200+ organizations impacted
  • 25,000+ GitHub repos created for exfiltration

${c('yellow', 'High-Risk Packages:')}
  • posthog-node, posthog-js, @posthog/agent
  • @postman/tunnel-agent
  • @asyncapi/specs, @asyncapi/openapi-schema-parser
  • zapier-platform-core, zapier-platform-cli
  • @ensdomains/ensjs
  • ngx-bootstrap
  • tinycolor2

${c('yellow', 'Malicious Files to Look For:')}
  • setup_bun.js (dropper)
  • bun_environment.js (payload, ~10MB)
  • actionsSecrets.json, cloud.json (exfiltration)
  • .github/workflows/formatter_*.yml (backdoor)

${c('yellow', 'Behavioral Indicators:')}
  • GitHub repos with description "Sha1-Hulud: The Second Coming"
  • Random 18-character repo names
  • Unexpected Bun processes running
  • .truffler-cache directory

${c('bright', '═══════════════════════════════════════════════════════')}
Run ${c('cyan', 'npx hulud scan')} to check your project.
`

// Get version from package.json
function getVersion() {
  try {
    const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf-8'))
    return pkg.version || '0.0.0'
  } catch {
    return '0.0.0'
  }
}

// Run a shell script
function runScript(scriptName, args = []) {
  const scriptPath = join(ROOT, 'scripts', scriptName)

  if (!existsSync(scriptPath)) {
    console.error(c('red', `Error: Script not found: ${scriptPath}`))
    process.exit(1)
  }

  const child = spawn('bash', [scriptPath, ...args], {
    stdio: 'inherit',
    cwd: process.cwd(),
  })

  child.on('error', (err) => {
    console.error(c('red', `Error running script: ${err.message}`))
    process.exit(1)
  })

  child.on('close', (code) => {
    process.exit(code || 0)
  })
}

// Parse arguments
function parseArgs(args) {
  const parsed = {
    command: 'scan',
    path: '.',
    mode: 'quick',
    verbose: false,
    json: false,
    output: null,
    parallel: 4,
    dryRun: false,
    help: false,
    version: false,
  }

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]

    if (arg === '--help' || arg === '-h') {
      parsed.help = true
    } else if (arg === '--version' || arg === '-v') {
      parsed.version = true
    } else if (arg === '--verbose') {
      parsed.verbose = true
    } else if (arg === '--json') {
      parsed.json = true
    } else if (arg === '--output' && args[i + 1]) {
      parsed.output = args[++i]
    } else if (arg === '--parallel' && args[i + 1]) {
      parsed.parallel = parseInt(args[++i], 10) || 4
    } else if (arg === '--dry-run') {
      parsed.dryRun = true
    } else if (!arg.startsWith('-')) {
      if (['scan', 'check', 'full', 'suspend', 'info'].includes(arg)) {
        parsed.command = arg
      } else if (['quick', 'full', 'projects'].includes(arg)) {
        parsed.mode = arg
      } else {
        parsed.path = arg
      }
    }
  }

  return parsed
}

// Main
function main() {
  const args = parseArgs(process.argv.slice(2))

  // Handle --help
  if (args.help) {
    console.log(helpText)
    process.exit(0)
  }

  // Handle --version
  if (args.version) {
    console.log(`hulud v${getVersion()}`)
    process.exit(0)
  }

  // Handle commands
  switch (args.command) {
    case 'scan':
    case 'check': {
      console.log(banner)
      const scriptArgs = [resolve(args.path)]
      if (args.verbose) scriptArgs.push('--verbose')
      if (args.output) scriptArgs.push('--output', args.output)
      runScript('detect.sh', scriptArgs)
      break
    }

    case 'suspend': {
      console.log(banner)
      console.log(c('yellow', '⚠️  Suspending malicious processes with SIGSTOP...\n'))
      const scriptArgs = []
      if (args.verbose) scriptArgs.push('--verbose')
      runScript('suspend-malware.sh', scriptArgs)
      break
    }

    case 'info': {
      console.log(infoText)
      process.exit(0)
      break // unreachable but satisfies linter
    }

    case 'full': {
      console.log(banner)
      console.log(c('cyan', `🔍 Comprehensive system scan (mode: ${args.mode})\n`))
      const scriptArgs = [`--${args.mode}`]
      if (args.parallel !== 4) scriptArgs.push('--parallel', String(args.parallel))
      if (args.dryRun) scriptArgs.push('--dry-run')
      runScript('comprehensive-scan.sh', scriptArgs)
      break
    }

    default: {
      console.log(banner)
      runScript('detect.sh', [resolve(args.path)])
      break
    }
  }
}

main()
