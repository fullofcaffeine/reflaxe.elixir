# Preserve records after a null check

A Haxe author can reject a missing record, pass the complete record to a callback,
and then copy its fields. The compiler must preserve the original values.

An old warning-cleanup pass inserted an unconditional `pending = %{}` after the
null check. This discarded valid data, even when the null branch threw an error.
Removing that pass preserves the source behavior without inventing a fallback.

`Main.hx` exercises the ordinary typed Haxe path. `runtime.exs` supplies two
records with different values and independently checks the copied fields and
callback arguments. It also checks that a null record throws before the callback.
The native assertions are intentionally not generated through the compiler.

Run the snapshot with `make -C test test-regression__nullable_record_guard`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture covers immutable records. It does not establish shared mutable
object identity or all possible null-guard control-flow shapes.
