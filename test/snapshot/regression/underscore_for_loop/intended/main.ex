defmodule Main do
  def main() do
    count = 0
    _ = 1
    {count, _reflaxe_receiver_value_0} = {count + 1, count}
    _ = 2
    {count, _reflaxe_receiver_value_1} = {count + 1, count}
    _ = 3
    {_count, _reflaxe_receiver_value_2} = {count + 1, count}
    numbers = [1, 2, 3, 4, 5]
    _total = Lambda.count(numbers, nil)
    _ = 1
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _g = 0
    _ = Enum.reduce(matrix, rows, fn _, rows_acc ->
      {rows_acc, _reflaxe_receiver_value_3} = {rows_acc + 1, rows_acc}
      cols = 0
      _ = 1
      {cols, _reflaxe_receiver_value_4} = {cols + 1, cols}
      _ = 2
      {_cols, _reflaxe_receiver_value_5} = {cols + 1, cols}
      rows_acc
    end)
    nil
  end
end
