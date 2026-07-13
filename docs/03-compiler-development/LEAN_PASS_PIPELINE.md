# Lean Pass Pipeline (Contributor Guide)

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

- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md` (seven default bundles)
- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md` (every effective pass)
- `docs/05-architecture/PASS_REGISTRY_INVENTORY.md` (phase/scope contracts, replay families, and registry diagnostics)
- `docs/05-architecture/PASS_REGISTRY_BASELINE.json` (representative pass counts and reference timings)

Regenerate the documentation from typed registry data:

```bash
npm run docs:passes
npm run guard:pass-inventory
```

The generator runs as a Haxe macro. That is intentional: the registry references compiler and
`haxe.macro.*` APIs that are valid in macro context, while a normal `--interp` main would type those
APIs as application runtime code. The old source-text parser could overcount disabled or deduplicated
registrations; structured introspection reports the effective validated order instead.

### Granular vs lean registry

By default, the registry exposes a small **lean** list of bundle passes (<=20) to keep the
order understandable for contributors. For deep debugging (per-pass metrics/timing), you can
opt into the full granular list:

- Build flag: `-D hxx_granular_pass_registry`
- Doc output: `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md`

### Inventory and bounded timing baseline

The validated granular registry contains 576 effective passes, but normal compilation no longer walks
every framework transform for every module. `PassScopeManifest` assigns exact stable pass IDs to an
ownership scope. `PassApplicability` then derives module capabilities from Haxe annotations, retained
compiler metadata, and structured ElixirAST nodes. It does not classify by pass-name fragments,
generated module names, file paths, or application names.

The runner re-evaluates capabilities at phase boundaries because an earlier phase can introduce a
structured target call used by a later phase. The default lean bundles and granular debugging mode
use the same pass functions, order, scopes, and capability analysis; bundles only make the registry
easier to inspect.

Run the bounded baseline report with:

```bash
npm run profile:passes:baseline
```

Each scenario selects one module and records only executed passes plus one summary. The summary also
records skipped and total registry counts, and the guard requires `executed + skipped = 576` with
stable registry indexes. Current representative counts are 406 executed passes for core and stdlib,
569 for Phoenix, 573 for LiveView, 453 for Ecto, 468 for HXX, and 409 for ExUnit. Checked-in
milliseconds are reference observations, not performance thresholds; compare them directionally on
the same machine. Counts and report shape are the stable contract.

### Why scoped and all-pass builds do not drift

Scoped execution is not a second compiler or a source-versus-package difference. Source checkouts and
built packages both use the same scoped pipeline. The verification-only
`-D reflaxe_elixir_disable_pass_scopes` switch asks that pipeline to execute every pass as it did
before scoping; framework passes still self-gate on their own semantic shape.

Run the cross-check with:

```bash
npm run test:pass-scope-parity
```

The guard compiles representative core, stdlib, Phoenix, LiveView, Ecto, HXX, and ExUnit fixtures in
both modes, compares the complete generated file trees byte-for-byte, and restores each fixture's
prior output directory. CI runs the timing/count and byte-parity checks together through
`npm run guard:pass-scopes`.

This cleanup removed 50 same-name registrations that `RegistryCore` had already discarded before
ordering or execution. Distinctly named final/replay passes were retained: similar names do not prove
equivalence because a later phase may create a shape the earlier pass could not see. Consolidate those
only after an idempotence test and focused regression demonstrate that the later execution is dead.

The non-`Void` result invariant follows the same boundary model:

- `-D reflaxe_elixir_validate_results` with the default lean registry reports the bundle that exposed a lost result.
- Adding `-D hxx_granular_pass_registry` reports the exact granular pass, which is slower but better for diagnosis.
- Snapshot tests enable result validation automatically through `test/Makefile`; ordinary compiler consumers do not pay this diagnostic cost.

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
