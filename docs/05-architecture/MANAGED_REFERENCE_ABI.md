# Selective Managed-Reference ABI

Status: **accepted for staged implementation; not yet shipped**

Decision record: `haxe.elixir.codex-0yn.10.3.1`

Initial review baseline: Haxe 4.3.7 and Reflaxe.Elixir commit
`6dc9c0dff1d8ca44c44394c0bd195eda17400ba7`

Representation-boundary review baseline: Reflaxe.Elixir commit
`7f8218d1368534d0867646d200a952858482b514`, including feasibility spike
`e051c53ea879a8bf385f55adaa6581f5291caf0f`

## Thirty-second explanation

Haxe lets two variables point to the same object. If one alias changes the
object, the other must see that change:

```haxe
var account = new Account("Grace");
var alias = account;
account.name = "Ada";
trace(alias.name); // Ada
```

An Elixir map is an immutable value. `%{account | name: "Ada"}` creates a new
map for one binding; `alias` still contains the old map. The planned managed
representation gives the Haxe object one stable hidden identity and shared
field storage, while Elixir variables carry opaque handles to it.

This machinery is not only for `ObjectMap`. Ordinary mutable Haxe arrays, maps,
lists, buffers, and similar objects can expose the same alias requirement:

```haxe
var values = [1];
var alias = values;
values.push(2);
trace(alias.length); // 2
```

Rebinding only `values` to `[1, 2]` would leave `alias` at `[1]`. The
[reference-semantics audit](HAXE_REFERENCE_SEMANTICS_AUDIT.md) records the
confirmed first tranche and the still-unknown types.

This design does not turn every BEAM value into a handle. Explicitly native
Ecto/Phoenix/OTP/JSON values and explicitly target-native immutable lists/maps
stay ordinary BEAM terms. It also does not ship the runtime yet.

## Outcome

Reflaxe.Elixir will use one selective managed-reference ABI for ordinary Haxe
reference objects and mutable collections whenever object identity or
alias-visible mutation can be observed. Explicit BEAM-native values keep their
native representation.

The managed-reference ABI must provide:

- allocation-time identity independent of visible fields;
- shared field storage observed through every alias;
- strong and weak graph edges with reclamation of unreachable cycles;
- managed ordinary Haxe collections whose audited APIs expose shared mutation;
- mutable identity-keyed `haxe.ds.ObjectMap` values;
- same-node process sharing;
- exact field mutation for the official `haxe.ds.ListSort` algorithms;
- representation-aware equality, reflection, RTTI, serialization, inspection,
  JSON, process-message, and interop behavior.

This is a compiler and runtime object-model project. It is not a stdlib-only
override, a second compiler backend, or an application-profile switch.

Managed ordinary objects and collections are also not enabled today.
`ObjectMap`, `ListSort`, `WeakMap`, and complete reference-graph serialization
remain unsupported. Their current diagnostics and documented limitations must
stay in place until the independently gated implementation slices and runtime
evidence pass.

## Why this decision is necessary

The current compiler represents ordinary generated instances and anonymous
structures as persistent BEAM maps or structs. A field assignment creates a new
term and rebinds one Elixir variable. That works for a persistent value receiver,
but it cannot preserve shared Haxe references:

```haxe
var alias = object;
object.value = 2;
trace(alias.value);
```

Rebinding only `object` leaves `alias` pointing at the old term. A hidden
`make_ref()` field would distinguish allocations, but it would not make their
visible fields shared. Adding identity when a value first reaches
`ObjectMap.set()` is also too late: allocation identity has already been lost.

The same counterexample applies to ordinary mutable Haxe collections:

```haxe
var values = [1];
var alias = values;
values.push(2);
trace(alias.length); // 2 under the pinned Haxe contract
```

Lowering `push` as `values = values ++ [2]` preserves one local variable but
not `alias`. `Map.set`, `List.add`, `GenericStack.add`, `StringBuf.add`, and
other audited mutators expose the same distinction. Receiver-return conventions
are therefore a valid mechanism only for explicitly persistent native values or
as a proven local optimization; they are not the object model for an ordinary
shared Haxe value.

