# Releasing (Semantic Versioning + GitHub Releases)

This repo uses **semantic-release** to publish GitHub Releases using **semantic versioning**.

High level:

- Merge changes to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- The final `CI` job on a `main` push releases only after its explicit same-run gates succeed
- `semantic-release` determines the next version (if any), builds the package from that tested commit,
  creates a `vX.Y.Z` tag on the same commit, and publishes a complete immutable GitHub Release

## Same-commit publication boundary

Normal publication is deliberately part of `.github/workflows/ci.yml`, not a later
`workflow_run` workflow. The release job has explicit `needs` edges to compiler tests, the package
smoke, examples, dogfood, the QA sentinel, dependency audit, secret scan, and supporting gates. It
checks out `github.sha` with full history and receives `contents: write` only at the job level.

This means a pull request, fork event, feature-branch push, manual dispatch, failed/cancelled gate,
or unrelated workflow result cannot enter normal publication. The release job does not download CI
artifacts or restore caches: it reconstructs the already-tested package from the exact commit and
the locked dependency graph. The artifact plugin then performs the source/package parity and
byte-reproducibility checks again before a tag or hosted asset is created.

The called Dogfood, Example Compilation, and QA Sentinel workflows remain manually runnable for
diagnosis, but those read-only runs cannot publish. The protected manual workflow is only a repair
path for an existing immutable tag; it cannot select an arbitrary new release commit.

## What triggers a release?

Semantic-release looks at commit messages since the last release:

- `fix:` → patch release (`0.1.2` → `0.1.3`)
- `feat:` → minor release (`0.1.2` → `0.2.0`)
- `feat!:` or `BREAKING CHANGE:` → **minor release while pre-1.0** (`0.2.0` → `0.3.0`)

The version-independent release policy intentionally keeps breaking changes on the minor line while
the project is pre-1.0. A stable major release requires every named requirement plus an approval
record for that major. For major 1, complete applicable Haxe stdlib support is one of those
requirements. Approval is non-releasing, so a subsequent new breaking commit must still authorize
the release.

If there are no release-worthy commits, the workflow runs but produces no new release.

By default, commits like `docs:`, `chore:`, `test:`, `refactor:`, `ci:` do **not** trigger a new version unless they
also include a breaking-change marker.

## Maintainer checklist

1) **Keep main green**

CI is the source of truth; locally you can sanity-check with:

```bash
npm ci
npm audit --audit-level=high --omit=optional
npm run ci:guards
npm test
npm run test:haxe-exunit-stdlib
npm run guard:upstream-unitstd
npm run test:examples
npm run test:examples-elixir
npm run test:haxelib-package
npm run test:release-recovery
npm run package:haxelib
npm run ci:budgets
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --async --deadline 900 -v
```

2) **Merge Conventional Commits**

Use clear, scoped messages (examples):

- `feat(hxx): typecheck slot :let`
- `fix(mix): show full Haxe compiler output on failure`
- `chore(ci): ...`

3) **Let semantic-release do the rest**

Immutable reachable tags are the source of truth for released versions. `release/manifest.json`
contains release-line policy, named release requirements, and per-major approvals. The validator
rejects an approval while any requirement is pending. Tracked `package.json`, `haxelib.json`,
`mix.exs`, and scoped HXML versions are development sentinels, not release mirrors.

The artifact plugin exports the exact tested Git commit to temporary storage, runs that commit's
vendored Reflaxe builder, and injects the derived version, tag, and source SHA only into package
staging. It builds the complete package twice under varied environment settings, requires identical
bytes, validates the ZIP layout and metadata, runs installed-package parity against that exact ZIP,
and emits `dist/reflaxe.elixir.zip.sha256`. Normal publication leaves tracked files unchanged and
does not create a release commit. GitHub Release notes are the current release changelog.

Release notes are generated before packaging from the same Conventional Commits used to choose the
version. The guard suite runs that real generator with representative release and non-release
commits. The artifact plugin also requires at least one non-heading note before doing expensive
package work, so a preset/writer compatibility regression fails before semantic-release creates the
tag. Direct release-tool dependencies stay exact-pinned as one tested compatibility set; do not
upgrade the preset independently just because a newer major exists.

Project scaffolding also respects that split. An installed Haxelib release reads the exact version
injected into its staged `haxelib.json`; Haxe and Mix scaffolds running from a repository checkout
resolve the nearest reachable immutable release tag when they encounter a development sentinel.
They fail clearly when neither identity exists instead of generating a fake `v0.0.0`,
`v0.0.0-development`, or `vlatest` download URL.

## Staged release verification

Release verification runs at four boundaries:

