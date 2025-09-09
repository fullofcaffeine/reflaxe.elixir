defmodule Main do
  def main() do
    test_simple_map()
    test_map_with_enum_construction()
    test_nested_operations()
    test_array_filter()
  end
  defp test_simple_map() do
    numbers = [1, 2, 3, 4, 5]
    _doubled = Enum.map(numbers, fn n -> n * 2 end)
    strings = Enum.map(numbers, fn n -> "Number: " <> Kernel.to_string(n) end)
    processed = Enum.map(numbers, fn n -> process_number(n) end)
  end
  defp test_map_with_enum_construction() do
    tags = ["work", "personal", "urgent"]
    _values = Enum.map(tags, fn t -> string_value(t) end)
    tuples = Enum.map(tags, fn t -> %{:type => "string", :value => t} end)
    nested = Enum.map(tags, fn t -> array_value([string_value(t)]) end)
  end
  defp test_nested_operations() do
    matrix = [[1, 2], [3, 4], [5, 6]]
    _doubled = Enum.map(matrix, fn row -> Enum.map(row, fn n -> n * 2 end) end)
    filtered = Enum.map(matrix, fn row -> Enum.filter(row, fn n -> n > 2 end) end)
  end
  defp test_array_filter() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    in_range = Enum.filter(numbers, fn n -> n > 3 && n < 8 end)
    result = Enum.map(Enum.filter(numbers, fn n -> n > 5 end), fn n -> n * 2 end)
  end
  defp process_number(n) do
    "Processed: " <> Kernel.to_string(n)
  end
  defp generate_id(name) do
    length(name) * 100
  end
  defp string_value(s) do
    %{:type => "StringValue", :value => s}
  end
  defp array_value(arr) do
    %{:type => "ArrayValue", :items => arr}
  end
end

Code.require_file("main.ex", __DIR__)
Main.main()