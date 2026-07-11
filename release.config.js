/**
 * Semantic-release derives V from immutable tags and Conventional Commits, builds the exact
 * Reflaxe package from tested source commit S, tags S directly, and publishes those approved bytes.
 * Normal publication never writes tracked metadata or creates a release commit.
 */
module.exports = {
  branches: ['main'],
  tagFormat: 'v${version}',
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
    [
      '@semantic-release/release-notes-generator',
      { preset: 'conventionalcommits' },
    ],
    './scripts/release/haxelib-artifact-plugin.cjs',
    [
      '@semantic-release/github',
      {
        successComment: false,
        failComment: false,
        releasedLabels: false,
        assets: [
          {
            path: 'dist/reflaxe.elixir.zip',
            name: 'reflaxe.elixir-${nextRelease.version}.zip',
            label: 'Reflaxe.Elixir haxelib package (${nextRelease.gitTag})',
          },
          {
            path: 'dist/reflaxe.elixir.zip.sha256',
            name: 'reflaxe.elixir-${nextRelease.version}.zip.sha256',
            label: 'SHA-256 checksum',
          },
        ],
      },
    ],
    './scripts/release/published-verifier-plugin.cjs',
  ],
}
