# Keep the payload read in a `catch` inside a result arm

The compiler lowers a Haxe `catch` to an Elixir `rescue`. The rescue always
binds the exception as `haxe_exception` and then picks the right Haxe catch
with a `case`:

```elixir
try do
  raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
rescue
  haxe_exception ->
    (case {thrown_value, haxe_exception} do
      {value, _} when is_binary(value) -> value <> v
      _ -> reraise(haxe_exception, __STACKTRACE__)
    end)
end
```

A later pass renames the `{:ok, binder}` payload when the clause body reads
exactly one name that nothing binds. It did not count the `rescue` binder as
bound, so `haxe_exception` was that one name. The payload took its name, and
the payload read inside the rescue read the exception instead
(haxe.elixir.codex-1h8a):

```haxe
case Ok(v):
  try { throw "T"; } catch (value:String) { value + v; }
```

```elixir
{:ok, haxe_exception} ->          # old output
  try do ... rescue
    haxe_exception -> ... {value, _} when is_binary(value) -> value <> haxe_exception
```

`value <> haxe_exception` raised `ArgumentError`. When an earlier statement
copied the payload (`v = haxe_exception`), the program was correct by chance.
The rename pass now counts `rescue` and `catch` binders as bound, as the
`Error` arm pass already did, and the payload keeps its name:

```elixir
{:ok, v} ->
  try do ... rescue
    haxe_exception -> ... {value_2, _} when is_binary(value_2) -> value_2 <> v
```

`Main` covers both arms and catch variables named `value`, `reason` and the
payload's own name, typed and untyped catches, an unused catch variable, a
nested `try`, a catch inside a closure, and a catch of `haxe.Exception`.
`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```
