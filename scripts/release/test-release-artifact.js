#!/usr/bin/env node

const assert = require('assert')
const crypto = require('crypto')
const { execFileSync } = require('child_process')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { strToU8, zipSync } = require('fflate')
const zipApi = require('./deterministic-zip')
const artifactPlugin = require('./haxelib-artifact-plugin.cjs')
const { preparePackageMetadata } = require('./prepare-package-metadata')
const verifyApi = require('./verify-release-artifact')

const VERSION = '0.15.0'
const TAG = `v${VERSION}`
const SOURCE_SHA = '1234567890abcdef1234567890abcdef12345678'
const ZIP_SCRIPT = path.join(__dirname, 'deterministic-zip.js')
const ROOT = path.resolve(__dirname, '../..')

function write(root, relativePath, content) {
  const filePath = path.join(root, relativePath)
  fs.mkdirSync(path.dirname(filePath), { recursive: true })
  fs.writeFileSync(filePath, content)
}

function packageFixture(root, options = {}) {
  write(
    root,
    'haxelib.json',
    `${JSON.stringify(
      {
        name: 'reflaxe.elixir',
        version: '0.0.0',
        releasenote: 'Development checkout',
        classPath: 'src',
      },
      null,
      2
    )}\n`
  )
  for (const [name, content] of Object.entries({
    'README.md': '# fixture\n',
    LICENSE: 'fixture license\n',
    'extraParams.hxml': '# fixture\n',
    'src/Run.hx': 'class Run {}\n',
    'src/Std.cross.hx': 'class Std {}\n',
    'src/String.cross.hx': 'class String {}\n',
    'src/StringBuf.cross.hx': 'class StringBuf {}\n',
    'src/haxe/Exception.cross.hx': 'package haxe; class Exception {}\n',
    'src/reflaxe/elixir/CompilerBootstrap.hx':
      'package reflaxe.elixir; class CompilerBootstrap {}\n',
    'vendor/reflaxe/src/reflaxe/ReflectCompiler.hx':
      'package reflaxe; class ReflectCompiler {}\n',
    'vendor/phoenix_shared/src/phoenix/channels/WirePayload.hx':
      'package phoenix.channels; class WirePayload {}\n',
    'vendor/phoenix_shared/src/phoenix/live_react/LiveReactEventProtocol.hx':
      'package phoenix.live_react; class LiveReactEventProtocol {}\n',
  })) {
    write(root, name, content)
  }
  preparePackageMetadata({
    haxelibPath: path.join(root, 'haxelib.json'),
    metadataPath: path.join(root, 'release-metadata.json'),
    version: options.version || VERSION,
    tag: options.tag || TAG,
    sourceCommit: SOURCE_SHA,
  })
}

function sha256(filePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(filePath))
    .digest('hex')
}

function touchTree(root, milliseconds) {
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const entryPath = path.join(root, entry.name)
    if (entry.isDirectory()) touchTree(entryPath, milliseconds + 1000)
    fs.utimesSync(entryPath, milliseconds / 1000, milliseconds / 1000)
  }
}

function replaceAllAscii(buffer, from, to) {
  assert.strictEqual(Buffer.byteLength(from), Buffer.byteLength(to))
  let replacements = 0
  let offset = 0
  while ((offset = buffer.indexOf(from, offset, 'utf8')) !== -1) {
    buffer.write(to, offset, 'utf8')
    offset += Buffer.byteLength(to)
    replacements += 1
  }
  return replacements
}

function verify(zipPath) {
  return verifyApi.verifyReleaseArtifact({
    zipPath,
    version: VERSION,
    tag: TAG,
    sourceCommit: SOURCE_SHA,
  })
}

