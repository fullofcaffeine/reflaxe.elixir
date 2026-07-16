# Stdlib Support Matrix (Elixir target)

This page describes **how Haxe stdlib support works on the Elixir target**, and what is currently:

- **Overridden / implemented by this repo** (because upstream breaks or is non-idiomatic)
- **Provided by the upstream Haxe stdlib** (and generally expected to work)
- **Not implemented or only partially implemented yet** (these are now 1.0 blockers when the API
  applies to generated Elixir programs)

This matrix is intentionally practical. For toolchain versions, see `docs/06-guides/SUPPORT_MATRIX.md`.

> [!IMPORTANT]
> Major 1 requires complete support for every applicable public Haxe stdlib API. This page describes
> the current state; it is not yet the final 1.0 contract. A verified official Haxe fallback counts as
> support. A local override file does not count unless its public behavior is tested. See
> [Standard Libraries And Packages](../08-roadmap/stdlib-and-package-ecosystem.md) and Beads epic
> `haxe.elixir.codex-0yn.10`.

## How to read this

Reflaxe.Elixir does *not* ship a full fork of Haxe stdlib.

Instead:
- Most modules come from the official Haxe stdlib.
- We provide **selective upstream stdlib replacements** under `std/elixir/_std/**` when needed.
- Target-owned additions remain under plain `std/**` only when they do not replace an upstream Haxe std namespace. BEAM-backed `sys.*` replacements live under `std/elixir/_std/sys/**` so Reflaxe package builds publish them as `.cross.hx`.

The canonical local audit command is:

```bash
npm run guard:stdlib-api-inventory
```

This regenerates the complete pinned public surface and checks every API row against the reviewed
policy. The generated report below carries the exact count, so this guide cannot quietly become
stale when the pinned Haxe surface changes.
Read the [Haxe stdlib API inventory](../08-roadmap/stdlib-parity/api-inventory.md) for the current
module/API split, plain-language definitions, and open work. To ask the stricter 1.0 question, run:

```bash
npm run guard:stdlib-api-release-ready
```

That release-readiness command must fail while any runtime row is unsupported, partial, unknown, or
lacks exact ordinary-Haxe runtime evidence. The older file-ownership report is still available as
`npm run guard:stdlib-parity`; it tells us which modules have local target code, not which APIs work.

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
- `skipped-unsupported`: legacy/current state for behavior this target rejects. Any applicable public
  runtime API in this state blocks 1.0 and must be implemented and enabled or covered by equivalent
  ordinary-Haxe runtime evidence.
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

## Current classified core set

These modules have an explicit current decision. Many are supported and tested; entries that say
unsupported or subset remain blockers. Most use a local target override; entries marked as official
fallback intentionally use the installed Haxe stdlib unchanged.

Top-level:
- `Array` (current native-list lowering handles many direct-receiver flows, but
  alias-visible mutators and indexed writes are not complete; this blocks 1.0)
- `Date`
- `DateTools`
- `EReg`
- `IntIterator`
- `Lambda`
- `List`
- `Map` (current native-map lowering handles many direct-receiver flows, but
  ordinary Haxe map aliases do not yet share `set`/`remove`/`clear`; this blocks
  1.0)
- `Math` (portable Haxe NaN/Infinity support is implemented for constants,
  operators, Math APIs, IEEE byte paths, JSON, Haxe serialization, templates,
  and finite-native ErlangMath boundary diagnostics; the full target contract is
  documented in `docs/05-architecture/HAXE_FLOAT_SPECIAL_VALUES.md`.
  Typed Elixir-first code may use native finite BEAM numeric APIs directly,
  with explicit boundaries for Haxe special floats.)
- `Reflect` (current native/map-oriented subset; managed fields, identity-aware
  copy, bound methods, and graph behavior remain 1.0 blockers)
- `Std`
- `String`
- `StringBuf` (current receiver-rebinding path is not complete for aliases)
- `StringTools`
- `Sys`
- `Type` (target-specific; typed enum reflection calls used by `haxe.EnumTools`
  and `haxe.EnumFlags` are backed by generated enum metadata; managed class
  tags, instance creation, and empty allocation remain blockers)
