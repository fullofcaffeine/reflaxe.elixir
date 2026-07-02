# Epic: Stdlib Parity vs `haxe.compilerdev.reference`

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

Related work:
- Iterator + `IMap` runtime canonicalization (task `haxe.elixir-hm47.23`):
  - canonical iterator runtime now lives in `std/haxe/iterators/ArrayIterator.cross.hx` and `std/haxe/iterators/MapKeyValueIterator.cross.hx`
  - transformer iterator fallback was removed; iterator behavior is owned by stdlib/runtime modules
  - map representation decision: built-in `Map`/`StringMap`/`IntMap` are native `%{}` backed on Elixir; `ObjectMap` identity semantics and parity tests are tracked as follow-ups

## Inputs

- Module-level gap report: `docs/08-roadmap/stdlib-parity/gap-report.json`
- Regeneration script: `scripts/stdlib-parity-report.sh`
- CI drift guard (local-state consistency): `npm run guard:stdlib-parity`
- Reference repo: `$HAXE_ELIXIR_REFERENCE` (local env var path)

## Current status (rolling)

- Latest gap report: **103 Haxe stdlib modules/classes still to port** (see `docs/08-roadmap/stdlib-parity/gap-report.md`)
- Recently closed (high leverage):
  - `haxe.Int32`, `haxe.Int64`, `haxe.Int64Helper` (deterministic overflow + bitwise semantics on BEAM)
  - `haxe.ds.Map` + `haxe.ds.StringMap`/`IntMap`/`ObjectMap` surfaces (native `%{}` backend; lowered to `Map.*`)
  - `haxe.DynamicAccess` + iterators (typed dynamic map access for JSON/string-key payloads)
  - `Reflect` improvements for string-key JSON maps vs atom-key “object literal” maps
  - `haxe.crypto.Md5`, `haxe.crypto.Sha1`, `haxe.crypto.Sha224`, `haxe.crypto.Sha256` (BEAM-native `:crypto.hash/2` for runtime, pure Haxe fallback for macro context)
  - `UnicodeString` (UTF-8 validation + codepoint/key-value iteration on BEAM strings)
  - `haxe.Http` / `sys.Http` / `haxe.http.HttpBase` (OTP `:httpc` mapping with Haxe callback/state semantics)

## Root Layout (source of truth)

Most stdlib overrides live under `std/` and are injected only for Elixir builds via bootstrap macros.
However, a small subset of overrides may need to be visible **before** bootstrap runs in consumer
installs (because Haxe resolves some std modules very early).

Local roots considered by the gap report:
- `std/` — `.cross.hx` stdlib overrides + extern surfaces
- `std/_std/` — Elixir-only shims (classpath-gated)
- `src/haxe/` — early-resolved overrides needed by consumer installs (example: `haxe.Exception`)

## Definition of Done (incremental)

### Phase 0 — Classification (required first)
- A reference-only module in the gap report is not automatically an override to
  add. First classify it as one of:
  - upstream fallback works through the official Haxe stdlib; add tests/docs or
    tracking only, not a duplicate local file
  - BEAM-specific override needed for correct semantics or idiomatic generated
    Elixir
  - unsupported/fail-fast on the Elixir target, with diagnostics and docs
- Do not copy an unchanged upstream stdlib file into `std/`, `std/_std/`, or
  `src/haxe/` just to reduce the missing count.
- If an upstream-fallback module needs confidence, add a Haxe-authored ExUnit
  or upstream `unitstd` fixture and track the classification in Beads.

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
- Focused command:
  - `npm run test:haxe-exunit-stdlib`
- Primary command (fast CI-friendly):
  - `npm run test:mix-fast`

## Priority / sequencing (task-ready)

The gap report is large; we focus on the smallest set that unlocks real-world libraries quickly while avoiding semantic traps.

### Phase 0 — Parity harness + conventions (done)

**Task: “Stdlib runtime parity harness (Haxe→ExUnit)”**
- Status: implemented. The focused command is `npm run test:haxe-exunit-stdlib`,
  and the CI `Tests` job runs the same lane.
- Convention for stdlib runtime tests:
  - One test module per stdlib module touched (fast, deterministic).
  - Each module’s task must include at least one runtime test that exercises sharp edges.
