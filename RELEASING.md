# Releasing

This project uses version tags of the form `vX.Y.Z`.

## Preflight Checklist

```bash
npm install
npm test
npm run test:examples
npm run test:examples-elixir
npm run ci:guards
npm run ci:budgets
```

## Todo-app Acceptance Gate (Recommended)

Use the non-blocking sentinel (never run `mix phx.server` in the foreground during automated validation):

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 600
```

## Tagging

### Automated (Preferred)

This repo uses **semantic-release** to publish GitHub Releases using semver:

- Merge commits to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.)
- After CI passes on `main`, the CI workflow runs `semantic-release` (Release job) which:
  - determines the next semver version
  - updates version strings across the repo
  - creates a `vX.Y.Z` tag
  - publishes a GitHub Release (with generated release notes)

Release notes are generated from Conventional Commits and grouped by type (e.g. Features, Bug Fixes, Docs, CI).

### Backfill / Manual Tags

If you already have a tag but no GitHub Release entry exists (historical tags), run the
workflow **Release (Backfill Existing Tag)** and provide the tag (for example `v1.1.5`).
To backfill all tags in one run, set `all_tags=true`.

If you must tag manually (rare), after commits are merged to `main`:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push --tags
```

Then run **Release (Backfill Existing Tag)** for that tag.

Backfill prefers the corresponding `CHANGELOG.md` section for a tag when present; otherwise it falls back to
git-derived notes or GitHub auto notes.
