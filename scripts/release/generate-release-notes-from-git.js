#!/usr/bin/env node
/**
 * generate-release-notes-from-git.js
 *
 * Generates simple “semantic-release style” release notes for a given semver tag
 * by parsing commit subjects between the previous semver tag and the given tag.
 *
 * This is used by CI backfill workflows to populate GitHub Release bodies for
 * historical tags without relying on GitHub's auto-generated notes.
 *
 * Usage:
 *   node scripts/release/generate-release-notes-from-git.js v1.1.5
 *   node scripts/release/generate-release-notes-from-git.js 1.1.5
 */

const { execSync } = require('child_process')

function exec(cmd) {
  return execSync(cmd, { encoding: 'utf8' }).trim()
}

function ensureArg(value) {
  if (!value) {
    console.error('Usage: node scripts/release/generate-release-notes-from-git.js <vX.Y.Z|X.Y.Z>')
    process.exit(2)
  }
  return value
}

function normalizeTag(raw) {
  if (raw.startsWith('v')) return raw
  return `v${raw}`
}

function parseConventionalSubject(subject) {
  const match = subject.match(/^([a-zA-Z]+)(?:\(([^)]+)\))?(!)?:\s+(.+)$/)
  if (!match) return null

  const type = match[1].toLowerCase()
  const scope = match[2] || null
  const breaking = Boolean(match[3])
  const description = match[4]

  return { type, scope, breaking, description }
}

function formatCommitLine(subject, parsed, sha) {
  const shortSha = sha.slice(0, 7)
  const commitUrl = `https://github.com/fullofcaffeine/reflaxe.elixir/commit/${sha}`

  if (!parsed) {
    return `* ${escapeMarkdownText(subject)} ([${shortSha}](${commitUrl}))`
  }

  const scopePrefix = parsed.scope ? `**${parsed.scope}:** ` : ''
  return `* ${scopePrefix}${parsed.description} ([${shortSha}](${commitUrl}))`
}

function escapeMarkdownText(text) {
  return String(text).replace(/\\r?\\n/g, ' ')
}

function main() {
  const tag = normalizeTag(ensureArg(process.argv[2]))
  const version = tag.startsWith('v') ? tag.slice(1) : tag

  const tags = exec("git tag --list 'v*.*.*' --sort=version:refname")
    .split('\n')
    .map((t) => t.trim())
    .filter(Boolean)

  const tagIndex = tags.indexOf(tag)
  if (tagIndex === -1) {
    console.error(`ERROR: Tag not found: ${tag}`)
    process.exit(1)
  }

  const previousTag = tagIndex > 0 ? tags[tagIndex - 1] : null
  const releaseDate = exec(`git show -s --format=%cs ${tag}`)

  const compareUrl = previousTag
    ? `https://github.com/fullofcaffeine/reflaxe.elixir/compare/${previousTag}...${tag}`
    : null

  const header = compareUrl ? `# [${version}](${compareUrl}) (${releaseDate})` : `# ${version} (${releaseDate})`

  const range = previousTag ? `${previousTag}..${tag}` : tag
  const rawCommits = exec(`git log --no-merges --pretty=format:%H%x09%s ${range}`)
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)

  const sections = {
    features: [],
    fixes: [],
    other: [],
  }

  for (const row of rawCommits) {
    const [sha, ...subjectParts] = row.split('\t')
    const subject = subjectParts.join('\t').trim()

    if (!sha || !subject) continue
    if (/^chore\(release\):/i.test(subject)) continue

    const parsed = parseConventionalSubject(subject)
    const line = formatCommitLine(subject, parsed, sha)

    if (parsed?.type === 'feat') {
      sections.features.push(line)
    } else if (parsed?.type === 'fix') {
      sections.fixes.push(line)
    } else {
      sections.other.push(line)
    }
  }

  const out = [header, '']

  if (sections.features.length) {
    out.push('### Features', '', ...sections.features, '')
  }

  if (sections.fixes.length) {
    out.push('### Bug Fixes', '', ...sections.fixes, '')
  }

  if (!sections.features.length && !sections.fixes.length && sections.other.length) {
    out.push('### Changes', '', ...sections.other, '')
  }

  // Keep "Other" small to avoid noisy release pages, but don't emit empty notes.
  if ((sections.features.length || sections.fixes.length) && sections.other.length) {
    out.push('### Other', '', ...sections.other.slice(0, 12), '')
    if (sections.other.length > 12) {
      out.push(`_Plus ${sections.other.length - 12} more._`, '')
    }
  }

  process.stdout.write(out.join('\n').trim() + '\n')
}

main()
