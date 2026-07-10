const fs = require('fs')
const path = require('path')

const DEFAULT_MANIFEST_PATH = 'release/manifest.json'
const SEMVER_PATTERN = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/
const APPROVAL_BEAD_PATTERN = /^haxe\.elixir(?:\.codex)?-[0-9A-Za-z.]+$/
const APPROVAL_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/
const EVIDENCE_KEYS = [
  'platformToolchain',
  'compatibility',
  'applicationRuntime',
  'independentReview',
]

function fail(message) {
  throw new Error(`Invalid release manifest: ${message}`)
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function parseSemver(version, label = 'version') {
  const match = typeof version === 'string' ? SEMVER_PATTERN.exec(version) : null
  if (!match) fail(`${label} must be a valid semantic version`)
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  }
}

function validateReleaseManifest(manifest) {
  if (!isObject(manifest)) fail('root must be an object')
  if (manifest.schemaVersion !== 1) fail('schemaVersion must be 1')

  if (!isObject(manifest.package)) fail('package must be an object')
  if (manifest.package.name !== 'reflaxe.elixir') {
    fail('package.name must be reflaxe.elixir')
  }
  parseSemver(manifest.package.version, 'package.version')

  const policy = manifest.releasePolicy
  if (!isObject(policy)) fail('releasePolicy must be an object')
  if (policy.currentLine !== 'pre1' && policy.currentLine !== 'stable') {
    fail('releasePolicy.currentLine must be pre1 or stable')
  }

  if (!isObject(policy.lines)) fail('releasePolicy.lines must be an object')
  const pre1 = policy.lines.pre1
  const stable = policy.lines.stable
  if (!isObject(pre1) || pre1.major !== 0 || pre1.breakingRelease !== 'minor') {
    fail('pre1 line must use major 0 and minor breaking releases')
  }
  if (!isObject(stable) || stable.minimumMajor !== 1 || stable.breakingRelease !== 'major') {
    fail('stable line must start at major 1 and use major breaking releases')
  }

  const graduation = policy.graduation
  if (!isObject(graduation) || typeof graduation.approved !== 'boolean') {
    fail('releasePolicy.graduation must contain an approved boolean')
  }
  if (!isObject(graduation.evidence)) {
    fail('releasePolicy.graduation.evidence must be an object')
  }
  for (const key of EVIDENCE_KEYS) {
    if (!(key in graduation.evidence)) {
      fail(`releasePolicy.graduation.evidence.${key} is required`)
    }
  }

  return manifest
}

function loadReleaseManifest(manifestPath = DEFAULT_MANIFEST_PATH, cwd = process.cwd()) {
  const absolutePath = path.resolve(cwd, manifestPath)
  let parsed
  try {
    parsed = JSON.parse(fs.readFileSync(absolutePath, 'utf8'))
  } catch (error) {
    throw new Error(`Unable to read release manifest ${absolutePath}: ${error.message}`)
  }
  return validateReleaseManifest(parsed)
}

function assertGraduationApproved(manifest) {
  validateReleaseManifest(manifest)
  const graduation = manifest.releasePolicy.graduation
  const missing = []

  if (graduation.approved !== true) missing.push('approved=true')
  if (!APPROVAL_BEAD_PATTERN.test(graduation.approvalBead || '')) {
    missing.push('a reviewed approvalBead')
  }
  if (!APPROVAL_DATE_PATTERN.test(graduation.approvedAt || '')) {
    missing.push('approvedAt in YYYY-MM-DD form')
  }
  for (const key of EVIDENCE_KEYS) {
    const value = graduation.evidence[key]
    if (typeof value !== 'string' || value.trim() === '') {
      missing.push(`${key} evidence`)
    }
  }

  if (missing.length > 0) {
    throw new Error(`Stable graduation is not approved: missing ${missing.join(', ')}`)
  }
}

function assertVersionAllowed(manifest, version) {
  validateReleaseManifest(manifest)
  const { major } = parseSemver(version, 'requested version')
  const line = manifest.releasePolicy.currentLine

  if (major === 0 && line !== 'pre1') {
    throw new Error('Stable release policy cannot generate a 0.x version')
  }
  if (major >= 1) {
    if (line !== 'stable') {
      throw new Error('A 1.x release requires releasePolicy.currentLine=stable')
    }
    assertGraduationApproved(manifest)
  }
}

function releaseRulesForManifest(manifest) {
  validateReleaseManifest(manifest)
  const line = manifest.releasePolicy.currentLine
  if (line === 'stable') assertGraduationApproved(manifest)

  return [
    {
      breaking: true,
      release: manifest.releasePolicy.lines[line].breakingRelease,
    },
    { type: 'feat', release: 'minor' },
    { type: 'fix', release: 'patch' },
    { type: 'perf', release: 'patch' },
    { type: 'revert', release: 'patch' },
  ]
}

module.exports = {
  DEFAULT_MANIFEST_PATH,
  assertGraduationApproved,
  assertVersionAllowed,
  loadReleaseManifest,
  parseSemver,
  releaseRulesForManifest,
  validateReleaseManifest,
}
