# Transparent Pass Pipeline (Contributor Guide)

Reflaxe.Elixir’s AST transformer stack is intentionally **ordered**: each pass assumes certain
shapes are already normalized by earlier passes. This document explains:

- where pass ordering lives,
- how to inspect the effective order,
- and which fixtures guard LiveView correctness without relying on the todo-app.

## Where ordering lives

- Registry (source of truth):
  - `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx`
- Registry groups (keep the registry readable):
  - `src/reflaxe/elixir/ast/transformers/registry/groups/`
- Runner (applies passes in order, skipping `enabled: false`):
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`

## Inspect the effective pass order

The repository maintains generated, deterministic registry artifacts:

- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md` (seven transparent group headings)
- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md` (every effective pass)
- `docs/05-architecture/PASS_REGISTRY_INVENTORY.md` (phase/scope contracts, replay families, and registry diagnostics)
- `docs/05-architecture/PASS_REGISTRY_BASELINE.json` (the accepted order/phase/scope digest,
  transparent group order, representative pass counts, and reference timings)

Regenerate the documentation from typed registry data:

```bash
npm run docs:passes
npm run guard:pass-inventory
```

The generator runs as a Haxe macro. That is intentional: the registry references compiler and
`haxe.macro.*` APIs that are valid in macro context, while a normal `--interp` main would type those
APIs as application runtime code. The old source-text parser could overcount disabled or deduplicated
registrations; structured introspection reports the effective validated order instead.

The baseline stores a SHA-256 digest of each effective pass's name, phase, and scope in execution
order. The generated granular document remains the readable list; the digest makes accidental
reordering fail even if someone regenerates that document. An intentional pipeline change therefore
requires reviewing the readable order first and then explicitly updating the baseline contract.

Registry relationships now fail closed. Suppose `NormalizeCalls` declares that it runs after
`BuildCalls`. If `BuildCalls` is misspelled, duplicated, part of a cycle, or ends up later in the
effective list, compilation stops before either transform runs and names the invalid relationship.
The validator also rejects unknown phases and movement back into an earlier phase.

Use `runAfter` and `runBefore` for hard relationships. Use `runAfterIfPresent` or
`runBeforeIfPresent` only when a supported conditional build deliberately omits the target. The
current `fast_boot` contract has two such edges: result binding follows the full reducer accumulator
pass when enabled, and the final case-binder replay follows the full underscore repair when enabled.
An optional edge is still enforced whenever its target exists.

The mature stable topological sorter remains in place because several source registrations are
intentionally moved by existing relationships. Validation runs once before it to reject malformed
declarations and once after it to prove the effective order.

### Groups are headings, not hidden runners

The default pipeline presents seven named groups so contributors do not have to understand all 578
passes at once. Each group contains the passes for one phase, but it does not execute them itself.
The main transformer flattens the groups once and executes every child through the same runner.

This distinction matters when a pass breaks a function result. Under the old opaque bundle, the
diagnostic could report only `BundleCoreTransforms`, even if `NormalizeCaseTail` was the child that
lost the value. With transparent groups, the diagnostic, timer, and AST snapshot all name
`NormalizeCaseTail` directly. The `BundleCoreTransforms` name remains a readable heading and a
backward-compatible group-disable token; it is no longer a second pass loop.

The historical flag below remains only as a differential test path. It constructs the same
validated granular list directly, without first grouping and flattening it:

- Build flag: `-D hxx_granular_pass_registry`
- Doc output: `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md`

Normal diagnosis does not need this flag. Default builds already expose exact child-pass timing,
snapshots, and invariant attribution.

### Inventory and bounded timing baseline

The validated registry contains 578 effective passes, but normal compilation does not execute every
framework transform for every module. `PassScopeManifest` assigns exact stable pass IDs to an
ownership scope. `PassApplicability` then derives module capabilities from Haxe annotations, retained
compiler metadata, and structured ElixirAST nodes. Inapplicable passes are skipped before their
transform function runs. The classifier does not use pass-name fragments, generated module names,
file paths, or application names.

The runner re-evaluates capabilities at phase boundaries because an earlier phase can introduce a
structured target call used by a later phase. Transparent grouped construction and direct granular
construction use the same pass functions, order, scopes, and capability analysis. Request-local
analysis invalidation infrastructure now exists, but `PassApplicability` deliberately remains outside
that cache: moving it would require cached-versus-forced-recomputed parity and a bounded performance
comparison. Its phase-level cadence therefore remains unchanged.

Each visible child pass does run with a request-local `PassContext`. New outcome-aware passes can
report `Changed`, `Unchanged`, or `Unknown` and explicitly preserve named cached analyses. Existing
AST-only passes are adapted as `Unknown`; they never claim preservation from root identity or printed
output. This is conservative without causing 578 capability recomputations, because no established
capability analysis has been migrated into the new cache yet. Under `debug_pass_metrics`, structural
digests replace printer calls so compiler-only intermediate nodes can be measured without teaching
the printer to accept them. The context does not eagerly walk each module for temporary-name hygiene,
and revision changes do not allocate cache bookkeeping while no analysis is materialized; both costs
begin only when a migrated pass requests the corresponding service.

Run the bounded baseline report with:

```bash
npm run profile:passes:baseline
```

Each scenario uses the default transparent-group path, selects one module, and records only executed
passes plus one summary. The summary also records skipped and total registry counts, and the guard
requires `executed + skipped = 578` with stable registry indexes. Current representative counts are
407 executed passes for core and stdlib,
570 for Phoenix, 574 for LiveView, 454 for Ecto, 469 for HXX, 410 for ExUnit, and 408 for Mix. Checked-in
milliseconds are reference observations, not performance thresholds; compare them directionally on
the same machine. Counts and report shape are the stable contract.

### Shared traversal allocation

Most passes inspect a complete module but change only a small part of it. The shared
`ElixirASTTransformer.transformNode` walk therefore preserves the original node and child arrays when
the callback leaves every descendant unchanged. If one descendant changes, only that ancestor path is
rebuilt; unrelated sibling branches retain their identity. This is ordinary structural sharing: every
callback still runs in the same order, and it does not let an adapted pass claim that cached analysis is
preserved. Legacy pass outcomes remain `Unknown` unless the pass reports a stronger outcome explicitly.

`npm run test:ast-children` checks no-op identity for every AST constructor and separately checks that a
real descendant edit rebuilds its path. Snapshot output and scoped/all-pass parity remain the semantic
oracles; object identity alone does not prove generated-code equivalence.

The 2026-08-02 optimization was measured against the same clean commit in an isolated worktree using
`core/domain_abstractions`, three alternating baseline/candidate pairs per state, fresh Haxe processes
(`HAXE_NO_SERVER=1`), and nearest-rank percentiles. “Cold output” means the generated tree was absent;
“warm output” means an identical generated tree already existed. The workstation had ordinary varying
load, so paired direction and compiler-phase timings are more trustworthy than the absolute process
times, and these numbers are evidence rather than a new budget.

| State and measurement | Baseline p50 / p95 | Structural sharing p50 / p95 |
| --- | ---: | ---: |
| Cold output, process wall | 9.02s / 9.22s | 8.58s / 8.64s |
| Cold output, target compiler | 3.25s / 3.40s | 3.01s / 3.04s |
| Cold output, pass manager | 2.37s / 2.40s | 2.22s / 2.22s |
| Warm output, process wall | 8.98s / 9.21s | 8.48s / 8.67s |
| Warm output, target compiler | 3.62s / 3.90s | 3.05s / 3.07s |
| Warm output, pass manager | 2.40s / 2.63s | 2.06s / 2.08s |

All twelve measured output trees had the same SHA-256 digest. The full categorized snapshot backstop
then passed 413/413 fixtures. Re-measure on the same host and toolchain when changing this traversal;
do not compare these workstation seconds directly with hosted CI duration.

### Read-only walks

Most passes find nothing to do in a given module. In the todo-app, a warm build after an edit of one
function body in `TodoLive.hx` runs 555 passes on `TodoAppWeb.TodoLive`, and only 40 of them change
its tree (counted with `-D debug_pass_metrics`). No single pass costs more than 2% of the module's pass
time. The cost is the many walks over the same tree, not one slow pass.

Many of those walks only collect facts through `ASTUtils.walk`. That walk used to call `iterateAST` on
each node, which made two closures for each node. It now calls `ElixirASTTransformer.visitPreorder`,
which runs the same traversal engine once over the tree: the engine's boundary check is the visit, and
the transform callback returns each node unchanged. The visited nodes and their order do not change.
`npm run test:ast-children` compares the new walk with the old recursion, node by node, over every AST
constructor.

Measured on 2026-11-25 on the todo-app, at a one-minute load of 36 on 12 cores. The pipeline for
`TodoAppWeb.TodoLive` ran 12 times in one warm compiler process, taking turns between the old and the
new walk:

| Measurement for one `TodoLive` pass pipeline | Old walk | New walk |
| --- | ---: | ---: |
| Interpreter allocation (minor heap words, exact) | 816 M | 767 M |
| CPU time, median of 6 runs (indicative: measured on a busy machine) | 2.78 s | 2.55 s |

The allocation count is exact and repeats run to run. The CPU time was measured at a load of 36,
so treat it as indicative. An independent check measured one walk of a 9,771-node tree at 605
minor heap words per node before and 314 after, and a whole fresh todo-app compile at 5,409 M
words before and 5,274 M after.

The fresh todo-app output tree is byte-identical before and after (125 files), and a warm build after
edits equals a fresh build. The pipeline call made 3,433 walks for this one module.

### Engine cost per node

A profile of the same `TodoLive` edit (on `5aa5fdf0a`) found that 295 of its 555 pass runs return a
new tree object with no structural change, and that these runs allocate 499 M of the pipeline's
767 M words. The first guess was that rebuilt nodes cause this allocation. A measurement disproved
it: making the engine keep a node that a callback only copied (below) changed the pipeline's
allocation by +0.2%. Most of the allocation is the cost of the walks themselves. In the Haxe macro
interpreter every function call allocates a frame of about 30 words, and an anonymous record about
18 words. A no-op `transformNode` cost about 260 words per node on a synthetic module.

The traversal engine now avoids work it does not need:

- **Leaf children inline.** Most nodes are leaves (`EVar`, `EAtom`, literals). The engine handles a
  leaf child in place (`transformChild`, an inline function) instead of calling itself just to find
  that the leaf has no children. A leaf still gets the same calls in the same order: the boundary
  predicate, then the callback. `ERaw` is not handled this way, because the engine gives it to the
  callback only when it is a boundary.
- **No result records.** The child-array helpers return the array itself when nothing changed, and a
  copy when something changed, instead of an `{array, changed}` record for each array.
- **Fewer closures for patterns.** `PVar` and `PWildcard` hold no AST, so the engine returns them at
  once, with no closure. Every other pattern still gets one closure from the engine.
  `ElixirPatternChildren.mapImmediate` copies a pattern, an array, or a record only when one of its
  children changed, and it no longer makes two closures and a new pattern value per call.
- **Walks without an identity callback.** `visitPreorder` (behind `ASTUtils.walk`) passes no
  transform callback; the engine reads `null` as "keep every node".
- **Copies kept as the original.** When a callback returns a one-level copy of its input (same
  constructor, the same child objects, the same scalar values, the same metadata object, and the same
  position), the engine keeps the input (`ElixirASTShallowEquality.sameNode`). Its parent then sees an
  unchanged child and is not rebuilt either. This does not cut allocation, but on `TodoLive` it makes
  183 more pass runs return their input object (403 of 555 instead of 220). The other 112 no-change
  rebuilds come from passes with hand-written recursion that copy whole subtrees; a one-level check
  cannot see those.

What a kept copy changes, and what it does not: a kept node and its copy have the same `def` values,
the same metadata object, and the same position, so the printer and every later pass read the same
values. Only object identity differs. A metadata write in place lands in the same object either way.
Three guards keep this narrow:

- A node whose metadata is `null` is never treated as a copy, because a later `node.metadata = {}`
  would then write to a node that the input tree also holds.
- An `EFloat` copy always counts as a change: in Haxe `-0.0 == 0.0` is true, but the two print
  differently.
- New arrays and clause records count as the same when every entry is the same object or value. This
  is safe only while no pass changes a payload array or a clause record in place: the kept node is the
  input node, so a pass that edits the arrays of a returned node, expecting a fresh copy, would also
  edit the input tree.

Object identity does change, so code that **reads identity to make a decision** can behave
differently. The first version of this change did change generated code this way.
`HeexStringReturnToSigilTransforms.convertStringReturns` read `newBody != body` to decide whether a
function body had taken part in the `~H` conversion. Its helper rebuilds every `if` and parenthesis,
so before, such a body always looked changed. With copies kept, a `render/1` that only delegates
behind an `if` looked unchanged, and the `render/1` fallback replaced the whole body with a `~H`
sigil. A helper with `_assigns` and a plain `if` kept `_assigns` instead of being renamed, and a
parenthesized HTML string body became `~H`. The pass now uses an explicit flag: the body counts as
rebuilt when its callback returned a different object for any node, which is exactly the old
identity answer. `test/snapshot/phoenix/heex_render_delegation_identity` and a pass-level check in
`npm run test:ast-children` hold the output of `5aa5fdf0a` for these cases.

To find every other such caller, a temporary instrument (not committed) recorded each
`transformNode` or `transformNodeUntil` call that returned its input only because a copy was kept,
with the caller's file and line. It ran over the whole snapshot corpus and a fresh todo-app build. It
found 308 distinct call sites:

- 299 return the result directly. 229 of them are pass functions that the registry names, whose
  result goes to the pass runner; the runner does not branch on identity (legacy passes report
  `Unknown`). The other 70 (helpers, and passes that the registry names in another way) were traced to
  every caller. Four of those callers compare the result with their input:
  - `HeexStringReturnToSigilTransforms.convertStringReturns`: changes output; fixed with the flag
    above.
  - `ReduceWhileSentinelCleanupTransforms.transformPass` and
    `StaticVarMutationRewriteTransforms.transformPass`: identity only chooses between returning the
    node and rebuilding it with the same children, the same shape, metadata and position, so the
    output is the same either way.
  - `BinderTransforms.rewriteInScope` callers: the same output, for a simpler reason.
    `rewriteInScope` is hand-written recursion; its only engine use is `transformAST`, where every
    child is a boundary, so no copy is ever kept and its identity result is the same on both engines.

`ReduceMetasHeadRepairTransforms.pass` also compares a result with its input (`newBody !=
clause.body`) and rebuilds with fresh metadata when they differ. It is safe today because the
callbacks of `repairInBody` never return a copy; a comment at that site says so.
- 9 store the result in a variable that is never compared by identity.

Code that keys a map by node objects was read by hand. `TempVariableTransforms` and
`AssignmentExtractionTransforms` collect nodes before they run, and their callbacks return either the
node itself or a real rewrite, never a copy, so what they see does not change.
`TemplateHelpers.convertWithLiteralTemplateSource` maps new `EString` nodes back to their
`EStringLiteral` source by identity, and returns its input when `convert` returned the same tree.
When `convert` changes nothing, both the old path (map back) and the new one (return the input) give
the input tree, because no `convert` callback copies an `EString` leaf. The audit covers the code
paths that the corpus and the todo-app reach; a pass that reads identity on a path no fixture reaches
would not be listed.

`npm run test:ast-children` checks, for every AST constructor except `EFloat`, that a callback that
copies every node gives back the input object, and that a real change (another name, another child,
fresh or copied metadata, a dropped attribute span, `-0.0` for `0.0`) is still a change. It also checks
that the engine's inline leaf list names exactly the constructors with no AST and no pattern children,
except `ERaw`.

Measured on 2026-11-25 on the todo-app, after an edit of one string in `TodoLive.hx`. The `TodoLive`
pass pipeline ran 12 times in one warm compiler process, taking turns between the old engine and the
new one (a temporary copy of the old engine, not committed). The one-minute load was 55 to 67 on 12
cores:

| Measurement for one `TodoLive` pass pipeline | Old engine | New engine |
| --- | ---: | ---: |
| Interpreter allocation (minor heap words, exact) | 767.7 M | 537.8 M (-30%) |
| CPU time, median of 6 runs (indicative: measured on a busy machine) | 3.83 s | 3.24 s (-15%) |

After the explicit flag in `HeexStringReturnToSigilTransforms`, the same paired run on 2026-11-26
(load 26 to 45) gave 767.7 M and 537.6 M words, and CPU medians of 2.57 s and 2.21 s (-14%).

The fresh todo-app output tree is byte-identical before and after (125 files, `_GeneratedFiles.json`
included).

### Why grouped, granular, and all-pass builds do not drift

Scoped execution is not a second compiler or a source-versus-package difference. Source checkouts and
built packages both use the same scoped pipeline. The verification-only
`-D reflaxe_elixir_disable_pass_scopes` switch asks that pipeline to execute every pass as it did
before scoping; framework passes still self-gate on their own semantic shape.

Run the cross-check with:

```bash
npm run test:pass-scope-parity
```

For each representative core, stdlib, Phoenix, LiveView, Ecto, HXX, and ExUnit fixture, the guard
performs three bounded compilations:

1. default transparent groups with normal pass scopes;
2. direct granular construction with normal pass scopes; and
3. direct granular construction with every pass enabled.

It compares the complete generated trees from 1↔2 and 2↔3 byte-for-byte, then restores the fixture's
previous output directory. The first comparison proves that grouping is scheduling metadata only.
The second preserves the established scoped-versus-all-pass contract. CI runs the timing/count and
byte-parity checks together through `npm run guard:pass-scopes`.

This cleanup removed 50 same-name registrations that `RegistryCore` had already discarded before
ordering or execution. Distinctly named final/replay passes were retained: similar names do not prove
equivalence because a later phase may create a shape the earlier pass could not see. Consolidate those
only after an idempotence test and focused regression demonstrate that the later execution is dead.

The non-`Void` result invariant follows the same boundary model:

- `-D reflaxe_elixir_validate_results` reports the exact child pass that first exposes a lost result.
- The diagnostic path is identical under transparent-group and direct-granular construction.
- Snapshot tests enable result validation automatically through `test/Makefile`; ordinary compiler
  consumers do not pay this diagnostic cost.

Use `npm run test:result-invariant` to run the compile-time-only mutation fixture. It deliberately
removes one function result after a known pass and verifies that the diagnostic names both the pass
and function. The mutation code is excluded from every build that does not define
`reflaxe_elixir_test_result_invariant_mutation`.

## LiveView “golden” fixture

The todo-app is a great integration test, but it’s too large and app-specific for a stable
regression signal. Use the focused LiveView fixture snapshot instead:

- `test/snapshot/liveview/golden_liveview_fixture`

What it covers:
- runnable callback names/shapes: `mount/3`, `handle_event/3`, `handle_info/2`, `render/1`
- event parameter extraction from `params` (shape-only, no domain heuristics)
- typed assigns updates via `LiveSocket` macros

Run it:

```bash
make -C test single TEST=liveview/golden_liveview_fixture
```

Update its intended output (when a change is intentional):

```bash
make -C test update-intended TEST=liveview/golden_liveview_fixture
```

## Design guardrails (reminders)

- Prefer **shape-based** transforms over name-based heuristics.
- Declare framework ownership by exact pass ID and typed module capability; do not derive scope from names.
- Avoid ERaw-dependent rewrites (passes can’t “see” inside raw strings).
- Fix root causes in builder/transformer; keep the printer as a pretty-printer only.
- Preserve function value context. A cleanup pass may remove a non-final no-op, but it must keep the RHS when that expression is the function or block result.