The same defect makes exact `ListSort` impossible over persistent maps. Rebuilding
a sorted chain creates new values or updates only local bindings; aliases to the
original nodes retain stale `next` and `prev` links. The upstream algorithm must
mutate the original node identities.

`WeakMap` and cyclic Haxe serialization make lifecycle observable as well.
Process dictionaries, ETS, Agents, and PIDs do not by themselves reclaim an
entry when the last ordinary BEAM term referring to one Haxe object disappears.
An exact design therefore needs a term-lifetime hook plus graph tracing.

The first evidence tranche is documented separately in
[Haxe Reference-Semantics Audit](HAXE_REFERENCE_SEMANTICS_AUDIT.md). It confirms
the broader forcing set without claiming that every stdlib type has already
been classified.

## Representation contract

The compiler will classify representation from typed metadata before building
`ElixirAST`.

| Classification | Runtime representation | Examples |
| --- | --- | --- |
| Managed class | Opaque managed handle | Ordinary generated Haxe class instances |
| Managed anonymous object | Opaque managed handle | Ordinary Haxe anonymous structures |
| Managed mutable collection | Opaque managed handle | Ordinary `Array`, `List`, and Haxe map surfaces whose audited contract exposes alias-visible writes; `ObjectMap`; other confirmed mutable objects |
| Native value | Native BEAM term | numbers, atoms, strings, binaries, tuples, enums/value records, and **explicitly target-native immutable** lists or maps |
| Native interop | Declared native BEAM term | Ecto structs, Phoenix/OTP option maps, JSON payload maps, target exceptions, native externs |
| Managed closure | Compiler-owned closure and traced environment | Bound methods or closures whose captures participate in managed graphs |
| Representation variable or dynamic union | Compile-time descriptor plus checked runtime dispatch where needed | Generic `T`, narrowed `Dynamic`, composites containing managed leaves |
| Representation conflict | Compile-time diagnostic | A native Ecto struct used as an identity key or mutable `ListSort` node without explicit boxing |

Ordinary Haxe classes, anonymous structures, and audited mutable collections
default to the managed ABI at public and cross-module boundaries. A later
optimization may scalarize a proven local, non-escaping allocation whose
identity and mutation cannot be observed, but it must preserve the declared ABI
and pass byte- and runtime-parity evidence. Demand-only wrapping at `ObjectMap`,
`ListSort`, or a later mutator call site is forbidden.

An explicitly native value is not silently promoted. A value cannot
simultaneously remain a raw `%Schema{}` or `%{}` term, have identity independent
of its fields, and expose alias-visible in-place field mutation. Identity-sensitive
use therefore requires a typed boxing or projection API, or a diagnostic.

Classification must be ABI-stable across calls and separately maintained source
boundaries. It must use typed annotations and structured metadata, never module
name fragments, generated paths, app names, or shape guesses. An unknown
`Dynamic` or generic flow into an identity-sensitive operation is conservatively
managed when the ABI permits it; otherwise it is rejected. It never falls back
to structural equality.

Portable and Elixir-first remain authoring profiles over one compiler pipeline.
They do not choose the object backend. Portable code commonly needs managed Haxe
semantics; Elixir-first boundary types commonly declare a native representation.
The same typed expression cannot mean shared mutation in one profile and
persistent copying in another.

The word "native" in this decision describes an explicit typed representation,
not an implementation guessed from coding style. `@:structInit`, `final` fields,
an immutable-looking function body, or an Elixir-first module location do not by
themselves prove that allocation identity is unobservable.

### Generics, `Dynamic`, and package ABI

An unconstrained generic value is not automatically native or managed. A helper
that only passes `T` through can remain representation-polymorphic. An operation
that needs identity, writable shared fields, or an exact native layout adds that
capability to the generic ABI.

For example, a generic helper that inserts `T` into `ObjectMap<T,V>` requires a
managed-identity capability. An ordinary managed class can satisfy it. A native
Ecto struct or checked value record cannot silently satisfy it; the caller must
choose a structural key, use an explicit future box, or change the type contract.

`Dynamic` is a bounded representation union, not “assume this is a map.” Its
origin and typed extern signature narrow the possible representations. Reads,
writes, equality, reflection, and calls dispatch only over defined cases; an
ambiguous mutation or identity operation diagnoses instead of shape-sniffing or
silently boxing.

