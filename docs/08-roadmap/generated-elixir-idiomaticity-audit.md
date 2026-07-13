# Generated Elixir Idiomaticity Audit

Status: accepted workstream, implementation tracked by epic
`haxe.elixir.codex-3qh`.

Audit date: 2026-07-12.

## Executive Answer

Reflaxe.Elixir already has the right product direction, but its output is not
yet consistently at the "could have been handwritten" bar.

The important gradient already exists:

- Functional, Elixir-first Haxe can compile to direct `String`, `Enum`, map,
  tuple, Phoenix, LiveView, and Ecto code.
- Portable Haxe preserves Haxe behavior first and therefore exposes more
  lowering and runtime support.
- Mutable, class-heavy, or dynamically dispatched Haxe needs the most visible
  machinery because Elixir does not share those execution semantics directly.

The goal is to make that gradient sharper. Source that is already close to
Elixir should produce code that is correspondingly close to raw Elixir. Any
remaining helper, reducer, dispatch layer, or control-flow carrier should have
a concrete semantic reason.

This is not a request for a second compiler backend. Reflaxe.Elixir should keep
one AST pipeline and one semantic model. Portable and Elixir-first remain
authoring profiles communicated primarily through source shape and API choice.

## What "Idiomatic" Means Here

Generated output has four separate quality layers:

1. **Correctness**: the Elixir must preserve the Haxe program's observable
   behavior. This outranks every presentation concern.
2. **Canonical syntax and formatting**: generated files should pass the
   project's normal `mix format --check-formatted` contract.
3. **Target-native structure**: prefer ordinary `Enum`, `String`, `case`,
   `cond`, `with`, maps, tuples, pipelines, Phoenix callbacks, Ecto schemas,
   and OTP APIs when they are semantically equivalent.
4. **Justified compatibility machinery**: runtime helpers and explicit
   lowering are acceptable when required for Haxe evaluation order, mutation,
   virtual dispatch, exceptions, floats, reflection, or stdlib behavior.

Formatting alone does not make code idiomatic, and an attractive rewrite is
not an improvement if it changes semantics.

## What Is Already Strong

The Elixir-first LiveView example demonstrates the intended end state:

- `examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx` maps to
  direct `String.trim`, `String.downcase`, `String.contains?`, `Enum.filter`,
  maps, and `{:ok, value}` / `{:error, reason}` tuples.
- `SearchLive.hx` maps to normal `use Phoenix.LiveView`, `mount/3`,
  `handle_event/3`, `assign`, and `~H` shapes.
- Todo-app Ecto schemas emit normal `use Ecto.Schema`, `schema`, changeset
  functions, and pipelines.
- Framework-facing module paths generally follow Phoenix conventions rather
  than mirroring Haxe source roots.

This proves that a separate "native backend" is unnecessary. The existing
compiler can already emit target-native structures when the source and typed
API surface provide enough information.

## Confirmed Correctness Gap

The audit found a live semantic regression in the abstraction lab:

```haxe
public function nextDelayMs(_attempt:Int):Int {
  return 0;
}
```

A fresh build generated an empty Elixir function, which returns `nil` instead
of `0`. Granular pass snapshots showed that the value exists before
`LocalAssignUnusedUnderscore_Scoped_Final` and is removed by that pass.

This was not only stale checked-in output. The current compiler reproduced it.
The example's compile-only QA classification did not execute the method, so
strict compilation could not detect the changed return value.

Resolution: `haxe.elixir.codex-3qh.1` preserves the original scalar function-
body value context after unused-local analysis and adds snapshot plus runtime
coverage for literal, collection, local, call, and branch tail values. The
coverage includes native list, map, and tuple target shapes. The broader phase-
level invariant remains tracked separately by `3qh.2`.

This is the P0 item because output polish must not proceed on top of a known
value-preservation hole:

- `haxe.elixir.codex-3qh.1` - preserve non-Void tail values.
- `haxe.elixir.codex-3qh.2` - add phase-level result invariants.

## Measured Output Gaps

### Canonical formatting

File-level formatter checks found:

| Corpus | Files failing canonical format |
| --- | ---: |
| Elixir-first LiveView application files | 8 of 11 |
| Portable chat domain application files | 4 of 4 |
| Abstraction lab application files | 7 of 7 |

These failures include avoidable parentheses and layout differences. They do
not by themselves imply wrong structure, but they make otherwise good output
look generated and create needless review noise.

