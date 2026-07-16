# Iterator Runtime Model (Elixir target)

This document defines how Haxe iterator APIs are supported on the Elixir target, and why we intentionally keep a small runtime model even though most iteration patterns are compiled to `Enum.*`.

## Background

In idiomatic Reflaxe.Elixir output, `for`/`while` patterns over `Iterable`/`Iterator` are usually rewritten by the AST pipeline to `Enum.*` operations.

However, some stdlib and user code still constructs and calls iterators at runtime, e.g.:

- `it = arr.iterator(); while (it.hasNext()) it.next();`
- generated stdlib helpers that call `*.new/arity` for iterator modules under `--warnings-as-errors` (WAE)

So we must provide a *real* runtime implementation for the iterator modules that can be invoked at runtime.

## Constraint: stateful iterator calling conventions

Haxe iterators are stateful: `next()` advances internal state.

On BEAM/Elixir, persistent data cannot mutate in place. Reflaxe.Elixir therefore uses two iterator strategies depending
on how the iterator is represented.

## Persistent receiver iterators

`IntIterator` is a persistent receiver-backed iterator. Its Haxe API is:

```haxe
iterator.hasNext();
iterator.next();
```

but `next()` mutates `min` and returns the old value. Generated Elixir must return both the updated receiver and the Haxe
method result:

```elixir
{iterator, value} = IntIterator.next(iterator)
```

The caller then rebinds `iterator` in the same Elixir scope before any later `has_next/1` call. This is required for
embedded expressions and repeated calls:

```haxe
iterator.next() + iterator.next();
pair(iterator.next(), iterator.hasNext());
```

Those shapes lower by hoisting the stateful `next()` calls before the surrounding expression, preserving Haxe
left-to-right evaluation order and the updated receiver state.

For `for (value in iterator)` over an `IntIterator`, the compiler lowers the desugared `while (iterator.hasNext())`
shape to a `reduce_while` that threads the iterator through the reducer accumulator and rebinds the outer iterator after
the loop. A second loop over the same iterator therefore sees the exhausted iterator, matching Haxe semantics.

## Runtime-state iterators

Some iterator modules intentionally keep the Haxe surface convention where `next(it)` advances without returning a new
`it`.

## Current runtime strategy

The canonical iterator runtime is implemented in:

- `std/elixir/_std/haxe/iterators/ArrayIterator.hx`
- `std/elixir/_std/haxe/iterators/MapKeyValueIterator.hx`

Both iterators preserve stateful Haxe semantics by storing the current index in the **process dictionary**, keyed by a unique reference created at iterator construction time:

- `ref = make_ref()`
- state key: `{__MODULE__, ref}`
- `Process.get/2` and `Process.put/2` hold the current index

This keeps iterator semantics correct without changing the call sites.

Do not blindly classify these process-dictionary-backed iterators as persistent receiver mutators. Their receiver value is
not what changes; their runtime state changes through the process dictionary.

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

- explicit target-native map values are represented as plain Elixir maps (`%{}`)
- ordinary `Map`/`StringMap`/`IntMap` values currently also use `%{}`, but that
  representation is partial because mutators do not update aliases; the
  managed-collection audit owns the final representation
- tree-backed or custom `IMap` implementations must expose key/value pairs through their own APIs
- runtime helpers must unwrap through `Reflaxe.Elixir.IMap.unwrap/1`

`Reflaxe.Elixir.IMap.unwrap/1` accepts exactly:

- a plain Elixir map (`%{}`), excluding BEAM structs and Reflaxe runtime structs
- a list of `{k,v}` tuples or `%{key: k, value: v}` maps for pre-normalized iterables

It returns a normalized list of `%{key: k, value: v}` maps. Unsupported inputs raise `ArgumentError` instead of silently guessing. This keeps the representation contract centralized and prevents helpers from shape-sniffing arbitrary maps.

When managed ordinary Haxe maps ship, `IMap` needs an explicit typed managed-map
path that snapshots entries through the runtime. A carrier must never be passed
to this native unwrap helper and guessed from its outward term shape.

## Current implementation: native map-backed built-in Haxe maps

The current Elixir target uses native `%{}` maps for these built-in Haxe map surfaces:

- `haxe.ds.Map<K,V>` as the abstract user-facing surface
- `haxe.ds.StringMap<V>`
- `haxe.ds.IntMap<V>`

