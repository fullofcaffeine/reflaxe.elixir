# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
batch = %{name: "batch", values: [5, 6, -7, 8]}
check.("single, found", Main.single(batch, 6), {:negative, 1})
check.("single, absent", Main.single(batch, 9), {:negative, -1})
check.("nested, found", Main.nested(batch, 8), {:err, {:negative, 3}})
check.("two arguments", Main.two_arguments(batch, 8, 5), {:missing, 3, 0})
check.("loop, negative value", Main.first_negative(batch), {:err, {:negative, 2}})
check.("loop, no negative value", Main.first_negative(%{name: "clean", values: [1, 2]}), {:ok, 2})
IO.puts("PASS: enum values keep arguments that need a helper statement")
