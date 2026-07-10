const { generatedReleaseAssets } = require('./scripts/release/sync-versions')

const root = __dirname

module.exports = {
  branches: ['main'],
  plugins: [
    [
      './scripts/release/semantic-release-policy.cjs',
      {
        policyPath: 'release/manifest.json',
        commitAnalyzer: {
          releaseRules: [
            { type: 'perf', release: 'patch' },
            { type: 'revert', release: 'patch' },
          ],
        },
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
        assets: generatedReleaseAssets('release/manifest.json', root),
        message:
          'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
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
