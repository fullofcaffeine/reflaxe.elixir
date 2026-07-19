# Structural Elixir AST and focused semantic plans

Status: **accepted direction for staged 1.x work; exhaustive structural traversal is implemented,
while later semantic/runtime slices remain gated**

Planning issue: [GitHub issue #38](https://github.com/fullofcaffeine/reflaxe.elixir/issues/38)

Implementation plan: [Structural AST and semantic plans](../../plans/active/semantic-plans-and-structural-ast.md)

## Beginner-readable reason

The compiler already translates typed Haxe into a structured Elixir tree before printing source.
That tree, `ElixirAST`, is Reflaxe.Elixir's existing target-specific intermediate representation.
That is the right architecture. The problem begins when an ordinary compiler-owned expression is
printed too early and then stored as raw text. A more immediate prerequisite is that every
structural child must be visible to generic traversal at all: otherwise a new node can be perfectly
typed yet silently become a leaf to analysis.

Consider a Haxe expression such as:

```haxe
final label = 'Account: ${account.name}';
```

The Haxe typer knows that `account.name` is a field access with a type and source position. The
Elixir AST can represent that field access structurally. Today, however, the interpolation pass may
print the field expression and replace the concatenation with raw target text resembling:

```elixir
"Account: #{account.name}"
```

The target text is valid, but later compiler passes can no longer visit `account.name` as an AST
node. A variable-usage or rename pass must scan characters inside the string, rediscover braces,
skip quoted text, and guess which tokens are identifiers. If the expression later needs a binder
rename, an IIFE, or a target-specific rewrite, every scanner must agree. A missed case can produce an
undefined variable, invalid escaping, or an expression evaluated in the wrong scope.

The intended structural form keeps literal and expression parts separate until printing:

```text
InterpolatedString([
  Literal("Account: "),
  Expression(Field(Var("account"), "name"))
])
```

Now ordinary AST traversal sees the field expression, and only the printer owns `#{...}` syntax and
escaping. This is a richer target AST, not a new compiler backend.

## Decision

Reflaxe.Elixir will preserve its existing ordered pipeline and make request-level determinism an
executable contract:

```text
TypedExpr
  -> typed analysis and builders
  -> ElixirAST (structural target nodes plus admitted semantic markers)
  -> scoped, ordered legalization and structural passes with executable contracts
  -> printer-legal structural ElixirAST
  -> formatting-only printer
  -> generated Elixir
```

The project will **not** copy haxe.c's whole-program `HxcIR`, replace `ElixirAST`, or force Elixir
through a C-shaped control-flow graph. Instead it will:

1. centralize exhaustive structural and pattern-child traversal before admitting another node;
2. freeze the effective pass order, fail closed on registry errors, and keep groups transparent;
3. keep compiler-owned values structural for as long as later passes need to inspect them;
4. classify and constrain raw target authority rather than treating every raw node alike;
5. introduce a small typed semantic plan only when one observable Haxe invariant otherwise depends
   on repeated target-text/shape inference or synchronized side tables;
6. validate important preconditions and postconditions at the pass boundary that owns them; and
7. lower each semantic plan once before the printer.

Portable and Elixir-first authoring remain profiles over one semantic compiler contract. This
decision creates no profile-selected representation, alternate backend, or public mode.

## Compatibility with the current transformer pipeline

This is an incremental extension of the existing transformer pipeline, not a replacement for it.
Most current transforms operate on ordinary structural `ElixirAST` and can continue unchanged once
a focused semantic node has been lowered. Compatibility follows these rules:

1. One authoritative no-default schema explicitly maps the immediate children of every
   `ElixirASTDef` constructor.
2. One coordinated exhaustive mapper owns `EPattern`, including AST values in literals, map keys,
   and binary sizes.
3. The shared mapper owns structure, not lexical meaning. Scope-sensitive transforms add the
   smallest local binder policy they need; raw target text and AST-valued metadata stay opaque by
   default until a concrete consumer proves otherwise.
4. One named semantic owner validates and consumes each focused plan.
5. A legacy structural transform that cannot interpret an unresolved semantic node runs after that
   owner or rejects the node through typed applicability or a boundary invariant.
6. Equality/digest, result behavior, legality, printer disposition, and source/metadata preservation
   are decided whenever a new `ElixirAST` case is admitted.

Transforms that currently infer source meaning from printed text or target map/struct shape are not
silently grandfathered in. Reviewed source evidence identifies the debt; focused compiler tests,
typed authority, and phase ownership make the replacement executable. Consequently, strengthening
`ElixirAST` requires a traversal foundation and may require focused pass updates, but it does not
require a wholesale transformer rewrite or automatic pass rescheduling.

## Lessons adopted from LLVM and MLIR

[LLVM's relevant lesson](https://llvm.org/docs/NewPassManager.html) is that a pass must state which
analyses remain valid after it changes the IR; stale cached analysis is a correctness bug, while
recomputing every analysis after every pass is needlessly expensive. [MLIR adds a useful
progressive-lowering model](https://mlir.llvm.org/docs/DialectConversion/): an owned conversion
boundary declares operations legal, illegal, or conditionally legal and fails when required
legalization is incomplete.

Reflaxe.Elixir adopts those principles in a lightweight form:

- every focused semantic family has a declared legal phase range and one lowering owner;
- the owner verifies its preconditions and postconditions;
- transforms explicitly preserve or invalidate affected cached analyses;
- unresolved semantic nodes are illegal at the printer boundary; and
- stable pass IDs and before/after diagnostics explain failed legalization.

It does not adopt LLVM's low-level SSA instruction set as a universal source representation, force
Elixir through a C-shaped CFG, depend on MLIR, or create a general dialect framework. Elixir's own
structured expressions, pattern matching, guards, exceptions, and immutable values remain visible
in `ElixirAST`.

## Reviewed baseline and current implementation

The architecture review baseline was statically rechecked against repository head
`40254f38d9c07c069c7c3e19831096dcc2d6c95d`:

- compilation follows `TypedExpr -> ElixirAST -> ordered transforms -> ElixirASTPrinter`;
- `ElixirASTDef` has 66 constructors and `ElixirMetadata` has 136 optional fields;
- `transformNodeScopedInternal`, `iterateAST`, and `transformAST` implement overlapping child
  switches with leaf catch-alls; the latter two omit many child-bearing forms;
- `iterateAST` skips `EReceiverEffect.operation`, function guards, module attribute values, macro
  bodies, quote/unquote, sends, and AST values embedded in patterns;
- `ASTUtils.walk` delegates to that incomplete walker, so `PassApplicability` inherits its omissions;
- identity rebuild in the generic scoped transformer can drop optional `EAttribute` span fields;
- the validated registry has 578 effective granular passes but normal compilation executes seven
  bundle functions whose private inner loop hides granular result, timing, snapshot, and future
  invalidation/legality boundaries;
- registry validation drops duplicate names, does not validate missing `runBefore`, and tolerates
  missing names/cycles during scheduling even though the checked healthy inventory reports none;
- `LoopIR` is a useful narrow-plan experiment, but successful emission still uses placeholder
  `ENil`, confidence scoring, `originalExpr` re-analysis, and an `EnumReduce` legacy fallback;
- `EReceiverEffect` and receiver-return conventions already preserve part of the immutable
  receiver-rebinding problem as explicit intent;
- receiver lowering currently runs before and after the registry, followed by a final accumulator
  replay, so the marker does not yet have exactly one phase owner;
- `FunctionResultInvariant` detects when a named pass loses a non-`Void` result carrier;
- that invariant models numeric tails that the printer later discards, exposing hidden semantic
  ownership in the formatting layer;
- the printer also injects exception declarations, scans or qualifies Repo/module references,
  allocates loop names from static state, and performs other target-policy work;
- `stringInterpolationPass` in `ElixirASTTransformer.hx` prints embedded AST expressions and returns
  `ERaw` containing a complete Elixir string literal;
- `VarUseAnalyzer`, `OptimizedVarUseAnalyzer`, scoped rewriters, loop restoration, binder repair, and
  other transforms consequently scan interpolation or raw-code text for identifiers;
- some passes print AST subtrees to compare shapes or to build another node; and
- explicit raw Elixir and externally validated template/DSL boundaries remain legitimate public or
  framework authorities.

The traversal portion of that baseline has since been addressed by one fused structural engine in
`ElixirASTTransformer` plus the coordinated `ElixirPatternChildren` schema. All 66 AST constructors
and all 11 pattern constructors have executable constructor-set and immediate-child coverage;
immediate map/visit and recursive walk entry points derive from the same AST switch. Expanded
traversal exposed one real anonymous-function scope omission in
`ClauseUndefinedRefRewrite`, which is fixed at that pass and covered by the ordinary-Haxe
`core/maps` reducer regression. The remaining bullets are reviewed debt, not claims that every later
architecture slice has shipped.

The existing generated pass inventory freezes pass order and count. Each implementation slice adds
a focused Haxe-authored contract test for the invariant it introduces, while source-level snapshots,
runtime tests, package checks, and determinism evidence protect behavior. Do not add a parallel
architecture receipt or semantic-boundary inventory: those artifacts duplicate executable tests and
couple CI to incidental source text.

## Why haxe.c needs more IR than Reflaxe.Elixir

haxe.c targets strict C11. C does not directly provide Haxe's evaluation order, exceptions,
garbage-collected objects, strings, collections, checked conversions, cleanup, or reference model.
For a call such as `consume(next(), next())`, C call syntax alone cannot prove which `next()` runs
first. haxe.c therefore earns a validated semantic layer that records ordered instructions, mutable
places, failure successors, cleanup regions, representation, bounds, and runtime intent before C
syntax is selected.

Elixir has a different gap. It already provides ordered expression evaluation, immutable values,
pattern matching, exceptions, garbage collection, closures, tuples, maps, binaries, and process
semantics. `ElixirAST` can represent most target choices directly and structurally. A C-like CFG
would discard useful Elixir structure and make ordinary generated modules harder to reason about
without solving a demonstrated problem.

The reusable lesson from haxe.c is not its schema. It is its admission rule:

> Make a lower semantic fact explicit when removing it would recreate several loosely synchronized
> analyses or force the target emitter to infer source meaning.

That rule supports focused plans in Reflaxe.Elixir while rejecting a speculative universal IR.

## Cross-compiler lessons adopted selectively

The reference compilers support different architectures because their targets exert different
pressure; they are evidence, not templates to copy mechanically.

- **Genes TS:** immutable reachability, temporary, and ABI plans can be better than a target AST when
  the target stays close to `TypedExpr`. Reflaxe.Elixir keeps `ElixirAST` because it already performs
  substantial shared target-structure rewriting, but adopts the plan-minimization and deterministic
  pre-emission facts.
- **Reflaxe.Rust:** a central exhaustive target-tree mapper is the useful precedent for constructor
  safety. Its small runner is not copied into a 578-pass compiler.
- **Reflaxe.Go:** duplicate/dependency/cycle validation should fail closed. Its smaller pipeline does
  not justify automatic rescheduling of this mature list.
- **Reflaxe.Ruby and Reflaxe.OCaml:** narrow callable, runtime, place, or evaluation plans are the
  closest precedent for receiver and ABI gaps. The plan earns its fields through independent
  consumers or validators rather than becoming a second tree.
- **haxe.c:** a durable semantic IR is appropriate only when evaluation, places, cleanup, lifetime,
  failure, representation, and undefined-behavior pressure are broad and recurring. Elixir does not
  currently meet that threshold.

The reusable rule is to choose the least powerful representation that preserves the target's real
semantic gaps and can be independently verified.

## Layer ownership

| Layer | Owns | Must not own |
| --- | --- | --- |
| Haxe `TypedExpr` | Resolved Haxe types, declarations, source positions, and frontend desugaring | Elixir punctuation or final runtime layout |
| Focused semantic plan | One proven cross-phase Haxe invariant and the typed facts needed to validate it; it may feed the builder or exist temporarily as an admitted marker carried by `ElixirAST` | A copy of every `TypedExpr`, unrelated semantic families, target formatting, or a parallel general-purpose pipeline |
| `ElixirAST` | Structural Elixir expressions, patterns, clauses, modules, templates, typed target metadata, and bounded semantic markers until their one owned lowering boundary | Recovery of facts already erased into strings or unresolved semantic intent at the printer boundary |
| Fused AST traversal and pattern schema | Exhaustive structural children, deterministic order, metadata/position preservation, and derived immediate/recursive APIs | Lexical scope, completion flow, quote/raw authority, or implicit metadata traversal |
| Pass manager | Stable IDs, transparent groups, frozen effective order, context, diagnostics, failure, legality, and analysis invalidation | App/path/name heuristics, implicit profile semantics, or hidden inner runners |
| Validators | Structural, phase, result, ABI, and final legality checks | Repairing the tree |
| Printer | Delimiters, precedence, escaping, interpolation spelling, indentation, and surface syntax | Semantic repair, binder discovery, runtime selection, or framework policy |
| Explicit raw authority | Reviewed user injection or externally owned source that cannot be represented honestly yet | Ordinary compiler-owned lowering by convenience |

## Traversal contract

`ElixirASTTransformer.transformNodeScopedInternal` owns every structural `ElixirAST` child for all
66 constructors, and `ElixirPatternChildren` owns all 11 pattern variants and their embedded AST
values. The authoritative switches have no catch-all branch. `transformAST` derives a one-level map
from the fused engine by treating direct children as transformable boundaries; `iterateAST` derives
visiting from that map; `ASTUtils.walk` supplies recursion without another constructor switch.

This is one structural traversal contract, not a family of speculative universal walkers. Ordinary
Mapping preserves metadata, source positions, optional payload fields, and attribute spans. Raw
target injection is opaque. Metadata is preserved but not entered. Object identity is not a public
traversal contract; semantic and generated-output behavior are the regression boundary.
Transforms that care about lexical binders or a deliberate boundary such as an anonymous function
express that policy locally, as `ClauseUndefinedRefRewrite` now does for anonymous-function clause
arguments.

The Haxe macro test compares the runtime enum constructor sets with its explicit samples, verifies
immediate child counts and deterministic order, and exercises boundary/raw behavior. Adding a
constructor is incomplete until the structural schema and focused contract test classify it;
printer or legality work is added only when the new constructor's actual role requires it.

## Pass-manager and analysis contract

The current effective 578-pass list is behavioral data. During this migration it remains the
scheduling source of truth. Ordering metadata is validated against that list; it does not silently
topologically move mature passes. Duplicate IDs, missing hard dependencies, cycles, and phase
regressions fail. Optional edges are typed as optional.

The seven contributor-facing groups remain useful, but become transparent scheduling groups rather
than functions containing a second pass runner. Each granular child remains visible to result
tracking, diagnostics, timing, snapshots, legality, and analysis invalidation.

Analysis state is request-local and keyed by AST revision. A changed or legacy-unknown pass
invalidates cached AST analyses unless preservation is explicitly proven. Migration does not force
all legacy passes to claim a precise change set at once, and it does not recompute an expensive
capability inventory after all 578 passes merely for architectural appearance. Each analysis moves
under invalidation only after cached and forced-recomputed results agree under bounded profiles.

## Admission test for a semantic plan

A new semantic plan is justified only when all of these are true:

1. **Observable invariant:** it preserves a named Haxe or external-ABI behavior, not a formatting
   preference.
2. **Cross-phase pressure:** the invariant spans more than one target construct or pass boundary.
3. **Current evidence:** the existing implementation needs repeated string/shape/name inference,
   mutable global state, or several synchronized side tables to retain that behavior.
4. **Closed model:** the proposed plan has typed inputs, outputs, source positions, validation, and
   explicit unsupported/conflict states.
5. **Single lowering owner:** one named boundary consumes the plan; the printer never completes or
   repairs it.
6. **Incremental adoption:** unrelated expressions continue through the existing pipeline without
   translation into the new model.
7. **Executable proof:** focused semantic/runtime fixtures and pass invariants can distinguish a
   correct plan from a renamed AST node.

If a proposed node merely renames a `TypedExpr` or `ElixirAST` case and adds no independently
testable invariant, it stays in the existing layer.

## Raw authority taxonomy

The later typed raw-authority and legality work must assign every admitted raw or print/re-embed
boundary to one owner. The regression baseline deliberately does not make this semantic judgment:

| Class | Meaning | Policy |
| --- | --- | --- |
| Explicit user injection | `__elixir__()` or another documented target escape hatch | Keep opaque, mark authority and source position, fail closed in analyses that require structure |
| Validated external source | A framework/template/DSL compiler returns target text under a checked contract | Keep only at the narrow boundary; record producer and validation contract |
| Migration debt | Compiler-owned lowering is text because a structural target node or traversal is missing | Replace incrementally, starting with highest semantic visibility loss |
| Invalid ordinary lowering | The compiler prints and re-parses/re-scans its own semantic child without an explicit authority | Reject in new code and migrate existing sites |

Raw-node count alone is not a progress metric. The useful measures are approved authority coverage,
eliminated compiler-owned text boundaries, and fewer semantic scanners.

## First new structural-node slice: interpolation

After traversal and pass-boundary infrastructure is safe, the first new structural node is a closed
interpolated-string form (exact name provisional) with literal and expression parts. Its contract is:

- literal text is stored unescaped or canonically escaped exactly once;
- embedded expressions remain `ElixirAST` nodes with metadata and source positions;
- normal traversal, use analysis, renaming, equality, and scope analysis visit embedded expressions;
- IIFE or expression legalization remains structural;
- the printer alone writes quotes, escapes literal `#{`, and emits `#{expression}`;
- explicit raw strings remain a different authority; and
- no pass prints an embedded expression merely to attach it to the string.

Migration must cover both `ERaw("...#{...}...")` produced by the interpolation pass and `EString`
values whose later passes currently treat `#{...}` as target code. Adversarial coverage includes
nested braces, quotes, backslashes, literal `#{`, newlines, field/index access, calls, blocks,
renamed binders, loop variables, and expressions that throw.

## First focused plan: persistent receiver effects

The next bounded semantic family is receiver mutation over immutable BEAM values. It already has a
partial explicit form (`EReceiverEffect`) and a centralized convention table, making it a safer
candidate than inventing a new family from scratch.

The marker/plan stores only irrecoverable behavioral variants:

- receiver identity and representation category;
- structural source operation and source position;
- whether the source result is the updated receiver, a separate value, or both;
- the writable binding/writeback target, if any; and
- an optional stable classification/decision ID when cross-node validation needs it.

Left-to-right evaluation and ordinary failure behavior are invariants of the one owner unless a real
operation variant needs additional data. Control-flow joins belong in scoped lowering context or a
separate proven state plan, not as a full CFG summary copied onto every marker. Runtime/helper prose
belongs in classification evidence; it is not repeated as free-form payload.

The plan is valid only for declared persistent value APIs. Managed Haxe reference carriers use the
separate managed-reference semantic nodes and shared-storage writes; they must never become caller
receiver rebinding. Unknown `Dynamic` writes fail unless their domain and writeback target make the
effect unambiguous.

This slice coordinates with, but does not take ownership from, the selective managed-reference ABI.

## Managed-reference ownership

The managed-reference program already owns representation analysis, ABI descriptors, managed
allocation/get/put/identity/dispatch nodes, native-value conflicts, package manifests, and lowering
order. That work remains under `haxe.elixir.codex-0yn.10.3.*` and
[Managed Reference ABI](MANAGED_REFERENCE_ABI.md).

This decision owns only reusable structural and invariant infrastructure:

- AST traversal must be able to visit any embedded managed expression;
- raw authority cannot erase a representation ID or managed operation;
- pass contracts can assert that managed nodes do not enter persistent receiver lowering; and
- the printer rejects unresolved semantic nodes.

No task in this plan may redefine managed representation categories, runtime layout, collector,
public support gates, or package ABI.

## Executable pass contracts

Pass checks should attach to the smallest boundary that owns the behavior. The initial contracts
are:

- interpolation expressions remain structural and source-attributable until printing;
- approved raw authority is explicit, and an ordinary lowering cannot introduce unclassified raw
  code;
- a persistent receiver plan is consumed exactly once and has a legal writeback target;
- managed targets never enter receiver-rebind lowering;
- no unresolved semantic-intent node reaches the printer;
- the non-`Void` result contract remains valid; and
- typed runtime/helper reasons agree with the lowered AST usage for the selected family.

These checks are not a request to run every whole-tree invariant after every rewrite. They should be
cheap in normal builds where practical, more detailed under the existing compiler validation
defines, and actionable when they fail.

Legality applies to semantic and authority families, not every ordinary Elixir syntax constructor.
Each admitted family declares its construction domain, legal phase range, one owner, and
post-owner status. Existing debt begins report-only; already-owned failures such as a receiver
marker at printer readiness remain hard errors.

## `LoopIR` status

`LoopIR` supports the architectural idea of a local plan, but is not evidence that its current
schema is complete. It still uses placeholder target nodes, a floating confidence score,
`originalExpr` re-analysis in emitters, and a nominal reduce strategy that falls back to legacy
emission. The tightening task replaces successful paths with closed variants and explicit `NoMatch`
or unsupported reasons. A successful emitter consumes only the plan; the original typed expression
remains outside it solely for fallback. This remains a builder-local plan, not a whole-compiler CFG.

## HXX and HEEx

Typed HXX/HEEx should keep template structure, attributes, control constructs, and embedded
`ElixirAST` expressions visible until the template printer. The interpolation slice establishes the
generic part of that model. The typed authority slice will classify remaining
`ESigil(content:String)` and raw
HEEx producers before any template-AST expansion is approved.

External raw HEEx remains valid only through the documented explicit authority. A broad template IR
will not be designed speculatively; it earns a follow-up only when a focused typed audit and failing
examples show a closed repeated semantic family that ordinary `ElixirAST` fragments cannot
represent.

## Pass/module decomposition

Large files are not split merely to reduce line counts. After structural interpolation,
receiver-effect ownership, and invariant checks have byte/runtime parity, their implementations may
move from `ElixirASTTransformer.hx` into focused modules while preserving:

- stable pass IDs and applicability scopes;
- exact order and dependencies;
- request-local state;
- source positions and metadata;
- generated behavior; and
- focused and all-pass parity.

A mechanical move that leaves ownership or side tables ambiguous does not satisfy this decision.

## Staged implementation and rollback

1. Freeze the existing generated-output, result, pass-order/scope, runtime, package, and determinism
   baselines; record reviewed architecture debt in this decision without creating a parallel audit
   database.
2. Add exhaustive child/pattern traversal, switch the legacy generic entry points onto it, and use
   constructor contracts plus full generated/runtime parity to classify newly reached children.
3. Make registry errors fail closed while preserving the exact effective list.
4. Replace opaque executable bundles with transparent nested groups, initially preserving current
   capability snapshot semantics.
5. Add request-local pass context, conservative analysis infrastructure, and report-only legality.
6. Instrument then consolidate persistent receiver effects under one owner; keep managed carriers
   explicitly excluded.
7. Move numeric-sentinel ownership upstream so result validation no longer models printer repair.
8. Add structural interpolation behind byte/runtime parity, then remove interpolation scanners only
   when structural replacements cover the same cases.
9. Move remaining semantic printer policy upstream and tighten `LoopIR` as independent slices.
10. Extract proven owners without changing registry identity/order, then consider HEEx/framework,
    failure, managed-reference, or further runtime plans only from measured evidence.

Each slice is independently revertible before a public AST/internal contract is relied upon. A
rollback restores the previous internal lowering but must not weaken Haxe behavior, disable result
validation, or convert a managed operation into persistent rebinding. Because internal AST APIs are
not public, node schema changes need source/package parity rather than consumer migration.

## Required evidence

Implementation slices require, proportionate to scope:

- structural AST tests proving traversal and source metadata;
- constructor/pattern coverage, deterministic traversal, and complete generated/runtime parity;
- strict registry negative tests, frozen effective order, and opaque/transparent runner parity;
- request-local determinism and cached/forced-recomputed analysis parity;
- focused interpolation snapshots and BEAM runtime assertions;
- adversarial escaping and binder/scope fixtures;
- pass-order, pass-inventory, and pass-scope guards;
- result-invariant and focused owner-boundary diagnostics where a semantic family actually exists;
- handwritten-output review;
- full snapshot categories for AST/pass changes;
- Haxe-authored ExUnit/stdlib tests where behavior is runtime-visible;
- example compile/output/WAE/runtime gates;
- source/package parity; and
- bounded todo-app sentinel and Playwright coverage for compiler-wide changes.

Tests must exercise ordinary Haxe source. Raw target injection cannot stand in for the source
operation whose lowering is being verified.

## Non-goals

- A copy of haxe.c's HxcIR, CFG, place/lifetime model, or schema versioning.
- A universal Reflaxe IR shared speculatively across targets.
- Replacing `TypedExpr`, `ElixirAST`, or the pass registry; `LoopIR` may be tightened as a local plan.
- Duplicating every Haxe expression in a second tree.
- A big-bang builder/transformer rewrite.
- Treating Portable and Elixir-first as different semantic backends.
- Eliminating documented user raw authority before an honest typed surface exists.
- Inferring framework, runtime, representation, or pass ownership from app names, paths, or printed
  target shapes.
- Claiming managed references, HXX restructuring, or any new public API is implemented by this
  planning decision.

## Confidence and unknowns

| Conclusion | Confidence | Limitation |
| --- | ---: | --- |
| Preserve the existing pipeline instead of adopting HxcIR wholesale | High | Future evidence may justify additional focused plans, not a current whole-program IR |
| Exhaustive child/pattern traversal is the first implementation prerequisite | High | Implemented; the migration exposed and fixed one anonymous-function binder bug, confirming the need for full semantic parity tests |
| Structural interpolation is the first new structural-node seam | High | It follows traversal/pass/result prerequisites rather than preceding them |
| Receiver effects are the best first semantic-plan completion | Medium-high | Exact interaction with `Dynamic` and managed representation must be validated against current main |
| Raw authority can be completely classified | Medium-high | Some framework/template producers may need a temporary migration class |
| A general structural HEEx model should be designed now | Low | Inventory and interpolation evidence must come first |

The main unknown is not whether Reflaxe.Elixir needs “an IR” in the abstract. It already has
`TypedExpr`, `ElixirAST`, and narrow semantic forms. The implementation question is which remaining
source invariants earn one more explicit, validated plan before target syntax is chosen.
