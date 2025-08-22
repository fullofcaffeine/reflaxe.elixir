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
          case (elem(color, 0)) do
      0 -> temp_string = "red"
      1 -> temp_string = "green"
      2 -> temp_string = "blue"
      3 -> (
          elem(color, 1)
          elem(color, 2)
          elem(color, 3)
          temp_string = "custom"
        )
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
          case (elem(color, 0)) do
      0 -> temp_string = "primary"
      1 -> temp_string = "primary"
      2 -> temp_string = "primary"
      3 -> g = elem(color, 1)
    g = elem(color, 2)
    g = elem(color, 3)
    r = g
    g = g
    b = g
    if ((((r + nil) + b) > 500)) do
          temp_string = "bright"
        else
          (
          r = g
          g = g
          b = g
          if ((((r + nil) + b) < 100)) do
          temp_string = "dark"
        else
          (
          g
          g
          g
          temp_string = "medium"
        )
        end
        )
        end
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
          case (elem(result, 0)) do
      0 -> (
          g = elem(result, 1)
          value = g
          temp_string = "Got value: " <> value
        )
      1 -> (
          g = elem(result, 1)
          error = g
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
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          num = Enum.at(numbers, g)
          g + 1
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
        ) end)
        )
  end

  @doc "Function test_array_patterns"
  @spec test_array_patterns() :: nil
  def test_array_patterns() do
    (
          arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
          g_counter = 0
          while_loop(fn -> ((g < arrays.length)) end, fn -> (
          arr = Enum.at(arrays, g)
          g + 1
          temp_string = nil
          case (arr.length) do
      0 -> temp_string = "empty"
      1 -> (
          g = Enum.at(arr, 0)
          (
          x = g
          temp_string = "single: " <> to_string(x)
        )
        )
      2 -> (
          g = Enum.at(arr, 0)
          g = Enum.at(arr, 1)
          (
          x = g
          y = g
          temp_string = "pair: " <> to_string(x) <> ", " <> to_string(y)
        )
        )
      3 -> (
          g = Enum.at(arr, 0)
          g = Enum.at(arr, 1)
          g = Enum.at(arr, 2)
          (
          x = g
          y = g
          z = g
          temp_string = "triple: " <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z)
        )
        )
      _ -> (
          temp_string1 = nil
          if ((arr.length > 0)) do
          temp_string1 = Std.string(Enum.at(arr, 0))
        else
          temp_string1 = "none"
        end
          temp_string = "length=" <> to_string(arr.length) <> ", first=" <> (temp_string1)
        )
    end
          description = temp_string
          Log.trace("Array pattern: " <> description, %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "testArrayPatterns"})
        ) end)
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
          g = point_x
          g = point_y
          x = g
          y = g
          if (((x > 0) && (y > 0))) do
          temp_string = "first"
        else
          (
          x = g
          y = g
          if (((x < 0) && (y > 0))) do
          temp_string = "second"
        else
          (
          x = g
          y = g
          if (((x < 0) && (y < 0))) do
          temp_string = "third"
        else
          (
          x = g
          y = g
          if (((x > 0) && (y < 0))) do
          temp_string = "fourth"
        else
          if ((g == 0)) do
          temp_string = "axis"
        else
          if ((g == 0)) do
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

end
