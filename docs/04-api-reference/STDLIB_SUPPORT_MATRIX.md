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

`sys.*` (BEAM mappings):
- `sys.FileStat`
- `sys.FileSystem`
- `sys.io.File`
- `sys.io.FileInput`
- `sys.io.FileOutput`
- `sys.io.Process`
- `sys.io.FileSeek`

Notes:
- Iterator modules (`haxe.iterators.ArrayIterator`, `haxe.iterators.MapKeyValueIterator`) now have canonical Elixir-target runtime implementations under `std/haxe/iterators/*.cross.hx` and are no longer transformer-only runtime stubs.
- The AST pipeline still optimizes most loop patterns to idiomatic `Enum.*`; runtime iterators are primarily for manual iterator usage and stdlib/runtime compatibility.
- Built-in map surfaces (`haxe.ds.Map`, `StringMap`, `IntMap`) are represented as native Elixir `%{}` maps and lowered to idiomatic `Map.*` operations. `ObjectMap` remains a tracked parity risk until identity-vs-structural-key semantics are pinned down. See `docs/05-architecture/ITERATOR_RUNTIME_MODEL.md`.
- Some exist to avoid invalid Elixir from upstream inline patterns (notably parts of `haxe.io`).

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

Top-level std modules that exist upstream but are not yet overridden/validated specifically for Elixir:

- `Xml` (XML parsing/printing)
- `UnicodeString`, etc.

`sys.*` surfaces that still need BEAM mapping (not exhaustive):

- `sys.net.*` (Socket/UdpSocket/Host)
- `sys.thread.*` (EventLoop, pools)
- `sys.ssl.*`
- `sys.db.*`

Track the ongoing parity roadmap in bd:
- `haxe.elixir-hm47` (stdlib parity roadmap)
