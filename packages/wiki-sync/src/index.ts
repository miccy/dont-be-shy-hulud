/**
 * @hulud/wiki-sync
 * Synchronizes documentation from packages/docs-content to GitHub Wiki
 *
 * Wiki naming convention:
 * - en/getting-started/quick-start.md → Getting-Started-Quick-Start.md
 * - cs/getting-started/quick-start.md → Getting-Started-Quick-Start.cs.md
 * - en/index.mdx → Home.md
 * - cs/index.mdx → Home.cs.md
 */

import { existsSync } from 'node:fs'
import { readFile, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { glob } from 'glob'
import matter from 'gray-matter'

const CONTENT_DIR = join(import.meta.dirname, '../../docs-content')
const WIKI_DIR = join(import.meta.dirname, '../../../../dont-be-shy-hulud.wiki')

interface DocFile {
  path: string
  lang: 'en' | 'cs'
  slug: string
  title: string
  content: string
  order?: number
}

interface SidebarSection {
  title: string
  slug: string
  docs: DocFile[]
}

/**
 * Transform a slug to Wiki-compatible filename
 * getting-started/quick-start → Getting-Started-Quick-Start
 */
function toWikiName(slug: string): string {
  if (slug === 'index') return 'Home'

  return slug
    .split('/')
    .filter(Boolean)
    .map((part) =>
      part
        .split('-')
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join('-')
    )
    .join('-')
}

/**
 * Get the full Wiki filename with language suffix
 */
function getWikiFilename(slug: string, lang: 'en' | 'cs'): string {
  const wikiName = toWikiName(slug)
  return lang === 'en' ? `${wikiName}.md` : `${wikiName}.cs.md`
}

/**
 * Extract title from frontmatter or first heading
 */
function extractTitle(content: string, slug: string): string {
  // Try frontmatter first
  const { data } = matter(content)
  if (data.title) return data.title

  // Try first H1 heading
  const h1Match = content.match(/^#\s+(.+)$/m)
  if (h1Match) return h1Match[1]

  // Fallback to slug
  const lastPart = slug.split('/').pop() ?? slug
  return lastPart
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}

/**
 * Transform MDX content to plain Markdown for Wiki
 */
function transformContent(content: string): string {
  const { content: body } = matter(content)

  return (
    body
      // Remove MDX imports
      .replace(/^import\s+.+$/gm, '')
      // Remove JSX components (simple cases)
      .replace(/<Card[^>]*>([^<]*)<\/Card>/g, '$1')
      .replace(/<CardGrid[^>]*>([\s\S]*?)<\/CardGrid>/g, '$1')
      // Convert Astro components to markdown
      .replace(/<Tabs[^>]*>([\s\S]*?)<\/Tabs>/g, '$1')
      .replace(/<TabItem[^>]*label="([^"]*)"[^>]*>([\s\S]*?)<\/TabItem>/g, '### $1\n$2')
      // Clean up extra whitespace
      .replace(/\n{3,}/g, '\n\n')
      .trim()
  )
}

/**
 * Generate sidebar content for a language
 */
function generateSidebar(docs: DocFile[], lang: 'en' | 'cs'): string {
  const sections: Record<string, SidebarSection> = {
    'getting-started': {
      title: lang === 'en' ? 'Getting Started' : 'Začínáme',
      slug: 'getting-started',
      docs: [],
    },
    detection: {
      title: lang === 'en' ? 'Detection' : 'Detekce',
      slug: 'detection',
      docs: [],
    },
    remediation: {
      title: lang === 'en' ? 'Remediation' : 'Náprava',
      slug: 'remediation',
      docs: [],
    },
    hardening: {
      title: lang === 'en' ? 'Hardening' : 'Zabezpečení',
      slug: 'hardening',
      docs: [],
    },
    stacks: {
      title: lang === 'en' ? 'Stack Guides' : 'Průvodci pro stacky',
      slug: 'stacks',
      docs: [],
    },
    reference: {
      title: lang === 'en' ? 'Reference' : 'Reference',
      slug: 'reference',
      docs: [],
    },
  }

  // Categorize docs
  for (const doc of docs.filter((d) => d.lang === lang)) {
    const section = doc.slug.split('/')[0]
    if (sections[section]) {
      sections[section].docs.push(doc)
    }
  }

  // Build sidebar
  let sidebar = `### ${lang === 'en' ? '🪱 Shai-Hulud Toolkit' : '🪱 Shai-Hulud Toolkit'}\n\n`

  // Home link
  const homeDoc = docs.find((d) => d.lang === lang && d.slug === 'index')
  if (homeDoc) {
    sidebar += `**[[${lang === 'en' ? 'Home' : 'Domů'}|Home${lang === 'cs' ? '.cs' : ''}]]**\n\n`
  }

  // Sections
  for (const [, section] of Object.entries(sections)) {
    if (section.docs.length === 0) continue

    sidebar += `**${section.title}**\n`
    for (const doc of section.docs) {
      const wikiName = toWikiName(doc.slug)
      const linkName = lang === 'cs' ? `${wikiName}.cs` : wikiName
      sidebar += `- [[${doc.title}|${linkName}]]\n`
    }
    sidebar += '\n'
  }

  // Language switch
  sidebar += `---\n`
  if (lang === 'en') {
    sidebar += `🌍 [[Čeština|Home.cs]]\n`
  } else {
    sidebar += `🌍 [[English|Home]]\n`
  }

  return sidebar
}

/**
 * Generate footer content
 */
function generateFooter(): string {
  return `---
📖 [Documentation](https://hulud.dev) | 🐙 [GitHub](https://github.com/miccy/dont-be-shy-hulud) | 🪱 v1.5.1
`
}

/**
 * Main sync function
 */
async function syncToWiki() {
  console.log('🪱 Starting wiki sync...')
  console.log(`   Source: ${CONTENT_DIR}`)
  console.log(`   Target: ${WIKI_DIR}`)

  // Check if wiki directory exists
  if (!existsSync(WIKI_DIR)) {
    console.error(`❌ Wiki directory not found: ${WIKI_DIR}`)
    console.log('   Clone the wiki repo first:')
    console.log('   git clone https://github.com/miccy/dont-be-shy-hulud.wiki.git')
    process.exit(1)
  }

  // Find all markdown files
  const files = await glob('**/*.{md,mdx}', {
    cwd: CONTENT_DIR,
    ignore: ['**/node_modules/**', '**/meta/**'],
  })

  console.log(`📄 Found ${files.length} documentation files`)

  const docs: DocFile[] = []

  // Process each file
  for (const file of files) {
    const content = await readFile(join(CONTENT_DIR, file), 'utf-8')
    const lang = file.startsWith('cs/') ? 'cs' : 'en'
    const slug = file
      .replace(/^(en|cs)\//, '')
      .replace(/\.(md|mdx)$/, '')
      .replace(/\/index$/, '')

    // Handle root index
    const finalSlug = slug === '' ? 'index' : slug

    docs.push({
      path: file,
      lang,
      slug: finalSlug,
      title: extractTitle(content, finalSlug),
      content: transformContent(content),
    })
  }

  // Write docs to wiki
  let written = 0
  for (const doc of docs) {
    const filename = getWikiFilename(doc.slug, doc.lang)
    const filepath = join(WIKI_DIR, filename)

    await writeFile(filepath, doc.content, 'utf-8')
    written++
    console.log(`   ✓ ${filename}`)
  }

  // Generate sidebars
  const sidebarEn = generateSidebar(docs, 'en')
  const sidebarCs = generateSidebar(docs, 'cs')

  await writeFile(join(WIKI_DIR, '_Sidebar.md'), sidebarEn, 'utf-8')
  await writeFile(join(WIKI_DIR, '_Sidebar.cs.md'), sidebarCs, 'utf-8')
  console.log('   ✓ _Sidebar.md')
  console.log('   ✓ _Sidebar.cs.md')

  // Generate footer
  const footer = generateFooter()
  await writeFile(join(WIKI_DIR, '_Footer.md'), footer, 'utf-8')
  console.log('   ✓ _Footer.md')

  console.log(`\n✅ Synced ${written} docs + 3 wiki files`)
  console.log('\n📌 Next steps:')
  console.log('   cd dont-be-shy-hulud.wiki')
  console.log('   git add -A && git commit -m "docs: sync from main repo"')
  console.log('   git push')
}

// Run
syncToWiki().catch((err) => {
  console.error('❌ Sync failed:', err)
  process.exit(1)
})
