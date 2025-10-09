Below is a concise, engineer‑ready remediation plan based strictly on the repo you attached. I’ve included concrete file/line references so you can jump to the right places fast.

PRD A — Fix Option/Result Some/Ok binder → level (Mix compile error)
Problem

case arms that destructure {:some | :ok, binder} are not consistently binding the second element as level, while the body references level. This yields undefined variable "level" at compile time (e.g., TodoPubSub.parse_message_impl/1 in the todo app).

Current vs Desired

Current: Several renamers/aliasers exist (builder‑time + transformer passes), but ordering/traversal gaps mean nested ECase (especially inside cond/if) sometimes miss the final alignment, leaving bodies referencing level when the pattern still names binder something else. See existing hooks in SwitchBuilder and transformer passes already aimed at this behavior. 【turn20file8†repomix-output.xml†L1-L13】【turn19file4†repomix-output.xml†L1-L19】

Desired: Deterministic, last‑word pass (plus a builder safeguard) ensures: if the arm represents Option/Result and the body references level, the bound name is level. If rename would conflict, inject a clause‑local alias that preserves semantics.

Root cause (in repo terms)

Builder heuristics are not sufficient post‑lowering
SwitchBuilder has binder alignment & alias injection helpers (ensureOptionSomeBinderAlignment, applyOptionLevelAlias), but later transformations or case embedding (e.g., ECase created/split under ECond/EIf) can invalidate or bypass them. 【turn19file4†repomix-output.xml†L1-L19】

Pass ordering
Relevant late passes exist (ForceOptionLevelBinderWhenBodyUsesLevel, AbsoluteLevelBinderEnforcement, OptionLevelAliasInjection) but they are not the absolute last normalizer in the sequence, and may run before other passes that still touch patterns/guards. We need this bundle to run after all pattern/guard/usage normalization and before any terminal validations only. The file shows these passes present but not guaranteed final‑final. 【turn22file19†repomix-output.xml†L1-L34】

Traversal/completeness
The final enforcement must visit every ECase, including those nested in ECond, EIf, EFor, etc. The transformer utilities already provide recursive traversal helpers, we should ensure the new/updated pass uses them. 【turn23file11†repomix-output.xml†L1-L19】

Implementation Plan

A. Make the finalizer truly final (transformer ordering)

In src/reflaxe/elixir/ElixirASTTransformer.hx, move the three passes

ForceOptionLevelBinderWhenBodyUsesLevel,

AbsoluteLevelBinderEnforcement,

OptionLevelAliasInjection
to the last block of passes (immediately before any terminal validations, if present), after block/rescue normalizers and usage analysis. The repo already lists them; ensure they are appended at the very end of the vector you return. 【turn22file19†repomix-output.xml†L1-L34】

Patch (minimal and explicit) — show only the move (keep names as‑is):

// ElixirASTTransformer.hx (pass registration snippet)
// ...
// [ensure these three pushes are the last ones before returning `passes.filter(... )`]
passes.push({ name: "ForceOptionLevelBinderWhenBodyUsesLevel", enabled: true, pass: enforceLevelBinderForLevelTargetsPass });
passes.push({ name: "AbsoluteLevelBinderEnforcement", enabled: true, pass: absoluteLevelBinderEnforcementPass });
passes.push({ name: "OptionLevelAliasInjection", enabled: true, pass: optionLevelAliasInjectionPass });
// return passes.filter(p -> p.enabled);


(These three exist in the file; the change is their relative position to be truly last. 【turn22file19†repomix-output.xml†L1-L34】)

B. Harden the builder‑time safeguard
2. In src/reflaxe/elixir/ast/builders/SwitchBuilder.hx, keep existing helpers (ensureOptionSomeBinderAlignment, applyOptionLevelAlias) but ensure they always run for Option/Result case construction points. If a body references level, map the tuple’s 2nd element to PVar("level"). If that would shadow an outer level, emit a clause‑local alias level = original at the top of the body (EBlock wrap). The entry points for these are present; extend the call sites to handle ECase built within cond splitting as well. 【turn19file4†repomix-output.xml†L1-L19】