That implementation avoids boundary allocation, lets generated code call
idiomatic `Map.*` functions, and is easy to inspect. It preserves many
direct-receiver flows. It is **not** the final 1.0 semantic decision: the Haxe
4.3.7 APIs mutate one map object, so another alias must observe `set`, `remove`,
and `clear`. Rebinding one variable to a new `%{}` cannot provide that behavior.

The representation-boundary review therefore distinguishes ordinary mutable
Haxe maps from explicitly target-native immutable maps. The former join the
managed-collection audit; the latter remain raw `%{}` values at
Phoenix/JSON/PubSub and declared extern boundaries. See
`HAXE_REFERENCE_SEMANTICS_AUDIT.md`.

This choice is intentionally scoped:

- `haxe.ds.ObjectMap<K,V>` is currently rejected until an identity-key implementation exists, and
  this is a 1.0 blocker. Haxe ObjectMap expects two distinct object instances with equal fields to
  remain distinct keys; native BEAM maps compare key terms structurally, so lowering ObjectMap to
  `%{}` would silently merge those keys. The selective managed-reference architecture is now accepted
  in `MANAGED_REFERENCE_ABI.md`, but its feasibility, distribution, compiler, lifecycle, and runtime
  gates have not shipped.
- `haxe.ds.BalancedTree` and `haxe.ds.EnumValueMap` remain bootstrap-safe dual-mode surfaces. They exist to satisfy macro/eval and WAE constraints, not because arbitrary tree-backed `IMap` values should be shape-sniffed as native maps.
- Custom `IMap` implementations must use explicit APIs or normalized pair lists at runtime. `Reflaxe.Elixir.IMap.unwrap/1` is the only generic runtime boundary.

Map abstract conversions currently preserve the backing `%{}` when one exists.
Converting a populated `Map<String,V>` to `StringMap<V>`, `Map<Int,V>` to
`IntMap<V>`, or a native-map-backed enum-value map surface is currently a
representation cast rather than allocation of a fresh empty map.

Under current persistent lowering, those conversions do not create a shared
mutable alias: later `set`, `remove`, or `clear` calls update one receiving
binding only, and `copy()` may return the same immutable term. That is an honest
description of current output, not a claim of exact ordinary-Haxe behavior.
The managed map design must define conversion and `copy()` semantics from Haxe
4.3.7 evidence before this section can become a final contract.

Tradeoffs:

- **WAE:** native-map built-ins avoid emitting canonical Haxe stdlib map implementations that can produce Elixir warnings under `--warnings-as-errors`.
- **Macro/eval:** dual-mode modules under `src/haxe/ds` remain required for stdlib classes that eval instantiates during macro compilation.
- **Performance:** `%{}` storage gives O(1)-ish BEAM map operations and avoids conversion at Elixir boundaries. Those benefits do not justify stale aliases for an ordinary Haxe map. Iteration order follows BEAM map semantics and must not be treated as insertion order.
- **Portability:** explicit native maps may rely on persistent BEAM behavior. Shared Haxe code using ordinary `Map` must receive the audited Haxe contract rather than target folklore.

## ObjectMap implementation status

`haxe.ds.ObjectMap` is rejected at compile time on the Elixir target rather than supported with structural semantics.

The rejected structural option would be deceptively convenient because `%{}` already accepts arbitrary BEAM terms as keys, but it would violate ObjectMap's identity contract. For example, two `new Key("same")` objects should occupy two entries even if their fields compare equal; as native BEAM map keys, equivalent generated struct/map terms would collide structurally. That is worse than an unsupported feature because it loses data silently.

The accepted implementation direction is the selective managed-reference ABI in
`MANAGED_REFERENCE_ABI.md`: identity is assigned at object allocation, shared fields live behind the
carrier, and ObjectMap is itself a managed mutable identity map. An identity token added only at map
insertion would not preserve aliases and is forbidden.

The architecture decision does not enable the API. Construction and direct method calls continue to
fail with the current compiler diagnostic until the managed runtime, compiler lowering, lifecycle,
package, and ordinary-Haxe conformance gates are complete.

## Source-of-truth locations

- Canonical runtime: `std/elixir/_std/haxe/iterators/*.hx`
- Canonical `IMap` unwrap API: `std/reflaxe/elixir/IMap.hx`
- `StdHaxeRuntimeOverrideTransforms` no longer owns iterator behavior. If iterator output regresses,
  fix the stdlib/runtime modules rather than adding transformer-side replacement blocks.
