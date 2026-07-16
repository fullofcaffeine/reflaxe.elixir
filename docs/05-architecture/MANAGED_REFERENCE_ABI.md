# Selective Managed-Reference ABI

Status: **accepted for staged implementation; not yet shipped**

Decision record: `haxe.elixir.codex-0yn.10.3.1`

Review baseline: Haxe 4.3.7 and Reflaxe.Elixir commit
`6dc9c0dff1d8ca44c44394c0bd195eda17400ba7`

## Outcome

Reflaxe.Elixir will use one selective managed-reference ABI for ordinary Haxe
reference objects whenever object identity or alias-visible mutation can be
observed. Explicit BEAM-native values keep their native representation.

The managed-reference ABI must provide:

- allocation-time identity independent of visible fields;
- shared field storage observed through every alias;
- strong and weak graph edges with reclamation of unreachable cycles;
- mutable identity-keyed `haxe.ds.ObjectMap` values;
- same-node process sharing;
- exact field mutation for the official `haxe.ds.ListSort` algorithms;
- representation-aware equality, reflection, RTTI, serialization, inspection,
  JSON, process-message, and interop behavior.

This is a compiler and runtime object-model project. It is not a stdlib-only
override, a second compiler backend, or an application-profile switch.

`ObjectMap`, `ListSort`, `WeakMap`, and complete reference-graph serialization
remain unsupported today. Their current diagnostics must stay in place until
the independently gated implementation slices and runtime evidence pass.

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

The same defect makes exact `ListSort` impossible over persistent maps. Rebuilding
a sorted chain creates new values or updates only local bindings; aliases to the
original nodes retain stale `next` and `prev` links. The upstream algorithm must
mutate the original node identities.

`WeakMap` and cyclic Haxe serialization make lifecycle observable as well.
Process dictionaries, ETS, Agents, and PIDs do not by themselves reclaim an
entry when the last ordinary BEAM term referring to one Haxe object disappears.
An exact design therefore needs a term-lifetime hook plus graph tracing.

## Representation contract

The compiler will classify representation from typed metadata before building
`ElixirAST`.

| Classification | Runtime representation | Examples |
| --- | --- | --- |
| Managed class | Opaque managed handle | Ordinary generated Haxe class instances |
| Managed anonymous object | Opaque managed handle | Ordinary Haxe anonymous structures |
| Managed collection | Opaque managed handle | `ObjectMap`; other identity-sensitive mutable objects when explicitly assigned |
| Native value | Native BEAM term | numbers, atoms, strings, binaries, tuples, lists, value-semantic maps |
| Native interop | Declared native BEAM term | Ecto structs, Phoenix/OTP option maps, JSON payload maps, target exceptions, native externs |
| Representation conflict | Compile-time diagnostic | A native Ecto struct used as an identity key or mutable `ListSort` node without explicit boxing |

Ordinary Haxe classes and anonymous structures default to the managed ABI at
public and cross-module boundaries. A later optimization may scalarize a proven
local, non-escaping allocation whose identity and mutation cannot be observed,
but it must preserve the declared ABI and pass byte- and runtime-parity evidence.
Demand-only wrapping at `ObjectMap` or `ListSort` call sites is forbidden.

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
8. `Map<K,V>` selects this representation when `K` is an object-key type.

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
| Pre-build analysis | Classify class types, anonymous shapes, allocations, variables, calls, and boundaries before AST construction |
| `CompilationContext` | Store representation, class/shape IDs, promotion reason, native-boundary reason, conflicts, and runtime emission requirements |
| `ElixirAST` | Carry semantic reference allocation, get, put, equality, and collection operations that cannot be mistaken for native maps |
| Object and constructor builders | Allocate managed objects at birth; retain explicit native literals and structs |
| Field and assignment builders | Emit managed reads/writes with single evaluation; preserve native persistent updates elsewhere |
| Binary and call builders | Emit identity equality, object-map operations, class-tag dispatch, and exact diagnostics |
| Pattern/control-flow builders | Read carrier fields before patterns and guards |
| Runtime facade | Validate handles and expose the selected managed heap without leaking implementation fields |
| Printer | Print only lowered ordinary calls and reject surviving semantic nodes |

The planned semantic constructors are conceptually:

```haxe
ERefAlloc(kind, classTag, fields)
ERefGet(target, field)
ERefPut(target, field, value)
ERefSame(left, right)
EObjectMapOp(operation, arguments)
```

`ManagedReferenceLowering` is a stable core/global pass. It runs before passes
that assume instance fields are inline persistent values, including:

- `InstanceFieldLowering`;
- `ControlFlowStateHoist`;
- `AssignmentExtraction`;
- `StructUpdateTransform`;
- `HaxeMapModuleCallRewrite`.

A validation pass rejects native field access, struct updates, `Map.put`, and
receiver writeback whose typed target is managed. The printer rejects any
unlowered managed semantic node. Pass eligibility follows typed representation
metadata, never names or paths.

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

The task graph deliberately prevents a speculative broad rewrite:

| Gate | Bead | Completion boundary |
| --- | --- | --- |
| Architecture decision | `haxe.elixir.codex-0yn.10.3.1` | This contract is reviewed; no behavior changes |
| Feasibility | `haxe.elixir.codex-0yn.10.3.2` | Resource leases, tracing, cycles, process behavior, scheduler safety, and package implications are proven in a bounded spike |
| Distribution ABI | `haxe.elixir.codex-0yn.10.3.3` | Native/hybrid design, build, upgrade, license, artifact, and platform contracts are selected |
| Semantic scaffolding | `haxe.elixir.codex-0yn.10.3.4` | Typed classification and semantic AST exist with byte-for-byte output parity |
| Managed core | `haxe.elixir.codex-0yn.10.3.5` | Allocation identity and alias-visible fields work for managed classes and anonymous objects |
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
- stable identity after mutation and through shallow copies;
- constructor escape and exception behavior;
- ObjectMap aliases, copy divergence, iteration, mutation, cycles, and liveness;
- stable original-node singly and doubly linked sorting;
- weak-key reclamation;
- visible-only reflection, class tags, and empty allocation;
- shared subgraphs, self-cycles, mutual cycles, custom serialization, and wire
  output without hidden state;
- closure cycles and nested carrier edges;
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
- [Haxe 4.3.7 `Serializer`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/Serializer.hx)
- [Haxe 4.3.7 `Unserializer`](https://raw.githubusercontent.com/HaxeFoundation/haxe/4.3.7/std/haxe/Unserializer.hx)
- [Erlang NIF resource documentation](https://www.erlang.org/doc/apps/erts/erl_nif.html)
- [Erlang ETS documentation](https://www.erlang.org/doc/apps/stdlib/ets.html)
