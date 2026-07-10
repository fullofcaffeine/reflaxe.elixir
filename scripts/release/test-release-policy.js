#!/usr/bin/env node
const assert = require('assert')
const fs = require('fs')
const path = require('path')
const { analyzeCommits } = require('@semantic-release/commit-analyzer')
const {
  assertGraduationApproved,
  assertVersionAllowed,
  loadReleaseManifest,
  releaseRulesForManifest,
} = require('./release-manifest')

const root = path.resolve(__dirname, '../..')
const manifest = loadReleaseManifest('release/manifest.json', root)
const packageJson = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'))

function approvedStableManifest() {
  const stable = JSON.parse(JSON.stringify(manifest))
  stable.releasePolicy.currentLine = 'stable'
  stable.releasePolicy.graduation = {
    approved: true,
    approvalBead: 'haxe.elixir.codex-stable.1',
    approvedAt: '2026-07-09',
    evidence: {
      platformToolchain: 'CI matrix evidence URL',
      compatibility: 'compatibility report URL',
      applicationRuntime: 'application QA report URL',
      independentReview: 'independent review URL',
    },
  }
  return stable
}

async function analyze(manifestFixture, message) {
  return analyzeCommits(
    {
      preset: 'conventionalcommits',
      releaseRules: releaseRulesForManifest(manifestFixture),
    },
    {
      cwd: root,
      commits: [{ message }],
      logger: { log() {} },
    }
  )
}

async function main() {
  assert.strictEqual(manifest.package.version, packageJson.version)
  assert.strictEqual(manifest.releasePolicy.currentLine, 'pre1')
  const releaseConfig = require(path.join(root, 'release.config.js'))
  const analyzerPlugin = releaseConfig.plugins[0]
  assert.strictEqual(analyzerPlugin[0], '@semantic-release/commit-analyzer')
  assert.deepStrictEqual(analyzerPlugin[1].releaseRules, releaseRulesForManifest(manifest))
  assert.strictEqual(releaseRulesForManifest(manifest)[0].release, 'minor')
  assert.strictEqual(await analyze(manifest, 'feat!: change stable behavior'), 'minor')
  assert.strictEqual(await analyze(manifest, 'fix: preserve behavior'), 'patch')
  assert.doesNotThrow(() => assertVersionAllowed(manifest, '0.15.0'))
  assert.throws(() => assertVersionAllowed(manifest, '1.0.0'), /requires.*stable/)

  const stable = approvedStableManifest()
  assert.doesNotThrow(() => assertGraduationApproved(stable))
  assert.strictEqual(releaseRulesForManifest(stable)[0].release, 'major')
  assert.strictEqual(await analyze(stable, 'feat!: change stable behavior'), 'major')
  assert.doesNotThrow(() => assertVersionAllowed(stable, '1.0.0'))
  assert.throws(() => assertVersionAllowed(stable, '0.15.0'), /cannot generate a 0\.x/)

  const unapprovedStable = approvedStableManifest()
  unapprovedStable.releasePolicy.graduation.approved = false
  unapprovedStable.releasePolicy.graduation.evidence.independentReview = null
  assert.throws(
    () => releaseRulesForManifest(unapprovedStable),
    /Stable graduation is not approved.*approved=true.*independentReview/
  )

  console.log('[release-policy] OK: pre-1.0 and stable graduation contracts')
}

main().catch((error) => {
  console.error(error.stack || error.message)
  process.exit(1)
})
