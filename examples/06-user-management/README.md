# Example 06: User Management (Phoenix LiveView)

This example is a small Phoenix app written in Haxe that demonstrates:
- `@:schema` / `@:field` (Ecto schema generation)
- `@:changeset` (changeset generation/bridging at the framework boundary via `elixir.types.Term`)
- `@:liveview` (typed LiveView callbacks + HXX templates)
- Type-safe params/assigns patterns (no `Dynamic`, no `untyped` in app code)

## Key Files
- `examples/06-user-management/src_haxe/contexts/Users.hx` — `User` schema + context helpers
- `examples/06-user-management/src_haxe/live/UserLive.hx` — LiveView module + HXX templates
- `examples/06-user-management/src_haxe/services/UserGenServer.hx` — GenServer skeleton (service patterns)

## Run

```bash
cd examples/06-user-management
mix deps.get
mix compile
mix phx.server
```

Then open `http://localhost:4000`.

## Notes
- This example focuses on demonstrating compiler + stdlib patterns; some context functions are intentionally minimal.
- For a fully end-to-end app (Ecto + PubSub + Presence + Playwright E2E), see `examples/todo-app/README.md`.
