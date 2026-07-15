'use strict'

const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { spawnSync } = require('child_process')

const ROOT = path.resolve(__dirname, '../..')
const INSTALLER = path.join(__dirname, 'install-gitleaks.sh')
const WORKFLOWS = path.join(ROOT, '.github', 'workflows')

function extract(source, pattern, label) {
  const match = source.match(pattern)
  assert(match, `missing ${label}`)
  return match[1]
}

function workflowFiles() {
  return fs
    .readdirSync(WORKFLOWS)
    .filter((name) => name.endsWith('.yml') || name.endsWith('.yaml'))
    .sort()
}

const installer = fs.readFileSync(INSTALLER, 'utf8')
const version = extract(
  installer,
  /readonly GITLEAKS_VERSION="([^"]+)"/,
  'pinned Gitleaks version'
)
const digest = extract(
  installer,
  /readonly GITLEAKS_SHA256="([0-9a-f]+)"/,
  'pinned Gitleaks SHA-256'
)
assert.match(version, /^\d+\.\d+\.\d+$/)
assert.match(digest, /^[0-9a-f]{64}$/)

const ci = fs.readFileSync(path.join(WORKFLOWS, 'ci.yml'), 'utf8')
assert.match(ci, /bash scripts\/ci\/install-gitleaks\.sh --install-dir/)
assert.doesNotMatch(
  ci,
  /gitleaks\/gitleaks\/releases\/download/,
  'CI must not bypass the checksum-verifying installer'
)

for (const name of workflowFiles()) {
  const source = fs.readFileSync(path.join(WORKFLOWS, name), 'utf8')
  source.split('\n').forEach((line, index) => {
    const match = line.match(/^\s*uses:\s*([^\s#]+)/)
    if (!match || match[1].startsWith('./')) return
    assert.match(
      match[1],
      /^[^@\s]+@[0-9a-f]{40}$/,
      `${name}:${index + 1} must pin an external action to a full commit SHA`
    )
  })
}

const tempDir = fs.mkdtempSync(
  path.join(os.tmpdir(), 'reflaxe-elixir-security-tool-test-')
)
try {
  const tamperedArchive = path.join(tempDir, 'tampered.tar.gz')
  const installDir = path.join(tempDir, 'bin')
  fs.writeFileSync(tamperedArchive, 'bytes that are not the reviewed release')

  const result = spawnSync(
    'bash',
    [
      INSTALLER,
      '--archive',
      tamperedArchive,
      '--install-dir',
      installDir
    ],
    { encoding: 'utf8' }
  )
  assert.notStrictEqual(result.status, 0, 'tampered archive must be rejected')
  assert.match(result.stderr, /checksum mismatch/)
  assert.strictEqual(
    fs.existsSync(path.join(installDir, 'gitleaks')),
    false,
    'tampered bytes must not be installed'
  )
} finally {
  fs.rmSync(tempDir, { recursive: true, force: true })
}

process.stdout.write(
  `[security-tools] Gitleaks ${version} digest, tamper rejection, and Action pins: OK\n`
)
