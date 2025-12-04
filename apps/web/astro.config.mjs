import starlight from '@astrojs/starlight'
import { defineConfig } from 'astro/config'

export default defineConfig({
  site: 'https://miccy.github.io',
  base: '/dont-be-shy-hulud',
  integrations: [
    starlight({
      title: "Don't Be Shy, Hulud",
      description:
        'npm supply chain attack detection toolkit — Shai-Hulud 2.0 detection, defense & remediation',
      logo: {
        src: './src/assets/logo.png',
        replacesTitle: false,
      },
      social: {
        github: 'https://github.com/miccy/dont-be-shy-hulud',
      },
      editLink: {
        baseUrl: 'https://github.com/miccy/dont-be-shy-hulud/edit/main/apps/web/',
      },
      defaultLocale: 'root',
      locales: {
        root: {
          label: 'English',
          lang: 'en',
        },
        cs: {
          label: 'Čeština',
          lang: 'cs',
        },
      },
      sidebar: [
        {
          label: 'Getting Started',
          translations: { cs: 'Začínáme' },
          items: [
            {
              label: 'Introduction',
              slug: 'getting-started/introduction',
              translations: { cs: 'Úvod' },
            },
            {
              label: 'Quick Start',
              slug: 'getting-started/quickstart',
              translations: { cs: 'Rychlý start' },
            },
            {
              label: 'Installation',
              slug: 'getting-started/installation',
              translations: { cs: 'Instalace' },
            },
          ],
        },
        {
          label: 'Detection',
          translations: { cs: 'Detekce' },
          items: [
            { label: 'Overview', slug: 'detection/overview', translations: { cs: 'Přehled' } },
            {
              label: 'IOC Files',
              slug: 'detection/ioc-files',
              translations: { cs: 'IOC soubory' },
            },
            {
              label: 'Network IOCs',
              slug: 'detection/network',
              translations: { cs: 'Síťové IOC' },
            },
            {
              label: 'Behavioral Signs',
              slug: 'detection/behavioral',
              translations: { cs: 'Behaviorální znaky' },
            },
          ],
        },
        {
          label: 'Remediation',
          translations: { cs: 'Náprava' },
          items: [
            {
              label: 'Immediate Actions',
              slug: 'remediation/immediate',
              translations: { cs: 'Okamžité kroky' },
            },
            {
              label: 'Credential Rotation',
              slug: 'remediation/credentials',
              translations: { cs: 'Rotace credentials' },
            },
            {
              label: 'Full Cleanup',
              slug: 'remediation/cleanup',
              translations: { cs: 'Kompletní čištění' },
            },
          ],
        },
        {
          label: 'Hardening',
          translations: { cs: 'Zabezpečení' },
          items: [
            {
              label: 'npm Configuration',
              slug: 'hardening/npm',
              translations: { cs: 'Konfigurace npm' },
            },
            {
              label: 'GitHub Actions',
              slug: 'hardening/github-actions',
              translations: { cs: 'GitHub Actions' },
            },
            { label: 'CI/CD', slug: 'hardening/cicd', translations: { cs: 'CI/CD' } },
          ],
        },
        {
          label: 'Stack Guides',
          translations: { cs: 'Průvodci pro stacky' },
          items: [
            { label: 'Bun', slug: 'stacks/bun' },
            { label: 'Expo & React Native', slug: 'stacks/expo-react-native' },
            { label: 'TypeScript & Astro', slug: 'stacks/typescript-astro' },
            { label: 'Monorepo', slug: 'stacks/monorepo' },
            { label: 'Rust, Go & Tauri', slug: 'stacks/rust-go-tauri' },
          ],
        },
        {
          label: 'Reference',
          translations: { cs: 'Reference' },
          items: [
            { label: 'CLI Commands', slug: 'reference/cli', translations: { cs: 'CLI příkazy' } },
            {
              label: 'IOC Database',
              slug: 'reference/ioc-database',
              translations: { cs: 'IOC databáze' },
            },
            {
              label: 'Configuration',
              slug: 'reference/configuration',
              translations: { cs: 'Konfigurace' },
            },
          ],
        },
      ],
      customCss: ['./src/styles/custom.css'],
      head: [
        {
          tag: 'meta',
          attrs: {
            name: 'theme-color',
            content: '#f97316',
          },
        },
      ],
    }),
  ],
})
