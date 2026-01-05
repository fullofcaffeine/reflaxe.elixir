defmodule Main do
  def main() do
    g = []
    g = g ++ [0]
    g = g ++ [2]
    g = g ++ [4]
    g = g ++ [6]
    _evens = g ++ [8]
    g = []
    g = g ++ [4]
    g = g ++ [16]
    g = g ++ [36]
    _even_squares = g ++ [64]
    g = []
    g = g ++ [1]
    g = g ++ [3]
    g = g ++ [5]
    g = g ++ [7]
    _odds = g ++ [9]
    nil
  end
end
