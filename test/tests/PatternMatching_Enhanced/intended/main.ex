defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.test_simple_enum_pattern()
    Main.test_complex_enum_pattern()
    Main.test_result_pattern()
    Main.test_guard_patterns()
    Main.test_array_patterns()
    Main.test_object_patterns()
    Log.trace("Pattern matching tests complete", %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "main"})
  end

  @doc "Function test_simple_enum_pattern"
  @spec test_simple_enum_pattern() :: nil
  def test_simple_enum_pattern() do
    (
          color = :red
          temp_string = nil
          case color do
      :red -> temp_string = "red"
      :green -> temp_string = "green"
      :blue -> temp_string = "blue"
      :r_g_b -> temp_string = "custom"
    end
          Log.trace("Simple enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "testSimpleEnumPattern"})
        )
  end

  @doc "Function test_complex_enum_pattern"
  @spec test_complex_enum_pattern() :: nil
  def test_complex_enum_pattern() do
    (
          color = Color.r_g_b(255, 128, 0)
          temp_string = nil
          case color do
      :red -> temp_string = "primary"
      :green -> temp_string = "primary"
      :blue -> temp_string = "primary"
      :r_g_b -> (
          r = g_array
          g_array = g_array
          b = g_array
          if ((((r + g) + b) > 500)) do
          temp_string = "bright"
        else
          (
          r = g_array
          g_array = g_array
          b = g_array
          if ((((r + g) + b) < 100)) do
          temp_string = "dark"
        else
          temp_string = "medium"
        end
        )
        end
        )
    end
          Log.trace("Complex enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "testComplexEnumPattern"})
        )
  end

  @doc "Function test_result_pattern"
  @spec test_result_pattern() :: nil
  def test_result_pattern() do
    (
          result = {:ok, "success"}
          temp_string = nil
          case result do
      {:ok, _} -> (
          value = g_array
          temp_string = "Got value: " <> value
        )
      {:error, _} -> (
          error = g_array
          temp_string = "Got error: " <> error
        )
    end
          Log.trace("Result pattern: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "testResultPattern"})
        )
  end

  @doc "Function test_guard_patterns"
  @spec test_guard_patterns() :: nil
  def test_guard_patterns() do
    (
          numbers = [1, 5, 10, 15, 20]
          g_counter = 0
          Enum.each(numbers, fn num -> 
      temp_string = nil
      (
          n = num
          if ((n < 5)) do
          temp_string = "small"
        else
          (
          n = num
          if (((n >= 5) && (n < 15))) do
          temp_string = "medium"
        else
          (
          n = num
          if ((n >= 15)) do
          temp_string = "large"
        else
          temp_string = "unknown"
        end
        )
        end
        )
        end
        )
      category = temp_string
      Log.trace("Number " <> to_string(num) <> " is " <> category, %{"fileName" => "Main.hx", "lineNumber" => 98, "className" => "Main", "methodName" => "testGuardPatterns"})
    end)
        )
  end

  @doc "Function test_array_patterns"
  @spec test_array_patterns() :: nil
  def test_array_patterns() do
    (
          arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
          g_counter = 0
          Enum.each(arrays, fn arr -> 
      temp_string = nil
      case (elem(arr.length, 0)) do
      0 ->
        temp_string = "empty"
      1 ->
        (
          g_array = Enum.at(arr, 0)
          (
          x = g_array
          temp_string = "single: " <> to_string(x)
        )
        )
      2 ->
        (
          g_array = Enum.at(arr, 0)
          g_array = Enum.at(arr, 1)
          (
          x = g_array
          y = g_array
          temp_string = "pair: " <> to_string(x) <> ", " <> to_string(y)
        )
        )
      3 ->
        (
          g_array = Enum.at(arr, 0)
          g_array = Enum.at(arr, 1)
          g_array = Enum.at(arr, 2)
          (
          x = g_array
          y = g_array
          z = g_array
          temp_string = "triple: " <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z)
        )
        )
      _ -> tempString1 = if ((arr.length > 0)), do: Std.string(Enum.at(arr, 0)), else: "none"
    end
      description = temp_string
      Log.trace("Array pattern: " <> description, %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "testArrayPatterns"})
    end)
        )
  end

  @doc "Function test_object_patterns"
  @spec test_object_patterns() :: nil
  def test_object_patterns() do
    (
          point_x = 10
          point_y = 20
          temp_string = nil
          (
          g_array = point_x
          g_array = point_y
          x = g_array
          y = g_array
          if (((x > 0) && (y > 0))) do
          temp_string = "first"
        else
          (
          x = g_array
          y = g_array
          if (((x < 0) && (y > 0))) do
          temp_string = "second"
        else
          (
          x = g_array
          y = g_array
          if (((x < 0) && (y < 0))) do
          temp_string = "third"
        else
          (
          x = g_array
          y = g_array
          if (((x > 0) && (y < 0))) do
          temp_string = "fourth"
        else
          if ((g_array == 0)) do
          temp_string = "axis"
        else
          if ((g_array == 0)) do
          temp_string = "axis"
        else
          temp_string = "origin"
        end
        end
        end
        )
        end
        )
        end
        )
        end
        )
          Log.trace("Point " <> to_string(point_x) <> "," <> to_string(point_y) <> " is in " <> temp_string <> " quadrant", %{"fileName" => "Main.hx", "lineNumber" => 135, "className" => "Main", "methodName" => "testObjectPatterns"})
        )
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