Reflaxe.Rust already provides a useful precedent: it can run `rustfmt` from
`BaseCompiler.onOutputComplete`, and its snapshot workflow checks formatted
output. Reflaxe.Elixir can use the same lifecycle with explicit off, write, and
check behavior. Formatting must remain a post-generation presentation step,
not a semantic repair mechanism.

Tracked by `haxe.elixir.codex-3qh.6`.

### Discarded effect calls

Resolved by `haxe.elixir.codex-3qh.5`.

The compiler previously emitted:

```elixir
_ = Supervisor.start_link(children, opts)
```

and wrapped Phoenix router DSL calls in `_ =`. Ordinary Elixir uses the bare
call in statement position.

The cleanup removed `BareCallToUnderscoreAssign` and the redundant
`PresenceBareCallPreserve` pass. Calls now remain direct `ECall`/`ERemoteCall`
nodes in `EBlock`/`EDo`; their list position already preserves execution order,
and a tail call remains the function result. Ecto migration sequence parsing
now accepts direct calls, and `ChangesetEnsureReturn` preserves a bare final
Ecto call instead of replacing its result with an earlier local.

This was intentionally not implemented as an absolute-final unwrap. Real
wildcard matches used by mutation, pattern, or explicit discard lowering remain
available, and each residual origin can be audited on its own semantics.

### Pass breadth and interaction risk

A granular trace of the tiny `ImmediateRetryPolicy` module originally produced 578 pass
snapshots. Most framework-specific passes were no-ops for that module, but they
still illustrate the breadth of the registry and the number of late final,
repair, replay, alignment, and cleanup interactions.

After the discarded-call cleanup, the effective granular registry contains 576
passes; the two removed registrations were the synthetic call-wrapper passes
described above.

The default registry presents a small set of bundles, but those bundles execute
large contiguous portions of the granular registry. The right response is not
to remove the custom Elixir AST pipeline. It is to give the pipeline explicit
phases, applicability predicates, and invariants, then consolidate only the
chains proven redundant.

Tracked by:

- `haxe.elixir.codex-3qh.3` - inventory and phase every pass family.
- `haxe.elixir.codex-3qh.4` - scope framework passes and consolidate proven
  repair chains.

### Portable collection lowering

The portable chat `Transcript` example builds an array with `push` in a loop.
Current output uses `Enum.reduce` plus repeated `Enum.concat`. A handwritten
equivalent is normally `Enum.map`, and repeated append can be O(n squared).

That rewrite is only valid when the accumulator is fresh, partial state is not
observed, each iteration contributes exactly one ordered value, and there is no
break, continue, non-local return, mutation threading, or stateful iterator
behavior. The compiler must retain its reducer fallback whenever proof fails.

Tracked by `haxe.elixir.codex-3qh.8`.

### Expression and control-flow artifacts

Representative output also contains:

- immediately invoked anonymous functions used only for local sequencing;
- nested tail-position `if` chains where `cond` is clearer;
- `case`-heavy straight-line Result flows that may qualify for `with`;
- `StringTools` calls where some concrete operations may be natively
  equivalent;
- dynamic virtual dispatch even where a closed-world exact receiver may be
  provable.

Each item has different semantic danger, so they are separate beads:

- `haxe.elixir.codex-3qh.9` - pure IIFE elimination.
- `haxe.elixir.codex-3qh.10` - proven native String operations.
- `haxe.elixir.codex-3qh.11` - pure nested branches to `cond`.
- `haxe.elixir.codex-3qh.12` - narrow Result/Option lowering to `with`.
- `haxe.elixir.codex-3qh.13` - proof-driven devirtualization.

### Generated support footprint

The Elixir-first LiveView example had 58 generated files for 11 application
modules. A fresh build with `-dce full` reduced that to 42. This shows two
different concerns:

- Some output is reachable only because example build policy does not enable
  full DCE.
- Some runtime and facade modules remain because the compiler currently treats
  them as required.

Examples 14 and 16 cannot simply enable full DCE today because their
compile-only application modules have no reachable runtime entry. They need a
meaningful runtime harness before DCE can become a trustworthy test.

Tracked by `haxe.elixir.codex-3qh.14`.

### Behaviours, protocols, and typespecs

The abstraction lab currently presents behaviour-style and protocol-style
Haxe APIs, but generated output is made of ordinary modules rather than native
`@callback` / `@behaviour` or `defprotocol` / `defimpl` constructs.