Every exported type and callable carries a versioned representation signature
across separately compiled modules. That signature includes receiver,
parameters, results, fields, generic constraints, callbacks, and required
runtime ABI. DCE or a distant use may optimize an implementation but may not
change the public representation. Legacy tagged-map class modules cannot link
silently against managed-handle modules; migration requires a clean rebuild and
an explicit ABI version change.

## Semantic invariants

### Allocation and identity

1. Every managed allocation receives a fresh, stable object identity before a
   constructor body runs.
2. Separately allocated objects remain distinct when their visible fields are
   equal.
3. Copying a variable copies a handle. Every alias denotes the same identity.
4. Mutating fields never changes identity.
5. `null` remains `nil`; there is no allocated null handle.
6. Identity, class tags, leases, and heap bookkeeping are not Haxe-visible
   fields.
7. Generated Haxe equality for managed values uses object identity. Native
   scalar and declared value types retain their existing equality contract.

The public wrapper term is opaque. Two outward leases for the same object may be
different BEAM resource terms, so generated equality must use a semantic
`same?/2` operation rather than raw Elixir structural equality.

### Shared fields and evaluation order

1. A managed field write changes the shared heap slot, not only the local
   receiver binding.
2. Receiver, selector, and right-hand side are evaluated once in Haxe
   left-to-right order.
3. Assignment expressions still evaluate to the assigned value.
4. Compound assignment and increment or decrement perform one logical read and
   one logical write against the same identity.
5. Managed receiver methods do not return an updated receiver for caller
   rebinding. Persistent native value receivers continue using the existing
   receiver-return convention.
6. Writes completed before a constructor, setter, comparator, or callback throws
   remain visible. There is no implicit transaction or rollback.

### Ordinary mutable Haxe collections

1. A collection is classified from its pinned Haxe contract, not from the raw
   BEAM term used by today's lowering.
2. If an ordinary Haxe API says a mutator changes the collection, every alias to
   that collection observes the change. Updating only the receiver's current
   lexical binding is insufficient.
3. `Array` indexed writes and mutators, ordinary Haxe `Map` specializations,
   `List`, `GenericStack`, buffers, and other mutable surfaces enter the managed
   set only after their exact API family is audited. The confirmed first tranche
   is recorded in `HAXE_REFERENCE_SEMANTICS_AUDIT.md`.
4. One collection kind must not mix managed and persistent mutation operations:
   partial representation would make alias behavior depend on which method was
   called.
5. An explicitly target-native immutable list or map is a different typed
   contract. Its update operation returns a new value and does not pretend to
   mutate every alias.
6. Current extern signatures that reuse Haxe `Array` or `Map` to describe raw
   native terms need a representation descriptor or distinct typed surface
   before the managed ABI is frozen. Source spelling alone cannot distinguish
   the two contracts.
7. A dedicated existing representation, such as process-backed storage, may
   remain when it independently proves the same alias, lifetime, process, and
   boundary invariants. The architecture requires semantics, not one universal
   storage implementation.

### `ObjectMap`

1. `ObjectMap` is itself a mutable managed object; aliases observe `set`,
   `remove`, and `clear` without receiver rebinding.
2. Entries are keyed only by managed object ID.
3. Key field mutation does not affect lookup.
4. Keys and values remain strongly reachable while present.
5. `copy()` creates a new map identity with shallow-copied entries.
6. Iterators snapshot the entry vector under synchronization and release the
   heap lock before user code runs.
7. `toString()` and inspection expose no IDs, leases, resources, or hidden tags.
8. `Map<K,V>` selects the audited managed map family, including identity-keyed
   behavior when `K` is an object-key type. It never falls back to structural
   `%{}` keys for managed objects.

### `WeakMap`

`WeakMap` keys use managed identity but do not become strong collector roots.
Weak processing is part of heap tracing, not a TTL, periodic cleanup guess, or
undocumented VM-pointer trick. The pinned Haxe 4.3.7 public contract must be
classified before final API and iterator behavior is enabled.

### `ListSort`

1. `sort` and `sortSingleLinked` reuse the original nodes and upstream Haxe
   algorithm.
2. Every `next` and `prev` write is a managed field operation visible to all
   aliases.
