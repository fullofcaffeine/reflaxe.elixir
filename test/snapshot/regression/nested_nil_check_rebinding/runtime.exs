# Native assertions do not share the compiler lowering under test.
check = fn name, actual, expected ->
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end
check.("reassigned to text", Main.reassigned_in_branch(true, 2), "some label 2")
check.("reassigned to null", Main.reassigned_in_branch(true, 0), "none")
check.("reassignment skipped", Main.reassigned_in_branch(false, 2), "skipped")
check.("cleared", Main.cleared_in_branch(true), "cleared")
check.("clear skipped", Main.cleared_in_branch(false), "skipped")
check.("unchanged", Main.unchanged_in_branch(true), "present")
check.("unchanged skipped", Main.unchanged_in_branch(false), "skipped")
IO.puts("PASS: nil checks use the value assigned in the nested block")
