# Transformer Performance on `server.live.TodoLive`

## Context

- Regression: first Haxe compile hang for the todo-app appears at commit `76abdeb3`.
- TodoLive.hx is unchanged across the regression; the slowdown is in compiler pipeline.
- This document records transformer timing measurements for the LiveView server pass (`build-server-passF.hxml`) on HEAD using `-D hxx_instrument_sys` and the new `[PassTiming]` instrumentation in `ElixirASTTransformer`.

## Instrumentation Setup

- Added flag‑gated timing in `ElixirASTTransformer.transform`:
  - Per‑pass timing: `[PassTiming] name=<passName> ms=<elapsed>` for each pass in the registry when `-D hxx_instrument_sys` is defined.
  - Pipeline total: `[PassTiming] name=ElixirASTTransformer.total ms=<elapsed>` per module.
- This code is entirely behind `#if hxx_instrument_sys` and does not affect normal builds.

## Measurement Command (HEAD)

```bash
cd examples/todo-app
HAXE_USE_SERVER=0 ../../scripts/with-timeout.sh --secs 60 -- \
  haxe -D hxx_instrument_sys build-server-passF.hxml \
  > /tmp/passF-head.log 2>&1
```

Notes:
- We use `with-timeout.sh` to keep the run bounded (60s) per AGENTS constraints.
- The timeout fired with exit code 143; the log still contains complete timing for many modules and passes prior to the kill.

## High-Level Findings

- The log contains ~19,800 `[PassTiming]` lines.
- For the modules that completed their transform phase before timeout:
  - **All individual passes report `ms=0`** at integer millisecond resolution.
  - The only entries with non‑zero timings are `ElixirASTTransformer.total` per module, typically `4–11 ms`:

    ```text
    [PassTiming] name=ElixirASTTransformer.total ms=7
    [PassTiming] name=ElixirASTTransformer.total ms=4
    ...
    [PassTiming] name=ElixirASTTransformer.total ms=11
    ```

- This indicates:
  - Each individual transform pass runs in <1ms for the observed modules (rounded down to `0` by `Std.int`).
  - The **transformer pipeline as a whole** per module is on the order of single‑digit milliseconds.
  - The 60‑second timeout is dominated by earlier phases (typing, macros such as HXX/TemplateHelpers, and/or repeated compilation of many modules), not by a single pathological AST transform.

## Impact on Hypotheses

- Original suspicion: the batch of LHS/binder/assign hygiene passes added at `76abdeb3` caused the hang via expensive AST walks.
- Measurement suggests a more nuanced picture:
  - For modules reached before the timeout, hygiene and case/binder passes are individually cheap.
  - The slowdown may instead be due to:
    - Macros that run before the AST transformer (HXX, TemplateHelpers, HEEx macros).
    - The cumulative cost of running many passes across many modules.
    - The overall Haxe typing and macro evaluation phase, not the transform loop itself.

## Next Steps

1. Keep `[PassTiming]` instrumentation in `ElixirASTTransformer` as a diagnostic tool.
2. For further analysis, add similar timing wrappers around:
   - Macro entry points (HXX/HXXMacro/RouterBuildMacro/ModuleMacro).
   - TemplateHelpers operations in the macro phase.
3. Combine transformer timing with macro timing to build a complete wall‑clock picture of where time is spent during the `build-server-passF.hxml` run.
4. Use this combined data to decide whether to:
   - Gate cosmetic passes under `fast_boot` / `disable_hygiene_final` (still useful to reduce work), and/or
   - Prioritize macro‑level optimizations and caching for TodoLive templates.

At this stage, the key conclusion is that **no single AST transform pass stands out as a dominant millisecond‑scale hotspot on HEAD**; the hang behavior must be explained by earlier phases or aggregate work across many transformations.
