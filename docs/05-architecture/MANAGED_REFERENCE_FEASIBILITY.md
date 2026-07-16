# Managed-Reference Runtime Feasibility

Status: **feasibility demonstrated; experimental only, not shipped**

Decision record: `haxe.elixir.codex-0yn.10.3.2`

Architecture contract: [Selective Managed-Reference ABI](MANAGED_REFERENCE_ABI.md)

## Outcome

The managed-reference runtime is feasible on BEAM without changing every native map or struct. A
central native heap rooted by opaque BEAM resource leases demonstrated the required foundational
properties:

- allocation identity independent of visible values;
- alias-visible mutation across local processes;
- synchronized concurrent operations;
- last-term lease destruction;
- direct and nested strong object-ID edges;
- weak edges that do not retain their targets;
- tracing reclamation of a doubly linked cycle;
- resource takeover across a module code reload;
- deterministic rejection on a remote BEAM node; and
- full collection on a dirty CPU scheduler with no user callback under the heap lock.

The prototype also confirms that a hybrid native-lease plus Elixir-owned heap can observe last-term
lifetime and reclaim cycles. It is not the recommended primary implementation: it still requires a
NIF, adds a `GenServer` round trip to every object operation, and loses all live object state if its
owner process terminates.

The next distribution-ABI task should advance the **central native heap** as the baseline candidate.
That is an engineering recommendation, not approval to ship this C prototype. Language choice,
licensing, artifact distribution, incremental collection, heap layout, and the closure-edge ABI
remain separately gated.

No compiler or public stdlib behavior changed. Existing `ObjectMap`, `ListSort`, and `WeakMap`
diagnostics remain in force.

## Experimental boundary

All executable evidence lives under
[`tools/managed_reference_spike/`](../../tools/managed_reference_spike/README.md). The prototype is
not referenced by compiler classpaths or target runtime modules.

The root Hex package declaration includes only `lib`, `mix.exs`, README files, and license files. The
Haxelib release builder copies only `src`, `std`, selected metadata, and the vendored Reflaxe runtime.
The installed-package smoke now fails if any `managed_reference_spike` path appears in the installed
archive.

This boundary is deliberate. The spike tests whether the runtime model works; it is not a partially
supported object ABI.

## Prototypes

### Central native heap

The native candidate uses one heap in NIF private data. Each object slot contains:

```text
object ID
integer mutation probe
external root count
strong object-ID edges
weak object-ID edges
collector mark state
```

An outward lease resource stores the heap pointer and object ID. Creating a distinct outward lease
increments the object's external root count. Copying the same resource term between variables or
processes does not create a second lease. The resource destructor decrements the root only after the
last copy of that resource term disappears.

Internal edges store IDs rather than resource terms. The dirty collector marks from objects with
external roots, follows strong IDs, sweeps unmarked slots, then prunes dead weak IDs. This reclaims
cycles that resource reference counting alone cannot reclaim.

All heap and root operations use one NIF mutex in the spike. Comparator, serializer, inspector, and
other user callbacks are absent from the NIF API. Nested scanning rejects a function term as
`{:error, :opaque_closure}` without calling it. The production design must preserve that separation
while replacing the single full-heap critical section with incremental or otherwise bounded
collector phases.

The resource types open with `ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER`. Reloading the Elixir module
with a live lease reuses the heap private data and transfers the resource destructor successfully.
This proves the basic takeover mechanism, not arbitrary native-layout migration between releases.

### Hybrid lease with Elixir-owned graph

The hybrid candidate keeps objects and edges in a `GenServer`. A smaller NIF resource stores only the
owner PID and object ID. Its destructor sends `{:hybrid_lease_down, id}` to that local owner, which
updates roots and performs tracing in Elixir.

This avoids native graph allocation and makes cycle tracing memory-safe at the Elixir layer. It also
has three semantic and operational costs:

1. Every field or map operation is serialized through one process.
2. Destructor messages are asynchronous, so reclamation can lag safely but unpredictably.
3. If the owner process dies, existing handles survive as terms but their state is gone.

Sharding or supervising owners can reduce contention and restart risk, but cannot reconstruct live
mutable state after owner loss. The hybrid also cannot remove the native build requirement because
ordinary Elixir terms have no last-copy callback.

## Evidence matrix

