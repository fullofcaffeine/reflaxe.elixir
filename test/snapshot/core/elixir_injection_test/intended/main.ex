defmodule Main do
  defp main() do
    test_elixir_injection()
  end
  defp test_elixir_injection() do
    result = 42
    Log.trace("Result: " <> result, %{:fileName => "Main.hx", :lineNumber => 10, :className => "Main", :methodName => "testElixirInjection"})
  end
end