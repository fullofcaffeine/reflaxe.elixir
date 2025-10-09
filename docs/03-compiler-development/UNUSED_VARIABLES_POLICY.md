# Unused Variables Policy (Std Stubs vs User Code)

This document explains why some std cross files intentionally use underscore‑prefixed
parameter names (e.g., `_v`) while automatic unused detection remains enabled for
user code.

## Background

- The Elixir target supports raw code injection via `__elixir__()` which becomes
  ERaw nodes in our ElixirAST.
- ERaw nodes are opaque to the usage analyzer and Symbol IR overlay — reads/writes
  inside those strings are not “visible” to our analysis passes.
- Several std cross files (e.g., `std/haxe/Log.cross.hx`, `std/StringBuf.cross.hx`)
  use `__elixir__()` to emit legacy or exact shapes required by source‑map test
  suites for deterministic token alignment.

## Policy

1. Std Stubs (cross files with ERaw)
   - When parameters are not used in Haxe code (only referenced inside injected
     Elixir or not used at all), we intentionally prefix with `_` (e.g., `_v`).
   - This follows Elixir idiom, silences unused warnings, and stabilizes
     source‑map snapshots where exact shapes matter.

2. User Code (normal AST pipeline)
   - Automatic detection remains enabled: preprocessor + hygiene + (optionally)
     Symbol IR late naming apply underscores only when the analysis confirms a
     variable is unused.
   - No special handling is required — do not manually prefix user code unless
     desired for clarity.

## Rationale

- Avoids analyzer blind spots: ERaw injection prevents the analyzer from seeing
  “usage” inside injected strings; explicit `_` prevents inconsistent outcomes.
- Keeps source‑map suites stable: deterministic output preserves token alignment,
  improving trace mapping.
- Maintains idiomatic behavior for application code.

## Future Improvements

- Consider default‑on Symbol IR and blacklist std stubs from late renaming.
- Introduce annotations (e.g., `@:unused`) for std stubs to make intent explicit
  without encoding `_` names in the source.

