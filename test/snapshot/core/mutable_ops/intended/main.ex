defmodule Main do
  def main() do
    _ = test_mutable_ops()
    _ = test_variable_reassignment()
    _ = test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    _ = Log.trace("After +=: #{(fn -> x end).()}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "testMutableOps"})
    x = (x - 3)
    _ = Log.trace("After -=: #{(fn -> x end).()}", %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "testMutableOps"})
    x = x * 2
    _ = Log.trace("After *=: #{(fn -> x end).()}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testMutableOps"})
    x = rem(x, 3)
    _ = Log.trace("After %=: #{(fn -> x end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testMutableOps"})
    str = "Hello"
    str = "#{(fn -> str end).()} World"
    _ = Log.trace("String concat: #{(fn -> str end).()}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testMutableOps"})
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    _ = Log.trace("Array: #{(fn -> inspect(arr) end).()}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testMutableOps"})
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    _ = Log.trace("Count after reassignments: #{(fn -> count end).()}", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testVariableReassignment"})
    value = 5
    if (value > 0) do
      value = value * 2
    else
      value = value * -1
    end
    _ = Log.trace("Value after conditional: #{(fn -> value end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testVariableReassignment"})
    result = 1
    result = result * 2
    result = result + 10
    result = (result - 5)
    _ = Log.trace("Result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testVariableReassignment"})
  end
  defp test_loop_counters() do
    i = 0
    _ = Enum.each(0..(5 - 1), (fn -> fn i ->
  Log.trace("While loop i: " <> Kernel.to_string(i), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "testLoopCounters"})
  i + 1
end end).())
    j = 5
    _ = Enum.each(j, (fn -> fn item ->
  Log.trace("While loop j: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testLoopCounters"})
  (item - 1)
end end).())
    sum = 0
    k = 1
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, k}, (fn -> fn _, {sum, k} ->
  if (k <= 5) do
    sum = sum + k
    k + 1
    {:cont, {sum, k}}
  else
    {:halt, {sum, k}}
  end
end end).())
    _ = Log.trace("Sum: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testLoopCounters"})
    total = 0
    x = 0
    _ = Enum.each(0..(3 - 1), (fn -> fn x ->
  y = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, y}, (fn -> fn _, {total, y} ->
    if (y < 3) do
      total = total + 1
      y + 1
      {:cont, {total, y}}
    else
      {:halt, {total, y}}
    end
  end end).())
  x + 1
end end).())
    _ = Log.trace("Total from nested loops: #{(fn -> total end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testLoopCounters"})
  end
end
