# Native assertions do not share the compiler lowering under test.
steps = 12
unless Main.chain(0, -1) == {:ok, steps}, do: raise("the full chain must count every step")
for fail_at <- 0..(steps - 1) do
  expected = {:err, "stopped at #{fail_at}"}
  actual = Main.chain(0, fail_at)
  unless actual == expected, do: raise("expected #{inspect(expected)}, got #{inspect(actual)}")
end
IO.puts("PASS: early-return chain returns the first error or the final count")
