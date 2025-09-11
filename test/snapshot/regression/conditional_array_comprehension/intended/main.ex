defmodule Main do
  def main() do
    evens = for i <- 0..9, :erlang.rem(i, 2) == 0, do: i
    Log.trace("Even numbers: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "main"})
    even_squares = for i <- 0..8, :erlang.rem(i, 2) == 0, do: i
    Log.trace("Even squares: " <> Std.string(even_squares), %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
    results = [%{:value => 3, :square => 9}, %{:value => 4, :square => 16}]
    Log.trace("Results: " <> Std.string(results), %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})
    odds = for i <- 0..9, :erlang.rem(i, 2) != 0, do: i
    Log.trace("Odd numbers: " <> Std.string(odds), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "main"})
  end
end