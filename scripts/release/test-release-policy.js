#!/usr/bin/env node

const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')

const root = path.resolve(__dirname, '../..')
const policyModulePath = path.join(
  root,
  'scripts',
  'release',
  'release-policy.js'
)
const pluginModulePath = path.join(
  root,
  'scripts',
  'release',
  'semantic-release-policy.cjs'
)

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`)
}

function approval(record) {
  return { record, date: '2026-07-10' }
}

function policy(options = {}) {
  const lines = {
    0: { stage: 'initial-development', breakingBump: 'minor' },
    1: {
      stage: 'stable',
      approval: options.major1Approved
        ? approval('haxe.elixir.codex-major-1')
        : null,
    },
  }
  if (options.includeMajor2) {
    lines[2] = {
      stage: 'stable',
      approval: options.major2Approved
        ? approval('haxe.elixir.codex-major-2')
        : null,
    }
  }
  return { schemaVersion: 2, releaseLines: lines }
}

function logger() {
  return { log() {}, error() {}, success() {} }
}

async function analyze(plugin, fixtureRoot, lastVersion, messages) {
  return plugin.analyzeCommits(
    {
      policyPath: path.join(fixtureRoot, 'release', 'manifest.json'),
      commitAnalyzer: {
        releaseRules: [
          { type: 'perf', release: 'patch' },
          { type: 'revert', release: 'patch' },
        ],
      },
    },
    {
      cwd: fixtureRoot,
      commits: messages.map((message, index) => ({
        message,
        hash: String(index + 1).padStart(40, '0'),
      })),
      lastRelease: { version: lastVersion },
      logger: logger(),
    }
  )
}

async function verify(plugin, fixtureRoot, version) {
  return plugin.verifyRelease(
    { policyPath: path.join(fixtureRoot, 'release', 'manifest.json') },
    { cwd: fixtureRoot, nextRelease: { version }, logger: logger() }
  )
}

async function main() {
  assert(fs.existsSync(policyModulePath), 'release policy module must exist')
  assert(
    fs.existsSync(pluginModulePath),
    'semantic-release policy plugin must exist'
  )

  const policyApi = require(policyModulePath)
  const plugin = require(pluginModulePath)
  const fixtureRoot = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-elixir-release-policy-')
  )
  const manifestPath = path.join(fixtureRoot, 'release', 'manifest.json')
  fs.mkdirSync(path.dirname(manifestPath), { recursive: true })

  try {
    writeJson(manifestPath, policy())

    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.14.23', ['fix: repair output']),
      'patch'
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.14.23', ['feat: add facade']),
      'minor'
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.14.23', [
        'perf: reduce allocations',
      ]),
      'patch'
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.14.23', ['docs: clarify usage']),
      null
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.14.23', [
        'feat!: replace an unstable API',
      ]),
      'minor',
      'unapproved breaking changes on 0.x must remain on the initial-development line'
    )

    await verify(plugin, fixtureRoot, '0.15.0')
    await assert.rejects(
      verify(plugin, fixtureRoot, '1.0.0'),
      /stable major 1 requires an approved release record/
    )

    writeJson(manifestPath, policy({ major1Approved: true }))
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.15.0', [
        'chore(release): approve stable graduation',
      ]),
      null,
      'approval state alone must not manufacture a 1.0.0 release'
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '0.15.0', [
        'feat!: graduate the stable contract',
      ]),
      'major',
      'a new breaking graduation change may derive 1.0.0 after approval'
    )
    await verify(plugin, fixtureRoot, '1.0.0')

    writeJson(
      manifestPath,
      policy({
        major1Approved: true,
        includeMajor2: true,
        major2Approved: false,
      })
    )
    assert.strictEqual(
      await analyze(plugin, fixtureRoot, '1.4.2', [
        'feat!: replace the stable API',
      ]),
      'major'
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '2.0.0'),
      /stable major 2 requires an approved release record/
    )

    writeJson(
      manifestPath,
      policy({
        major1Approved: true,
        includeMajor2: true,
        major2Approved: true,
      })
    )
    await verify(plugin, fixtureRoot, '1.9.0')
    await verify(plugin, fixtureRoot, '2.0.0')

    await assert.rejects(
      verify(plugin, fixtureRoot, '3.0.0'),
      /no release policy for major 3/
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '1.0.0-rc.1'),
      /prerelease channels are not enabled/
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '1.0.0+build.7'),
      /build metadata is not enabled/
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '1.0.0-alpha..1'),
      /invalid semantic version/
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '1.0.0-01'),
      /invalid semantic version/
    )
    await assert.rejects(
      verify(plugin, fixtureRoot, '9007199254740993.0.0'),
      /invalid semantic version/
    )

    const malformed = policy()
    malformed.releaseLines['0'] = {
      stage: 'stable',
      approval: approval('wrong-stage'),
    }
    writeJson(manifestPath, malformed)
    assert.throws(
      () => policyApi.loadReleasePolicy('release/manifest.json', fixtureRoot),
      /major 0 must use stage initial-development/
    )

    const incomplete = policy({ major1Approved: true })
    incomplete.releaseLines['1'].approval.date = '2026-02-30'
    writeJson(manifestPath, incomplete)
    assert.throws(
      () => policyApi.loadReleasePolicy('release/manifest.json', fixtureRoot),
      /releaseLines\.1\.approval\.date must be a real YYYY-MM-DD date/
    )

    const futureDated = policy({ major1Approved: true })
    futureDated.releaseLines['1'].approval.date = '2999-01-01'
    writeJson(manifestPath, futureDated)
    assert.throws(
      () => policyApi.loadReleasePolicy('release/manifest.json', fixtureRoot),
      /releaseLines\.1\.approval\.date must not be future-dated/
    )

    const unsafeMajor = policy()
    unsafeMajor.releaseLines['9007199254740993'] = {
      stage: 'stable',
      approval: null,
    }
    writeJson(manifestPath, unsafeMajor)
    assert.throws(
      () => policyApi.loadReleasePolicy('release/manifest.json', fixtureRoot),
      /releaseLines contains unsafe major 9007199254740993/
    )

    const trackedPolicy = require(path.join(root, 'release', 'manifest.json'))
    assert.deepStrictEqual(Object.keys(trackedPolicy).sort(), [
      'releaseLines',
      'schemaVersion',
    ])
    assert(!JSON.stringify(trackedPolicy).includes('versionFiles'))
    assert(!JSON.stringify(trackedPolicy).includes('postureBlocks'))
    assert(!JSON.stringify(trackedPolicy).includes('0.14.23'))

    const configPath = path.join(root, 'release.config.js')
    const originalReadFileSync = fs.readFileSync
    fs.readFileSync = function blockedDevelopmentMetadata(filePath, ...args) {
      const relative = path
        .relative(root, String(filePath))
        .split(path.sep)
        .join('/')
      if (
        relative === 'package.json' ||
        relative === 'haxelib.json' ||
        relative === 'mix.exs' ||
        relative === 'haxe_libraries/reflaxe.elixir.hxml'
      ) {
        throw new Error(`development metadata is unavailable: ${relative}`)
      }
      return originalReadFileSync.call(fs, filePath, ...args)
    }
    let releaseConfig
    try {
      delete require.cache[require.resolve(configPath)]
      releaseConfig = require(configPath)
    } finally {
      fs.readFileSync = originalReadFileSync
      delete require.cache[require.resolve(configPath)]
    }

    const analyzerPlugin = releaseConfig.plugins[0]
    assert.strictEqual(
      analyzerPlugin[0],
      './scripts/release/semantic-release-policy.cjs'
    )
    assert.strictEqual(analyzerPlugin[1].policyPath, 'release/manifest.json')
    assert(!fs.readFileSync(configPath, 'utf8').includes('release-manifest'))

    const notesPlugin = releaseConfig.plugins.find(
      (entry) =>
        Array.isArray(entry) &&
        entry[0] === '@semantic-release/release-notes-generator'
    )
    assert(notesPlugin, 'release notes generator must be configured')
    const { generateNotes } = await import(
      '@semantic-release/release-notes-generator'
    )
    const notes = await generateNotes(notesPlugin[1], {
      cwd: root,
      commits: [
        {
          hash: '1234567890abcdef1234567890abcdef12345678',
          message: 'fix(release): restore complete release notes',
        },
        {
          hash: 'abcdef1234567890abcdef1234567890abcdef12',
          message: 'docs: keep non-release changes out of generated notes',
        },
      ],
      lastRelease: {
        version: '0.14.26',
        gitTag: 'v0.14.26',
        gitHead: '0000000000000000000000000000000000000000',
      },
      nextRelease: {
        version: '0.14.27',
        gitTag: 'v0.14.27',
        gitHead: '1234567890abcdef1234567890abcdef12345678',
      },
      options: {
        repositoryUrl:
          'https://github.com/fullofcaffeine/reflaxe.elixir.git',
        tagFormat: 'v${version}',
      },
      branch: { name: 'main' },
      logger: logger(),
    })
    assert.match(notes, /### Bug Fixes/)
    assert.match(notes, /\* \*\*release:\*\* restore complete release notes/)
    assert.match(notes, /\/commit\/1234567890abcdef1234567890abcdef12345678/)
    assert(
      !notes.includes('keep non-release changes out of generated notes'),
      'generated release notes must omit non-release commits'
    )

    console.log(
      '[release-policy] OK: tag-owned SemVer and per-major approval contracts'
    )
  } finally {
    fs.rmSync(fixtureRoot, { recursive: true, force: true })
  }
}

main().catch((error) => {
  console.error(error.stack || error.message)
  process.exit(1)
})
