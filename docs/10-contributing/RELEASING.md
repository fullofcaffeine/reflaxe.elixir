# Releasing (Semantic Versioning + GitHub Releases)

This repo uses **semantic-release** to publish GitHub Releases using **semantic versioning**.

High level:

- Merge changes to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- When `CI` completes successfully on `main`, the `Release` workflow runs `semantic-release`
- `semantic-release` determines the next version, creates a `vX.Y.Z` tag, publishes a GitHub Release,
  and updates repo version strings + `CHANGELOG.md`

## What triggers a release?

Semantic-release looks at commit messages since the last release:

- `fix:` → patch release (`1.1.5` → `1.1.6`)
- `feat:` → minor release (`1.1.5` → `1.2.0`)
- `feat!:` or `BREAKING CHANGE:` → major release (`1.x` → `2.0.0`)

If there are no release-worthy commits, the workflow runs but produces no new release.

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

## Backfilling releases for existing tags

If tags already exist but the GitHub **Releases** list is empty (or older tags predate the workflow),
run the workflow **Release (Backfill Existing Tag)** and provide the tag (for example `v1.1.5`).

If you want to backfill *all* semver tags in one run, use the same workflow with `all_tags=true`.

Notes:

- Backfill generates “semantic-release style” notes from git history (Conventional Commits) for each tag.
- If notes generation fails for a tag, it falls back to GitHub auto-generated release notes.
- To update existing releases, run backfill with `overwrite_existing=true`.
