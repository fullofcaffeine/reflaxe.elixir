defmodule Main do
  def main() do
    test_elixir_injection()
    test_multiline_argument()
  end
  defp accept_int(value) do
    value
  end
  defp test_multiline_argument() do
    statements = accept_int((
    raw_left = 10
    raw_right = 20
    raw_left + raw_right
    ))
    if (statements != 30) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected multiline native argument to return 30"]
    end
    expression = accept_int((Enum.sum([
    1,
    2,
    3
    ])))
    if (expression != 6) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected multiline native call to return 6"]
    end
  end
  defp test_elixir_injection() do
    _result = 42
    nil
  end
end
