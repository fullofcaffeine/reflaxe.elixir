# A null operand of a string concatenation prints as `null`

Haxe turns a null operand of `+` into the text `null`:

```haxe
function path(name:Null<String>):String return "x/" + name;
path(null); // "x/null" on the Haxe interpreter
```

The compiler passed a String operand to Elixir unchanged. Elixir then printed
`"x/#{nil}"` as `"x/"`, so the program silently produced different text. The
string interpolation `'x/$name'` had the same fault, because Haxe rewrites it to
the same `+` expression. So did `text += name`: it stays a compound assignment
in Haxe, and the compiler lowers its `+` in the same way. `"x/" + null` did not
compile.

An operand whose Haxe type can hold null (`Null<String>`, an optional argument,
a `Map.get` result, a typedef alias of these) now goes through
`Reflaxe.Elixir.HaxeFloat.to_string/1`.
That helper returns a binary unchanged and maps `nil` to `"null"`. Operands of
other types already used it. A plain `String` operand keeps the direct form
`"x/#{name}"`, with no run-time check.

`Main.hx` passes each value as a function argument, so nothing is folded at
compile time. `expected.stdout` is the output of the same program on the Haxe
interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

Run the snapshot with `make -C test test-regression__null_string_concat`. Run
the program on the BEAM and compare it with `expected.stdout` with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/null_string_concat`.

Limit: a value declared as plain `String` that holds null at run time is not
converted. `"x/" <> value` raises `ArgumentError` for it, and `"x/#{value}"`
gives `"x/"`. Declare such a value as `Null<String>`.
