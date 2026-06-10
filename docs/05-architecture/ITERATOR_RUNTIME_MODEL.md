# Iterator Runtime Model (Elixir target)

This document defines how Haxe iterator APIs are supported on the Elixir target, and why we intentionally keep a small runtime model even though most iteration patterns are compiled to `Enum.*`.

## Background

In idiomatic Reflaxe.Elixir output, `for`/`while` patterns over `Iterable`/`Iterator` are usually rewritten by the AST pipeline to `Enum.*` operations.

However, some stdlib and user code still constructs and calls iterators at runtime, e.g.:

- `it = arr.iterator(); while (it.hasNext()) it.next();`
- generated stdlib helpers that call `*.new/arity` for iterator modules under `--warnings-as-errors` (WAE)

So we must provide a *real* runtime implementation for the iterator modules that can be invoked at runtime.

## Constraint: stateful iterator calling convention

Haxe iterators are stateful: `next()` advances internal state.

On BEAM/Elixir, a purely functional iterator protocol would typically return an updated iterator (`{value, it2}`), but the Haxe surface does not do that.

Therefore, the Elixir target must preserve the calling convention:

- `has_next(it)` does not mutate `it` directly
- `next(it)` advances, without returning a new `it`

## Current runtime strategy

The canonical iterator runtime is implemented in:

- `std/haxe/iterators/ArrayIterator.cross.hx`
- `std/haxe/iterators/MapKeyValueIterator.cross.hx`

Both iterators preserve stateful Haxe semantics by storing the current index in the **process dictionary**, keyed by a unique reference created at iterator construction time:

- `ref = make_ref()`
- state key: `{__MODULE__, ref}`
- `Process.get/2` and `Process.put/2` hold the current index

This keeps iterator semantics correct without changing the call sites.

### Tradeoffs

- **Pros**
  - Preserves Haxe iterator semantics without compiler-wide call-site rewrites.
  - Works for both stdlib-generated and user-written iterator loops.
  - Keeps WAE examples compiling cleanly (required for CI).
- **Cons**
  - Relies on process-local state (not purely functional).
  - Iterator state is tied to the process executing it (which is acceptable for iterator usage patterns).

## Canonical IMap representation and unwrap API

`haxe.iterators.MapKeyValueIterator` takes `haxe.Constraints.IMap<K,V>`. Depending on where the value originates, the runtime may see:

- a plain Elixir map (`%{}`) (common for boundary terms like Phoenix params/payloads)
- a Haxe map implementation (e.g. `BalancedTree`) represented as a struct/map with `__reflaxe_class__` dispatch

The Elixir target contract is:

- native `Map`/`StringMap`/`IntMap` values are represented as plain Elixir maps (`%{}`)
- tree-backed or custom `IMap` implementations must expose key/value pairs through their own APIs
- runtime helpers must unwrap through `Reflaxe.Elixir.IMap.unwrap/1`

`Reflaxe.Elixir.IMap.unwrap/1` accepts exactly:

- a plain Elixir map (`%{}`), excluding BEAM structs and Reflaxe runtime structs
- a list of `{k,v}` tuples or `%{key: k, value: v}` maps for pre-normalized iterables

It returns a normalized list of `%{key: k, value: v}` maps. Unsupported inputs raise `ArgumentError` instead of silently guessing. This keeps the representation contract centralized and prevents helpers from shape-sniffing arbitrary maps.

## Source-of-truth locations

- Canonical runtime: `std/haxe/iterators/*.cross.hx`
- Canonical `IMap` unwrap API: `std/reflaxe/elixir/IMap.hx`
- CI safety-net fallback (narrowed): `src/reflaxe/elixir/ast/transformers/StdHaxeRuntimeOverrideTransforms.hx`
  - fallback only applies when generated iterator modules are incomplete (missing `new/has_next/next`).
