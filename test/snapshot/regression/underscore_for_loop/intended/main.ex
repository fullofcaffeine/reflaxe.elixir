defmodule Main do
  def main() do
    # Test 1: Simple underscore in for loop
    count = Enum.reduce([1, 2, 3], 0, fn _item, acc_count ->
      acc_count + 1
    end)
    Log.trace("Count: #{count}", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})

    # Test 2: Lambda with underscore variable
    numbers = [1, 2, 3, 4, 5]
    total = Lambda.count(numbers)
    Log.trace("Total count: #{total}", %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})

    # Test 3: Empty check with underscore
    empty_list = []
    non_empty_list = [1]
    Log.trace("Empty list is empty: #{Lambda.empty(empty_list)}", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "main"})
    Log.trace("Non-empty list is empty: #{Lambda.empty(non_empty_list)}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "main"})

    # Test 4: Nested for loops with underscores
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = Enum.reduce(matrix, 0, fn _row, acc_rows ->
      cols = Enum.reduce([1, 2], 0, fn _col, acc_cols ->
        acc_cols + 1
      end)
      Log.trace("Columns: #{cols}", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "main"})
      acc_rows + 1
    end)
    Log.trace("Rows: #{rows}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
  end
end