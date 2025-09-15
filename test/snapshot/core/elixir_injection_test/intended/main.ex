defmodule Main do
  def main() do
    test_elixir_injection()
  end
  defp test_elixir_injection() do
    result = 42
    Log.trace("Result: #{result}", %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "testElixirInjection"})
  end
end