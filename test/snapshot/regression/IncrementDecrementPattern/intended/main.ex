defmodule Main do
  defp test_while_loop() do
    k = 10
    pos = 0
    _ = Enum.each(k, (fn -> fn item ->
  Log.trace("Processing at position: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "testWhileLoop"})
  item + 1
  (item - 1)
end end).())
    _ = Log.trace("Final: k=#{(fn -> k end).()}, pos=#{(fn -> pos end).()}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testWhileLoop"})
  end
  defp test_for_loop() do
    count = 0
    _ = Log.trace("Iteration: #{(fn -> 0 end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    _ = Log.trace("Iteration: #{(fn -> 1 end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    _ = Log.trace("Iteration: #{(fn -> 2 end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    _ = Log.trace("Iteration: #{(fn -> 3 end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    _ = Log.trace("Iteration: #{(fn -> 4 end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
    count = count + 1
    _ = Log.trace("Total count: #{(fn -> count end).()}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testForLoop"})
  end
end