3. Sorting remains stable through the upstream `cmp(p, q) <= 0` branch.
4. The final tail has `next == null`.
5. Doubly linked sorting updates every `prev` and sets the returned head's
   `prev` to the tail, matching Haxe 4.3.7.
6. Comparator calls occur outside heap locks and may call generated code,
   mutate carriers, or throw.
7. Primitive heap operations are linearizable; a multi-step sort is not a
   cross-process transaction.

### Reflection and RTTI

1. `Type.typeof`, `Type.getClass`, `Std.isOfType`, virtual dispatch, and
   inheritance obtain kind and class tags from the managed slot.
2. `Type.createInstance` allocates before calling the constructor.
3. `Type.createEmptyInstance` allocates a class-tagged carrier without running a
   constructor.
4. `Reflect.field`, `setField`, `hasField`, `deleteField`, and `fields` dispatch
   to the managed runtime for carriers and retain native behavior for declared
   native maps.
5. `Reflect.copy` creates a new anonymous identity and shallow-copies visible
   fields.
6. Managed fields required by a case or guard are read before guard evaluation;
   runtime calls are never emitted inside Elixir guards.
7. `Reflect.compareMethods` must include method identity and managed receiver
   identity for bound methods.

### Serialization and graph identity

1. Haxe `Serializer` caches managed object identity, not wrapper equality.
2. A cache entry is installed before descending into visible fields or entries.
3. Class, anonymous, enum, custom, and `ObjectMap` wire forms follow the pinned
   Haxe format; hidden runtime state never enters the wire.
4. `Unserializer` allocates an empty carrier or `ObjectMap`, caches it, then
   fills it so aliases and cycles are restored.
5. Custom `hxSerialize` and `hxUnserialize` dispatch uses the carrier class tag
   and intended receiver identity.
6. Raw Erlang external-term serialization of a resource is not the Haxe wire
   contract.
7. JSON materializes visible acyclic data. Cyclic graphs fail clearly or require
   an explicit projection; they never loop or emit hidden IDs.

### Process and lifetime

1. Passing a managed handle between processes on one BEAM node preserves live
   identity and shared state.
2. Individual reads, writes, and map operations are memory-safe and linearizable.
3. Raw handles are node-local. Distributed transport rejects them
   deterministically or uses explicit snapshot export and import; it never
   pretends to provide live cross-node sharing.
4. Unreachable acyclic and cyclic graphs are reclaimable independently of the
   process that allocated them.
5. User callbacks, comparators, inspectors, serializers, and property code run
   with no heap lock held.
6. Collection work is incremental or runs on an appropriate dirty scheduler;
   normal schedulers are not blocked by unbounded native work.

## Runtime direction

The selected direction is a GC-aware managed heap rooted by BEAM NIF resource
leases. The feasibility and distribution gates choose the native language and
whether field and graph storage lives entirely in native memory or behind a
hybrid native-lease/Elixir heap. Those choices may vary without changing the
semantic ABI below. The bounded comparison and its production constraints are
recorded in the [managed-reference feasibility report](MANAGED_REFERENCE_FEASIBILITY.md).

One logical heap exists per loaded runtime instance on a BEAM node. Each slot has
an object ID, kind or class tag, visible fields or collection entries, internal
strong and weak edges, and collector/concurrency metadata.

An outward lease records the heap and object ID and contributes an external root.
When its last BEAM term disappears, the resource destructor removes that root or
queues bounded collection work. Internal graph edges store object IDs, not BEAM
resource terms. Tracing starts from outward roots and follows internal strong
edges, allowing mutually linked and doubly linked cycles to be reclaimed.

Direct and nested handles in lists, tuples, and maps must be internalized as
object-ID edges when stored. Reads reconstruct outward handles as needed.

Closures are a release gate. A closure can capture a carrier and be stored back
inside that carrier, creating an edge invisible to ordinary term traversal.
Exact lifecycle requires compiler-owned capture metadata or managed closure
conversion. Conservatively pinning opaque closures may be safe for a feasibility
experiment, but it is a leak and cannot satisfy the release contract.

The logical target API is:

```elixir
Reflaxe.Elixir.Ref.new_class(class_tag, initial_fields)
Reflaxe.Elixir.Ref.new_object(initial_fields)
Reflaxe.Elixir.Ref.get(ref, field)
Reflaxe.Elixir.Ref.put(ref, field, value)
Reflaxe.Elixir.Ref.same?(left, right)
Reflaxe.Elixir.Ref.class(ref)
Reflaxe.Elixir.Ref.fields(ref)
Reflaxe.Elixir.Ref.materialize(ref, options)

Reflaxe.Elixir.ObjectMap.new()
Reflaxe.Elixir.ObjectMap.set(map, key, value)
Reflaxe.Elixir.ObjectMap.get(map, key)
Reflaxe.Elixir.ObjectMap.remove(map, key)
Reflaxe.Elixir.ObjectMap.clear(map)
Reflaxe.Elixir.ObjectMap.copy(map)
```

Names and arities become stable only in the distribution-ABI decision. The
semantic operations and their results are fixed by this document.

Invalid, stale, wrong-heap, and wrong-node handles raise a documented target
error. They never silently return `nil`, an empty map, or a placeholder value.

## Generated target shape

Given ordinary Haxe:

```haxe
var a = new Key("same");
var b = new Key("same");
var alias = a;
var map = new haxe.ds.ObjectMap<Key, Int>();

map.set(a, 1);
map.set(b, 2);
a.name = "changed";
trace(alias.name);
```

the managed implementation must have this conceptual Elixir shape:

```elixir
a = Reflaxe.Elixir.Ref.new_class(Key, %{name: "same"})
b = Reflaxe.Elixir.Ref.new_class(Key, %{name: "same"})
alias_a = a
map = Reflaxe.Elixir.ObjectMap.new()

_ = Reflaxe.Elixir.ObjectMap.set(map, a, 1)
_ = Reflaxe.Elixir.ObjectMap.set(map, b, 2)
"changed" = Reflaxe.Elixir.Ref.put(a, :name, "changed")
"changed" = Reflaxe.Elixir.Ref.get(alias_a, :name)
```

There is no `map = Map.put(map, ...)`, `%{a | name: ...}`, or rebuilt key.

An ordinary mutable Haxe array has the same alias rule:

```haxe
var values = [1];
var alias = values;
values.push(2);
trace(alias.length); // 2
```

Its conceptual target shape uses shared collection storage:

```elixir
values = Reflaxe.Elixir.ManagedArray.new([1])
alias_values = values
_ = Reflaxe.Elixir.ManagedArray.push(values, 2)
2 = Reflaxe.Elixir.ManagedArray.length(alias_values)
```

`ManagedArray` is an illustrative internal name, not a frozen public module.
An explicitly target-native immutable list instead remains a normal BEAM list
and exposes a persistent API that returns the replacement value. The compiler
does not choose between these meanings from an authoring profile or local code
style.

The upstream `ListSort` body similarly remains generated Haxe control flow, but
link access becomes managed operations:

```elixir
next = Reflaxe.Elixir.Ref.get(node, :next)
_ = Reflaxe.Elixir.Ref.put(tail, :next, node)
_ = Reflaxe.Elixir.Ref.put(node, :prev, tail)
```

No node is allocated inside the sort.

## Compiler ownership and ordering

The staged implementation has these owners:

| Area | Responsibility |
| --- | --- |
| Pre-build analysis | Classify declarations, class types, anonymous shapes, mutable collection kinds, allocations, variables, generics, closures, calls, and native boundaries before AST construction and before DCE can erase public ABI facts |
| Package ABI metadata | Carry versioned representations for exported types, fields, call parameters/results, generic constraints, callbacks, and runtime requirements across separately compiled modules |
| `CompilationContext` | Hold an immutable/shared representation registry plus current expression, variable, function, and closure IDs; child contexts must not reconstruct representation from target shape |
| `ElixirAST` | Carry semantic managed allocation, get, put, equality, dispatch, collection, closure, dynamic, boxing, and materialization operations that cannot be mistaken for native maps |
| Object and constructor builders | Allocate managed objects at birth; retain explicit native literals and structs |
| Field and assignment builders | Emit managed reads/writes with single evaluation; preserve native persistent updates elsewhere; never emit receiver effects for managed values |
| Binary and call builders | Emit identity equality, object-map operations, class-tag dispatch, and exact diagnostics |
| Pattern/control-flow builders | Batch-read carrier fields before patterns and guards while keeping alias binders on the original handle |
| Runtime facade | Validate handles and expose the selected managed heap without leaking implementation fields |
| Printer | Print only lowered ordinary calls and reject surviving semantic nodes |

