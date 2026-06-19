defmodule Main do
  def main() do
    count = 0
    _ = 1
    count = count + 1
    _ = 2
    count = count + 1
    _ = 3
    _ = count + 1
    numbers = [1, 2, 3, 4, 5]
    _total = Lambda.count(numbers, nil)
    _ = 1
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _g = 0
    _ = Enum.reduce(matrix, rows, fn _, rows_acc ->
      rows_acc = rows_acc + 1
      cols = 0
      _ = 1
      cols = cols + 1
      _ = 2
      _ = cols + 1
      rows_acc
    end)
    nil
  end
end