The suite uses runtime-internal ExUnit because this task tests the heap implementation rather than a
public Haxe operation. Public stdlib slices will still require Haxe-authored semantic tests.

| Property | Native candidate | Hybrid candidate | Evidence |
| --- | --- | --- | --- |
| Fresh allocation identity | Pass | Pass | Equal initial values receive different IDs; cloned leases retain one ID |
| Alias-visible mutation | Pass | Pass | A second process writes through an alias and the original reads the new value |
| Same-node sharing | Pass | Pass | Resource terms and hybrid refs cross process mailboxes without copying object state |
| Concurrent primitive operations | Pass | Serialized by owner | Eight native writers perform 8,000 linearizable increments |
| Last-lease destruction | Pass | Pass, asynchronous | A short-lived process exits; root count reaches zero without explicit release |
| Nested carrier extraction | Pass for lists, tuples, and maps | Pass for lists, tuples, and maps | Nested resource handles become unique object-ID edges |
| Strong graph edges | Pass | Pass | A rooted owner keeps zero-root children alive |
| Weak graph edges | Pass | Pass | Zero-root weak target is swept and the weak ID is pruned |
| Doubly linked cycle | Pass | Pass | Two zero-root objects with mutual strong edges are both reclaimed |
| Root/collector race | Pass | Owner serialization | Lease creation/destruction, graph reads, writes, and collection run concurrently |
| Closure edge detection | Explicit rejection | Explicit rejection | A closure is not executed and returns `:opaque_closure` |
| Resource hot takeover | Pass for unchanged layout | NIF lease type can take over | A live native lease remains readable after module reload |
| Remote raw handle | Deterministic rejection | Same resource limit | Remote NIF sees `:wrong_node_or_stale` rather than a valid local resource |
| Remote descriptor | Deterministic rejection | Not promoted | Per-VM token mismatch returns `:wrong_node` |
| Owner-process failure | Heap remains independent | Fails closed as `:heap_down` | Hybrid state disappears when its owner terminates |
| User callback under heap lock | None | None in graph operations | Native API accepts data only; closure terms are rejected before locking |

The test suite currently contains 14 focused cases and completes in roughly 0.3 seconds after the NIF
is built.

## Reproduction

The main command builds from C source, checks formatting and package boundaries, starts a named local
node, runs the remote-node evidence through an OTP peer, and deletes the generated shared library:

```sh
npm run test:managed-reference-spike
```

Equivalent focused commands are:

```sh
make -C tools/managed_reference_spike clean all
scripts/with-timeout.sh --secs 120 -- bash -lc \
  'cd tools/managed_reference_spike && elixir --sname managed_ref_manual -S mix test --seed 0 --max-cases 1'
make -C tools/managed_reference_spike clean
```

The comparison benchmark is intentionally outside CI assertions:

```sh
make -C tools/managed_reference_spike clean all
scripts/with-timeout.sh --secs 60 -- bash -lc \
  'cd tools/managed_reference_spike && mix run benchmark.exs'
make -C tools/managed_reference_spike clean
```

## Toolchains and measurements

Local evidence was collected on 2026-07-15:

| Item | Result |
| --- | --- |
| Host | macOS 15.4, Apple Silicon ARM64 |
| BEAM | OTP 27, ERTS 15.2.7, NIF API 2.17 |
| Elixir | 1.18.3 |
| C compiler | Apple clang 17 |
| Clean source build | 0.27 seconds wall time |
| Unstripped shared library | 53 KiB |
| Semantic suite | 14 tests, 0 failures, about 0.3 seconds |
| Native static analysis | Clang analyzer completed with no findings after the mark-stack invariant was made explicit |
| Undefined-behavior sanitizer | All 14 tests passed with Clang UBSan and fail-fast enabled |
| Mutation benchmark | 50,000 synchronized increments per candidate, five fresh VMs |
| Native median | 1,911 microseconds |
| Hybrid median | 50,794 microseconds |
| Median ratio | Hybrid was about 26.6 times slower in this narrow probe |

The benchmark isolates one synchronized integer operation. It is useful for comparing the extra
process hop, but it is not a generated-Haxe performance forecast and does not choose field layout or
native language.

Cross-platform source builds are wired into the required CI workflow:

