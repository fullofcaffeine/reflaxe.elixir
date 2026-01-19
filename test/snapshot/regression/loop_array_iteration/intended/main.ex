defmodule Main do
  def main() do
    names = ["Alice", "Bob", "Charlie"]
    _g = 0
    names_length = length(names)
    _ = Enum.each(0..(names_length - 1)//1, fn _ -> nil end)
    _g = 0
    _ = Enum.each(names, fn _ -> nil end)
    grid = [[1, 2], [3, 4], [5, 6]]
    _g = 0
    grid_length = length(grid)
    _ = Enum.each(0..(grid_length - 1)//1, fn row ->
  _g = 0
  grid_length = length(grid[row])
  _ = Enum.each(0..(grid_length - 1)//1, fn _ -> nil end)
end)
  end
end
