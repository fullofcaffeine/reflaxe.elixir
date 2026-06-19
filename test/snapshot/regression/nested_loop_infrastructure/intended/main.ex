defmodule Main do
  def main() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    results = []
    g = 0
    _ = Enum.reduce(matrix, results, fn row, results_acc ->
      g = 0
      Enum.reduce(row, results_acc, fn item, results_acc -> Enum.concat(results_acc, [item * 2]) end)
    end)
    g = []
    g = Enum.reduce(matrix, g, fn row, g_acc ->
      _ = Enum.reduce(row, g, fn item, g_acc -> Enum.concat(g_acc, [item * 2]) end)
      g_acc
    end)
    _doubled = g
    _mapped = Enum.map(matrix, fn row -> Enum.map(row, fn item -> item * 2 end) end)
    sum_of_sums = 0
    g = 0
    _ = Enum.reduce(matrix, sum_of_sums, fn row, sum_of_sums_acc ->
      row_sum = 0
      g = 0
      row_sum = Enum.reduce(row, row_sum, fn item, row_sum_acc -> row_sum_acc + item end)
      sum_of_sums_acc + row_sum
    end)
    nil
  end
end
