defmodule Main do
  def main() do
    test_basic_operations()
    test_chaining()
    test_list_operations()
  end
  defp test_basic_operations() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    Log.trace("Doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "testBasicOperations"})
    evens = Enum.filter(numbers, fn x -> is_even(x) end)
    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "testBasicOperations"})
    more = numbers ++ [6, 7, 8]
    Log.trace("Concatenated: #{inspect(more)}", %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "testBasicOperations"})
  end
  defp test_chaining() do
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    result = Enum.filter(Enum.map(Enum.filter(data, fn x -> x > 5 end), fn x -> x * 10 end), fn x -> x < 100 end)
    Log.trace("Chained result: #{inspect(result)}", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "testChaining"})
    transformed = Enum.map(Enum.map(Enum.map(data, fn x -> x + 1 end), fn x -> x * 2 end), fn x -> (x - 3) end)
    Log.trace("Triple mapped: #{inspect(transformed)}", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "testChaining"})
  end
  defp test_list_operations() do
    items = ["apple", "banana", "cherry", "date"]
    cherry_index = (

                case Enum.find_index(items, fn item -> item == "cherry" end) do
                    nil -> -1
                    idx -> idx
                end
            
)
    Log.trace("Index of cherry: #{cherry_index}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "testListOperations"})
    list = [1, 2, 3]
    list = list ++ [4]
    Log.trace("After push: #{inspect(list)}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testListOperations"})
    combined = list ++ [5, 6, 7]
    Log.trace("Combined: #{inspect(combined)}", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testListOperations"})
    has_two = (

                case Enum.find_index(list, fn item -> item == 2 end) do
                    nil -> -1
                    idx -> idx
                end
            
) != -1
    Log.trace("Has 2: #{has_two}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testListOperations"})
  end
  defp is_even(n) do
    rem(n, 2) == 0
  end
end