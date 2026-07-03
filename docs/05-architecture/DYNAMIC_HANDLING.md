# Dynamic Handling (No‑Dynamic Policy)

Reflaxe.Elixir aims to provide **typed, idiomatic** Haxe→Elixir development. As a result, the project
enforces a strong “no `Dynamic`” policy for new work.

## Why Avoid `Dynamic`

- It weakens the type guarantees that are the core value proposition of using Haxe on the BEAM.
- It hides compiler/transform bugs by widening types instead of fixing shapes.
- It creates fragile extern surfaces that are hard to maintain.

## What to Do Instead

- Prefer precise Haxe types (`typedef`, `enum`, `abstract`) over untyped maps.
- For “map-like” boundary data (JSON, params, PubSub payloads):
  - model the shape explicitly with `typedef` + optional fields, or
  - provide a small, typed wrapper API that validates/normalizes once at the boundary.
- When interacting with native Elixir APIs, prefer framework-level externs and helpers instead of
  pushing dynamic structures into application code.

## Enforcement

CI includes a guard that flags new `Dynamic` usage:

```bash
npm run guard:no-dynamic
```

## Exceptions

Some inherently dynamic boundaries require dynamic representation internally,
but public surfaces should remain typed and the dynamic usage should be clearly
contained at the boundary.

Legitimate examples:

- JSON or Phoenix params that arrive as native Elixir maps/terms and are decoded
  once into typed Haxe structures.
- `haxe.DynamicAccess<T>` when code intentionally models a string-keyed dynamic
  payload while keeping value type `T` explicit.
- `Reflect` helpers that must preserve Haxe behavior over native map/object
  shapes.
- Macro/compiler internals that mirror Haxe's own macro APIs.

This is a narrow compatibility boundary, not a reason to add a broad runtime
adapter. If the compiler can lower a Haxe construct to idiomatic Elixir, or a
stdlib API can call a BEAM-native primitive directly, prefer that over routing
through `Dynamic` or an emitted runtime helper.