- `UInt`
- `UnicodeString` (UTF-8 validation and codepoint iteration)
- `Xml` (parse/print, attributes, child iteration, parent links)

`Date` and `DateTools` use Haxe's normal millisecond timestamp and formatting
contract while storing runtime values as BEAM `%DateTime{}` structs. For
example:

```haxe
var d = Date.fromString("2026-07-07 12:30:45");
var ms = d.getTime();
var text = d.toString();
```

The generated Elixir shape is direct target code, not a wrapper object:

```elixir
date_time = DateTime.from_naive!(naive, "Etc/UTC")
ms = DateTime.to_unix(date_time, :millisecond)
text = Calendar.strftime(date_time, "%Y-%m-%d %H:%M:%S")
```

`Date.fromString` accepts the Haxe stdlib formats `YYYY-MM-DD HH:MM:SS`,
`YYYY-MM-DD`, and `HH:MM:SS`; ISO8601 input remains supported as an
Elixir-target extension for native interop. `Date.getTimezoneOffset()` derives
minutes from `DateTime.utc_offset + DateTime.std_offset`, so UTC-backed Haxe
`Date` values report `0`. `DateTools` remains a Haxe-compatible helper layer
over this `Date` surface, including `format`, `delta`, timestamp unit helpers,
and `makeUtc`.

`EReg` uses Elixir's `Regex` engine while preserving Haxe's first-match versus
global `g` behavior. The official Haxe 4.3.7 runtime fixture verifies matching,
captured groups, `matchedLeft` / `matchedRight` / `matchedPos`, split, capture
replacement and dollar escaping, `map`, and `escape` on BEAM.

```haxe
var words = ~/([a-z]+)/gi;
if (words.match("One TWO")) {
  trace(words.matched(1));
}
```

The generated runtime delegates pattern compilation and matching to BEAM
`Regex`, while retaining the last Haxe match state under a reference unique to
the `EReg` value:

```elixir
regex = Regex.compile!(pattern, "i")
indices = Regex.run(regex, subject, return: :index)
Process.put({:reflaxe_ereg, ref}, match_state)
```

Call `match` / `matchSub` and the subsequent `matched*` methods in the same BEAM
process. This is the natural request/process boundary for Phoenix and OTP code;
last-match state is intentionally process-local rather than shared mutable
state across processes.

`haxe.*`:
- `haxe.CallStack` (BEAM stack capture/formatting)
- `haxe.Constraints` (official stdlib fallback for compile-time `Function` and `IMap` constraints; `IMap` values cross the runtime boundary through `Reflaxe.Elixir.IMap`)
- `haxe.DynamicAccess` (Reflect-backed dynamic maps)
- `haxe.EntryPoint` (currently unsupported Haxe process main-loop bridge and therefore a 1.0 blocker;
  meanwhile use the documented
  `elixir.otp.Application` + `TypeSafeChildSpec` application-wiring shape, `phoenix.*` modules and
  annotations for Phoenix callbacks, or `sys.thread.EventLoop`/`haxe.Timer` for callback scheduling;
  broader supervisor behavior is outside the [OTP Support Contract](OTP_SUPPORT_CONTRACT.md))
- `haxe.EnumFlags` (official abstract fallback; dynamic flag operations use typed `Type.enumIndex` lowering backed by generated enum metadata)
- `haxe.EnumTools` (official extern inline fallback; typed constructor/name/index/equality helpers lower through generated enum metadata)
- `haxe.Http` (current OTP-backed partial implementation; remaining APIs below block 1.0)
- `haxe.Int64` (signed 64-bit wrapping semantics on BEAM integers)
- `haxe.Int64Helper`
- `haxe.Log`
- `haxe.MainLoop` (currently unsupported Haxe process main-loop/event queue bridge and therefore a
  1.0 blocker; meanwhile use the
  documented `elixir.otp.Application` + `TypeSafeChildSpec` application-wiring shape, `phoenix.*`
  modules and annotations for Phoenix callbacks, or `sys.thread.EventLoop`/`haxe.Timer` for callback
  scheduling; broader supervisor behavior is outside the
  [OTP Support Contract](OTP_SUPPORT_CONTRACT.md))
