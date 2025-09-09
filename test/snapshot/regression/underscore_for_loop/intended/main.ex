defmodule Main do
  def main() do
    count = 0
    _item = 1
    count = count + 1
    _item = 2
    count = count + 1
    _item = 3
    count = count + 1
    Log.trace("Count: " <> Kernel.to_string(count), %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
    numbers = [1, 2, 3, 4, 5]
    total = Lambda.count(numbers)
    Log.trace("Total count: " <> Kernel.to_string(total), %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    empty_list = []
    non_empty_list = [1]
    Log.trace("Empty list is empty: " <> Std.string(Lambda.empty(empty_list)), %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "main"})
    Log.trace("Non-empty list is empty: " <> Std.string(Lambda.empty(non_empty_list)), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "main"})
    matrix = [[1, 2], [3, 4], [5, 6]]
    rows = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {cols, rows, matrix, g, :ok}, fn _, {acc_cols, acc_rows, acc_matrix, acc_g, acc_state} -> nil end)
    Log.trace("Rows: " <> Kernel.to_string(rows), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("lambda.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()