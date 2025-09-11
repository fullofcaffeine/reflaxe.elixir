defmodule Main do
  def main() do
    test_mutable_ops()
    test_variable_reassignment()
    test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    Log.trace("After +=: " <> Kernel.to_string(x), %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "testMutableOps"})
    x = (x - 3)
    Log.trace("After -=: " <> Kernel.to_string(x), %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "testMutableOps"})
    x = x * 2
    Log.trace("After *=: " <> Kernel.to_string(x), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testMutableOps"})
    x = rem(x, 3)
    Log.trace("After %=: " <> Kernel.to_string(x), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testMutableOps"})
    str = "Hello"
    str = str <> " World"
    Log.trace("String concat: " <> str, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testMutableOps"})
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    Log.trace("Array: " <> Std.string(arr), %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testMutableOps"})
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    Log.trace("Count after reassignments: " <> Kernel.to_string(count), %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testVariableReassignment"})
    value = 5
    if (value > 0) do
      value = value * 2
    else
      value = value * -1
    end
    Log.trace("Value after conditional: " <> Kernel.to_string(value), %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testVariableReassignment"})
    result = 1
    result = result * 2
    result = result + 10
    result = (result - 5)
    Log.trace("Result: " <> Kernel.to_string(result), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testVariableReassignment"})
  end
  defp test_loop_counters() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    Log.trace("While loop i: " <> Kernel.to_string(acc_i), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "testLoopCounters"})
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    j = 5
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j > 0) do
    Log.trace("While loop j: " <> Kernel.to_string(acc_j), %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testLoopCounters"})
    acc_j = (acc_j - 1)
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    sum = 0
    k = 1
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, k, :ok}, fn _, {acc_sum, acc_k, acc_state} -> nil end)
    Log.trace("Sum: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testLoopCounters"})
    total = 0
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, x, y, :ok}, fn _, {acc_total, acc_x, acc_y, acc_state} -> nil end)
    Log.trace("Total from nested loops: " <> Kernel.to_string(total), %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testLoopCounters"})
  end
end