| Lane | OS | OTP / Elixir | Status |
| --- | --- | --- | --- |
| Minimum | Ubuntu | OTP 25 / Elixir 1.14 | [Passed](https://github.com/fullofcaffeine/reflaxe.elixir/actions/runs/29464983595/job/87516569837) |
| Primary Linux | Ubuntu | OTP 27.2 / Elixir 1.18.3 | [Passed](https://github.com/fullofcaffeine/reflaxe.elixir/actions/runs/29464983595/job/87516569842) |
| Primary macOS | macOS | OTP 27.2 / Elixir 1.18.3 | [Passed](https://github.com/fullofcaffeine/reflaxe.elixir/actions/runs/29464983595/job/87516569841) |

All three source-build jobs passed on exact commit `e051c53ea879a8bf385f55adaa6581f5291caf0f` in
[CI run 29464983595](https://github.com/fullofcaffeine/reflaxe.elixir/actions/runs/29464983595).

## Failure modes and limits

The spike exposed one collector defect during development: pruning a reachable object's weak list in
the same forward pass that swept later slots left a dead weak ID behind. The corrected collector uses
two phases—sweep all dead slots, then prune weak IDs from survivors. The regression remains in the
suite.

The following limits are intentional and must not be mistaken for solved production scope:

- The object slot stores an integer mutation probe and edge vectors, not complete Haxe field values,
  class metadata, `ObjectMap` entries, serializer state, or bound methods.
- The node token is a process-local collision-resistant probe value, not a security credential or a
  stable distribution identifier.
- Full tracing runs as a dirty CPU NIF, so ordinary schedulers remain available, but the spike holds
  the heap mutex for the entire trace. Production collection needs incremental phases or a proven
  bounded dirty strategy that does not starve heap users.
- Resource takeover is proven only with the same resource layout. A production ABI needs explicit
  versioning and migration or compatibility rules.
- Native C code can crash the VM. A production implementation needs the language, fuzzing, memory,
  sanitizer, review, and supply-chain policy selected by the next gate.
- A wrapper from an unknown NIF cannot be inferred as a managed edge by shape. Typed compiler
  metadata must identify carrier values before they enter native storage.
- No closure capture graph exists. A carrier captured by a closure and stored back into a carrier can
  still create an invisible cycle. Exact release claims remain blocked on compiler-owned capture
  metadata or managed closure conversion.
- Live sharing remains node-local. Distributed use requires a Haxe graph snapshot/import contract;
  raw references are rejected.

## Build and package implications

A source-built native runtime requires a C-compatible compiler and the active OTP installation's
`erl_nif.h`. The spike builds without Hex dependencies on macOS and Ubuntu. Production consumers
would need one of these explicit contracts:

- compile the native runtime during package/application build;
- install a compatible prebuilt artifact selected by OS, architecture, and supported NIF ABI; or
- use a documented fallback that does not claim managed-reference semantics.

There is no exact pure-Elixir fallback: the hybrid comparison still needs the resource destructor to
observe the last term. Silently reverting to structural maps would violate the accepted ABI.

The repository's current Haxelib artifact contains compiler sources, not an application-specific Mix
build. The distribution-ABI task must decide where native source, build hooks, and optional prebuilt
artifacts live for generated applications. That decision remains blocked by the qualified licensing
task `haxe.elixir.codex-0yn.4`; this report makes no legal or redistribution policy.

## Recommendation for the next gate

Advance the central native heap into `haxe.elixir.codex-0yn.10.3.3`, with these required decisions:

1. Select the production implementation language and memory-safety strategy.
2. Version the lease, heap, object-slot, and resource-takeover ABI.
3. Design incremental marking/sweeping and weak processing without user callbacks under locks.
4. Specify carrier encoding for scalars, nested containers, closures, and bound methods.
5. Specify source-build and prebuilt artifact support for OTP 25 and the primary lane on Linux and
   macOS.
6. Define node-local errors plus explicit distributed snapshot export/import.
7. Keep the native Ecto, Phoenix, OTP, JSON, exception, and extern boundary contract unchanged.

Do not copy the experimental C file into a production runtime. Its value is the evidence that the
semantic substrate works and the concrete list of obligations the real implementation must meet.

## Primary references

- [Erlang NIF API and resource lifecycle](https://www.erlang.org/doc/apps/erts/erl_nif.html)
- [Selective Managed-Reference ABI](MANAGED_REFERENCE_ABI.md)
- [Experimental spike README](../../tools/managed_reference_spike/README.md)
