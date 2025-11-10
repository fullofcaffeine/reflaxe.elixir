# Regression: c07bfa5c — Case binder/body mismatch and camelCase leaks

SUMMARY
- First bad commit: `c07bfa5c` (immediately after good `34a8122d`).
- Symptoms in generated Elixir (todo-app):
  - `value = g` assignments inside `case` branches with no `g` bound.
  - Mixed camelCase identifiers leaking into output: `tempResult`, `defaultValue`, `tempString`.
  - Underscored binders in patterns (e.g., `_value`) while the body still uses `value`.
- Effect: `mix compile` fails; Phoenix cannot boot; perceived “Compiling Haxe files…” hang is the repeated Phoenix log line while compile never finishes.

REPRO STEPS
1) Check out the bad worktree (example):
   - `git worktree add ../wt-c07bfa5c c07bfa5c`
   - `cd ../wt-c07bfa5c/examples/todo-app`
2) Compile directly:
   - `MIX_ENV=dev mix compile`
   - Expected failures (examples below).
3) Non-blocking sentinel (from repo root):
   - `scripts/qa-sentinel.sh --app ../wt-c07bfa5c/examples/todo-app --port 4011 --async --deadline 300 --verbose`
   - Use `scripts/qa-logpeek.sh --run-id <RUN_ID> --last 200 --follow 30` to observe logs.

BROKEN OUTPUT EXAMPLES
1) `examples/todo-app/lib/ecto/changeset_utils.ex` (bad)
```
defmodule ChangesetUtils do
  def unwrap_or(result, default_value) do
    temp_result = nil
    case (result) do
      {:ok, _value} ->
        value = g
        temp_result = value
      {:error, g} ->
        temp_result = defaultValue
    end
    tempResult
  end
  def to_option(result) do
    temp_result = nil
    case (result) do
      {:ok, _value} ->
        value = g
        temp_result = {:some, value}
      {:error, g} ->
        temp_result = {:none}
    end
    tempResult
  end
end
```
Issues:
- `g` is never bound in the `{:ok, _value}` clause.
- camelCase identifiers leak: `defaultValue`, `tempResult`.

2) `examples/todo-app/lib/elixir/otp/child_spec_builder.ex` (bad, excerpt)
```
%{:id => tempString, :start => {module, :start_link, args}, ...}
```
Issue:
- `tempString` camelCase leaked into final Elixir.

SCOPE
- Case/enum patterns compiled from Haxe Option/Result-like constructs.
- OTP supervisor child spec helpers.
- Potentially other pattern-driven transforms that rely on binder ↔ body consistency and snake_case naming.

ROOT CAUSE HYPOTHESIS
- Enum/case canonicalization introduced in `c07bfa5c` altered binder handling:
  - The case pattern binds `_value`/`value`, but builder still emits `value = g` or the body references `g`.
  - Missing/incorrect ClauseContext mapping from temp vars (`g`, `_gN`) to user binders (`value`, `reason`).
- Naming normalization ordering gaps:
  - camelCase→snake_case transforms for locals/params/body references not applied consistently, leaving `tempResult/defaultValue/tempString` in output.
  - Over-eager underscoring of binders used later in the clause body.

FIX PLAN (HIGH LEVEL)
1) Case binder ↔ body unification in ElixirASTBuilder:
   - Inside case clauses, skip emitting `binder = temp` assignments; instead update ClauseContext to map temp.id → binder.id and varIdToName so uses of temp print as the binder.
   - Ensure this runs regardless of optional enum-binding metadata; handle nested cases and parenthesized targets.
2) Consistent camelCase→snake_case normalization:
   - Strengthen LocalCamelToSnakeDecl and DefParamCamelToSnake transforms to rewrite both declarations and all EVar usages.
   - Extend clause-body camel→snake rewrite when the binder is already snake_case to realign residual camel refs.
   - Do NOT enable broad underscore passes; keep shape-based and safe.
3) Registry hygiene (noise/ordering safety):
   - Remove duplicate pass registrations; fix runAfter edges referencing disabled names; add dev validator to error on duplicates/missing deps.

VERIFICATION
- Snapshot tests:
  - Add regression suite under `test/snapshot/regression/c07bfa5c_case_binder_naming` with minimal Option/Result and child spec cases.
  - Ensure `value = g` never appears; snake_case only.
- Todo-app compile/runtime:
  - `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 420 --verbose`
  - GET / returns 2xx; no CompileError; time-to-ready acceptable.
- Grep checks:
  - `rg -n "\bvalue = g\b|tempResult|defaultValue|tempString" examples/todo-app/lib` → no matches.