- Coverage: tests compile from Haxe and run on BEAM in CI; the command is
  documented in `package.json`, `docs/02-user-guide/exunit-testing.md`, and
  `docs/03-compiler-development/TESTING_INFRASTRUCTURE.md`.

Notes learned from early parity work:
- Prefer semantic tests that exercise real BEAM behaviors (immutability, exceptions, key types) rather than relying on print-shape snapshots alone.
- Avoid introducing generic variable binders inside `__elixir__()` snippets (e.g. `x = ...`), since injected bindings occur in the caller’s scope and can clobber user variables after inlining. Use descriptive `reflaxe_*` binders or avoid binding entirely.

Suggested command coverage:
- Snapshot layer: `make -C test summary`
- Runtime layer (stdlib-focused): `npm run test:haxe-exunit-stdlib`

### Phase 1 — Map family parity (high leverage; removes gotchas)

Goal: make `Map` usage predictable and eliminate “native map vs Haxe map” traps without forcing conversions.

**Task: `haxe.ds.StringMap` (native `%{}` backend)**
- Implement/override so `get/set/exists/remove/keys/iterator` map to Elixir-native `Map.*`.
- Runtime tests: missing key, overwrite, deletion, iteration.

**Task: `haxe.ds.IntMap` (native `%{}` backend)**
- Same, with integer keys.
- Runtime tests for negative keys, key equality, iteration.

**Task: `haxe.ds.ObjectMap` decision (explicit, separate)**
- Decision: intentionally unsupported for Elixir output until there is a real identity-key runtime.
- Haxe’s object identity does not translate cleanly to BEAM structural terms, so the compiler rejects ObjectMap construction/calls instead of lowering them to `%{}` and silently merging distinct-but-equal objects.
- Future implementation path: identity tokens/wrappers plus tests proving distinct objects with equal fields remain distinct keys.

**Task: `Map<K,V>` dispatch rules (Elixir target)**
- Ensure `Map<K,V>` chooses the correct backing implementation (StringMap/IntMap/…).
- Ensure generated Elixir stays idiomatic (no wrapper allocations).

### Phase 2 — Core “ecosystem blockers” (small set; big payoff)

**Task: `haxe.CallStack`**
- Status: implemented for BEAM stack capture/formatting and integrated with generated `try/catch` plus `haxe.Exception.details()`.
- Contract: `callStack()` captures `Process.info(self(), :current_stacktrace)`; generated rescues save `__STACKTRACE__` so `exceptionStack()` can return the last caught stack.
- Coverage: `test/snapshot/stdlib/haxe_callstack` and Haxe-authored ExUnit runtime tests in `test:haxe-exunit-stdlib`.

**Task: `haxe.Int64`**
- Status: implemented for deterministic 64-bit wrapping, parsing/printing,
  comparison, high/low construction, shifts, and overflow-aware `toInt`.
- Contract: BEAM integers are arbitrary precision, but the Haxe-facing
  `Int64` abstract normalizes operations back to Haxe's signed 64-bit range so
  portable Haxe code sees wrapping semantics instead of unbounded integers.
- Coverage: Haxe-authored ExUnit runtime tests in `test:haxe-exunit-stdlib`
  cover overflow/underflow wrapping, high/low round-trip, unsigned shift, and
  `toInt` overflow behavior.

**Task cluster: `haxe.Serializer` + `haxe.Unserializer`**
- Status: portable data subset implemented for BEAM (`null`/bool/int/float/string, arrays/lists, native maps/anonymous objects).
- Contract: emits standard Haxe wire prefixes for supported values; map values round-trip as native BEAM maps because target maps do not carry the original Haxe map abstract at runtime.
- Remaining: class instances, enums, `Date`, `Bytes`, object/reference caches, custom `hxSerialize` / `hxUnserialize`, and resolver behavior.
- Coverage: `test/snapshot/stdlib/haxe_serializer_basic` and Haxe-authored ExUnit runtime tests in `test:haxe-exunit-stdlib`.

