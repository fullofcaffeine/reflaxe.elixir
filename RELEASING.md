# Releasing

This project uses version tags of the form `vX.Y.Z`.

## Preflight Checklist

```bash
npm install
npm test
npm run test:examples
npm run ci:guards
```

## Todo-app Acceptance Gate (Recommended)

Use the non-blocking sentinel (never run `mix phx.server` in the foreground during automated validation):

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 600
```

## Tagging

After commits are merged to `main`:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push --tags
```

Update `CHANGELOG.md`, `package.json`, and `haxelib.json` as appropriate for the release.
