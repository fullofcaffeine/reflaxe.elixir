# 05 - HEEx Templates from Haxe

This example focuses on HXX template authoring and Phoenix component-style markup.

## Important context

- This example uses legacy string template style (`hxx('...')`) for migration compatibility demos.
- It therefore targets the default `@:hxx_mode("balanced")` workflow (typed inline markup available, legacy strings still allowed).
- Recommended default for new code is inline TSX-like markup (`return <div>...</div>`) in `@:hxx_mode("tsx")`.
- See `docs/02-user-guide/INLINE_MARKUP.md` and `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`.

## Run

```bash
cd examples/05-heex-templates
haxe build.hxml
```

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

## For strict typed TSX authoring

Use inline markup with `@:hxx_mode("tsx")`, for example:

```haxe
@:hxx_mode("tsx")
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
