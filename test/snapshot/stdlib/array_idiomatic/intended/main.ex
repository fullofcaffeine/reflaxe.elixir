defmodule Main do
  def main() do
    _ = test_map_function()
    _ = test_filter_function()
    _ = test_concat_function()
    _ = test_reverse_function()
    _ = test_sort_function()
    _ = test_contains_function()
    _ = test_index_of_function()
    _ = test_join_function()
    _ = test_slice_function()
    _ = test_iterator_function()
  end
  defp test_map_function() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    plus_ten = Enum.map(numbers, fn x -> x + 10 end)
    strings = ["hello", "world"]
    uppercased = Enum.map(strings, fn s -> String.upcase(s) end)
    nil
  end
  defp test_filter_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
    greater_than_five = Enum.filter(numbers, fn x -> x > 5 end)
    even_and_greater_than_five = Enum.filter(Enum.filter(numbers, fn x -> rem(x, 2) == 0 end), fn x -> x > 5 end)
    nil
  end
  defp test_concat_function() do
    first = [1, 2, 3]
    second = [4, 5, 6]
    third = [7, 8, 9]
    combined = first ++ second
    all = first ++ second ++ third
    nil
  end
  defp test_reverse_function() do
    numbers = [1, 2, 3, 4, 5]
    copy = numbers.copy()
    _ = Enum.reverse(copy)
    nil
  end
  defp test_sort_function() do
    numbers = [5, 2, 8, 1, 9, 3]
    copy = numbers.copy()
    _ = Enum.sort(copy, fn a, b -> (a - b) end)
    nil
  end
  defp test_contains_function() do
    numbers = [1, 2, 3, 4, 5]
    has_three = Enum.member?(numbers, 3)
    has_ten = Enum.member?(numbers, 10)
    nil
  end
  defp test_index_of_function() do
    numbers = [1, 2, 3, 4, 5, 3, 6]
    first_three = 
                case Enum.find_index(numbers, fn item -> item == 3 end) do
                    nil -> -1
                    idx -> idx
                end
            
    not_found = 
                case Enum.find_index(numbers, fn item -> item == 10 end) do
                    nil -> -1
                    idx -> idx
                end
            
    nil
  end
  defp test_join_function() do
    words = ["Hello", "Elixir", "World"]
    sentence = Enum.join((fn -> " " end).())
    csv = Enum.join((fn -> ", " end).())
    nil
  end
  defp test_slice_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    from_third = numbers.slice(2)
    middle = numbers.slice(2, 5)
    nil
  end
  defp test_iterator_function() do
    numbers = [1, 2, 3]
    _g = 0
    _ = Enum.each(numbers, fn _ -> nil end)
    iter_current = nil
    iter_array = nil
    iter_current = 0
    iter_array = numbers
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (iter_current < length(iter_array)) do
    nil
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
  end
end
