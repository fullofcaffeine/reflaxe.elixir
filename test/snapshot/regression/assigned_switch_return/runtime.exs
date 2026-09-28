# Expectations are source-language results, independent of generated control flow.
for {kind, expected} <- [{0, 90}, {1, 11}, {2, 80}] do
  for call <- [&Main.conditional_value/1, &Main.protected_conditional/1] do
    actual = call.(kind)
    unless actual == expected, do: raise("conditional return: expected #{expected}, got #{actual}")
  end
end
for {kind, expected, effects} <- [{0, 90, [0]}, {1, 30, [1, 11, 20, 30]}, {2, 80, [2, 12]}] do
  observe = fn value -> send(self(), {:observed, value}); value end
  unless Main.conditional_effects(kind, observe) == expected, do: raise("statement conditional return changed")
  for value <- effects do
    receive do
      {:observed, ^value} -> :ok
      other -> raise("unexpected effect: #{inspect(other)}")
    after
      0 -> raise("missing effect #{value}")
    end
  end
  receive do
    {:observed, value} -> raise("extra effect #{value}")
  after
    0 -> :ok
  end
end
for {kind, expected, effects} <- [{0, 90, []}, {1, 30, [20, 30]}, {2, 30, [30]}] do
  observe = fn value -> send(self(), {:observed, value}); value end
  unless Main.implicit_else(kind, observe) == expected, do: raise("implicit else lost continuation")
  for value <- effects do
    receive do
      {:observed, ^value} -> :ok
    after
      0 -> raise("missing implicit-else effect #{value}")
    end
  end
  receive do
    {:observed, value} -> raise("extra implicit-else effect #{value}")
  after
    0 -> :ok
  end
end
IO.puts("PASS: chained condition returns and ordered effects")

# Keep the earlier assigned-switch and closure regressions in the runtime lane.
Main.main()
