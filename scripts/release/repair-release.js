#!/usr/bin/env node

const fs = require('fs')
const os = require('os')
const path = require('path')
const { execFileSync } = require('child_process')
const { loadReleasePolicy, verifyReleaseVersion } = require('./release-policy.js')
const { verifyReleaseArtifact } = require('./verify-release-artifact.js')
const {
  approvedAssetIdentity,
  artifactNames,
  normalizeSha,
  verifyAsset,
  verifyHostedRelease,
  verifyTagIdentity,
} = require('./release-provenance.js')

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    cwd: options.cwd,
    encoding: 'utf8',
    env: options.env || process.env,
    stdio: options.stdio || ['ignore', 'pipe', 'pipe'],
  })
}

function releaseView(tag, cwd, execute = run) {
  try {
    return JSON.parse(
      execute(
        'gh',
        [
          'release',
          'view',
          tag,
          '--json',
          'tagName,isDraft,isImmutable,isPrerelease,assets',
        ],
        { cwd }
      )
    )
  } catch (error) {
    const message = `${error.message || ''}\n${error.stderr || ''}`
    if (/release not found|HTTP 404/i.test(message)) return null
    throw error
  }
}

function buildApprovedArtifact({ cwd, version, tag, sourceCommit }) {
  const dist = path.join(cwd, 'dist')
  const zipPath = path.join(dist, 'reflaxe.elixir.zip')
  const checksumPath = path.join(dist, 'reflaxe.elixir.zip.sha256')
  const repeatRoot = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-elixir-repair-repeat-')
  )
  const repeatZip = path.join(repeatRoot, 'reflaxe.elixir.zip')
  try {
    fs.mkdirSync(dist, { recursive: true })
    run(
      'bash',
      [
        'scripts/release/package-haxelib.sh',
        zipPath,
        version,
        tag,
        sourceCommit,
      ],
      { cwd, stdio: 'inherit' }
    )
    run(
      'bash',
      [
        'scripts/release/package-haxelib.sh',
        repeatZip,
        version,
        tag,
        sourceCommit,
      ],
      {
        cwd,
        env: { ...process.env, TZ: 'UTC', TMPDIR: repeatRoot },
        stdio: 'inherit',
      }
    )
    if (!fs.readFileSync(zipPath).equals(fs.readFileSync(repeatZip))) {
      throw new Error(
        'repaired Haxelib package is not byte-for-byte reproducible'
      )
    }
    const verified = verifyReleaseArtifact({
      zipPath,
      version,
      tag,
      sourceCommit,
    })
    const names = artifactNames(version)
    fs.writeFileSync(
      checksumPath,
      `${verified.sha256}  ${names.archive}\n`
    )
    run('bash', ['scripts/ci/haxelib-package-smoke.sh'], {
      cwd,
      env: {
        ...process.env,
        PACKAGE_SMOKE_USE_EXISTING: '1',
        PACKAGE_ZIP_REL: path.relative(cwd, zipPath),
      },
      stdio: 'inherit',
    })
    return { checksumPath, names, verified, zipPath }
  } finally {
    fs.rmSync(repeatRoot, { recursive: true, force: true })
  }
}

/** Validate a mutable draft without deleting or replacing any hosted bytes. */
function draftAssetPlan({ release, tag, expectedAssets }) {
  if (!release || release.tagName !== tag)
    throw new Error('draft GitHub Release tag does not match')
  if (!release.isDraft) throw new Error('GitHub Release is not a draft')
  if (release.isImmutable)
    throw new Error('draft GitHub Release unexpectedly reports immutable')
  if (release.isPrerelease)
    throw new Error('draft GitHub Release unexpectedly uses prerelease status')

  const expectedNames = Object.keys(expectedAssets).sort()
  const assets = Array.isArray(release.assets) ? release.assets : []
  const actualNames = assets.map(({ name }) => name)
  if (new Set(actualNames).size !== actualNames.length)
    throw new Error('draft GitHub Release contains duplicate asset names')
  const unexpected = actualNames.filter(
    (name) => !Object.prototype.hasOwnProperty.call(expectedAssets, name)
  )
  if (unexpected.length > 0) {
    throw new Error(
      `draft GitHub Release contains unexpected custom assets: ${unexpected.join(', ')}`
    )
  }
  const byName = new Map(assets.map((asset) => [asset.name, asset]))
  for (const name of actualNames) {
    verifyAsset(byName.get(name), expectedAssets[name], `draft ${name}`)
  }
  return expectedNames.filter((name) => !byName.has(name))
}