- `haxe.Serializer` (portable data subset; missing behavior below blocks 1.0)
- `haxe.Template` (portable rendering subset; missing behavior below blocks 1.0)
- `haxe.Timer` (BEAM event-loop backed delay/repeat, callback rebinding, stamp/measure)
- `haxe.Unserializer` (portable data subset; missing behavior below blocks 1.0)
- `haxe.ValueException` (official stdlib fallback; explicit value wrapper semantics covered by local runtime tests)
- `haxe.crypto.Adler32`
- `haxe.crypto.BaseCode`
- `haxe.crypto.Base64`
- `haxe.crypto.Crc32`
- `haxe.crypto.Hmac`
- `haxe.crypto.Md5`
- `haxe.crypto.Sha1`
- `haxe.crypto.Sha224`
- `haxe.crypto.Sha256`
- `haxe.ds.ArraySort` (target override lowered to stable `Enum.sort/2` rebinding for local array bindings; aliases are not updated yet)
- `haxe.ds.BalancedTree`
- `haxe.ds.Either` (official stdlib enum fallback; covered by local runtime tests)
- `haxe.ds.EnumValueMap` (bootstrap-safe override under `src/haxe/ds`)
- `haxe.ds.GenericStack` (target override with receiver rebinding for `add`, `pop`, and `remove`; upstream `unitstd` plus local iterator/toString tests pass, but shared-alias mutation is incomplete)
- `haxe.ds.HashMap` (target override keyed by `hashCode()` with receiver rebinding for `set`, `remove`, and `clear`; direct runtime tests pass, but shared-alias mutation still needs pinned evidence)
- `haxe.ds.List` (target override with receiver rebinding for `add`, `push`, `pop`, `remove`, and `clear`; adapted upstream `unitstd` plus local tests pass, but aliases retain old snapshots and therefore block complete parity)
- `haxe.ds.ListSort` (current fail-fast unsupported surface and 1.0 blocker)
- `haxe.ds.Option` (local `@:elixirIdiomatic` target surface with `OptionTools`; covered by local runtime tests)
- `haxe.ds.Vector` (target override with process-local backing cells for fixed-length indexed storage; covered by adapted upstream `unitstd`, local Reflect ordering runtime coverage, and `test/snapshot/stdlib/haxe_ds_vector`; alias/lifetime behavior remains part of the representation audit)
- `haxe.exceptions.ArgumentException` (official stdlib fallback; covered by local runtime tests)
- `haxe.exceptions.NotImplementedException` (official stdlib fallback; covered by local runtime tests)
- `haxe.format.JsonParser` (BEAM-native `Jason.decode!/1` direct parser surface; covered by local runtime tests)
- `haxe.format.JsonPrinter`
- `haxe.http.HttpBase`
- `haxe.io.ArrayBufferView` (official portable implementation; BEAM conformance covered with the typed-array cluster)
- `haxe.io.BufferInput`
- `haxe.io.Bytes`
- `haxe.io.BytesBuffer` (current receiver-rebinding path is not complete for aliases)
- `haxe.io.BytesData`
- `haxe.io.BytesInput`
- `haxe.io.BytesOutput`
- `haxe.io.Encoding`
- `haxe.io.Error`
- `haxe.io.Eof`
- `haxe.io.FPHelper`
- `haxe.io.Float32Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.io.Float64Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.io.Input`
- `haxe.io.Int32Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.io.Mime` (official String enum-abstract fallback; constants and custom values compile to binaries)
- `haxe.io.Output`
- `haxe.io.Path`
- `haxe.io.Scheme` (official String enum-abstract fallback; constants and custom values compile to binaries)
- `haxe.io.StringInput`
- `haxe.io.UInt8Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.io.UInt16Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.io.UInt32Array` (official portable implementation over `haxe.io.Bytes`)
- `haxe.iterators.ArrayIterator`
- `haxe.iterators.ArrayKeyValueIterator`
- `haxe.iterators.HashMapKeyValueIterator` (inline type-compatibility surface for explicit `HashMap` iterator construction)
- `haxe.iterators.MapKeyValueIterator`
- `haxe.iterators.StringIterator` (process-dictionary-backed runtime state for explicit iterator construction)
- `haxe.iterators.StringKeyValueIterator` (process-dictionary-backed runtime state for explicit iterator construction)
- `haxe.iterators.StringIteratorUnicode`
- `haxe.iterators.StringKeyValueIteratorUnicode`