1. Before tag creation, the artifact plugin requires meaningful generated release notes, proves two
   complete builds are byte-identical, validates canonical entries/modes/metadata, smokes the exact
   ZIP, records byte count and SHA-256, and checks that the tracked tree stayed clean. Failure here
   prevents tag creation.
2. After semantic-release creates the tag, but before GitHub upload, the plugin re-validates the
   approved ZIP/checksum, confirms that tracked source was not modified, and requires checked-out
   HEAD plus the local and origin tags to resolve to the tested source SHA.
3. The GitHub publisher creates a draft, uploads both approved assets, and only then publishes it.
   The provenance plugin requires the release tag, complete custom-asset set, uploaded states,
   byte counts, SHA-256 digests, and immutable status to agree with the approved local files.
4. The final consumer check downloads both assets, validates embedded package version/tag/source
   metadata, and verifies GitHub's signed immutable-release attestation for the release and files.
   A no-op does not re-audit an older release as newly published.

### Partial-publication recovery

- **Failure before tag creation:** if the failure was transient, rerun the failed jobs in that same
  `CI` run so the release still targets the same `github.sha`. If source must change, push the fix and
  let the new complete CI graph decide publication. Do not create a tag manually; no public release
  identity exists yet.
- **Tag exists but its GitHub Release is absent or still draft:** run the protected **Repair Existing
  Release** workflow with that exact `vMAJOR.MINOR.PATCH` tag. A required reviewer must approve the
  environment. The workflow checks out `refs/tags/<tag>`, verifies local/origin tag identity,
  rebuilds twice, smokes the exact ZIP, preserves any already-correct draft assets, uploads only
  missing assets, publishes the complete draft, and verifies immutable hosted digests.
- **Published bytes, tag identity, or immutable state are wrong:** treat this as a release incident.
  Repair refuses published mutable releases, unexpected assets, and same-name assets with different
  bytes. Never move/delete the remote tag or reuse the version; ship a corrective version.

Finish every recovery with:

```bash
scripts/release/verify-published-package.sh vX.Y.Z
```

The repair path never invokes semantic-release, analyzes commits, creates a version, or creates,
moves, or deletes a tag. Re-running it after a lost API response is safe: an already-complete
immutable release becomes a read-only verification.

## Consumer verification

Every release publishes exactly two custom assets:

- `reflaxe.elixir-X.Y.Z.zip`
- `reflaxe.elixir-X.Y.Z.zip.sha256`

Consumers can download both from the same immutable release and run `sha256sum --check` on Linux or
`shasum -a 256 --check` on macOS, as shown in the
[installation guide](../01-getting-started/installation.md#verify-the-package).
The sidecar names the versioned ZIP, so a checksum copied from another version fails. GitHub's
immutable-release control prevents the verified asset from being replaced under the same tag.

Maintainer verification is stricter:

```bash
scripts/release/verify-published-package.sh vX.Y.Z
```

That command also checks embedded version/tag/source metadata, exact hosted asset names and sizes,
GitHub's hosted SHA-256 digests, and signed release/asset attestations.

## Repository host controls

The repository enables GitHub immutable releases for all future publications and has an active
`Immutable semantic version tags` ruleset for `refs/tags/v*` that blocks update and deletion. The
`release-repair` environment requires reviewer approval. Audit all three controls with an
administrator-capable token:

```bash
node scripts/release/verify-host-controls.js fullofcaffeine/reflaxe.elixir
```

This is a personal repository, so normal tag creation uses the short-lived same-run
`GITHUB_TOKEN`; there is no separate long-lived release credential. Organization-owned forks with
multiple writers must add a dedicated GitHub App (or equivalent release identity), restrict
version-tag creation to that identity, and keep update/deletion protection. The host verifier fails
closed for an organization-owned repository without that creation restriction.

## Token / permissions notes

The release job uses the built-in GitHub Actions token (`github.token`) with `contents: write`.
This avoids failures caused by stale or under-scoped personal tokens.

If an organization policy blocks `github.token`, use a dedicated GitHub App identity allowed by the
tag ruleset. Keep authority job-scoped and preserve the same-run `needs` graph; do not fall back to
a broad personal token.

## Baseline tag guard

The CI release job fails fast if no semver tag is reachable from current `main` history.
This prevents semantic-release from incorrectly treating the repo as an initial `1.0.0` release.

Quick diagnostic:

```bash
git tag --merged main | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'
```

If this returns nothing, stop publication and investigate the repository history. Baseline creation
is a one-time migration operation, not a recovery action and not part of the repair workflow.

For the predecessor protocol and live reference-rollout evidence, see
[Release Protocol History](../09-history/RELEASE_PROTOCOL_HISTORY.md).
