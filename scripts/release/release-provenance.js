const crypto = require('crypto')
const fs = require('fs')
const { execFileSync } = require('child_process')

function defaultRun(command, args, options = {}) {
  return execFileSync(command, args, {
    cwd: options.cwd,
    encoding: 'utf8',
    env: options.env || process.env,
    stdio: ['ignore', 'pipe', 'pipe'],
  })
}

function normalizeSha(value, label) {
  const sha = String(value).trim().toLowerCase()
  if (!/^[0-9a-f]{40}$/.test(sha))
    throw new Error(`${label} is not a full Git commit SHA`)
  return sha
}

function fileIdentity(filePath) {
  const bytes = fs.readFileSync(filePath)
  return {
    digest: `sha256:${crypto.createHash('sha256').update(bytes).digest('hex')}`,
    size: bytes.length,
  }
}

function artifactNames(version) {
  if (typeof version !== 'string' || !/^[0-9A-Za-z.+-]+$/.test(version)) {
    throw new Error('release version is not safe for an artifact name')
  }
  return {
    archive: `reflaxe.elixir-${version}.zip`,
    checksum: `reflaxe.elixir-${version}.zip.sha256`,
  }
}

/** Bind checked-out HEAD plus local and origin tags to one tested commit. */
function verifyTagIdentity({ tag, sourceCommit, cwd, run = defaultRun }) {
  const expected = normalizeSha(sourceCommit, 'CI-tested source commit')
  const head = normalizeSha(
    run('git', ['rev-parse', 'HEAD^{commit}'], { cwd }),
    'checked-out HEAD'
  )
  if (head !== expected)
    throw new Error('checked-out HEAD does not identify the CI-tested commit')

  const local = normalizeSha(
    run('git', ['rev-parse', `refs/tags/${tag}^{commit}`], { cwd }),
    'local release tag'
  )
  if (local !== expected)
    throw new Error('local release tag does not identify the CI-tested commit')

  const remoteOutput = run(
    'git',
    [
      'ls-remote',
      '--tags',
      'origin',
      `refs/tags/${tag}`,
      `refs/tags/${tag}^{}`,
    ],
    { cwd }
  )
  const refs = new Map(
    String(remoteOutput)
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((line) => {
        const [sha, ref] = line.split(/\s+/, 2)
        return [ref, normalizeSha(sha, 'remote release tag')]
      })
  )
  const remote =
    refs.get(`refs/tags/${tag}^{}`) || refs.get(`refs/tags/${tag}`)
  if (!remote) throw new Error('remote release tag is missing')
  if (remote !== expected)
    throw new Error('remote release tag does not identify the CI-tested commit')
  return expected
}

function verifyAsset(asset, expected, label) {
  if (!asset || asset.state !== 'uploaded')
    throw new Error(`${label} is not in uploaded state`)
  if (asset.size !== expected.size)
    throw new Error(`${label} size does not match the approved file`)
  if (asset.digest !== expected.digest)
    throw new Error(`${label} digest does not match the approved file`)
}

function approvedAssetIdentity({ version, zipPath, checksumPath }) {
  const names = artifactNames(version)
  const archive = fileIdentity(zipPath)
  const checksum = fileIdentity(checksumPath)
  const checksumText = `${archive.digest.slice('sha256:'.length)}  ${names.archive}\n`
  if (fs.readFileSync(checksumPath, 'utf8') !== checksumText) {
    throw new Error('checksum sidecar does not identify the approved archive')
  }
  return {
    [names.archive]: archive,
    [names.checksum]: checksum,
  }
}

