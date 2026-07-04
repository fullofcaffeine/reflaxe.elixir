# Stdlib Support Matrix (Elixir target)

This page describes **how Haxe stdlib support works on the Elixir target**, and what is currently:

- **Overridden / implemented by this repo** (because upstream breaks or is non-idiomatic)
- **Provided by the upstream Haxe stdlib** (and generally expected to work)
- **Not implemented yet** (mostly `sys.*` gaps or “native host” APIs that need BEAM mappings)

This matrix is intentionally practical. For toolchain versions, see `docs/06-guides/SUPPORT_MATRIX.md`.

## How to read this

Reflaxe.Elixir does *not* ship a full fork of Haxe stdlib.

Instead:
- Most modules come from the official Haxe stdlib.
- We provide **selective overrides** in `std/` when needed.
- Some additional modules exist under `std/haxe/**` and `std/sys/**` to provide BEAM-backed behavior.

The canonical local audit command is:

```bash
scripts/stdlib-parity-report.sh --reference /path/to/haxe/std
```

CI parity drift guard (no external reference checkout required):

```bash
npm run guard:stdlib-parity
```

Runtime conformance guard:

```bash
npm run guard:upstream-unitstd
npm run test:haxe-exunit-stdlib
```

## Upstream runtime conformance

Snapshot tests validate the generated Elixir shape. Stdlib runtime conformance
uses checked-in Haxe upstream `unitstd` specs under
`test/upstream_unitstd/upstream/**`, compiles them through Reflaxe.Elixir into
ExUnit, and runs the resulting tests on BEAM.

The coverage manifest is `test/upstream_unitstd/manifest.json`.

- `enabled` / `adapted`: the checked-in fixture is compiled and run by
  `npm run test:haxe-exunit-stdlib`.
- `skipped-target-specific`: an upstream spec exists, but the BEAM semantics or
  adapter support still need explicit triage before enabling it.
- `skipped-unsupported`: the upstream spec targets behavior this Elixir target
  intentionally does not support.
- `no-upstream-spec`: no matching upstream `unitstd` fixture exists, so runtime
  behavior must be covered by local Haxe-authored ExUnit or snapshot/runtime
  tests.

When adding or changing a stdlib override, update this manifest in the same
change. If upstream has a matching `unitstd` spec, prefer enabling/adapting that
fixture; otherwise record the reason and add local runtime coverage where
appropriate. Refresh checked-in enabled, unmodified fixtures from a local Haxe checkout with:

```bash
scripts/sync-upstream-unitstd-specs.sh
```

## Implemented/overridden by Reflaxe.Elixir (core set)

These modules are implemented/overridden in this repo (and covered by snapshot tests where relevant):

Top-level:
- `Array`
- `Date`
- `DateTools`
- `EReg`
- `IntIterator`
- `Lambda`
- `List`
- `Map`
- `Math` (portable Haxe NaN/Infinity support is implemented for constants,
  operators, Math APIs, IEEE byte paths, JSON, Haxe serialization, templates,
  and finite-native ErlangMath boundary diagnostics; the full target contract is
  documented in `docs/05-architecture/HAXE_FLOAT_SPECIAL_VALUES.md`.
  Typed Elixir-first code may use native finite BEAM numeric APIs directly,
  with explicit boundaries for Haxe special floats.)
- `Reflect`
- `Std`
- `String`
- `StringBuf`
- `StringTools`
- `Sys`
- `Type`
- `UInt`
- `UnicodeString` (UTF-8 validation and codepoint iteration)
- `Xml` (parse/print, attributes, child iteration, parent links)

