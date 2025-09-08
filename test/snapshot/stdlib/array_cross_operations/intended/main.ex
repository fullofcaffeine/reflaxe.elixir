defmodule Main do
  defp main() do
    Main.test_basic_operations()
    Main.test_chaining()
    Main.test_list_operations()
  end
  defp test_basic_operations() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    Log.trace("Doubled: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "testBasicOperations"})
    evens = Enum.filter(numbers, fn x -> Main.is_even(x) end)
    Log.trace("Evens: " <> Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 21, :className => "Main", :methodName => "testBasicOperations"})
    more = numbers ++ [6, 7, 8]
    Log.trace("Concatenated: " <> Std.string(more), %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "testBasicOperations"})
  end
  defp test_chaining() do
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    result = Enum.filter(Enum.map(Enum.filter(data, fn x -> x > 5 end), fn x -> x * 10 end), fn x -> x < 100 end)
    Log.trace("Chained result: " <> Std.string(result), %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "testChaining"})
    transformed = Enum.map(Enum.map(Enum.map(data, fn x -> x + 1 end), fn x -> x * 2 end), fn x -> (x - 3) end)
    Log.trace("Triple mapped: " <> Std.string(transformed), %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "testChaining"})
  end
  defp test_list_operations() do
    items = ["apple", "banana", "cherry", "date"]
    cherry_index = (

                case Enum.find_index(items, fn item -> item == "cherry" end) do
                    nil -> -1
                    idx -> idx
                end
            
)
    Log.trace("Index of cherry: " <> Kernel.to_string(cherry_index), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "testListOperations"})
    list = [1, 2, 3]
    list = list ++ [4]
    Log.trace("After push: " <> Std.string(list), %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "testListOperations"})
    combined = list ++ [5, 6, 7]
    Log.trace("Combined: " <> Std.string(combined), %{:fileName => "Main.hx", :lineNumber => 62, :className => "Main", :methodName => "testListOperations"})
    has_two = (

                case Enum.find_index(list, fn item -> item == 2 end) do
                    nil -> -1
                    idx -> idx
                end
            
) != -1
    Log.trace("Has 2: " <> Std.string(has_two), %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "testListOperations"})
  end
  defp is_even(n) do
    rem(n, 2) == 0
  end
end