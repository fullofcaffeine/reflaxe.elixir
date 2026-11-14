# Keep a method call on a new object as one `cond` test

A Haxe author can test text with a regex directly in a `switch` guard:

```haxe
case NumberValue(canonical) if (~/^[1-9][0-9]{0,8}$/.match(canonical)): Std.parseInt(canonical);
```

The compiler stores the regex in a temporary variable before it calls `match`, so
the receiver is evaluated once. The guard becomes the test of an Elixir `cond`
clause. The printer wrote both statements before the arrow, which Elixir rejects:

```elixir
cond do
  receiver = EReg.new("^[1-9][0-9]{0,8}$", "")
apply(..., :match, [receiver, canonical]) -> ...
```

The `cond` printer now writes such a test as `(fn -> ... end).()`. This is the
form that the printer already uses for a block in a function argument or an operand.

`Main.hx` has a guard with a new regex, a guard with a regex from a static field,
and a `?:` condition in a case body. `runtime.exs` checks the results natively.

Run the snapshot with `make -C test test-regression__method_call_receiver_in_cond_condition`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture does not make the call itself more idiomatic. The compiler still
dispatches through `apply/3`, also when the receiver's class is known.