/** Verify release metadata and the exact complete custom-asset set. */
function verifyHostedReleaseData({ release, tag, expectedAssets }) {
  if (!release || release.tagName !== tag)
    throw new Error('published GitHub Release tag does not match')
  if (release.isDraft)
    throw new Error('published GitHub Release is still a draft')
  if (release.isPrerelease)
    throw new Error(
      'published GitHub Release unexpectedly uses prerelease status'
    )
  if (!release.isImmutable)
    throw new Error('published GitHub Release is not immutable')

  const assets = Array.isArray(release.assets) ? release.assets : []
  const expectedNames = Object.keys(expectedAssets).sort()
  const actualNames = assets.map(({ name }) => name).sort()
  if (JSON.stringify(actualNames) !== JSON.stringify(expectedNames)) {
    throw new Error('hosted custom asset set does not match the release contract')
  }
  const byName = new Map(assets.map((asset) => [asset.name, asset]))
  for (const name of expectedNames) {
    verifyAsset(byName.get(name), expectedAssets[name], `hosted ${name}`)
  }
  return release
}

function sleep(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds)
}

/** Compare GitHub's immutable release attestation metadata to the approved local bytes. */
function verifyHostedRelease({
  version,
  tag,
  zipPath,
  checksumPath,
  cwd,
  run = defaultRun,
  attempts = 1,
  retryDelayMs = 0,
  wait = sleep,
}) {
  const expectedAssets = approvedAssetIdentity({
    version,
    zipPath,
    checksumPath,
  })
  let lastError
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const release = JSON.parse(
        run(
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
      return verifyHostedReleaseData({ release, tag, expectedAssets })
    } catch (error) {
      lastError = error
      if (attempt < attempts && retryDelayMs > 0) wait(retryDelayMs)
    }
  }
  throw lastError
}

function verifyHostReleaseControls({ repository, cwd, run = defaultRun }) {
  if (
    typeof repository !== 'string' ||
    !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)
  ) {
    throw new Error('repository must use OWNER/NAME form')
  }
  const immutable = JSON.parse(
    run('gh', ['api', `repos/${repository}/immutable-releases`], { cwd })
  )
  if (!immutable.enabled)
    throw new Error('immutable GitHub Releases are not enabled')

  const repositoryState = JSON.parse(
    run('gh', ['api', `repos/${repository}`], { cwd })
  )

  const summaries = JSON.parse(
    run('gh', ['api', `repos/${repository}/rulesets`], { cwd })
  )
  const summary = summaries.find(
    (entry) =>
      entry &&
      entry.name === 'Immutable semantic version tags' &&
      entry.target === 'tag' &&
      entry.enforcement === 'active'
  )
  if (!summary)
    throw new Error('active semantic-version tag immutability ruleset is missing')
  const ruleset = JSON.parse(
    run('gh', ['api', `repos/${repository}/rulesets/${summary.id}`], { cwd })
  )
  const includes =
    ruleset.conditions &&
    ruleset.conditions.ref_name &&
    ruleset.conditions.ref_name.include
  const types = new Set((ruleset.rules || []).map(({ type }) => type))
  if (
    !Array.isArray(includes) ||
    !includes.includes('refs/tags/v*') ||
    !types.has('deletion') ||
    !types.has('non_fast_forward')
  ) {
    throw new Error(
      'semantic-version tag ruleset does not prevent update and deletion'
    )
  }
  if (
    repositoryState.owner &&
    repositoryState.owner.type === 'Organization' &&
    (!types.has('creation') ||
      !Array.isArray(ruleset.bypass_actors) ||
      ruleset.bypass_actors.length === 0)
  ) {
    throw new Error(
      'organization-owned repository must restrict version-tag creation to a dedicated bypass identity'
    )
  }

  const environment = JSON.parse(
    run(
      'gh',
      ['api', `repos/${repository}/environments/release-repair`],
      { cwd }
    )
  )
  const reviewerRule = (environment.protection_rules || []).find(
    ({ type }) => type === 'required_reviewers'
  )
  if (
    !reviewerRule ||
    !Array.isArray(reviewerRule.reviewers) ||
    reviewerRule.reviewers.length === 0
  ) {
    throw new Error('release-repair environment must require a reviewer')
  }
  return { environment, immutable, repository: repositoryState, ruleset }
}

module.exports = {
  approvedAssetIdentity,
  artifactNames,
  defaultRun,
  fileIdentity,
  normalizeSha,
  verifyAsset,
  verifyHostReleaseControls,
  verifyHostedRelease,
  verifyHostedReleaseData,
  verifyTagIdentity,
}
