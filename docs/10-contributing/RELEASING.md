# Releasing (Semantic Versioning + GitHub Releases)

This repo uses **semantic-release** to publish GitHub Releases using **semantic versioning**.

High level:

- Merge changes to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- When `CI` completes successfully on `main`, the separate **Release** workflow runs automatically
- `semantic-release` determines the next version (if any), creates a `vX.Y.Z` tag, publishes a GitHub Release,
  and updates repo version strings + `CHANGELOG.md`

## What triggers a release?

Semantic-release looks at commit messages since the last release:

- `fix:` → patch release (`1.1.5` → `1.1.6`)
- `feat:` → minor release (`1.1.5` → `1.2.0`)
- `feat!:` or `BREAKING CHANGE:` → major release (`1.x` → `2.0.0`)

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
npm run ci:budgets
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --async --deadline 900 -v
```

2) **Merge Conventional Commits**

Use clear, scoped messages (examples):

- `feat(hxx): typecheck slot :let`
- `fix(mix): show full Haxe compiler output on failure`
- `chore(ci): ...`

3) **Let semantic-release do the rest**

Version strings are updated automatically via `scripts/release/sync-versions.js`, including:

- `package.json` / `package-lock.json`
- `haxelib.json`
- `mix.exs`
- `README.md` version badge
- `CHANGELOG.md` (generated)

## Token / permissions notes

The release job uses the GitHub Actions token by default. If your repo has hardened permissions
and semantic-release fails to push tags or publish releases, add a `RELEASE_TOKEN` secret (PAT or fine‑grained token)
with `contents: write` access and the workflow will use it automatically.

## Backfilling releases for existing tags

If tags already exist but the GitHub **Releases** list is empty (or older tags predate the workflow),
run the workflow **Release (Backfill Existing Tag)** and provide the tag (for example `v1.1.5`).

If you want to backfill *all* semver tags in one run, use the same workflow with `all_tags=true`.

Notes:

- Backfill prefers the corresponding `CHANGELOG.md` section for a tag (curated, human-readable notes).
- If a changelog section is missing, it generates “semantic-release style” notes from git history (Conventional Commits).
- If notes generation fails for a tag, it falls back to GitHub auto-generated release notes.
- To update existing releases, run backfill with `overwrite_existing=true`.
