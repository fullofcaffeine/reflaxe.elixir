# 800 KB inputs. `mixed` holds a two-byte character in every number, so codepoint
# positions and byte positions differ everywhere.
ascii = String.duplicate("12345678,", 90_000)
mixed = String.duplicate("1234é678,", 80_000)
budget_ms = 5_000

run = fn name, call, expected ->
  {micros, actual} = :timer.tc(call)
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
  IO.puts("#{name}: #{div(micros, 1000)} ms")
  div(micros, 1000)
end

# Expected values are computed natively from the same inputs.
sum = fn text -> text |> String.to_charlist() |> Enum.sum() end
commas = fn text -> text |> :binary.matches(",") |> length() end

total_ms =
  run.("sumCodes ascii", fn -> Main.sum_codes(ascii) end, sum.(ascii)) +
    run.("sumCodes mixed", fn -> Main.sum_codes(mixed) end, sum.(mixed)) +
    run.("count ascii", fn -> Main.count(ascii, ",") end, commas.(ascii)) +
    run.("count mixed", fn -> Main.count(mixed, ",") end, commas.(mixed)) +
    run.("sumNumbers ascii", fn -> Main.sum_numbers(ascii, ",") end, 90_000 * 12_345_678)

# Before the fix a 72 KB loop took about three minutes, so 800 KB never finished.
unless total_ms < budget_ms, do: raise("character loops took #{total_ms} ms, budget is #{budget_ms} ms")

IO.puts("PASS: character loops over 800 KB ran in #{total_ms} ms (budget #{budget_ms} ms)")

# --- What the String runtime keeps in the process dictionary ---------------
key = :reflaxe_haxe_string_index
kept = fn -> Process.get(key) end
check = fn name, condition -> unless condition, do: raise("index: #{name}") end

# A large whole string is kept with its index, and release drops it.
Main.release()
check.("starts empty", kept.() == nil)
check.("reads a kept string", Main.code_at(mixed, 4) == 0xE9)
check.("keeps the last large string", match?({^mixed, _}, kept.()))
Main.release()
check.("release drops the entry", kept.() == nil)

# A short string is never kept.
check.("reads a short string", Main.code_at("1234\u00E9", 4) == 0xE9)
check.("does not keep a short string", kept.() == nil)

# A slice of a much larger binary is not kept: the entry would keep the whole
# larger binary alive for as long as the process lives.
parent = String.duplicate("1234\u00E9678,", 100_000)
slice = binary_part(parent, 10, 600)
check.("the slice refers to its parent", :binary.referenced_byte_size(slice) > 2 * byte_size(slice))
check.("reads a slice", Main.cut(slice, 4, 3) == String.slice(slice, 4, 3))
check.("reads a slice by code", Main.code_at(slice, 4) == 0xE9)
check.("does not keep a slice", kept.() == nil)

# A string built with `<>` has spare room behind it. It must still be kept,
# or a loop over it would walk the string on every read.
built = Enum.reduce(1..1_000, "[", fn _, text -> text <> "1234\u00E9678," end)
check.("a built string has spare room", :binary.referenced_byte_size(built) > byte_size(built))
check.("reads a built string", Main.code_at(built, 5) == 0xE9)
check.("keeps a built string", match?({^built, _}, kept.()))

# Size cap: the index never holds more than 1,048,576 offsets (8 MB), also for
# text with more codepoints than that. 2.4 MB here holds 2.16 million.
huge = String.duplicate("1234\u00E9678,", 240_000)
huge_codes = 240_000 * 9
{huge_micros, huge_sum} = :timer.tc(fn -> Main.sum_codes(huge) end)
check.("sum over capped index", huge_sum == sum.(huge))
{^huge, {stride, count, offsets}} = kept.()
check.("codepoint count", count == huge_codes)
check.("capped offsets", tuple_size(offsets) <= 1_048_576)
check.("stride above one", stride == 4)
for position <- [0, 1, 3, 4, 5, 1_000_003, huge_codes - 1] do
  want = huge |> binary_part(div(position, 9) * 10, 10) |> String.to_charlist() |> Enum.at(rem(position, 9))
  check.("capped read at #{position}", Main.code_at(huge, position) == want)
end
check.("capped read after the end", Main.code_at(huge, huge_codes) == nil)
check.("capped cut", Main.cut(huge, huge_codes - 5, 9) == "\u00E9678,")
check.("capped loop time", div(huge_micros, 1000) < budget_ms)
Main.release()

IO.puts("PASS: kept index: whole and built strings only, capped at 1,048,576 offsets, loop over 2.4 MB in #{div(huge_micros, 1000)} ms")
