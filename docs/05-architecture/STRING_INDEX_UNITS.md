# String positions count codepoints

**Decision:** on the Elixir target, every Haxe `String` position and length
counts Unicode codepoints. The compiler and the target standard library own
this rule.

## The problem

A Haxe program reads a string by position:

```haxe
while (index < source.length) {
	if (source.charAt(index) == "\"") ...
	if (source.charCodeAt(index) == "[".code) ...
	index++;
}
```

This works only when `length`, `charAt`, `charCodeAt`, `substr`, `substring`,
`indexOf` and `lastIndexOf` all count the same unit. Text has three possible
units:

| Unit | What it is | `"\r\n"` | `e` + combining accent | Flag emoji |
| --- | --- | --- | --- | --- |
| Byte | One UTF-8 byte | 2 | 3 | 8 |
| Codepoint | One Unicode number | 2 | 2 | 2 |
| Grapheme | One character as a reader sees it | 1 | 1 | 1 |

Elixir's `String.length/1`, `String.at/2` and `String.slice/3` count
graphemes. The compiler used them for `length`, `charAt`, `substr` and
`substring`, but read `charCodeAt` from a codepoint list. After the first
grapheme that holds two codepoints, the two positions pointed at different
places. A JSON parser written in Haxe then rejected valid text such as
`[1,\r\n2]` and `["🇧🇷",true]`.

## Why codepoints

- Haxe does not fix one unit for all targets. The
  [Haxe manual](https://haxe.org/manual/std-String-encoding.html) lists the
  internal encoding of each target: UTF-16 for JavaScript, Java, C# and
  HashLink, and UTF-8 for Eval and Lua.
- The Haxe interpreter (Eval, 4.3.7) counts codepoints. This was measured:
  `test/snapshot/regression/string_codepoint_units/interpreter.txt` holds its
  results. The interpreter is the reference for this compiler's tests, and it
  also runs macros, so the same code gives the same positions at compile time
  and at run time.
- This repository already said so. `StringTools.unsafeCodeAt`, `UnicodeString`,
  `haxe.Utf8` and the string iterators are documented as codepoint-indexed, and
  the test fixtures compile with `-D no-utf16`.
- `charCodeAt` and `String.fromCharCode` are defined on single codes. With
  graphemes, `charCodeAt` could return only part of a character. With bytes,
  `charAt` could return part of a codepoint, which is not a valid string.

Graphemes remain available on purpose through the typed Elixir API
(`elixir.ElixirString`) when a program needs what a reader sees.

## What the rule covers

| Haxe | Generated Elixir |
| --- | --- |
| `s.length` | `StringTools.haxe_length(s)` |
| `s.charAt(i)` | `StringTools.haxe_char_at(s, i)` |
| `s.charCodeAt(i)` | `StringTools.haxe_char_code_at(s, i)` |
| `s.substr(pos, len)` | `StringTools.haxe_substr(s, pos, len)` |
| `s.substring(a, b)` | `StringTools.haxe_substring(s, a, b)` |
| `s.indexOf(v, from)` | `StringTools.haxe_index_of(s, v, from)` |
| `s.lastIndexOf(v, from)` | `StringTools.haxe_last_index_of(s, v, from)` |
| `s.split("")` | one piece per codepoint (`String.codepoints/1`) |

`StringTools.fastCodeAt`, `unsafeCodeAt`, `isSpace`, `UnicodeString.length`,
`haxe.Utf8.length`, `StringIterator` and `StringKeyValueIterator` use the same
helpers. A `.length` read on a value whose type is not known at compile time,
but which is a binary at run time, uses `length(String.codepoints(value))`.

`s.length` no longer prints as `String.length(s)`. That call reads well, but it
counts graphemes, so it gives a different number from every other operation.

A byte that is not valid UTF-8 counts as one position, and its code is the byte
value. This matches `String.codepoints/1`.

## How positions stay fast

BEAM stores a string as UTF-8 bytes. One codepoint takes one to four bytes, so
finding codepoint `i` means a walk from the start. A walk for each `length`,
`charAt` and `charCodeAt` made a character loop cost the square of the string
size: 72 KB took about three minutes.

`StringTools.haxe_unit_index/1` builds a position index for a string once:

- `:ascii` when every codepoint is one byte. Position and byte offset are then
  equal, and each operation is a direct byte read.
- Otherwise a tuple with the byte offset of each codepoint.

For a string of 256 bytes or more, the index is kept in the process dictionary
under `:reflaxe_haxe_string_index`, together with the string. The next
operation on the same string reuses it. The test "is this the same string" is
`===`, which BEAM answers at once for the same term and for a different size.
Shorter strings are indexed on each call. That is cheap, and it means a short
string read inside the loop (a separator, a keyword) does not replace the kept
index of the large one.

Measured on one machine (Apple silicon, OTP 27, Elixir 1.18.3).

The loop `while (i < s.length) total += s.charCodeAt(i++)`, from
`test/snapshot/regression/string_scan_scaling`:

| Input | Before | After |
| --- | --- | --- |
| 800 KB ASCII | stopped at the 20 s limit | 47 ms |
| 800 KB with two-byte characters | stopped at the 20 s limit | 104 ms |

A JSON parser written in Haxe (Caf's canonical JSON codec), on an array of
numbers:

| Input | Before | After |
| --- | --- | --- |
| 9 KB | 2.8 s | 19 ms |
| 18 KB | 12 s | 59 ms |
| 36 KB | 49 s | 227 ms |
| 72 KB | 187 s | 491 ms |

The parser times still grow faster than the input. That part is not String
reads: see the last item under Limits.

`test/snapshot/regression/string_scan_scaling` keeps this result with a time
budget.

## Limits

- One index is kept per process. A loop that reads two different strings of 256
  bytes or more in turn rebuilds the index on each switch. The results stay
  correct; the cost is one pass over the string per switch. Task:
  `haxe.elixir.codex-dvy`.
- The kept index holds its string, and for non-ASCII text one machine word per
  codepoint, until another large string replaces it or the process ends.
- The dynamic `.length` path counts on each call and does not use the index.
- Not yet on this rule: `EReg` match positions (`haxe.elixir.codex-4x2`),
  `StringBuf.addSub` (`haxe.elixir.codex-e0w`), and `haxe.Template` and the
  legacy untyped rewrite in `ElixirASTTransformer.stringMethodTransformPass`
  (`haxe.elixir.codex-u66`).
- `StringTools.ltrim` and `rtrim` use Elixir's Unicode whitespace list, which is
  wider than Haxe's (`haxe.elixir.codex-u66`).
- A fast String read does not make a whole parser linear. `StringBuf` appends
  (`haxe.elixir.codex-e0w`) and `array.push` in a loop (`haxe.elixir.codex-sd6`)
  still copy their whole content on each call.

## Tests

- `test/snapshot/regression/string_codepoint_units`: the inputs above, checked
  in Elixir against Haxe interpreter results.
- `test/snapshot/regression/string_scan_scaling`: three loop shapes on 800 KB
  with a time budget.

Both run in `npm run test:runtime-smoke`.
