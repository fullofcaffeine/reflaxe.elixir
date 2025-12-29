# Source Mapping (Experimental)

Reflaxe.Elixir’s long‑term goal is to provide `.ex.map` files that map generated Elixir code back
to original Haxe source positions, enabling:

- better error messages (Haxe file/line from Elixir stacktraces)
- LLM‑friendly navigation between generated and source code
- tooling like `mix haxe.source_map`

## Current Status (December 2025)

Source mapping is implemented, but remains **experimental**:

- The Haxe‑side writer (`src/reflaxe/elixir/SourceMapWriter.hx`) is wired into the output phase
  (`src/reflaxe/elixir/ElixirOutputIterator.hx`) and emits `.ex.map` files when enabled.
- The Elixir‑side lookup module (`lib/source_map_lookup.ex`) implements Source Map v3 VLQ decoding
  and can resolve Elixir `{file,line,column}` back to Haxe positions.

### What “experimental” still means

- Mappings are currently **coarse/line‑level**: each generated line maps to the nearest enclosing
  top‑level definition (module start and `def`/`defp`/macro boundaries), not every expression.
- More granular mapping would require threading the writer through a printer buffer (planned).

Non‑alpha / production‑ready status for Reflaxe.Elixir does **not** require source mapping; it is
opt‑in and intended as a debugging aid.

## Where the Pieces Live

- Haxe source map writer (planned emission point):
  - `src/reflaxe/elixir/SourceMapWriter.hx`
- Elixir lookup task + runtime helpers:
  - `lib/source_map_lookup.ex`
  - `lib/mix/tasks/haxe.source_map.ex`
  - `lib/phoenix_error_handler.ex` (optional runtime enrichment)

## How to Enable

Add a define to your Elixir build:

```hxml
-D source_map_enabled
```

Then compile normally. The compiler will emit sibling files:

- `lib/my_module.ex`
- `lib/my_module.ex.map`

## Recommended Next Steps (If You Want This Feature)

1. **Increase granularity**
   - Thread a `SourceMapWriter` through the printer so we can map at expression‑level, not just
     per generated line.
2. **Harden reverse lookup**
   - Improve `mix haxe.source_map --reverse` by searching maps by referenced source file rather than
     assuming filename equivalence.
3. **Expand integration coverage**
   - Extend the fixture coverage under `test/snapshot/core/source_map_*` to assert specific mappings
     (not just structure).
