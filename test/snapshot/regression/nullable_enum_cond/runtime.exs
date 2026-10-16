# Independent target observer: generating these assertions through the same
# enum lowering could hide the defect under test. Product behavior stays in Haxe.
values = [Main.first(), Main.second(), nil]

checks = [
  {:nonnullable, Enum.map(Enum.take(values, 2), &Main.nonnullable/1), [true, false]},
  {:nullable, Enum.map(values, &Main.nullable/1), [true, false, false]},
  {:payload, Enum.map(values, &Main.payload/1), ["one", "other", "other"]},
  {:guarded_field, Enum.map(values, &Main.guarded_field(%{choice: &1})), [true, false, false]}
]

for value <- [Main.second(), nil] do
  unless Main.reject_first(value) == "accepted", do: raise("Empty case lost its continuation")
end

rejection = try do
  Main.reject_first(Main.first())
  :missing_rejection
rescue
  error in Reflaxe.Elixir.HaxeThrow -> error.value
end

unless rejection == "first", do: raise("Constructor rejection was lost")

for {name, actual, expected} <- checks do
  unless actual == expected, do: raise("#{name}: expected #{inspect(expected)}, got #{inspect(actual)}")
end

for {value, expected} <- Enum.zip(values, ["one", "other", "other"]) do
  Process.put(:source_calls, 0)
  source = fn ->
    Process.put(:source_calls, Process.get(:source_calls) + 1)
    value
  end

  unless Main.evaluated(source) == expected, do: raise("Incorrect producer result")
  unless Process.get(:source_calls) == 1, do: raise("Switch evaluated its producer more than once")
  Process.delete(:source_calls)
end
