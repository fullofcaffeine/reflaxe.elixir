# Structural Elixir AST and focused semantic plans

Status: active implementation contract; regression baseline complete, exhaustive traversal next

External source: [GitHub issue #38](https://github.com/fullofcaffeine/reflaxe.elixir/issues/38)

Architecture decision: [Structural Elixir AST and focused semantic plans](../../docs/05-architecture/SEMANTIC_PLANS_AND_STRUCTURAL_AST.md)

## Decision summary

`ElixirAST` is the compiler's existing target-specific intermediate representation. Keep the
existing `TypedExpr -> ElixirAST -> ordered passes -> printer` compiler; do not add a parallel
universal IR, copy haxe.c's whole-program HxcIR, or introduce another backend. Strengthen the current
IR in bounded slices. The architecture review changed the immediate order: safety infrastructure
comes before another node family.

1. freeze no-regression evidence with existing guards/tests and record reviewed architecture debt;
2. centralize exhaustive `ElixirAST` child and `EPattern` traversal;
3. make registry failures strict without rescheduling the 578-pass effective list;
4. expose granular passes through transparent nested groups;
5. add request-local pass state, conservative invalidation, and phase legality;
6. consolidate receiver effects under one owner and detach result flow from printer repair;
7. add structural interpolation, de-semanticize the printer, and tighten `LoopIR`; and
8. extract only proven owners after parity evidence.

The managed-reference program retains ownership of representation analysis, managed semantic nodes,
runtime ABI, and release gates. This plan supplies reusable structural traversal and pass-invariant
infrastructure without re-planning that work.

## Beads graph

| ID | Work item | Status |
| --- | --- | --- |
| `haxe.elixir.codex-75i` | Strengthen semantic plans and structural AST boundaries | P1, open |
| `haxe.elixir.codex-75i.1` | Freeze architecture-refactor regression baselines | P1, complete |
| `haxe.elixir.codex-75i.2` | Keep Elixir string interpolation structural through printing | P2, open |
| `haxe.elixir.codex-75i.3` | Complete the persistent receiver-effect semantic plan | P1, open |
| `haxe.elixir.codex-75i.4` | Establish phase legality and raw/runtime-intent contracts | P1, open |
| `haxe.elixir.codex-75i.5` | Extract proven semantic owners from the mega-transformer | P2, open |
| `haxe.elixir.codex-75i.6` | Centralize exhaustive ElixirAST child and pattern traversal | P1, open |
| `haxe.elixir.codex-75i.7` | Freeze effective pass order and fail closed on registry errors | P1, open |
| `haxe.elixir.codex-75i.8` | Make pass bundles transparent nested pipeline groups | P1, open |
| `haxe.elixir.codex-75i.9` | Add request-local pass context and conservative analysis invalidation | P1, open |
| `haxe.elixir.codex-75i.10` | Detach result correctness from printer sentinel behavior | P1, open |
| `haxe.elixir.codex-75i.11` | Move semantic policy out of ElixirASTPrinter | P1, open |
| `haxe.elixir.codex-75i.12` | Tighten LoopIR into a closed builder-local plan | P2, open |

Intended blocking graph:

```text
haxe.elixir.codex-75i.1
└── haxe.elixir.codex-75i.6
    └── haxe.elixir.codex-75i.7
        └── haxe.elixir.codex-75i.8
            └── haxe.elixir.codex-75i.9
                └── haxe.elixir.codex-75i.4
                    └── haxe.elixir.codex-75i.3
                        └── haxe.elixir.codex-75i.10
                            └── haxe.elixir.codex-75i.2
                                ├── haxe.elixir.codex-75i.11
                                └── haxe.elixir.codex-75i.12

haxe.elixir.codex-75i.11 + haxe.elixir.codex-75i.12
└── haxe.elixir.codex-75i.5
```

Traceability (non-blocking):

- `haxe.elixir.codex-75i` is discovered from closed architecture audit `haxe.elixir-bqv` and
  GitHub issue #38.
- `haxe.elixir.codex-75i` is related to generated-output epic `haxe.elixir.codex-3qh`.
- `haxe.elixir.codex-75i.3` and `.4` are related to managed representation scaffolding
  `haxe.elixir.codex-0yn.10.3.4`; they do not replace or block its representation/runtime work.
- `haxe.elixir.codex-75i.10`, `.11`, and `.12` are related to generated-output epic
  `haxe.elixir.codex-3qh`.

## Slice 1: regression baselines, not an architecture receipt

Use the repository's existing executable evidence before changing architecture:

- the checked pass inventory and scope guards freeze the healthy 578-pass effective order;
- snapshot and result-invariant suites freeze generated behavior and value contracts;
- scoped-versus-all-pass comparisons freeze pass-selection equivalence;
- Haxe-authored runtime, example, package, and determinism checks cover the affected public paths;
  and
- the architecture decision records the currently observed traversal, receiver, printer, static
  state, and `LoopIR` debt with source references and explicit uncertainty.

Do not add a regex-generated source receipt, string-anchor catalog, or parallel architecture
database. Those artifacts couple CI to incidental implementation text without proving compiler
behavior. Each later slice adds the smallest focused Haxe test for the contract it introduces—for
example exhaustive child preservation, fail-closed registry validation, transparent pass
attribution, or conservative analysis invalidation—alongside ordinary source-level regressions and
byte/runtime parity. One-off discovery scripts remain disposable investigation aids.

## Slice 2: exhaustive traversal foundation

Add one no-default immediate-child schema for all `ElixirASTDef` constructors plus a coordinated
exhaustive `EPattern` mapper. Preserve metadata, positions, optional record fields, and HEEx attribute
spans under identity mapping. Layer scope, control flow, quote/raw behavior, and AST-valued metadata
as explicit traversal policies. Shadow current walkers and classify every newly reached child before
switching production APIs.

## Slice 3: strict and transparent pass management

Materialize the current 578-pass effective order as behavioral data. Distinguish hard and optional
ordering edges, fail on duplicates, missing hard edges, cycles, and phase regressions, and do not
topologically reshuffle the mature list. Replace the seven executable bundle functions with seven
transparent nested groups so each granular pass remains visible to diagnostics and invariants while
initially preserving today's capability snapshot cadence.

## Slice 4: request-local state, analysis, and legality

Add request-local pass context, collision-aware naming, AST revisions, conservative analysis
invalidation, and forced-recompute differential checks. Legacy passes may report changed/unknown;
they must not claim false preservation. Introduce a small legal/illegal/conditionally-legal matrix
only for admitted semantic and raw-authority families. Report current debt first and harden each
family immediately after its one owner can prove the postcondition.

## Slice 5: persistent receiver-effect plan

Instrument every producer and consumer before moving ownership. The marker stores only irrecoverable
variants: receiver identity/representation, structural operation, result projection, writeback, and
source attribution. Evaluation order and ordinary failure are owner invariants unless a demonstrated
variant needs data; branch/join state belongs in scoped lowering context. Run one owner once, require
zero reintroduction, and remove the final lowering/reducer replay only with byte/runtime evidence.

## Slice 6: printer-independent result flow

Move numeric-sentinel deletion to its earliest truthful AST owner and remove printer-specific rules
from `FunctionResultInvariant`. Model normal value/unit completion, abrupt completion, and opaque raw
authority explicitly. Preserve first-degrading granular pass attribution.

## Slice 7: structural interpolation

Add a closed interpolated-string AST form whose parts are literals or child `ElixirAST` expressions.
Migrate the string-concatenation pass, printer, traversal, equality, variable-use/scope analysis,
binder repair, loop restoration, and IIFE legalization. Delete interpolation token scanners only
after structural coverage is proven. Preserve exact source behavior and idiomatic target output.

## Slice 8: printer policy and closed local plans

Move exception, dependency/alias, qualification, correctness-visible naming, and other semantic
policy out of `ElixirASTPrinter` one family at a time. Tighten `LoopIR`: successful plans have closed
variants, no placeholder target nodes, no confidence-based correctness, and no emitter re-analysis
of `originalExpr`; fallback keeps the original expression outside the successful plan.

## Slice 9: ownership extraction

Move the proven interpolation, receiver-plan, and invariant implementations into focused modules
only after scoped/all-pass byte parity and runtime evidence. Preserve registry IDs, order,
applicability, metadata, request-local state, and generated behavior. This is ownership cleanup, not
a broad rewrite.

## Cross-cutting invariants

- One compiler and one source semantic contract.
- `ElixirAST` remains the single target-specific IR; focused plans enrich it or feed it at an owned
  boundary rather than forming a parallel general-purpose compiler pipeline.
- Structural AST before target text for ordinary compiler-owned lowering.
- A semantic plan must pass the admission test in the architecture decision.
- No generic traversal has a catch-all leaf case; scope/raw/quote/metadata policies are explicit.
- Current effective pass order is behavioral data and is not changed by infrastructure work.
- Pass groups are scheduling structure, not hidden runners.
- Changed or unknown passes invalidate cached facts unless preservation is proven.
- Printer owns syntax and escaping only.
- Explicit raw authority remains distinct and source-attributable.
- No app, path, profile, function-name, or printed-shape heuristic establishes semantic ownership.
- Managed representation and runtime ABI remain owned by `haxe.elixir.codex-0yn.10.3.*`.
- HXX/HEEx stays structural where current nodes permit; broader template modeling requires focused
  evidence, a typed authority audit, and a separately decision-complete follow-up.
- Public behavior and generated output do not change during baseline capture or mechanical
  extraction.
- Compiler changes update docs/examples and generated outputs in the same slice when behavior moves.

## Transformer compatibility contract

Existing transformers remain valid when their declared input is structural `ElixirAST`, but current
generic traversal is not safe enough for another child-bearing node. Compatibility is enforced by
structure, policy, phase, and ownership:

- one exhaustive immediate-child schema covers all `ElixirASTDef` constructors, and one coordinated
  mapper covers every `EPattern` variant;
- structural traversal does not pretend to understand lexical scope, quote/raw authority,
  control-flow completion, or AST-valued metadata; those are explicit layered policies;
- exactly one named semantic owner validates and consumes each focused plan;
- a structural transform that cannot interpret an unresolved semantic node must run after lowering
  or reject it through typed applicability or an invariant;
- exhaustive `ElixirAST` handling is updated when a new structural or semantic case is admitted; and
- no legacy transform may recover source intent from printed text, target names, or map/struct shape.

The old and new walkers run in bounded shadow mode before production switches. Focused constructor
coverage and identity-map tests capture the current gaps and then enforce explicit structural,
scope, quote/raw, metadata, and control-flow policies before new nodes are introduced. This makes
compatibility an executable migration property, not an assumption.

## LLVM and MLIR lessons we adopt

The applicable LLVM-project lessons are pass discipline, not LLVM IR:

- declare which node families are legal, illegal, or conditionally legal at each lowering phase;
- verify those contracts immediately after the owning pass;
- explicitly preserve or invalidate cached analyses when a transform changes relevant structure;
- keep stable pass identities and debuggable before/after evidence; and
- lower progressively from admitted semantic intent to structural Elixir nodes.

We do not adopt low-level SSA as the universal representation, force Elixir through a C-like CFG,
add an MLIR dependency, or build a general dialect framework. The lightweight legality and analysis
contracts belong to the existing pass registry and `ElixirAST`.

## No-regression migration gate

This work uses a parity-first, slice-by-slice migration:

1. Capture complete generated-output, runtime, package, pass-order, and determinism baselines.
2. Require traversal schema, strict registry, transparent groups, context/analysis scaffolding, and
   mechanical ownership extraction to remain byte-identical.
3. Shadow old/new traversal and pass runners before switching; classify every difference.
4. Admit one node or semantic owner at a time only after constructor coverage and legality exist.
5. Keep the old behavior until ordinary-Haxe semantic, evaluation-order, exception, and runtime
   regressions distinguish the replacement from a cosmetic rewrite.
6. Run pass order/scope/result guards, affected full snapshot chunks, handwritten-output review,
   examples, source/package parity, and bounded runtime/browser evidence when applicable.
7. Land and push each closed child separately, then require exact-head CI and CodeQL before starting
   the next child.

An intentional bug fix may change reviewed generated output only with a source-level regression that
proves the corrected behavior. If parity or semantics cannot be established, split a narrower
prerequisite; do not preserve progress through printer repair, disabled invariants, or a semantic
feature flag.

## Rollout and rollback

This is 1.x compiler architecture work and does not block `haxe.elixir.codex-0yn` or the 1.0 release
decision. Each child is independently reviewable and revertible. Structural nodes and validation can
ship internally without a user flag. No profile or feature flag may select different semantics.

If a slice cannot prove semantic and byte/runtime parity, retain the current path, record the exact
counterexample in its Bead, and split a narrower prerequisite. Do not disable invariants, repair
printed output, or replace ordinary Haxe test input with raw Elixir.

## Verification contract

Planning changes run Beads lint/ready/dependency checks, docs links, diff checks, and path hygiene.
Implementation tasks must state bounded focused commands and then run the applicable pass inventory,
pass scope, snapshot, result-invariant, handwritten-output, Haxe-authored ExUnit/stdlib, examples,
source/package, and async todo-app QA gates required by `AGENTS.md`.
