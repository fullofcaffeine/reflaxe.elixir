#!/usr/bin/env node
/**
 * extract-changelog-section.js
 *
 * Extracts a single version section from CHANGELOG.md for use as a GitHub Release body.
 *
 * Usage:
 *   node scripts/release/extract-changelog-section.js v1.1.5
 *   node scripts/release/extract-changelog-section.js 1.1.5
 */

const fs = require('fs')

function ensureArg(value) {
  if (!value) {
    console.error('Usage: node scripts/release/extract-changelog-section.js <vX.Y.Z|X.Y.Z>')
    process.exit(2)
  }
  return value
}

function normalizeVersion(raw) {
  return raw.startsWith('v') ? raw.slice(1) : raw
}

function findSection(lines, version) {
  const headerPattern = new RegExp(`^(#{1,3})\\s+\\[?${escapeRegExp(version)}\\]?\\b`)

  const startIndex = lines.findIndex((line) => headerPattern.test(line))
  if (startIndex === -1) return null

  let endIndex = lines.length
  for (let index = startIndex + 1; index < lines.length; index += 1) {
    const line = lines[index]
    if (/^#{1,3}\s+\[?([0-9]+\.[0-9]+\.[0-9]+|Unreleased)\]?/.test(line)) {
      endIndex = index
      break
    }
  }

  return {
    startIndex,
    endIndex,
  }
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function formatForRelease(rawSection) {
  const lines = rawSection.split('\n')
  if (lines.length === 0) return rawSection

  // GitHub Release pages already show the tag name; use a top-level heading like EspressoBar.
  lines[0] = lines[0].replace(/^##\s+/, '# ')
  return lines.join('\n').trim() + '\n'
}

function main() {
  const version = normalizeVersion(ensureArg(process.argv[2]))
  const changelogPath = 'CHANGELOG.md'

  if (!fs.existsSync(changelogPath)) {
    console.error(`ERROR: ${changelogPath} not found`)
    process.exit(2)
  }

  const content = fs.readFileSync(changelogPath, 'utf8')
  const lines = content.split(/\r?\n/)
  const section = findSection(lines, version)

  if (!section) {
    console.error(`ERROR: Version section not found in CHANGELOG.md: ${version}`)
    process.exit(1)
  }

  const raw = lines.slice(section.startIndex, section.endIndex).join('\n').trim() + '\n'
  process.stdout.write(formatForRelease(raw))
}

main()

