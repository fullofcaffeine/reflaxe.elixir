defmodule Main do
  def main() do
    test_map_function()
    test_filter_function()
    test_concat_function()
    test_reverse_function()
    test_sort_function()
    test_contains_function()
    test_index_of_function()
    test_join_function()
    test_slice_function()
    test_iterator_function()
  end
  defp test_map_function() do
    numbers = [1, 2, 3, 4, 5]
    _doubled = Enum.map(numbers, fn x -> x * 2 end)
    _plus_ten = Enum.map(numbers, fn x -> x + 10 end)
    strings = ["hello", "world"]
    _uppercased = Enum.map(strings, fn s -> String.upcase(s) end)
    nil
  end
  defp test_filter_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
    _greater_than_five = Enum.filter(numbers, fn x -> x > 5 end)
    _even_and_greater_than_five = Enum.filter(Enum.filter(numbers, fn x -> rem(x, 2) == 0 end), fn x -> x > 5 end)
    nil
  end
  defp test_concat_function() do
    first = [1, 2, 3]
    second = [4, 5, 6]
    third = [7, 8, 9]
    _combined = first ++ second
    _all = first ++ second ++ third
    nil
  end
  defp test_reverse_function() do
    numbers = [1, 2, 3, 4, 5]
    copy = numbers
    apply(Map.get(copy, :__reflaxe_class__) || Map.get(copy, :__struct__), :reverse, [copy])
    nil
  end
  defp test_sort_function() do
    numbers = [5, 2, 8, 1, 9, 3]
    copy = numbers
    _ = Enum.sort(copy, fn a, b -> (fn a, b -> (a - b) end).(a, b) < 0 end)
    nil
  end
  defp test_contains_function() do
    numbers = [1, 2, 3, 4, 5]
    _has_three = Enum.member?(numbers, 3)
    _has_ten = Enum.member?(numbers, 10)
    nil
  end
  defp test_index_of_function() do
    numbers = [1, 2, 3, 4, 5, 3, 6]
    _first_three = (case Enum.find_index(numbers, fn item -> item == 3 end) do
      nil -> -1
      index -> index
    end)
    _not_found = (case Enum.find_index(numbers, fn item -> item == 10 end) do
      nil -> -1
      index -> index
    end)
    nil
  end
  defp test_join_function() do
    words = ["Hello", "Elixir", "World"]
    _sentence = Enum.join(words, " ")
    _csv = Enum.join(words, ", ")
    nil
  end
  defp test_slice_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _from_third = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :slice, [numbers, 2, nil])
    _middle = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :slice, [numbers, 2, 5])
    nil
  end
  defp test_iterator_function() do
    numbers = [1, 2, 3]
    _g = 0
    Enum.each(numbers, fn _ -> nil end)
    iter = ArrayIterator.new(numbers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
      try do
        if (apply(Map.get(iter, :__reflaxe_class__) || Map.get(iter, :__struct__), :has_next, [iter])), do: {:cont, acc}, else: {:halt, acc}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, acc}
        :throw, :continue ->
          {:cont, acc}
      end
    end)
  end
end
