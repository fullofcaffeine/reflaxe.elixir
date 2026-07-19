# PRD: Audit and Absorb Reflaxe.Elixir’s Vendored Genes Improvements into `genes-ts`

**Document type:** implementation PRD, migration specification, and verification contract
**Target repository:** `fullofcaffeine/genes-ts`
**Working directory:** the `genes` checkout (the sibling `../genes` when viewed from `haxe.elixir.codex`)
**Downstream evidence repository:** `../haxe.elixir.codex` when viewed from the Genes checkout
**Original Genes reference:** `../genes-vanilla` when viewed from the Genes checkout
**Related downstream Bead:** `haxe.elixir.codex-m52`
**Date:** 2026-07-16

## 0. Instructions to the Genes Agent

Start in the `genes` checkout. On this machine it is the sibling named `genes` beside `haxe.elixir.codex`. Once there, use these paths:

```text
Current genes-ts repository:
.

Reflaxe.Elixir downstream repository:
../haxe.elixir.codex

Vendored modified Genes source:
../haxe.elixir.codex/vendor/genes

Reflaxe.Elixir's hermetic Genes library descriptor:
../haxe.elixir.codex/haxe_libraries/genes.hxml

Original benmerckx/genes reference:
../genes-vanilla
```

Read and follow `AGENTS.md` in the `genes-ts` repository before mutating anything. Use `bd` for issue tracking; do not hand-edit `.beads/issues.jsonl`.

Do not delete the untracked audit bundles currently present in `../genes` or `../genes-vanilla`. Do not run `git clean -fd`.

This task is authorized to modify `../genes`, add tests, commit the resulting work, and follow that repository’s normal push/CI workflow. It is not authorization to modify or remove `../haxe.elixir.codex/vendor/genes`; downstream adoption is owned separately.

---

# 1. Objective

Audit every substantive difference between Reflaxe.Elixir’s vendored Genes `v0.4.14` derivative and current `genes-ts`, then absorb every still-useful generic improvement into `genes-ts`.

The desired result is not a textual port of the old vendor. It is a semantic consolidation:

- determine why each downstream change was introduced;
- identify whether current `genes-ts` already solves it;
- preserve current `genes-ts` architecture when it is superior;
- add missing regression coverage where behavior is already supported;
- implement genuinely missing generic improvements;
- reject downstream-only, obsolete, formatting-only, or unsound changes explicitly;
- keep classic Genes JavaScript and TypeScript output modes green;
- provide a precise adoption handoff for Reflaxe.Elixir.

The final `genes-ts` result must benefit arbitrary Haxe applications. It must not know about PhoenixHX, Reflaxe.Elixir paths, application modules, or downstream product conventions.

---

# 2. Repository and Revision Evidence

## 2.1 Reflaxe.Elixir vendor snapshot

Audit against the downstream repository snapshot:

```text
Repository: ../haxe.elixir.codex
Snapshot:   1ce84dcfef6c1633e56cbc8e266984519181d84f
Vendor:     vendor/genes
Declared version: genes 0.4.14
```

Before relying on that snapshot, verify it still exists:

```bash
git -C ../haxe.elixir.codex rev-parse 1ce84dcfef6c1633e56cbc8e266984519181d84f
git -C ../haxe.elixir.codex status --short
```

Do not overwrite any newer downstream work.

## 2.2 Original Genes baseline

The original upstream comparison point is:

```text
Repository: ../genes-vanilla
Tag:        v0.4.14
Commit:     a5dccf2797a829ea0a186944b0a8601ed6823ed4
```

`../genes-vanilla` is read-only reference evidence. Do not patch it.

## 2.3 Current genes-ts state

At handoff time, the local `../genes` checkout was:

```text
HEAD:        1e7e323fdbda4c5b93689355294bd978e9170725
origin/main: 1e7e323fdbda4c5b93689355294bd978e9170725
description: v1.32.0-8-g1e7e323
```

A newer `v1.33.0` release was observed at:

```text
7999b7cff09f78ebb8e09c3db6e221beb141b67b
```

