# Releasing (SemVer + GitHub Releases)

This repo uses **SemVer tags** (`vMAJOR.MINOR.PATCH`) and a GitHub Actions workflow to publish **GitHub Releases**.

## Quick release checklist

1) **Verify main is green locally**

```bash
npm ci
npm run ci:guards
npm test
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --async --deadline 900 -v
```

2) **Bump versions + docs pins**

- `package.json` → `"version": "X.Y.Z"`
- `package-lock.json` → `"version": "X.Y.Z"` (top-level + packages[""])
- `haxelib.json` → `"version": "X.Y.Z"` (+ update `releasenote`)
- `CHANGELOG.md` → add an entry for `X.Y.Z`
- Docs that pin tags (search `#v` / `tag: "v`) → update to the new tag

3) **Commit**

```bash
git add -A
git commit -m "chore(release): vX.Y.Z"
git push origin main
```

4) **Tag + push**

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Pushing the tag triggers `.github/workflows/release.yml`, which creates the GitHub Release and auto-generates release notes.

## Pre-releases (rc/beta)

Use a SemVer pre-release suffix (GitHub will mark these as prereleases automatically):

```bash
git tag v1.2.0-rc.1
git push origin v1.2.0-rc.1
```

## Backfilling releases for existing tags

If tags already exist but the GitHub **Releases** list is empty (or older tags predate the workflow), use the workflow’s manual mode:

1) GitHub → Actions → **Release** → **Run workflow**
2) Provide `tag` (e.g. `v1.1.4`)
3) Keep `skip_verify=true` for historical backfill (or set to false to re-run full verification)

