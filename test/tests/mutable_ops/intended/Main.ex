defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * Test for mutable operations like +=, -=, etc.
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.testMutableOps()
Main.testVariableReassignment()
Main.testLoopCounters()
  end

  @doc "Function test_mutable_ops"
  @spec test_mutable_ops() :: nil
  def test_mutable_ops() do
    x = 10
x = x + 5
Log.trace("After +=: " <> x, %{fileName: "Main.hx", lineNumber: 17, className: "Main", methodName: "testMutableOps"})
x = x - 3
Log.trace("After -=: " <> x, %{fileName: "Main.hx", lineNumber: 20, className: "Main", methodName: "testMutableOps"})
x = x * 2
Log.trace("After *=: " <> x, %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "testMutableOps"})
x = x rem 3
Log.trace("After %=: " <> x, %{fileName: "Main.hx", lineNumber: 30, className: "Main", methodName: "testMutableOps"})
str = "Hello"
str = str <> " World"
Log.trace("String concat: " <> str, %{fileName: "Main.hx", lineNumber: 35, className: "Main", methodName: "testMutableOps"})
arr = [1, 2, 3]
arr = arr ++ [4, 5]
Log.trace("Array: " <> Std.string(arr), %{fileName: "Main.hx", lineNumber: 41, className: "Main", methodName: "testMutableOps"})
  end

  @doc "Function test_variable_reassignment"
  @spec test_variable_reassignment() :: nil
  def test_variable_reassignment() do
    count = 0
count = count + 1
count = count + 1
count = count + 1
Log.trace("Count after reassignments: " <> count, %{fileName: "Main.hx", lineNumber: 50, className: "Main", methodName: "testVariableReassignment"})
value = 5
if (value > 0), do: value = value * 2, else: value = value * -1
Log.trace("Value after conditional: " <> value, %{fileName: "Main.hx", lineNumber: 59, className: "Main", methodName: "testVariableReassignment"})
result = 1
result = result * 2
result = result + 10
result = result - 5
Log.trace("Result: " <> result, %{fileName: "Main.hx", lineNumber: 66, className: "Main", methodName: "testVariableReassignment"})
  end

  @doc "Function test_loop_counters"
  @spec test_loop_counters() :: nil
  def test_loop_counters() do
    i = 0
(fn loop_fn ->
  if (i < 5) do
    Log.trace("While loop i: " <> i, %{fileName: "Main.hx", lineNumber: 73, className: "Main", methodName: "testLoopCounters"})
i = i + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
j = 5
(fn loop_fn ->
  if (j > 0) do
    Log.trace("While loop j: " <> j, %{fileName: "Main.hx", lineNumber: 80, className: "Main", methodName: "testLoopCounters"})
j = j - 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
sum = 0
k = 1
(fn loop_fn ->
  if (k <= 5) do
    sum = sum + k
k = k + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
Log.trace("Sum: " <> sum, %{fileName: "Main.hx", lineNumber: 91, className: "Main", methodName: "testLoopCounters"})
total = 0
x = 0
(fn loop_fn ->
  if (x < 3) do
    y = 0
(fn loop_fn ->
  if (y < 3) do
    total = total + 1
y = y + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
x = x + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
Log.trace("Total from nested loops: " <> total, %{fileName: "Main.hx", lineNumber: 104, className: "Main", methodName: "testLoopCounters"})
  end

end
