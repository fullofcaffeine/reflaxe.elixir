defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test for mutable operations like +=, -=, etc.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_mutable_ops()

    Main.test_variable_reassignment()

    Main.test_loop_counters()
  end

  @doc "Generated from Haxe testMutableOps"
  def test_mutable_ops() do
    x = 10

    x = x + 5

    Log.trace("After +=: " <> to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "testMutableOps"})

    x = x - 3

    Log.trace("After -=: " <> to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "testMutableOps"})

    x = x * 2

    Log.trace("After *=: " <> to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "testMutableOps"})

    x = rem(x, 3)

    Log.trace("After %=: " <> to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "testMutableOps"})

    str = "Hello"

    str = str <> " World"

    Log.trace("String concat: " <> str, %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "testMutableOps"})

    arr = [1, 2, 3]

    arr = arr ++ [4, 5]

    Log.trace("Array: " <> Std.string(arr), %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testMutableOps"})
  end

  @doc "Generated from Haxe testVariableReassignment"
  def test_variable_reassignment() do
    count = 0

    count = (count + 1)

    count = (count + 1)

    count = (count + 1)

    Log.trace("Count after reassignments: " <> to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 50, "className" => "Main", "methodName" => "testVariableReassignment"})

    value = 5

    if ((value > 0)), do: value = (value * 2), else: value = (value * -1)

    Log.trace("Value after conditional: " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 59, "className" => "Main", "methodName" => "testVariableReassignment"})

    result = 1

    result = (result * 2)

    result = (result + 10)

    result = (result - 5)

    Log.trace("Result: " <> to_string(result), %{"fileName" => "Main.hx", "lineNumber" => 66, "className" => "Main", "methodName" => "testVariableReassignment"})
  end

  @doc "Generated from Haxe testLoopCounters"
  def test_loop_counters() do
    i = 0

    (fn loop ->
      if ((i < 5)) do
            Log.trace("While loop i: " <> to_string(i), %{"fileName" => "Main.hx", "lineNumber" => 73, "className" => "Main", "methodName" => "testLoopCounters"})
        i + 1
        loop.()
      end
    end).()

    j = 5

    (fn loop ->
      if ((j > 0)) do
            Log.trace("While loop j: " <> to_string(j), %{"fileName" => "Main.hx", "lineNumber" => 80, "className" => "Main", "methodName" => "testLoopCounters"})
        j - 1
        loop.()
      end
    end).()

    sum = 0

    k = 1

    (fn loop ->
      if ((k <= 5)) do
            sum = sum + k
        k + 1
        loop.()
      end
    end).()

    Log.trace("Sum: " <> to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 91, "className" => "Main", "methodName" => "testLoopCounters"})

    total = 0

    x = 0

    (fn loop ->
      if ((x < 3)) do
            y = 0
        (fn loop ->
          if ((y < 3)) do
                total = total + 1
            y + 1
            loop.()
          end
        end).()
        x + 1
        loop.()
      end
    end).()

    Log.trace("Total from nested loops: " <> to_string(total), %{"fileName" => "Main.hx", "lineNumber" => 104, "className" => "Main", "methodName" => "testLoopCounters"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
