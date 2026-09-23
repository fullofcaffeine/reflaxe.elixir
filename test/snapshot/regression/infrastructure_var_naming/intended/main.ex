defmodule Main do
  def main() do
    test_simple_loop()
    test_string_iteration()
    test_distinct_comprehension_state()
  end
  defp reorder(value, first, second) do
    if (first < 0 or second < 0 or first >= length(value.items) or second >= length(value.items)) do
      value.items
    else
      g = []
      g2 = length(value.items)
      g = Enum.reduce(0..(g2 - 1)//1, g, fn position, g_acc ->
        Enum.concat(g_acc, [Enum.at(value.items, (cond do
          position == first -> second
          position == second -> first
          true -> position
        end))])
      end)
      next = g
      next
    end
  end
  defp test_distinct_comprehension_state() do
    values = [10, 20, 30, 40]
    moved = reorder(%{items: values}, 1, 2)
    if (Enum.join(moved, ",") != "10,30,20,40" or Enum.join(values, ",") != "10,20,30,40") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Comprehension merged its output list with its range length."]
    end
    if (length(reorder(%{items: []}, 0, 0)) != 0 or Enum.join(reorder(%{items: [7]}, 0, 0), ",") != "7") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Comprehension changed its empty or singleton result."]
    end
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
      c = StringTools.haxe_char_at(input, i)
      result_acc <> c
    end)
    result
  end
end
