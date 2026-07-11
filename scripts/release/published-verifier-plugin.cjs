const path = require('path')
const {
  normalizeSha,
  verifyHostedRelease,
  verifyTagIdentity,
} = require('./release-provenance.js')

function sourceCommit(cwd) {
  const { execFileSync } = require('child_process')
  const head = normalizeSha(
    execFileSync('git', ['rev-parse', 'HEAD^{commit}'], {
      cwd,
      encoding: 'utf8',
    }),
    'checked-out HEAD'
  )
  return process.env.RELEASE_SOURCE_SHA
    ? normalizeSha(process.env.RELEASE_SOURCE_SHA, 'RELEASE_SOURCE_SHA')
    : head
}

/** Verify immutable hosted provenance after GitHub publishes the complete draft. */
async function publish(_pluginConfig, context) {
  const cwd = context.cwd
  const source = sourceCommit(cwd)
  const version = context.nextRelease.version
  const tag = context.nextRelease.gitTag
  verifyTagIdentity({ tag, sourceCommit: source, cwd })
  verifyHostedRelease({
    version,
    tag,
    zipPath: path.join(cwd, 'dist', 'reflaxe.elixir.zip'),
    checksumPath: path.join(cwd, 'dist', 'reflaxe.elixir.zip.sha256'),
    cwd,
    attempts: 6,
    retryDelayMs: 5000,
  })
  context.logger.success(
    `Verified immutable hosted release ${tag} and both approved asset digests`
  )
}

module.exports = { publish }
