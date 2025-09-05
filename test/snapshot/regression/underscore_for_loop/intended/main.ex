defmodule Main do
  def main() do
    count = 0
    _item = 1
    count = count + 1
    _item = 2
    count = count + 1
    _item = 3
    count = count + 1
    Log.trace("Count: " <> count, %{:fileName => "Main.hx", :lineNumber => 21, :className => "Main", :methodName => "main"})
    numbers = [1, 2, 3, 4, 5]
    total = Lambda.count(numbers)
    Log.trace("Total count: " <> total, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    empty_list = []
    non_empty_list = [1]
    Log.trace("Empty list is empty: " <> Std.string(Lambda.empty(empty_list)), %{:fileName => "Main.hx", :lineNumber => 31, :className => "Main", :methodName => "main"})
    Log.trace("Non-empty list is empty: " <> Std.string(Lambda.empty(non_empty_list)), %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "main"})
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {rows, g, cols, matrix, :ok}, fn _, {acc_rows, acc_g, acc_cols, acc_matrix, acc_state} ->
  if (acc_g < acc_matrix.length) do
    _item = matrix[g]
    acc_g = acc_g + 1
    acc_rows = acc_rows + 1
    acc_cols = 0
    _item = 1
    acc_cols = acc_cols + 1
    _item = 2
    acc_cols = acc_cols + 1
    Log.trace("Columns: " <> acc_cols, %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "main"})
    {:cont, {acc_rows, acc_g, acc_cols, acc_matrix, acc_state}}
  else
    {:halt, {acc_rows, acc_g, acc_cols, acc_matrix, acc_state}}
  end
end)
    Log.trace("Rows: " <> rows, %{:fileName => "Main.hx", :lineNumber => 45, :className => "Main", :methodName => "main"})
  end
end