The planned semantic constructors are conceptually:

```haxe
ERefAlloc(kind, classTag, fields)
ERefGet(target, field)
ERefPut(target, field, value)
ERefSame(left, right)
EManagedCollectionOp(kind, operation, arguments)
EManagedClosure(codeId, environment)
EDynamicManagedOp(domain, operation, arguments)
EManagedBox(typeId, nativeValue)
EMaterialize(projectionId, managedValue)
```

Names remain conceptual until the semantic-scaffolding gate. The important rule
is that managed meaning remains explicit in the IR until a dedicated lowering
step; an ordinary `EMap`, `EField`, `EStructUpdate`, or `EReceiverEffect` must
never carry hidden managed semantics.

### Required ordering

The representation-boundary review found that merely placing
`ManagedReferenceLowering` before several persistent-value transforms is not
enough. The current pass inventory describes bootstrap input as builder output
**after initial receiver-effect lowering**. A managed operation could therefore
already have been turned into caller rebinding before a later managed pass saw
it.

The required order is:

1. Load and validate dependency representation manifests.
2. Run typed representation analysis before AST construction and before DCE
   changes which bodies remain reachable.
3. Preserve representation IDs through TypedExpr preprocessing and cloning.
4. Build semantic managed, native, and dynamic operations directly.
5. Validate that no managed receiver was emitted as native field access,
   `EStructUpdate`, `Map.put`, or `EReceiverEffect`.
6. Legalize managed pattern and guard projections outside target guards.
7. Optionally scalar-replace only proven local, non-escaping managed
   allocations while their identity/effects are still explicit.
8. Run `ManagedReferenceLowering` through the versioned runtime facade.
9. Validate again that no managed target remains in a persistent-value form.
10. Run receiver-effect lowering only for explicitly persistent native values.
11. Run existing passes that assume persistent values, including
    `InstanceFieldLowering`, `ControlFlowStateHoist`, `AssignmentExtraction`,
    `StructUpdateTransform`, and `HaxeMapModuleCallRewrite`.
12. Perform final representation/ABI validation, then let the printer render
    only ordinary lowered target constructs.

Managed-aware builders must therefore never emit `EReceiverEffect`; the order
protects that invariant rather than trying to repair it later. Pass eligibility
follows typed representation metadata, never names, paths, generated module
names, or authoring profiles.

Registry dependency metadata is validation, not a topological scheduler. The
actual registered list must obey this order as well as declaring the dependency,
and an invariant test must prove both.

## Native boundary contract

| Boundary | Contract |
| --- | --- |
| Ecto | Schemas remain real `%Schema{}` terms. Identity-sensitive use diagnoses unless the user explicitly boxes a domain object. |
| Phoenix and OTP | Typed option maps, assigns intended for hand-written code, child specs, and target payloads retain their declared native shapes. |
| JSON | Native decoded maps remain maps. Managed values require explicit visible-field materialization at an encoder boundary. |
| Hand-written Elixir | Uses the documented `Ref` facade or materializes a snapshot. Direct map patterns and `value.field` are not equivalent carrier access. |
| Process messages | Same-node carrier handles preserve live sharing; remote transport snapshots or rejects. |
| Inspection | Displays visible Haxe state with cycle protection and no IDs or resource internals. |

Compiler-inserted materialization is allowed only at a typed, known boundary. A
general automatic conversion would destroy alias identity and is forbidden.

### Conversion semantics

- Passing a managed value through the same compatible managed ABI preserves its
  identity and live aliases.
- Converting a managed graph to a native value is an explicit typed snapshot or
  projection. It must document whether repeated references are rejected,
  duplicated, or represented in a graph envelope; ordinary JSON/Ecto tree
  projections reject cycles.
- Giving a native value a managed identity is an explicit allocation. Two boxes
  around the same `%Schema{}` or map are two different identities, and neither
  is live-linked to the original native term.
