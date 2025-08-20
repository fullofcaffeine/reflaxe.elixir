defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test for mutable operations like +=, -=, etc.
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.test_mutable_ops()
    Main.test_variable_reassignment()
    Main.test_loop_counters()
  end

  @doc "Function test_mutable_ops"
  @spec test_mutable_ops() :: nil
  def test_mutable_ops() do
    x = 10
    x = x + 5
    Log.trace("After +=: " <> Integer.to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 17, "className" => "Main", "methodName" => "testMutableOps"})
    x = x - 3
    Log.trace("After -=: " <> Integer.to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "testMutableOps"})
    x = x * 2
    Log.trace("After *=: " <> Integer.to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "testMutableOps"})
    x = x rem 3
    Log.trace("After %=: " <> Integer.to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "testMutableOps"})
    str = "Hello"
    str = str <> " World"
    Log.trace("String concat: " <> str, %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "testMutableOps"})
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    Log.trace("Array: " <> Std.string(arr), %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testMutableOps"})
  end

  @doc "Function test_variable_reassignment"
  @spec test_variable_reassignment() :: nil
  def test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    Log.trace("Count after reassignments: " <> Integer.to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 50, "className" => "Main", "methodName" => "testVariableReassignment"})
    value = 5
    if (value > 0), do: value = value * 2, else: value = value * -1
    Log.trace("Value after conditional: " <> Integer.to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 59, "className" => "Main", "methodName" => "testVariableReassignment"})
    result = 1
    result = result * 2
    result = result + 10
    result = result - 5
    Log.trace("Result: " <> Integer.to_string(result), %{"fileName" => "Main.hx", "lineNumber" => 66, "className" => "Main", "methodName" => "testVariableReassignment"})
  end

  @doc "Function test_loop_counters"
  @spec test_loop_counters() :: nil
  def test_loop_counters() do
    i = 0
    (
      loop_helper = fn loop_fn, {i} ->
        if (i < 5) do
          try do
            Log.trace("While loop i: " <> Integer.to_string(i), %{"fileName" => "Main.hx", "lineNumber" => 73, "className" => "Main", "methodName" => "testLoopCounters"})
          i = i + 1
          loop_fn.({i + 1})
            loop_fn.(loop_fn, {i})
          catch
            :break -> {i}
            :continue -> loop_fn.(loop_fn, {i})
          end
        else
          {i}
        end
      end
      {i} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    j = 5
    (
      loop_helper = fn loop_fn, {j} ->
        if (j > 0) do
          try do
            Log.trace("While loop j: " <> Integer.to_string(j), %{"fileName" => "Main.hx", "lineNumber" => 80, "className" => "Main", "methodName" => "testLoopCounters"})
          j = j - 1
          loop_fn.({j - 1})
            loop_fn.(loop_fn, {j})
          catch
            :break -> {j}
            :continue -> loop_fn.(loop_fn, {j})
          end
        else
          {j}
        end
      end
      {j} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    sum = 0
    k = 1
    (
      loop_helper = fn loop_fn, {sum, k} ->
        if (k <= 5) do
          try do
            sum = sum + k
          k = k + 1
          loop_fn.({sum + k, k + 1})
            loop_fn.(loop_fn, {sum, k})
          catch
            :break -> {sum, k}
            :continue -> loop_fn.(loop_fn, {sum, k})
          end
        else
          {sum, k}
        end
      end
      {sum, k} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    Log.trace("Sum: " <> Integer.to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 91, "className" => "Main", "methodName" => "testLoopCounters"})
    total = 0
    x = 0
    (
      loop_helper = fn loop_fn, {x} ->
        if (x < 3) do
          try do
            y = 0
          (
      loop_helper = fn loop_fn, {total, y} ->
        if (y < 3) do
          try do
            total = total + 1
          y = y + 1
          loop_fn.({total + 1, y + 1})
            loop_fn.(loop_fn, {total, y})
          catch
            :break -> {total, y}
            :continue -> loop_fn.(loop_fn, {total, y})
          end
        else
          {total, y}
        end
      end
      {total, y} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
          x = x + 1
          loop_fn.({x + 1})
            loop_fn.(loop_fn, {x})
          catch
            :break -> {x}
            :continue -> loop_fn.(loop_fn, {x})
          end
        else
          {x}
        end
      end
      {x} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Log.trace("Total from nested loops: " <> Integer.to_string(total), %{"fileName" => "Main.hx", "lineNumber" => 104, "className" => "Main", "methodName" => "testLoopCounters"})
  end

end