Refresh before starting. Do not assume the handoff-time revision is still current:

```bash
git fetch origin --tags
git status --short
git log --oneline --decorate -10
git tag --sort=-version:refname | head
```

Follow the repository’s rebase/fast-forward policy. Never discard the existing untracked audit artifacts.

---

# 3. Product Decision

The target architecture is current `genes-ts`, not the old vendored compiler.

For each downstream delta, assign exactly one disposition:

1. **Already supported:** current `genes-ts` preserves the behavior with sufficient tests.
2. **Supported but under-tested:** implementation exists; add a reduced generic regression.
3. **Superseded:** current `genes-ts` has a better architecture; prove semantic equivalence and do not port the old mechanism.
4. **Missing and valid:** implement it generically in `genes-ts`.
5. **Downstream-only:** leave it in downstream code or downstream packaging.
6. **Obsolete or unsound:** reject it with evidence.
7. **Formatting-only:** preserve only if it enforces a documented output-quality invariant.

Do not declare a delta absorbed merely because similar terminology appears in current source. Prove the relevant generated output and runtime behavior.

---

# 4. Beads Planning Requirements

Before implementation:

```bash
bd onboard
bd list
bd ready
bd dep add --help
```

Find whether an existing issue already owns this audit. If not, create a parent issue titled in substance:

```text
Audit and absorb Reflaxe.Elixir vendored Genes improvements
```

Recommended child slices:

1. Audit and classify downstream vendor deltas.
2. Close literal-emission, source-map, and writer typing gaps.
3. Review runtime registry and bound-method typing.
4. Prove async/await semantic supersession.
5. Run dual-mode, downstream, and release-readiness verification.

Do not invent issue IDs. Capture IDs immediately after creation. Use `bd` for all issue and dependency mutations.

Each implementation slice must be committed separately when it represents an independently verified fix, following `AGENTS.md`.

---

# 5. Required Three-Way Audit

Do not compare only `vendor/genes` against current `genes-ts`; the repositories have diverged too much for a raw diff to explain intent.

Perform a three-way audit:

```text
Original v0.4.14
      │
      ├── Reflaxe.Elixir vendor deltas
      │
      └── modern genes-ts evolution
```

A useful vendor-delta command from `../genes` is:

```bash
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git -C ../genes-vanilla archive v0.4.14 | tar -xf - -C "$tmpdir"

git diff --no-index --stat \
  "$tmpdir/src/genes" \
  ../haxe.elixir.codex/vendor/genes/src/genes

git diff --no-index \
  "$tmpdir/src/genes" \
  ../haxe.elixir.codex/vendor/genes/src/genes
```

Also inspect the originating downstream commits:

```bash
git -C ../haxe.elixir.codex show ab4ff6e6d
git -C ../haxe.elixir.codex show 6a9b841da
git -C ../haxe.elixir.codex show 9df8f2b79
git -C ../haxe.elixir.codex show 23ee96a83
git -C ../haxe.elixir.codex show 94ab7d584
git -C ../haxe.elixir.codex show 18efaf896
```

Maintain a decision ledger containing:

| Delta | Original behavior | Vendor behavior | Current genes-ts behavior | Disposition | Evidence |
|---|---|---|---|---|---|

Record observed facts separately from inference.

---

# 6. Known Vendor Delta Inventory

The following inventory is a starting point, not permission to cherry-pick blindly.

## 6.1 Native async/await emission

### Vendor files

```text
vendor/genes/src/genes/es/ExprEmitter.hx
vendor/genes/src/genes/es/ModuleEmitter.hx
```

### Origin

The custom async work entered with downstream commit:

```text
ab4ff6e6d feat: integrate genes for full-stack JavaScript generation
```

The vendor implementation:

- detects `__async_marker__` in anonymous function bodies;
- emits `async function`;
- removes the synthetic marker from output;
- recognizes `js.Syntax.code("await {0}", value)`;
- emits native `await`;
- recognizes `@:async` and `@:jsAsync` on methods;
- avoids marking constructors async.

### Current genes-ts evidence

Current `genes-ts` already has a more deliberate architecture:

