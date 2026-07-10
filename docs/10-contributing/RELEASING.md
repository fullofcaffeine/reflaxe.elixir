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

The current release manifest intentionally keeps breaking changes on the minor line while the
project is pre-1.0. Stable graduation changes the manifest policy only after its evidence gate is
approved; semantic-release then derives major breaking releases from that policy.

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

Version strings and current-status blocks are updated in one validated generation pass via
`scripts/release/sync-versions.js`, using `release/manifest.json` as the source of truth, including:

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

The generator rejects unsafe paths, missing or duplicate generated markers, and `1.x` versions that
do not have an approved stable-graduation record. Semantic-release obtains its release-commit asset
list from the same generator through `release.config.js` instead of maintaining another list in
`package.json`. The JavaScript config still uses the official semantic-release analyzer and git
plugins; local code only supplies validated rules and assets.

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
run the workflow **Release (Backfill Existing Tag)** and provide the tag (for example `v1.1.5`).

If you want to backfill *all* semver tags in one run, use the same workflow with `all_tags=true`.

Notes:

- Backfill prefers the corresponding `CHANGELOG.md` section for a tag (curated, human-readable notes).
- If a changelog section is missing, it generates “semantic-release style” notes from git history (Conventional Commits).
- If notes generation fails for a tag, it falls back to GitHub auto-generated release notes.
- To update existing releases, run backfill with `overwrite_existing=true`.
