defmodule Main do
  def main() do
    squares = for i <- 0..4, do: i * i
    Log.trace(squares, %{:file_name => "Main.hx", :line_number => 5, :class_name => "Main", :method_name => "main"})

    matrix = for i <- 0..2, do: (for j <- 0..2, do: i * 3 + j)
    Log.trace(matrix, %{:file_name => "Main.hx", :line_number => 9, :class_name => "Main", :method_name => "main"})

    evens = for i <- 0..9, rem(i, 2) == 0, do: i
    Log.trace(evens, %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})

    multiplier = 2
    doubled = for i <- 0..4, do: i * multiplier
    Log.trace(doubled, %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
  end
end