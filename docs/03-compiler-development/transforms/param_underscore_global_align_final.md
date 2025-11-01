# ParamUnderscoreGlobalAlignFinalTransforms

WHAT
- Absolute‑final safety pass that replaces lingering `_params` references with `params` inside `mount/3` and `handle_event/3` bodies.

WHY
- Late rewrites or preceding passes can leave `_params` body references even after head promotions. This pass ensures there are no dangling underscored body refs that would cause warnings or undefined variables.

HOW
- For any `def mount/3` or `def handle_event/3`, traverses the body and rewrites `EVar("_params")` to `EVar("params")`. Does not rely on application names or variables beyond these shapes.

ORDERING
- Runs after HandleEventParamsUltraFinal and MountParamsUltraFinal and before a final replay of safe unused‑param underscoring.

