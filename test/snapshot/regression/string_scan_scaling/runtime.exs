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
