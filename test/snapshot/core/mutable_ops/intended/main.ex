defmodule Main do
  def main() do
    test_mutable_ops()
    test_variable_reassignment()
    test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    Log.trace("After +=: " <> x, %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "testMutableOps"})
    x = (x - 3)
    Log.trace("After -=: " <> x, %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "testMutableOps"})
    x = x * 2
    Log.trace("After *=: " <> x, %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "testMutableOps"})
    x = x rem 3
    Log.trace("After %=: " <> x, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testMutableOps"})
    str = "Hello"
    str = str <> " World"
    Log.trace("String concat: " <> str, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "testMutableOps"})
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    Log.trace("Array: " <> Std.string(arr), %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testMutableOps"})
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    Log.trace("Count after reassignments: " <> count, %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "testVariableReassignment"})
    value = 5
    if (value > 0) do
      value = value * 2
    else
      value = value * -1
    end
    Log.trace("Value after conditional: " <> value, %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "testVariableReassignment"})
    result = 1
    result = result * 2
    result = result + 10
    result = (result - 5)
    Log.trace("Result: " <> result, %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "testVariableReassignment"})
  end
  defp test_loop_counters() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    Log.trace("While loop i: " <> acc_i, %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "testLoopCounters"})
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    j = 5
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j > 0) do
    Log.trace("While loop j: " <> acc_j, %{:fileName => "Main.hx", :lineNumber => 80, :className => "Main", :methodName => "testLoopCounters"})
    acc_j = (acc_j - 1)
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    sum = 0
    k = 1
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, k, :ok}, fn _, {acc_sum, acc_k, acc_state} ->
  if (acc_k <= 5) do
    acc_sum = acc_sum + acc_k
    acc_k = acc_k + 1
    {:cont, {acc_sum, acc_k, acc_state}}
  else
    {:halt, {acc_sum, acc_k, acc_state}}
  end
end)
    Log.trace("Sum: " <> sum, %{:fileName => "Main.hx", :lineNumber => 91, :className => "Main", :methodName => "testLoopCounters"})
    total = 0
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, y, x, :ok}, fn _, {acc_total, acc_y, acc_x, acc_state} ->
  if (acc_x < 3) do
    acc_y = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_total, acc_y, :ok}, fn _, {acc_total, acc_y, acc_state} ->
  if (acc_y < 3) do
    acc_total = acc_total + 1
    acc_y = acc_y + 1
    {:cont, {acc_total, acc_y, acc_state}}
  else
    {:halt, {acc_total, acc_y, acc_state}}
  end
end)
    acc_x = acc_x + 1
    {:cont, {acc_total, acc_y, acc_x, acc_state}}
  else
    {:halt, {acc_total, acc_y, acc_x, acc_state}}
  end
end)
    Log.trace("Total from nested loops: " <> total, %{:fileName => "Main.hx", :lineNumber => 104, :className => "Main", :methodName => "testLoopCounters"})
  end
end