```text
src/genes/js/Async.hx
src/genes/es/ExprEmitter.hx
src/genes/es/ModuleEmitter.hx
```

It uses:

- `genes.js.Async.enable()`;
- a typed `await(...)` macro;
- `:jsAsync` semantic metadata;
- explicit anonymous-function metadata handling;
- shared native `async`/`await` emission.

### Required decision

Do not port the `__async_marker__` protocol unless a reduced test proves current architecture cannot express an important case.

The likely disposition is **superseded**, but it must be demonstrated.

### Required tests

Cover both TypeScript and classic JavaScript modes:

- static async method;
- instance async method;
- anonymous async function;
- nested anonymous async function;
- `Promise<T>` returning `T`;
- `Promise<Void>` used for side effects;
- awaited value followed by field access;
- awaited value followed by index access;
- exception propagation;
- evaluation order and single evaluation of the awaited expression;
- no marker variable in generated output;
- native `async` and `await`, with no Promise-wrapper simulation;
- source-map placement around `await`;
- invalid use outside an async function;
- constructor misuse rejected clearly.

If all pass, classify the vendor mechanism as superseded and add only missing regressions.

## 6.2 String literal emission

### Vendor file

```text
vendor/genes/src/genes/es/ExprEmitter.hx
```

### Origin

```text
6a9b841da fix: rename std files to .cross.hx for Elixir-specific implementations
```

The vendor changed:

```haxe
for (char in input)
```

to an indexed UTF-16 walk:

```haxe
for (i in 0...input.length) {
    var char = input.charCodeAt(i);
    ...
}
```

### Current genes-ts evidence

Current classic emitter still appears to use:

```haxe
for (char in input)
```

### Required decision

Reduce the original Haxe 4.3.7 failure and determine whether this is:

- a compiler compatibility fix;
- a Unicode correctness fix;
- a target-specific workaround that is no longer required;
- or a behavior change with supplementary-plane Unicode consequences.

Do not port it without testing Unicode behavior.

### Required tests

Generate, parse, and execute literals containing:

- ASCII;
- quotes and backslashes;
- newline, carriage return, and tab;
- control characters below `0x20`;
- Latin-1 and BMP Unicode;
- emoji and other surrogate-pair characters;
- combining characters;
- U+2028 and U+2029;
- strings used as object keys and import-like values;
- strings represented in source maps or generated metadata.

Compare:

- original Haxe JavaScript behavior where relevant;
- classic Genes output;
- genes-ts output;
- runtime string length and code-unit sequence.

The chosen implementation must preserve valid JavaScript/TypeScript and runtime equality, not merely produce a visually similar snapshot.

## 6.3 Runtime registry and bound-method typing

### Vendor file

```text
vendor/genes/src/genes/Register.hx
```

### Origin

```text
23ee96a83 refactor: enforce No-Dynamic policy + stabilize examples/todo-app
```

The vendor changed several independent concerns:

1. `globals` became `DynamicAccess<Object>`.
2. `global(name)` stopped using `untyped`.
3. array detection moved to `js.Syntax.code`.
4. structural iterator invocation stopped using `untyped`.
5. `bind` changed from broad `Dynamic` inputs to `Object` and `Function`.
6. hidden closure-cache access was confined to explicit `js.Syntax.code`.
7. closure cache keys became explicit strings.

### Current genes-ts evidence

Modern `Register.hx` has evolved significantly:

- iterator inputs now model arrays and structural iterable/map-like shapes;
- TypeScript runtime support distinguishes internal dynamic boundaries;
- `bind(o, m)` still uses `Dynamic`;
- the file includes a comment explaining why hidden runtime fields are dynamic;
- generated runtime declarations currently expose `any` for some registry functions.

### Required decision

Audit each concern separately. Do not replace the modern structural iterator model with the narrower vendor code.

For `bind`, determine the actual Haxe JS runtime contract before narrowing:

- what values can be receivers;
- what callable shapes can be passed;
- what hidden fields Haxe boot/runtime expects;
- whether `js.lib.Function` and `js.lib.Object` are sound for every call;
- whether a typed private carrier or narrow unsafe boundary is more accurate.

