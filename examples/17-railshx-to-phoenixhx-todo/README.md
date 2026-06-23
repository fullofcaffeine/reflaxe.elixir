# 17 - RailsHx To PhoenixHx Todo

This example ports the user-facing shape of the RailsHx todo sample from
[`reflaxe.ruby/examples/todoapp_rails`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails)
into a Phoenix/Reflaxe.Elixir app.

The point is not to make Phoenix pretend to be Rails. The same product surface is
implemented with Phoenix-native concepts:

- LiveView callbacks and inline HXX instead of ActionController plus ERB/Turbo partials.
- Ecto schemas, context functions, and LiveView events instead of ActiveRecord plus Turbo Stream form mutation.
- Phoenix project/asset conventions instead of Rails importmap conventions.
- A small Phoenix session flow that demonstrates Plug session to LiveView session handoff.

## What This Slice Includes

- Haxe-authored OTP application and router.
- Haxe-authored LiveView at `/` and `/todos`.
- Haxe-authored Ecto Repo, `User`/`Todo` schemas, context functions, and migrations.
- Haxe-authored `ChatMessage` schema/context/migration plus a compact PubSub-backed ship room.
- Haxe-authored session controller plus `liveSessionMfa(...)` route wiring.
- RailsHx-inspired login shell, app top bar, composer, todo list, stats, chat panel, and conversion notes.
- Haxe-authored domain/state module with ExUnit coverage.
- Haxe-authored LiveView hook bootstrap through Genes.
- Playwright smoke for guest entry, create, toggle, delete, and conversion copy.

This slice keeps the RailsHx user journey while moving persistence, auth, and realtime room notes into Phoenix/Ecto/PubSub patterns. User-management remains intentionally deferred because it needs admin authorization and account lifecycle policy.

## Run

```bash
cd examples/17-railshx-to-phoenixhx-todo
mix setup
mix phx.server
```

Open `http://localhost:4000/todos`.

## Test

```bash
cd examples/17-railshx-to-phoenixhx-todo
mix test
```

Browser smoke via the repository sentinel:

```bash
scripts/qa-sentinel.sh --app examples/17-railshx-to-phoenixhx-todo --port 4017 --compile-migrations --migrations-hxml build-migrations.hxml --playwright --e2e-spec e2e/railshx_port.spec.ts --e2e-workers 1 --async --deadline 900 --verbose
```

## Source Map

- `src_haxe/PhoenixHxTodo.hx` - Haxe-authored OTP application.
- `src_haxe/PhoenixHxTodoRouter.hx` - Haxe-authored Phoenix router.
- `src_haxe/phoenix_hx_todo_hx/data/` - Ecto schemas.
- `src_haxe/phoenix_hx_todo_hx/contexts/` - Phoenix context APIs.
- `src_haxe/phoenix_hx_todo_hx/controllers/SessionController.hx` - session create/delete actions.
- `src_haxe/phoenix_hx_todo_hx/infrastructure/LiveSession.hx` - Plug session to LiveView session bridge.
- `src_haxe/phoenix_hx_todo_hx/migrations/` - Haxe-authored Ecto migrations.
- `src_haxe/phoenix_hx_todo_hx/live/AppLive.hx` - LiveView UI and events.
- `src_haxe/phoenix_hx_todo_hx/live/TodoState.hx` - pure todo state transitions.
- `src_haxe/test/` - Haxe-authored ExUnit coverage.
- `src_haxe/client/Boot.hx` - Genes-compiled LiveView hook registry.
- `e2e/railshx_port.spec.ts` - real-browser smoke.
- `docs/RAILSHX_TO_PHOENIXHX.md` - conversion crosswalk and future tooling notes.
- `docs/CONVERSION_INVENTORY.md` - deterministic RailsHx artifact inventory for future tooling.
- `tools/rails_hx_inventory.js` - report generator for the conversion inventory.

## Relationship To RailsHx

RailsHx source reference:

- [`README.md`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/README.md)
- [`models/`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/models)
- [`controllers/`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/controllers)
- [`views/`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/views)
- [`shared/TodoHooks.hx`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/shared/TodoHooks.hx)
- [`client/TodoClient.hx`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/client/TodoClient.hx)
- [`e2e/todoapp.spec.ts`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/e2e/todoapp.spec.ts)

RailsHx proves typed Haxe can author Rails-shaped code. This example shows the same lesson for Phoenix: keep the Haxe type vocabulary, but let the target framework stay itself.

## Conversion Inventory Prototype

The checked-in [conversion inventory](./docs/CONVERSION_INVENTORY.md) classifies the RailsHx todo source and separates deterministic mappings from areas that need product or framework decisions. It is an example-local report and fixture, not the architecture for a general migration compiler. Regenerate it from the repository root with:

```bash
RAILSHX_TODO_SOURCE=/path/to/reflaxe.ruby/examples/todoapp_rails \
  node examples/17-railshx-to-phoenixhx-todo/tools/rails_hx_inventory.js \
  > examples/17-railshx-to-phoenixhx-todo/docs/CONVERSION_INVENTORY.md
```

That prototype is intentionally report-only. General RailsHx-to-PhoenixHx migration compiler work is tracked separately as R&D; this todo example should remain a validation fixture/oracle, not the conversion system itself.
