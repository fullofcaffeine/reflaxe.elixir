# Managed-reference feasibility spike

This directory is an experimental proof for the managed-reference architecture. It is not linked
to the compiler, is not copied into Haxelib or Hex packages, and does not enable `ObjectMap`,
`ListSort`, `WeakMap`, or mutable generated objects.

The spike compares two ways to observe the lifetime of an opaque BEAM handle:

1. `ManagedReferenceSpike.Native` keeps object slots, strong and weak object-ID edges, root counts,
   mutation, and tracing collection in a central native heap. Resource destructors remove external
   roots. Collection runs as a dirty CPU NIF and never invokes Elixir code.
2. `ManagedReferenceSpike.HybridHeap` keeps the graph in a `GenServer`. A much smaller native
   resource sends a local `{:hybrid_lease_down, id}` message when its last BEAM term disappears.

Both candidates intentionally reject closures stored inside managed values. A BEAM closure can hide
carrier handles from either graph scanner, so release-ready GC still requires compiler-owned closure
capture metadata.

Run the bounded build and semantic suite from the repository root:

```sh
npm run test:managed-reference-spike
```

Run the small comparison benchmark after building the NIF:

```sh
make -C tools/managed_reference_spike clean all
scripts/with-timeout.sh --secs 60 -- bash -lc \
  'cd tools/managed_reference_spike && mix run benchmark.exs'
make -C tools/managed_reference_spike clean
```

The C source uses only NIF APIs available on the repository minimum OTP line. Resource leases are
opaque terms that can be copied between local processes; their destructor runs after the last term is
collected. Resource-type takeover preserves live leases across a module upgrade. The implementation
uses explicit locking for shared mutable state, and the full tracing pass is registered on a dirty CPU
scheduler. These constraints follow the official
[Erlang NIF resource and scheduler documentation](https://www.erlang.org/doc/apps/erts/erl_nif.html).

The checked architecture report records the evidence and the remaining production gates. This code
is deliberately small and observable; it is not a reusable runtime library.
