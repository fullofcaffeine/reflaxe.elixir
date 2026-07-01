defmodule Main do
  def main() do
    count = 0
    count = count + 1
    count = count + 1
    _ = count + 1
    numbers = [1, 2, 3, 4, 5]
    _total = Lambda.count(numbers, nil)
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _g = 0
    _ = Enum.reduce(matrix, rows, fn _, rows_acc ->
      rows_acc = rows_acc + 1
      cols = 0
      cols = cols + 1
      _ = cols + 1
      rows_acc
    end)
    nil
  end
end