`sys.*` (BEAM mappings):
- `sys.FileStat`
- `sys.FileSystem`
- `sys.Http` (current partial implementation; remaining APIs below block 1.0)
- `sys.io.File`
- `sys.io.FileInput`
- `sys.io.FileOutput`
- `sys.io.Process`
- `sys.io.FileSeek`
- `sys.net.Address`
- `sys.net.Host`
- `sys.net.Socket` (caller-buffer receive behavior below blocks 1.0)
- `sys.net.UdpSocket` (caller-buffer receive behavior below blocks 1.0)
- `sys.ssl.Certificate` (current partial implementation; remaining APIs below block 1.0)
- `sys.ssl.Digest` (current partial implementation; remaining APIs below block 1.0)
- `sys.ssl.DigestAlgorithm`
- `sys.ssl.Key`
- `sys.ssl.Socket` (current partial implementation; remaining APIs below block 1.0)
- `sys.thread.Condition` (current fail-fast partial implementation and 1.0 blocker)
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
- Iterator modules (`haxe.iterators.ArrayIterator`, `haxe.iterators.MapKeyValueIterator`, and the string iterator pair) now have canonical Elixir-target runtime implementations under `std/elixir/_std/haxe/iterators/*.hx` and are no longer transformer-only runtime stubs.
- The AST pipeline still optimizes most loop patterns to idiomatic `Enum.*`; runtime iterators are primarily for manual iterator usage and stdlib/runtime compatibility.
- `UnicodeString.validate` supports `UTF8`; UTF-16/UTF-32 validation currently fails fast because
  `haxe.io.Bytes` stores UTF-8 binaries on this target. The missing encodings block 1.0.
- Built-in map surfaces (`haxe.ds.Map`, `StringMap`, `IntMap`) are currently
  represented as native Elixir `%{}` maps and lowered to idiomatic `Map.*`
  operations. That is the current implementation, not the final parity
  decision: a discarded or one-binding `Map.put` does not update another Haxe
  alias. Ordinary mutable maps are part of the managed-collection audit, while
  explicit target-native immutable maps remain `%{}` values.
- `haxe.ds.List` is currently represented as an ordered immutable snapshot with
  receiver rebinding for mutators; generated Elixir uses `Haxe.Ds.List` so it
  does not collide with Elixir's built-in `List` module. The snapshot/rebind
  path does not update aliases and is therefore partial for 1.0 semantics.
- The same audit covers `Array`, `GenericStack`, `StringBuf`, `BytesBuffer`, and
  other ordinary mutable Haxe objects. See
  `docs/05-architecture/HAXE_REFERENCE_SEMANTICS_AUDIT.md` for observed evidence,
  inferred representation impact, and remaining unknowns.
- `haxe.ds.ObjectMap` is currently unsupported and blocks 1.0. Haxe ObjectMap requires object-identity
  keys, but BEAM map keys are structural terms. The compiler currently rejects construction and
  direct method calls instead of silently lowering them to incorrect `%{}` behavior. See
  `docs/05-architecture/ITERATOR_RUNTIME_MODEL.md`. The implementation direction is accepted in
  `docs/05-architecture/MANAGED_REFERENCE_ABI.md`, but none of its support gates have shipped.
- `haxe.ds.ListSort` is currently unsupported and blocks 1.0. Its API mutates arbitrary linked-node
  `next`/`prev` fields in place; ordinary BEAM structs/maps are immutable values, so the current
  compiler rejects calls instead of emitting misleading linked-list updates. It will be enabled only
  after managed node aliases and original-node mutation have runtime evidence.
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

