defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    evens = []
    _g = 0
    evens = Enum.reduce(numbers, evens, fn n, evens_acc ->
      if (rem(n, 2) == 0) do
        evens_acc = Enum.concat(evens_acc, [n])
        evens_acc
      else
        evens_acc
      end
    end)
    doubled = []
    _g = 0
    doubled = Enum.reduce(numbers, doubled, fn n, doubled_acc -> Enum.concat(doubled_acc, [n * 2]) end)
    nil
  end
end