function main() {
  const releaseConfig = require(path.join(ROOT, 'release.config.js'))
  const pluginNames = releaseConfig.plugins.map((plugin) =>
    Array.isArray(plugin) ? plugin[0] : plugin
  )
  for (const forbidden of [
    '@semantic-release/changelog',
    '@semantic-release/exec',
    '@semantic-release/git',
  ]) {
    assert(
      !pluginNames.includes(forbidden),
      `normal publication must not use ${forbidden}`
    )
  }
  assert(pluginNames.includes('./scripts/release/haxelib-artifact-plugin.cjs'))
  assert(
    pluginNames.includes('./scripts/release/published-verifier-plugin.cjs')
  )
  const github = releaseConfig.plugins.find(
    (plugin) =>
      Array.isArray(plugin) && plugin[0] === '@semantic-release/github'
  )
  assert(
    github[1].assets.some(({ path: assetPath }) =>
      assetPath.endsWith('.zip.sha256')
    )
  )
  assert.strictEqual(
    require(path.join(ROOT, 'package.json')).version,
    '0.0.0-development'
  )
  assert.strictEqual(require(path.join(ROOT, 'haxelib.json')).version, '0.0.0')
  assert.doesNotThrow(() =>
    artifactPlugin.assertMeaningfulReleaseNotes(
      '## 0.15.0\n\n### Bug Fixes\n\n* **release:** restore notes\n'
    )
  )
  assert.throws(
    () => artifactPlugin.assertMeaningfulReleaseNotes('## 0.15.0\n'),
    /heading-only release/
  )
  assert.throws(
    () => artifactPlugin.assertMeaningfulReleaseNotes(undefined),
    /heading-only release/
  )

  const temp = fs.mkdtempSync(
    path.join(os.tmpdir(), 'reflaxe-elixir-release-artifact-')
  )
  try {
    const left = path.join(temp, 'left')
    const right = path.join(temp, 'right')
    packageFixture(left)
    packageFixture(right)
    touchTree(left, Date.UTC(2020, 0, 1))
    touchTree(right, Date.UTC(2030, 5, 1))
    fs.chmodSync(path.join(left, 'README.md'), 0o600)
    fs.chmodSync(path.join(right, 'README.md'), 0o755)
    const leftZip = path.join(temp, 'left.zip')
    const rightZip = path.join(temp, 'right.zip')
    execFileSync(process.execPath, [ZIP_SCRIPT, left, leftZip], {
      env: { ...process.env, TZ: 'America/Mexico_City' },
      stdio: 'pipe',
    })
    execFileSync(process.execPath, [ZIP_SCRIPT, right, rightZip], {
      env: { ...process.env, TZ: 'UTC' },
      stdio: 'pipe',
    })
    assert.strictEqual(sha256(leftZip), sha256(rightZip))

    const result = verify(leftZip)
    assert.strictEqual(result.sha256, sha256(leftZip))
    assert.strictEqual(result.size, fs.statSync(leftZip).size)
    assert.deepStrictEqual(
      [...result.entries].sort(zipApi.compareEntryNames),
      result.entries
    )
    const checksumPath = path.join(temp, 'left.zip.sha256')
    fs.writeFileSync(
      checksumPath,
      `${result.sha256}  ${artifactPlugin.artifactNames(VERSION).archive}\n`
    )
    artifactPlugin.verifyApprovedArtifact({
      zipPath: leftZip,
      checksumPath,
      version: VERSION,
      tag: TAG,
      source: SOURCE_SHA,
    })

    write(left, 'README.md', '# altered fixture\n')
    zipApi.createDeterministicZip(left, leftZip)
    assert.throws(
      () =>
        artifactPlugin.verifyApprovedArtifact({
          zipPath: leftZip,
          checksumPath,
          version: VERSION,
          tag: TAG,
          source: SOURCE_SHA,
        }),
      /approved release artifact changed/
    )
    packageFixture(left)
    zipApi.createDeterministicZip(left, leftZip)

    const noncanonicalZip = path.join(temp, 'noncanonical.zip')
    const noncanonicalEntries = Object.create(null)
    for (const file of zipApi.collectFiles(left)) {
      Object.defineProperty(noncanonicalEntries, file.name, {
        enumerable: true,
        value: [
          fs.readFileSync(file.absolute),
          {
            level: 9,
            mtime: new Date(2001, 0, 1),
            os: 3,
            attrs: 0o644 << 16,
          },
        ],
      })
    }
    fs.writeFileSync(noncanonicalZip, Buffer.from(zipSync(noncanonicalEntries)))
    assert.throws(
      () => verify(noncanonicalZip),
      /not in canonical ZIP representation/
    )

    const missing = path.join(temp, 'missing')
    packageFixture(missing)
    fs.rmSync(path.join(missing, 'src/haxe/Exception.cross.hx'))
    const missingZip = path.join(temp, 'missing.zip')
    zipApi.createDeterministicZip(missing, missingZip)
    assert.throws(() => verify(missingZip), /required archive entry is missing/)

    const wrong = path.join(temp, 'wrong')
    packageFixture(wrong, { version: '0.14.9', tag: 'v0.14.9' })
    const wrongZip = path.join(temp, 'wrong.zip')
    zipApi.createDeterministicZip(wrong, wrongZip)
    assert.throws(
      () => verify(wrongZip),
      /packaged haxelib version 0\.14\.9 does not match/
    )

    const unexpected = path.join(temp, 'unexpected')
    packageFixture(unexpected)
    write(unexpected, 'private/secret.txt', 'no\n')
    const unexpectedZip = path.join(temp, 'unexpected.zip')
    zipApi.createDeterministicZip(unexpected, unexpectedZip)
    assert.throws(
      () => verify(unexpectedZip),
      /unexpected archive root: private/
    )

    const unsafeZip = path.join(temp, 'unsafe.zip')
    fs.writeFileSync(
      unsafeZip,
      Buffer.from(zipSync({ '../escape.txt': strToU8('escape') }))
    )
    assert.throws(() => verify(unsafeZip), /unsafe archive entry/)

    const duplicateZip = path.join(temp, 'duplicate.zip')
    const duplicateBytes = Buffer.from(
      zipSync({
        'a.txt': [strToU8('a'), { os: 3, attrs: 0o644 << 16 }],
        'b.txt': [strToU8('b'), { os: 3, attrs: 0o644 << 16 }],
      })
    )
    assert.strictEqual(replaceAllAscii(duplicateBytes, 'b.txt', 'a.txt'), 2)
    fs.writeFileSync(duplicateZip, duplicateBytes)
    assert.throws(() => verify(duplicateZip), /duplicate archive entry/)

    const modeZip = path.join(temp, 'mode.zip')
    fs.writeFileSync(
      modeZip,
      Buffer.from(
        zipSync({
          'README.md': [strToU8('readme'), { os: 3, attrs: 0o600 << 16 }],
        })
      )
    )
    assert.throws(() => verify(modeZip), /archive entry mode must be 0644/)

    assert.throws(
      () => zipApi.validateEntryNames(['a.txt', 'a.txt']),
      /duplicate archive entry/
    )
    assert.throws(
      () => zipApi.validateEntryNames(['/absolute.txt']),
      /unsafe archive entry/
    )
    assert.throws(
      () => zipApi.validateEntryNames(['windows\\escape.txt']),
      /unsafe archive entry/
    )

    const symlink = path.join(temp, 'symlink')
    packageFixture(symlink)
    fs.symlinkSync(
      path.join(symlink, 'README.md'),
      path.join(symlink, 'linked-readme')
    )
    assert.throws(
      () =>
        zipApi.createDeterministicZip(symlink, path.join(temp, 'symlink.zip')),
      /symbolic link/
    )

    assert.throws(
      () =>
        preparePackageMetadata({
          haxelibPath: path.join(left, 'haxelib.json'),
          metadataPath: path.join(left, 'bad.json'),
          version: VERSION,
          tag: 'v9.9.9',
          sourceCommit: SOURCE_SHA,
        }),
      /package tag must be/
    )

    const workflow = fs.readFileSync(
      path.join(ROOT, '.github/workflows/ci.yml'),
      'utf8'
    )
    assert.match(
      workflow,
      /RELEASE_SOURCE_SHA: \$\{\{ github\.sha \}\}/
    )
    const packageJob = workflow.match(
      /  haxelib-package-smoke:\n([\s\S]*?)\n  [a-z][a-z0-9-]+:\n/
    )
    assert(packageJob, 'CI must contain the dedicated haxelib package job')
    assert.match(
      packageJob[1],
      /erlef\/setup-beam@[0-9a-f]{40}[\s\S]*npm ci --ignore-scripts --no-audit --no-fund[\s\S]*npm run test:haxelib-package/
    )
    assert.match(workflow, /uses: erlef\/setup-beam@[0-9a-f]{40}/)
    console.log(
      '[release-artifact] OK: canonical archive and adversarial validation contracts'
    )
  } finally {
    fs.rmSync(temp, { recursive: true, force: true })
  }
}

main()
