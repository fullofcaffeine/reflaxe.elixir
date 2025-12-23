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

Some inherently dynamic boundaries may temporarily require `Dynamic` internally, but public surfaces
should remain typed and the dynamic usage should be clearly contained at the boundary.

