# Epic: Stdlib Parity vs `haxe.elixir.reference`

Owner: Compiler/stdlib

## Goal

Close the Elixir-target stdlib parity gap so that “normal” Haxe code that relies on the standard library compiles and runs correctly on BEAM, with outputs that are idiomatic and maintainable.

This epic is module-level scoped first (coverage), then drills into API/behavior parity within each module.

## Design stance (important)

This epic optimizes for two properties:

1) **Idiomatic Elixir output** (human-reviewable BEAM code, minimal runtime scaffolding)
2) **Predictable Haxe semantics** (stdlib users should not need “target folklore” to avoid traps)

In practice, this means:

- **Boundary terms stay native**: payloads coming from Phoenix/JSON (e.g. params, Presence) are native `%{}` maps/terms and should be accessed via Elixir-native helpers (`ElixirMap`, `WirePayload`, etc.).
- **Haxe containers are honest**: if something is typed as `Map<K,V>` and you call `.get/.set`, it must be backed by a compatible map runtime (or we should provide a target override that safely maps `Map` operations to native `Map.*`).

This is why we treat “Map parity” as a first-class workstream: it is the highest leverage way to remove gotchas while still generating idiomatic Elixir.

Related (ongoing) work:
- Iterator + `IMap` runtime canonicalization: BD `haxe.elixir-hm47.23` (removes remaining “map wrapper shape” ambiguity and moves iterator runtime into stdlib as source of truth).

## Inputs

- Module-level gap report: `docs/08-roadmap/stdlib-parity/gap-report.json`
- Regeneration script: `scripts/stdlib-parity-report.sh`
- CI drift guard (local-state consistency): `npm run guard:stdlib-parity`
- Reference repo: `../haxe.elixir.reference`

## Current status (rolling)

- Latest gap report: **147 missing** modules (see `docs/08-roadmap/stdlib-parity/gap-report.md`)
- Recently closed (high leverage):
  - `haxe.Int32`, `haxe.Int64`, `haxe.Int64Helper` (deterministic overflow + bitwise semantics on BEAM)
  - `haxe.ds.Map` + `haxe.ds.StringMap`/`IntMap`/`ObjectMap` surfaces (native `%{}` backend; lowered to `Map.*`)
  - `haxe.DynamicAccess` + iterators (typed dynamic map access for JSON/string-key payloads)
  - `Reflect` improvements for string-key JSON maps vs atom-key “object literal” maps
  - `haxe.crypto.Md5` (BEAM-native `:crypto.hash/2` for runtime, pure Haxe fallback for macro context)

## Root Layout (source of truth)

Most stdlib overrides live under `std/` and are injected only for Elixir builds via bootstrap macros.
However, a small subset of overrides may need to be visible **before** bootstrap runs in consumer
installs (because Haxe resolves some std modules very early).

Local roots considered by the gap report:
- `std/` — `.cross.hx` stdlib overrides + extern surfaces
- `std/_std/` — Elixir-only shims (classpath-gated)
- `src/haxe/` — early-resolved overrides needed by consumer installs (example: `haxe.Exception`)

## Definition of Done (incremental)

### Phase 1 — Coverage (modules exist)
- Each priority module exists under `std/` / `std/_std/` (or `src/haxe/` for early-resolved consumer-install overrides).
- Compiles cleanly in snapshot suite and todo-app under `--warnings-as-errors`.

### Phase 2 — API parity (surface area)
- Public functions/types match Haxe std expectations (signatures, nullability, exceptions).
- No new `Dynamic` on public surfaces unless unavoidable.

### Phase 3 — Behavioral parity (runtime semantics)
- Snapshot tests cover core behaviors per module.
- Add at least one Haxe-authored ExUnit runtime test per priority module to prove BEAM semantics (see `docs/02-user-guide/exunit-testing.md`).
- Example app(s) exercise common code paths.

## Testing policy (non-negotiable)

For stdlib work we require **both**:

- **Snapshots** (shape/regression): lock in emitted Elixir shape where it matters.
- **Haxe-authored ExUnit runtime tests** (semantics): prove behavior on BEAM.

Rationale: snapshots alone do not catch subtle semantic drift (edge cases, exceptions, ordering, identity).

### Runtime parity harness (concrete)

Stdlib runtime semantics are tested by compiling Haxe tests into ExUnit and executing them on BEAM as part of the normal `mix test` suite:

- Haxe-authored tests live under:
  - `test/haxe_exunit/stdlib_parity/src_haxe/**`
- Compilation + loading is wired in:
  - `test/exunit/test_helper.exs`
- Primary command (fast CI-friendly):
  - `npm run test:mix-fast`

## Priority / sequencing (BD-ready)

