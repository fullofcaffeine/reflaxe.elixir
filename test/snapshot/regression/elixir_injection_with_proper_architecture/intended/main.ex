defmodule Main do
  def main() do
    message = "Testing composition architecture"
    IO.puts("Injection still works")
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    if (length(doubled) > 0) do
      Enum.each(doubled, (fn -> fn _ ->
                nil
      end end).())
    end
  end
end
