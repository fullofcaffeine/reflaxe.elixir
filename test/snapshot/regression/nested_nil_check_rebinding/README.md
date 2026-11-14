# Check for nil with the value assigned in a nested block

A Haxe author can set a variable to `null`, give it a real value inside an `if`
block, and then test it in that same block:

```haxe
var text:Null<String> = null;
if (enter) {
  text = label(count);
  if (text == null) return "none";
  return "some " + text;
}
```

The compiler removes a nil check when an earlier literal assignment proves the
answer (pass `SimplifyIsNilFalse`). It used to apply the fact from the outer block
(`text` is nil) to the whole `if` statement, and ignored the assignment inside it.
The function above then always returned `"none"`.

The pass now walks each function once, from the outside in. A nested block starts
with a copy of the outer facts and updates the copy at each of its own statements.

`Main.hx` has one function where the nested block replaces a null, one where it
clears a value, and one where nothing changes and the check can still be removed.
`runtime.exs` checks every result natively.

Run the snapshot with `make -C test test-regression__nested_nil_check_rebinding`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture covers assignments in `if` blocks. A variable that a `case` pattern
binds again is not covered here.
