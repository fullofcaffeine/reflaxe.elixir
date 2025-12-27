defmodule Main do
  def main() do
    count = 0
    _ = 1
    old_count = count
    count = count + 1
    old_count
    _ = 2
    old_count = count
    count = count + 1
    old_count
    _ = 3
    old_count = count
    count = count + 1
    old_count
    numbers = [1, 2, 3, 4, 5]
    total = Lambda.count(numbers)
    _ = 1
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _g = 0
    rows = Enum.reduce(matrix, rows, fn _, rows_acc ->
      _old_rows_acc = rows_acc
      rows_acc = rows_acc + 1
      cols = 0
      _ = 1
      old_cols = cols
      rows_acc = rows_acc + 1
      old_cols
      _ = 2
      old_cols = cols
      rows_acc = rows_acc + 1
      old_cols
      nil
      rows_acc
    end)
    nil
  end
end