Native behaviours are plausible but need a versioned compatibility contract.
Native protocols are harder because Elixir dispatches on the native data type,
while many Haxe instances share a map-backed representation. Typespecs can add
value at stable public boundaries, but inaccurate precision is worse than a
conservative `term()`.

Tracked by:

- `haxe.elixir.codex-3qh.15` - explicit native behaviour surface.
- `haxe.elixir.codex-3qh.16` - protocol representation decision.
- `haxe.elixir.codex-3qh.17` - useful public typespecs.

## Cross-Target Comparison

| Target | What it demonstrates | Main limitation |
| --- | --- | --- |
| Reflaxe.Ruby | Ruby-first extern and Rails code can map directly to target APIs. | General output still exposes `HXRuby` helpers, metadata, receiver syntax, and dynamic dispatch. It is not a universal handwritten baseline. |
| Reflaxe.Rust | A small, clearly phased pass runner plus `rustfmt` integration gives strong output discipline. Metal source can reduce runtime use. | Rust has a much larger semantic and ownership gap from Haxe, so portable output necessarily carries more runtime machinery. |
| Reflaxe.Elixir | Functional Haxe and BEAM/Phoenix/Ecto/OTP surfaces already map closely to raw target code. | Formatting, statement-context output, broad late-pass interactions, and avoidable helper/control-flow shapes still weaken consistency. |

Elixir has the smallest semantic distance for functional code. It should
therefore aim for a higher default handwritten-output bar than either sibling,
while borrowing Rust's formatter lifecycle and pass-discipline practices.

## Priority And Dependency Order

The active beads graph was empty when this workstream was created. There were
494 closed issues and four unrelated deferred issues. Prioritization therefore
starts directly with the confirmed regression:

| Order | Priority | Work |
| --- | --- | --- |
| 1 | P0 | Fix tail-value corruption (`3qh.1`). |
| 2 | P1 | Enforce result invariants and map the registry (`3qh.2`, `3qh.3`). |
| 3 | P1 | Scope/consolidate passes, fix effect-call statement output, and integrate formatting (`3qh.4` through `3qh.6`). |
| 4 | P1 | Establish the reviewed handwritten-output corpus and CI gate (`3qh.7`). |
| 5 | P2 | Land conservative collection, expression, String, branch, and footprint improvements (`3qh.8` through `3qh.11`, `3qh.14`). |
| 6 | P3 | Attempt higher-risk `with`, devirtualization, behaviours, protocols, and specs only behind the quality gate (`3qh.12`, `3qh.13`, `3qh.15` through `3qh.17`). |
| 7 | P2 | Update canonical docs and prove source/package parity (`3qh.18`). |

## Non-Goals And Safety Rules

- Do not create separate portable and Elixir-first compiler backends.
- Do not remove the Elixir AST pipeline or custom semantic passes.
- Do not use generated-text replacements as semantic fixes.
- Do not optimize away Haxe left-to-right evaluation or exception timing.
- Do not break receiver-return rebinding, persistent iterators, loop return
  carriers, virtual dispatch, reflection, float edge cases, or stdlib parity.
- Do not make every Haxe program look artificially native. Explain unavoidable
  compatibility machinery instead.
- Keep advisory profile metadata deferred unless a real application proves it
  prevents mistakes without noisy or semantic behavior.

## Investigation Method

The audit used:

- fresh builds of examples 13, 14, and 16;
- direct source-to-generated-output comparison;
- file-level `mix format --check-formatted` checks;
- granular AST pass snapshots around the confirmed return regression;
- full-Reflaxe-prepass experiments on representative examples;
- an `idiomatic_comprehensions` experiment on the portable chat example;
- DCE file-count comparison;
- direct inspection of Reflaxe.Ruby and Reflaxe.Rust profile, pass, runtime,
  generated-output, and formatter behavior.

The full generic Reflaxe prepass set did not materially change the
representative output or fix the return regression. The experimental
idiomatic-comprehensions define also did not change the portable Transcript
output. These results support targeted Elixir IR improvements rather than a
blanket framework switch.

## Completion Contract

The roadmap audit preserves why the work exists. Beads preserve execution
state, dependencies, acceptance criteria, and verification evidence. The final
closeout is tracked by `haxe.elixir.codex-3qh.18`; it must update canonical user
and compiler documentation rather than leaving this roadmap file as the only
explanation.
