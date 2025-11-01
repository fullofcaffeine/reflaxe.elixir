# MountParamsUltraFinalTransforms

WHAT
- Ensures Phoenix LiveView `mount/3` functions declare the first argument as `params` and rewrites body references accordingly.

WHY
- Generated wrappers may keep `_params` for hygiene but then read from it. This causes Elixir warnings and diverges from idiomatic LiveView heads.

HOW
- Matches `def mount(arg1, session, socket)` with arity 3. If `arg1` is a variable and not `params`, rename to `params` and update body references.

EXAMPLE
- Before: `def mount(_params, session, socket) do Map.get(_params, "session") end`
- After:  `def mount(params, session, socket) do Map.get(params, "session") end`

ORDERING
- Runs absolute‑final after chain‑assign replay; followed by ParamUnderscore* final sweeps.