Not yet supported (all are 1.0 blockers):
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

Not yet supported (all are 1.0 blockers):
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

Current unsupported pieces fail explicitly instead of corrupting data. Each remains a 1.0 blocker:
- `customRequest` with a caller-supplied `sys.net.Socket` is not supported; use `sys.net.Socket` directly for manual protocol work.
- `sys.Http.PROXY` is not supported on this target yet; configure an OTP `:httpc` profile or use a typed application HTTP boundary.
- `fileTransfer` / `fileTransfert` multipart uploads are not supported yet; use an Elixir HTTP client boundary for multipart payloads.

Coverage:
- Snapshot/runtime smoke: `test/snapshot/stdlib/sys_http_basic` exercises `requestUrl`, GET query params, POST form params, custom PUT, callbacks, response bytes/data, duplicate headers, and HTTP error callbacks against a tiny local TCP server.

### `sys.net.*` BEAM contract

`sys.net.Host` and `sys.net.Address` support IPv4 host/address values. `Host` resolves names with Erlang `:inet`, stores `ip` as a big-endian IPv4 integer, and converts to `{a, b, c, d}` tuples when socket APIs need BEAM-native addresses.

`sys.net.Socket` maps TCP operations to `:gen_tcp`; `sys.net.UdpSocket` maps UDP operations to `:gen_udp`. Because Haxe socket objects are mutable but generated Elixir values are immutable maps, sockets store mutable runtime state behind an opaque BEAM reference in the current process dictionary. This keeps `connect()`, `bind()`, `listen()`, `accept()`, `input`, and `output` observing the same underlying BEAM socket without pretending Elixir maps mutate in place.

Blocking behavior is implemented with BEAM receive/socket timeouts. `setTimeout(seconds)` sets the timeout in milliseconds; `setBlocking(false)` uses zero-timeout receive behavior for read-style operations. Full POSIX `select(2)` semantics are not promised; `Socket.select()` is a lightweight readiness helper for generated Haxe compatibility.

Unsupported buffer-mutating receive APIs fail explicitly instead of silently losing data:
`Socket.input.readBytes(buf, pos, len)` and `UdpSocket.readFrom(buf, pos, len, addr)` currently raise
`haxe.io.Error.Custom`. These missing operations block 1.0. Generated Elixir `haxe.io.Bytes` values
are immutable maps, so the APIs need a stateful Bytes backing or compiler-level out-parameter support
before they can preserve Haxe's caller-buffer mutation semantics. Supported paths today are TCP
`Socket.read()`/`write()`, `Input.readByte()`, TCP bind/listen/accept/connect endpoint flows, and UDP
bind/options/`sendTo()`.

### `sys.ssl.*` BEAM contract

`sys.ssl.Socket` maps TLS sockets to Erlang/OTP `:ssl` and reuses the same opaque socket-reference model as `sys.net.Socket`. The generated target module is `SslSocket` to avoid colliding with `sys.net.Socket`'s generated `Socket` module while preserving the Haxe-facing `sys.ssl.Socket` API.

Supported today:
- `Socket.connect`, `listen`, `accept`, `handshake`, `shutdown`, `peer`, `host`, `setCA`, `setHostname`, `setCertificate`, and `peerCertificate` lower to `:ssl`/`:public_key` surfaces.
- `Certificate.loadFile`, `loadPath`, `fromString`, `loadDefaults`, `add`, `addDER`, and `next` operate on opaque DER certificate chains suitable for `:ssl` CA/cert options.
- `Key.loadFile`, `readPEM`, and `readDER` create opaque key containers for `:ssl` certificate configuration.
- `Digest.make` maps Haxe digest names to `:crypto.hash/2`.

Current unsupported pieces fail explicitly with `haxe.io.Error.Custom` instead of pretending full
native SSL parity. Each remains a 1.0 blocker:
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

