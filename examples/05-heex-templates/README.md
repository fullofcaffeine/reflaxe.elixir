# 05 - HEEx Templates from Haxe

This example focuses on legacy/balanced HXX template authoring and Phoenix component-style markup.

It is intentionally not the preferred starting point for new templates. For new Phoenix UI code, use
inline HXX markup (`return <div>...</div>`) in strict TSX mode.

## Important context

- This example uses legacy string template style (`hxx('...')`) for migration compatibility demos.
- It is the intentional non-TSX example listed in `examples/README.md` policy guardrails.
- It therefore opts into `-D hxx_mode=balanced` (typed inline markup available, legacy strings still allowed).
- Recommended default for new code is inline markup (`return <div>...</div>`) in strict TSX mode.
- See `docs/02-user-guide/INLINE_MARKUP.md` and `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`.

## When this style is useful

Use this balanced string-template style only when you have a real compatibility reason:

- You are migrating an existing HEEx template and want the first Haxe version to stay close to the original markup.
- You are maintaining older Reflaxe.Elixir code that already uses `hxx('...')` and should be converted gradually.
- You need a compatibility fixture proving legacy string templates still lower to valid Phoenix HEEx.
- You are blocked by a current inline-markup lexer limitation and want to isolate that one template.

Do not use this style as the default for greenfield app templates. It gives less Haxe type-checking than inline markup because template markers are string-level constructs.

Raw HEEx (`<% ... %>` / `<%= ... %>`) is a separate escape hatch and should be avoided even in this example style unless explicitly isolated with `@:allow_heex` or `@:hxx_mode("metal")`.

## Run

```bash
cd examples/05-heex-templates
haxe build.hxml
```

## Test

```bash
cd examples/05-heex-templates
mix deps.get
mix test --no-start
```

The tests render the generated HEEx through `Phoenix.HTML.Safe` so nested HXX helpers are checked at runtime, not just at compile time.

## Key files

- `examples/05-heex-templates/src_haxe/templates/UserProfile.hx`
- `examples/05-heex-templates/src_haxe/templates/FormComponents.hx`

## Haxe -> generated HEEx (shape)

Haxe template excerpt:

```haxe
return hxx('
  <div class="user-profile">
    <h1>Welcome, ${assigns.user.name}!</h1>
  </div>
');
```

Generated HEEx shape:

```elixir
~H"""
<div class="user-profile">
  <h1>Welcome, <%= @user.name %>!</h1>
</div>
"""
```

## Why this example exists

- Demonstrates compatibility for existing string-template workflows.
- Shows component usage patterns (`<.button>`, `<.input>`) in Haxe-authored templates.
- Serves as a migration bridge while TSX-style inline markup becomes the default authoring path.
- Proves the compatibility path renders at runtime through ExUnit, so legacy support does not silently drift.

## For default strict typed TSX authoring

Use inline markup directly, for example:

```haxe
public static function render(assigns: { var count:Int; }): String {
  return <div><h1>${assigns.count}</h1></div>;
}
```

That path provides real Haxe expression typing for `${...}` and TSX control tags (`<if ${...}>`, `<for ${...}>`).

Generated Elixir shape:

```elixir
def render(assigns) do
  ~H"""
  <div><h1><%= @count %></h1></div>
  """
end
```
