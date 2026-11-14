# No unused-variable warning for a variable assigned in every branch

A Haxe author can declare a variable and give it a value in each branch:

```haxe
var whole:String;
var fraction:String;
if (position <= 0) { whole = "0"; fraction = digits; } else { ... }
```

The declaration becomes `whole = nil`. The branches return their new values, and
one statement binds them: `{fraction, whole} = cond do ... end`. The first `whole`
is then never read, and Elixir warns "variable is unused". A build that treats
warnings as errors fails.

The pass `DropTempNilAssign` now also removes `name = nil` when a later statement
of the same block binds the name again and nothing reads the nil value before that.

`Main.hx` also has a variable that one branch leaves unset. Its `nil` is read, so
it must stay. `runtime.exs` checks the values natively, and the runtime smoke
compile refuses warnings.

Run the snapshot with `make -C test test-regression__declared_then_assigned_in_branches`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

Limit: a block that holds raw injected Elixir between the two statements keeps the
`nil` assignment, because the compiler cannot see reads inside raw code.
