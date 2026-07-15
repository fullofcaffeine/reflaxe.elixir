const path = require('path')
const {
  isStableMajorApproved,
  loadReleasePolicy,
  parseSemanticVersion,
  releaseLine,
  verifyReleaseVersion,
} = require('./release-policy.js')

function policyPath(pluginConfig, context) {
  const configured = pluginConfig.policyPath || 'release/manifest.json'
  return path.isAbsolute(configured)
    ? configured
    : path.resolve(context.cwd, configured)
}

/**
 * Conventional Commits describe consumer impact, but the analyzer's normal
 * `major` result does not express this project's initial-development policy.
 * Delegate parsing to the pinned official analyzer, then cap only an
 * unapproved 0.x breaking change to the policy's minor bump. The verify hook
 * independently rejects unknown or unapproved derived majors. Package metadata
 * and generated documentation are never consulted.
 */
async function analyzeCommits(pluginConfig, context) {
  const { analyzeCommits: officialAnalyzeCommits } = await import(
    '@semantic-release/commit-analyzer'
  )
  const analyzed = await officialAnalyzeCommits(
    { preset: 'conventionalcommits', ...(pluginConfig.commitAnalyzer || {}) },
    context
  )
  if (analyzed !== 'major') return analyzed

  const lastVersion = context.lastRelease && context.lastRelease.version
  const last = parseSemanticVersion(lastVersion)
  const policy = loadReleasePolicy(
    policyPath(pluginConfig, context),
    context.cwd
  )
  if (last.major === 0 && !isStableMajorApproved(policy, 1)) {
    return releaseLine(policy, 0).breakingBump
  }
  return analyzed
}

async function verifyRelease(pluginConfig, context) {
  const policy = loadReleasePolicy(
    policyPath(pluginConfig, context),
    context.cwd
  )
  verifyReleaseVersion(policy, context.nextRelease.version)
}

module.exports = { analyzeCommits, verifyRelease }
