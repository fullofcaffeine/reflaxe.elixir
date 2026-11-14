# Native assertions do not share the compiler lowering under test.
for {key, expected} <- [
      {"summary", {:ok, 1}},
      {"body", {:ok, 2}},
      {"other", {:err, "unknown depth"}},
      {"none", {:err, "unknown depth"}},
      {"", {:err, "empty"}}
    ] do
  Process.put(:lookups, [])
  actual = Main.depth_of(key, fn seen -> Process.put(:lookups, [seen | Process.get(:lookups)]) end)
  unless actual == expected, do: raise("depth_of(#{inspect(key)}): expected #{inspect(expected)}, got #{inspect(actual)}")
  unless Process.get(:lookups) == [key], do: raise("depth_of(#{inspect(key)}) must look the key up once, saw #{inspect(Process.get(:lookups))}")
end
Process.delete(:lookups)
IO.puts("PASS: the second switch tests its own value and the first call runs once")
