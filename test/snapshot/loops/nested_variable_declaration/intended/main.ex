defmodule Main do
  def main() do
    test_simple_nested_var()
    test_reflect_fields_nested_var()
    test_deep_nesting()
  end

  defp test_simple_nested_var() do
    Log.trace("Test 1: Simple nested variable in loop", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "testSimpleNestedVar"})

    items = [1, 2, 3, 4, 5]

    # Use comprehension for filtering and transformation
    results = for item <- items, item > 2 do
      doubled = item * 2
      if doubled > 6, do: doubled, else: nil
    end |> Enum.filter(&(&1 != nil))

    Log.trace(results, %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testSimpleNestedVar"})
  end

  defp test_reflect_fields_nested_var() do
    Log.trace("Test 2: Reflect.fields with nested variable", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})

    data = %{
      :user1 => %{:status => "active", :score => 10},
      :user2 => %{:status => "inactive", :score => 5},
      :user3 => %{:status => "active", :score => 15}
    }

    # Use comprehension to filter active high scorers
    active_high_scorers = for {key, user_data} <- data,
                               user_data.status == "active",
                               user_data.score > 8 do
      Atom.to_string(key)
    end

    Log.trace(active_high_scorers, %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "testReflectFieldsNestedVar"})
  end

  defp test_deep_nesting() do
    Log.trace("Test 3: Deep nesting levels", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testDeepNesting"})

    matrix = [[1, 2], [3, 4], [5, 6]]

    # Use nested comprehension for matrix operations
    found = for row <- matrix do
      for element <- row, element > 3 do
        element
      end
    end |> List.flatten()

    Log.trace(found, %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "testDeepNesting"})
  end
end