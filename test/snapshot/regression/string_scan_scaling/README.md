# Keep character loops linear on large strings

A hand-written scanner reads a string one character at a time:

```haxe
while (index < source.length) {
	total += source.charCodeAt(index);
	index++;
}
```

On BEAM a string is a UTF-8 binary, so finding character `index` means walking
from the start. The compiler did that walk for every `length`, `charAt` and
`charCodeAt`, and `charCodeAt` also built a list of the whole string. The loop
cost grew with the square of the size: 9 KB took 2.8 s, 72 KB took 187 s, and
800 KB did not finish.

The String runtime now indexes a large string once and reuses the index while
the same string is read. See `docs/05-architecture/STRING_INDEX_UNITS.md`.

`runtime.exs` runs three loop shapes on 800 KB of ASCII text and of text with
two-byte characters. It checks the results against values computed in Elixir
and fails when the loops together take more than 5 seconds. The budget is wide
for slow machines; a normal run takes well under one second.

`runtime.exs` also checks what the String runtime keeps in the process
dictionary between calls: a whole large string and a string built with `<>` are
kept, a short string and a slice of a much larger binary are not, the index for
2.4 MB of two-byte text holds at most 1,048,576 offsets and still reads the
right characters, and `StringTools.releaseIndex()` leaves nothing behind.

Run the snapshot with `make -C test test-regression__string_scan_scaling` and
the timed check with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/string_scan_scaling`.
