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
helpers. `StringBuf.addSub(s, pos, len)` cuts with `StringTools.haxe_substr`, and
`StringBuf.length` counts the codepoints of the built text. A `.length` read on
a value whose type is not known at compile time, but which is a binary at run
time, uses `length(String.codepoints(value))`.

`EReg` follows the rule too: `matchedPos`, `matchedLeft`, `matchedRight`, the
`matchSub` range, `replace` and `map` count codepoints, so
`text.substr(matcher.matchedPos().pos)` cuts at the match. The `EReg` runtime
module has its own small counting functions and does not need `StringTools`.

`s.length` no longer prints as `String.length(s)`. That call reads well, but it
counts graphemes, so it gives a different number from every other operation.

### Text that is not valid UTF-8

A byte that is not valid UTF-8 counts as one position, and its code is the byte
value. This matches `String.codepoints/1`.

One visible difference from other Haxe targets follows from this. A Haxe
string on the interpreter or on JavaScript can hold half of a UTF-16 surrogate
pair, for example `String.fromCharCode(0xD800)`. A BEAM string cannot: Erlang's
UTF-8 does not allow the codes `0xD800` to `0xDFFF`. `String.fromCharCode` with
such a code raises `ArgumentError` on this target. If the three bytes that
other systems write for it (`ED A0 80`, the encoding known as WTF-8) arrive
from outside, they count as three positions, not one.

## How positions stay fast

BEAM stores a string as UTF-8 bytes. One codepoint takes one to four bytes, so
finding codepoint `i` means a walk from the start. A walk for each `length`,
`charAt` and `charCodeAt` made a character loop cost the square of the string
size: 72 KB took about three minutes.

`StringTools.haxe_unit_index/1` chooses how to find positions in a string:

- **Under 256 bytes:** no index. Each read walks from the start to the
  position it needs. `charAt(3)` reads three codepoints and stops, so short
  strings cost no more than before this change (measured below).
- **256 bytes or more, all ASCII:** the index is `:ascii`. Position and byte
  offset are equal, so each operation is a direct byte read.
- **256 bytes or more, other text:** the index is `{stride, count,
  checkpoints}`. `checkpoints` is a tuple with the byte offset of every
  `stride`-th codepoint. `stride` is 1 for text up to 1 MB, so each read is
  direct. Above 1 MB it doubles until the tuple holds at most 1,048,576
  offsets, and a read walks at most `stride - 1` codepoints from the nearest
  stored offset.

### What is kept, and for how long

For a string of 256 bytes or more, the index is kept in the process dictionary
under `:reflaxe_haxe_string_index`, together with the string, as
`{string, index}`. The next operation on the same string reuses it. The lookup
is a pattern match with the string pinned (`{^s, index}`), which compares the
bytes of the two binaries. BEAM answers at once when both are the same term or
have different sizes; two different binaries with the same size and content
also match, after a byte comparison.

Only the last large string is kept. Strings under 256 bytes never replace it,
so a short separator or keyword read inside a loop does not disturb the index
of the large string.

Rules that limit what is kept:

- **A slice of a larger binary is not kept.** `binary_part/3` and pattern
  matching return a slice that refers to the whole original binary. Keeping a
  300-byte slice of a 66 MB request body would keep all 66 MB alive. The index
  is not kept when `:binary.referenced_byte_size(s)` is more than twice
  `byte_size(s)`. The limit is twice the size, not the exact size, because a
  string built with `<>` has spare room behind it for the next append: BEAM
  reports up to twice its size for it. Such strings are common inputs, and
  without the index a loop over them is quadratic again. The cost of this
  choice is bounded: the kept entry can hold at most as much unused memory as
  the string itself.
- **The index is at most 8 MB.** The checkpoint tuple never has more than
  1,048,576 elements of one machine word each. 8 MB was chosen because it
  keeps direct reads for text up to 1 MB, which covers ordinary documents and
  API payloads, and it keeps the index near or below the size of the text it
  serves. Larger text stays linear; each read walks a few codepoints more.
- **The string itself has no size limit.** A loop over a 50 MB string keeps
  that string until another large string replaces it or the process ends.

`StringTools.releaseIndex()` drops the entry. Call it in a long-lived process,
such as a GenServer, when it has finished with a large or sensitive string. It
changes no result; the next read builds the index again.

What a kept entry means for a long-lived process:

