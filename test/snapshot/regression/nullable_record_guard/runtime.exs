# Native values and assertions do not share the compiler lowering under test.
for original <- [%{identity: "kept", sequence: 7}, %{identity: "other", sequence: -3}] do
  Process.put(:observations, [])
  observer = fn value -> Process.put(:observations, [value | Process.get(:observations)]) end
  actual = Main.copy(%{pending: original}, observer)
  unless actual == original, do: raise("Record fields changed after the guard")
  unless Process.get(:observations) == [original], do: raise("Whole-record observer lost fields or ran twice")
end
Process.put(:observations, [])
rejection = try do
  Main.copy(%{pending: nil}, fn value -> Process.put(:observations, [value]) end)
  :not_rejected
rescue
  error in Reflaxe.Elixir.HaxeThrow -> error.value
end
unless rejection == "missing", do: raise("Null record was not rejected")
unless Process.get(:observations) == [], do: raise("Observer ran after null rejection")
Process.delete(:observations)
