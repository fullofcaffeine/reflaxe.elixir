# Native assertions do not share the compiler lowering under test.
counted = fn value ->
  fn ->
    Process.put(:calls, Process.get(:calls, 0) + 1)
    value
  end
end
Process.put(:calls, 0)
unless Main.require_now(counted.({:now})) == "now", do: raise("Now must pass")
unless Process.get(:calls) == 1, do: raise("the tested expression must run once, ran #{Process.get(:calls)} times")

Process.put(:calls, 0)
message =
  try do
    Main.require_now(counted.({:never}))
    :not_thrown
  rescue
    error in Reflaxe.Elixir.HaxeThrow -> error.value
  end
unless message == "expected Now, got Never", do: raise("unexpected result: #{inspect(message)}")
unless Process.get(:calls) == 1, do: raise("the tested expression must run once before the throw, ran #{Process.get(:calls)} times")
Process.delete(:calls)
IO.puts("PASS: the switch value runs once and the catch-all name holds it")
