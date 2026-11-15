# Do not rename an `Ok`/`Error` binder to an Erlang module name

```haxe
return switch r {
  case Ok(value) if (value >= 0): value;
  case Ok(_): (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast -1)) : Int);
  case Error(_): -2;
};
```

`elixir.ErlangTerm` is an extern for the Erlang module `:erlang`
(`@:native(":erlang")`), so the call compiles to `:erlang.term_to_binary(...)`.
The generated `case` was:

```elixir
case r do
  {:ok, :erlang} ->          # should be {:ok, value}
    cond do
      :erlang >= 0 -> :erlang
      true -> :erlang.binary_to_term(:erlang.term_to_binary(-1))
    end
  {:error, _} -> -2
end
```

`{:ok, :erlang}` matches only the atom `:erlang`, so `Ok(5)` raised
`CaseClauseError`. An application hit this in a channel module that encodes
terms; a module without such a call did not show it.

## Cause

In the compiler's syntax tree, a variable node (`EVar`) carries local variables
and also module references: `Enum`, and Erlang modules such as `:erlang`.
Several passes repair a clause whose body reads a name that nothing binds. To
find local variables, they tested that the first character of the name equals
its lower-case form. `:` has no upper-case form, so `:erlang` passed the test
and counted as an unbound local variable. Four passes then acted on it, each
one visible only after the previous one was fixed:

| Pass | Result |
| --- | --- |
| `CaseOkBinderAlign` | `{:ok, value}` became `{:ok, :erlang}` |
| `ClauseUndefinedVarBindToBinder` | added `:erlang = value` to the arm |
| `CaseOkBinderPrefixBindAllUndefined` | added `:lists = value` and `:erlang = value` |
| `CaseErrorVarUnify` | `:erlang.binary_to_term` became `Reason.binary_to_term` |

All passes with this test now ask `ElixirNaming.isVariableStart`: a variable
name starts with a lower-case letter or `_`.

## What the fixture covers

- the guarded arm reads the binder, and another `Ok` arm calls the module;
- the guarded arm passes the binder to the module;
- only the guard reads the binder;
- an early return moves the code after the `switch`, with its module call,
  into the `Ok` arm;
- the same shape on the `Error` side with the name `reason`;
- an arm that names two Erlang modules (`:lists` and `:erlang`).

`expected.stdout` is the output of this program on the Haxe interpreter. The
interpreter cannot call Erlang, so under `#if elixir ... #else` two small
stand-in classes replace the modules there: a codec round trip that returns
its value, and a list reverse. The compiler before the fix printed none of the
24 lines; the first call raised `CaseClauseError`.

Run the snapshot with
`make -C test test-regression__erlang_module_call_in_result_arm` and the native
check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/erlang_module_call_in_result_arm`.
