# Keep an outer variable visible when a clause does not read its binder

```haxe
enum SRes { SOk(value:String); SErr(e:String); }

public static function outerArgument(r:SRes, value:String):String {
  return switch (r) {
    case SOk(a): "ok " + value;   // `a` is not read
    ...
```

The clause does not read `a`, so the compiler names the payload after the enum
field, `value`. That name hid the function argument:

```elixir
{:s_ok, payload_value} -> "ok #{payload_value}"   # prints the payload
```

`outerArgument(SOk("x"), "P")` returned `"ok x"` instead of `"ok P"`. The
earlier fix in `result_payload_outer_name` covered only the `value` and
`reason` names that the compiler gives `Ok` and `Error` payloads.

The compiler now checks every payload name against the outer variables that
the clause reads. An outer variable is one that the clause reads but does not
declare. On a clash the binder keeps its Haxe name:

```elixir
{:s_ok, _a} -> "ok #{value}"
```

A nested pattern such as `Wrap(SOk(_))` has no Haxe name for the outer
payload. There the compiler adds `payload_` to the field name:

```elixir
{:wrap, payload_value} ->
  value = (case payload_value do ...
```

`expected.stdout` is the output of this program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

It covers an argument and a local named like the enum field, a local that is
null (the folded nil test must use the outer value), `Ok` and `Error`
payloads, an inner switch that binds the same name, a nested pattern, and a
constructor with two payloads.

Not covered: `case Both(a, b)` with an unread `a` next to a `case _:` clause
does not compile to valid Elixir (`_a = _`). That older problem is separate
from the naming rule here.

Run the snapshot with `make -C test test-regression__unused_enum_binder_outer_read`
and the native check with
`bash scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/unused_enum_binder_outer_read`.
