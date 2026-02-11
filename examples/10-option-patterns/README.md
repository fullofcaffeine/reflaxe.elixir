# 10 - Option<T> Patterns

This example demonstrates type-safe `Option<T>` and `Result<T, E>` usage in Haxe, compiled to idiomatic Elixir tuple patterns.

## What this example demonstrates

- Repository APIs return `Option<T>` instead of nullable values.
- Service-layer flows compose `Option` and `Result` safely.
- ExUnit tests are authored in Haxe and compiled into Elixir tests.

## Run

```bash
cd examples/10-option-patterns
haxe build.hxml
mix test
```

## Key files

- Haxe sources:
  - `examples/10-option-patterns/src_haxe/repositories/UserRepository.hx`
  - `examples/10-option-patterns/src_haxe/services/ConfigManager.hx`
  - `examples/10-option-patterns/src_haxe/services/NotificationService.hx`
- Haxe-authored tests:
  - `examples/10-option-patterns/test_haxe/repositories/UserRepositoryTest.hx`
  - `examples/10-option-patterns/test_haxe/services/ConfigManagerTest.hx`
  - `examples/10-option-patterns/test_haxe/services/NotificationServiceTest.hx`
- Generated Elixir:
  - `examples/10-option-patterns/lib/repositories/user_repository.ex`
  - `examples/10-option-patterns/lib/services/config_manager.ex`
  - `examples/10-option-patterns/lib/services/notification_service.ex`

## Haxe -> generated Elixir (shape)

Haxe (`UserRepository.find`):

```haxe
public static function find(id: Int): Option<User> {
    if (id <= 0) return None;
    for (user in users) {
        if (user.id == id) return Some(user);
    }
    return None;
}
```

Generated Elixir shape:

```elixir
def find(id) do
  if id <= 0 do
    {:none}
  else
    case Enum.reduce_while(users(), :__reflaxe_no_return__, fn user, _ ->
      if user.id == id, do: {:halt, {:__reflaxe_return__, {:some, user}}}, else: {:cont, :__reflaxe_no_return__}
    end) do
      {:__reflaxe_return__, value} -> value
      _ -> {:none}
    end
  end
end
```

## Why this example exists

- It validates that high-level Haxe null-safety patterns map cleanly to BEAM tuple conventions.
- It gives a compact reference for teams adopting typed domain logic in Elixir without jumping directly into Phoenix complexity.

## Next examples

- `examples/11-domain-validation/README.md` - typed domain validation and business rules.
- `examples/06-user-management/README.md` - Option/Result patterns in LiveView + Ecto app flow.
- `examples/todo-app/README.md` - full app with Presence/PubSub/UI runtime checks.
