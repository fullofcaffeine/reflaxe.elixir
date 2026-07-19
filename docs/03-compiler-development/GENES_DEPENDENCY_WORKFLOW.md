# Genes Dependency and Upstream-Fix Workflow

PhoenixHX uses `genes-ts` for Haxe-authored browser code. The compiler can emit
the existing classic split ESM JavaScript profile and the strict
TypeScript/TSX profile used by Haxe-authored React components. Vite or the
application's selected JavaScript tooling remains the bundler; Genes is a
source compiler, not a second bundler.

This document separates four things that are easy to conflate:

1. the immutable Genes revision consumed by this repository and CI;
2. the local `$GENES_CHECKOUT` authority checkout used to investigate compiler work;
3. an isolated Git worktree used to implement one generic change; and
4. a remote branch or fork used to share that change before it lands.

## Committed dependency rule

Committed builds resolve one exact `genes-ts` revision through Lix. They must
not depend on `$GENES_CHECKOUT`, another worktree path, a moving branch, `haxelib dev`,
or an unpushed commit.

A scoped Lix file records the repository and exact commit, for example:

```hxml
# @install: lix --silent download "gh://github.com/fullofcaffeine/genes-ts#<exact-sha>" into genes-ts/<version>/github/<exact-sha>
```

The full generated Lix file also records the admitted version, classpath,
dependencies, and Genes parameters. The SHA—not a branch label—is the build
identity. Release evidence may additionally record the tag, Git tree, release
artifact URL, and artifact digest.

`-lib genes` may remain temporarily as a compatibility alias while existing
PhoenixHX projects migrate, but the alias must delegate to the same pinned
`genes-ts` source. It must not preserve a second compiler tree.

## Local development with the Genes authority checkout

The sibling checkout is useful because it contains the full compiler history,
tests, and contributor tooling. It is not a consumer dependency. A developer
may point an uncommitted Lix development override at that checkout or at an
isolated worktree:

```bash
export GENES_CHECKOUT="<local genes-ts checkout>"
export GENES_WORKTREE="<local genes-ts topic worktree>"
npx lix dev genes-ts "$GENES_CHECKOUT"
# or, while developing one isolated change
npx lix dev genes-ts "$GENES_WORKTREE"
```

That command changes the local scoped-library resolution. Do not commit the
resulting development-path HXML. Restore the repository's exact pin before
running clean-install, package, release, or path-hygiene gates.

## Worktree versus fork

A worktree and a fork solve different problems:

- A **worktree** is another local directory backed by the same Git repository.
  It isolates a clean topic branch from a busy or dirty authority checkout.
- A **fork** is another remote repository. It provides remote ownership,
  permissions, and a place for other machines and CI to fetch commits.

When contributors can push feature branches to the canonical Genes repository,
an extra fork is unnecessary. A worktree plus a pushed topic branch is enough.
Use a private/project-owned fork only when repository permissions, visibility,
or ownership require it.

Create a topic worktree from a known clean canonical base, not from whatever
files happen to be present in the sibling working tree:

```bash
git -C "$GENES_CHECKOUT" fetch origin
git -C "$GENES_CHECKOUT" worktree add "$GENES_WORKTREE" \
  -b <topic-branch> origin/main
```

Follow the Genes repository's own instructions inside the worktree.

Normally that base is `origin/main`. A temporary downstream admission fix may
instead be based on the exact currently admitted release commit when newer
canonical work is independently failing the downstream compatibility matrix.
That exception must be recorded in the migration receipt, must contain only the
generic fix, and must still be replaced by the eventual canonical merge or
release commit. It is not permission to maintain a permanent release fork.

## Generic fix workflow

If PhoenixHX exposes a Genes defect or missing capability:

1. Reduce it to a Genes fixture containing no PhoenixHX, LiveReact, application,
   route, or component-specific names.
2. Create an isolated Genes worktree and implement the smallest generic fix.
3. Test both affected output profiles. A TypeScript/TSX fix must not regress
   classic ESM; a classic fix must not silently weaken strict TypeScript.
4. Run the complete Genes gates required by that repository.
5. Commit the change and push the topic branch to the canonical repository or
   an authorized fork. The commit must be fetchable by CI.
6. Open the Genes pull request when authorized. The PR belongs to Genes and
   must explain the generic language/compiler behavior, not PhoenixHX product
   policy.
7. If PhoenixHX must consume the fix before merge, pin the exact pushed topic
   commit temporarily and record its repository, branch, SHA, owner, PR, and
   replacement condition. This is an experimental integration pin, not a
   stable release dependency.
8. After merge, replace the topic-branch SHA with the exact commit that
   actually landed on canonical `main`:
   - for a squash merge, use the new squash commit;
   - for a merge commit, use the merge commit;
   - do not retain the pre-merge topic SHA merely because its tree was similar.
9. When a release is admitted, advance the pin to the exact commit identified
   by that release and record the release artifact evidence.

This sequence makes every intermediate build reproducible while ensuring the
long-lived dependency belongs to canonical Genes history.

## Downstream admission gates