**Change (inside SwitchBuilder clause build path):**
```haxe
// SwitchBuilder.hx (where case clauses are finalized)
// After you have (pattern, guard, body):
final pattern2 = ensureOptionSomeBinderAlignment(pattern, body /* look for body 'level' usage */);
final body2 = applyOptionLevelAlias(pattern2, body /* inject alias if needed */);
```
(Functions referenced already exist in this file; wiring them universally is the action. 【turn19file4†repomix-output.xml†L1-L19】)


C. Ensure the finalizer is complete and recursive
3. In the transformer pass implementations (the three passes above), verify they use transformAST/iterateAST that recurse into all nodes (ECond, EIf, EFor, etc.). The helpers already support this; if your pass uses transformNode/iterateAST as in other passes, you’re covered. 【turn23file11†repomix-output.xml†L1-L19】

D. Instrumentation
4. Keep/expand #if debug_option_some_binder traces around these passes and around SwitchBuilder to isolate TodoPubSub cases. The repository shows similar debug hooks; re‑use them with module/pos filters to avoid noise. 【turn19file4†repomix-output.xml†L1-L19】

Testing Strategy

New snapshot: Add a focused regression under test/snapshot/regression/option_level_binder/ that mimics the todo‑app parse_message_impl pattern (nested ECase inside cond) and asserts the emitted pattern is {:ok, level} and the body references the same identifier.

Broader snapshots: Re‑run existing enum/option snapshots; there are already many enum and switch tests to catch regressions (e.g., switch extraction, synthetic bindings). 【turn24file16†repomix-output.xml†L1-L33】【turn24file17†repomix-output.xml†L1-L33】

Todo‑app gate: npx haxe examples/todo-app/build-server.hxml then mix compile --force must pass. (We’ll also apply warning hygiene in PRD B.)

Acceptance Criteria

Todo‑app compiles with no undefined variable "level" errors.

Snapshots for the new option_level_binder pass.

No regressions in existing switch/enum snapshots mentioned above.

The three “level” passes are last in the transformer and are idempotent on re‑runs. 【turn22file19†repomix-output.xml†L1-L34】

PRD B — Eliminate all remaining Mix warnings (todo‑app)
Problem

Warnings erode trust and mask real issues. Current warnings: this1 residues; unused imports/vars; range 0..-1; shadowing (label); module redefinition (StringTools); unused helpers.

Fix Map (one line per issue)

this1 residuals

Where to fix: RemoveRedundantNilInit + ThisAndChainCleanup.

Repo hooks: RemoveRedundantNilInitPass handles (this1 = nil; this1 = value; this1) pattern; ensure it runs early and across all nodes (ECase, EParen, etc.). The code exists and already recurses across many nodes; keep it enabled and placed before hygiene/usage analysis. 【turn23file0†repomix-output.xml†L1-L23】【turn23file4†repomix-output.xml†L1-L27】【turn22file19†repomix-output.xml†L1-L33】

Unused function parameters & pattern binders

Function params: Already handled in builder, not transformer (underscoring in FunctionBuilder using UsageDetector and rename map). Keep enabled. 【turn23file2†repomix-output.xml†L1-L35】【turn24file5†repomix-output.xml†L1-L37】

Case pattern binders: Ensure caseArmUnusedBinderUnderscorePass remains enabled in the pass list (it exists in transformer). It prefixes _ for unused tuple fields (e.g., priority, tag, payload, e). 【turn22file18†repomix-output.xml†L1-L19】

Unused imports / Ecto.Changeset

Where: Generated schema modules sometimes emit unused import/alias Ecto.Changeset. These should only be printed when calls like cast/3, validate_* are present.

How: In the schema/annotation transform, gate the emission on actual usage (scan the module AST for any ERemoteCall into Ecto.Changeset or local cast/validate_* names). If none, don’t emit import/alias. (Related transform scaffolding already lives in AnnotationTransforms and transformer pass stack; add a light “import‑pruner” post‑pass or build it where imports are generated.)