function copyVersionedAssets({ cwd, artifact }) {
  const paths = {
    [artifact.names.archive]: path.join(cwd, 'dist', artifact.names.archive),
    [artifact.names.checksum]: path.join(
      cwd,
      'dist',
      artifact.names.checksum
    ),
  }
  fs.copyFileSync(artifact.zipPath, paths[artifact.names.archive])
  fs.copyFileSync(artifact.checksumPath, paths[artifact.names.checksum])
  return paths
}

function ensureDraft(tag, cwd) {
  let release = releaseView(tag, cwd)
  if (release) return release
  try {
    run(
      'gh',
      [
        'release',
        'create',
        tag,
        '--verify-tag',
        '--draft',
        '--generate-notes',
        '--title',
        tag,
      ],
      { cwd, stdio: 'inherit' }
    )
  } catch (error) {
    release = releaseView(tag, cwd)
    if (!release) throw error
    return release
  }
  release = releaseView(tag, cwd)
  if (!release)
    throw new Error('GitHub did not return the newly created draft Release')
  return release
}

function uploadMissingAssets({ tag, cwd, paths, missing, expectedAssets }) {
  for (const name of missing) {
    try {
      run('gh', ['release', 'upload', tag, paths[name]], {
        cwd,
        stdio: 'inherit',
      })
    } catch (error) {
      const release = releaseView(tag, cwd)
      const stillMissing = draftAssetPlan({ release, tag, expectedAssets })
      if (stillMissing.includes(name)) throw error
    }
  }
}

function releaseVersionFromTag(tag) {
  if (
    typeof tag !== 'string' ||
    !/^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.test(tag)
  ) {
    throw new Error('repair requires an existing vMAJOR.MINOR.PATCH tag')
  }
  return tag.slice(1)
}

/**
 * Complete publication for one immutable existing tag. This command never analyzes commits,
 * creates/moves/deletes a tag, or replaces mismatched hosted bytes.
 */
function main() {
  const [tag, ...rest] = process.argv.slice(2)
  if (!tag || rest.length > 0) {
    throw new Error(
      'usage: repair-release.js <existing vMAJOR.MINOR.PATCH tag>'
    )
  }
  const cwd = path.resolve(__dirname, '..', '..')
  const version = releaseVersionFromTag(tag)
  verifyReleaseVersion(
    loadReleasePolicy(path.join(cwd, 'release', 'manifest.json')),
    version
  )
  const sourceCommit = normalizeSha(
    run('git', ['rev-parse', 'HEAD^{commit}'], { cwd }),
    'checked-out HEAD'
  )
  verifyTagIdentity({ tag, sourceCommit, cwd })

  const tracked = run(
    'git',
    ['status', '--porcelain', '--untracked-files=no'],
    { cwd }
  )
  if (tracked.trim().length > 0)
    throw new Error('repair checkout contains tracked changes')

  const artifact = buildApprovedArtifact({
    cwd,
    version,
    tag,
    sourceCommit,
  })
  const expectedAssets = approvedAssetIdentity({
    version,
    zipPath: artifact.zipPath,
    checksumPath: artifact.checksumPath,
  })
  const existing = releaseView(tag, cwd)
  if (existing && !existing.isDraft) {
    verifyHostedRelease({
      version,
      tag,
      zipPath: artifact.zipPath,
      checksumPath: artifact.checksumPath,
      cwd,
      attempts: 6,
      retryDelayMs: 5000,
    })
    console.log(`[release-repair] ${tag} is already complete and immutable`)
    return
  }

  let draft = ensureDraft(tag, cwd)
  let missing = draftAssetPlan({ release: draft, tag, expectedAssets })
  if (missing.length > 0) {
    const paths = copyVersionedAssets({ cwd, artifact })
    uploadMissingAssets({ tag, cwd, paths, missing, expectedAssets })
    draft = releaseView(tag, cwd)
    missing = draftAssetPlan({ release: draft, tag, expectedAssets })
    if (missing.length > 0)
      throw new Error(`draft Release is still missing: ${missing.join(', ')}`)
  }

  try {
    run('gh', ['release', 'edit', tag, '--draft=false'], {
      cwd,
      stdio: 'inherit',
    })
  } catch (_error) {
    // A lost API response is resolved by the authoritative final query below.
  }
  verifyHostedRelease({
    version,
    tag,
    zipPath: artifact.zipPath,
    checksumPath: artifact.checksumPath,
    cwd,
    attempts: 6,
    retryDelayMs: 5000,
  })
  console.log(`[release-repair] completed immutable ${tag}`)
}

if (require.main === module) {
  try {
    main()
  } catch (error) {
    console.error(`[release-repair] ERROR: ${error.message}`)
    process.exit(1)
  }
}

module.exports = {
  draftAssetPlan,
  releaseView,
  releaseVersionFromTag,
}