`Dynamic` is allowed only if this is genuinely an irreducibly dynamic runtime boundary and the unsafety remains contained and documented. Removing the word `Dynamic` while introducing inaccurate public typing is not an improvement.

### Required tests

- `global(name)` returns the same object on repeated access;
- distinct names return distinct objects;
- registry behavior for unusual property names is stable;
- array iterator creation;
- structural iterator function;
- map-like `keys/get` iteration;
- non-callable iterator field behavior where the current contract supports it;
- bound method invocation preserves `this`;
- repeated `bind(receiver, method)` returns the same cached closure;
- different receivers produce different closures;
- different methods on one receiver do not collide;
- null method returns null if that remains the contract;
- inheritance and overridden methods;
- no cache leakage across objects;
- classic JS runtime parity;
- generated TypeScript contains no unnecessary `any` outside the justified runtime boundary;
- `.d.ts` output does not expose an unsoundly narrow API.

Prefer a small private runtime shape or typed helper abstraction over repeated casts. Any unavoidable unsafe access must have nearby explanatory documentation.

## 6.4 Typed source-map JSON model

### Vendor file

```text
vendor/genes/src/genes/SourceMapGenerator.hx
```

### Origin

```text
23ee96a83
```

The vendor introduced a `SourceMap` typedef and changed:

```haxe
final map: Dynamic
```

to:

```haxe
final map: SourceMap
```

The type includes:

- `version`;
- `names`;
- `file`;
- `sourceRoot`;
- `sources`;
- `mappings`;
- optional `sourcesContent`.

### Current genes-ts evidence

Current `SourceMapGenerator.hx` still constructs the map as `Dynamic`.

### Required decision

This appears to be a valid generic typing improvement, but update it for the current source-map and output-transaction architecture instead of copying the old typedef mechanically.

### Required tests

- source-map JSON schema and types;
- correct `file` naming;
- deterministic `sources` ordering;
- null/unknown source handling;
- optional `sourcesContent`;
- source content enabled and disabled;
- no path leaks;
- clean serialization;
- source-map rollback/output transaction behavior;
- exact existing source-map consumer tests;
- TS and classic output source-map parity where promised.

The change must not alter source-map bytes unintentionally unless the old bytes are demonstrably incorrect.

## 6.5 Writer exception typing

### Vendor file

```text
vendor/genes/src/genes/Writer.hx
```

### Origin

```text
23ee96a83
```

The vendor changed:

```haxe
catch (e:Dynamic) {}
```

to:

```haxe
catch (e) {}
```

### Current genes-ts evidence

Current `Writer.hx` still uses `catch (e:Dynamic)` in the unchanged-output path.

### Required decision

Prefer inferred or precise exception typing if Haxe 4.3.7 and all supported macro/runtime targets accept it. Keep the catch narrowly scoped.

Also review whether swallowing every exception is correct. The original intent appears to be:

- if comparison with an existing output fails, continue and write the desired output.

It must not hide actual write failures.

### Required tests

- unchanged output avoids rewriting;
- changed output is written;
- missing output is created;
- read/comparison failure falls through to writing;
- write failure still propagates;
- timer/finalization behavior remains correct;
- Haxe 4.3.7 compilation;
- output transaction and atomicity tests remain green.

Do not broaden the catch or add placeholder recovery behavior.

## 6.6 Assignment formatting and trailing whitespace

### Vendor file

```text
vendor/genes/src/genes/es/ModuleEmitter.hx
```

### Origin

The final formatting appeared under:

```text
18efaf896 Derive PhoenixHx target names by default
```

The Genes changes themselves were not Phoenix-specific semantics. They changed selected emissions from:

```haxe
write(' = ');
writeNewline();
```

to:

```haxe
write(' =');
writeNewline();
```

### Required decision

Treat this as formatting-only unless evidence shows a parser, source-map, lint, or determinism defect.

If current output contains trailing whitespace, prefer a generic output-quality invariant rather than patching three individual call sites.

