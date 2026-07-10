# Releasing (Semantic Versioning + GitHub Releases)

This repo uses **semantic-release** to publish GitHub Releases using **semantic versioning**.

High level:

- Merge changes to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- When `CI` completes successfully on `main`, the separate **Release** workflow runs automatically
- `semantic-release` determines the next version (if any), creates a `vX.Y.Z` tag, publishes a GitHub Release,
  and updates repo version strings + `CHANGELOG.md`

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

Immutable reachable tags are the source of truth for released versions.
`release/manifest.json` contains only release-line policy and per-major approvals; it does not own a
current version or generated-file inventory. During the release-protocol migration,
`scripts/release/sync-versions.js` remains a compatibility bridge that writes the derived tag version
to these tracked mirrors:

- `package.json` / `package-lock.json`
- `haxelib.json`
- `mix.exs`
- `README.md` version badge
- generated release-posture blocks in `README.md` and `VERSIONING_AND_STABILITY.md`
- `CHANGELOG.md` (generated)

Check for drift without modifying files:

```bash
npm run guard:release-state
```

The bridge rejects unsafe paths, missing or duplicate generated markers, and stable versions without
an approval for that exact major. Semantic-release obtains its transitional release-commit asset
list from the same module through `release.config.js`. The local policy plugin delegates commit
classification to the official semantic-release analyzer and changes only the explicit pre-1.0
breaking rule; its verification hook enforces stable-major approval.

## Staged release verification

Release verification runs at three boundaries:

1. After the official git plugin creates and pushes the release commit, but before semantic-release
   creates a tag, the prepared-state verifier checks committed generated assets, changelog version,
   clean tracked state, and package contents. Failure here prevents tag creation.
2. After semantic-release creates the tag, but before the GitHub plugin publishes, the tag verifier
   checks that the tag targets the prepared commit and that tagged metadata/docs and package contents
   agree.
3. After semantic-release returns, the workflow downloads the GitHub Release asset and verifies the
   published release state, exact asset name, non-empty upload, tagged generated state, and package
   contents. This step receives the exact tag created by that run. If commit analysis produces no new
   version, the workflow records a no-op and does not re-audit an older release as though it had just
   been published.

### Partial-publication recovery

- **Failure before tag creation:** fix the cause and rerun the Release workflow. Do not create a tag
  manually; no public release identity exists yet.
- **Tag exists but the GitHub Release or asset is missing:** do not move or recreate the tag. Check
  out that exact tag in a temporary clone, run `scripts/release/package-haxelib.sh`, verify the zip,
  then create the missing GitHub Release or upload the exact `reflaxe.elixir-X.Y.Z.zip` asset with
  `gh release create` / `gh release upload --clobber` as appropriate.
- **Published metadata is wrong:** treat the release as immutable until the discrepancy is understood.
  Prefer correcting GitHub Release notes/assets against the existing tag. Delete or move a public tag
  only as an explicitly reviewed release revocation.

Finish every recovery with:

```bash
scripts/release/verify-published-package.sh vX.Y.Z
```

Tags created before release policy schema v2, including tags with the earlier generated-state
manifest, can be audited with `ALLOW_LEGACY_RELEASE=1`; this bypasses only tagged policy/generated-
state comparison and is never set by the Release workflow. Package structure and hosted-asset checks
still run.

## Token / permissions notes

The release job uses the built-in GitHub Actions token (`github.token`) with `contents: write`.
This avoids failures caused by stale or under-scoped personal tokens.

If your org/repo policy blocks tag or release publishing with `github.token`, update
`.github/workflows/release.yml` to use a dedicated PAT secret explicitly for that environment.

## Baseline tag guard

The release workflow now fails fast if no semver tag is reachable from current `main` history.
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
