defmodule Main do
  def main() do
    test_mutable_ops()
    test_variable_reassignment()
    test_loop_counters()
  end

  defp test_mutable_ops() do
    x = 10
    x = x + 5
    Log.trace("After +=: #{x}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "testMutableOps"})

    x = x - 3
    Log.trace("After -=: #{x}", %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "testMutableOps"})

    x = x * 2
    Log.trace("After *=: #{x}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testMutableOps"})

    x = rem(x, 3)
    Log.trace("After %=: #{x}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testMutableOps"})

    str = "Hello"
    str = str <> " World"
    Log.trace("String concat: #{str}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "testMutableOps"})

    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    Log.trace("Array: #{inspect(arr)}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testMutableOps"})
  end

  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    Log.trace("Count after reassignments: #{count}", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testVariableReassignment"})

    value = 5
    value = if value > 0 do
      value * 2
    else
      value * -1
    end
    Log.trace("Value after conditional: #{value}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "testVariableReassignment"})

    result = 1
    result = result * 2
    result = result + 10
    result = result - 5
    Log.trace("Result: #{result}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testVariableReassignment"})
  end

  defp test_loop_counters() do
    # While loop with increment
    defp while_increment(i) when i < 5 do
      Log.trace("While loop i: #{i}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "testLoopCounters"})
      while_increment(i + 1)
    end
    defp while_increment(_i), do: :ok
    while_increment(0)

    # While loop with decrement
    defp while_decrement(j) when j > 0 do
      Log.trace("While loop j: #{j}", %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testLoopCounters"})
      while_decrement(j - 1)
    end
    defp while_decrement(_j), do: :ok
    while_decrement(5)

    # Sum calculation with loop
    sum = Enum.reduce(1..5, 0, fn k, acc -> acc + k end)
    Log.trace("Sum: #{sum}", %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testLoopCounters"})

    # Nested loops for total calculation
    total = for x <- 0..2, y <- 0..2, reduce: 0 do
      acc -> acc + x + y
    end
    Log.trace("Total from nested loops: #{total}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testLoopCounters"})
  end
end