`haxe.*`:
- `haxe.CallStack` (BEAM stack capture/formatting)
- `haxe.DynamicAccess` (Reflect-backed dynamic maps)
- `haxe.Http`
- `haxe.Int64` (signed 64-bit wrapping semantics on BEAM integers)
- `haxe.Int64Helper`
- `haxe.Log`
- `haxe.Serializer` (portable data subset)
- `haxe.Template` (portable rendering subset)
- `haxe.Timer` (BEAM event-loop backed delay/repeat, callback rebinding, stamp/measure)
- `haxe.Unserializer` (portable data subset)
- `haxe.crypto.Adler32`
- `haxe.crypto.BaseCode`
- `haxe.crypto.Base64`
- `haxe.crypto.Crc32`
- `haxe.crypto.Hmac`
- `haxe.crypto.Md5`
- `haxe.crypto.Sha1`
- `haxe.crypto.Sha224`
- `haxe.crypto.Sha256`
- `haxe.ds.ArraySort` (target override lowered to stable `Enum.sort/2` rebinding for local array bindings)
- `haxe.ds.BalancedTree`
- `haxe.ds.EnumValueMap` (bootstrap-safe override under `src/haxe/ds`)
- `haxe.ds.GenericStack` (target override with receiver rebinding for `add`, `pop`, and `remove`; covered by upstream `unitstd` plus local iterator/toString runtime tests)
- `haxe.ds.HashMap` (target override keyed by `hashCode()` with receiver rebinding for `set`, `remove`, and `clear`; covered by local runtime tests)
- `haxe.ds.ListSort` (explicit fail-fast unsupported surface)
- `haxe.ds.Option`
- `haxe.exceptions.ArgumentException` (official stdlib fallback; covered by local runtime tests)
- `haxe.exceptions.NotImplementedException` (official stdlib fallback; covered by local runtime tests)
- `haxe.format.JsonPrinter`
- `haxe.http.HttpBase`
- `haxe.io.BufferInput`
- `haxe.io.Bytes`
- `haxe.io.BytesBuffer`
- `haxe.io.BytesData`
- `haxe.io.BytesInput`
- `haxe.io.BytesOutput`
- `haxe.io.Encoding`
- `haxe.io.Error`
- `haxe.io.Eof`
- `haxe.io.FPHelper`
- `haxe.io.Input`
- `haxe.io.Output`
- `haxe.io.Path`
- `haxe.io.StringInput`
- `haxe.iterators.ArrayIterator`
- `haxe.iterators.ArrayKeyValueIterator`
- `haxe.iterators.HashMapKeyValueIterator` (inline type-compatibility surface for explicit `HashMap` iterator construction)
- `haxe.iterators.MapKeyValueIterator`
- `haxe.iterators.StringIteratorUnicode`
- `haxe.iterators.StringKeyValueIteratorUnicode`

`sys.*` (BEAM mappings):
- `sys.FileStat`
- `sys.FileSystem`
- `sys.Http`
- `sys.io.File`
- `sys.io.FileInput`
- `sys.io.FileOutput`
- `sys.io.Process`
- `sys.io.FileSeek`
- `sys.net.Address`
- `sys.net.Host`
- `sys.net.Socket`
- `sys.net.UdpSocket`
- `sys.ssl.Certificate`
- `sys.ssl.Digest`
- `sys.ssl.DigestAlgorithm`
- `sys.ssl.Key`
- `sys.ssl.Socket`
- `sys.thread.Condition`
- `sys.thread.Deque`
- `sys.thread.ElasticThreadPool`
- `sys.thread.EventLoop`
- `sys.thread.FixedThreadPool`
- `sys.thread.IThreadPool`
- `sys.thread.Lock`
- `sys.thread.Mutex`
- `sys.thread.NoEventLoopException`
- `sys.thread.Semaphore`
- `sys.thread.Thread`
- `sys.thread.ThreadPoolException`
- `sys.thread.Tls`

Notes:
- Iterator modules (`haxe.iterators.ArrayIterator`, `haxe.iterators.MapKeyValueIterator`) now have canonical Elixir-target runtime implementations under `std/haxe/iterators/*.cross.hx` and are no longer transformer-only runtime stubs.
- The AST pipeline still optimizes most loop patterns to idiomatic `Enum.*`; runtime iterators are primarily for manual iterator usage and stdlib/runtime compatibility.
- `UnicodeString.validate` supports `UTF8`; UTF-16/UTF-32 validation fails fast because `haxe.io.Bytes` stores UTF-8 binaries on this target.
- Built-in map surfaces (`haxe.ds.Map`, `StringMap`, `IntMap`) are represented as native Elixir `%{}` maps and lowered to idiomatic `Map.*` operations.
- `haxe.ds.ObjectMap` is intentionally unsupported for Elixir output code for now. Haxe ObjectMap requires object-identity keys, but BEAM map keys are structural terms. The compiler rejects construction and direct method calls instead of silently lowering them to structural `%{}` behavior. See `docs/05-architecture/ITERATOR_RUNTIME_MODEL.md`.
- `haxe.ds.ListSort` is intentionally unsupported for Elixir output code for now. Its API mutates arbitrary linked-node `next`/`prev` fields in place; ordinary BEAM structs/maps are immutable values, so the compiler rejects calls instead of emitting misleading linked-list updates.
- Some exist to avoid invalid Elixir from upstream inline patterns (notably parts of `haxe.io`).

