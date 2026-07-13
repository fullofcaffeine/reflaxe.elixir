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
- There is no manual normal-release or tag-moving path.
- The reviewer-gated repair workflow can complete or verify publication for an existing tag only; it
  cannot derive a version, choose a branch, create a tag, or replace mismatched published bytes.

Do not follow older backfill or manual-tag instructions from historical commits. Use the canonical
guide for preflight commands, recovery, consumer verification, host controls, and the stable-major
approval gate.
