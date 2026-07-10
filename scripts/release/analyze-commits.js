const { analyzeCommits: analyzeConventionalCommits } = require('@semantic-release/commit-analyzer')
const {
  DEFAULT_MANIFEST_PATH,
  loadReleaseManifest,
  releaseRulesForManifest,
} = require('./release-manifest')

async function analyzeCommits(pluginConfig, context) {
  const manifestPath = pluginConfig.manifestPath || DEFAULT_MANIFEST_PATH
  const manifest = loadReleaseManifest(manifestPath, context.cwd)
  const releaseRules = releaseRulesForManifest(manifest)

  context.logger.log(
    `Using ${manifest.releasePolicy.currentLine} release policy from ${manifestPath}`
  )

  return analyzeConventionalCommits(
    {
      preset: 'conventionalcommits',
      releaseRules,
    },
    context
  )
}

module.exports = { analyzeCommits }
