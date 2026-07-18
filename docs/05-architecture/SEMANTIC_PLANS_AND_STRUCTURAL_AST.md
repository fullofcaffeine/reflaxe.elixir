# Structural Elixir AST and focused semantic plans

Status: **accepted direction for staged 1.x work; no new compiler behavior is enabled by this
decision**

Planning issue: [GitHub issue #38](https://github.com/fullofcaffeine/reflaxe.elixir/issues/38)

Implementation plan: [Structural AST and semantic plans](../../plans/active/semantic-plans-and-structural-ast.md)

## Beginner-readable reason

The compiler already translates typed Haxe into a structured Elixir tree before printing source.
That is the right architecture. The problem begins when an ordinary compiler-owned expression is
printed too early and then stored as raw text.

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

Reflaxe.Elixir will preserve its existing deterministic pipeline:

```text
TypedExpr
  -> focused analysis or semantic plan only where evidence requires one
  -> structural ElixirAST
  -> scoped, ordered passes with executable contracts
  -> formatting-only printer
  -> generated Elixir
```

The project will **not** copy haxe.c's whole-program `HxcIR`, replace `ElixirAST`, or force Elixir
through a C-shaped control-flow graph. Instead it will:

1. keep compiler-owned values structural for as long as later passes need to inspect them;
2. classify and constrain raw target authority rather than treating every raw node alike;
3. introduce a small typed semantic plan only when one observable Haxe invariant otherwise depends
   on repeated target-text/shape inference or synchronized side tables;
4. validate important preconditions and postconditions at the pass boundary that owns them; and
5. lower each semantic plan once before the printer.

Portable and Elixir-first authoring remain profiles over one semantic compiler contract. This
decision creates no profile-selected representation, alternate backend, or public mode.

## What is observed today

At repository baseline `79255c533f33896c0d29de25a704b96e40363961`:

- compilation follows `TypedExpr -> ElixirAST -> ordered transforms -> ElixirASTPrinter`;
- `LoopIR` is a successful narrow precedent: it normalizes several Haxe loop shapes before choosing
  an idiomatic Elixir form;
- `EReceiverEffect` and receiver-return conventions already preserve part of the immutable
  receiver-rebinding problem as explicit intent;
- `FunctionResultInvariant` detects when a named pass loses a non-`Void` result carrier;
- `stringInterpolationPass` in `ElixirASTTransformer.hx` prints embedded AST expressions and returns
  `ERaw` containing a complete Elixir string literal;
- `VarUseAnalyzer`, `OptimizedVarUseAnalyzer`, scoped rewriters, loop restoration, binder repair, and
  other transforms consequently scan interpolation or raw-code text for identifiers;
- some passes print AST subtrees to compare shapes or to build another node; and
- explicit raw Elixir and externally validated template/DSL boundaries remain legitimate public or
  framework authorities.

An initial unclassified search found `ERaw` construction in 101 compiler files, `case ERaw` handling
in 90 files, and `ElixirASTPrinter` references in 56 compiler files. Those counts are **not** a defect
count or a promise to eliminate raw authority. They show why the first implementation slice must
produce a classified, reproducible inventory before broad rewrites.

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

## Layer ownership

| Layer | Owns | Must not own |
| --- | --- | --- |
| Haxe `TypedExpr` | Resolved Haxe types, declarations, source positions, and frontend desugaring | Elixir punctuation or final runtime layout |
| Focused semantic plan | One proven cross-phase Haxe invariant and the typed facts needed to validate it before target selection | A copy of every `TypedExpr`, unrelated semantic families, or target formatting |
| `ElixirAST` | Structural Elixir expressions, patterns, clauses, modules, templates, and typed target metadata | Recovery of facts already erased into strings |
| Pass registry | Stable IDs, typed applicability, ordering, and owned pre/postconditions | App/path/name heuristics or implicit profile semantics |
| Printer | Delimiters, precedence, escaping, interpolation spelling, indentation, and surface syntax | Semantic repair, binder discovery, runtime selection, or framework policy |
| Explicit raw authority | Reviewed user injection or externally owned source that cannot be represented honestly yet | Ordinary compiler-owned lowering by convenience |

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

The inventory must assign every raw or print/re-embed site to one owner:

| Class | Meaning | Policy |
| --- | --- | --- |
| Explicit user injection | `__elixir__()` or another documented target escape hatch | Keep opaque, mark authority and source position, fail closed in analyses that require structure |
| Validated external source | A framework/template/DSL compiler returns target text under a checked contract | Keep only at the narrow boundary; record producer and validation contract |
| Migration debt | Compiler-owned lowering is text because a structural target node or traversal is missing | Replace incrementally, starting with highest semantic visibility loss |
| Invalid ordinary lowering | The compiler prints and re-parses/re-scans its own semantic child without an explicit authority | Reject in new code and migrate existing sites |

Raw-node count alone is not a progress metric. The useful measures are approved authority coverage,
eliminated compiler-owned text boundaries, and fewer semantic scanners.

## First structural slice: interpolation

The first implementation slice adds a closed interpolated-string node (exact name provisional) with
literal and expression parts. Its contract is:

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

The completed plan must record:

- receiver identity and representation category;
- source operation and source position;
- whether the source result is the updated receiver, a separate value, or both;
- evaluation order for receiver and arguments;
- the writable binding/writeback target, if any;
- control-flow joins that must carry the updated value;
- exception behavior and completed effects; and
- the reason a runtime/helper operation is or is not required.

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

## HXX and HEEx

Typed HXX/HEEx should keep template structure, attributes, control constructs, and embedded
`ElixirAST` expressions visible until the template printer. The interpolation slice establishes the
generic part of that model. The inventory will classify remaining `ESigil(content:String)` and raw
HEEx producers before any template-AST expansion is approved.

External raw HEEx remains valid only through the documented explicit authority. A broad template IR
will not be designed speculatively; it earns a follow-up when the inventory shows a closed repeated
semantic family that ordinary `ElixirAST` fragments cannot represent.

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

1. Freeze a machine-readable inventory and authority taxonomy without changing output.
2. Add structural interpolation behind byte/runtime parity, then remove interpolation scanners only
   when their structural replacements cover the same cases.
3. Complete and validate the persistent receiver-effect plan; keep managed carriers explicitly
   excluded.
4. Add semantic-boundary/raw-authority/runtime-reason invariants.
5. Extract the proven owners into focused modules without changing registry identity or order.
6. Consider HEEx/framework, failure, or further runtime plans only from measured inventory evidence.

Each slice is independently revertible before a public AST/internal contract is relied upon. A
rollback restores the previous internal lowering but must not weaken Haxe behavior, disable result
validation, or convert a managed operation into persistent rebinding. Because internal AST APIs are
not public, node schema changes need source/package parity rather than consumer migration.

## Required evidence

Implementation slices require, proportionate to scope:

- structural AST tests proving traversal and source metadata;
- focused interpolation snapshots and BEAM runtime assertions;
- adversarial escaping and binder/scope fixtures;
- pass-order, pass-inventory, and pass-scope guards;
- result-invariant and semantic-boundary diagnostics;
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
- Replacing `TypedExpr`, `ElixirAST`, `LoopIR`, or the pass registry.
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
| Structural interpolation is the best first seam | High | The inventory may reveal prerequisite traversal/equality work |
| Receiver effects are the best first semantic-plan completion | Medium-high | Exact interaction with `Dynamic` and managed representation must be validated against current main |
| Raw authority can be completely classified | Medium-high | Some framework/template producers may need a temporary migration class |
| A general structural HEEx model should be designed now | Low | Inventory and interpolation evidence must come first |

The main unknown is not whether Reflaxe.Elixir needs “an IR” in the abstract. It already has
`TypedExpr`, `ElixirAST`, and narrow semantic forms. The implementation question is which remaining
source invariants earn one more explicit, validated plan before target syntax is chosen.