Possible valid outcome:

- add or strengthen a “no trailing whitespace” generated-output guard;
- fix the writer/emitter abstraction centrally;
- update reviewed snapshots.

Possible valid rejection:

- current output does not produce meaningful trailing whitespace after modern emitter changes;
- changing it would only churn snapshots.

Do not connect this patch to Phoenix target naming.

## 6.7 Non-substantive or downstream-only deltas

The following are not upstream compiler improvements by themselves:

- comment-only additions in `Genes.hx`;
- newline normalization in `extraParams.hxml`;
- CRLF/LF normalization;
- deletion of vendored upstream tests;
- deletion of vendored editor and Lix configuration;
- Reflaxe.Elixir’s custom `haxe_libraries/genes.hxml`;
- its `-D genes=0.4.14` compatibility identity;
- downstream example HXML activation;
- Phoenix-specific build, watcher, or target-name conventions;
- removal of files solely to keep the downstream vendor small.

Record these as downstream packaging or repository-maintenance decisions. Do not port them into compiler source.

---

# 7. Implementation Algorithm

## Phase 1 — Refresh and establish a clean baseline

1. Read `AGENTS.md`.
2. Inspect Beads state.
3. Fetch `origin` and tags without deleting untracked files.
4. Rebase or fast-forward according to repository policy.
5. Confirm existing tests pass before changes.
6. Record exact starting commit, Haxe version, Node version, and package-lock state.
7. Create the owning Bead and branch according to repository conventions.

## Phase 2 — Produce the decision ledger

For every vendor delta:

1. Identify the exact original line in `v0.4.14`.
2. Identify the downstream change and originating commit.
3. Find the corresponding current `genes-ts` owner.
4. Reduce the behavior into the smallest generic Haxe fixture.
5. Run it through:

   - standard Haxe JS where useful;
   - classic Genes JS;
   - genes-ts TypeScript.

6. Record output, runtime behavior, and typing.
7. Assign one disposition from section 3.

Do not begin broad implementation until the ledger distinguishes missing behavior from superseded behavior.

## Phase 3 — Implement missing generic improvements

For every “missing and valid” item:

1. Add the failing regression first.
2. Fix the earliest correct compiler/runtime layer.
3. Preserve both output modes.
4. Avoid string post-processing and downstream-specific conditions.
5. Add hxdoc for advanced compiler, macro, or interop behavior.
6. Update generated snapshots only after reviewing semantic output.
7. Run focused tests.
8. Commit the independently complete fix.

## Phase 4 — Prove superseded behavior

For async and any other superseded delta:

1. Add missing equivalence tests.
2. Show that modern architecture covers the downstream behavior.
3. Do not retain compatibility with an internal marker unless it is a documented public contract.
4. Record why the old implementation should not be ported.

## Phase 5 — Full verification

Run focused gates during iteration and the complete repository gate before declaring the work consumable:

```bash
yarn test
yarn test:dual-output
yarn test:genes-ts
yarn test:genes-ts:minimal
yarn test:genes-ts:full
yarn test:genes-ts:snapshots
yarn test:genes-ts:sourcemaps
yarn test:classic:dts
yarn test:library-profile
yarn test:output-quality
yarn test:output-transaction
yarn test:examples
yarn test:acceptance
yarn test:ci
```

Use the exact current script names if they change after syncing.

Full `yarn test:ci` is mandatory. Focused tests alone do not authorize downstream adoption.

---

# 8. Downstream Compatibility Verification

After `genes-ts` itself is green, test Reflaxe.Elixir from a temporary worktree or disposable copy.

Do not edit the real downstream main worktree merely to run the experiment. Do not add direct broad repository classpaths to its browser HXML.

The downstream currently uses Genes in:

```text
examples/12-phoenix-chat/build-client.hxml
examples/13-elixir-first-liveview/build-client.hxml
examples/15-phoenix-chat-haxe-first/build-client.hxml
examples/17-railshx-to-phoenixhx-todo/build-client.hxml
examples/todo-app/build-client.hxml
```

Its current HXML explicitly enables:

