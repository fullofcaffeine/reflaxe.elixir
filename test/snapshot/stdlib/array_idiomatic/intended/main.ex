defmodule Main do
  def main() do
    Main.test_map_function()
    Main.test_filter_function()
    Main.test_concat_function()
    Main.test_reverse_function()
    Main.test_sort_function()
    Main.test_contains_function()
    Main.test_index_of_function()
    Main.test_join_function()
    Main.test_slice_function()
    Main.test_iterator_function()
  end
  defp test_map_function() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    plus_ten = Enum.map(numbers, fn x -> x + 10 end)
    strings = ["hello", "world"]
    uppercased = Enum.map(strings, fn s -> s.toUpperCase() end)
    Log.trace("Doubled: " + Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testMapFunction"})
    Log.trace("Plus ten: " + Std.string(plus_ten), %{:fileName => "Main.hx", :lineNumber => 33, :className => "Main", :methodName => "testMapFunction"})
    Log.trace("Uppercased: " + Std.string(uppercased), %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "testMapFunction"})
  end
  defp test_filter_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    evens = Enum.filter(numbers, fn x -> x rem 2 == 0 end)
    greater_than_five = Enum.filter(numbers, fn x -> x > 5 end)
    even_and_greater_than_five = Enum.filter(Enum.filter(numbers, fn x -> x rem 2 == 0 end), fn x -> x > 5 end)
    Log.trace("Evens: " + Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "testFilterFunction"})
    Log.trace("Greater than 5: " + Std.string(greater_than_five), %{:fileName => "Main.hx", :lineNumber => 52, :className => "Main", :methodName => "testFilterFunction"})
    Log.trace("Even and > 5: " + Std.string(even_and_greater_than_five), %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "testFilterFunction"})
  end
  defp test_concat_function() do
    first = [1, 2, 3]
    second = [4, 5, 6]
    third = [7, 8, 9]
    combined = first ++ second
    all = first ++ second ++ third
    Log.trace("Combined: " + Std.string(combined), %{:fileName => "Main.hx", :lineNumber => 67, :className => "Main", :methodName => "testConcatFunction"})
    Log.trace("All: " + Std.string(all), %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "testConcatFunction"})
  end
  defp test_reverse_function() do
    numbers = [1, 2, 3, 4, 5]
    copy = numbers
    Enum.reverse(copy)
    Log.trace("Original: " + Std.string(numbers), %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "testReverseFunction"})
    Log.trace("Reversed: " + Std.string(copy), %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "testReverseFunction"})
  end
  defp test_sort_function() do
    numbers = [5, 2, 8, 1, 9, 3]
    copy = numbers
    Enum.sort(copy, fn a, b -> a - b end)
    Log.trace("Original: " + Std.string(numbers), %{:fileName => "Main.hx", :lineNumber => 89, :className => "Main", :methodName => "testSortFunction"})
    Log.trace("Sorted: " + Std.string(copy), %{:fileName => "Main.hx", :lineNumber => 90, :className => "Main", :methodName => "testSortFunction"})
  end
  defp test_contains_function() do
    numbers = [1, 2, 3, 4, 5]
    has_three = Enum.member?(numbers, 3)
    has_ten = Enum.member?(numbers, 10)
    Log.trace("Contains 3: " + Std.string(has_three), %{:fileName => "Main.hx", :lineNumber => 102, :className => "Main", :methodName => "testContainsFunction"})
    Log.trace("Contains 10: " + Std.string(has_ten), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testContainsFunction"})
  end
  defp test_index_of_function() do
    numbers = [1, 2, 3, 4, 5, 3, 6]
    first_three = Enum.find_index(numbers, fn item -> item == 3 end) || -1
    not_found = Enum.find_index(numbers, fn item -> item == 10 end) || -1
    Log.trace("Index of 3: " + first_three, %{:fileName => "Main.hx", :lineNumber => 115, :className => "Main", :methodName => "testIndexOfFunction"})
    Log.trace("Index of 10: " + not_found, %{:fileName => "Main.hx", :lineNumber => 116, :className => "Main", :methodName => "testIndexOfFunction"})
  end
  defp test_join_function() do
    words = ["Hello", "Elixir", "World"]
    sentence = Enum.join(words, " ")
    csv = Enum.join(words, ", ")
    Log.trace("Sentence: " + sentence, %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "testJoinFunction"})
    Log.trace("CSV: " + csv, %{:fileName => "Main.hx", :lineNumber => 129, :className => "Main", :methodName => "testJoinFunction"})
  end
  defp test_slice_function() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    from_third = if (end == nil) do
  Enum.slice(numbers, 2..-1)
else
  Enum.slice(numbers, 2..{2})
end
    middle = if (end == nil) do
  Enum.slice(numbers, 2..-1)
else
  Enum.slice(numbers, 2..5)
end
    Log.trace("From third: " + Std.string(from_third), %{:fileName => "Main.hx", :lineNumber => 141, :className => "Main", :methodName => "testSliceFunction"})
    Log.trace("Middle: " + Std.string(middle), %{:fileName => "Main.hx", :lineNumber => 142, :className => "Main", :methodName => "testSliceFunction"})
  end
  defp test_iterator_function() do
    numbers = [1, 2, 3]
    Log.trace("Iterating with for loop:", %{:fileName => "Main.hx", :lineNumber => 149, :className => "Main", :methodName => "testIteratorFunction"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  n = numbers[g]
  g + 1
  Log.trace("  Number: " + n, %{:fileName => "Main.hx", :lineNumber => 151, :className => "Main", :methodName => "testIteratorFunction"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    iter = numbers.iterator()
    Log.trace("Iterating with iterator:", %{:fileName => "Main.hx", :lineNumber => 156, :className => "Main", :methodName => "testIteratorFunction"})
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (iter.current < iter.array.length) do
  Log.trace("  Next: " + iter.array[iter.current + 1], %{:fileName => "Main.hx", :lineNumber => 158, :className => "Main", :methodName => "testIteratorFunction"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
end