# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
check.("private tag", Main.is_private_tag("personal"), true)
check.("other tag", Main.is_private_tag("business"), false)
check.("direct call", Tags_Fields_.is_private("private"), true)
check.("under the limit", Main.under_limit(2), true)
check.("at the limit", Main.under_limit(3), false)
IO.puts("PASS: module-level values are read from the module that is defined")