- A raw native value is never wrapped automatically at `ObjectMap.set`, a
  generic call, a `Dynamic` operation, or a package boundary.

A future source API may use concepts such as a checked native-value annotation,
a managed box, and typed projection descriptors. Names shown in design reviews
such as `@:elixirValue`, `@:elixirNativeAbi`, `@:elixirManaged`, or
`ManagedBox<T>` are **provisional examples only**. They are not implemented,
accepted public names, or valid guidance for application code today.

Any checked native-value declaration must reject uses that make reference
identity observable: writable shared state, `ObjectMap`/`WeakMap` keys, dynamic
field mutation, identity-preserving graph serialization, constructor escape, or
an incompatible class/interface hierarchy. Final fields or `@:structInit`
syntax alone are not sufficient proof.

## Rejected alternatives

| Alternative | Reason rejected |
| --- | --- |
| Hidden `make_ref()` inside every map | Distinguishes allocations but leaves field state persistent and leaks hidden structure into boundaries unless every consumer filters it |
| Wrap on first `ObjectMap.set` | Allocation identity is already lost and aliases still do not share fields |
| Structural `%{}` ObjectMap | Distinct equal-looking keys collide and key mutation changes structural equality |
| Rebuild a sorted linked list | External aliases retain stale links and node identity changes |
| Process dictionary as the object heap | Process-local, process-lifetime storage cannot model arbitrary same-node sharing or per-object reclamation |
| ETS, Agent, or one process per object without leases | No last-term lifetime hook; entries or processes outlive the final handle |
| Naive resource-per-object graph | Resource terms stored in each other form native reference-count cycles the BEAM collector cannot trace through |
| Arbitrary traversal caps or fail-open defaults | Changes Haxe semantics and hides malformed state rather than solving ownership |
| Fully threaded functional heap | Exact in principle, but requires heap and root state through calls, closures, exceptions, and process boundaries; it is not smaller than the selected ABI |

## Delivery gates

Delivery must remain sliced so a feasibility result or semantic enum cannot be
mistaken for public support. The representation-boundary review adds two
blocking slices that were not explicit in the original task graph: the complete
reference-semantics audit and ordinary mutable Haxe collections. The task graph
now records both slices and their dependencies; neither enables compiler or
runtime behavior by itself.

| Gate | Bead | Completion boundary |
| --- | --- | --- |
| Architecture decision | `haxe.elixir.codex-0yn.10.3.1` | This contract is reviewed; no behavior changes |
| Feasibility | `haxe.elixir.codex-0yn.10.3.2` | Resource leases, tracing, cycles, process behavior, scheduler safety, and package implications are proven in a bounded spike |
| Reference-semantics audit | `haxe.elixir.codex-0yn.10.3.13` | Every ordinary Haxe reference/mutable collection surface in scope has a pinned contract, representation owner, alias regression plan, and explicit unknowns |
| Distribution ABI | `haxe.elixir.codex-0yn.10.3.3` | Native/hybrid design, build, upgrade, license, artifact, and platform contracts are selected |
| Semantic scaffolding | `haxe.elixir.codex-0yn.10.3.4` | Typed classification, package ABI descriptors, generic/dynamic constraints, semantic AST, and pre-receiver-effect invariants exist with byte-for-byte output parity |
| Managed core | `haxe.elixir.codex-0yn.10.3.5` | Allocation identity and alias-visible fields work for managed classes and anonymous objects |
| Ordinary mutable Haxe collections | `haxe.elixir.codex-0yn.10.3.14` | Audited `Array`, map, list, buffer, and other mutable families preserve aliases end to end while explicit native collections remain raw values |
| ObjectMap | `haxe.elixir.codex-0yn.10.3.6` | Complete identity-keyed mutable map behavior |
| ListSort | `haxe.elixir.codex-0yn.10.3.7` | Original-node stable singly and doubly linked sorting |
| WeakMap | `haxe.elixir.codex-0yn.10.3.8` | Collector-integrated weak identity keys |
| Reflection and graphs | `haxe.elixir.codex-0yn.10.3.9` | RTTI, reflection, Haxe serialization, aliases, and direct cycles |
| Operational hardening | `haxe.elixir.codex-0yn.10.3.10` | Closure edges, GC stress, process, remote, interop, DCE, JSON, inspection, and upgrades |
| Release evidence | `haxe.elixir.codex-0yn.10.3.11` | Inventory rows change only after complete source/package and runtime evidence |
| Other `.10.3` APIs | `haxe.elixir.codex-0yn.10.3.12` | Value-semantic utility rows are classified and split independently |

