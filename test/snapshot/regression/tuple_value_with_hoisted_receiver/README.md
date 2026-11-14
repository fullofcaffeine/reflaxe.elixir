# Keep helper statements when a tuple value needs them

A Haxe author can pass a call result to an enum value:

```haxe
return Negative(batch.values.indexOf(wanted));
```

`indexOf` on a field first stores `batch.values` in a temporary variable. An enum
value is an Elixir tuple, and a tuple cannot hold that statement, so the compiler
moves it in front of the tuple (pass `ExtractTupleInlineAssignments`).

The pass used to keep only the last expression of a two-statement block and drop
the first statement. The value then read a variable that no longer existed. With
nested enum values, such as `Err(Negative(...))`, each level dropped the statement
of the level below, and the result was `tuple_elem_1 = {:negative, tuple_elem_1}`.
Elixir refused both with "undefined variable".

The pass now moves every helper statement in front of the tuple, in order, and
leaves the value in the tuple:

```elixir
receiver = batch.values
{:negative, (case Enum.find_index(receiver, fn item -> item == wanted end) do ... end)}
```

`Main.hx` has one enum value, two nested enum values, two arguments that each need
a helper statement, and an early return from a loop. `runtime.exs` checks every
result natively.

Run the snapshot with `make -C test test-regression__tuple_value_with_hoisted_receiver`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

Limit: helper statements now run before the earlier arguments of the same enum
value. This fixture does not cover earlier arguments that have effects.
