defmodule Main do
  def main() do
    count = 0
    _ = 1
    (old_count = count
count = count + 1
old_count)
    _ = 2
    (old_count = count
count = count + 1
old_count)
    _ = 3
    (old_count = count
count = count + 1
old_count)
    numbers = [1, 2, 3, 4, 5]
    total = MyApp.Lambda.count(numbers)
    _ = nil
    _ = 1
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _g = 0
    _ = Enum.each(matrix, (fn -> fn _ ->
  (old_rows = rows
rows = rows + 1
old_rows)
  cols = 0
  _ = 1
  (old_cols = cols
cols = cols + 1
old_cols)
  _ = 2
  (old_cols = cols
cols = cols + 1
old_cols)
  nil
end end).())
    nil
  end
end
