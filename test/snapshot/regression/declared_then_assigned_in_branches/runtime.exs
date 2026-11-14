# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
check.("fraction only", Main.split("125", 0), "0.125")
check.("whole only", Main.split("125", 3), "125")
check.("both parts", Main.split("125", 1), "1.25")
check.("unset stays null", Main.label(0), "none")
check.("set in one branch", Main.label(2), "some")
IO.puts("PASS: variables assigned in every branch have the right values")
