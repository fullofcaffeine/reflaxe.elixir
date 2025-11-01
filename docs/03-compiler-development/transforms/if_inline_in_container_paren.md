# IfInlineInContainerParenTransforms

WHAT
- Wrap inline `if ... do ... else ... end` expressions in parentheses when they appear inside container literals (tuples, lists, maps).

WHY
- Elixir requires parentheses around `if` expressions embedded in containers to avoid parser ambiguity (e.g., `{if cond, do: ..., else: ...}` vs `{ (if ...), ... }`).

HOW
- Traverses ETuple/EList/EMap and rewrites any child `EIf` node to `EParen(EIf(...))`.

SCOPE
- Intended for Phoenix contexts where container literals inside view code are common; pass is safe and shape‑based (no name heuristics).

