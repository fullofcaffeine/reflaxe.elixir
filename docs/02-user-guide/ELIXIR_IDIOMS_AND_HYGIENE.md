# Elixir Idioms & Hygiene (Codegen Conventions)

This guide documents **small but important** conventions Reflaxe.Elixir applies so the generated Elixir:

- is idiomatic and readable
- avoids common compiler warnings
- preserves Haxe semantics in an immutable, expression-oriented target

If you’re looking for construct-by-construct mappings (classes, enums, types, control flow), also see:
`docs/02-user-guide/HAXE_ELIXIR_MAPPINGS.md`.

## Naming: snake_case + module casing

### Variables and functions

Haxe typically uses `camelCase`. Elixir idiomatically uses `snake_case`.

Reflaxe.Elixir normalizes:

- local variables and function parameters → `snake_case`
- function names → `snake_case`

Example:

```haxe
public static function parseNumber(input: String): Int { ... }
```

Generates (shape):

```elixir
def parse_number(input) do
  ...
end
```

### Modules

Haxe packages and class names become Elixir module namespaces:

- `my.app.UserService` → `My.App.UserService`
- `MyThing` stays `MyThing` (module casing is preserved/normalized)

Use `@:native("My.App.UserService")` when you need an exact module name.

## Unused variables: automatic underscore-prefixing

Elixir warns on unused variables and parameters. The idiomatic way to silence this is a leading underscore (`_var`).

Reflaxe.Elixir performs **usage analysis** and automatically prefixes unused binders in the generated Elixir:

- unused local variables → `_var_name = ...`
- unused parameters → `def f(_arg) do ... end`
- unused pattern binders → `{:tag, _unused, used} -> ...`

This means:

- You **do not** need to write leading underscores in Haxe to get warning-free Elixir.
- You **can** still use `_foo` in Haxe to explicitly communicate “intentionally unused”; the compiler preserves it.

Example (Haxe):

```haxe
var upperResult = ResultTools.map(result, s -> s.toUpperCase());
// upperResult intentionally unused
```

Generated (shape):

```elixir
_upper_result = ResultTools.map(result, fn s -> String.upcase(s) end)
```

### Special case: Phoenix `assigns`

Phoenix function components and `~H` templates expect the parameter to be named `assigns`.
Even if it’s unused, the compiler keeps it as `assigns` (it will not be rewritten to `_assigns`).

## Enums: tagged tuples everywhere

Reflaxe.Elixir represents Haxe enums as **tagged tuples**, so pattern matching is uniform:

- zero-argument constructor → `{:red}` (1-tuple)
- constructor with N args → `{:rgb, r, g, b}` (N+1 tuple)

Example (Haxe):

```haxe
enum Color {
  Red;
  Rgb(r:Int, g:Int, b:Int);
}
```

Generated usage (shape):

```elixir
{:red}
{:rgb, r, g, b}
```

### `Option<T>` and `Result<T, E>` (recommended idioms)

Two enums are used pervasively in the stdlib and Phoenix surfaces:

- `Option<T>`:
  - `Some(v)` → `{:some, v}`
  - `None` → `{:none}`
- `Result<T, E>`:
  - `Ok(v)` → `{:ok, v}`
  - `Error(e)` → `{:error, e}`

These shapes are intentionally “Elixir-native”:
- they work well with `case`, guards, and pipelines
- they’re compatible with typical OTP-style return conventions

## Nullability: `null` becomes `nil`

`null` in Haxe becomes `nil` in Elixir. Prefer `Option<T>` when you want the type system to force handling.

## Data shapes: lists + maps

### Arrays are lists

`Array<T>` compiles to an Elixir list (`[...]`). Many familiar operations become `Enum.*` calls:

- `array.map(f)` → `Enum.map(array, f)`
- `array.filter(f)` → `Enum.filter(array, f)`
- `array.contains(x)` → `Enum.member?(array, x)`

This is implemented in `std/Array.cross.hx` and is designed to read like hand-written Elixir.

### Anonymous structures are maps (atom keys)

Haxe anonymous structures / typedef “records” compile to Elixir maps with atom keys:

```haxe
var user = { name: "Alice", age: 42 };
```

Shape:

```elixir
user = %{:name => "Alice", :age => 42}
```

Field reads and updates use idiomatic Elixir map syntax:

- `user.name` (read)
- `%{user | name: "Bob"}` (update)

## Control flow: expressions + preservation helpers

### `switch` → `case` (expression-preserving)

Haxe `switch` is an expression; Elixir `case` is also an expression, but compilation sometimes needs
temporary variables to preserve evaluation order and “return from inside” behavior.

You may see compiler-generated helpers such as:

- `_g` / `g` scratch variables (for expression plumbing)
- `Enum.reduce_while(..., :__reflaxe_no_return__, fn ... -> ... end)` patterns
- `{:__reflaxe_return__, value}` sentinels when a `return` must escape an internal loop

These are intentional and exist to keep Haxe semantics correct in Elixir’s immutable model.

### `break` / `continue` in loops

When Haxe uses `break` / `continue`, compilation may introduce `throw`/`catch` inside
`Enum.reduce_while` to emulate structured loop control flow without mutable state.

## Interop escape hatches

When you need exact Elixir code, use the supported injection surfaces (documented here):

- `docs/04-api-reference/ELIXIR_INJECTION_GUIDE.md`

These are powerful but should be used sparingly; prefer typed externs and stdlib helpers when possible.

