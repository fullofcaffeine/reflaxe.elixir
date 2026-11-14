join = fn list -> Enum.join(list, ",") end

# Each line is `label result`, as `Main.main` prints it.
actual = [
  "collect #{join.(Main.collect(5))}",
  "collectOdd #{join.(Main.collect_odd(9))}",
  "untilLimit-done #{Main.until_limit(4, 10)}",
  "untilLimit-over #{Main.until_limit(40, 2)}",
  "squares #{join.(Main.squares(5))}",
  "keepEven #{join.(Main.keep_even([4, 7, 10, 3, 8]))}",
  "split #{Main.split(6)}",
  "runningTotal #{Main.running_total(6)}",
  "extend #{join.(Main.extend(3))}",
  "twoLoops #{join.(Main.two_loops(3))}",
  "grid #{Main.grid(2, 3)}",
  "fill #{join.(Main.fill([9, 8], 3))}",
  "aliasAfter #{Main.alias_after(4)}",
  "doubled #{join.(Main.doubled([1, 2, 3]))}",
  "none [#{join.(Main.none())}]"
]

# `interpreter.txt` holds the output of the same program on the Haxe interpreter.
expected = __DIR__ |> Path.join("interpreter.txt") |> File.read!() |> String.split("\n", trim: true)

unless length(actual) == length(expected), do: raise("expected #{length(expected)} results, got #{length(actual)}")

failures = for {want, got} <- Enum.zip(expected, actual), want != got, do: "  interpreter: #{want}\n  BEAM:        #{got}"

unless failures == [], do: raise("Array results differ from the Haxe interpreter:\n" <> Enum.join(failures, "\n"))

IO.puts("PASS: array results equal the Haxe interpreter")

# 200,000 items for each loop shape. Expected values are computed natively.
count = 200_000
budget_ms = 3_000

run = fn name, call, expected ->
  {micros, actual} = :timer.tc(call)
  unless actual == expected, do: raise("#{name}: wrong result")
  IO.puts("#{name}: #{div(micros, 1000)} ms")
  div(micros, 1000)
end

values = Enum.to_list(0..(count - 1))
last = (count - 1) * 3
half = div(count, 2)

total_ms =
  run.("collect", fn -> Main.collect(count) end, values) +
    run.("collectOdd", fn -> Main.collect_odd(count) end, Enum.filter(1..count, &(rem(&1, 2) == 1))) +
    run.("untilLimit", fn -> Main.until_limit(count, count) end, "done:#{count}:#{last}") +
    run.("squares", fn -> Main.squares(count) end, Enum.map(values, &(&1 * &1))) +
    run.("keepEven", fn -> Main.keep_even(values) end, Enum.filter(values, &(rem(&1, 2) == 0))) +
    run.("split", fn -> Main.split(count) end, join.(Enum.take(values, half)) <> "|" <> join.(Enum.drop(values, half))) +
    run.("aliasAfter", fn -> Main.alias_after(count) end, "#{count}:#{count}:#{join.(values)}")

# Before the fix each `push` copied the whole list: 40,000 items took 14 s.
unless total_ms < budget_ms, do: raise("push loops took #{total_ms} ms, budget is #{budget_ms} ms")

IO.puts("PASS: seven loops collected #{count} items each in #{total_ms} ms (budget #{budget_ms} ms)")
