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

We implement stateful advancement by storing the “current index” in the **process dictionary**, keyed by a unique reference created at iterator construction time:

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

## Canonical IMap representation (planned)

`haxe.iterators.MapKeyValueIterator` takes `haxe.Constraints.IMap<K,V>`. Depending on where the value originates, the runtime may see:

- a plain Elixir map (`%{}`) (common for boundary terms like Phoenix params/payloads)
- a Haxe map implementation (e.g. `BalancedTree`) represented as a struct/map with `__reflaxe_class__` dispatch

To avoid “shape sniffing” (checking arbitrary internal fields), the canonical direction is:

- `MapKeyValueIterator.new/1` accepts either:
  - a plain Elixir map (`%{}`), or
  - a list of `{k,v}` pairs
- Non-map `IMap` implementations (tree-backed, custom, etc.) should *produce* pairs and call `new(pairs)` from their own runtime implementation.

Tracking:
- BD task: `haxe.elixir-hm47.23` (child of stdlib parity epic)

## Source-of-truth locations

- Short-term CI safety net: `src/reflaxe/elixir/ast/transformers/StdHaxeRuntimeOverrideTransforms.hx`
- Long-term target: real stdlib/runtime modules under `std/` / `std/_std/` with upstream-matching signatures and runtime tests.