The gap report is large; we focus on the smallest set that unlocks real-world libraries quickly while avoiding semantic traps.

### Phase 0 — Parity harness + conventions (1–2 tasks)

**Task: “Stdlib runtime parity harness (Haxe→ExUnit)”**
- Add a tiny convention for stdlib runtime tests:
  - One test module per stdlib module touched (fast, deterministic).
  - Each module’s task must include at least one runtime test that exercises sharp edges.
- Acceptance:
  - Tests compile from Haxe and run on BEAM in CI.
  - Documentation on where/how to add these tests.

Notes learned from early parity work:
- Prefer semantic tests that exercise real BEAM behaviors (immutability, exceptions, key types) rather than relying on print-shape snapshots alone.
- Avoid introducing generic variable binders inside `__elixir__()` snippets (e.g. `x = ...`), since injected bindings occur in the caller’s scope and can clobber user variables after inlining. Use descriptive `reflaxe_*` binders or avoid binding entirely.

Suggested command coverage:
- Snapshot layer: `make -C test summary`
- Runtime layer (stdlib-focused): add a fast CI entry that runs only the stdlib parity ExUnit tests (to be defined as part of the harness).

### Phase 1 — Map family parity (high leverage; removes gotchas)

Goal: make `Map` usage predictable and eliminate “native map vs Haxe map” traps without forcing conversions.

**Task: `haxe.ds.StringMap` (native `%{}` backend)**
- Implement/override so `get/set/exists/remove/keys/iterator` map to Elixir-native `Map.*`.
- Runtime tests: missing key, overwrite, deletion, iteration.

**Task: `haxe.ds.IntMap` (native `%{}` backend)**
- Same, with integer keys.
- Runtime tests for negative keys, key equality, iteration.

**Task: `haxe.ds.ObjectMap` decision (explicit, separate)**
- Decide/document what semantics we support on BEAM.
  - Haxe’s “object identity” does not translate cleanly to BEAM terms.
- Either implement with clearly documented semantics + tests, or intentionally defer with a documented limitation (no band-aids).

**Task: `Map<K,V>` dispatch rules (Elixir target)**
- Ensure `Map<K,V>` chooses the correct backing implementation (StringMap/IntMap/…).
- Ensure generated Elixir stays idiomatic (no wrapper allocations).

### Phase 2 — Core “ecosystem blockers” (small set; big payoff)

**Task: `haxe.CallStack`**
- Provide correct types + behavior for stack capture/formatting that integrates with our exception model.
- Runtime tests: capture is non-empty; formatting stable; integration with `haxe.Exception.details()`.

**Task: `haxe.Int64`**
- Implement minimal correct semantics for arithmetic/comparison/printing.
- Runtime tests: parse/print, comparisons, arithmetic edge cases (document expectations).

**Task cluster: `haxe.Serializer` + `haxe.Unserializer`**
- Only if we want portability claims for libs that rely on them (common in some ecosystems).
- Runtime tests: round-trip, malformed input errors, compatibility notes.

### Phase 3 — `sys.*` integration (BEAM/OTP idioms; explicitly scoped)

The gap report shows `sys.*` missing is mostly `sys.net.*`, `sys.ssl.*`, `sys.thread.*`, `sys.db.*`, and `sys.Http`.
These require careful design on BEAM; we should not “fake” POSIX semantics.

**Task: `sys.Http`**
- Provide a BEAM-native implementation with clear sync/async semantics matching Haxe expectations.
- Prefer minimal dependencies and document limitations.
- Runtime tests: GET success, error handling, timeout behavior.

**Task cluster: `sys.net.*`**
- `sys.net.Host`, `sys.net.Address`, `sys.net.Socket`, `sys.net.UdpSocket`
- Map to `:gen_tcp` / `:gen_udp` idioms; document blocking behavior.
- Runtime tests: local loopback connect/send/recv, error cases.

**Task cluster: `sys.ssl.*`**
- `sys.ssl.Socket` plus certificate/key/digest types as needed.
- Map to `:ssl` module; document platform limitations.

**Task cluster: `sys.thread.*`**
- BEAM is not OS-thread oriented; treat as “concurrency primitives” mapping to OTP processes where possible.
- Must be carefully specified; some APIs may not be meaningfully supported 1:1.

**Task cluster: `sys.db.*`**
- Likely out of scope for “stdlib parity first” unless needed by key libraries; if implemented, prefer DB driver idioms and document mismatch.

## Workstreams (proposed order)

1) **Core top-level modules**
   - Done: `EReg`, `DateTools`, `IntIterator`, `List`, `Map`, `UInt`
   - Next: `Xml`, `UnicodeString` (core-types like `Any`, `Class`, `StdTypes` are typically not override targets)

