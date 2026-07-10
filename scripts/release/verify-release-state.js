#!/usr/bin/env node
const childProcess = require('child_process')
const fs = require('fs')
const os = require('os')
const path = require('path')
const {
  validateReleasePolicy,
  verifyReleaseVersion,
} = require('./release-policy')
const {
  generateReleaseState,
  generatedReleaseAssets,
} = require('./sync-versions')

const DEFAULT_MANIFEST_PATH = 'release/manifest.json'
const DEFAULT_PACKAGE_PATH = 'dist/reflaxe.elixir.zip'

function command(commandName, args, options = {}) {
  const result = childProcess.spawnSync(commandName, args, {
    cwd: options.cwd,
    encoding: options.encoding === undefined ? 'utf8' : options.encoding,
    env: options.env || process.env,
  })
  if (result.error) throw result.error
  if (result.status !== 0 && !options.allowFailure) {
    const detail = String(result.stderr || result.stdout || '').trim()
    throw new Error(
      `${commandName} ${args.join(' ')} failed${detail ? `: ${detail}` : ''}`
    )
  }
  return result
}

function gitText(root, args, options = {}) {
  return command('git', args, { cwd: root, ...options }).stdout.trim()
}

function gitFile(root, ref, relativePath) {
  return command('git', ['show', `${ref}:${relativePath}`], {
    cwd: root,
    encoding: null,
  }).stdout
}

function gitRef(root, ref) {
  const result = command(
    'git',
    ['rev-parse', '-q', '--verify', `${ref}^{commit}`],
    {
      cwd: root,
      allowFailure: true,
    }
  )
  return result.status === 0 ? result.stdout.trim() : null
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function policyAtRef(root, ref, policyPath) {
  let policy
  try {
    policy = JSON.parse(gitFile(root, ref, policyPath).toString('utf8'))
  } catch (error) {
    throw new Error(`${ref}:${policyPath} is not valid JSON: ${error.message}`)
  }
  return validateReleasePolicy(policy)
}

function verifyGeneratedStateAtRef({ root, ref, version, manifestPath }) {
  const policy = policyAtRef(root, ref, manifestPath)
  verifyReleaseVersion(policy, version)

  const assets = generatedReleaseAssets(manifestPath, root)
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'reflaxe-tag-state-'))
  try {
    for (const relativePath of assets) {
      const target = path.join(tempRoot, relativePath)
      fs.mkdirSync(path.dirname(target), { recursive: true })
      fs.writeFileSync(target, gitFile(root, ref, relativePath))
    }
    generateReleaseState({
      root: tempRoot,
      policyPath: manifestPath,
      version,
      check: true,
    })

    const changelog = fs.readFileSync(
      path.join(tempRoot, 'CHANGELOG.md'),
      'utf8'
    )
    const heading = new RegExp(`^## \\[${escapeRegExp(version)}\\]`, 'm')
    if (!heading.test(changelog)) {
      throw new Error(
        `${ref}:CHANGELOG.md is missing the ${version} release heading`
      )
    }
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true })
  }
  return { policy, assets }
}

