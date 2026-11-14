# Run the arguments of an enum value from left to right

Haxe evaluates arguments from left to right:

```haxe
return Pair(step("first"), source("second").indexOf(2));
```

`indexOf` on a call result first stores the result in a temporary variable. An
enum value is an Elixir tuple, which cannot hold that statement, so the compiler
moves it in front of the tuple. If nothing else changes, `source("second")` then
runs before `step("first")`: Elixir printed `second,first` where the Haxe
interpreter prints `first,second`.

The pass `ExtractTupleInlineAssignments` now first binds every earlier element
that is not a variable or a literal to a temporary, in order:

```elixir
tuple_elem_1 = step.("first")
receiver = source.("second")
{:pair, tuple_elem_1, (case Enum.find_index(receiver, ...) do ... end)}
```

`runtime.exs` passes native callbacks that record the order. The expected values
and orders are the results of the same program on the Haxe interpreter.

Run the snapshot with `make -C test test-regression__tuple_argument_order`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture covers enum values. Maps, lists and call arguments have their own
passes and are not covered here.
