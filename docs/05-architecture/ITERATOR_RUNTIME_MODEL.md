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

## Decision: native map-backed built-in Haxe maps

The Elixir target uses native `%{}` maps as the runtime representation for the built-in Haxe map surfaces where BEAM semantics line up:

- `haxe.ds.Map<K,V>` as the abstract user-facing surface
- `haxe.ds.StringMap<V>`
- `haxe.ds.IntMap<V>`

This is the chosen direction because these map types sit directly on common Phoenix/JSON/PubSub boundaries. Keeping them as `%{}` avoids boundary allocation, lets generated code call idiomatic `Map.*` functions, and makes values easier to inspect from hand-written Elixir.

This choice is intentionally scoped:

- `haxe.ds.ObjectMap<K,V>` is intentionally unsupported for Elixir output code until an identity-key implementation exists. Haxe ObjectMap expects two distinct object instances with equal fields to remain distinct keys; native BEAM maps compare key terms structurally, so lowering ObjectMap to `%{}` would silently merge those keys.
- `haxe.ds.BalancedTree` and `haxe.ds.EnumValueMap` remain bootstrap-safe dual-mode surfaces. They exist to satisfy macro/eval and WAE constraints, not because arbitrary tree-backed `IMap` values should be shape-sniffed as native maps.
- Custom `IMap` implementations must use explicit APIs or normalized pair lists at runtime. `Reflaxe.Elixir.IMap.unwrap/1` is the only generic runtime boundary.

Map abstract conversions preserve the current backing value when one exists. For Elixir output, converting a populated `Map<String,V>` to `StringMap<V>`, `Map<Int,V>` to `IntMap<V>`, or a native-map-backed enum-value map surface must be a representation cast, not allocation of a fresh empty map. The only allocation path is the abstract constructor case where Haxe supplies a null backing value for `new Map()`.

These conversions do not create a mutable alias. Native map operations compile to persistent BEAM map updates that rebind the receiving Haxe variable, so later `set`, `remove`, or `clear` calls on the converted binding do not mutate earlier bindings. `copy()` follows the same value semantics: it can preserve the backing value directly because subsequent writes rebind rather than mutating in place.

Tradeoffs:

- **WAE:** native-map built-ins avoid emitting canonical Haxe stdlib map implementations that can produce Elixir warnings under `--warnings-as-errors`.
- **Macro/eval:** dual-mode modules under `src/haxe/ds` remain required for stdlib classes that eval instantiates during macro compilation.
- **Performance:** `%{}` storage gives O(1)-ish BEAM map operations and avoids conversion at Elixir boundaries. Iteration order follows BEAM map semantics and must not be treated as insertion order.
- **Portability:** this is Elixir-target behavior only. Shared Haxe code should rely on the Haxe `Map` API, not on `%{}` identity.

## ObjectMap decision

`haxe.ds.ObjectMap` is rejected at compile time on the Elixir target rather than supported with structural semantics.

The rejected structural option would be deceptively convenient because `%{}` already accepts arbitrary BEAM terms as keys, but it would violate ObjectMap's identity contract. For example, two `new Key("same")` objects should occupy two entries even if their fields compare equal; as native BEAM map keys, equivalent generated struct/map terms would collide structurally. That is worse than an unsupported feature because it loses data silently.

A future supported implementation needs explicit identity tokens or a wrapper runtime that assigns stable per-object identities and carries those identities through map operations. Until that design exists, construction and direct method calls fail with a compiler diagnostic.

## Source-of-truth locations

- Canonical runtime: `std/haxe/iterators/*.cross.hx`
- Canonical `IMap` unwrap API: `std/reflaxe/elixir/IMap.hx`
- `StdHaxeRuntimeOverrideTransforms` no longer owns iterator behavior. If iterator output regresses,
  fix the stdlib/runtime modules rather than adding transformer-side replacement blocks.
