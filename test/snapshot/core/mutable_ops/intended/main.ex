defmodule Main do
  def main() do
    Main.test_mutable_ops()
    Main.test_variable_reassignment()
    Main.test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    Log.trace("After +=: " + x, %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "testMutableOps"})
    x = x - 3
    Log.trace("After -=: " + x, %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "testMutableOps"})
    x = x * 2
    Log.trace("After *=: " + x, %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "testMutableOps"})
    x = x rem 3
    Log.trace("After %=: " + x, %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testMutableOps"})
    str = "Hello"
    str = str + " World"
    Log.trace("String concat: " + str, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "testMutableOps"})
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    Log.trace("Array: " + Std.string(arr), %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testMutableOps"})
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    Log.trace("Count after reassignments: " + count, %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "testVariableReassignment"})
    value = 5
    if (value > 0) do
      value = value * 2
    else
      value = value * -1
    end
    Log.trace("Value after conditional: " + value, %{:fileName => "Main.hx", :lineNumber => 59, :className => "Main", :methodName => "testVariableReassignment"})
    result = 1
    result = result * 2
    result = result + 10
    result = result - 5
    Log.trace("Result: " + result, %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "testVariableReassignment"})
  end
  defp test_loop_counters() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < 5) do
  Log.trace("While loop i: " + i, %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "testLoopCounters"})
  i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    j = 5
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (j > 0) do
  Log.trace("While loop j: " + j, %{:fileName => "Main.hx", :lineNumber => 80, :className => "Main", :methodName => "testLoopCounters"})
  j - 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    sum = 0
    k = 1
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k <= 5) do
  sum = sum + k
  k + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Sum: " + sum, %{:fileName => "Main.hx", :lineNumber => 91, :className => "Main", :methodName => "testLoopCounters"})
    total = 0
    x = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (x < 3) do
  y = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (y < 3) do
  total = total + 1
  y + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
  x + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Total from nested loops: " + total, %{:fileName => "Main.hx", :lineNumber => 104, :className => "Main", :methodName => "testLoopCounters"})
  end
end