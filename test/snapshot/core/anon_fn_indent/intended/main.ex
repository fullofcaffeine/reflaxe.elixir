defmodule Main do
  def run() do
    xs = [1, 2, 3]
    Enum.map(xs, fn x ->
      if (x > 1), do: x + 1, else: (x - 1)
    end)
  end
  def main() do
    
  end
end
