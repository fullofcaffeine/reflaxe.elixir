# HandleEventParamsUltraFinalTransforms

WHAT
- Ensures Phoenix LiveView `handle_event/3` functions declare the second argument as `params` and rewrites any body references to that name.

WHY
- Underscored parameters (e.g., `_params`) that are subsequently used trigger Elixir warnings and reduce readability. Earlier passes may miss certain wrapper shapes or be undone by later hygiene. This absolute‑final pass guarantees idiomatic heads without app‑specific coupling.

HOW
- Matches `def handle_event(event, arg2, socket)` with arity 3. If `arg2` is a plain variable and not `params`, it renames it to `params` and traverses the body to update `EVar("old") → EVar("params")`.

EXAMPLES
- Haxe (typed bridge): `handleEvent(SaveTodo(params), socket)` → generated `handle_event("save_todo", params, socket)`.
- Before: `def handle_event("save_todo", _params, socket) do ... Map.get(_params, ...) end`
- After:  `def handle_event("save_todo", params, socket) do ... Map.get(params, ...) end`

NOTES
- Runs absolute‑final in the pass registry; complementary to ParamUnderscoreArgRefAlign_Final and ParamUnderscoreGlobalAlign_Final.

