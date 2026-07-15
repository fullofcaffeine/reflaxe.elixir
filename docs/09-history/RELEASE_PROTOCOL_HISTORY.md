# Release Protocol History

This note preserves why Reflaxe.Elixir changed release architecture. It is historical evidence, not
an operational runbook. Use [Releasing](../10-contributing/RELEASING.md) for current procedures and
[Versioning & Stability](../06-guides/VERSIONING_AND_STABILITY.md) for current policy.

## Predecessor: generated release commits

The completed `haxe.elixir.codex-m81` epic established the first coherent release model. It replaced
contradictory version files with a structured manifest, generated tracked package/version/changelog
state, prevented unapproved stable releases, and verified a prepared package and GitHub Release.

Its live happy-path proof was `v0.14.23`:

| Identity | Value |
| --- | --- |
| Tested source commit | `212be207e99c925c1aa897ff3f03a2cfe8b731ed` (`fix(release): verify staged release state`) |
| Generated release commit | `9b256d7ef6e8b78d127bf25f8176df72c283385a` (`chore(release): 0.14.23 [skip ci]`) |
| `v0.14.23` tag target | `9b256d7ef6e8b78d127bf25f8176df72c283385a` |
| Parent relationship | The generated release commit's parent is the tested source commit |
| Tracking epic | `haxe.elixir.codex-m81` |

That release succeeded and remains valid public history. Existing `v0.14.x` tags were not rewritten
or deleted during the migration.

The tradeoff was structural: the public tag identified a newly generated commit that CI had not
tested as its source commit. Current version truth also had to remain synchronized across generated
tracked files. More verification made that design internally consistent, but it could not make the
tag identify the unchanged tested commit.

## Current reference: tested-commit publication

The `haxe.elixir.codex-83h` epic simplified the model around one identity:

1. The complete `main` CI graph tests source commit `S`.
2. The final job in that same run derives version `V` from protected reachable tags and Conventional
   Commits.
3. Reflaxe builds the package twice from `S`, injecting `V`, `vV`, and `S` only into temporary
   staging; the two ZIPs must be byte-identical.
4. `vV` points directly to `S`.
5. GitHub publishes the approved ZIP and checksum through draft/upload/publish, then locks the
   Release as immutable.
6. Post-publication verification binds HEAD, local/origin tag, embedded metadata, hosted names,
   bytes, SHA-256 digests, and GitHub attestations to the same `S` and `V`.

Normal publication never changes tracked files or creates a release commit. A protected manual lane
can only finish publication for an already-existing version tag; it cannot derive a version, select
a branch or SHA, create or move a tag, or replace mismatched bytes.

The first live immutable release under this protocol is recorded below by the immediately following
documentation commit. Keeping evidence here avoids turning operational docs into generated
current-version prose.

## Live reference evidence

`v0.14.26` is the first reference release:

| Identity | Verified value |
| --- | --- |
| Source commit `S` | `0b82ba82180cc51b4adc1b2ce825f7feab391ab7` (`fix(release): activate immutable publication protocol`) |
| Full CI run | `29139653073` |
| Release job | `86512689271` (`Release exact CI-tested commit`) |
| Version/tag | `0.14.26` / `v0.14.26` |
| GitHub Release | `https://github.com/fullofcaffeine/reflaxe.elixir/releases/tag/v0.14.26` |
| ZIP | `reflaxe.elixir-0.14.26.zip`, 2,502,008 bytes, SHA-256 `4d896af5d45d1cc5730aa4fd6aae8fc08b1f09aacf447844fa7377eec10a4280` |
| Checksum sidecar | `reflaxe.elixir-0.14.26.zip.sha256`, 93 bytes, SHA-256 `005e3a663ccbf6571033080a12e7425791b89e82c59a2bcbac1000005372e9aa` |
| Hosted state | Both assets `uploaded`; release published, non-prerelease, and immutable |
| Host controls | Immutable releases enabled; active ruleset `18796523` blocks `v*` update/deletion; `release-repair` requires review |

After fetching the tag, checked-out HEAD, `v0.14.26^{}`, and `origin`'s
`refs/tags/v0.14.26` all resolved to `S`. The published-package verifier also checked the ZIP's
embedded version, tag, and source metadata plus GitHub's signed release/asset attestations. A fresh
consumer smoke downloaded both assets, reported the ZIP checksum `OK`, installed it through Lix,
generated a Phoenix app, and compiled its Haxe and Elixir sources.

The published GitHub Release body contains its generated version heading but no commit entries. The
release-notes generator and Conventional Commits preset were individually valid packages but used
incompatible writer-template contracts, and the old release test checked configuration rather than
rendered output. This is a presentation defect, not an artifact or compiler defect: the tag,
package, checksum, source identity, and signed attestations above remain valid. Immutability correctly
prevents silently rewriting that public record, so a normal corrective patch release restores notes.
Publication now renders representative commits in tests and rejects heading-only notes before the
package build and tag boundary.

The commit immediately following `v0.14.26` is documentation/test evidence only. Its exact CI and
semantic-release no-op result passed in CI run `29158403187`; CodeQL run `29158403127` also passed.

## Corrective release-note evidence

`v0.14.27` proves the release-note correction without weakening immutability or changing compiler
behavior:

| Identity | Verified value |
| --- | --- |
| Source commit `S` | `4a15d2a552235ef79578112633f400b2cfe7e686` (`fix(release): restore complete release notes`) |
| Full CI run | `29160260486`, 31/31 jobs successful |
| CodeQL run | `29160260396`, successful |
| Release job | `86566689945` (`Release exact CI-tested commit`) |
| Version/tag | `0.14.27` / `v0.14.27`; local tag, origin tag, and checked-out HEAD all resolved to `S` |
| GitHub Release | `https://github.com/fullofcaffeine/reflaxe.elixir/releases/tag/v0.14.27`; published, non-prerelease, and immutable |
| Rendered notes | `Bug Fixes` contains the scoped release entry and link to `S` |
| ZIP | `reflaxe.elixir-0.14.27.zip`, 2,502,009 bytes, SHA-256 `6b052fd9f002590f9f035d7b1c31e634537cbca75e96fa426735800dcbef52c9` |
| Checksum sidecar | `reflaxe.elixir-0.14.27.zip.sha256`, 93 bytes, SHA-256 `2937a3a76e2a8278c647df635fae643c594cc068d66a66b56ad3c4c17bdcf5e0` |

Both assets reported `uploaded`, and the published-package verifier accepted their embedded
version/tag/source metadata plus GitHub's signed immutable-release attestations. This shows the
appropriate recovery for an immutable release-note defect: preserve the valid prior release, fix
and test the generator compatibility contract, then publish a new patch version from a fully tested
commit.
