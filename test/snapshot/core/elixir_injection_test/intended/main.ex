defmodule Main do
  def main() do
    test_elixir_injection()
  end
  defp test_elixir_injection() do
    _result = 42
    nil
  end
end
