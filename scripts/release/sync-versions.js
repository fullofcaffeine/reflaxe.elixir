#!/usr/bin/env node
/**
 * Transitional generator for tracked release mirrors. Release policy remains
 * version-independent; callers must supply a version explicitly or derive it
 * from a reachable tag. Artifact child haxe.elixir.codex-83h.2 removes these
 * tracked release writes in favor of staging-only metadata.
 */
const fs = require('fs')
const path = require('path')
const childProcess = require('child_process')
const semver = require('semver')
const {
  DEFAULT_POLICY_PATH,
  isStableMajorApproved,
  loadReleasePolicy,
  parseSemanticVersion,
  releaseLine,
  verifyReleaseVersion,
} = require('./release-policy')

const ROOT_DIR = path.resolve(__dirname, '../..')
const VERSION_FILE_KINDS = new Set([
  'package-json',
  'package-lock-json',
  'haxelib-json',
  'mix-version',
  'readme-version-badge',
  'hxml-library-version',
])
const POSTURE_BLOCK_KINDS = new Set(['readme-stability', 'versioning-summary'])
const LEGACY_GENERATION = {
  versionFiles: [
    { path: 'package.json', kind: 'package-json' },
    { path: 'package-lock.json', kind: 'package-lock-json' },
    { path: 'haxelib.json', kind: 'haxelib-json' },
    { path: 'mix.exs', kind: 'mix-version' },
    { path: 'README.md', kind: 'readme-version-badge' },
    {
      path: 'haxe_libraries/reflaxe.elixir.hxml',
      kind: 'hxml-library-version',
    },
    {
      path: 'test/support/test_reflaxe_elixir.hxml',
      kind: 'hxml-library-version',
    },
  ],
  postureBlocks: [
    { path: 'README.md', marker: 'release-posture', kind: 'readme-stability' },
    {
      path: 'docs/06-guides/VERSIONING_AND_STABILITY.md',
      marker: 'release-posture',
      kind: 'versioning-summary',
    },
  ],
  releaseCommitExtraAssets: ['CHANGELOG.md'],
}

function readUtf8(filePath) {
  return fs.readFileSync(filePath, 'utf8')
}

function formatJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`
}

function safeRelativePath(root, relativePath, label) {
  if (typeof relativePath !== 'string' || relativePath.trim() === '') {
    throw new Error(`${label} must be a non-empty repo-relative path`)
  }
  if (path.isAbsolute(relativePath)) {
    throw new Error(`${label} must not be absolute: ${relativePath}`)
  }
  if (relativePath.includes('\\')) {
    throw new Error(
      `${label} must use portable forward slashes: ${relativePath}`
    )
  }
  if (relativePath.split('/').includes('..')) {
    throw new Error(
      `${label} must not contain parent traversal: ${relativePath}`
    )
  }

  const normalized = path.normalize(relativePath)
  const absolute = path.resolve(root, normalized)
  const relative = path.relative(root, absolute)
  if (
    relative === '' ||
    relative.startsWith('..') ||
    path.isAbsolute(relative)
  ) {
    throw new Error(`${label} escapes the repository root: ${relativePath}`)
  }
  return { absolute, relative: normalized.split(path.sep).join('/') }
}

function validateGenerationConfig(root, policyPath) {
  const generation = LEGACY_GENERATION
  if (
    !Array.isArray(generation.versionFiles) ||
    generation.versionFiles.length === 0
  ) {
    throw new Error('Legacy release generation versionFiles must be non-empty')
  }
  if (
    !Array.isArray(generation.postureBlocks) ||
    generation.postureBlocks.length === 0
  ) {
    throw new Error('Legacy release generation postureBlocks must be non-empty')
  }
  if (!Array.isArray(generation.releaseCommitExtraAssets)) {
    throw new Error(
      'Legacy release generation releaseCommitExtraAssets must be an array'
    )
  }

  safeRelativePath(root, policyPath, 'policy path')
  const seenVersionKinds = new Set()
  for (const [index, spec] of generation.versionFiles.entries()) {
    if (!spec || !VERSION_FILE_KINDS.has(spec.kind)) {
      throw new Error(
        `Legacy release generation has unsupported versionFiles[${index}].kind`
      )
    }
    safeRelativePath(root, spec.path, `generation.versionFiles[${index}].path`)
    const key = `${spec.path}\0${spec.kind}`
    if (seenVersionKinds.has(key)) {
      throw new Error(
        `Legacy release generation duplicates ${spec.kind} for ${spec.path}`
      )
    }
    seenVersionKinds.add(key)
  }

  const seenMarkers = new Set()
  for (const [index, spec] of generation.postureBlocks.entries()) {
    if (!spec || !POSTURE_BLOCK_KINDS.has(spec.kind)) {
      throw new Error(
        `Legacy release generation has unsupported postureBlocks[${index}].kind`
      )
    }
    safeRelativePath(root, spec.path, `generation.postureBlocks[${index}].path`)
    if (typeof spec.marker !== 'string' || !/^[a-z0-9-]+$/.test(spec.marker)) {
      throw new Error(
        `Legacy release generation postureBlocks[${index}].marker is unsafe`
      )
    }
    const key = `${spec.path}\0${spec.marker}`
    if (seenMarkers.has(key)) {
      throw new Error(
        `Legacy release generation duplicates marker ${spec.marker} for ${spec.path}`
      )
    }
    seenMarkers.add(key)
  }

  for (const [index, asset] of generation.releaseCommitExtraAssets.entries()) {
    safeRelativePath(
      root,
      asset,
      `generation.releaseCommitExtraAssets[${index}]`
    )
  }
}

function replaceExactlyOnce(text, pattern, replacement, label) {
  const matches = text.match(pattern) || []
  if (matches.length !== 1) {
    throw new Error(
      `${label} must match exactly once (found ${matches.length})`
    )
  }
  return text.replace(pattern, replacement)
}

function updateVersionFile(text, kind, version, filePath) {
  if (kind === 'package-json') {
    const json = JSON.parse(text)
    json.version = version
    return formatJson(json)
  }
  if (kind === 'package-lock-json') {
    const json = JSON.parse(text)
    json.version = version
    if (!json.packages || !json.packages['']) {
      throw new Error(`${filePath} is missing packages[""]`)
    }
    json.packages[''].version = version
    return formatJson(json)
  }
  if (kind === 'haxelib-json') {
    const json = JSON.parse(text)
    json.version = version
    json.releasenote = `v${version}: See CHANGELOG.md`
    return formatJson(json)
  }
  if (kind === 'mix-version') {
    return replaceExactlyOnce(
      text,
      /version:\s*"[0-9]+\.[0-9]+\.[0-9]+(?:-[^"\s]+)?"/g,
      `version: "${version}"`,
      `${filePath} Mix version`
    )
  }
  if (kind === 'readme-version-badge') {
    return replaceExactlyOnce(
      text,
      /\[!\[Version\]\(https:\/\/img\.shields\.io\/badge\/version-[0-9A-Za-z.-]+-blue\)\]/g,
      `[![Version](https://img.shields.io/badge/version-${version}-blue)]`,
      `${filePath} version badge`
    )
  }
  if (kind === 'hxml-library-version') {
    return replaceExactlyOnce(
      text,
      /^-D\s+reflaxe\.elixir=[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?\s*$/gm,
      `-D reflaxe.elixir=${version}`,
      `${filePath} library version`
    )
  }
  throw new Error(`Unsupported version generator kind: ${kind}`)
}