Current unsupported pieces fail explicitly. Each remains a 1.0 blocker:
- `haxe.EntryPoint` and `haxe.MainLoop` are not BEAM application lifecycle primitives. Direct
  output-code calls or static field reads fail at compile time. Use the documented
  `elixir.otp.Application` + `TypeSafeChildSpec` application-wiring shape, `phoenix.*` modules and
  annotations for Phoenix callbacks, or `sys.thread.EventLoop`/`haxe.Timer` for callback scheduling.
  The [OTP Support Contract](OTP_SUPPORT_CONTRACT.md) lists the exact lifecycle behavior that is
  covered.
- `Condition.wait`, `signal`, and `broadcast` are not implemented because POSIX condition-variable semantics depend on shared-memory mutation. Use `Thread` messages, `Deque`, `Lock`, or `Semaphore` instead.

## Additional modules shipped under `std/` (not part of upstream std)

These are “extra” modules provided by the library (not present in upstream Haxe stdlib), typically used by Reflaxe.Elixir features or example apps:

- `haxe.ds.OptionTools`
- `haxe.functional.Result` / `haxe.functional.ResultTools`
- `haxe.test.Assert` / `haxe.test.ExUnit` (Haxe-authored ExUnit support)
- `haxe.validation.*` (example-facing typed validation helpers)

## Current 1.0 Blocker: `sys.db.*`

`sys.db.Connection`, `sys.db.ResultSet`, `sys.db.Mysql`, and `sys.db.Sqlite` are currently rejected at
Haxe compile time on the Elixir target. That fail-fast behavior is safer than a broken runtime stub,
but it no longer satisfies the planned 1.0 Haxe stdlib contract.

Why:
- Haxe `sys.db.*` models direct host-driver database access.
- BEAM/Phoenix applications should normally use Ecto schemas, queries, changesets, migrations, and
  Repo boundaries.
- Emitting runtime stubs would fail late and would encourage non-idiomatic database code.

Ecto remains the recommended Elixir-first API. The complete-stdlib work must still provide the
portable `sys.db.*` behavior through a real BEAM-compatible implementation before major 1; product
guidance is not a compatibility implementation.

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
- typed enum helper code that goes through `haxe.EnumTools`, `haxe.EnumValueTools`,
  `haxe.EnumFlags`, or `Type.enum*` with a statically known enum type
- many `haxe.*` utilities that don’t rely on target-specific host APIs

If a given upstream std module produces invalid/non-idiomatic Elixir, it becomes a candidate for an override.

`haxe.io.Mime` and `haxe.io.Scheme` are verified examples of this fallback model. Their official
Haxe definitions are `enum abstract ... (String)` declarations, so constants and custom values erase
to ordinary Elixir binaries and do not emit `Mime` or `Scheme` runtime modules. They remain visible
in the module-level gap report because that report inventories local target ownership, not because
the APIs are unsupported.

The typed-buffer cluster (`haxe.io.ArrayBufferView`, `Float32Array`, `Float64Array`, `Int32Array`,
`UInt8Array`, `UInt16Array`, and `UInt32Array`) also uses the official Haxe implementation unchanged.
The portable classes and abstracts layer views over the target `haxe.io.Bytes` implementation, whose
process-local storage preserves shared mutation across `sub`, `subarray`, and `fromBytes` aliases on
immutable BEAM binaries. The compiler groups inlined multi-expression abstract constructors as value
expressions and obtains omitted Haxe defaults from Reflaxe's typed `ClassFuncData`; all seven upstream
`unitstd` specs execute on BEAM, and source/package parity is checked by the haxelib package smoke.

## Known high-impact gaps (planned parity work)

Core top-level modules like `Any`, `Class`, `Enum`, `EnumValue`, and `StdTypes` are compiler/type-system surfaces rather than normal override targets.

Remaining `sys.*` gaps must be evaluated and implemented against BEAM/OTP semantics. `sys.db.*` needs
a real compatibility design for portable Haxe while Ecto remains the preferred Elixir-first surface.

Track the ongoing parity roadmap in bd:
- `haxe.elixir.codex-0yn.10` (complete Haxe stdlib before 1.0)
- `haxe.elixir-hm47` (earlier stdlib parity roadmap and implementation history)
