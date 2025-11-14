Reflaxe.Elixir 1.0 – Compiler + Todo-App PRD
============================================

Vision
------

Deliver a production‑quality Haxe→Elixir compiler that:

- Uses a **pure AST pipeline** (TypedExpr → ElixirAST → transforms → printer).
- Generates **idiomatic Elixir/Phoenix/Ecto/OTP** code that looks hand‑written.
- Builds and runs the **todo-app** as a first‑class end‑to‑end test with:
  - Zero Haxe compiler warnings.
  - Zero Mix compile warnings (warnings‑as‑errors clean).
  - Zero runtime warnings/errors in Phoenix logs under LiveView + Playwright smoke.
- Compiles within **bounded time** – no apparent hangs, no unbounded passes.

This document ties together the existing 1.0 PRD (docs/08-roadmap/1.0-PRD.md) and the active todo‑app PRD (docs/08-roadmap/ACTIVE_PRD.md) with the latest findings about transformer performance and the regression at commit `76abdeb3`.

Non‑Negotiable Constraints
--------------------------

- **AST pipeline only**
  - All compilation must go through ElixirAST; no string concatenation emitters.
  - No alternative backdoors that bypass builders/transformers/printer.

- **No band‑aids**
  - Fix root causes instead of masking symptoms.
  - No TODOs left in production code as “temporary” workarounds.
  - No arbitrary limits added just to break infinite loops.
  - No string post‑processing to patch bad output.
  - No `-D analyzer-optimize` in server builds.

- **No app‑specific heuristics**
  - Transformers must not key behavior on todo‑app names, atoms, routes or variable names.
  - Allowed decisions are based on shape (AST, annotations, types) and documented APIs, never on domain words like “todo”, “updated_todo”, “toggle_todo”.

- **Runtime artifact rule**
  - Do not edit generated `.ex` files to fix behavior.
  - All fixes must be made in compiler `.hx` sources or std/_std Haxe sources and validated via snapshots and QA sentinel.

- **Module size constraint**
  - Any compiler `.hx` module (builders, transformers, helpers) must remain **< 2000 LOC**.
  - If approaching the limit, extract into domain modules (e.g. CaseBinderTransforms, AssignHygieneTransforms).

- **No Dynamic expansion**
  - Avoid introducing `Dynamic` in public compiler APIs or std externs.
  - Only use `Dynamic` at unavoidable boundary points; prefer precise types everywhere else.

Architectural Invariants
------------------------

The following invariants extend the 1.0 PRD (docs/08-roadmap/1.0-PRD.md) with concrete expectations for the transformer stack and performance:

- **ElixirASTTransformer is a registry, not a brain**
  - It wires passes in a clear order and forwards to domain modules.
  - It does not embed complex logic that belongs in dedicated transformers.

- **Transformers are grouped by responsibility**
  - Core semantic transforms (loops, pattern matching, Phoenix/Ecto behaviors).
  - Cosmetic/hygiene transforms (underscore/alias cleanup, unused assign removal).
  - Late, narrow sweeps (minimal final repairs only when needed).

- **Single‑pass bias**
  - Prefer single AST traversals that compose analyses rather than separate passes that re‑walk the entire tree.
  - Where multiple passes are required, each must be bounded and avoid O(N²) patterns on large modules such as `server.live.TodoLive`.

- **Target‑conditional stdlib gating**
  - Elixir specific std/_std and `__elixir__()` helpers are only placed on the classpath when the target is Elixir.
  - Macro context and non‑Elixir targets see stock Haxe stdlib.

Regression Context: 76abdeb3
----------------------------

Bisect results show that:

- The first commit where the Haxe server build for the todo‑app “hangs” (exceeds strict timeouts) is **`76abdeb3`**.
- That commit introduced a large batch of **LHS/binder/assign hygiene transformers** and rewired **ElixirASTPassRegistry** to run them.
- `server.live.TodoLive.hx` is unchanged between the known‑good baseline and HEAD; the regression is entirely in the compiler transforms and registry, not in app code.

This PRD encodes a requirement: **1.0 must ship with these transformer families architecturally sound and bounded**, and with a clear partition between semantic and cosmetic passes.

Milestones and Success Criteria
-------------------------------

### M1 – Compiler Core Stable and Snapshot Suites Green

- All snapshot categories are green:
  - Core, stdlib, regression, phoenix, ecto, otp and any cross‑migration suites.
- The AST pipeline is the only compilation path and is fully documented.
- ElixirASTPassRegistry is clearly partitioned into:
  - Core semantic passes.
  - Cosmetic hygiene passes.
  - Minimal late repair passes.
- No snapshot indicates unbounded or pathological transform behavior (no timeouts in snapshot runners under documented caps).

### M2 – Bounded Haxe Server Build for Todo-App

- Cold Haxe server build for todo‑app:
  - `cd examples/todo-app && HAXE_USE_SERVER=0 haxe build-server.hxml`
  - Completes within **< 30 seconds cold** on reference hardware.
- LiveView only pass (build-server-passF.hxml) for `server.live.TodoLive`:
  - `HAXE_USE_SERVER=0 haxe build-server-passF.hxml`
  - Completes within **< 15 seconds cold** on reference hardware.
- No Haxe step (including multi‑pass A1..F) is treated as “hanging” by our time‑bounded wrappers.

### M3 – Todo-App QA Sentinel: Zero Warnings, No Runtime Errors

- QA sentinel run for todo‑app (non‑blocking, bounded):

  - `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline <CAP> -v`

