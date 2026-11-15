# A null `Null<Int>` length means "to the end" in `substr` and `slice`

In Haxe, the second argument of `String.substr` and `Array.slice` can be null.
A null value means "to the end":

```haxe
function rest(text:String, start:Int, length:Null<Int>):String return text.substr(start, length);
rest("abcdef", 1, null); // "bcdef" on the Haxe interpreter
```

The compiler has a fast form for an argument that cannot be null and a
null-aware form for one that can. It chose the fast form for a `Null<Int>`
argument too, so a null value raised `ArithmeticError` on the BEAM.

The cause was the check `TypeUtils.mayBeNil`. It asked Haxe for the final type
first, and that step removes `Null<...>`. The check now reads each layer of the
type before it disappears, so `Null<Int>` selects the null-aware form. A plain
`Int` keeps the fast form.

`expected.stdout` is the output of the same program on the Haxe interpreter:

```bash
haxe -cp . -main Main --interp > expected.stdout
```

Run the snapshot with `make -C test test-regression__nullable_substr_slice_length`.
Run the program on the BEAM and compare it with `expected.stdout` with
`scripts/test-runtime-smoke.sh --fixture test/snapshot/regression/nullable_substr_slice_length`.
