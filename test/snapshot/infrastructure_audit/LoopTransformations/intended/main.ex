defmodule Main do
  def main() do
    fruits = ["apple", "banana", "cherry"]
    g = 0
    _ = Enum.each(fruits, fn _ -> nil end)
    g = []
    n = 1
    g = g ++ [n * 2]
    n = 2
    g = g ++ [n * 2]
    n = 3
    g = g ++ [n * 2]
    n = 4
    g = g ++ [n * 2]
    n = 5
    g = g ++ [n * 2]
    _doubled = g
    g = []
    n = 1
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    n = 2
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    n = 3
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    n = 4
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    n = 5
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    n = 6
    if (rem(n, 2) == 0) do
      g = g ++ [n]
    else
      g
    end
    _evens = g
    _grid = [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g = g ++ [2]
  g
end).(), (fn ->
  g = []
  g = g ++ [3]
  g = g ++ [4]
  g = g ++ [5]
  g
end).(), (fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g = g ++ [8]
  g
end).()]
    nil
  end
end
