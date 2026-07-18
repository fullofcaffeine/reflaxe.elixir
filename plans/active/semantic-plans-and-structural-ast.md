# Structural Elixir AST and focused semantic plans

Status: active planning contract; implementation has not started

External source: [GitHub issue #38](https://github.com/fullofcaffeine/reflaxe.elixir/issues/38)

Architecture decision: [Structural Elixir AST and focused semantic plans](../../docs/05-architecture/SEMANTIC_PLANS_AND_STRUCTURAL_AST.md)

## Decision summary

Keep the existing `TypedExpr -> ElixirAST -> ordered passes -> printer` compiler. Do not copy
haxe.c's whole-program HxcIR or introduce another backend. Strengthen the current pipeline in bounded
slices:

1. classify semantic-information loss and raw target authority;
2. keep interpolated expressions structural through printing;
3. complete persistent receiver rebinding as a closed typed semantic plan;
4. enforce executable semantic-boundary and runtime-intent contracts; and
5. extract only the proven owners from the mega-transformer after parity evidence.

The managed-reference program retains ownership of representation analysis, managed semantic nodes,
runtime ABI, and release gates. This plan supplies reusable structural traversal and pass-invariant
infrastructure without re-planning that work.

## Beads graph

| ID | Work item | Status |
| --- | --- | --- |
| `haxe.elixir.codex-75i` | Strengthen semantic plans and structural AST boundaries | open |
| `haxe.elixir.codex-75i.1` | Inventory semantic-information loss and raw target authorities | open |
| `haxe.elixir.codex-75i.2` | Keep Elixir string interpolation structural through printing | open |
| `haxe.elixir.codex-75i.3` | Complete the persistent receiver-effect semantic plan | open |
| `haxe.elixir.codex-75i.4` | Enforce semantic-boundary and runtime-intent pass contracts | open |
| `haxe.elixir.codex-75i.5` | Extract proven semantic owners from the mega-transformer | open |

Intended blocking graph:

```text
haxe.elixir.codex-75i.1
├── haxe.elixir.codex-75i.2
└── haxe.elixir.codex-75i.3

haxe.elixir.codex-75i.2 + haxe.elixir.codex-75i.3
└── haxe.elixir.codex-75i.4
    └── haxe.elixir.codex-75i.5
```

Traceability (non-blocking):

- `haxe.elixir.codex-75i` is discovered from closed architecture audit `haxe.elixir-bqv` and
  GitHub issue #38.
- `haxe.elixir.codex-75i` is related to generated-output epic `haxe.elixir.codex-3qh`.
- `haxe.elixir.codex-75i.3` and `.4` are related to managed representation scaffolding
  `haxe.elixir.codex-0yn.10.3.4`; they do not replace or block its representation/runtime work.

## Slice 1: inventory and authority taxonomy

Produce a checked-in, reproducible inventory of:

- every `ERaw` construction and consumer;
- every AST print/re-embed or print-to-compare site;
- every interpolation/raw-text identifier scanner;
- every target-shape/name inference site used for semantic decisions;
- static or request-global compiler state in affected paths;
- runtime/helper and framework intent selection; and
- existing focused plans/analyzers/invariants that should be reused.

Classify each raw site as explicit user injection, validated external source, migration debt, or
invalid ordinary lowering. Record semantic risk, owner, replacement shape, dependencies, and an
executable guard strategy. This slice is output-inert.

## Slice 2: structural interpolation

Add a closed interpolated-string AST form whose parts are literals or child `ElixirAST` expressions.
Migrate the string-concatenation pass, printer, traversal, equality, variable-use/scope analysis,
binder repair, loop restoration, and IIFE legalization. Delete interpolation token scanners only
after structural coverage is proven. Preserve exact source behavior and idiomatic target output.

## Slice 3: persistent receiver-effect plan

Turn the partial `EReceiverEffect`/receiver-return convention into one validated request-local plan.
It must preserve evaluation order, returned value, writeback target, branch/loop joins, and failure
behavior. It applies only to persistent value receivers. Managed carriers use managed semantic nodes;
ambiguous `Dynamic` writes fail closed.

## Slice 4: executable contracts

Extend existing result validation with the smallest owned checks for structural interpolation, raw
authority, receiver-plan consumption, managed/persistent separation, unresolved semantic nodes, and
typed runtime/helper reasons. Do not run unrelated expensive invariants after every rewrite. The
printer must fail on unresolved semantic intent rather than repairing it.

## Slice 5: ownership extraction

Move the proven interpolation, receiver-plan, and invariant implementations into focused modules
only after scoped/all-pass byte parity and runtime evidence. Preserve registry IDs, order,
applicability, metadata, request-local state, and generated behavior. This is ownership cleanup, not
a broad rewrite.

## Cross-cutting invariants

- One compiler and one source semantic contract.
- Structural AST before target text for ordinary compiler-owned lowering.
- A semantic plan must pass the admission test in the architecture decision.
- Printer owns syntax and escaping only.
- Explicit raw authority remains distinct and source-attributable.
- No app, path, profile, function-name, or printed-shape heuristic establishes semantic ownership.
- Managed representation and runtime ABI remain owned by `haxe.elixir.codex-0yn.10.3.*`.
- HXX/HEEx stays structural where current nodes permit; broader template modeling requires inventory
  evidence and a separately decision-complete follow-up.
- Public behavior and generated output do not change during inventory or mechanical extraction.
- Compiler changes update docs/examples and generated outputs in the same slice when behavior moves.

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
