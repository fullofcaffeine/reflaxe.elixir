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

## Current migration receipt (2026-07-18)

The initial external dependency audit admitted `genes-ts` 1.36.3 at release
commit `c59ecb361fd91418584487c2138bae8d3d3a3961`. Compiling the PhoenixHX
corpus exposed one generated-output quality defect: blank separators before
documented members contained indentation-only lines. That made a clean
generated tree fail `git diff --check` even though the emitted programs ran.

The generic Genes fix is published at:

- repository: `https://github.com/fullofcaffeine/genes-ts`;
- branch: `codex/output-blank-line-whitespace`;
- exact commit: `51dc422c2ec930604dfd928d2a112ead354362e3`;
- base: `genes-ts` 1.36.3 commit
  `c59ecb361fd91418584487c2138bae8d3d3a3961`;
- scope: whitespace-free documentation, enum/switch/value-block layout,
  declaration separators, silent empty-static phases, and Genes-owned raw
  runtime boundaries in classic ESM, strict TypeScript/TSX, and declaration
  output; the generic output-quality regression now rejects every
  whitespace-only generated source line. External Haxelib and Haxe-stdlib
  source-map entries now use stable `haxe://classpath/...` identities instead
  of a consumer machine's package-cache path, while project-owned sources stay
  navigable as relative paths and `-D source_map_content` embeds external
  source text when requested;
- upstream verification: `yarn test:output-quality`, `yarn test:dual-output`,
  `yarn test:genes-ts:sourcemaps`, the focused
  `SKIP_CLASSIC=1 SKIP_TS2HX=1 yarn test:acceptance` lane, and the complete
  `yarn test:ci` lane under Node 20.19.3, including both todo-app browser
  profiles and `ts2hx`;
- downstream replacement condition: move to the exact commit that lands on
  canonical Genes `main`, or to the exact commit of a subsequently admitted
  release containing the fix. This stable-promotion step is tracked by
  `haxe.elixir.codex-aas` and does not block the current experimental lane.

This topic is deliberately based on the admitted release rather than the local
`origin/main` observed at `ff588cff2c48bd6443af20e6f8429423d256fafe`.
During this migration, that newer checkout independently failed its
`dual-output-source-modules` fixture count (17 discovered versus 13 expected)
before the whitespace change was applied. That local observation does not make
a broad claim about upstream release readiness; it only prevents unrelated
unfinished changes from entering this downstream pin.

The known-green PhoenixHX rollback commit before dependency consolidation is
`f0a22cc`. The vendored source is removed only after the exact topic pin passes
all current browser consumers, the strict TSX/React fixture, generated-output
review, path hygiene, and the applicable Phoenix example/runtime gates.

## Rollback

Before changing compiler ownership, commit a known-green repository state.
Record that commit in the migration receipt. A failed migration rolls back the
consumer pin and generated/browser artifacts to that commit; it does not create
an application-specific patch inside Genes or keep two active compiler sources.
