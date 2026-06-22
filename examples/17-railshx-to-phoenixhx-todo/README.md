# 17 - RailsHx To PhoenixHx Todo

This example ports the user-facing shape of the RailsHx todo sample from
[`reflaxe.ruby/examples/todoapp_rails`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails)
into a Phoenix/Reflaxe.Elixir app.

The point is not to make Phoenix pretend to be Rails. The same product surface is
implemented with Phoenix-native concepts:

- LiveView callbacks and inline HXX instead of ActionController plus ERB/Turbo partials.
- LiveView events instead of Turbo Stream form mutation.
- Phoenix project/asset conventions instead of Rails importmap conventions.
- A small demo auth gate in this first slice, with the docs mapping the production path to Phoenix sessions and `on_mount`.

## What This Slice Includes

- Haxe-authored OTP application and router.
- Haxe-authored LiveView at `/` and `/todos`.
- RailsHx-inspired login shell, app top bar, composer, todo list, stats, and conversion notes.
- Haxe-authored domain/state module with ExUnit coverage.
- Haxe-authored LiveView hook bootstrap through Genes.
- Playwright smoke for guest entry, create, toggle, delete, and conversion copy.

This first slice intentionally keeps todo state in LiveView assigns so the Rails-to-Phoenix UI conversion is easy to inspect. Ecto persistence, production-grade session auth, chat, user management, and deterministic conversion inventory are tracked as `haxe.elixir.codex-1fg.1`, `haxe.elixir.codex-1fg.2`, and `haxe.elixir.codex-1fg.3`.

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
scripts/qa-sentinel.sh --app examples/17-railshx-to-phoenixhx-todo --port 4017 --playwright --e2e-spec e2e/railshx_port.spec.ts --e2e-workers 1 --async --deadline 900 --verbose
```

## Source Map

- `src_haxe/PhoenixHxTodo.hx` - Haxe-authored OTP application.
- `src_haxe/PhoenixHxTodoRouter.hx` - Haxe-authored Phoenix router.
- `src_haxe/phoenix_hx_todo_hx/live/AppLive.hx` - LiveView UI and events.
- `src_haxe/phoenix_hx_todo_hx/live/TodoState.hx` - pure todo state transitions.
- `src_haxe/test/live/TodoStateTest.hx` - Haxe-authored ExUnit coverage.
- `src_haxe/client/Boot.hx` - Genes-compiled LiveView hook registry.
- `e2e/railshx_port.spec.ts` - real-browser smoke.
- `docs/RAILSHX_TO_PHOENIXHX.md` - conversion crosswalk and future tooling notes.

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
