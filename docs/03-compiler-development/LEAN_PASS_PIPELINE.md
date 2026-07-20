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
