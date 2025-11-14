Transformer Essential Passes – TodoLive/LiveView Focus
=====================================================

Context
-------

- Regression analysis shows the first Haxe compile “hang” for the todo‑app server build at commit `76abdeb3`, which introduced a large batch of binder/assign hygiene transforms and rewired the pass registry.
- Profiling on HEAD using `-D hxx_instrument_sys` and a bounded `build-server-passF.hxml` run indicates:
  - Individual transformer passes all report `<1ms` (`ms=0` after rounding) for modules that complete before timeout.
  - `ElixirASTTransformer.total` per module is typically `4–11 ms`, so no **single** transform pass currently dominates wall‑clock time.
- The hang behavior must therefore be explained by **aggregate work** across many passes and/or by **typed/macro phases** (HXX/TemplateHelpers/etc.), not by one pathological AST pass.

This document identifies **essential** transformer passes that are critical for semantics on LiveView modules like `server.live.TodoLive`, distinguishes them from late hygiene, and records design/complexity expectations for each.

Essential Semantic Pass Families
--------------------------------

The following are considered essential in the context of TodoLive and Phoenix idioms. They must remain active even in fast profiles (fast_boot) and must be kept algorithmically bounded.

### 1. LiveViewTypedEventBridgeTransforms

File: `src/reflaxe/elixir/ast/transformers/LiveViewTypedEventBridgeTransforms.hx`

**Role**

- Generates idiomatic `handle_event/3` callbacks from a typed `handleEvent(enum, socket)` function in `@:liveview` modules.
- Bridges fully typed Haxe event enums to the runtime `handle_event/3` API Phoenix expects.

**Complexity Notes**

- Operates per module:
  - Scans top‑level definitions of a LiveView module.
  - Locates a single `handleEvent/2` (or `handle_event/2`) and its `case` on the event argument.
  - Synthesizes one handle_event clause per case branch, plus a rewrite pass over existing `handle_event/3` clauses.
- Complexity is effectively linear in the size of the module body.
- Profiling does not show it as a wall‑clock hotspot on HEAD for TodoLive.

**Requirements**

- Must not grow beyond linear complexity in the number of clauses and functions in a module.
- Any future changes must:
  - Avoid nested full‑module rescans.
  - Preserve shape‑based behavior (no app‑name heuristics).

### 2. CaseSuccessVarUnifyTransforms (+ CaseSuccessVarUnifier)

File: `src/reflaxe/elixir/ast/transformers/CaseSuccessVarUnifyTransforms.hx`

**Role**

- Reconciles success binders in `{:ok, _x}` patterns with the names actually used in clause bodies, to fix undefined variable issues introduced by earlier underscore hygiene.
- Works in tandem with CaseSuccessVarUnifier to ensure bodies reference a declared success variable.

**Complexity Notes**

- Operates per case expression:
  - For each `ECase`, iterates its clauses once.
  - For each clause, walks the clause body to collect used names into a `Map<String,Bool>`.
  - Applies a simple pattern rewrite when a single underscored binder has a matching usage in the body.
- Complexity is linear in the number of clauses and in the size of each clause body.
- Profiling shows no evidence that this pass is a millisecond‑scale hotspot on TodoLive.

**Requirements**

- Must preserve O(N) behavior (N = total AST nodes in case bodies).
- Future modifications must:
  - Reuse collected usage maps instead of recomputing them.
  - Avoid nested traversals beyond what is strictly necessary for each clause.

### 3. RepoGetBinderRepairTransforms

File: `src/reflaxe/elixir/ast/transformers/RepoGetBinderRepairTransforms.hx`

**Role**

- Repairs trivial `get_*` helpers that accidentally return undeclared locals (e.g., `def get_user(id), do: user`) by reconstructing a `Repo.get(schema, id)` call using shape‑derived data from sibling `Repo.get/2` or `Repo.all/1` calls.
- Prevents hard compile errors without introducing app‑specific naming heuristics.

**Complexity Notes**

- Phases:
  - `collectRepoGetInfo` walks the module’s AST once, collecting repository+schema info into a `Map`.
  - `rewriteFunctions` walks function bodies to identify bare variable returns that match known schema bases.
- Both phases are single‑walk and re‑use the same `Map`, so complexity is linear in the size of the module.
- Profiling does not show it as an outlier; it remains below 1ms per module.

**Requirements**

- Must remain single‑pass per module for info collection and rewrite.
- Future enhancements should:
  - Avoid additional full‑module scans; any extra data should be piggy‑backed onto the existing walk.
  - Maintain the strict shape‑based matching (no dependence on todo‑app names such as “todo”).

### 4. GuardGrouping and PatternMatchingTransforms

Files:

- `src/reflaxe/elixir/ast/transformers/GuardConditionFlattener/GuardGrouping` (via `alias_guardGroupingPass`)
- `src/reflaxe/elixir/ast/transformers/PatternMatchingTransforms.hx`

**Role**

- Normalize nested `if`‑based guard chains in `case` expressions into flatter, idiomatic patterns and conds.
- Serve as foundation for many Phoenix and Ecto pattern rewrites.

**Complexity Notes**

- Grouped around:
  - One pass over the AST to find `ECase` nodes with guard patterns.
  - Per‑clause guard extraction and validation, with bounded, local traversal.
- Profiling indicates these passes are not currently wall‑clock bottlenecks for TodoLive; they remain <1ms per module in timed runs.

**Requirements**

- Continue to operate in at most linear time w.r.t. clause bodies.
- Any additional pattern forms or validations must reuse existing visitor logic and avoid new global rescans.

Summary and Guidance
--------------------

- Essential semantic transforms used by TodoLive (LiveViewTypedEventBridge, CaseSuccessVar* passes, RepoGetBinderRepair, GuardGrouping/PatternMatching) are **already structured as single‑pass or locally scoped traversals**.
- Current profiling shows **no single transform dominates module‑level time**; each pass is effectively sub‑millisecond per module, while `ElixirASTTransformer.total` per module is only a few milliseconds.
- The observed >60s behavior for `build-server-passF.hxml` is therefore more likely due to:
  - The macro/typing phase (HXX/HXXMacro, TemplateHelpers, macro validation), or
  - The cumulative cost of running many passes across many modules, rather than any one essential pass.

For future work:

- If a transform in this list is extended or refactored, the default expectation is:
  - Keep it single‑pass over the module or expression tree.
  - Reuse analysis results via maps/indices instead of scanning the same structures multiple times.
  - Add `-D hxx_instrument_sys`‑aware timing if deeper investigation is needed, but do not couple any logic to todo‑app specifics.