### `haxe.Serializer` / `haxe.Unserializer` BEAM contract

`haxe.Serializer` and `haxe.Unserializer` use the standard Haxe serialization wire prefixes for the portable BEAM data subset.

Supported today:
- nulls, booleans, integers, floats, and strings
- Haxe special floats using standard `k` / `p` / `m` wire tags
- arrays/lists as `a...h`
- native string-key maps and anonymous maps as object records (`o...g`)
- `Serializer.run(value)` / `Unserializer.run(value)`
- instance buffering through `new Serializer(); serialize(...); toString()`

Not yet supported:
- class instances, enum values, `Date`, `haxe.io.Bytes`, `haxe.ds.ObjectMap`, object/reference caches, and custom `hxSerialize` / `hxUnserialize`
- class/enum resolver behavior in `Unserializer`

Notes:
- Native Elixir maps do not carry the original Haxe map abstract type at runtime, so the supported map encoding uses object-record semantics and round-trips to a native map.
- Coverage: `test/snapshot/stdlib/haxe_serializer_basic` locks emitted shape; `test:haxe-exunit-stdlib` covers portable array, native map, and instance-buffer round-trips.

### `haxe.Template` BEAM contract

`haxe.Template` uses a BEAM-native renderer for the portable template subset instead of lowering the upstream mutable parser directly.

Supported today:
- variable interpolation with `::name::` and dotted paths such as `::user.name::`
- `::if expr::...::else::...::end::` where expressions are booleans, null, numbers, quoted strings, negation, or lookups
- `::foreach items::...::end::` over lists and maps
- macro calls such as `$$upper(name)` through the `execute(context, macros)` macro object
- special Float values through `Std.string`-compatible rendering (`NaN`,
  `Infinity`, `-Infinity`) and Haxe-compatible numeric literal parsing

Not yet supported:
- the full upstream expression parser, including arithmetic/comparison operators inside template expressions
- object-identity-sensitive iteration semantics; maps iterate over values in BEAM map order

Notes:
- `Template.globals` remains available and is consulted after the local context stack.
- Missing lookups render as `null`, matching the target's `Std.string(null)` behavior.
- Coverage: `test/snapshot/stdlib/haxe_template_basic` locks emitted shape; `test:haxe-exunit-stdlib` covers interpolation, conditionals, loops, and macros on BEAM.

### `haxe.CallStack` BEAM contract

`haxe.CallStack` maps BEAM stacktrace entries into Haxe `StackItem` values. A BEAM frame such as
`{Module, function, arity, location}` becomes `FilePos(Method(module, function), file, line)`.

Supported today:
- `CallStack.callStack()` captures the current BEAM process stack with `Process.info(self(), :current_stacktrace)`.
- `CallStack.exceptionStack(true)` returns the last rescued Elixir `__STACKTRACE__` saved by generated Haxe `try/catch`.
- `CallStack.exceptionStack(false)` subtracts the current call stack from the saved exception stack, matching Haxe's default API shape.
- `CallStack.toString(stack)`, `copy()`, `subtract()`, and array access are available on the Elixir target.
- `haxe.Exception` now captures a creation stack and includes stack text in `details()`.

Notes:
- BEAM stack frames use Elixir/Erlang module and function names after lowering, so output is target-native rather than source-mapped Haxe locations.
- Coverage: `test/snapshot/stdlib/haxe_callstack` locks emitted shape; `test:haxe-exunit-stdlib` covers runtime stack capture, exception stack capture, formatting, subtraction, and `haxe.Exception.details()`.

### `haxe.Http` / `sys.Http` BEAM contract

`haxe.Http` is the standard sys-target alias to `sys.Http`. The implementation is backed by OTP `:httpc`, not by a custom HTTP parser over `sys.net.Socket`. This keeps the generated code close to BEAM/OTP primitives while preserving the Haxe callback contract.

