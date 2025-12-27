defmodule Main do
  defp test_simple_map() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    strings = Enum.map(numbers, fn n -> "Number: " <> Kernel.to_string(n) end)
    processed = Enum.map(numbers, fn n -> process_number(n) end)
  end
  defp test_map_with_enum_construction() do
    tags = ["work", "personal", "urgent"]
    values = Enum.map(tags, fn t -> string_value(t) end)
    tuples = Enum.map(tags, fn t -> %{:type => "string", :value => t} end)
    nested = Enum.map(tags, fn t -> array_value([string_value(t)]) end)
  end
  defp test_nested_operations() do
    matrix = [[1, 2], [3, 4], [5, 6]]
    doubled = Enum.map(matrix, fn row -> Enum.map(row, fn n -> n * 2 end) end)
    filtered = Enum.map(matrix, fn row -> Enum.filter(row, fn n -> n > 2 end) end)
  end
  defp test_array_filter() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    in_range = Enum.filter(numbers, fn n -> n > 3 and n < 8 end)
    result = Enum.map(Enum.filter(numbers, fn n -> n > 5 end), fn n -> n * 2 end)
  end
  defp test_complex_transformations() do
    users = [%{:name => "Alice", :age => 30}, %{:name => "Bob", :age => 25}, %{:name => "Charlie", :age => 35}]
    user_info = Enum.map(users, fn u -> %{:name => String.upcase(u.name), :age_group => (if (u.age < 30), do: "young", else: "adult"), :id => generate_id(u.name)} end)
    adults = Enum.map(Enum.filter(users, fn u -> u.age >= 30 end), fn u -> u.name end)
    processed = Enum.map(Enum.filter(Enum.map(Enum.filter(users, fn u -> u.age > 20 end), fn u -> %{:name => u.name, :valid => true} end), fn u -> u.valid end), fn u -> u.name end)
  end
  defp process_number(n) do
    "Processed: #{(fn -> Kernel.to_string(n) end).()}"
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
