defmodule Main do
  def main() do
    count = 0
    _ = 1
    count = count + 1
    _ = 2
    count = count + 1
    _ = 3
    count = count + 1
    _ = Log.trace("Count: #{(fn -> count end).()}", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
    numbers = [1, 2, 3, 4, 5]
    total = MyApp.Lambda.count(numbers)
    _ = Log.trace("Total count: #{(fn -> total end).()}", %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    empty_list = []
    non_empty_list = [1]
    _ = Log.trace("Empty list is empty: #{(fn -> inspect(Lambda.empty(empty_list)) end).()}", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "main"})
    _ = Log.trace("Non-empty list is empty: #{(fn -> inspect(Lambda.empty(non_empty_list)) end).()}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "main"})
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    _ = Enum.each(matrix, (fn -> fn item ->
    item + 1
  cols = 0
  _2 = 1
  item + 1
  _2 = 2
  item + 1
  Log.trace("Columns: " <> Kernel.to_string(cols), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "main"})
end end).())
    _ = Log.trace("Rows: #{(fn -> rows end).()}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
  end
end