- The string stays in memory after the code that read it has returned.
- The string appears in `:sys.get_status/1` output, in `Process.info(pid,
  :dictionary)`, and in the crash report that OTP logs when the process ends
  abnormally. A password or token inside a string of 256 bytes or more can
  therefore reach a log. Call `StringTools.releaseIndex()` after such a read,
  or do the read in a short-lived process such as a `Task`.

### Measurements

Measured on one machine (Apple silicon, OTP 27, Elixir 1.18.3).

The loop `while (i < s.length) total += s.charCodeAt(i++)`, from
`test/snapshot/regression/string_scan_scaling`:

| Input | Before | After |
| --- | --- | --- |
| 800 KB ASCII | stopped at the 20 s limit | 66 ms |
| 800 KB with two-byte characters | stopped at the 20 s limit | 131 ms |
| 2.4 MB with two-byte characters (stride 4) | not measured | 522 ms |

A JSON parser written in Haxe (Caf's canonical JSON codec), on an array of
numbers:

| Input | Before | After |
| --- | --- | --- |
| 9 KB | 2.8 s | 19 ms |
| 18 KB | 12 s | 59 ms |
| 36 KB | 49 s | 227 ms |
| 72 KB | 187 s | 491 ms |

The parser times on this branch still grew faster than the input. That part
was not String reads: `StringBuf` appends and `array.push` copied their whole
content on each call. With both fixed, the 144 KB array takes about 0.34 s and
the time grows in proportion to the input.

Single operations on short strings, in nanoseconds per call (best of two runs;
"before" is the compiler before this change):

| Input | Operation | Before | After |
| --- | --- | --- | --- |
| 8 bytes ASCII | `length` | 150 | 118 |
| 8 bytes ASCII | `charAt(3)` | 168 | 102 |
| 8 bytes ASCII | `charCodeAt(3)` | 58 | 40 |
| 200 bytes ASCII | `length` | 591 | 118 |
| 200 bytes ASCII | `charAt(3)` | 184 | 84 |
| 200 bytes ASCII | `charCodeAt(3)` | 758 | 57 |
| 20 codepoints, accents | `length` | 766 | 147 |
| 20 codepoints, accents | `charAt(3)` | 190 | 116 |
| 120 codepoints, accents | `charAt(3)` | 207 | 92 |
| 120 codepoints, accents | `substr(1, 3)` | 5708 | 901 |
| 300 bytes ASCII | `charCodeAt(3)` | 1170 | 33 |

No measured operation is slower than before.

## Limits

- One index is kept per process. A loop that reads two different strings of 256
  bytes or more in turn rebuilds the index on each switch. The results stay
  correct; the cost is one pass over the string per switch. Task:
  `haxe.elixir.codex-dvy`.
- A large slice of a much larger binary gets no kept index, so a character loop
  over it walks the slice on each read. Copy it first with `:binary.copy/1`
  when it must be scanned.
- The dynamic `.length` path counts on each call and does not use the index.
- `EReg.replace` and `EReg.map` convert positions with a walk for each match,
  as before this change, so many matches in one large string cost more than
  linear time.
- Not yet on this rule: `haxe.Template` and the legacy untyped rewrite in
  `ElixirASTTransformer.stringMethodTransformPass` (`haxe.elixir.codex-u66`).
- `StringTools.ltrim` and `rtrim` use Elixir's Unicode whitespace list, which is
  wider than Haxe's (`haxe.elixir.codex-u66`).
- A fast String read does not make a whole parser linear. `array.push` in a
  loop is linear only for a new, empty array that the loop body does not read;
  other shapes still copy the whole array on each call
  (`haxe.elixir.codex-sd6`,
  `docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md`).

## Tests

- `test/snapshot/regression/string_codepoint_units`: the inputs above, a
  600-byte input that uses the kept index, and negative and out-of-range
  arguments, checked in Elixir against Haxe interpreter results.
- `test/snapshot/regression/ereg_codepoint_positions`: `EReg` positions used
  with `substr`, checked against Haxe interpreter results.
- `test/snapshot/regression/string_scan_scaling`: three loop shapes on 800 KB
  with a time budget, and what the process keeps: whole and appended strings
  only, no slices, at most 1,048,576 offsets, nothing after `releaseIndex`.
- `test/snapshot/regression/string_buf_linear_append`: `StringBuf.addSub` and
  `length` against Haxe interpreter results, and 800 KB of appends with a time
  budget.

All run in `npm run test:runtime-smoke`.
