defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    _doubled = Enum.map(numbers, fn x -> x * 2 end)
    _evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    _result = Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * 3 end)
    _joined = Enum.join(["a", "b", "c"], ", ")
    _len = length(numbers)
    nil
  end
end
