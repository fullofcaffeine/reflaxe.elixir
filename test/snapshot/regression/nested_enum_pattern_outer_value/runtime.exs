# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
check.("stale digest", Main.refuses_stale("abc", "other"), true)
check.("equal digests", Main.refuses_stale("abc", "abc"), false)
check.("malformed digest", Main.refuses_stale("", "abc"), false)
IO.puts("PASS: the inner pattern matches the value found by the outer pattern")
