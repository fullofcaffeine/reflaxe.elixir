# `#{` in a Haxe string literal is plain text

Haxe has no `#{...}` syntax. The characters are ordinary text:

```haxe
Sys.println("lit #{1 + 1} end"); // "lit #{1 + 1} end" on the Haxe interpreter
```

In an Elixir quoted string, `#{...}` runs the code between the braces. The
compiler copied the Haxe literal into Elixir unchanged:

```elixir
IO.puts("lit #{(fn -> 1 + 1 end).()} end") # printed "lit 2 end"
```

So the program printed different text without an error. A literal such as
`"#{x}"` with no variable `x` in scope did not compile. Neither did a regular
expression such as `~/^#{1,3} /`, where the braces are a repeat count. Text in
a string literal could run as Elixir code.

The compiler now keeps such a literal as literal data and prints the marker
escaped. Elixir reads `\#{` as the two characters `#{`:

```elixir
IO.puts("lit \#{1 + 1} end") # prints "lit #{1 + 1} end"
```

The same holds when the literal sits next to values in one concatenation, where
the compiler writes real values as `#{...}`:

```haxe
"lit #{1 + 1} " + name          // "lit \#{1 + 1} #{name}"
"a#" + "{" + name + "}"         // "a\#{#{name}}": the pieces meet, the text stays text
```

`#` and `{` apart need no escape and are not changed.

Three places keep `#{...}` as code on purpose:

- Target code injection, `untyped __elixir__('IO.puts("#{1 + 1}")')`. The author
  writes Elixir there. A Haxe literal passed as an injection argument is still
  text.
- HXX template source, `HXX.hxx('<p>#{@user.name}</p>')`, where `#{...}` is a
  documented template marker.
- HTML text returned from a function that takes `assigns`,
  `function help(assigns) return "<p>#{assigns.name}</p>";`. The compiler turns
  that return into a `~H` template, where `#{...}` becomes `<%= ... %>`. The
  fixture `test/snapshot/phoenix/assigns_html_string_markers` covers it.

`expected.stdout` is the output of the same program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

The three injection lines have no interpreter form, so `Main.hx` prints their
expected text directly on the interpreter. The atom line uses an `Atom`
parameter on Elixir and builds the same text by hand on the interpreter.

Run the snapshot with `make -C test test-regression__string_literal_hash_brace`.
Run the program on the BEAM and compare it with `expected.stdout` with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/string_literal_hash_brace`.

Limits. All give Elixir "unused variable" warnings only; the printed text is
correct.

- A parameter is used nowhere, and its name stands between the braces of a
  literal marker (for example `function f(x:Int) return "#{x}";`). The compiler
  keeps the name `x`, and Elixir warns that `x` is unused. The compiler cannot
  rename such a parameter, because the same text can be a template that reads
  it (see `test/snapshot/phoenix/assigns_html_string_markers`).
- A local that holds a computed value is used nowhere, and its name stands
  between the braces of a literal marker that the compiler joins with values
  (for example `var x = name.length; return "#{x} " + name;`). The compiler
  keeps the binding `x = ...`, and Elixir warns that `x` is unused.
- A `switch` arm on an enum joins such a marker with values, and the name
  between the braces is one that the compiler knows as another name of the
  matched value (for example `case Ok(v): "#{value} " + name`). The compiler
  adds the binding `value = v`, and Elixir warns that `value` is unused.
