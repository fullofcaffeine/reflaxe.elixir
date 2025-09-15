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
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    plus_ten = Enum.map(numbers, fn x -> x + 10 end)

    strings = ["hello", "world"]
    uppercased = Enum.map(strings, fn s -> String.upcase(s) end)

    Log.trace("Doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testMapFunction"})
    Log.trace("Plus ten: #{inspect(plus_ten)}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testMapFunction"})
    Log.trace("Uppercased: #{inspect(uppercased)}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testMapFunction"})
  end

  defp test_filter_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
    greater_than_five = Enum.filter(numbers, fn x -> x > 5 end)

    even_and_greater_than_five = numbers
      |> Enum.filter(fn x -> rem(x, 2) == 0 end)
      |> Enum.filter(fn x -> x > 5 end)

    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "testFilterFunction"})
    Log.trace("Greater than 5: #{inspect(greater_than_five)}", %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "testFilterFunction"})
    Log.trace("Even and > 5: #{inspect(even_and_greater_than_five)}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testFilterFunction"})
  end

  defp test_concat_function() do
    first = [1, 2, 3]
    second = [4, 5, 6]
    third = [7, 8, 9]

    combined = first ++ second
    all = first ++ second ++ third

    Log.trace("Combined: #{inspect(combined)}", %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testConcatFunction"})
    Log.trace("All: #{inspect(all)}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "testConcatFunction"})
  end

  defp test_reverse_function() do
    numbers = [1, 2, 3, 4, 5]
    reversed = Enum.reverse(numbers)

    Log.trace("Original: #{inspect(numbers)}", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testReverseFunction"})
    Log.trace("Reversed: #{inspect(reversed)}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testReverseFunction"})
  end

  defp test_sort_function() do
    numbers = [5, 2, 8, 1, 9, 3]
    sorted = Enum.sort(numbers)

    Log.trace("Original: #{inspect(numbers)}", %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "testSortFunction"})
    Log.trace("Sorted: #{inspect(sorted)}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testSortFunction"})
  end

  defp test_contains_function() do
    numbers = [1, 2, 3, 4, 5]
    has_three = Enum.member?(numbers, 3)
    has_ten = Enum.member?(numbers, 10)

    Log.trace("Contains 3: #{has_three}", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testContainsFunction"})
    Log.trace("Contains 10: #{has_ten}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testContainsFunction"})
  end

  defp test_index_of_function() do
    numbers = [1, 2, 3, 4, 5, 3, 6]

    first_three = case Enum.find_index(numbers, fn item -> item == 3 end) do
      nil -> -1
      idx -> idx
    end

    not_found = case Enum.find_index(numbers, fn item -> item == 10 end) do
      nil -> -1
      idx -> idx
    end

    Log.trace("Index of 3: #{first_three}", %{:file_name => "Main.hx", :line_number => 115, :class_name => "Main", :method_name => "testIndexOfFunction"})
    Log.trace("Index of 10: #{not_found}", %{:file_name => "Main.hx", :line_number => 116, :class_name => "Main", :method_name => "testIndexOfFunction"})
  end

  defp test_join_function() do
    words = ["Hello", "Elixir", "World"]
    sentence = Enum.join(words, " ")
    csv = Enum.join(words, ", ")

    Log.trace("Sentence: #{sentence}", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testJoinFunction"})
    Log.trace("CSV: #{csv}", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testJoinFunction"})
  end

  defp test_slice_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    from_third = Enum.slice(numbers, 2..-1)
    middle = Enum.slice(numbers, 2..5)

    Log.trace("From third: #{inspect(from_third)}", %{:file_name => "Main.hx", :line_number => 141, :class_name => "Main", :method_name => "testSliceFunction"})
    Log.trace("Middle: #{inspect(middle)}", %{:file_name => "Main.hx", :line_number => 142, :class_name => "Main", :method_name => "testSliceFunction"})
  end

  defp test_iterator_function() do
    numbers = [1, 2, 3]

    Log.trace("Iterating with for loop:", %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "testIteratorFunction"})
    Enum.each(numbers, fn n ->
      Log.trace("  Number: #{n}", %{:file_name => "Main.hx", :line_number => 151, :class_name => "Main", :method_name => "testIteratorFunction"})
    end)

    Log.trace("Iterating with iterator:", %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "testIteratorFunction"})
    Enum.each(numbers, fn n ->
      Log.trace("  Next: #{n}", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testIteratorFunction"})
    end)
  end
end