function postureLabel(version) {
  return parseSemanticVersion(version).major === 0
    ? 'pre-1.0 (`v0.x`)'
    : 'stable (`v1.x` and later)'
}

function renderPostureBlock(kind, policy, version) {
  const parsed = parseSemanticVersion(version)

  if (kind === 'readme-stability') {
    if (parsed.major === 0) {
      return `> [!WARNING]\n> **Stability**: v${version} is on the pre-1.0 (\`v0.x\`) release line.\n> Breaking changes to documented stable surfaces use minor releases until an explicitly reviewed stable graduation.\n> Some features remain experimental/opt-in; see [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md) and [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).`
    }
    return `> [!NOTE]\n> **Stability**: v${version} is on the stable release line.\n> Breaking changes to documented stable surfaces require a major release.\n> See [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md) and [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).`
  }

  if (kind === 'versioning-summary') {
    const breakingRelease =
      parsed.major === 0 ? releaseLine(policy, 0).breakingBump : 'major'
    const targetMajor = parsed.major === 0 ? 1 : parsed.major
    const graduationStatus = isStableMajorApproved(policy, targetMajor)
      ? 'approved'
      : 'not approved'
    return `> Current version: **v${version}**<br>\n> Current release line: **${postureLabel(version)}**<br>\n> Breaking stable-surface changes produce a **${breakingRelease}** release on this line.<br>\n> Stable graduation: **${graduationStatus}**.`
  }

  throw new Error(`Unsupported posture block kind: ${kind}`)
}

function replaceGeneratedBlock(text, marker, body, filePath) {
  const begin = `<!-- BEGIN GENERATED: ${marker} -->`
  const end = `<!-- END GENERATED: ${marker} -->`
  const beginCount = text.split(begin).length - 1
  const endCount = text.split(end).length - 1
  if (beginCount !== 1 || endCount !== 1) {
    throw new Error(
      `${filePath} must contain exactly one ${begin} and one ${end} marker`
    )
  }
  const beginIndex = text.indexOf(begin)
  const endIndex = text.indexOf(end)
  if (endIndex < beginIndex) {
    throw new Error(`${filePath} generated marker ${marker} is out of order`)
  }
  return `${text.slice(0, beginIndex)}${begin}\n${body}\n${end}${text.slice(
    endIndex + end.length
  )}`
}

function generatedReleaseAssets(
  policyPath = DEFAULT_POLICY_PATH,
  root = ROOT_DIR
) {
  validateGenerationConfig(root, policyPath)
  const paths = [policyPath]
  for (const spec of LEGACY_GENERATION.versionFiles) paths.push(spec.path)
  for (const spec of LEGACY_GENERATION.postureBlocks) paths.push(spec.path)
  paths.push(...LEGACY_GENERATION.releaseCommitExtraAssets)
  return [...new Set(paths)]
}

