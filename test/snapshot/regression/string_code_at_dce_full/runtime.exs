# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
check.("fastCodeAt", Main.code("abc", 1), 98)
check.("unsafeCodeAt", Main.unsafe_code("abc", 2), 99)
IO.puts("PASS: fastCodeAt and unsafeCodeAt run under -dce full")