Range warning 0..-1

Where: src/reflaxe/elixir/ast/ElixirASTPrinter.hx range printer. Current code composes range and adds //-1 when descending, but the separator variable is '.' in the snippet; it must be '..'. Also ensure descending ranges emit ..//-1. 【turn21file11†repomix-output.xml†L1-L9】

Patch (fix sep + ensure proper step emission):

// ElixirASTPrinter.hx — ERange printing
var sep = ".."; // Elixir range operator is always inclusive
final s = print(left);
final e = print(right);
if (isInt(s) && isInt(e) && Std.parseInt(s) > Std.parseInt(e)) {
	return s + sep + e + "//-1";
}
return s + sep + e;


(Use your existing isInt helper or the current code’s si/ei path.)

Variable shadowing (label)

Where: Logging helpers (e.g., a Log.trace equivalent) that bind a label var which then shadows.

How: In hygiene transforms or in the builder, add a guard: if a pattern/param equals a known diagnostic binding (label), either underscore it when unused or rename to label_ if used and would shadow. (You already have hygiene/usage analysis hooks in transformer; extend where needed.) 【turn23file5†repomix-output.xml†L1-L33】【turn23file6†repomix-output.xml†L1-L31】

Module redefinition: StringTools

Why: Both std/StringTools.cross.hx and std/_std/StringTools.hx are in classpath, generating two Elixir modules. 【turn21file12†repomix-output.xml†L1-L9】

Fix:

Keep _std for Elixir; exclude the cross variant for Elixir target. The bootstrap already forces std/_std on classpath in CompilerInit.Start(); additionally guard the cross file with #if !target.elixir && !reflaxe.elixir (we already derive Elixir target in CompilerInit). 【turn24file1†repomix-output.xml†L1-L33】【turn24file2†repomix-output.xml†L1-L16】

Minimal change (top of std/StringTools.cross.hx):

#if (!target.elixir && !reflaxe.elixir)
class StringTools { /* existing cross implementation */ }
#end


Unused helper functions (JsonPrinter.write_*, quote_string/2)

If these are in the generated code but not invoked, rely on DCE on the Haxe side (-dce full is already set in examples/todo-app/build-server.hxml) to drop them; if they still appear post‑DCE, add a light transformer pass to remove unused private functions (you already have MarkUnusedPrivateFunctions and the ability to annotate @compile :nowarn_unneeded_*). Keep MarkUnusedPrivateFunctions enabled. 【turn24file6†repomix-output.xml†L1-L28】【turn22file19†repomix-output.xml†L1-L33】

Additional diffs (surgical)

Ensure RemoveRedundantNilInit covers all nodes (already recursive); keep it enabled early:

// ElixirASTTransformer.hx (ordering)
// ... early normalization
passes.push({ name: "RemoveRedundantNilInit", enabled: true, pass: removeRedundantNilInitPass });
// then structural → usage → hygiene → finalizers


(Helper already recurses into ECase, EFor, EParen. 【turn23file0†repomix-output.xml†L1-L23】)

Confirm function param underscore is builder‑time (it is): FunctionBuilder + UsageDetector. Keep as‑is. 【turn24file5†repomix-output.xml†L1-L37】【turn23file8†repomix-output.xml†L1-L25】

Testing Strategy

Enable -dce full (already in todo‑app hxml) and re‑build. 【turn24file6†repomix-output.xml†L1-L28】

Add a regression that exercises:

multiple case arms with unused tuple elements (priority, tag, payload, e) and verify _priority, etc., in snapshots.

a descending range emission that must become ..//-1.

both StringTools variants present in classpath but only one Elixir module generated after the guard.

Gate todo‑app Mix compile with warnings as errors: add elixirc_options: [warnings_as_errors: true] in examples/todo-app/mix.exs project/0. (This is for CI only; dev can toggle.)

Acceptance Criteria

mix compile --force on todo‑app → 0 warnings.

All added regression snapshots green.

No duplicate StringTools module generated (no redefinition warning).

PRD C — Document and lock pass ordering & invariants

