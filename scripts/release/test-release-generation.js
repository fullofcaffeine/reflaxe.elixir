#!/usr/bin/env node

const assert = require('assert')
const crypto = require('crypto')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { loadReleasePolicy, parseSemanticVersion } = require('./release-policy')
const {
  generateReleaseState,
  generatedReleaseAssets,
  latestReachableVersion,
  safeRelativePath,
} = require('./sync-versions')

const root = path.resolve(__dirname, '../..')
const releaseConfig = require(path.join(root, 'release.config.js'))

function copyFile(sourceRoot, targetRoot, relativePath) {
  const source = path.join(sourceRoot, relativePath)
  const target = path.join(targetRoot, relativePath)
  fs.mkdirSync(path.dirname(target), { recursive: true })
  fs.copyFileSync(source, target)
}

function tempRepo() {
  const targetRoot = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-release-generation-')
  )
  for (const file of generatedReleaseAssets()) copyFile(root, targetRoot, file)
  return targetRoot
}

function digestFiles(targetRoot, files) {
  const digest = crypto.createHash('sha256')
  for (const file of [...files].sort()) {
    digest.update(file)
    digest.update('\0')
    digest.update(fs.readFileSync(path.join(targetRoot, file)))
    digest.update('\0')
  }
  return digest.digest('hex')
}

function main() {
  const targetRoot = tempRepo()
  try {
    const policy = loadReleasePolicy('release/manifest.json', targetRoot)
    const policyBefore = fs.readFileSync(
      path.join(targetRoot, 'release/manifest.json'),
      'utf8'
    )
    const assets = generatedReleaseAssets()
    assert(assets.includes('release/manifest.json'))
    assert(assets.includes('CHANGELOG.md'))
    assert(assets.includes('docs/06-guides/VERSIONING_AND_STABILITY.md'))
    assert.strictEqual(new Set(assets).size, assets.length)
    assert.deepStrictEqual(Object.keys(policy).sort(), [
      'releaseLines',
      'schemaVersion',
    ])

    const commitPlugin = releaseConfig.plugins.find(
      (plugin) => Array.isArray(plugin) && plugin[0] === '@semantic-release/git'
    )
    assert(
      commitPlugin,
      'legacy release generation must remain wired until the artifact child'
    )
    assert.deepStrictEqual(commitPlugin[1].assets, assets)

    const currentVersion = JSON.parse(
      fs.readFileSync(path.join(targetRoot, 'package.json'), 'utf8')
    ).version
    const parsedVersion = parseSemanticVersion(currentVersion)
    const generatedVersion = `${parsedVersion.major}.${parsedVersion.minor}.${parsedVersion.patch + 1}`
    assert.notStrictEqual(generatedVersion, currentVersion)

    const first = generateReleaseState({
      root: targetRoot,
      version: generatedVersion,
    })
    assert(!first.changed.includes('release/manifest.json'))
    assert(first.changed.includes('package.json'))
    assert(first.changed.includes('README.md'))
    assert.strictEqual(
      fs.readFileSync(path.join(targetRoot, 'release/manifest.json'), 'utf8'),
      policyBefore,
      'release policy must not become generated version state'
    )
    assert.strictEqual(
      JSON.parse(fs.readFileSync(path.join(targetRoot, 'package.json'), 'utf8'))
        .version,
      generatedVersion
    )
    assert.strictEqual(
      JSON.parse(
        fs.readFileSync(path.join(targetRoot, 'package-lock.json'), 'utf8')
      ).packages[''].version,
      generatedVersion
    )
    assert.strictEqual(
      JSON.parse(fs.readFileSync(path.join(targetRoot, 'haxelib.json'), 'utf8'))
        .version,
      generatedVersion
    )
    assert(
      fs
        .readFileSync(path.join(targetRoot, 'mix.exs'), 'utf8')
        .includes(`version: "${generatedVersion}"`)
    )
    assert(
      fs
        .readFileSync(
          path.join(targetRoot, 'haxe_libraries/reflaxe.elixir.hxml'),
          'utf8'
        )
        .includes(`-D reflaxe.elixir=${generatedVersion}`)
    )
    assert(
      fs
        .readFileSync(path.join(targetRoot, 'README.md'), 'utf8')
        .includes(`v${generatedVersion} is on`)
    )
    assert(
      fs
        .readFileSync(
          path.join(targetRoot, 'docs/06-guides/VERSIONING_AND_STABILITY.md'),
          'utf8'
        )
        .includes(`Current version: **v${generatedVersion}**`)
    )

    const firstDigest = digestFiles(targetRoot, assets)
    const second = generateReleaseState({
      root: targetRoot,
      version: generatedVersion,
    })
    const secondDigest = digestFiles(targetRoot, assets)
    assert.deepStrictEqual(second.changed, [])
    assert.strictEqual(firstDigest, secondDigest)
    assert.doesNotThrow(() =>
      generateReleaseState({
        root: targetRoot,
        version: generatedVersion,
        check: true,
      })
    )

    const readmePath = path.join(targetRoot, 'README.md')
    fs.writeFileSync(
      readmePath,
      fs
        .readFileSync(readmePath, 'utf8')
        .replace(`version-${generatedVersion}-blue`, 'version-0.0.0-blue')
    )
    const drifted = fs.readFileSync(readmePath, 'utf8')
    assert.throws(
      () =>
        generateReleaseState({
          root: targetRoot,
          version: generatedVersion,
          check: true,
        }),
      /Generated release state is stale: README\.md/
    )
    assert.strictEqual(fs.readFileSync(readmePath, 'utf8'), drifted)
    generateReleaseState({ root: targetRoot, version: generatedVersion })

    const missingMarker = fs
      .readFileSync(readmePath, 'utf8')
      .replace('<!-- END GENERATED: release-posture -->', '')
    fs.writeFileSync(readmePath, missingMarker)
    assert.throws(
      () =>
        generateReleaseState({
          root: targetRoot,
          version: generatedVersion,
          check: true,
        }),
      /must contain exactly one.*END GENERATED: release-posture/
    )
    copyFile(root, targetRoot, 'README.md')

    const duplicateMarker = fs
      .readFileSync(readmePath, 'utf8')
      .replace(
        '<!-- BEGIN GENERATED: release-posture -->',
        '<!-- BEGIN GENERATED: release-posture -->\n<!-- BEGIN GENERATED: release-posture -->'
      )
    fs.writeFileSync(readmePath, duplicateMarker)
    assert.throws(
      () =>
        generateReleaseState({
          root: targetRoot,
          version: generatedVersion,
          check: true,
        }),
      /must contain exactly one.*BEGIN GENERATED: release-posture/
    )

    assert.throws(
      () => safeRelativePath(targetRoot, '../outside.json', 'test path'),
      /must not contain parent traversal/
    )
    const reachableVersion = latestReachableVersion(root)
    assert.doesNotThrow(() => parseSemanticVersion(reachableVersion))

    console.log(
      '[release-generation] OK: policy-independent legacy generation remains deterministic'
    )
  } finally {
    fs.rmSync(targetRoot, { recursive: true, force: true })
  }
}

main()
