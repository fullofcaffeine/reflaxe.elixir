defmodule Main do
  def main() do
    test_array_concatenation()
    test_nested_array_building()
  end
  defp test_array_concatenation() do
    arr = []
    arr = arr ++ [1]
    arr = arr ++ [2]
    _ = arr ++ [3]
    nil
  end
  defp test_nested_array_building() do
    matrix = []
    row = []
    row = row ++ [0]
    row = row ++ [1]
    row = row ++ [2]
    matrix = matrix ++ [row]
    row = []
    row = row ++ [3]
    row = row ++ [4]
    row = row ++ [5]
    matrix = matrix ++ [row]
    row = []
    row = row ++ [6]
    row = row ++ [7]
    row = row ++ [8]
    _ = matrix ++ [row]
    nil
  end
end
