# Releasing

The canonical release process is [docs/10-contributing/RELEASING.md](docs/10-contributing/RELEASING.md).

In short:

- Conventional Commits on `main` drive semantic-release.
- Normal publication is the final job of the same CI run and targets only that run's exact
  `github.sha`.
- Compiler, package, examples, dogfood, QA, minimum-toolchain, security, and release-policy gates must
  all pass before publication.
- The package is built twice for byte reproducibility, checked for source/package parity, and
  published with a checksum under a protected immutable version tag.
- There is no manual normal-release, separate repair workflow, deployment environment, or tag-moving
  path.
- If publication is interrupted, rerun the failed `Release exact CI-tested commit` job. The same job
  can complete or verify only a strict version tag pointing at its own tested commit; it cannot pick
  an arbitrary branch/tag/SHA or replace mismatched published bytes.

Do not follow older backfill or manual-tag instructions from historical commits. Use the canonical
guide for preflight commands, recovery, consumer verification, host controls, and the stable-major
approval gate.
