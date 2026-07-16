# Haxe Reference-Semantics Audit

Status: **first tranche confirmed; full stdlib audit still required; no new runtime support shipped**

Audit baseline: Haxe 4.3.7 and Reflaxe.Elixir commit
`7f8218d1368534d0867646d200a952858482b514`

This audit records the semantic correction identified while reviewing the
[selective managed-reference ABI](MANAGED_REFERENCE_ABI.md): shared-reference behavior is not
isolated to `haxe.ds.ObjectMap` or linked-list sorting. Ordinary Haxe classes, anonymous objects,
arrays, maps, lists, buffers, and other mutable objects can expose the same alias requirement.

It is an evidence ledger, not an implementation announcement. The current compiler behavior and
the support matrix remain incomplete until the relevant managed-object and managed-collection
gates pass.

## The issue in one minute

Haxe lets two variables refer to the same mutable array:

```haxe
var values = [1];
var alias = values;

values.push(2);
trace(alias.length); // 2
```

A direct translation to an immutable Elixir list updates only one binding:

```elixir
values = [1]
alias_values = values

values = values ++ [2]
length(alias_values) # 1: stale alias
```

The Elixir code is behaving correctly for an immutable Elixir list. It is the wrong representation
for this ordinary Haxe `Array`, because `push` is specified as modifying that array in place. The
same problem appears with a class field, `Map.set`, `List.add`, `StringBuf.add`, and other mutating
Haxe APIs.

This does **not** mean native BEAM lists and maps are undesirable. They remain the right
representation for explicitly target-native, immutable values and framework boundaries. It means
that the compiler must not silently give an ordinary mutable Haxe type native value semantics merely
because the generated term happens to be a list or map.

## Evidence vocabulary

The audit keeps four categories separate:

- **Observed**: stated by a pinned Haxe 4.3.7 source/API contract, exercised on a Haxe reference
  target, or directly visible in current generated Elixir.
- **Inferred**: a conclusion that follows from those observations but still needs implementation
  and regression evidence.
- **Proposed**: a design direction that is not a public compiler or API contract yet.
- **Unknown**: behavior not yet audited deeply enough to classify.

This distinction matters because a passing happy-path test such as `values.push(2); trace(values)`
proves only that the variable named `values` was updated. It does not prove that a second alias saw
the same mutation.

## First audit tranche

The following source-level probe was exercised with Haxe 4.3.7's interpreter and JavaScript target.
Both reported the expected shared-alias behavior. The same source was then compiled by
Reflaxe.Elixir with the deliberately unsupported `ObjectMap` portion omitted, and its generated
Elixir was inspected and executed.

| Surface | Haxe 4.3.7 evidence | Current Elixir-target evidence | Decision impact |
| --- | --- | --- | --- |
| Ordinary class instance | An alias observes a later field write. | A field write currently becomes a persistent struct/map update. The focused generated run stopped at `class alias did not observe field mutation`. | Managed object by default. |
| Ordinary anonymous object | An alias observes a later field write. | A simple straight-line probe was scalarized successfully, but the general map representation has no allocation identity or shared slot. One optimized case is not general proof. | Managed by default; proven local scalar replacement may erase it later. |
| `Array<T>` | `push`, indexed assignment, and other mutators modify the array instance. | The probe emitted `_ = array ++ [2]`; the alias retained the original list, and the indexed write did not update it. | Managed mutable collection unless a complete proof removes observability. |
| `Map<String,V>`, `StringMap<V>`, `IntMap<V>` | `set` and `clear` mutate the map object; aliases on interpreter and JavaScript observed the changes. | The probe emitted discarded `Map.put` results, so an alias retained the original `%{}`. | Managed mutable collection for ordinary Haxe map APIs. |
| `haxe.ds.List<T>` | `add`, `push`, `pop`, `remove`, and `clear` update the list's internal state. | Receiver rebinding updates one lexical variable. A previously copied alias retains the old snapshot. | Managed collection/object; receiver rebinding alone is insufficient. |
| `haxe.ds.GenericStack<T>` | `add`, `pop`, and `remove` mutate the stack. | The current receiver-return convention can update one caller binding but not every alias. | Managed collection/object candidate. |
| `StringBuf` and `haxe.io.BytesBuffer` | `add*` methods mutate the buffer; aliases observed the appended data on reference targets. | Current generated calls can discard the returned updated receiver, and aliases retain earlier state. | Managed mutable object candidates. |
| `haxe.ds.Vector<T>` | Indexed writes are visible through aliases. | The target already has special process-local backing cells. That dedicated representation must be audited rather than replaced based only on this broader result. | Shared-storage requirement confirmed; exact target classification still under review. |
| `haxe.ds.ObjectMap<K,V>` | Separate equal-looking allocations are distinct keys, and key-field mutation does not change lookup. | Correctly rejected today; structural `%{}` keys would merge identities or make lookup field-dependent. | Managed identity map after its complete gate. |

Primary Haxe 4.3.7 sources for this tranche:

- [`Array`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/Array.hx)
- [`Map`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/Map.hx),
  [`StringMap`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/StringMap.hx), and
  [`IntMap`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/IntMap.hx)
- [`List`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/List.hx) and
  [`GenericStack`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/GenericStack.hx)
- [`StringBuf`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/StringBuf.hx) and
  [`BytesBuffer`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/io/BytesBuffer.hx)
- [`Vector`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/Vector.hx)
- [`ObjectMap`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/ObjectMap.hx)

