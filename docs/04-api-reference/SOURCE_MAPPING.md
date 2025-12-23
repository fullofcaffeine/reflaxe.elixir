# Source Mapping (Experimental)

Reflaxe.Elixir’s long‑term goal is to provide `.ex.map` files that map generated Elixir code back
to original Haxe source positions, enabling:

- better error messages (Haxe file/line from Elixir stacktraces)
- LLM‑friendly navigation between generated and source code
- tooling like `mix haxe.source_map`

## Current Status (December 2025)

Source mapping is **not yet fully wired end‑to‑end** in the AST pipeline:

- The Haxe‑side writer (`src/reflaxe/elixir/SourceMapWriter.hx`) exists, but emission is not currently
  integrated into `ElixirASTPrinter`/`ElixirOutputIterator` for normal builds.
- The Elixir‑side lookup module (`lib/source_map_lookup.ex`) contains placeholder decoding logic and
  is not a production‑ready source map implementation.

As a result, you should treat source mapping as **experimental** and avoid relying on it for
production debugging.

## Where the Pieces Live

- Haxe source map writer (planned emission point):
  - `src/reflaxe/elixir/SourceMapWriter.hx`
- Elixir lookup task + runtime helpers:
  - `lib/source_map_lookup.ex`
  - `lib/mix/tasks/haxe.source_map.ex`
  - `lib/phoenix_error_handler.ex` (optional runtime enrichment)

## Recommended Next Steps (If You Want This Feature)

1. **Implement real emission**
   - Thread a `SourceMapWriter` through the print/output phase so the printer can map positions as it
     writes Elixir source.
2. **Implement VLQ decoding in Elixir**
   - Replace placeholder decoding in `lib/source_map_lookup.ex` with a real Source Map v3 decoder.
3. **Add integration coverage**
   - Use (or extend) the fixtures under `test/snapshot/core/source_map_validation/` to ensure:
     - `.ex.map` files are created when enabled
     - lookups map to the correct Haxe file/line/column

