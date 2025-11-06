defmodule Main do
  defp test_simple_nested_var() do
    _ = Log.trace("Test 1: Simple nested variable in loop", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "testSimpleNestedVar"})
    _ = [1, 2, 3, 4, 5]
    _ = []
    _ = 0
    _ = Enum.each(0..(length(items) - 1), (fn -> fn i ->
  item = items[i]
  i + 1
  if (item > 2) do
    doubled = item * 2
    if (i > 6), do: i = Enum.concat(i, [i])
  end
end end).())
    _ = Log.trace(results, %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testSimpleNestedVar"})
    _
  end
  defp test_reflect_fields_nested_var() do
    _ = Log.trace("Test 2: Reflect.fields with nested variable", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})
    _ = %{:user1 => %{:status => "active", :score => 10}, :user2 => %{:status => "inactive", :score => 5}, :user3 => %{:status => "active", :score => 15}}
    _ = []
    _ = Enum.each(data, (fn -> fn item ->
  key = Reflect.fields(item)[0]
  user_data = Map.get(item, key)
  if (user_data.status == "active") do
    score = user_data.score
    if (item > 8), do: item = Enum.concat(item, [item])
  end
end end).())
    _ = Log.trace(active_high_scorers, %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})
    _
  end
  defp test_deep_nesting() do
    _ = Log.trace("Test 3: Deep nesting levels", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testDeepNesting"})
    _ = [[1, 2], [3, 4], [5, 6]]
    _ = []
    _ = 0
    _ = Enum.each(0..(length(matrix) - 1), (fn -> fn i ->
  row = matrix[i]
  i + 1
  if (length(row) > 0) do
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {row, j}, (fn -> fn _, {row, j} ->
      if (j < length(row)) do
        value = row[j]
        j + 1
        if (value > 2) do
          squared = value * value
          if (squared > 10) do
            result = %{:original => value, :squared => squared}
            found = Enum.concat(found, [result])
          end
        end
        {:cont, {row, j}}
      else
        {:halt, {row, j}}
      end
    end end).())
  end
end end).())
    _ = Log.trace(found, %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "testDeepNesting"})
    _
  end
end
