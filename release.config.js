const {
  DEFAULT_MANIFEST_PATH,
  loadReleaseManifest,
  releaseRulesForManifest,
} = require('./scripts/release/release-manifest')
const { generatedReleaseAssets } = require('./scripts/release/sync-versions')

const root = __dirname
const manifest = loadReleaseManifest(DEFAULT_MANIFEST_PATH, root)

module.exports = {
  branches: ['main'],
  plugins: [
    [
      '@semantic-release/commit-analyzer',
      {
        preset: 'conventionalcommits',
        releaseRules: releaseRulesForManifest(manifest),
      },
    ],
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    [
      '@semantic-release/exec',
      {
        prepareCmd:
          'node scripts/release/sync-versions.js ${nextRelease.version} && bash scripts/release/package-haxelib.sh dist/reflaxe.elixir.zip',
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: generatedReleaseAssets(manifest, DEFAULT_MANIFEST_PATH, root),
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
      },
    ],
    [
      './scripts/release/verify-release-stages.js',
      {
        manifestPath: 'release/manifest.json',
        packagePath: 'dist/reflaxe.elixir.zip',
      },
    ],
    [
      '@semantic-release/github',
      {
        assets: [
          {
            path: 'dist/reflaxe.elixir.zip',
            name: 'reflaxe.elixir-${nextRelease.version}.zip',
            label: 'Reflaxe-built haxelib package (${nextRelease.gitTag})',
          },
        ],
      },
    ],
  ],
}