function computeExpectedOutputs({ root, policyPath, version }) {
  const policy = loadReleasePolicy(policyPath, root)
  validateGenerationConfig(root, policyPath)
  verifyReleaseVersion(policy, version)
  const outputs = new Map()

  function currentText(relativePath) {
    if (outputs.has(relativePath)) return outputs.get(relativePath)
    const { absolute } = safeRelativePath(root, relativePath, relativePath)
    return readUtf8(absolute)
  }

  for (const spec of LEGACY_GENERATION.versionFiles) {
    outputs.set(
      spec.path,
      updateVersionFile(currentText(spec.path), spec.kind, version, spec.path)
    )
  }
  for (const spec of LEGACY_GENERATION.postureBlocks) {
    outputs.set(
      spec.path,
      replaceGeneratedBlock(
        currentText(spec.path),
        spec.marker,
        renderPostureBlock(spec.kind, policy, version),
        spec.path
      )
    )
  }

  return { policy, version, outputs }
}

function generateReleaseState({
  root = ROOT_DIR,
  policyPath = DEFAULT_POLICY_PATH,
  version,
  check = false,
}) {
  if (!version)
    throw new Error('An explicit or tag-derived version is required')
  const { policy, outputs } = computeExpectedOutputs({
    root,
    policyPath,
    version,
  })

  const drift = []
  for (const [relativePath, expected] of outputs) {
    const { absolute } = safeRelativePath(root, relativePath, relativePath)
    const actual = readUtf8(absolute)
    if (actual !== expected) drift.push(relativePath)
  }

  if (check) {
    if (drift.length > 0) {
      throw new Error(`Generated release state is stale: ${drift.join(', ')}`)
    }
    return { policy, version, changed: [] }
  }

  for (const relativePath of drift.sort()) {
    const { absolute } = safeRelativePath(root, relativePath, relativePath)
    fs.writeFileSync(absolute, outputs.get(relativePath))
  }
  return { policy, version, changed: drift.sort() }
}

function latestReachableVersion(root = ROOT_DIR) {
  const result = childProcess.spawnSync(
    'git',
    ['tag', '--merged', 'HEAD', '--list', 'v*'],
    {
      cwd: root,
      encoding: 'utf8',
    }
  )
  if (result.status !== 0) {
    throw new Error(
      `Unable to read reachable release tags: ${String(result.stderr || '').trim()}`
    )
  }
  const versions = result.stdout
    .split(/\r?\n/)
    .filter(Boolean)
    .map((tag) => (tag.startsWith('v') ? tag.slice(1) : tag))
    .filter((version) => {
      try {
        parseSemanticVersion(version)
        return true
      } catch (_error) {
        return false
      }
    })
  versions.sort(semver.rcompare)
  if (versions.length === 0)
    throw new Error('No supported semantic-version tag is reachable from HEAD')
  return versions[0]
}

function parseArgs(argv) {
  const args = [...argv]
  const check = args.includes('--check')
  const printAssets = args.includes('--print-assets')
  const positional = args.filter((arg) => !arg.startsWith('--'))
  if (
    args.some(
      (arg) =>
        arg.startsWith('--') && arg !== '--check' && arg !== '--print-assets'
    )
  ) {
    throw new Error(`Unknown option in: ${args.join(' ')}`)
  }
  if (check && printAssets)
    throw new Error('--check and --print-assets are mutually exclusive')
  if (positional.length > 1)
    throw new Error('Expected at most one version argument')
  return { check, printAssets, version: positional[0] }
}

function main() {
  const {
    check,
    printAssets,
    version: requestedVersion,
  } = parseArgs(process.argv.slice(2))

  if (printAssets) {
    if (requestedVersion)
      throw new Error('--print-assets does not accept a version')
    process.stdout.write(
      `${JSON.stringify(generatedReleaseAssets(), null, 2)}\n`
    )
    return
  }
  if (!check && !requestedVersion) {
    throw new Error(
      'Usage: node scripts/release/sync-versions.js <version> | --check | --print-assets'
    )
  }

  const version = requestedVersion || latestReachableVersion(ROOT_DIR)
  const result = generateReleaseState({ version, check })
  if (check) {
    console.log(
      `[release-generate] OK: tracked metadata matches reachable v${result.version}`
    )
  } else if (result.changed.length === 0) {
    console.log(`[release-generate] Already current: v${result.version}`)
  } else {
    console.log(`[release-generate] Updated to v${result.version}:`)
    for (const file of result.changed) console.log(`  ${file}`)
  }
}

if (require.main === module) {
  try {
    main()
  } catch (error) {
    console.error(`[release-generate] ERROR: ${error.message}`)
    process.exit(1)
  }
}

module.exports = {
  computeExpectedOutputs,
  generateReleaseState,
  generatedReleaseAssets,
  latestReachableVersion,
  parseArgs,
  renderPostureBlock,
  replaceGeneratedBlock,
  safeRelativePath,
  validateGenerationConfig,
}
