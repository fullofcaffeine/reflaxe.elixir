# Keep an outer `value` visible in an `Ok(v)` clause

Elixir code usually names the payload of `{:ok, _}` `value` and the payload of
`{:error, _}` `reason`. The compiler picks these names when the Haxe binder
has a generic name such as `v`.

That choice was wrong when the clause also reads another variable with the
same name:

```haxe
public static function outerValue(r:Res, value:Int):Int {
  return switch r {
    case Ok(v): v + value;
    ...
```

The old output bound the payload as `value`, which hid the argument:

```elixir
{:ok, payload_value} ->
  v = payload_value
  v + payload_value      # reads the payload twice
```

`outerValue(Ok(2), 10)` returned 4 instead of 12. The compiler now keeps the
binder's own name when the canonical name would hide a variable that the
clause reads:

```elixir
{:ok, v} -> v + value
```

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

`Main` covers an argument and a local named `value`, and an argument named
`reason` read in an `Error(v)` clause.

## A visible variable that the clause does not read itself

`VisibleNames.hx` holds the second part of the same rule
(haxe.elixir.codex-mj83). The clause below does not read `value`, so the check
above did not apply and the binder was named `value`:

```haxe
public static function argument(r:Verdict, value:String):String {
  switch (r) {
    case Ok(v): note(v);
    case Error(e): return "err " + e;
  }
  return "r=" + value;
}
```

Elixir has no `return`. Because the `Error` arm returns early, the compiler
moves the statements after the switch into the `Ok` arm. They then stood under
the binder and read the payload:

```elixir
{:ok, payload_value} ->
  v = payload_value
  note(v)
  "r=#{payload_value}"        # should read the argument
```

`argument(Ok("o"), "P")` returned `r=o` instead of `r=P`.

The compiler now keeps a canonical name away from every variable that is
visible where the switch stands, whether the clause reads it or not: function
arguments, earlier `var`s of the enclosing blocks, closure arguments, loop
variables, `catch` variables and the binders of enclosing patterns. Code that
a later pass moves into the clause can read any of them.

```elixir
{:ok, v} ->
  note(v)
  "r=#{value}"
```

Three late passes repair a clause by name: they take a name that the clause
body reads, and that nothing in the function binds, for the payload. They did
not count a name that a closure, a loop or a `catch` around the clause binds,
and renamed or aliased the binder to it (`ErrorReasonAliasInjection`,
`UnderscoreBinderAlignByBodyUse`, `SuccessBinderAlignByBodyUse`). They now
leave such a name alone.

`VisibleNames` covers:

- code after the switch that reads an argument or a local named `value`, and
  an argument named `reason` on the `Error` side;
- two switches in a row, a nested switch, a guarded arm, and the rest of a
  loop body;
- `value` or `reason` as a closure argument, a loop variable, a `catch`
  variable, and a local of an outer block;
- an arm that reads the closure argument or loop variable and not its payload;
- another arm that changes `value` without `=`: `push`, an element write, a
  map write and a field write.

The compiler before the fix printed 13 of these 54 lines wrong.

Not covered: a binder or a `var` inside an arm that the Haxe source itself
names like an outer variable (`case Ok(value):` with an argument `value`).
Code that moves into that arm still reads the inner variable.

Run the snapshot with `make -C test test-regression__result_payload_outer_name`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/result_payload_outer_name`.
