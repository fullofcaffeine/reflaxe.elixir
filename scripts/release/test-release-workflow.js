#!/usr/bin/env node

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const ROOT = path.resolve(__dirname, '../..')
const WORKFLOWS = path.join(ROOT, '.github/workflows')
const CI_PATH = path.join(WORKFLOWS, 'ci.yml')
const REQUIRED_NEEDS = [
  'dogfood-gate',
  'example-compilation-gate',
  'sentinel-gate',
  'secret-scan',
  'guards',
  'dependency-audit',
  'repo-hygiene',
  'haxelib-package-smoke',
  'test',
  'examples',
  'examples-elixir',
  'budgets',
  'smoke-min-toolchain',
  'smoke-macos',
  'docs-smoke',
]

function normalReleaseEligible({ event, ref, conclusions }) {
  return (
    event === 'push' &&
    ref === 'refs/heads/main' &&
    REQUIRED_NEEDS.every((job) => conclusions[job] === 'success')
  )
}

function successfulNeeds() {
  return Object.fromEntries(REQUIRED_NEEDS.map((job) => [job, 'success']))
}

function assertTriggerMatrix() {
  const green = successfulNeeds()
  const fixtures = [
    ['tested main push', 'push', 'refs/heads/main', green, true],
    ['main pull request', 'pull_request', 'refs/pull/12/merge', green, false],
    ['fork pull request', 'pull_request', 'refs/pull/99/merge', green, false],
    ['feature push', 'push', 'refs/heads/feature/release-me', green, false],
    ['manual dispatch', 'workflow_dispatch', 'refs/heads/main', green, false],
    ['workflow completion', 'workflow_run', 'refs/heads/main', green, false],
  ]
  for (const [name, event, ref, conclusions, expected] of fixtures) {
    assert.strictEqual(
      normalReleaseEligible({ event, ref, conclusions }),
      expected,
      name
    )
  }
  for (const conclusion of ['failure', 'cancelled', 'skipped']) {
    const conclusions = successfulNeeds()
    conclusions['sentinel-gate'] = conclusion
    assert.strictEqual(
      normalReleaseEligible({
        event: 'push',
        ref: 'refs/heads/main',
        conclusions,
      }),
      false,
      `${conclusion} gate`
    )
  }
}

function assertPinnedActions() {
  const workflowFiles = fs
    .readdirSync(WORKFLOWS)
    .filter((name) => name.endsWith('.yml'))
  for (const name of workflowFiles) {
    const source = fs.readFileSync(path.join(WORKFLOWS, name), 'utf8')
    for (const match of source.matchAll(/^\s*uses:\s+([^\s#]+)/gm)) {
      const action = match[1]
      if (action.startsWith('./')) continue
      assert.match(
        action,
        /@[0-9a-f]{40}$/,
        `${name} must pin ${action} to a full commit SHA`
      )
    }
  }
}

function main() {
  assert.strictEqual(
    fs.existsSync(path.join(WORKFLOWS, 'release.yml')),
    false,
    'normal publication must not use a detached privileged workflow'
  )

  const ci = fs.readFileSync(CI_PATH, 'utf8')
  assert.doesNotMatch(ci, /workflow_run|workflow_dispatch/)
  assert.match(ci, /push:\n\s+branches: \[ main \]/)
  assert.match(ci, /pull_request:\n\s+branches: \[ main \]/)
  assert.match(
    ci,
    /cancel-in-progress: \$\{\{ github\.ref != 'refs\/heads\/main' \}\}/
  )

  for (const gate of ['dogfood', 'examples', 'sentinel']) {
    const source = fs.readFileSync(path.join(WORKFLOWS, `${gate}.yml`), 'utf8')
    assert.match(source, /on:\n\s+workflow_call:/, `${gate} must be reusable`)
    assert.doesNotMatch(source, /\n\s+push:/)
    assert.doesNotMatch(source, /\n\s+pull_request:/)
    assert.match(ci, new RegExp(`uses: \\.\\/.github/workflows/${gate}\\.yml`))
  }

  const releaseMatch = ci.match(/\n  release:\n([\s\S]+)$/)
  assert(releaseMatch, 'CI must end with the normal release job')
  const release = releaseMatch[1]
  assert.match(
    release,
    /if: github\.event_name == 'push' && github\.ref == 'refs\/heads\/main'/
  )
  for (const dependency of REQUIRED_NEEDS) {
    assert.match(release, new RegExp(`^      - ${dependency}$`, 'm'))
  }
  assert.match(release, /runs-on: ubuntu-24\.04/)
  assert.match(release, /permissions:\n\s+contents: write/)
  assert.doesNotMatch(release, /issues: write|pull-requests: write/)
  assert.match(release, /group: release-\$\{\{ github\.repository \}\}/)
  assert.match(release, /ref: \$\{\{ github\.sha \}\}/)
  assert.match(release, /fetch-depth: 0/)
  assert.match(release, /RELEASE_SOURCE_SHA: \$\{\{ github\.sha \}\}/)
  assert.doesNotMatch(release, /actions\/cache|upload-artifact|download-artifact|cache:/)
  assert.doesNotMatch(release, /api\.github\.com|sleep |workflow_runs/)
  assert.match(
    release,
    /npm ci --ignore-scripts --no-audit --no-fund[\s\S]*npm audit --audit-level=high --omit=optional/
  )

  const packageJson = require(path.join(ROOT, 'package.json'))
  const lock = require(path.join(ROOT, 'package-lock.json'))
  for (const [name, version] of Object.entries(packageJson.devDependencies)) {
    assert.match(version, /^\d+\.\d+\.\d+$/, `${name} must use an exact version`)
    assert.strictEqual(lock.packages[''].devDependencies[name], version)
  }
  assert.strictEqual(packageJson.engines.node, '>=22.14.0')

  const releaseConfig = require(path.join(ROOT, 'release.config.js'))
  const githubPlugin = releaseConfig.plugins.find(
    (plugin) => Array.isArray(plugin) && plugin[0] === '@semantic-release/github'
  )
  assert(githubPlugin, 'GitHub publication plugin is required')
  assert.strictEqual(githubPlugin[1].successComment, false)
  assert.strictEqual(githubPlugin[1].failComment, false)
  assert.strictEqual(githubPlugin[1].releasedLabels, false)

  assertTriggerMatrix()
  assertPinnedActions()
  console.log('[release-workflow] OK: exact-SHA trigger, gate, and trust contracts')
}

main()
