# 02 - Mix Project Integration

This example shows the minimal, production-style wiring for compiling Haxe modules into a normal Mix project.

## What this example demonstrates

- `mix.exs` compilers pipeline includes `:haxe` so `mix compile` runs Haxe first.
- `build.hxml` compiles Haxe modules from `src_haxe/` into Elixir files under `lib/`.
- Generated Elixir stays callable from regular Elixir code and tests.

## Run

```bash
cd examples/02-mix-project
mix deps.get
mix compile
mix test
```

## Key files

- Haxe sources:
  - `examples/02-mix-project/src_haxe/services/UserService.hx`
  - `examples/02-mix-project/src_haxe/utils/StringUtils.hx`
  - `examples/02-mix-project/src_haxe/utils/MathHelper.hx`
  - `examples/02-mix-project/src_haxe/utils/ValidationHelper.hx`
- Build config:
  - `examples/02-mix-project/build.hxml`
  - `examples/02-mix-project/mix.exs`
- Generated Elixir:
  - `examples/02-mix-project/lib/services/user_service.ex`
  - `examples/02-mix-project/lib/utils/string_utils.ex`
  - `examples/02-mix-project/lib/utils/math_helper.ex`

## Haxe -> generated Elixir (shape)

Haxe (`UserService.createUser`):

```haxe
public static function createUser(userData: NewUserInput): Result<User, String> {
    if (!isValidUserData(userData)) {
        return Error("Invalid user data provided");
    }
    var user: User = {
        id: generateUserId(),
        name: formatName(userData.name),
        email: normalizeEmail(userData.email),
        age: userData.age != null ? userData.age : 0,
        createdAt: getCurrentTimestamp(),
        status: "active"
    };
    return Ok(user);
}
```

Generated Elixir shape:

```elixir
def create_user(user_data) do
  if not is_valid_user_data(user_data) do
    {:error, "Invalid user data provided"}
  else
    user = %{
      id: generate_user_id(),
      name: format_name(user_data.name),
      email: normalize_email(user_data.email),
      age: if(not is_nil(user_data.age), do: user_data.age, else: 0),
      created_at: get_current_timestamp(),
      status: "active"
    }
    {:ok, user}
  end
end
```

## Why this example exists

- It is the simplest reference for "Mix + Haxe compiler wiring" without Phoenix-specific complexity.
- It validates module/codegen conventions (`snake_case`, tagged tuples, maps, helpers) in an ordinary Elixir app.

## Next examples

- `examples/03-phoenix-app/README.md` - Router + controller generation in Phoenix.
- `examples/06-user-management/README.md` - LiveView + Ecto typed app patterns.
- `examples/todo-app/README.md` - End-to-end app (LiveView, Ecto, Presence, Playwright).
