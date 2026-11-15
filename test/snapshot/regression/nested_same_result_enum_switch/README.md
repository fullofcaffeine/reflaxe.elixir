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

## What the fixture covers

- `Ok` inside `Error`, with the outer binder named `m` and named `reason`;
- inner arms that read their own payload and the outer one;
- `Error` inside `Ok`;
- the nested switch as a statement, with code after it in the outer arm;
- the nested switch in a closure that the outer `Error` arm calls;
- three levels of the same enum.

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

The compiler before the fix printed 7 of the 32 lines wrong.

Run the snapshot with
`make -C test test-regression__nested_same_result_enum_switch` and the native
check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/nested_same_result_enum_switch`.
