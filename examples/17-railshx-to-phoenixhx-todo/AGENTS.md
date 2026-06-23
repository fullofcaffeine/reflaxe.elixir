# Agent Guide: RailsHx To PhoenixHx Todo

This example is a learning port of the RailsHx todo app into PhoenixHx. Keep the
user journey comparable, but keep the implementation Phoenix-native.

## Reference Boundary

- Canonical RailsHx reference: https://github.com/fullofcaffeine/reflaxe.ruby
- Todo source reference:
  - https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails
- Use RailsHx for UX comparison, migration vocabulary, test ideas, and didactic
  documentation.
- Do not link to machine-local `../haxe.ruby` paths in tracked docs.

## PhoenixHx Ownership

- Do not make this project pretend to be Rails.
- Prefer Haxe.Elixir, Phoenix, Ecto, LiveView, PubSub, OTP, and existing
  PhoenixHx patterns.
- Do not introduce Rails-shaped helpers, APIs, or naming unless the human has
  explicitly approved a translation or adapter layer for the task.
- If a RailsHx/PhoenixHx adapter layer is approved later, it must be explicit,
  optional, documented, and configurable at granular boundaries such as module,
  route, schema, feature, or runtime edge.
- Any API ergonomics improvement discovered here should generalize to PhoenixHx
  or Haxe.Elixir surfaces, not just this example.

## Authoring Rules

- Write new HXX as inline strict TSX markup.
- Do not use `hxx('...')`, `HXX.hxx('...')`, or raw HEEx blocks for new
  templates.
- Keep Haxe code typed. Avoid `Dynamic` except at unavoidable framework
  boundaries.
- Keep generated Elixir committed when source changes intentionally alter
  generated output.

## Bounded Validation

Run commands from the repository root unless noted.

```bash
scripts/with-timeout.sh --secs 240 --cwd examples/17-railshx-to-phoenixhx-todo -- haxe build.hxml
scripts/with-timeout.sh --secs 240 --cwd examples/17-railshx-to-phoenixhx-todo -- haxe build-tests.hxml
scripts/with-timeout.sh --secs 300 --cwd examples/17-railshx-to-phoenixhx-todo --env MIX_ENV=test --env HAXE_NO_SERVER=1 -- mix test
```

Browser smoke must use the bounded sentinel:

```bash
scripts/qa-sentinel.sh --app examples/17-railshx-to-phoenixhx-todo --port 4017 --compile-migrations --migrations-hxml build-migrations.hxml --playwright --e2e-spec e2e/railshx_port.spec.ts --e2e-workers 1 --async --deadline 900 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 180
```

For manual browsing, use keep-alive sentinel mode and stop the printed process
group when done:

```bash
scripts/qa-sentinel.sh --app examples/17-railshx-to-phoenixhx-todo --port 4017 --compile-migrations --migrations-hxml build-migrations.hxml --keep-alive --async --deadline 900 --verbose
```

Never run `mix phx.server` in the foreground during agent work.