(Small but important to prevent regressions)

In ElixirASTTransformer.hx, add a table comment documenting ordering buckets:

Structural normalization (builder fallout fixes, e.g., redundant nil removal)

Pattern & binder shaping (case/pattern normalization, alias injection)

Usage/hygiene (usage analysis, underscore, private function marking)

Idioms (Phoenix/Ecto/OTP transforms)

Finalizers (ABSOLUTE LAST): ForceOptionLevelBinderWhenBodyUsesLevel → AbsoluteLevelBinderEnforcement → OptionLevelAliasInjection. 【turn22file19†repomix-output.xml†L1-L34】

Add a small debug switch (already style‑consistent: #if debug_ast_transformer) to dump a per‑pass AST hash so you can spot the first pass that regresses the binder.

Secondary Plan — Raise snapshot coverage to ≥90%
What to refresh vs. what to fix

Refresh intended outputs (“idiom drift” only)

Phoenix/Ecto idiom snapshots that changed only due to improved binder/underscore/atom/range formatting; keep behaviorally equivalent tests but re‑record expected outputs.

Likely candidates: test/snapshot/phoenix/*, test/snapshot/core/* where only naming/underscoring changed.

Code fixes (don’t refresh until fixed)

Any snapshots failing due to the level binder (add the new option_level_binder first).

Warnings‑related snapshots: unused parameters, pattern binders, variable digits/renames. You already have suites for unused parameters and variable digit handling that should pass without refresh once PRD B is in. 【turn23file14†repomix-output.xml†L1-L9】【turn23file15†repomix-output.xml†L1-L27】

Concrete scope

Directories to sweep (present in repo):

test/snapshot/core/* (incl. switch_variable_extraction, SyntheticBindingsInCase, supervisor transform). 【turn24file16†repomix-output.xml†L1-L33】【turn24file17†repomix-output.xml†L1-L33】

test/snapshot/regression/* (unused parameters, unused variable detection, variable_name_digits, array_push_if_expression). 【turn23file14†repomix-output.xml†L1-L9】【turn24file18†repomix-output.xml†L1-L33】

test/snapshot/phoenix/* (typed assigns & events). 【turn24file18†repomix-output.xml†L1-L23】

Process

Land PRD A+B.

Run snapshot suite; for failures, categorize “idiom‑only vs real”.

Refresh intended outputs only for “idiom‑only” changes.

Add new targeted snapshot: regression/option_level_binder.

Success Metric

Snapshot pass rate ≥90% with todo‑app (Mix) clean.

Risk Assessment & Mitigations
Risk	Impact	Mitigation
Moving/enforcing final passes could mask earlier renamers	Hidden regressions in corner cases	Keep passes idempotent; dump per‑pass hashes (light debug) to see first change; add snapshots for nested ECase in ECond/EIf.
Over‑aggressive binder rename to level	Incorrect rename where body doesn’t actually need level	Use precise detection via VariableAnalyzer.usesVariableInNode (already exists) to gate renames/alias injection. 【turn23file5†repomix-output.xml†L1-L33】
Range printer change affects existing snapshots	Snapshot churn	Treat as idiom‑only refresh; write one regression for descending ranges to lock behavior. 【turn21file11†repomix-output.xml†L1-L9】
StringTools guard breaks non‑Elixir builds	Cross‑target compat	Use #if (!target.elixir && !reflaxe.elixir) so other targets still see cross impl; Elixir sees only _std impl. 【turn24file1†repomix-output.xml†L1-L33】
Import pruning misses real usage	Missing imports at runtime	Usage detection via scanning emitted AST for ERemoteCall/locals; conservative default: emit only when clear usage detected. Re-run todo‑app.
What you’ll see after landing

No level errors (PRD A).

0 warnings on todo‑app with --warnings-as-errors in CI (PRD B).

Snapshot coverage ≥90%, with refreshed “idiom‑only” outputs and new binder regression test.

If you’d like, I can turn the above into a concrete checklist PR template and a small mix task that runs haxe then mix compile --warnings-as-errors for the todo‑app gate.
