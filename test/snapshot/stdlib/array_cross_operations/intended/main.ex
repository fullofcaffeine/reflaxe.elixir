defmodule Main do
  defp test_basic_operations() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    evens = Enum.filter(numbers, fn x -> is_even(x) end)
    more = numbers ++ [6, 7, 8]
    nil
  end
  defp test_chaining() do
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    result = Enum.filter(Enum.map(Enum.filter(data, fn x -> x > 5 end), fn x -> x * 10 end), fn x -> x < 100 end)
    transformed = Enum.map(Enum.map(Enum.map(data, fn x -> x + 1 end), fn x -> x * 2 end), fn x -> (x - 3) end)
    nil
  end
  defp test_list_operations() do
    items = ["apple", "banana", "cherry", "date"]
    cherry_index = 
                case Enum.find_index(items, fn item -> item == "cherry" end) do
                    nil -> -1
                    idx -> idx
                end
            
    list = [1, 2, 3]
    _ = list ++ [4]
    combined = list ++ [5, 6, 7]
    has_two = 
                case Enum.find_index(list, fn item -> item == 2 end) do
                    nil -> -1
                    idx -> idx
                end
             != -1
    nil
  end
  defp is_even(n) do
    rem(n, 2) == 0
  end
end
