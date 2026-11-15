# HTML text returned from an `assigns` function is a template

A function that takes `assigns` and returns HTML text is a template route. The
compiler turns the returned text into a `~H` template, and `#{...}` in that
text becomes the template output `<%= ... %>`:

```haxe
public static function help(assigns:PageAssigns):String
	return "<p>Write #{1 + 1} to #{assigns.name}</p>";
```

```elixir
def help(assigns) do
  ~H"""
  <p>Write <%= 1 + 1 %> to <%= @name %></p>
  """
end
```

This is the third place where `#{...}` in a Haxe string is code on purpose. The
other two are `HXX.hxx(...)` template source and target code injection. In all
other strings `#{` is plain text and prints escaped (`\#{`); see
`test/snapshot/regression/string_literal_hash_brace`.

The fix for haxe.elixir.codex-yshb keeps a Haxe literal that contains `#{` as
literal data. Its first version did so for these returns too. `render(assigns)`
still became `~H`, but a helper such as `help(assigns)` returned a plain string
when its text held `#{`, and `~H` when it did not. A component helper must
return `~H` in both cases.

The rule now: a string that the compiler turns into `~H` is template source.
Every other string in the same function is ordinary text.

| Function | Text | Result |
|---|---|---|
| `render`, `help`, `viaVar` | HTML with `#{...}` | `~H`, `#{...}` becomes `<%= ... %>` |
| `helpPlain` | HTML without `#{` | `~H` |
| `nested` | HTML with `#{inner}`, `inner` holds HTML | `~H` with `Phoenix.HTML.raw(inner)` |
| `mixed` | the returned HTML | `~H` |
| `mixed` | the argument `"#{raw}"` of `shout` | text, `"\#{raw}"` |
| `label` | no HTML tags | text, `"no tags \#{assigns.name}"` |
| `plain` | HTML, but no `assigns` parameter | text, `"<p>\#{name}</p>"` |

The template functions print the same Elixir as before the fix (base commit
99605ed71). `~H` needs Phoenix, so this fixture compares generated code only;
it does not run on the BEAM.

Run it with `make -C test test-phoenix__assigns_html_string_markers`.

Limit: only a string that becomes `~H` is template source. HTML text that the
compiler leaves as a plain string stays text, even in a function that takes
`assigns`. For example, a function whose whole body is
`return if (assigns.on) "<u>#{assigns.name}</u>" else "<s>none</s>";` is not
converted, so it prints `\#{assigns.name}`. Use `HXX.hxx(...)` for templates.
