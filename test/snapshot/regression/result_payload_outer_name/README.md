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

It covers an argument and a local named `value`, and an argument named
`reason` read in an `Error(v)` clause.

Run the snapshot with `make -C test test-regression__result_payload_outer_name`
and the native check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/result_payload_outer_name`.