```text
-D js-es=6
--macro genes.Generator.use()
--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')
```

Modern `genes-ts/extraParams.hxml` additionally enables async and inline React markup. Verify whether automatic activation changes downstream output or macro order.

Test the first migration in classic ESM mode:

```text
Do not enable -D genes.ts.
```

TypeScript output is a separate product decision.

Required downstream evidence:

- all five client HXML files compile;
- generated ESM is reviewed;
- module/import paths remain compatible with existing bundlers;
- source maps remain usable;
- no runtime helper disappears unexpectedly;
- no duplicate macro activation causes behavior changes;
- no new machine-local paths appear;
- esbuild/Vite integration remains valid;
- browser behavior remains equivalent.

From the disposable downstream tree, run the relevant repository gates, including:

```bash
npm run test:examples
npm run test:examples-output
npm run test:examples-elixir
npm run test:examples-runtime
npm run guard:examples-qa
```

For todo-app browser validation, follow its `AGENTS.md` and use only the asynchronous bounded QA sentinel. Never start Phoenix in the foreground.

Review generated differences semantically. Byte identity is desirable when behavior has not changed, but it is not mandatory if modern `genes-ts` intentionally produces better reviewed output.

Leave the real downstream worktree unchanged after the experiment.

---

# 9. Failure Modes

The task is not complete if any of these occur:

- the old vendor is copied wholesale into `genes-ts`;
- the implementation introduces PhoenixHX or downstream path knowledge;
- `../genes-vanilla` is modified;
- untracked audit bundles are deleted;
- classic JavaScript is treated as secondary;
- TypeScript passes while classic runtime behavior regresses;
- async support is declared equivalent without anonymous/nested cases;
- a `Dynamic` annotation is removed by replacing it with an inaccurate type;
- runtime `any` leaks into user modules;
- string output is changed without Unicode/runtime tests;
- source-map output changes without exact map verification;
- writer exception handling begins hiding write failures;
- formatting churn is called a semantic fix;
- downstream output is tested through direct classpath hacks that bypass normal Lix/library resolution;
- focused tests pass but `yarn test:ci` is red;
- the Genes agent removes Reflaxe.Elixir’s vendor before a released/pinned replacement exists.

---

# 10. Rollout and Ownership

## genes-ts owns

- generic compiler/runtime improvements;
- regressions in both output modes;
- release notes for user-observable changes;
- package/release CI;
- exact commit/tag identifying the absorbed fixes.

## Reflaxe.Elixir owns later

- switching `-lib genes` to a pinned `genes-ts` dependency;
- any temporary compatibility alias;
- updating downstream HXML;
- removing `vendor/genes`;
- updating Phoenix examples and generated output;
- downstream browser and package smoke.

The downstream migration is tracked as:

```text
haxe.elixir.codex-m52
Replace vendored Genes with pinned genes-ts and prove PhoenixHX parity
```

Do not close that downstream task from the Genes repository.

### Downstream pin and pre-merge workflow

The downstream repository commits one exact Lix-resolved SHA.
`$GENES_CHECKOUT` and `$GENES_WORKTREE` are contributor inputs only and must
never appear in a committed consumer HXML.

If a downstream gate needs a generic fix before merge, push the isolated topic
branch to the canonical Genes repository or an authorized fork and temporarily
pin that exact fetchable SHA. Record its owner, PR, and replacement condition.
After merge, replace the topic SHA with the exact commit that landed on
canonical `main`: the squash commit when the PR was squash-merged, or the merge
commit when it was merged normally. When a release is admitted, advance to its
exact commit/artifact. A stable downstream release cannot retain an unmerged
topic/fork pin.

That stable-promotion repin is tracked explicitly as:

```text
haxe.elixir.codex-aas
Repin PhoenixHX Genes to the canonical merged or release commit
```

It is discovered from `haxe.elixir.codex-m52` and does not block the current
experimental integration lane. It becomes mandatory before stable promotion.

The canonical operational policy is
`docs/03-compiler-development/GENES_DEPENDENCY_WORKFLOW.md` in the downstream
repository.

