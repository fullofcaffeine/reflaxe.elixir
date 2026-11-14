# Evaluate a switch value once when its catch-all name is used in a throw

A Haxe author can name the value of a catch-all case and use it in an error:

```haxe
switch next() {
  case Now:
  case other:
    throw 'expected Now, got $other';
}
```

The generated Elixir called `next()` twice: once for the `case`, and again for
`other = next()`. A function with effects ran twice, and the error could show a
different value from the one that was tested.

Two things caused this. The pass `TempAliasCleanup` replaced every read of the
stored switch value by the call. If it had not, the pass
`CasePatternTempAssignmentRemoval` would have deleted `other = <stored value>`:
it asked the shared use check `VarUseAnalyzer.stmtUsesVar` whether `other` is read
later, and that check did not look inside `raise`.

Now the stored value stays when it is read more than once, and the use check
visits every kind of node.

`runtime.exs` passes a native callback and counts its calls, with and without the throw.

Run the snapshot with `make -C test test-regression__catch_all_name_in_throw`.
The standard `npm run test:runtime-smoke` command also executes its native observer.
