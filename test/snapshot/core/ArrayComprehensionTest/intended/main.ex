defmodule Main do
  def main() do
    _matrix = [(fn ->
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
    g = []
    g = g ++ [0]
    g = g ++ [2]
    g = g ++ [4]
    g = g ++ [6]
    _evens = g ++ [8]
    multiplier = 2
    _doubled = [0 * multiplier, multiplier, 2 * multiplier, 3 * multiplier, 4 * multiplier]
    nil
  end
end