function verifyPackageArchive(packagePath, version) {
  if (!fs.existsSync(packagePath) || fs.statSync(packagePath).size === 0) {
    throw new Error(`Release package is missing or empty: ${packagePath}`)
  }

  let metadata
  try {
    metadata = JSON.parse(
      command('unzip', ['-p', packagePath, 'haxelib.json']).stdout
    )
  } catch (error) {
    throw new Error(
      `Release package has invalid haxelib.json: ${error.message}`
    )
  }
  if (metadata.version !== version) {
    throw new Error(
      `Package version ${metadata.version} does not match ${version}`
    )
  }
  if (metadata.classPath !== 'src') {
    throw new Error(
      `Package classPath must be src, found ${metadata.classPath}`
    )
  }
  if (metadata.reflaxe !== undefined) {
    throw new Error(
      'Package metadata still contains source-only reflaxe configuration'
    )
  }

  const files = command('unzip', ['-Z1', packagePath])
    .stdout.split(/\r?\n/)
    .filter(Boolean)
  if (!files.includes('src/haxe/Exception.cross.hx')) {
    throw new Error('Package is missing src/haxe/Exception.cross.hx')
  }
  if (files.some((file) => /(^|\/)std\/elixir\/_std\//.test(file))) {
    throw new Error('Package contains the source-only std/elixir/_std tree')
  }
}

function verifyTrackedTreeClean(root) {
  const unstaged = command('git', ['diff', '--quiet', 'HEAD', '--'], {
    cwd: root,
    allowFailure: true,
  })
  const staged = command('git', ['diff', '--cached', '--quiet', '--'], {
    cwd: root,
    allowFailure: true,
  })
  if (unstaged.status !== 0 || staged.status !== 0) {
    throw new Error('Prepared release has uncommitted tracked changes')
  }
}

function verifyWorkingAssetsMatchCommit(root, ref, assets) {
  for (const relativePath of assets) {
    const workingPath = path.join(root, relativePath)
    if (!fs.existsSync(workingPath)) {
      throw new Error(
        `Prepared release is missing working file ${relativePath}`
      )
    }
    const committed = gitFile(root, ref, relativePath)
    const working = fs.readFileSync(workingPath)
    if (!working.equals(committed)) {
      throw new Error(
        `Prepared release did not commit generated asset ${relativePath}`
      )
    }
  }
}

function validateTag(version, tag) {
  const expected = `v${version}`
  if (tag !== expected)
    throw new Error(`Release tag ${tag} does not match ${expected}`)
}

function verifyPreparedRelease({
  root,
  version,
  tag,
  packagePath = DEFAULT_PACKAGE_PATH,
  manifestPath = DEFAULT_MANIFEST_PATH,
  expectedHead,
}) {
  validateTag(version, tag)
  const head = gitText(root, ['rev-parse', 'HEAD'])
  if (expectedHead && head !== expectedHead) {
    throw new Error(
      `Prepared HEAD ${head} does not match semantic-release gitHead ${expectedHead}`
    )
  }
  if (gitRef(root, `refs/tags/${tag}`)) {
    throw new Error(
      `Release tag ${tag} exists before prepared-state verification`
    )
  }
  const subject = gitText(root, ['log', '-1', '--format=%s', 'HEAD'])
  if (subject !== `chore(release): ${version} [skip ci]`) {
    throw new Error(
      `Prepared release commit has unexpected subject: ${subject}`
    )
  }

  verifyTrackedTreeClean(root)
  generateReleaseState({ root, policyPath: manifestPath, version, check: true })
  const { assets } = verifyGeneratedStateAtRef({
    root,
    ref: 'HEAD',
    version,
    manifestPath,
  })
  verifyWorkingAssetsMatchCommit(root, 'HEAD', assets)
  verifyPackageArchive(path.resolve(root, packagePath), version)
  return { head, assets }
}

function verifyTaggedRelease({
  root,
  version,
  tag,
  packagePath = DEFAULT_PACKAGE_PATH,
  manifestPath = DEFAULT_MANIFEST_PATH,
  requireHead = false,
  expectedHead,
}) {
  validateTag(version, tag)
  const tagCommit = gitRef(root, `refs/tags/${tag}`)
  if (!tagCommit) throw new Error(`Release tag does not exist: ${tag}`)
  if (expectedHead && tagCommit !== expectedHead) {
    throw new Error(
      `Tag ${tag} points to ${tagCommit}, expected ${expectedHead}`
    )
  }
  if (requireHead) {
    const head = gitText(root, ['rev-parse', 'HEAD'])
    if (tagCommit !== head)
      throw new Error(`Tag ${tag} must point to HEAD ${head}`)
  }

  verifyGeneratedStateAtRef({ root, ref: tag, version, manifestPath })
  verifyPackageArchive(path.resolve(root, packagePath), version)
  return { tagCommit }
}

function parseArgs(argv) {
  const [stage, ...rest] = argv
  if (stage !== 'prepared' && stage !== 'tagged') {
    throw new Error(
      'Usage: verify-release-state.js <prepared|tagged> --version X --tag vX'
    )
  }
  const values = {}
  for (let index = 0; index < rest.length; index += 1) {
    const option = rest[index]
    if (option === '--require-head') {
      values.requireHead = true
      continue
    }
    if (!option.startsWith('--') || index + 1 >= rest.length) {
      throw new Error(`Invalid argument: ${option}`)
    }
    values[option.slice(2)] = rest[index + 1]
    index += 1
  }
  if (!values.version || !values.tag)
    throw new Error('--version and --tag are required')
  return { stage, values }
}

function main() {
  const { stage, values } = parseArgs(process.argv.slice(2))
  const options = {
    root: process.cwd(),
    version: values.version,
    tag: values.tag,
    packagePath: values.package || DEFAULT_PACKAGE_PATH,
    manifestPath: values.manifest || DEFAULT_MANIFEST_PATH,
    expectedHead: values['expected-head'],
    requireHead: values.requireHead || false,
  }
  if (stage === 'prepared') verifyPreparedRelease(options)
  else verifyTaggedRelease(options)
  console.log(`[release-state] OK: ${stage} ${values.tag}`)
}

if (require.main === module) {
  try {
    main()
  } catch (error) {
    console.error(`[release-state] ERROR: ${error.message}`)
    process.exit(1)
  }
}

module.exports = {
  verifyGeneratedStateAtRef,
  verifyPackageArchive,
  verifyPreparedRelease,
  verifyTaggedRelease,
}
