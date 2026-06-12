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
- `Math`
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
- `haxe.Log`
- `haxe.ds.BalancedTree`
- `haxe.ds.EnumValueMap` (bootstrap-safe override under `src/haxe/ds`)
- `haxe.ds.Option`
- `haxe.format.JsonPrinter`
- `haxe.io.BufferInput`
- `haxe.io.Bytes`
- `haxe.io.BytesBuffer`
- `haxe.io.BytesData`
- `haxe.io.BytesInput`
- `haxe.io.BytesOutput`
- `haxe.io.Encoding`
- `haxe.io.Eof`
- `haxe.io.FPHelper`
- `haxe.io.Input`
- `haxe.io.Output`
- `haxe.iterators.ArrayIterator`
- `haxe.iterators.ArrayKeyValueIterator`
- `haxe.iterators.MapKeyValueIterator`
- `haxe.iterators.StringIteratorUnicode`
- `haxe.iterators.StringKeyValueIteratorUnicode`

`sys.*` (BEAM mappings):
- `sys.FileStat`
- `sys.FileSystem`
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
- Some exist to avoid invalid Elixir from upstream inline patterns (notably parts of `haxe.io`).

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

## Upstream stdlib fallback (expected to work)

Most of the remaining Haxe stdlib is used as-is from the installed Haxe toolchain.
In practice, this works well for:

- pure functional-ish code (pattern matching, enums, maps, arrays)
- many `haxe.*` utilities that don’t rely on target-specific host APIs

If a given upstream std module produces invalid/non-idiomatic Elixir, it becomes a candidate for an override.

## Known high-impact gaps (planned parity work)

Core top-level modules like `Any`, `Class`, `Enum`, `EnumValue`, and `StdTypes` are compiler/type-system surfaces rather than normal override targets.

`sys.*` surfaces that still need BEAM mapping (not exhaustive):

- `sys.db.*`

Track the ongoing parity roadmap in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)
