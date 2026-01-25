# Epic: Stdlib Parity vs `haxe.elixir.reference`

Owner: Compiler/stdlib

## Goal

Close the Elixir-target stdlib parity gap so that “normal” Haxe code that relies on the standard library compiles and runs correctly on BEAM, with outputs that are idiomatic and maintainable.

This epic is module-level scoped first (coverage), then drills into API/behavior parity within each module.

## Inputs

- Module-level gap report: `docs/08-roadmap/stdlib-parity/gap-report.json`
- Regeneration script: `scripts/stdlib-parity-report.sh`
- Reference repo: `../haxe.elixir.reference`

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

## Workstreams (proposed order)

1) **Core top-level modules**
   - Done: `EReg`, `DateTools`, `IntIterator`, `List`, `Map`, `UInt`
   - Next: `Xml`, `UnicodeString` (core-types like `Any`, `Class`, `StdTypes` are typically not override targets)

2) **`haxe.io` + core utilities**
   - Done (core building blocks): `haxe.io.BufferInput`, `haxe.io.BytesBuffer`, `haxe.io.BytesInput`, `haxe.io.BytesOutput`, `haxe.io.FPHelper`, `haxe.Json`
   - Done: `haxe.Exception`
   - Next: `haxe.CallStack`, and remaining `haxe.io.*` utilities as-needed

3) **`sys.*` runtime integration**
   - Prioritize: `sys.io.File`, `sys.FileSystem`, `sys.io.Process`, `sys.net.Socket`, `sys.thread.*`
   - Guardrails: BEAM/OTP idioms, avoid pretending POSIX semantics exist where they don’t.

4) **Parsers/serializers**
   - Prioritize: `haxe.Serializer` / `haxe.Unserializer` (if required by downstream libs)

## Tracking

Create one task per module (or small module cluster) with:
- The reference file(s) used for parity decisions.
- Snapshot(s) added/updated that lock in the intended Elixir shape and semantics.
- A runtime ExUnit test that executes on BEAM for key behavior (avoid “snapshot-only” confidence).

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
