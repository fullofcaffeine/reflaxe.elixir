# Haxe Reference-Semantics Audit

Status: **semantic inventory frozen for staged implementation; no managed-reference behavior is
shipped**

Language baseline: Haxe 4.3.7, tag commit
[`e0b355c6be312c1b17382603f018cf52522ec651`](https://github.com/HaxeFoundation/haxe/tree/e0b355c6be312c1b17382603f018cf52522ec651)

Repository review baseline: `7f8218d1368534d0867646d200a952858482b514`

This audit closes the classification gate for the
[selective managed-reference ABI](MANAGED_REFERENCE_ABI.md). It does not implement that ABI. In
particular, ordinary generated classes still use tagged persistent maps, several target stdlib
objects still use process-local state, and `ObjectMap`, runtime `ListSort`, `WeakMap`, managed
closure graphs, and complete graph serialization remain gated.

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

The Elixir code is valid persistent-value code. It is the wrong representation for this ordinary
Haxe `Array`, because Haxe 4.3.7 specifies `push` as modifying that array in place. The same problem
appears with class fields, anonymous records, map specializations, linked collections, byte
storage, builders, stateful iterators, regex match state, and XML nodes.

This does **not** make raw BEAM lists, maps, structs, tuples, or binaries undesirable. They remain
the correct representation for explicitly target-native immutable types and framework boundaries.
The compiler must distinguish those typed contracts from ordinary mutable Haxe APIs before target
shape erases the distinction.

## Evidence method and limits

The audit keeps four kinds of statement separate:

- **Observed**: stated by a pinned Haxe 4.3.7 source/API contract, exercised by official Haxe tests,
  reproduced on a reference target, or directly visible in current generated/runtime code.
- **Inferred**: follows from observed behavior but still needs compiler/runtime regression evidence.
- **Proposed**: an implementation or public API direction that has not shipped.
- **Unknown**: not pinned precisely enough to support a semantic or release claim.

Primary evidence comes from:

1. the exact Haxe 4.3.7 `std/**` sources and API documentation;
2. the exact Haxe 4.3.7 `tests/unit/src/unitstd/**` suite and compiler tests;
3. the repository probe in [`tools/reference_semantics_audit`](../../tools/reference_semantics_audit/README.md),
   executed unchanged on the Haxe interpreter and JavaScript target; and
4. inspection and focused execution of current Reflaxe.Elixir output and target stdlib overrides.

Run the portable alias probe and the non-asserting equality observation matrix with:

```bash
tools/reference_semantics_audit/run.sh
tools/reference_semantics_audit/run-equality-matrix.sh
```

Both reference targets pass the alias probe. Their equality observations agree for the cases in
the matrix below. Two targets are strong corroborating evidence, not a claim that every Haxe target
uses one physical representation. Where Haxe documents target-dependent behavior, this audit keeps
it target-dependent or requires a checked target contract.

The official 4.3.7 sources most directly relevant to this decision are:

- [`Array.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/Array.hx),
  [`ReadOnlyArray.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/ReadOnlyArray.hx),
  and [`Array.unit.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/tests/unit/src/unitstd/Array.unit.hx);
- [`Map.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/Map.hx)
  and [`Map.unit.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/tests/unit/src/unitstd/Map.unit.hx);
- [`List.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/List.hx),
  [`GenericStack.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/GenericStack.hx),
  [`BalancedTree.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/BalancedTree.hx), and
  [`HashMap.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/HashMap.hx);
- [`Bytes.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/io/Bytes.hx),
  [`ArrayBufferView.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/io/ArrayBufferView.hx),
  [`Vector.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/Vector.hx), and their 4.3.7 unitstd fixtures;
- [`StringBuf.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/StringBuf.hx),
  [`BytesBuffer.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/io/BytesBuffer.hx),
  [`Crc32.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/crypto/Crc32.hx), and
  [`Adler32.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/crypto/Adler32.hx);
- [`Xml.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/Xml.hx),
  [`EReg`](https://api.haxe.org/v/4.3.7/EReg.html),
  [`Reflect`](https://api.haxe.org/v/4.3.7/Reflect.html), and
  [`EnumValueTools`](https://api.haxe.org/v/4.3.7/haxe/EnumValueTools.html); and
- [`ObjectMap.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/ObjectMap.hx),
  [`WeakMap.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/WeakMap.hx), and
  [`ListSort.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/ds/ListSort.hx); and
- [`Rest.hx`](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/std/haxe/Rest.hx),
  whose API explicitly makes `Rest.of(Array)` backing sharing target-dependent.

## Frozen internal representation vocabulary

These names describe compiler-owned categories, not promised Haxe metadata or public class names.
Source names such as `@:elixirValue`, `ManagedBox<T>`, or `NativeList<T>` remain provisional until
their implementation task validates the user surface.

| Symbol | Meaning | Runtime form | Default examples |
| --- | --- | --- | --- |
| `MRef(typeId)` | Ordinary reference object with allocation identity and shared fields | Opaque managed handle/lease | ordinary classes, anonymous objects, `Date`, mutable nodes |
| `MCollection(kind,args...)` | Mutable collection or shared backing store | Opaque managed collection/storage handle | `Array`, ordinary map families, `List`, `Bytes`, `Vector` |
| `NValue(layoutId,children...)` | Compiler-owned value with no observable container identity | Raw BEAM scalar/tuple/list/map/struct | scalars, strings, nullary enum tags, checked value records, explicit native immutable collections |
| `NInterop(abiId)` | Externally owned exact target ABI | Raw framework/native BEAM term | Ecto/Phoenix/OTP/JSON values, target exceptions, declared externs |
| `MClosure(codeId,envId)` | Closure or bound method whose receiver/captures are managed graph edges | Compiler-owned traced closure carrier | bound managed methods, stored managed captures |
| `NClosure(abiId,arity)` | Native callable with no hidden managed edge or an explicit callback adapter | Raw BEAM function | proven capture-free functions, declared native callbacks |
| `RVar(id,constraints)` | Representation-polymorphic generic parameter | Compile-time only | pass-through `T`, capability-constrained `T` |
| `RDynamic(domain)` | Bounded union of possible runtime representations | Tagged/discriminated operations when needed | typed `Dynamic`, declared external origins |
| `Conflict(reason)` | A representation use that cannot preserve both contracts | Compile-time diagnostic | native schema used as an identity key without explicit boxing |

The governing rule is:

> A value is managed whenever ordinary Haxe can observe allocation identity, alias-visible
> mutation, identity-key use, reference-preserving reflection/serialization, or lifecycle. A raw
> BEAM term is retained only for a built-in value contract or an explicit checked native boundary
> where those observations are impossible, forbidden, or separately implemented exactly.

Representation is part of the cross-module ABI. Whole-program analysis may erase a proven local
managed allocation, but it may never invent or change a public representation. Portable and
Elixir-first profiles remain advisory authoring/lint inputs and never select semantics.

## Audited surface and implementation ownership

Support states in this table refer to **exact reference semantics**, not whether a module name or a
direct-receiver happy path currently compiles:

- **supported** means alias, identity, lifetime, and boundary evidence is complete for the stated
  surface;
- **partial** means useful operations exist but at least one required alias/lifetime/boundary
  contract is not preserved or not tested;
- **unsupported** means the compiler deliberately diagnoses or the public behavior is deliberately
  withheld; and
- **unknown** means the contract still needs primary evidence and therefore cannot be advertised.

| Haxe surface | Pinned observation | Required representation | Current exact state | Owner |
| --- | --- | --- | --- | --- |
| Ordinary class instance | Field writes are visible through aliases; same allocation compares equal to itself; separate equal-looking allocations are distinct on both reference targets. | `MRef` from allocation | **partial**: tagged-map persistent updates lose general aliases | `haxe.elixir.codex-0yn.10.3.5` |
| Ordinary anonymous object, including `@:structInit` construction | Writable fields share through aliases; syntax/final-looking construction does not remove identity-sensitive reflection or key use. | `MRef` by default; checked `NValue` only by explicit proof | **partial**: general representation is a raw map; local scalarization is not general proof | `.10.3.5`, `.10.3.15` |
| `Array<T>` and a `ReadOnlyArray<T>` view of it | Official API marks mutators as in-place; official unitstd copies an alias before several mutations; the probe covers push, index write, and reverse. Read-only access does not copy the backing array. | `MCollection(Array,T)`; read-only view retains the same carrier with reduced capability | **partial**: persistent list updates/rebinding preserve at most one binding | `.10.3.14.1` |
| `Map<String,V>`, `StringMap<V>`, `Map<Int,V>`, `IntMap<V>` | `set`, `remove`, and `clear` mutate the map object; `copy` is shallow and independently mutable. | Managed native-key map family | **partial**: raw `%{}` updates/rebinding lose aliases | `.10.3.14.2` |
| `Map<Enum,V>`, `EnumValueMap`, `BalancedTree` | Map specialization uses a mutable tree root; writes replace that root inside the same map object; copies later diverge. | Managed enum/tree map family | **partial**: tree/order and alias conformance are incomplete | `.10.3.14.2` |
| `HashMap<K,V>` | Source owns mutable key/value maps; `set`, `remove`, and `clear` mutate; `copy` creates independent maps. | Managed hash map preserving the pinned `hashCode` contract | **partial**: target override and receiver returns do not establish arbitrary aliases | `.10.3.14.2` |
| Object-key `Map` and `ObjectMap` | Keys use object allocation identity; equal-looking allocations stay distinct and field mutation cannot change lookup. | `MCollection(ObjectMap,ManagedIdentity<K>,V)` | **unsupported by design** | `.10.3.6` |
| `WeakMap` | Weak object keys require identity without retaining otherwise unreachable keys. | Collector-integrated managed weak map | **unsupported by design** | `.10.3.8` |
| `List<T>` and `GenericStack<T>` | Head/tail/length/cell state changes through add/push/pop/remove/clear are visible through aliases. | Managed linked collection | **partial**: receiver-return conventions update one binding | `.10.3.14.3` |
| Nodes passed to `ListSort` | Sorting must rewire the original `next`/`prev` fields; external node aliases must see the new links. | `MRef` nodes plus managed writable-field capability | **unsupported by design** | `.10.3.7` |
| `Bytes` | `set`, `blit`, `fill`, and numeric writes mutate one backing store; `sub` copies. | Managed byte storage; explicit native binary is a different boundary type | **partial**: current process-dictionary storage is process-local | `.10.3.14.4` |
| `Vector<T>` | Indexed writes and fill/blit mutate aliases; `copy` creates independent storage. | Managed fixed storage | **partial**: current opaque process-state cell lacks cross-process/lifetime proof | `.10.3.14.4` |
| `ArrayBufferView` and typed views (`UInt8/16/32`, `Int32`, `Float32/64`) | Views retain byte offset/length and intentionally share their source `Bytes`; subarray views share, while documented copies do not. | Managed view descriptor pointing to managed backing storage | **partial**: module tests exist, but complete sharing/process/package evidence does not | `.10.3.14.4` |
| `StringBuf`, `BytesBuffer` | `add*`/clear operations mutate receiver-owned accumulated state; aliases observe later content. | Managed mutable builder | **partial**: direct tests and receiver returns do not prove aliases | `.10.3.14.5` |
| `Crc32`, `Adler32` | Incremental `update` mutates checksum state observed by `get`/equals. | Managed mutable state object | **partial**: value tests exist; alias contract is incomplete | `.10.3.14.5` |
| Array/map/string/range/key-value iterators | `next` advances a receiver-owned cursor; two variables aliasing one iterator share the cursor, while two iterator allocations do not. | Managed cursor or rigorously equivalent shared state | **partial**: many current iterators use process-local `make_ref` state | `.10.3.14.6` |
| `EReg` | `match`/`matchSub` update state later read by `matched*`; state belongs to one regex allocation. | Managed state object; regex engine payload may remain native internally | **partial**: process-local state and module tests do not prove full aliases/lifetime | `.10.3.14.6` |
| `Xml` nodes | Names, values, attributes, parent/child order, detach/reparent, and graph links mutate original node identities. | `MRef` node graph | **partial**: process-dictionary nodes are process-local and graph lifetime is incomplete | `.10.3.14.6` |
| `Date` | Public API is immutable, but two separate equal-timestamp allocations compare unequal while an alias compares equal on both reference targets; a `Date` may be an object identity key. | `MRef` by safe default; a future built-in `NValue` requires proof that every identity operation is preserved | **partial**: value APIs pass, identity/equality/key behavior is not complete | `.10.3.5`, `.10.3.9` |
| `Reflect`, `Type`, RTTI, patterns | Reflection can read/write/copy visible object state; `Reflect.copy` is shallow; class tags, empty allocation, patterns, and guards must retain the original identity. | Representation-dispatched operations | **partial**: current implementation assumes visible maps in important paths | `.10.3.9` |
| `Serializer`, `Unserializer` | Stateful encoders maintain caches; reference-preserving decode must allocate/cache before descent to restore aliases and cycles. | Managed state plus representation-aware graph cache | **partial portable subset; complete graphs unsupported** | `.10.3.9` |
| Bound methods and closures with managed captures | `Reflect.compareMethods` requires the same method and same receiver; stored closures can hide graph edges and cycles. | `MClosure`; proven capture-free callbacks may be `NClosure` | **partial for invocation; managed closure graphs unsupported** | `.10.3.10` |
| `Input`, `Output`, `BytesInput`, `BytesOutput`, HTTP, Timer, sockets, TLS, thread primitives, certificates/keys and resource handles | These objects carry cursor, buffer, request, timeout, callback, ownership, or native-resource state. Exact sharing and transfer may be API- and platform-specific. | Typed `MRef` facade or declared `NInterop`; never inferred from `make_ref` shape | **partial or unknown by family**: several target implementations are process-local | `.10.4` owns API/platform behavior; `.10.3.10` owns managed carrier/process/lifetime integration |
| Ecto/Phoenix/OTP/JSON values, target exceptions, declared externs | Handwritten/framework code requires exact raw BEAM layouts. | `NInterop(abiId)` | **partial descriptors**; current Ecto constructor gap is confirmed below | `.10.3.15` |
| Explicit native immutable lists/maps and checked value records | Updates intentionally return new values; identity-sensitive Haxe uses must be rejected or explicitly boxed. | `NValue` or `NInterop` | **proposed checked contract; not public** | `.10.3.15` |
| Generic `T`, `Dynamic`, separate packages | Pass-through is representation-polymorphic; identity/write/native-layout/equality operations require capabilities that survive separate compilation. | `RVar`, `RDynamic`, versioned manifest | **not implemented** | `.10.3.4`, `.10.3.16` |
| `Rest<T>` and APIs whose 4.3.7 docs explicitly permit target-dependent backing sharing | The portable contract does not promise one alias result; callers must copy when they need isolation. | Dedicated built-in/value descriptor; no invented stronger promise | **unknown for Elixir until classified** | `.10.3.12` |

No reference-sensitive row in this table is currently **supported** end to end. Existing module-runtime
tests are still valuable, but a passing direct call does not upgrade an alias-sensitive row from
partial to supported.

## Current Elixir-target observations

The current compiler visibly emits persistent updates such as:

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

Those forms create valid new BEAM values, but the alias retains its earlier value. The relevant
ownership is distributed across
[`AssignmentBuilder`](../../src/reflaxe/elixir/ast/builders/AssignmentBuilder.hx),
[`CallExprBuilder`](../../src/reflaxe/elixir/ast/builders/CallExprBuilder.hx), and
[`ReceiverReturnConventions`](../../src/reflaxe/elixir/ast/ReceiverReturnConventions.hx).

Other types already use dedicated state, but the implementation boundary matters:

- [`Bytes`](../../std/elixir/_std/haxe/io/Bytes.hx),
  [`Vector`](../../std/elixir/_std/haxe/ds/Vector.hx), iterators, `EReg`, and
  [`Xml`](../../std/elixir/_std/Xml.hx) store state under process-dictionary keys;
- sockets, HTTP, timers, thread utilities, and other handles also use `make_ref` or process-local
  state in several overrides; and
- this can preserve aliases inside one process for selected operations, but it cannot by itself
  establish same-node cross-process sharing, last-lease lifetime, graph edges, package ABI, or
  remote behavior.

These are **partial implementations to audit and migrate**, not evidence that one persistent map or
one process-local key is a production managed-reference ABI.

## Equality contract

The 4.3.7 probe produced the same observations on interpreter and JavaScript:

| Operation | Observed result | Contract consequence |
| --- | --- | --- |
| class, anonymous object, Array, or Date compared with its alias | `true` | Managed carriers use logical allocation identity, not wrapper-term or field equality. |
| two separately allocated classes/anonymous objects/Arrays/Dates with equal visible values | `false` | Structural BEAM equality is invalid for managed objects and mutable collections. |
| nullary enum constructor compared with itself | `true` | A nullary enum tag may remain a native value. |
| `==` on an enum with constructor arguments | compile-time error: use `switch`, `match`, or `Type.enumEq` | Do not invent an ordinary `==` lowering for this source form. |
| `Type.enumEq` or `EnumValueTools.equals` on equal scalar payloads | `true` | These explicit APIs own recursive enum-value comparison. |
| the same APIs on two distinct equal-looking class payloads | `false` | Recursive comparison reaches managed payload identity rather than comparing visible fields structurally. |
| `Dynamic` class aliases/separate allocations | identity-consistent `true`/`false` | Runtime Dynamic equality needs representation dispatch; no map fallback. |
| separate enum values with arguments compared only after erasure to `Dynamic` | `false` on both probes | Preserve the bounded Dynamic contract; do not generalize this one observation into universal enum equality. |
| `Reflect.compareMethods` for the same method and receiver | `true`; a different receiver is `false` | A bound method carries code plus receiver/environment identity. |

The frozen rule is operation-specific:

1. managed objects and collections use logical identity for source operations that permit equality;
2. native scalars and checked values use their declared Haxe/native value contract;
3. explicit recursive APIs such as `Type.enumEq` recurse by descriptor and use identity at managed
   leaves;
4. forbidden source comparisons remain compiler diagnostics;
5. `Dynamic` dispatches over its bounded representation domain; and
6. raw BEAM equality is emitted only when the typed contract proves it is correct.

Numeric edge cases, abstracts that overload equality, and every target-native interop equality
remain owned by their existing typed semantics and the checked-native contract. They are not
silently changed by managed-reference lowering.

## Native-value validation and conversion contract

A class or anonymous record may request raw native value representation only through an explicit
checked contract. Final fields, `@:structInit`, immutable-looking source, module names, paths, or
authoring profiles are not proof. The initial validator must reject at least:

- writable fields, setters, receiver mutation, or partially initialized `this` escape;
- identity equality/key use, `ObjectMap`/`WeakMap`, bound-receiver identity, or mixed hierarchy;
- identity-sensitive reflection, Dynamic writes, empty allocation, or reference-cache serialization;
- cyclic/alias-restoring value serialization claims;
- an unrestricted `Dynamic` or generic escape that loses the declared representation; and
- an exported layout whose package ABI/version is absent or incompatible.

Crossing the managed/native boundary is explicit:

| From | To | Allowed operation | Identity and alias result |
| --- | --- | --- | --- |
| managed value | same compatible managed ABI | pass handle/view | preserved |
| managed value | native value or interop ABI | typed snapshot/projection | live sharing is lost according to an explicit tree/graph policy |
| native value/interop | managed box | explicit fresh allocation | new identity; the source term is not live-linked |
| native value/interop | same native ABI | pass term | declared value/external semantics |
| unknown handwritten term | managed parameter | declared validated facade/handle only | otherwise rejected |
| managed handle | remote node | explicit graph export/import or deterministic rejection | no implicit live distributed identity |

Two boxes around the same native value are distinct allocations. A late box cannot recover the
identity or alias history of a value that was previously emitted as a structural map. Managed graph
materialization must name whether it rejects repeated identities/cycles, duplicates a tree, or uses
an explicit graph envelope. Hidden runtime IDs never leak into ordinary JSON/framework values.

## Generics, `Dynamic`, and separate compilation

An unconstrained generic is `RVar`, not “native until proven otherwise.” Passing `T` through is
representation-polymorphic. Operations add capabilities to the exported generic ABI:

- `ObjectMap<T,V>` insertion requires `ManagedIdentity<T>`;
- shared structural field writes require a managed writable-field descriptor;
- a native pattern/framework call requires a precise `NativeLayout`/`NInterop` descriptor; and
- generic equality requires the operation-specific equality descriptor.

`Dynamic` records an origin domain. Generated Haxe values can carry managed and native cases;
declared externs carry their native ABI; an untyped handwritten Elixir result is native-unknown
unless a trusted extern says otherwise. Field writes whose domain includes both shared managed
mutation and persistent native update require an explicit writable binding/writeback plan or are
rejected. Arbitrary maps/resources are never recognized as managed by shape.

Every exported type and callable publishes a versioned representation signature for receiver,
parameters, results, fields, callbacks, generic constraints, and required runtime ABI. DCE cannot
change it. A legacy tagged-map module and a managed-handle module fail linking deterministically;
there is no automatic adapter because allocation identity is unrecoverable.

## Confirmed Ecto constructor boundary gap

The checked-in Ecto schema snapshot emits a real schema module, but its `new/0` returns a tagged
ordinary map. The focused gap sentinel loads that exact snapshot with Ecto available and observes:

```text
is_struct(MyApp.User.new(), MyApp.User) == false
Ecto.Changeset.change(MyApp.User.new()) raises FunctionClauseError
```

Reproduce it with:

```bash
tools/reference_semantics_audit/run-ecto-gap.sh
```

This proves the observable mismatch that was previously inferred from a snapshot. It does **not**
justify managing an Ecto schema. The checked-native-interop task must make construction return the
real `%MyApp.User{}` shape, replace the negative sentinel with a positive Ecto API test, and retain
native patterns/updates.

## Implementation graph produced by the audit

The original mutable-collection task was too broad to implement or verify atomically. It now owns
decision-complete children by semantic family:

| Bead | Complete family |
| --- | --- |
| `haxe.elixir.codex-0yn.10.3.14.1` | `Array` mutation, copies, callbacks, and native-list separation |
| `haxe.elixir.codex-0yn.10.3.14.2` | String/Int/enum map specializations, trees, and `HashMap`; object keys remain with `ObjectMap` |
| `haxe.elixir.codex-0yn.10.3.14.3` | `List` and `GenericStack`; `ListSort` remains separate |
| `haxe.elixir.codex-0yn.10.3.14.4` | `Bytes`, `Vector`, `ArrayBufferView`, and typed shared views |
| `haxe.elixir.codex-0yn.10.3.14.5` | `StringBuf`, `BytesBuffer`, `Crc32`, and `Adler32` |
| `haxe.elixir.codex-0yn.10.3.14.6` | stateful iterators, `EReg`, and `Xml` node graphs |

Existing owners remain:

- `.10.3.5` for ordinary object allocation identity and fields;
- `.10.3.6`, `.7`, and `.8` for `ObjectMap`, `ListSort`, and `WeakMap`;
- `.10.3.9` for Dynamic, reflection, RTTI, patterns, and reference-preserving graphs;
- `.10.4` for complete I/O/network/SSL/thread API and platform behavior, coordinated with
  `.10.3.10` for managed closures, carrier process/lifetime behavior, and native operational
  boundaries;
- `.10.3.15` for checked native values and Ecto/Phoenix/OTP/JSON/exception/extern ABIs; and
- `.10.3.16` for generic and cross-package representation ABI.

The parent `.10.3.14` remains the complete-family rollout gate. A child may not claim support for a
type while another mutator in the same type still uses one-binding persistent semantics.

## Remaining unknowns and non-claims

The semantic **classification** is frozen, but several implementation facts intentionally remain
unknown behind their owning gates:

- production runtime language, memory-safety model, collector, barriers, scheduler behavior,
  licensing, packaging, prebuilt policy, upgrades, and platform matrix;
- exact concurrency/atomicity for multi-field snapshots and compound collection operations;
- managed closure carrier/layout and cycles that alternate between objects and callbacks;
- native layout encoding for foreign resources and native composites containing managed leaves;
- remote graph export/import policy beyond deterministic rejection; and
- performance/memory budgets across representative generated applications.

Target- or platform-specific stdlib service APIs also require their own primary contract tests. They
remain **partial or unknown**, never implicitly supported because a process-local prototype exists.
Rows outside this audit's named reference-sensitive scope remain owned by the value-utility
classification task `.10.3.12`; they must be marked unknown until independently classified.

## Release gate

Before any public support claim:

1. typed classification and package descriptors must exist before `ElixirAST` construction and
   before receiver-effect lowering;
2. each complete family above must have ordinary-Haxe alias regressions for every mutator/indexed
   write, not only direct-receiver tests;
3. generated-shape tests must exclude discarded persistent updates, caller rebinding, map/struct
   field access on handles, and runtime calls inside guards;
4. explicit native values must remain raw and conflict diagnostics must be actionable;
5. current `ObjectMap`, `ListSort`, `WeakMap`, closure-graph, and graph-serialization diagnostics or
   limitations stay in force until their independent gates pass; and
6. source/package parity, minimum/primary toolchains, stdlib conformance, full snapshots, WAE,
   examples, handwritten-output, inventory, security/scheduler checks, and bounded sentinel evidence
   must pass for the advertised surface.

The audit therefore closes a planning uncertainty, not a runtime milestone: one compiler and one
typed semantic contract are sufficient, ordinary observable references require allocation-time
shared identity, explicit native boundaries remain raw, and no profile selects another language.