**Task: `haxe.Template`**
- Status: portable rendering subset implemented with a BEAM-native renderer.
- Contract: supports `::name::` / dotted interpolation, `::if::` / `::else::` / `::end::`, `::foreach::` over lists/maps, and `$$macro(...)` callback execution through `execute(context, macros)`.
- Remaining: full upstream expression-parser parity, including arithmetic/comparison operators inside template expressions.
- Coverage: `test/snapshot/stdlib/haxe_template_basic` and Haxe-authored ExUnit runtime tests in `test:haxe-exunit-stdlib`.

### Phase 3 — `sys.*` integration (BEAM/OTP idioms; explicitly scoped)

The gap report shows remaining `sys.*` gaps are smaller host/process surfaces. `sys.db.*` is intentionally unsupported on the Elixir target; use Ecto instead.
These require careful design on BEAM; we should not “fake” POSIX semantics.

**Task: `haxe.Http` / `sys.Http`**
- Status: implemented with OTP `:httpc` behind `sys.Http`, with `haxe.Http` as the standard sys-target alias.
- Contract: mutable Haxe request/response state is represented by an opaque process-dictionary reference; callback fields (`onStatus`, `onData`, `onBytes`, `onError`) are stored on the generated Elixir struct and invoked through target helpers.
- Supported: `requestUrl`, GET query params, POST form params, explicit request body bytes/data, custom methods (`GET`, `POST`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`, `TRACE`, `PATCH`), response bytes/data, response headers, and duplicate header values.
- Unsupported: caller-supplied sockets, `PROXY`, and multipart `fileTransfer` fail explicitly with target-specific guidance.
- Coverage: `test/snapshot/stdlib/sys_http_basic` includes a generated-runtime smoke against a local TCP server for success, callbacks, duplicate headers, POST, custom PUT, and HTTP error behavior.

**Task cluster: `sys.net.*`**
- Status: implemented for IPv4 `Host`/`Address`, TCP `Socket` via `:gen_tcp`, and UDP `UdpSocket` via `:gen_udp`.
- Contract: Haxe socket mutability is represented with an opaque BEAM reference and process-dictionary-backed state so `connect()`/`bind()`/`listen()` update the socket observed by existing `input`/`output` values.
- Blocking: `setTimeout(seconds)` maps to BEAM millisecond timeouts; `setBlocking(false)` uses zero-timeout read behavior. `Socket.select()` is a compatibility readiness helper, not full POSIX `select(2)`.
- Unsupported: buffer-mutating receive APIs (`Socket.input.readBytes(...)` and `UdpSocket.readFrom(...)`) raise `Error.Custom` on the Elixir target because generated `haxe.io.Bytes` values are immutable maps; implement stateful Bytes or compiler out-parameter support before claiming those semantics.
- Coverage: snapshot coverage for Host/Address and socket surfaces, plus generated-runtime smoke for bind/listen and UDP send.

**Task cluster: `sys.ssl.*`**
- Status: implemented for TLS `Socket` via `:ssl`, opaque DER `Certificate` chains, opaque `Key` containers, digest algorithm constants, and `Digest.make` via `:crypto.hash/2`.
- Contract: SSL sockets use generated target module `SslSocket` to avoid colliding with TCP `Socket`; Haxe-facing code still imports `sys.ssl.Socket`.
- Unsupported: X.509 metadata introspection (`subject`, `issuer`, `commonName`, SAN/date fields), digest sign/verify, SNI certificate callbacks, and buffer-mutating `input.readBytes` fail explicitly with `Error.Custom`.
- Coverage: snapshot coverage for digest and SSL socket surfaces, plus generated-runtime smoke for hashing, socket configuration, certificate-default loading, and fail-fast unsupported APIs.

**Task cluster: `sys.thread.*`**
- Status: implemented as BEAM process/mailbox primitives, not OS threads.
- Contract: `Thread` wraps BEAM pids; message passing uses tagged mailboxes; `Deque`, `Lock`, `Semaphore`, and `Mutex` use small BEAM server processes so state is shared across spawned processes without pretending Elixir maps mutate in place.
- Event loop: callbacks are queued in a BEAM state process but executed by the caller of `progress()`/`loop()`; `repeat` uses a timer process.
- Pools: `FixedThreadPool` uses fixed worker processes; `ElasticThreadPool` spawns per task and bounds concurrency with `Semaphore`.
- Unsupported: POSIX-style `Condition.wait`/`signal`/`broadcast` fail explicitly; use mailboxes, `Deque`, `Lock`, or `Semaphore`.
- Coverage: snapshot coverage plus generated-runtime smoke for thread messages, blocking deque handoff, TLS isolation, event-loop progress, lock/mutex/semaphore behavior, and fixed-pool execution.

**Task cluster: `sys.db.*`**
- Status: intentionally unsupported with compile-time rejection for `sys.db.Connection`, `sys.db.ResultSet`, `sys.db.Mysql`, and `sys.db.Sqlite`.
- Contract: direct Haxe host-driver database APIs are not mapped to BEAM. Generated Elixir applications should use Ecto schemas, changesets, typed queries, Repo externs, or Elixir boundary modules.
- Coverage: `test/snapshot/negative/sys_db_unsupported` verifies the APIs fail to compile instead of emitting runtime stubs.
- Docs: see `docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md` and `docs/07-patterns/ECTO_INTEGRATION_PATTERNS.md`.

## Workstreams (proposed order)

1) **Core top-level modules**
   - Done: `EReg`, `DateTools`, `IntIterator`, `List`, `Map`, `UInt`, `UnicodeString`, `Xml`
   - Remaining core-types like `Any`, `Class`, `Enum`, `EnumValue`, and `StdTypes` are typically not override targets

2) **`haxe.io` + core utilities**
   - Done (core building blocks): `haxe.io.BufferInput`, `haxe.io.BytesBuffer`, `haxe.io.BytesInput`, `haxe.io.BytesOutput`, `haxe.io.FPHelper`, `haxe.Json`
   - Done: `haxe.Exception`
   - Done: `haxe.Int32`, `haxe.Int64`, `haxe.Int64Helper`
   - Done: `haxe.CallStack`
   - Done: `haxe.Serializer` / `haxe.Unserializer` portable data subset
   - Done: `haxe.Template` portable rendering subset
   - Next: remaining `haxe.io.*` utilities as-needed

3) **`sys.*` runtime integration**
   - Prioritize: remaining smaller host/process surfaces
   - Guardrails: BEAM/OTP idioms, avoid pretending POSIX semantics exist where they don’t.

4) **Parsers/serializers**
   - Done: `haxe.Template` portable rendering subset
   - Next: expand `haxe.Serializer` / `haxe.Unserializer` beyond the portable data subset if downstream libraries require classes/enums/custom serialization

## Tracking

Create one task per module (or small module cluster) with:
- The reference file(s) used for parity decisions.
- Snapshot(s) added/updated that lock in the intended Elixir shape and semantics.
- A runtime ExUnit test that executes on BEAM for key behavior (avoid “snapshot-only” confidence).

## Future Task Checklist

For new stdlib parity work, open one task per module/cluster, each including:
   - Classification: upstream fallback, BEAM-specific override, unsupported/fail-fast, or docs/tests-only
   - Reference link(s) to `haxe.compilerdev.reference`
   - Snapshots + Haxe-authored ExUnit runtime semantics test(s)
   - WAE criteria: `npm run test:mix-fast`, `npm run test:examples-elixir`, and todo-app QA sentinel

## Task template (copy/paste)

For each module/cluster task:

- Scope: which module(s), which functions are in-scope now (explicit).
- Classification: upstream fallback vs BEAM-specific override vs unsupported/fail-fast.
- Reference: link to `haxe.compilerdev.reference` source file(s) used.
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

## Tracking Epic (copy/paste template)

Title:
- `Stdlib parity vs haxe.compilerdev.reference (phase 1–3)`

Description:
- Goal: close stdlib parity gaps for Haxe→Elixir while keeping output idiomatic and typed.
- Inputs:
  - `docs/08-roadmap/stdlib-parity/gap-report.json`
  - `docs/08-roadmap/stdlib-parity/gap-report.md`
  - `scripts/stdlib-parity-report.sh`
  - Reference repo: `$HAXE_ELIXIR_REFERENCE`
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
