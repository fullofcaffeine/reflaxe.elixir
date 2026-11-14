# Native callbacks record the order of evaluation independently of the compiler.
step = fn label ->
  Process.put(:order, Process.get(:order, []) ++ [label])
  length(Process.get(:order))
end
source = fn label ->
  Process.put(:order, Process.get(:order, []) ++ [label])
  [1, 2, 3]
end
run = fn name, call, expected_value, expected_order ->
  Process.put(:order, [])
  actual = call.()
  unless actual == expected_value, do: raise("#{name}: expected #{inspect(expected_value)}, got #{inspect(actual)}")
  unless Process.get(:order) == expected_order, do: raise("#{name}: expected order #{inspect(expected_order)}, got #{inspect(Process.get(:order))}")
end
# Expected values are the results of the same program on the Haxe interpreter.
run.("pair", fn -> Main.pair(step, source) end, {:pair, 1, 1}, ["first", "second"])
run.("triple", fn -> Main.triple(step, source, 7) end, {:triple, 1, 7, 5}, ["first", "third", "fourth"])
run.("two helpers", fn -> Main.two_helpers(source) end, {:pair, 0, 2}, ["first", "second"])
run.("nested", fn -> Main.nested(step, source) end, [{:pair, 1, 0}, {:pair, 2, 1}], ["first", "second", "third"])
Process.delete(:order)
IO.puts("PASS: enum value arguments run from left to right")