Removing or upgrading the previous compiler source requires evidence, not a
name or version comparison. For the vendored-to-`genes-ts` migration, map every
local behavior to the selected Genes implementation and test:

- classic split ESM module and import behavior;
- async/await and exception/finally semantics;
- inline HXX/JSX lowering;
- public/library-root retention and DCE;
- exact package-import identity and side-effect imports;
- emitted names and native-accessor policy;
- source maps and deterministic output;
- every current PhoenixHX Genes-backed example;
- strict TypeScript/TSX React authoring, exact props/events, Vite consumption,
  and browser behavior;
- source-checkout and installed-package resolution.

TypeScript compilation is necessary but not sufficient. Runtime behavior,
module ABI, source maps, and clean package installation remain separate gates.
The old source remains available until the matrix passes and the migration has
an explicit rollback commit.

## Historical consolidation receipt (2026-07-18)

PhoenixHX now consumes the reviewed canonical Genes release rather than an
intermediate development revision:

- repository: `https://github.com/fullofcaffeine/genes-ts`;
- release: `v1.36.7`;
- exact release commit:
  `25a5e3015f8b0f0e4447b8fd0590124548f132da`;
- merged pull request: `fullofcaffeine/genes-ts#5`;
- merge commit: `d2e881c7c3b5352399f16bc4216dd0b8c0fb18ff`;
- reviewed source-map commits:
  `20e2bd0bf61e00cbf6da408f1581155adf0a2102` and
  `184b45de99635ba6dac281b1b7462d9238f936af`.

The release keeps project-owned Haxe files as useful relative paths in source
maps. Files supplied by Genes, Haxelib packages, or the Haxe standard library
use stable `haxe://classpath/...` names instead of exposing one developer's
package-cache path. When classpaths overlap, every physical source still gets a
different deterministic name. The same release also contains the earlier
generated-output cleanup that prevents indentation-only blank lines.

Upstream evidence is tied to the canonical history, not to a local checkout:

- the pull request's focused source-map, output-quality, transaction,
  dual-profile, snapshot, and version gates passed;
- Codex reviewed the overlap correction on its exact final head and reported no
  remaining major issue;
- canonical `main` CI run `29650160563` passed classic JS on stable and
  next-LTS Node, strict TypeScript plus todo-app E2E, ts2hx, declaration and
  library profiles, Haxe-preview probes, secrets, and vulnerability checks;
- release run `29650589810` reran the full `yarn test:ci` gate before publishing
  `v1.36.7`.

Downstream admission also starts from clean dependency state. Lix resolved the
exact release commit into a disposable empty cache, the Haxe-owned scaffold
contract regenerated without drift, all 152 scaffold migration tests passed,
the strict TSX and classic ESM fixtures produced the same runtime transcript
with portable source maps, and the complete example corpus matched its
checked-in output. The complete downstream `npm test` gate also passed: all 404
generated Elixir trees parsed, all 305 ExUnit tests passed, and the runtime and
generated-output checks stayed green. A clean todo-app asset build, Phoenix
readiness probe, and all five bounded Playwright smoke scenarios passed as
well. The exact-commit Haxelib package smoke then proved source/package output
parity and compiled an installed-package Phoenix fixture. Hosted exact-head CI
remains the final authority before this downstream change is merged.

The known-green PhoenixHX rollback commit before dependency consolidation is
`f0a22cc`. The repository keeps one external Genes source: the legacy
`-lib genes` name is only an alias for the same immutable `genes-ts` release.

## Current candidate admission (2026-07-19)

Implementation-time verification found that the canonical upstream release had
advanced beyond the planning-time v1.36.8 reference. The candidate dependency is:

- repository: `https://github.com/fullofcaffeine/genes-ts`;
- release: [`v1.37.0`](https://github.com/fullofcaffeine/genes-ts/releases/tag/v1.37.0);
- exact release commit:
  `107491cb115ba7abd5628a1f3bcb338aa8cf2685`.

This release makes React HXX prop contracts part of Haxe type checking. The
downstream negative fixture now requires `GTS-HXX-PROP-002` when an `Int` is
passed to a `String` prop; it no longer relies on a TypeScript-only
`@ts-expect-error`. For the same valid Haxe React source, v1.37.0 emitted
byte-identical TypeScript/TSX and classic ESM modules to v1.36.7. Both profiles
rendered the same React HTML, and both source maps retained portable resolved
source identities.

The local downstream matrix passed the complete example compile, expected-output,
warnings-as-errors, and runtime lanes; all 305 fast Mix tests; the example 12
TypeScript, React, Vite, binding, and two-scenario browser canary; and the
todo-app five-scenario browser smoke. The package-smoke command also remained
green against the previously committed package baseline. Final admission still
requires rerunning package smoke from the commit that contains this exact pin
and obtaining green exact-head hosted CI; local source-checkout evidence alone
does not establish that release gate.

## Rollback

Before changing compiler ownership, commit a known-green repository state.
Record that commit in the migration receipt. A failed migration rolls back the
consumer pin and generated/browser artifacts to that commit; it does not create
an application-specific patch inside Genes or keep two active compiler sources.
