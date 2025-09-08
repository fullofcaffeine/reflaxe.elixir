defmodule Main do
  def main() do
    IO.puts("Testing bootstrap with fixed code...")
    test_basic_operations()
  end
  
  defp test_basic_operations() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
    IO.puts("Doubled: #{inspect(doubled)}")
    
    evens = Enum.filter(numbers, fn x -> is_even(x) end)
    IO.puts("Evens: #{inspect(evens)}")
    
    more = numbers ++ [6, 7, 8]
    IO.puts("Concatenated: #{inspect(more)}")
  end
  
  defp is_even(num) do
    rem(num, 2) == 0
  end
end
Main.main()