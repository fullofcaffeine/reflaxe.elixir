defmodule Main do
  def main() do
    test_simple_nested_var()
    test_reflect_fields_nested_var()
    test_deep_nesting()
  end
  defp test_simple_nested_var() do
    Log.trace("Test 1: Simple nested variable in loop", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "testSimpleNestedVar"})
    items = [1, 2, 3, 4, 5]
    results = []
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, i, :ok}, fn _, {acc_items, acc_i, acc_state} ->
  if (acc_i < length(acc_items)) do
    item = acc_items[acc_i]
    acc_i = acc_i + 1
    if (item > 2) do
      doubled = item * 2
      if (doubled > 6) do
        results = results ++ [doubled]
      end
    end
    {:cont, {acc_items, acc_i, acc_state}}
  else
    {:halt, {acc_items, acc_i, acc_state}}
  end
end)
    Log.trace(results, %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testSimpleNestedVar"})
  end
  defp test_reflect_fields_nested_var() do
    Log.trace("Test 2: Reflect.fields with nested variable", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})
    data = %{:user1 => %{:status => "active", :score => 10}, :user2 => %{:status => "inactive", :score => 5}, :user3 => %{:status => "active", :score => 15}}
    active_high_scorers = []
    g = 0
    g1 = Map.keys(data)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    key = acc_g1[acc_g]
    acc_g = acc_g + 1
    user_data = Map.get(data, String.to_atom(key))
    if (user_data.status == "active") do
      score = user_data.score
      if (score > 8) do
        active_high_scorers = active_high_scorers ++ [key]
      end
    end
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    Log.trace(active_high_scorers, %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})
  end
  defp test_deep_nesting() do
    Log.trace("Test 3: Deep nesting levels", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testDeepNesting"})
    matrix = [[1, 2], [3, 4], [5, 6]]
    found = []
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {matrix, i, j, :ok}, fn _, {acc_matrix, acc_i, acc_j, acc_state} ->
  if (acc_i < length(acc_matrix)) do
    row = acc_matrix[acc_i]
    acc_i = acc_i + 1
    nil
    {:cont, {acc_matrix, acc_i, acc_j, acc_state}}
  else
    {:halt, {acc_matrix, acc_i, acc_j, acc_state}}
  end
end)
    Log.trace(found, %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "testDeepNesting"})
  end
end