- Guarantees:
  - Haxe build step(s) pass under caps with **zero Haxe warnings**.
  - `mix compile` (with `--warnings-as-errors` where configured) succeeds with **zero warnings**.
  - Phoenix server boots and readiness probes succeed.
  - Runtime logs show **no warnings or errors** for LiveView lifecycle, Ecto calls, or PubSub.

### M4 – Playwright Smoke and Regression Specs Within Caps

- Playwright E2E specs in `examples/todo-app/e2e/` (at least basic and search, possibly additional high‑value flows):
  - Run against the QA sentinel controlled server (or equivalent bounded server lifecycle).
  - All specs pass with total runtime **≤ 120 seconds**, ideally **≤ 60 seconds**.
  - Individual specs remain **≤ 30 seconds**.
- Selectors and flows are resilient (no flakiness due to brittle selectors).

### M5 – CI Running Bounded Sentinel + Playwright on Main

- CI pipeline runs:
  - Haxe snapshot suites.
  - QA sentinel for todo‑app with configured caps.
  - Playwright smoke/regression against the same server.
- All CI steps:
  - Complete within documented time budgets.
  - Produce **zero warnings** and **zero runtime errors**.
- Main branch reflects this configuration; legacy branches or modes that allowed hangs or unbounded passes are retired.

Transformers and Performance Requirements
-----------------------------------------

To satisfy M1–M3 for the regression case at `76abdeb3`, the following are explicit requirements:

- **Transformer profiling**
  - ElixirASTTransformer must support a `-D hxx_instrument_sys` mode that logs per‑pass timings (`[PassTiming] name=<pass> ms=<time>`).
  - We must profile `server.live.TodoLive` to identify the passes that dominate runtime, especially in the Case*/LocalAssign*/DropUnused*/SanitizeAssignLhsIdentifier/RefDeclAlignment/FinalLocalReferenceAlign/ZeroAssignCallToBareCall families.

- **Partitioning semantic vs cosmetic passes**
  - Cosmetic hygiene passes are gated behind `fast_boot` and `disable_hygiene_final` so they do not run for example/dev builds.
  - Semantic passes (required for correct code generation) remain active in all profiles but must be refactored to bounded algorithms.

- **Bounded algorithms**
  - Essential transformer passes must not perform repeated full‑AST scans that scale poorly on large modules like TodoLive.
  - Passes must:
    - Build reusable indices (maps from IDs to binders, from clause indices to metadata).
    - Avoid nested loops over all clauses or statements where possible.
    - Include explicit complexity guards and fallbacks for unusually large functions or modules.

fast_boot vs full_prepasses Profiles
------------------------------------

We distinguish two main compilation profiles:

- **fast_boot (example/dev/todo-app profile)**
  - Minimal macro loader and macro scope.
  - Core semantic transformers only.
  - Cosmetic hygiene and late heavy passes disabled or significantly reduced.
  - Used by:
    - `examples/todo-app/build-server-fast.hxml`
    - `build-server-passA1..F.hxml`
    - QA sentinel Haxe builds.

- **full_prepasses / full_hygiene (compiler/CI profile)**
  - Full macro set (HXX/HXXMacro/RouterBuildMacro/ModuleMacro) with carefully scoped triggers.
  - Full transformer stack, including hygiene passes, for maximum safety and cleanliness.
  - Used by:
    - Compiler snapshot and integration tests.
    - Specialized validation builds (e.g., gating checks or stress tests).

Todo-App as 1.0 Quality Bar
---------------------------

The existing ACTIVE_PRD (docs/08-roadmap/ACTIVE_PRD.md) defines the todo‑app as the primary quality benchmark. This PRD refines that:

- Todo‑app must:
  - Compile from Haxe to Elixir via the AST pipeline under the fast_boot profile.
  - Compile Elixir via Mix with warnings as errors.
  - Run under Phoenix with LiveView and PubSub features fully functional.
  - Pass Playwright smoke/regression specs under caps.
  - Produce no warnings or errors in logs throughout that flow.

Verification Layers
-------------------

1. **Compiler/unit layer**
   - Snapshot suites for AST → Elixir printer output.
   - Haxe‑authored ExUnit tests for key Phoenix/Ecto/OTP integration points.

2. **Integration layer**
   - QA sentinel (Haxe build + mix compile + Phoenix boot + readiness) with strict timeouts and log scanning.

3. **Application/E2E layer**
   - Playwright specs checking key todo‑app flows (home, list, search, create, toggle, edit).

All new work toward 1.0 must declare which layer(s) it verifies via and must use QA sentinel for runtime verification whenever the compiler or std changes could affect the example app.

Non‑Goals for This PRD
----------------------

- Supporting new language features or frameworks beyond what Phoenix/Ecto/OTP integration requires for 1.0.
- Introducing experimental backends or printers.
- Micro‑optimizing the generated Elixir at the expense of clarity.

Links
-----

- docs/08-roadmap/1.0-PRD.md – high‑level Reflaxe.Elixir 1.0 PRD and roadmap.
- docs/08-roadmap/ACTIVE_PRD.md – todo‑app focused 1.0 readiness PRD.
- docs/05-architecture/AST_PIPELINE_MIGRATION.md – AST pipeline migration details.
- docs/03-compiler-development/TESTING_INFRASTRUCTURE.md – snapshot and test architecture.
- docs/05-architecture/COMPILER_REFACTORING_PRD.md – refactoring goals and file size constraints.