Do not publish a release unless the repository’s release workflow and human authorization permit it. At minimum, provide a green commit that downstream can pin.

---

# 11. Acceptance Criteria

This task may close only when:

1. Every substantive vendor delta has a recorded disposition.
2. Every “already supported” claim names executable evidence.
3. Every “superseded” claim proves the relevant semantics.
4. Every valid missing improvement is implemented generically.
5. Async behavior is proven through current `genes.js.Async`; the old marker protocol is not copied unnecessarily.
6. String emission has explicit Unicode and runtime evidence.
7. Runtime registry typing preserves actual Haxe JS semantics.
8. Any remaining dynamic runtime boundary is narrow and documented.
9. Source-map construction is typed where sound and exact map tests pass.
10. Writer exception handling is typed without hiding write errors.
11. Formatting-only deltas are either rejected or enforced through a generic quality invariant.
12. Both TypeScript and classic JavaScript modes pass.
13. Full `yarn test:ci` passes.
14. A disposable Reflaxe.Elixir integration run passes its relevant client/example gates.
15. The real Reflaxe.Elixir worktree remains unchanged.
16. The final handoff identifies the exact green commit/tag for downstream pinning.
17. Beads state and repository documentation accurately reflect what was absorbed, superseded, rejected, or deferred.

---

# 12. Required Final Report

Respond with:

```text
Starting genes-ts revision:
- <commit/tag>

Downstream vendor snapshot:
- haxe.elixir.codex@1ce84dcfef6c1633e56cbc8e266984519181d84f
- vendor baseline: genes v0.4.14

Disposition ledger:
- Async/await: <already supported / tests added / implemented / deferred>
- String emission: <decision and evidence>
- Register globals: <decision and evidence>
- Iterator runtime: <decision and evidence>
- Bound-method cache: <decision and evidence>
- Source-map typing: <decision and evidence>
- Writer catch typing: <decision and evidence>
- Assignment whitespace: <decision and evidence>
- Non-substantive vendor changes: <decision>

Implemented commits:
- <commit> — <description>
...

Tests:
- yarn test:dual-output: ...
- yarn test:genes-ts:sourcemaps: ...
- yarn test:output-quality: ...
- yarn test:output-transaction: ...
- yarn test:examples: ...
- yarn test:ci: ...

Downstream disposable verification:
- client builds: ...
- generated output review: ...
- source maps: ...
- bundler/browser evidence: ...
- downstream worktree unchanged: yes/no

Green adoption revision:
- <exact commit/tag/archive identity>

Known downstream migration notes:
- <macro activation differences>
- <output differences>
- <compatibility alias requirements>
- <remaining risks>

Rejected or deferred deltas:
- <item, reason, owner>

Beads:
- <issue IDs and final statuses>

Unresolved facts:
- <none or exact list>
```

Do not state that Reflaxe.Elixir can remove its vendor until the downstream migration task has pinned this green revision and completed its own full verification.

## 14. 2026-07-19 Downstream Strict-TS Follow-Up

The downstream LiveReact event-contract lane found one generic Genes output
quality gap after admitting canonical v1.37.0: enabling TypeScript
`noUnusedLocals` across the complete strict TSX output reports unused
`Register` imports in generated support modules such as `haxe/extern/Rest`,
`haxe/NativeStackTrace`, `js/lib/Object`, `js/lib/Promise`, and `index`.

This does not invalidate the admitted downstream revision: strict type checking,
React runtime behavior, classic ESM parity, and source maps remain green, and
the Haxe-generated LiveReact event contract independently passes
`noUnusedLocals` plus `noUnusedParameters`. It does mean Genes should not yet
claim that an arbitrary complete TSX tree is no-unused-clean.

The Genes agent should reduce this without PhoenixHx or LiveReact symbols and
either omit semantically unused `Register` imports or make their required side
effect explicit. Verify both strict TypeScript/TSX and classic ESM output before
proposing the generic fix. Downstream should consume it only through the normal
exact pushed-SHA/merged-main/release admission workflow; no local checkout path
or in-repository Genes patch is allowed.
