#!/usr/bin/env node
/**
 * sync-versions.js
 *
 * Updates version strings across the repo so all user-facing entrypoints stay in sync:
 * - package.json (+ package-lock.json)
 * - haxelib.json
 * - mix.exs
 * - README version badge
 *
 * Usage:
 *   node scripts/release/sync-versions.js 1.2.3
 */

const fs = require('fs')

function readUtf8(path) {
  return fs.readFileSync(path, 'utf8')
}

function writeUtf8(path, text) {
  fs.writeFileSync(path, text)
}

function updateJsonFile(path, update) {
  const original = readUtf8(path)
  const json = JSON.parse(original)
  update(json)
  const next = JSON.stringify(json, null, 2) + '\n'
  if (next !== original) writeUtf8(path, next)
}

function updateMixExsVersion(version) {
  const path = 'mix.exs'
  const original = readUtf8(path)
  const next = original.replace(
    /version:\\s*\"[0-9]+\\.[0-9]+\\.[0-9]+(-[^\"\\s]+)?\"/g,
    `version: \"${version}\"`
  )
  if (next === original) {
    throw new Error(`No version field found to update in ${path}`)
  }
  writeUtf8(path, next)
}

function updateReadmeBadge(version) {
  const path = 'README.md'
  const original = readUtf8(path)
  const next = original.replace(
    /\\[!\\[Version\\]\\(https:\\/\\/img\\.shields\\.io\\/badge\\/version-[^-\\)]+-blue\\)\\]/,
    `[![Version](https://img.shields.io/badge/version-${version}-blue)]`
  )
  if (next === original) {
    throw new Error(`No Version badge found to update in ${path}`)
  }
  writeUtf8(path, next)
}

function ensureSemver(version) {
  if (!/^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?$/.test(version)) {
    throw new Error(`Invalid semver: ${version}`)
  }
}

function main() {
  const version = process.argv[2]
  if (!version) {
    console.error('Usage: node scripts/release/sync-versions.js <version>')
    process.exit(2)
  }
  ensureSemver(version)

  updateJsonFile('package.json', (json) => {
    json.version = version
  })

  updateJsonFile('package-lock.json', (json) => {
    json.version = version
    if (json.packages && json.packages['']) {
      json.packages[''].version = version
    }
  })

  updateJsonFile('haxelib.json', (json) => {
    json.version = version
    json.releasenote = `v${version}: See CHANGELOG.md`
  })

  updateMixExsVersion(version)
  updateReadmeBadge(version)
}

main()

