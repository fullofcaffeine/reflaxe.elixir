# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
for {name, call} <- [
      {"guard with new regex", &Main.guard_with_new_regex/1},
      {"guard with static regex", &Main.guard_with_static_regex/1}
    ] do
  check.(name <> ", whole number", call.({:number_value, "42"}), 42)
  check.(name <> ", leading zero", call.({:number_value, "042"}), -1)
  check.(name <> ", no number", call.({:null_value}), -1)
end
check.("condition, whole number", Main.condition_with_new_regex({:number_value, "7"}), 7)
check.("condition, not whole", Main.condition_with_new_regex({:number_value, "1.5"}), -1)
check.("condition, no number", Main.condition_with_new_regex({:null_value}), -2)
IO.puts("PASS: method calls on new objects work in guards and conditions")
