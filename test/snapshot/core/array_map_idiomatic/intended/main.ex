defmodule Main do
  def main() do
    _ = test_simple_map()
    _ = test_map_with_enum_construction()
    _ = test_nested_operations()
    _ = test_array_filter()
    _ = test_complex_transformations()
  end
  defp test_simple_map() do
    numbers = [1, 2, 3, 4, 5]
    _doubled = Enum.map(numbers, fn n -> n * 2 end)
    _strings = Enum.map(numbers, fn n -> "Number: " <> Kernel.to_string(n) end)
    _processed = Enum.map(numbers, fn n -> process_number(n) end)
  end
  defp test_map_with_enum_construction() do
    tags = ["work", "personal", "urgent"]
    _values = Enum.map(tags, fn t -> string_value(t) end)
    _tuples = Enum.map(tags, fn t -> %{:type => "string", :value => t} end)
    _nested = Enum.map(tags, fn t -> array_value([string_value(t)]) end)
  end
  defp test_nested_operations() do
    matrix = [[1, 2], [3, 4], [5, 6]]
    _doubled = Enum.map(matrix, fn row -> Enum.map(row, fn n -> n * 2 end) end)
    _filtered = Enum.map(matrix, fn row -> Enum.filter(row, fn n -> n > 2 end) end)
  end
  defp test_array_filter() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    _in_range = Enum.filter(numbers, fn n -> n > 3 and n < 8 end)
    _result = Enum.map(Enum.filter(numbers, fn n -> n > 5 end), fn n -> n * 2 end)
  end
  defp test_complex_transformations() do
    users = [%{:name => "Alice", :age => 30}, %{:name => "Bob", :age => 25}, %{:name => "Charlie", :age => 35}]
    _user_info = Enum.map(users, fn u -> %{:name => String.upcase(u.name), :age_group => (if (u.age < 30), do: "young", else: "adult"), :id => generate_id(u.name)} end)
    _adults = Enum.map(Enum.filter(users, fn u -> u.age >= 30 end), fn u -> u.name end)
    _processed = Enum.map(Enum.filter(Enum.map(Enum.filter(users, fn u -> u.age > 20 end), fn u -> %{:name => u.name, :valid => true} end), fn u -> u.valid end), fn u -> u.name end)
  end
  defp process_number(n) do
    "Processed: #{Kernel.to_string(n)}"
  end
  defp generate_id(name) do
    String.length(name) * 100
  end
  defp string_value(s) do
    %{:type => "StringValue", :value => s}
  end
  defp array_value(arr) do
    %{:type => "ArrayValue", :items => arr}
  end
end