2) **`haxe.io` + core utilities**
   - Done (core building blocks): `haxe.io.BufferInput`, `haxe.io.BytesBuffer`, `haxe.io.BytesInput`, `haxe.io.BytesOutput`, `haxe.io.FPHelper`, `haxe.Json`
   - Done: `haxe.Exception`
   - Done: `haxe.Int32`, `haxe.Int64`, `haxe.Int64Helper`
   - Next: `haxe.CallStack`, and remaining `haxe.io.*` utilities as-needed

3) **`sys.*` runtime integration**
   - Prioritize: `sys.Http`, `sys.net.*`, `sys.ssl.*`, `sys.thread.*`
   - Guardrails: BEAM/OTP idioms, avoid pretending POSIX semantics exist where they don’t.

4) **Parsers/serializers**
   - Prioritize: `haxe.Serializer` / `haxe.Unserializer` (if required by downstream libs)

## Tracking

Create one task per module (or small module cluster) with:
- The reference file(s) used for parity decisions.
- Snapshot(s) added/updated that lock in the intended Elixir shape and semantics.
- A runtime ExUnit test that executes on BEAM for key behavior (avoid “snapshot-only” confidence).

## Next actions (turn this into BD work)

1) **Create the BD epic** using the template below.
2) **Generate a prioritized task list** from `gap-report.json`:
   - Tier 0 (DX unblockers): maps/iterators/callstack/exceptions/bytes/json
   - Tier 1 (ecosystem blockers): serializer/unserializer/template/http
   - Tier 2 (BEAM integration): `sys.net.*`, `sys.ssl.*`, `sys.thread.*`
3) **Open one BD task per module/cluster**, each including:
   - Reference link(s) to `haxe.elixir.reference`
   - Snapshots + Haxe-authored ExUnit runtime semantics test(s)
   - WAE criteria: `npm run test:mix-fast`, `npm run test:examples-elixir`, and todo-app QA sentinel

## Task template (copy/paste)

For each module/cluster task:

- Scope: which module(s), which functions are in-scope now (explicit).
- Reference: link to `haxe.elixir.reference` source file(s) used.
- Implementation:
  - `std/**/*.cross.hx` vs `std/_std/**/*.hx` vs `src/haxe/**/*.cross.hx` (if early-resolved)
  - any compiler transforms required (shape-driven; no app-specific heuristics)
- Tests:
  - Snapshot(s) updated/added (list)
  - Haxe-authored ExUnit runtime test(s) added (list)
- Acceptance:
  - WAE clean in todo-app + dogfood + sentinel
  - No new `Dynamic` public surfaces

## Notes / Non-goals

- This epic does not imply 1:1 parity with hxcpp/js quirks—parity target is the reference Elixir stdlib + Haxe std semantics.
- Prefer BEAM-native idioms where they preserve Haxe semantics; avoid runtime-only “string patch” fixes.

## BD Epic (pasteable template)

Title:
- `Stdlib parity vs haxe.elixir.reference (phase 1–3)`

Description:
- Goal: close stdlib parity gaps for Haxe→Elixir while keeping output idiomatic and typed.
- Inputs:
  - `docs/08-roadmap/stdlib-parity/gap-report.json`
  - `docs/08-roadmap/stdlib-parity/gap-report.md`
  - `scripts/stdlib-parity-report.sh`
  - Reference repo: `../haxe.elixir.reference`
- Acceptance:
  - Priority modules implemented in `std/` / `std/_std/` (or `src/haxe/` when required by consumer-install ordering).
  - Snapshot coverage + Haxe-authored ExUnit runtime tests for behaviors.
  - Todo-app + dogfood + sentinel remain green under `--warnings-as-errors`.

Task breakdown suggestion:
- 1 task per module (or small cluster), each with:
  - “Parity notes” link to reference source(s)
  - Snapshot(s) added/updated
  - ExUnit runtime test(s) proving BEAM behavior

## GPT‑5 Pro escalation (when needed)

If a parity decision is subtle (semantics vs BEAM idioms), ask GPT‑5 Pro with a small repomix
containing only the relevant std module + test scaffolding.

Suggested repomix inputs (edit per module):
- `docs/08-roadmap/stdlib-parity/gap-report.json`
- `scripts/stdlib-parity-report.sh`
- `docs/01-getting-started/cross-hx.md`
- `docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md`
- `src/reflaxe/elixir/CompilerBootstrap.hx`
- `src/reflaxe/elixir/CompilerInit.hx`
- `std/<Module>.cross.hx` (or `src/haxe/<Module>.cross.hx`)
- `test/snapshot/**` cases relevant to the module
- `docs/02-user-guide/exunit-testing.md`
