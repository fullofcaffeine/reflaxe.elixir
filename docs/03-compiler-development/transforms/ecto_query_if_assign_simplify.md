# EctoQueryIfAssignSimplifyTransforms (enhanced)

WHAT
- Simplifies patterns like `var = if cond, do: var = Ecto.Query.where(var, ...), else: var` by removing the inner rebinding and keeping a single `Ecto.Query.where(var, ...)` expression.

WHY
- Prevents unused‑variable warnings and stabilizes query binder naming for readability and downstream transforms.

HOW
- Detects `EMatch(PVar(var), EIf(...))` where the then‑branch rebinds the same `var` to `Ecto.Query.where(var, ...)` and rewrites the branch to the call expression, normalizing mismatched inner binder names when necessary.

EXAMPLE
- Before: `query = if filter, do: query = Ecto.Query.where(query, ...), else: query`
- After:  `query = if filter, do: Ecto.Query.where(query, ...), else: query`

