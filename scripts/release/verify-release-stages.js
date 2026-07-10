const {
  verifyPreparedRelease,
  verifyTaggedRelease,
} = require('./verify-release-state')
const { safeRelativePath } = require('./sync-versions')

function options(pluginConfig, context) {
  return {
    root: context.cwd,
    version: context.nextRelease.version,
    tag: context.nextRelease.gitTag,
    packagePath: pluginConfig.packagePath || 'dist/reflaxe.elixir.zip',
    manifestPath: pluginConfig.manifestPath || 'release/manifest.json',
    expectedHead: context.nextRelease.gitHead,
  }
}

function verifyConditions(pluginConfig, context) {
  for (const key of ['packagePath', 'manifestPath']) {
    const value = pluginConfig[key]
    if (value !== undefined) safeRelativePath(context.cwd, value, key)
  }
  context.logger.log('Release-stage verification is configured')
}

function prepare(pluginConfig, context) {
  verifyPreparedRelease(options(pluginConfig, context))
  context.logger.success(`Verified prepared release commit for ${context.nextRelease.gitTag}`)
}

function publish(pluginConfig, context) {
  verifyTaggedRelease({
    ...options(pluginConfig, context),
    requireHead: true,
  })
  context.logger.success(`Verified release tag ${context.nextRelease.gitTag} before publication`)
}

module.exports = { prepare, publish, verifyConditions }
