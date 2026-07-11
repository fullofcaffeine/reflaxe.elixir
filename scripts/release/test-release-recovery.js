#!/usr/bin/env node

const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const {
  approvedAssetIdentity,
  artifactNames,
  verifyHostReleaseControls,
  verifyHostedRelease,
  verifyHostedReleaseData,
  verifyTagIdentity,
} = require('./release-provenance.js')
const {
  draftAssetPlan,
  releaseView,
  releaseVersionFromTag,
} = require('./repair-release.js')

const VERSION = '0.15.0'
const TAG = `v${VERSION}`
const SHA = '1234567890abcdef1234567890abcdef12345678'

function releaseFixture(expectedAssets, options = {}) {
  return {
    tagName: TAG,
    isDraft: options.isDraft ?? true,
    isImmutable: options.isImmutable ?? false,
    isPrerelease: options.isPrerelease ?? false,
    assets: (options.names || Object.keys(expectedAssets)).map((name) => ({
      name,
      state: 'uploaded',
      ...expectedAssets[name],
    })),
  }
}

function main() {
  const temp = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-elixir-release-recovery-')
  )
  try {
    const names = artifactNames(VERSION)
    const zipPath = path.join(temp, 'reflaxe.elixir.zip')
    const checksumPath = path.join(temp, 'reflaxe.elixir.zip.sha256')
    fs.writeFileSync(zipPath, 'approved zip bytes\n')
    const zipDigest = require('crypto')
      .createHash('sha256')
      .update(fs.readFileSync(zipPath))
      .digest('hex')
    fs.writeFileSync(checksumPath, `${zipDigest}  ${names.archive}\n`)
    const expectedAssets = approvedAssetIdentity({
      version: VERSION,
      zipPath,
      checksumPath,
    })

    assert.strictEqual(releaseVersionFromTag(TAG), VERSION)
    for (const invalid of [
      'main',
      SHA,
      `refs/tags/${TAG}`,
      'v01.2.3',
      'v1.2.3-rc.1',
    ]) {
      assert.throws(() => releaseVersionFromTag(invalid), /existing vMAJOR/)
    }

    const repairSource = fs.readFileSync(
      path.join(__dirname, 'repair-release.js'),
      'utf8'
    )
    assert.doesNotMatch(repairSource, /run\(['"]git['"], \[['"]tag['"]/)
    assert.doesNotMatch(repairSource, /run\(['"]git['"], \[['"]push['"]/)
    assert.doesNotMatch(repairSource, /require\(['"]semantic-release/)

    // Tag exists but no Release: an authoritative 404 is the only absence signal.
    assert.strictEqual(
      releaseView(TAG, temp, () => {
        throw new Error('release not found')
      }),
      null
    )
    assert.throws(
      () =>
        releaseView(TAG, temp, () => {
          throw new Error('authentication failed')
        }),
      /authentication failed/
    )

    // Lost create response leaves an empty draft; repair uploads both files.
    assert.deepStrictEqual(
      draftAssetPlan({
        release: releaseFixture(expectedAssets, { names: [] }),
        tag: TAG,
        expectedAssets,
      }),
      [names.archive, names.checksum]
    )

    // Lost/partial upload response preserves verified bytes and uploads only the missing sidecar.
    assert.deepStrictEqual(
      draftAssetPlan({
        release: releaseFixture(expectedAssets, { names: [names.archive] }),
        tag: TAG,
        expectedAssets,
      }),
      [names.checksum]
    )
    assert.deepStrictEqual(
      draftAssetPlan({
        release: releaseFixture(expectedAssets),
        tag: TAG,
        expectedAssets,
      }),
      []
    )

    const wrongBytes = releaseFixture(expectedAssets, {
      names: [names.archive],
    })
    wrongBytes.assets[0].digest = `sha256:${'0'.repeat(64)}`
    assert.throws(
      () =>
        draftAssetPlan({ release: wrongBytes, tag: TAG, expectedAssets }),
      /digest does not match/
    )

    const unexpected = releaseFixture(expectedAssets)
    unexpected.assets.push({
      name: 'unapproved.bin',
      state: 'uploaded',
      size: 1,
      digest: `sha256:${'1'.repeat(64)}`,
    })
    assert.throws(
      () =>
        draftAssetPlan({ release: unexpected, tag: TAG, expectedAssets }),
      /unexpected custom assets/
    )

    const immutable = releaseFixture(expectedAssets, {
      isDraft: false,
      isImmutable: true,
    })
    verifyHostedReleaseData({ release: immutable, tag: TAG, expectedAssets })

    // Lost publish response and final-verifier retry converge on the immutable API state.
    let queries = 0
    const verified = verifyHostedRelease({
      version: VERSION,
      tag: TAG,
      zipPath,
      checksumPath,
      cwd: temp,
      attempts: 2,
      retryDelayMs: 1,
      wait() {},
      run() {
        queries += 1
        return JSON.stringify(
          queries === 1
            ? { ...immutable, isImmutable: false }
            : immutable
        )
      },
    })
    assert.strictEqual(verified.isImmutable, true)
    assert.strictEqual(queries, 2)

    assert.throws(
      () =>
        verifyHostedRelease({
          version: VERSION,
          tag: TAG,
          zipPath,
          checksumPath,
          cwd: temp,
          attempts: 2,
          retryDelayMs: 1,
          wait() {},
          run() {
            return JSON.stringify({ ...immutable, isImmutable: false })
          },
        }),
      /not immutable/
    )

    const tagRun = (_command, args) => {
      if (args[0] === 'rev-parse' && args[1] === 'HEAD^{commit}') return SHA
      if (args[0] === 'rev-parse') return SHA
      if (args[0] === 'ls-remote') return `${SHA}\trefs/tags/${TAG}\n`
      throw new Error(`unexpected command: ${args.join(' ')}`)
    }
    assert.strictEqual(
      verifyTagIdentity({ tag: TAG, sourceCommit: SHA, cwd: temp, run: tagRun }),
      SHA
    )
    assert.throws(
      () =>
        verifyTagIdentity({
          tag: TAG,
          sourceCommit: SHA,
          cwd: temp,
          run(_command, args) {
            if (args[0] === 'ls-remote')
              return `${'f'.repeat(40)}\trefs/tags/${TAG}\n`
            return SHA
          },
        }),
      /remote release tag does not identify/
    )

    const controls = verifyHostReleaseControls({
      repository: 'fullofcaffeine/reflaxe.elixir',
      cwd: temp,
      run(_command, args) {
        const endpoint = args[1]
        if (endpoint.endsWith('/immutable-releases'))
          return JSON.stringify({ enabled: true })
        if (endpoint.endsWith('/environments/release-repair'))
          return JSON.stringify({
            name: 'release-repair',
            protection_rules: [
              { type: 'required_reviewers', reviewers: [{ type: 'User' }] },
            ],
          })
        if (endpoint.endsWith('/rulesets'))
          return JSON.stringify([
            {
              id: 7,
              name: 'Immutable semantic version tags',
              target: 'tag',
              enforcement: 'active',
            },
          ])
        if (endpoint.includes('/rulesets/'))
          return JSON.stringify({
            id: 7,
            conditions: { ref_name: { include: ['refs/tags/v*'] } },
            rules: [{ type: 'deletion' }, { type: 'non_fast_forward' }],
          })
        return JSON.stringify({ owner: { type: 'User' } })
      },
    })
    assert.strictEqual(controls.ruleset.id, 7)

    console.log(
      '[release-recovery] OK: tag-only repair and failure-injection contracts'
    )
  } finally {
    fs.rmSync(temp, { recursive: true, force: true })
  }
}

main()
