# Releasing (Semantic Versioning + GitHub Releases)

This repo uses **semantic-release** to publish GitHub Releases using **semantic versioning**.

High level:

- Merge changes to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- The final `CI` job on a `main` push releases only after its explicit same-run gates succeed
- `semantic-release` determines the next version (if any), builds the package from that tested commit,
  creates a `vX.Y.Z` tag on the same commit, and publishes a GitHub Release

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
diagnosis, but those read-only runs cannot publish. Manual release backfill is a separate repair path
for an existing immutable tag; it is not a way to select an arbitrary new release commit.

## What triggers a release?

Semantic-release looks at commit messages since the last release:

- `fix:` → patch release (`0.1.2` → `0.1.3`)
- `feat:` → minor release (`0.1.2` → `0.2.0`)
- `feat!:` or `BREAKING CHANGE:` → **minor release while pre-1.0** (`0.2.0` → `0.3.0`)

The version-independent release policy intentionally keeps breaking changes on the minor line while
the project is pre-1.0. Stable graduation requires an approval record for the target major; that
approval is non-releasing, so a subsequent new breaking commit must still authorize the release.

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
npm run test:examples
npm run test:examples-elixir
npm run test:haxelib-package
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
contains only release-line policy and per-major approvals. Tracked `package.json`, `haxelib.json`,
`mix.exs`, and scoped HXML versions are development sentinels, not release mirrors.

The artifact plugin exports the exact tested Git commit to temporary storage, runs that commit's
vendored Reflaxe builder, and injects the derived version, tag, and source SHA only into package
staging. It builds the complete package twice under varied environment settings, requires identical
bytes, validates the ZIP layout and metadata, runs installed-package parity against that exact ZIP,
and emits `dist/reflaxe.elixir.zip.sha256`. Normal publication leaves tracked files unchanged and
does not create a release commit. GitHub Release notes are the current release changelog.

Project scaffolding also respects that split. An installed Haxelib release reads the exact version
injected into its staged `haxelib.json`; Haxe and Mix scaffolds running from a repository checkout
resolve the nearest reachable immutable release tag when they encounter a development sentinel.
They fail clearly when neither identity exists instead of generating a fake `v0.0.0`,
`v0.0.0-development`, or `vlatest` download URL.

## Staged release verification

Release verification runs at three boundaries:

1. Before tag creation, the artifact plugin proves two complete builds are byte-identical, validates
   canonical entries/modes/metadata, smokes the exact ZIP, records byte count and SHA-256, and checks
   that the tracked tree stayed clean. Failure here prevents tag creation.
2. After semantic-release creates the tag, but before GitHub upload, the plugin re-validates the
   approved ZIP and checksum and confirms that tracked source was not modified.
3. After semantic-release returns, the workflow downloads the GitHub Release asset and verifies the
   exact asset, checksum, staged package metadata, and source SHA. This step receives the exact tag
   created by that run. A no-op does not re-audit an older release as newly published.

### Partial-publication recovery

- **Failure before tag creation:** if the failure was transient, rerun the failed jobs in that same
  `CI` run so the release still targets the same `github.sha`. If source must change, push the fix and
  let the new complete CI graph decide publication. Do not create a tag manually; no public release
  identity exists yet.
- **Tag exists but the GitHub Release or asset is missing:** do not move or recreate the tag. Check
  out that exact tag in a temporary clone, then rebuild with the release identity explicitly:

  ```bash
  tag=vX.Y.Z
  version=${tag#v}
  source_sha=$(git rev-parse "${tag}^{commit}")
  scripts/release/package-haxelib.sh dist/reflaxe.elixir.zip "$version" "$tag" "$source_sha"
  archive="reflaxe.elixir-${version}.zip"
  mv dist/reflaxe.elixir.zip "dist/${archive}"
  node scripts/release/verify-release-artifact.js \
    --zip "dist/${archive}" --version "$version" --tag "$tag" --source-sha "$source_sha"
  hash=$(node -e 'const c=require("crypto"),f=require("fs");process.stdout.write(c.createHash("sha256").update(f.readFileSync(process.argv[1])).digest("hex"))' "dist/${archive}")
  printf '%s  %s\n' "$hash" "$archive" > "dist/${archive}.sha256"
  ```

  Compare the rebuilt SHA-256 with the release job record before creating the missing GitHub Release
  or uploading the exact `reflaxe.elixir-X.Y.Z.zip` and checksum assets. Never rebuild with the
  script defaults for recovery: those intentionally produce development metadata.
- **Published metadata is wrong:** treat the release as immutable until the discrepancy is understood.
  Prefer correcting GitHub Release notes/assets against the existing tag. Delete or move a public tag
  only as an explicitly reviewed release revocation.

Finish every recovery with:

```bash
scripts/release/verify-published-package.sh vX.Y.Z
```

Tags created before package provenance/checksum metadata can be audited with
`ALLOW_LEGACY_RELEASE=1`; this keeps legacy package-structure checks explicit and is never set by the
normal CI release job.

## Token / permissions notes

The release job uses the built-in GitHub Actions token (`github.token`) with `contents: write`.
This avoids failures caused by stale or under-scoped personal tokens.

If your org/repo policy blocks tag or release publishing with `github.token`, update
the `release` job in `.github/workflows/ci.yml` to use a dedicated PAT secret explicitly for that
environment. Keep that permission job-scoped and preserve the same-run `needs` graph.

## Baseline tag guard

The CI release job fails fast if no semver tag is reachable from current `main` history.
This prevents semantic-release from incorrectly treating the repo as an initial `1.0.0` release.

Quick diagnostic:

```bash
git tag --merged main | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'
```

If this returns nothing, create and push a baseline tag on a commit in current `main` ancestry:

```bash
git tag -a v0.1.0 <commit-on-main-history> -m "Baseline release tag v0.1.0"
git push origin v0.1.0
```

## Backfilling releases for existing tags

If tags already exist but the GitHub **Releases** list is empty (or older tags predate the workflow),
run the workflow **Release (Backfill Existing Tag)** and provide an existing tag (for example
`v0.14.23`).

If you want to backfill *all* semver tags in one run, use the same workflow with `all_tags=true`.

Notes:

- Backfill prefers the corresponding `CHANGELOG.md` section for a tag (curated, human-readable notes).
- If a changelog section is missing, it generates “semantic-release style” notes from git history (Conventional Commits).
- If notes generation fails for a tag, it falls back to GitHub auto-generated release notes.
- To update existing releases, run backfill with `overwrite_existing=true`.
