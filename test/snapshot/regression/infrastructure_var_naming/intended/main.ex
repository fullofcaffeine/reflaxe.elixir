defmodule Main do
  def main() do
    _ = test_simple_loop()
    _ = test_string_iteration()
  end
  defp test_simple_loop() do
    nil
  end
  defp test_string_iteration() do
    input = "ABC"
    result = ""
    _g = 0
    input_length = String.length(input)
    result = Enum.reduce(0..(input_length - 1)//1, result, fn i, result_acc ->
      c = if (i < 0) do
        ""
      else
        String.at(input, i) || ""
      end
      result_acc <> c
    end)
    result
  end
end