Supported today:
- `Http.requestUrl(url)` returns the response body or throws the recorded request error.
- `request(?post)` supports GET and form-style POST parameter encoding.
- `customRequest(post, output, null, method)` supports OTP `:httpc` methods `GET`, `POST`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`, `TRACE`, and `PATCH`.
- `setHeader`, `addHeader`, `setParameter`, `addParameter`, `setPostData`, and `setPostBytes` persist through an opaque process-dictionary reference because generated Elixir maps are immutable.
- `onStatus`, `onData`, `onBytes`, and `onError` remain assignable Haxe callback fields. The target runtime stores callbacks as struct fields and invokes them through explicit BEAM helper calls.
- `responseData`, `responseBytes`, `responseHeaders`, and `getResponseHeaderValues` are populated from the OTP response. Duplicate response headers keep the last value in `responseHeaders` and preserve all values through `getResponseHeaderValues`.

Unsupported pieces fail explicitly:
- `customRequest` with a caller-supplied `sys.net.Socket` is not supported; use `sys.net.Socket` directly for manual protocol work.
- `sys.Http.PROXY` is not supported on this target yet; configure an OTP `:httpc` profile or use a typed application HTTP boundary.
- `fileTransfer` / `fileTransfert` multipart uploads are not supported yet; use an Elixir HTTP client boundary for multipart payloads.

Coverage:
- Snapshot/runtime smoke: `test/snapshot/stdlib/sys_http_basic` exercises `requestUrl`, GET query params, POST form params, custom PUT, callbacks, response bytes/data, duplicate headers, and HTTP error callbacks against a tiny local TCP server.

### `sys.net.*` BEAM contract

`sys.net.Host` and `sys.net.Address` support IPv4 host/address values. `Host` resolves names with Erlang `:inet`, stores `ip` as a big-endian IPv4 integer, and converts to `{a, b, c, d}` tuples when socket APIs need BEAM-native addresses.

`sys.net.Socket` maps TCP operations to `:gen_tcp`; `sys.net.UdpSocket` maps UDP operations to `:gen_udp`. Because Haxe socket objects are mutable but generated Elixir values are immutable maps, sockets store mutable runtime state behind an opaque BEAM reference in the current process dictionary. This keeps `connect()`, `bind()`, `listen()`, `accept()`, `input`, and `output` observing the same underlying BEAM socket without pretending Elixir maps mutate in place.

Blocking behavior is implemented with BEAM receive/socket timeouts. `setTimeout(seconds)` sets the timeout in milliseconds; `setBlocking(false)` uses zero-timeout receive behavior for read-style operations. Full POSIX `select(2)` semantics are not promised; `Socket.select()` is a lightweight readiness helper for generated Haxe compatibility.

Unsupported buffer-mutating receive APIs fail explicitly instead of silently losing data: `Socket.input.readBytes(buf, pos, len)` and `UdpSocket.readFrom(buf, pos, len, addr)` currently raise `haxe.io.Error.Custom`. Generated Elixir `haxe.io.Bytes` values are immutable maps, so these APIs need a stateful Bytes backing or compiler-level out-parameter support before they can preserve Haxe’s caller-buffer mutation semantics. Supported paths today are TCP `Socket.read()`/`write()`, `Input.readByte()`, TCP bind/listen/accept/connect endpoint flows, and UDP bind/options/`sendTo()`.

### `sys.ssl.*` BEAM contract

`sys.ssl.Socket` maps TLS sockets to Erlang/OTP `:ssl` and reuses the same opaque socket-reference model as `sys.net.Socket`. The generated target module is `SslSocket` to avoid colliding with `sys.net.Socket`'s generated `Socket` module while preserving the Haxe-facing `sys.ssl.Socket` API.

Supported today:
- `Socket.connect`, `listen`, `accept`, `handshake`, `shutdown`, `peer`, `host`, `setCA`, `setHostname`, `setCertificate`, and `peerCertificate` lower to `:ssl`/`:public_key` surfaces.
- `Certificate.loadFile`, `loadPath`, `fromString`, `loadDefaults`, `add`, `addDER`, and `next` operate on opaque DER certificate chains suitable for `:ssl` CA/cert options.
- `Key.loadFile`, `readPEM`, and `readDER` create opaque key containers for `:ssl` certificate configuration.
- `Digest.make` maps Haxe digest names to `:crypto.hash/2`.

Unsupported pieces fail explicitly with `haxe.io.Error.Custom` instead of pretending full native SSL parity:
- `Certificate.subject`, `issuer`, `commonName`, `altNames`, `notBefore`, and `notAfter` are not implemented yet because Erlang decoded X.509 record shapes are version-sensitive.
- `Digest.sign` and `Digest.verify` are not implemented yet because the generic Haxe `Key` API does not expose signing algorithm/padding semantics precisely enough.
- `Socket.addSNICertificate` is not implemented yet; use `setCertificate` for a single cert/key pair.
- Like TCP sockets, `sys.ssl.Socket.input.readBytes(...)` is unsupported until generated `haxe.io.Bytes` can preserve caller-buffer mutations.

### `sys.thread.*` BEAM contract

`sys.thread.Thread` maps Haxe thread handles to BEAM process identifiers. `Thread.create` spawns a lightweight BEAM process, `Thread.current` wraps `self()`, and `sendMessage`/`readMessage` use tagged BEAM mailbox messages. Haxe's message API is dynamically typed upstream; that is the narrow compatibility exception for this surface.

Synchronization primitives use tiny BEAM server processes instead of process-local mutable fields:
- `Deque<T>` is a shared blocking FIFO/deque server, so producers and consumers in different BEAM processes observe the same queue.
- `Lock` is a counting release/wait primitive. `wait(0)` performs a server-side non-blocking availability check; positive timeouts are milliseconds-backed BEAM receive timeouts.
- `Semaphore` is a counting semaphore with blocking `acquire` and non-blocking/timed `tryAcquire`.
- `Mutex` is re-entrant for the owning BEAM process and queues other processes.
- `Tls<T>` stores values in the current BEAM process dictionary, matching thread-local behavior for spawned Haxe threads.

`EventLoop` is backed by a BEAM state process, but callbacks are drained and executed by the caller of `progress()`/`loop()` rather than inside the storage process. `repeat` uses a BEAM timer process and `cancel` sends that timer a cancel message.

Thread pools are BEAM-shaped:
- `FixedThreadPool` starts a fixed number of worker processes and feeds them through `Deque`.
- `ElasticThreadPool` spawns per task while bounding concurrency with `Semaphore`; `threadsCount` reports `0` because workers are not retained as an OS-thread pool.

Unsupported pieces fail explicitly:
- `Condition.wait`, `signal`, and `broadcast` are not implemented because POSIX condition-variable semantics depend on shared-memory mutation. Use `Thread` messages, `Deque`, `Lock`, or `Semaphore` instead.

## Additional modules shipped under `std/` (not part of upstream std)

These are “extra” modules provided by the library (not present in upstream Haxe stdlib), typically used by Reflaxe.Elixir features or example apps:

- `haxe.ds.OptionTools`
- `haxe.functional.Result` / `haxe.functional.ResultTools`
- `haxe.test.Assert` / `haxe.test.ExUnit` (Haxe-authored ExUnit support)
- `haxe.validation.*` (example-facing typed validation helpers)

## Intentionally Unsupported: `sys.db.*`

`sys.db.Connection`, `sys.db.ResultSet`, `sys.db.Mysql`, and `sys.db.Sqlite` are deliberately rejected at Haxe compile time on the Elixir target.

Why:
- Haxe `sys.db.*` models direct host-driver database access.
- BEAM/Phoenix applications should use Ecto schemas, queries, changesets, migrations, and Repo boundaries.
- Emitting runtime stubs would fail late and would encourage non-idiomatic database code.

Use these supported paths instead:
- `@:schema` and `@:changeset` for Ecto schema modules and changesets.
- `ecto.TypedQuery` / `Ecto.Query` externs for query construction.
- typed repository externs or application boundary modules for `Repo.all`, `Repo.get`, `Repo.insert`, `Repo.update`, and transactions.
- Haxe-authored Ecto migrations where appropriate.

Reference docs:
- `docs/02-user-guide/ECTO_INTEGRATION_PATTERNS.md`
- `docs/04-api-reference/ECTO_API_REFERENCE.md`
- `docs/07-patterns/ECTO_INTEGRATION_PATTERNS.md`

## Upstream stdlib fallback (expected to work)

Most of the remaining Haxe stdlib is used as-is from the installed Haxe toolchain.
In practice, this works well for:

- pure functional-ish code (pattern matching, enums, maps, arrays)
- many `haxe.*` utilities that don’t rely on target-specific host APIs

If a given upstream std module produces invalid/non-idiomatic Elixir, it becomes a candidate for an override.

## Known high-impact gaps (planned parity work)

Core top-level modules like `Any`, `Class`, `Enum`, `EnumValue`, and `StdTypes` are compiler/type-system surfaces rather than normal override targets.

Remaining `sys.*` gaps should be evaluated case-by-case against BEAM/OTP semantics. `sys.db.*` is not a planned direct mapping; use Ecto instead.

Track the ongoing parity roadmap in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)