The distribution-ABI gate also depends on the qualified licensing decision in
`haxe.elixir.codex-0yn.4`. Engineering documentation must not invent the legal
policy for a shipped native runtime.

## Evidence required before support claims

Each public operation is tested through ordinary typed Haxe source. Target
injection, direct heap calls, `untyped`, and raw Elixir do not substitute for the
source-language path.

At minimum, the managed-reference project must prove:

- distinct equal-looking class and anonymous allocations;
- alias-visible field and method mutation;
- alias-visible mutation for every audited ordinary Haxe collection operation,
  including nested aliases and collections stored in managed fields;
- unchanged raw output and persistent behavior for explicitly target-native
  immutable collection APIs;
- stable identity after mutation and through shallow copies;
- constructor escape and exception behavior;
- ObjectMap aliases, copy divergence, iteration, mutation, cycles, and liveness;
- stable original-node singly and doubly linked sorting;
- weak-key reclamation;
- visible-only reflection, class tags, and empty allocation;
- shared subgraphs, self-cycles, mutual cycles, custom serialization, and wire
  output without hidden state;
- closure cycles and nested carrier edges;
- representation-aware generic constraints, `Dynamic` narrowing, mixed
  composites, bound methods, and separately compiled package ABI mismatches;
- same-node process sharing and concurrent primitive operations;
- deterministic remote rejection and explicit snapshot import/export;
- acyclic and cyclic reclamation under long-lived process stress;
- unchanged Ecto, Phoenix, OTP, JSON, exception, and extern target shapes;
- installed-package/source parity on minimum and primary toolchains.

The final release-evidence gate runs the inventory guards, Haxe-authored stdlib
runtime suite, upstream unitstd guard, all snapshot chunks, handwritten-output
corpus, examples compile/output/WAE/runtime suites, package smoke, and bounded
todo-app sentinel. Native code also needs the selected security and scheduler
checks.

Happy-path receiver tests are not enough: every mutable surface needs at least
one test that copies the receiver to another variable before mutation and reads
through the alias afterward. Generated-shape assertions must also prove that a
managed mutation was not lowered to caller rebinding or a discarded persistent
update.

## Consequences

The decision preserves exact portable Haxe behavior and makes the remaining
identity-dependent 1.0 promise achievable. It also introduces material costs:

- managed field access is more expensive than direct map access;
- carrier output needs visible runtime helpers and is less directly patternable
  from hand-written Elixir;
- a native component adds crash, scheduler, build, supply-chain, upgrade, and
  platform support obligations;
- closure conversion and representation-aware patterns touch the compiler
  broadly;
- native interop conflicts become explicit diagnostics or conversions rather
  than convenient but incorrect structural behavior.

Correctness is the baseline. Compact layouts, field IDs, batched internal
operations, and proven scalar replacement are later optimizations. They may not
weaken the semantic or boundary contract.

Because the project is pre-1.0, this is the appropriate point to introduce the
object ABI. It must still land in independently bisectable slices, with current
unsupported diagnostics retained until each public surface is complete.

## Primary references

- [Haxe 4.3.7 `ObjectMap`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/ObjectMap.hx)
- [Haxe 4.3.7 `ListSort`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/ListSort.hx)
- [Haxe 4.3.7 `Array`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/Array.hx)
- [Haxe 4.3.7 `Map`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/Map.hx)
- [Haxe 4.3.7 `List`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/ds/List.hx)
- [Haxe 4.3.7 `Serializer`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/Serializer.hx)
- [Haxe 4.3.7 `Unserializer`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/Unserializer.hx)
- [Erlang NIF resource documentation](https://www.erlang.org/doc/apps/erts/erl_nif.html)
- [Erlang ETS documentation](https://www.erlang.org/doc/apps/stdlib/ets.html)