The Haxe manual also documents [array mutation](https://haxe.org/manual/std-Array.html) and writable
[anonymous-structure fields](https://haxe.org/manual/types-anonymous-structure.html).

## What was directly observed in current output

These simplified forms appeared in the generated Elixir from the audit probe:

```elixir
object = Box.new(1)
object_alias = object
_ = %{object | value: 2}

array = [1]
array_alias = array
_ = array ++ [2]

map = %{}
map_alias = map
_ = Map.put(map, "answer", 42)
```

Each update creates a valid new BEAM value, but the new value is either discarded or assigned only
to the receiver's current lexical binding. `object_alias`, `array_alias`, and `map_alias` still hold
the earlier values.

The existing receiver-return machinery is useful for explicitly persistent/native APIs and some
single-binding flows. It is not evidence of shared Haxe reference semantics. Adding more
same-scope rebinding cannot update an arbitrary number of aliases stored in fields, closures,
collections, or other modules.

## Architecture conclusion

**Inferred with high confidence:** the managed boundary must cover every ordinary Haxe type whose
pinned contract makes allocation identity or alias-visible mutation observable. It cannot be a
special wrapper added only for `ObjectMap` or `ListSort`.

That leads to one compiler with typed representations:

- ordinary Haxe reference objects and audited mutable collections use managed shared storage;
- scalars and compiler-owned value types remain native values;
- Ecto, Phoenix, OTP, JSON, exception, and declared extern boundaries retain their exact native
  BEAM shapes;
- explicitly target-native immutable collections remain native values;
- generic and `Dynamic` operations carry or check the capabilities they require; and
- local analysis may remove a managed allocation only after proving that identity, aliases,
  reflection, callbacks, exceptions, and escape cannot expose it.

Portable and Elixir-first remain authoring profiles. They may guide API choice and future warnings,
but they never make the same ordinary Haxe mutation shared in one build and persistent in another.

### Confidence and limits

| Conclusion | Confidence | Reason |
| --- | ---: | --- |
| One compiler with typed representations is sufficient; two semantic modes are unnecessary | High | Representation can be part of the typed ABI while profiles remain advisory, and mixed apps need both native boundaries and portable objects in one build. |
| Ordinary classes and anonymous objects need allocation-time managed identity by default | High | The alias counterexample is direct, and late wrapping cannot reconstruct allocation history or shared fields. |
| Ordinary mutable Haxe collections belong in the managed audit | High for the confirmed tranche; incomplete for the full stdlib | Haxe 4.3.7 sources and interpreter/JavaScript probes confirm alias-visible writes for the listed types; every remaining type still needs individual classification. |
| Explicit native/value types can preserve idiomatic BEAM shapes | Medium-high | Framework ABIs require raw terms, but the declaration, generic, equality, and conversion contracts are not frozen. |
| The feasibility spike is a production runtime | Low | It proves a narrow lifetime/graph substrate, not fields, closures, a collector with production bounds, packaging, licensing, or compiler integration. |

## Native collection ambiguity that still needs design

Some current `elixir.*` externs use Haxe `Array` or `Map` in their signatures to describe raw BEAM
lists and maps. That source spelling is not enough for the future representation analyzer: an
ordinary Haxe `Array` and an explicitly native immutable list have different mutation and alias
contracts even if both currently erase to a BEAM list.

The implementation therefore needs an ABI-stable typed boundary descriptor or a distinct native
collection type. Exact public names and annotations are **not decided**. Illustrative names such as
`@:elixirValue`, `ManagedBox<T>`, or `NativeList<T>` remain design proposals, not usable or promised
APIs.

## Still unknown or pending

This first tranche does not classify the whole standard library. The next audit must cover at
least:

- every entry in `ReceiverReturnConventions`, including checksums and iterators;
- `HashMap`, `Bytes`, mutable views, regex state, dates, XML nodes, HTTP state, and other objects with
  target-specific backing stores;
- equality for classes, anonymous objects, enums/tuples containing managed leaves, abstracts, and
  `Dynamic`;
- bound methods, closure capture graphs, reflection, RTTI, and constructor escape;
- serializer alias/cache behavior and cyclic graphs;
- generic representation constraints and separately compiled package ABIs;
- the current Ecto schema constructor boundary: the checked-in `new/0` snapshot
  returns a tagged ordinary map rather than the schema struct, but a focused
  Ecto runtime interop test must confirm the observable failure before the
  native-interop correction is treated as verified; and
- concurrency and lifetime behavior for each managed collection kind.

An existing special representation may already satisfy a type's contract, as may be true for some
process-backed values. The audit must test that representation rather than assuming every mutable
surface needs the same runtime object.

## Implementation and release gate

Before semantic scaffolding changes generated output:

1. Complete the pinned Haxe 4.3.7 reference-semantics inventory for the affected public surfaces.
2. Give each type one typed representation owner and record unresolved cases explicitly.
3. Add alias-focused ordinary-Haxe regressions, not only direct-receiver happy paths.
4. Keep current `ObjectMap`, `ListSort`, `WeakMap`, closure-graph, and cyclic-serialization
   diagnostics or limitations in place until their independent gates pass.
5. Do not describe module availability, one passing prototype, or one rebinding test as complete
   semantic support.

The production runtime, public annotations, boxing/projection APIs, and collection layout remain
separate decisions. The feasibility spike proves that one lifetime-aware substrate is possible; it
does not close this language-semantics audit.
