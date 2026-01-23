# Epic: Stdlib Parity vs `haxe.elixir.reference`

Owner: Compiler/stdlib

## Goal

Close the Elixir-target stdlib parity gap so that “normal” Haxe code that relies on the standard library compiles and runs correctly on BEAM, with outputs that are idiomatic and maintainable.

This epic is module-level scoped first (coverage), then drills into API/behavior parity within each module.

## Inputs

- Module-level gap report: `docs/08-roadmap/stdlib-parity/gap-report.json`
- Regeneration script: `scripts/stdlib-parity-report.sh`
- Reference repo: `../haxe.elixir.reference`

## Definition of Done (incremental)

### Phase 1 — Coverage (modules exist)
- Each priority module exists under `std/` or `std/_std/` (as appropriate for target-gated overrides).
- Compiles cleanly in snapshot suite and todo-app under `--warnings-as-errors`.

### Phase 2 — API parity (surface area)
- Public functions/types match Haxe std expectations (signatures, nullability, exceptions).
- No new `Dynamic` on public surfaces unless unavoidable.

### Phase 3 — Behavioral parity (runtime semantics)
- Snapshot tests cover core behaviors per module.
- Example app(s) exercise common code paths.

## Workstreams (proposed order)

1) **Core top-level modules**
   - Done: `EReg`, `DateTools`, `IntIterator`, `List`, `Map`
   - Next: `Xml`, `UInt`, `UnicodeString` (core-types like `Any`, `Class`, `StdTypes` are typically not override targets)

2) **`haxe.io` + core utilities**
   - Done (core building blocks): `haxe.io.BufferInput`, `haxe.io.BytesBuffer`, `haxe.io.BytesInput`, `haxe.io.BytesOutput`, `haxe.io.FPHelper`, `haxe.Json`
   - Next: `haxe.Exception`, `haxe.CallStack`, and remaining `haxe.io.*` utilities as-needed

3) **`sys.*` runtime integration**
   - Prioritize: `sys.io.File`, `sys.FileSystem`, `sys.io.Process`, `sys.net.Socket`, `sys.thread.*`
   - Guardrails: BEAM/OTP idioms, avoid pretending POSIX semantics exist where they don’t.

4) **Parsers/serializers**
   - Prioritize: `haxe.Serializer` / `haxe.Unserializer` (if required by downstream libs)

## Tracking

Create one task per module (or small module cluster) with:
- The reference file(s) used for parity decisions.
- Snapshot(s) added/updated that lock in the intended Elixir shape and semantics.

## Notes / Non-goals

- This epic does not imply 1:1 parity with hxcpp/js quirks—parity target is the reference Elixir stdlib + Haxe std semantics.
- Prefer BEAM-native idioms where they preserve Haxe semantics; avoid runtime-only “string patch” fixes.
