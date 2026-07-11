const crypto = require('crypto')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { execFileSync } = require('child_process')
const { verifyReleaseArtifact } = require('./verify-release-artifact.js')
const { verifyTagIdentity } = require('./release-provenance.js')

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    cwd: options.cwd,
    encoding: 'utf8',
    env: options.env || process.env,
    stdio: options.stdio || 'inherit',
  })
}

function normalizeSha(value, label) {
  const sha = String(value).trim().toLowerCase()
  if (!/^[0-9a-f]{40}$/.test(sha))
    throw new Error(`${label} is not a full Git commit SHA`)
  return sha
}

function sourceCommit(cwd) {
  const head = normalizeSha(
    execFileSync('git', ['rev-parse', 'HEAD^{commit}'], {
      cwd,
      encoding: 'utf8',
    }),
    'checked-out HEAD'
  )
  const tested = process.env.RELEASE_SOURCE_SHA
    ? normalizeSha(process.env.RELEASE_SOURCE_SHA, 'RELEASE_SOURCE_SHA')
    : head
  if (head !== tested)
    throw new Error('release checkout does not match the CI-tested GITHUB_SHA')
  return tested
}

function assertTrackedTreeClean(cwd) {
  const status = execFileSync(
    'git',
    ['status', '--porcelain', '--untracked-files=no'],
    {
      cwd,
      encoding: 'utf8',
    }
  )
  if (status.trim())
    throw new Error('release preparation modified tracked repository files')
}

function assertMeaningfulReleaseNotes(notes) {
  const contentLines = String(notes || '')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !/^#{1,6}\s/.test(line))
  if (contentLines.length === 0)
    throw new Error(
      'generated release notes contain no entries; refusing to publish a heading-only release'
    )
}

function artifactNames(version) {
  return {
    archive: `reflaxe.elixir-${version}.zip`,
    checksum: `reflaxe.elixir-${version}.zip.sha256`,
  }
}

function hash(filePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(filePath))
    .digest('hex')
}

function verifyApprovedArtifact({
  zipPath,
  checksumPath,
  version,
  tag,
  source,
}) {
  const verified = verifyReleaseArtifact({
    zipPath,
    version,
    tag,
    sourceCommit: source,
  })
  const expected = `${verified.sha256}  ${artifactNames(version).archive}\n`
  if (
    hash(zipPath) !== verified.sha256 ||
    fs.readFileSync(checksumPath, 'utf8') !== expected
  ) {
    throw new Error('approved release artifact changed after preparation')
  }
  return verified
}

/** Build twice under varied environments, validate exact bytes, and smoke the approved first ZIP. */
async function prepare(_pluginConfig, context) {
  const cwd = context.cwd
  const version = context.nextRelease.version
  const tag = context.nextRelease.gitTag
  assertMeaningfulReleaseNotes(context.nextRelease.notes)
  const source = sourceCommit(cwd)
  const dist = path.join(cwd, 'dist')
  const zipPath = path.join(dist, 'reflaxe.elixir.zip')
  const checksumPath = path.join(dist, 'reflaxe.elixir.zip.sha256')
  const secondRoot = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-elixir-release-repeat-')
  )
  const secondZip = path.join(secondRoot, 'reflaxe.elixir.zip')
  try {
    assertTrackedTreeClean(cwd)
    fs.mkdirSync(dist, { recursive: true })
    fs.rmSync(zipPath, { force: true })
    fs.rmSync(checksumPath, { force: true })
    run(
      'bash',
      ['scripts/release/package-haxelib.sh', zipPath, version, tag, source],
      { cwd }
    )
    run(
      'bash',
      ['scripts/release/package-haxelib.sh', secondZip, version, tag, source],
      {
        cwd,
        env: {
          ...process.env,
          TZ: 'Pacific/Auckland',
          LC_ALL: 'C',
          TMPDIR: secondRoot,
        },
      }
    )
    if (!fs.readFileSync(zipPath).equals(fs.readFileSync(secondZip))) {
      throw new Error(
        'complete Haxelib package is not byte-for-byte reproducible'
      )
    }
    const verified = verifyReleaseArtifact({
      zipPath,
      version,
      tag,
      sourceCommit: source,
    })
    const names = artifactNames(version)
    fs.writeFileSync(checksumPath, `${verified.sha256}  ${names.archive}\n`)
    run('bash', ['scripts/ci/haxelib-package-smoke.sh'], {
      cwd,
      env: {
        ...process.env,
        PACKAGE_SMOKE_USE_EXISTING: '1',
        PACKAGE_ZIP_REL: path.relative(cwd, zipPath),
      },
    })
    assertTrackedTreeClean(cwd)
    context.logger.success(
      `Prepared reproducible ${names.archive} (${verified.size} bytes, sha256:${verified.sha256}) from ${source}`
    )
  } finally {
    fs.rmSync(secondRoot, { recursive: true, force: true })
  }
}

/** Ensure the approved local artifact did not change between prepare and semantic-release tagging. */
async function publish(_pluginConfig, context) {
  const cwd = context.cwd
  const version = context.nextRelease.version
  const tag = context.nextRelease.gitTag
  const source = sourceCommit(cwd)
  const zipPath = path.join(cwd, 'dist', 'reflaxe.elixir.zip')
  const checksumPath = path.join(cwd, 'dist', 'reflaxe.elixir.zip.sha256')
  verifyApprovedArtifact({
    zipPath,
    checksumPath,
    version,
    tag,
    source,
  })
  verifyTagIdentity({ tag, sourceCommit: source, cwd })
  assertTrackedTreeClean(cwd)
  context.logger.success(
    `Verified the approved ${tag} artifact and local/origin tag identity before GitHub publication`
  )
}

module.exports = {
  artifactNames,
  assertMeaningfulReleaseNotes,
  prepare,
  publish,
  sourceCommit,
  verifyApprovedArtifact,
}
