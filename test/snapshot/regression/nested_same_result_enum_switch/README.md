# Read the inner payload in a switch nested under an `Error` arm

```haxe
enum Verdict { Ok(v:String); Error(v:String); }

public static function okInError(a:Verdict, b:Verdict):Int {
  return switch (a) {
    case Error(m): switch (b) {
        case Ok(v): v.length;
        case Error(x): m.length * 10;
      };
    case Ok(_): -1;
  };
}
```

Both switches use the same enum. The inner `Ok(v)` arm must read the payload
of `b`. The generated code read the payload of `a`, the outer error:

```elixir
{:error, reason} ->
  m = reason
  (case b do
    {:ok, _value} ->
      v = reason                 # should be v = value
      StringTools.haxe_length(v)
    {:error, _reason} -> StringTools.haxe_length(m) * 10
  end)
```

`okInError(Error("why"), Ok("o"))` returned 3, the length of `"why"`, instead
of 1. There was no compile error and no warning.

## Cause

The pass `CaseErrorVarUnify` repairs an `{:error, binder}` clause whose body
reads a name that nothing binds: it points that name at the binder. To find
such a name, it listed the names that the clause binds, but it did not look
at the patterns of a `case` inside the clause body. The inner `value`, bound
by `{:ok, value}`, therefore looked unbound in the outer clause, and
`v = value` became `v = reason`. An enum with other constructor names, such as
`SOk`/`SErr`, did not show the bug, because the pass looks only at `{:error, _}`
clauses.

The pass now counts every name that the clause body binds: the patterns of a
nested `case`, `receive`, `with`, `for`, `fn`, `rescue` and `catch`, and every
match.

## A typed `catch` in the clause

Counting more binders also left fewer unbound names. A typed Haxe `catch`
becomes a `rescue` whose catch-all clause rethrows:

```elixir
{:error, e} ->
  try do
    raise Reflaxe.Elixir.HaxeThrow, [value: code]
  rescue
    haxe_exception ->
      (case {..., haxe_exception} do
        {reason, _} when is_binary(reason) -> reason <> e
        _ -> reraise(haxe_exception, __STACKTRACE__)
      end)
  end
```

With `reason` now counted as bound, `__STACKTRACE__` was the only name left
that nothing in the clause binds. It looks like a variable, so the pass
replaced it with `e`. `reraise(haxe_exception, e)` gets a bad stacktrace,
returns `:badarg` and does not raise: the thrown `Int` never reached the
caller, and the function returned `:badarg`. A pass that renames an
`{:ok, _}` binder made the same mistake in an `Ok` arm.

`__STACKTRACE__`, `__MODULE__` and the other `__NAME__` special forms are not
variables: Elixir supplies their value. `ElixirNaming.isVariableName` now
rejects them, so no pass that looks for unbound locals through it can pick
one.

## What the fixture covers

- `Ok` inside `Error`, with the outer binder named `m` and named `reason`;
- inner arms that read their own payload and the outer one;
- `Error` inside `Ok`;
- the nested switch as a statement, with code after it in the outer arm;
- the nested switch in a closure that the outer `Error` arm calls;
- three levels of the same enum;
- a typed `catch` that does not match the thrown value, in an `Error` arm
  (as a value, as a statement, and with the payload read after the `try`)
  and in an `Ok` arm: the value must reach the caller.

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

The compiler before the first fix printed 7 of the first 32 lines wrong.

Run the snapshot with
`make -C test test-regression__nested_same_result_enum_switch` and the native
check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/nested_same_result_enum_switch`.
