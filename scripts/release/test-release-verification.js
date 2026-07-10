#!/usr/bin/env node
const assert = require('assert')
const childProcess = require('child_process')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { loadReleasePolicy, parseSemanticVersion } = require('./release-policy')
const {
  generateReleaseState,
  generatedReleaseAssets,
} = require('./sync-versions')
const {
  verifyPreparedRelease,
  verifyTaggedRelease,
} = require('./verify-release-state')

const root = path.resolve(__dirname, '../..')
const releaseConfig = require(path.join(root, 'release.config.js'))

function run(commandName, args, cwd) {
  childProcess.execFileSync(commandName, args, { cwd, stdio: 'pipe' })
}

function copyFile(sourceRoot, targetRoot, relativePath) {
  const target = path.join(targetRoot, relativePath)
  fs.mkdirSync(path.dirname(target), { recursive: true })
  fs.copyFileSync(path.join(sourceRoot, relativePath), target)
}

function createPackage(repoRoot, version, includeCross = true) {
  const packageRoot = path.join(repoRoot, '_package')
  fs.rmSync(packageRoot, { recursive: true, force: true })
  fs.mkdirSync(path.join(packageRoot, 'src/haxe'), { recursive: true })
  fs.writeFileSync(
    path.join(packageRoot, 'haxelib.json'),
    `${JSON.stringify({ name: 'reflaxe.elixir', version, classPath: 'src' }, null, 2)}\n`
  )
  if (includeCross) {
    fs.writeFileSync(
      path.join(packageRoot, 'src/haxe/Exception.cross.hx'),
      'package haxe;\n'
    )
  }
  fs.mkdirSync(path.join(repoRoot, 'dist'), { recursive: true })
  const packagePath = path.join(repoRoot, 'dist/reflaxe.elixir.zip')
  fs.rmSync(packagePath, { force: true })
  run('zip', ['-q', '-r', packagePath, '.'], packageRoot)
  return packagePath
}

function createReleaseRepo() {
  const repoRoot = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-release-verify-')
  )
  loadReleasePolicy('release/manifest.json', root)
  for (const file of generatedReleaseAssets()) copyFile(root, repoRoot, file)

  run('git', ['init', '-q'], repoRoot)
  run('git', ['config', 'user.name', 'Release Test'], repoRoot)
  run('git', ['config', 'user.email', 'release-test@example.invalid'], repoRoot)
  run('git', ['add', '.'], repoRoot)
  run('git', ['commit', '-q', '-m', 'baseline'], repoRoot)

  const currentVersion = JSON.parse(
    fs.readFileSync(path.join(root, 'package.json'), 'utf8')
  ).version
  const parsedVersion = parseSemanticVersion(currentVersion)
  const version = `${parsedVersion.major}.${parsedVersion.minor}.${parsedVersion.patch + 1}`
  const tag = `v${version}`
  generateReleaseState({ root: repoRoot, version })
  const changelogPath = path.join(repoRoot, 'CHANGELOG.md')
  fs.writeFileSync(
    changelogPath,
    `## [${version}](https://example.invalid/${tag}) (2026-07-10)\n\n${fs.readFileSync(
      changelogPath,
      'utf8'
    )}`
  )
  run('git', ['add', '.'], repoRoot)
  run(
    'git',
    ['commit', '-q', '-m', `chore(release): ${version} [skip ci]\n\nnotes`],
    repoRoot
  )
  createPackage(repoRoot, version)
  return { repoRoot, version, tag }
}

function main() {
  const verifierIndex = releaseConfig.plugins.findIndex(
    (plugin) =>
      Array.isArray(plugin) &&
      plugin[0] === './scripts/release/verify-release-stages.js'
  )
  const gitIndex = releaseConfig.plugins.findIndex(
    (plugin) => Array.isArray(plugin) && plugin[0] === '@semantic-release/git'
  )
  const githubIndex = releaseConfig.plugins.findIndex(
    (plugin) =>
      Array.isArray(plugin) && plugin[0] === '@semantic-release/github'
  )
  assert(
    gitIndex >= 0 && verifierIndex > gitIndex && githubIndex > verifierIndex
  )

  const gitPlugin = releaseConfig.plugins[gitIndex]
  assert(
    gitPlugin[1].message.includes('\n\n'),
    'release commit template must use real newlines'
  )
  assert(
    !gitPlugin[1].message.includes('\\n'),
    'release commit template must not use literal backslash-n text'
  )

  const releaseWorkflow = fs.readFileSync(
    path.join(root, '.github/workflows/release.yml'),
    'utf8'
  )
  assert.match(releaseWorkflow, /id: semantic_release/)
  assert.match(releaseWorkflow, /latestReachableVersion/)
  assert.match(
    releaseWorkflow,
    /steps\.semantic_release\.outputs\.published == 'true'/
  )
  assert.match(
    releaseWorkflow,
    /verify-published-package\.sh "\$\{\{ steps\.semantic_release\.outputs\.tag \}\}"/
  )

  const fixture = createReleaseRepo()
  const options = {
    root: fixture.repoRoot,
    version: fixture.version,
    tag: fixture.tag,
  }
  try {
    assert.doesNotThrow(() => verifyPreparedRelease(options))

    const readmePath = path.join(fixture.repoRoot, 'README.md')
    const readme = fs.readFileSync(readmePath)
    fs.appendFileSync(readmePath, '\nstale tracked state\n')
    assert.throws(
      () => verifyPreparedRelease(options),
      /uncommitted tracked changes/
    )
    fs.writeFileSync(readmePath, readme)

    createPackage(fixture.repoRoot, fixture.version, false)
    assert.throws(
      () => verifyPreparedRelease(options),
      /missing src\/haxe\/Exception\.cross\.hx/
    )
    createPackage(fixture.repoRoot, fixture.version)

    run('git', ['tag', fixture.tag], fixture.repoRoot)
    assert.throws(
      () => verifyPreparedRelease(options),
      /exists before prepared-state verification/
    )
    assert.doesNotThrow(() =>
      verifyTaggedRelease({ ...options, requireHead: true })
    )

    const parsedVersion = parseSemanticVersion(fixture.version)
    const wrongVersion = `${parsedVersion.major}.${parsedVersion.minor}.${parsedVersion.patch + 1}`
    const wrongTag = `v${wrongVersion}`
    run('git', ['tag', wrongTag, 'HEAD^'], fixture.repoRoot)
    assert.throws(
      () =>
        verifyTaggedRelease({
          ...options,
          version: wrongVersion,
          tag: wrongTag,
          requireHead: true,
        }),
      /must point to HEAD/
    )

    console.log(
      '[release-verification] OK: prepared, tagged, and failure contracts'
    )
  } finally {
    fs.rmSync(fixture.repoRoot, { recursive: true, force: true })
  }
}

main()
