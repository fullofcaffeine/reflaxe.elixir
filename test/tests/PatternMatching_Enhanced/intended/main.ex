defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_simple_enum_pattern()

    Main.test_complex_enum_pattern()

    Main.test_result_pattern()

    Main.test_guard_patterns()

    Main.test_array_patterns()

    Main.test_object_patterns()

    Log.trace("Pattern matching tests complete", %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "main"})
  end

  @doc "Generated from Haxe testSimpleEnumPattern"
  def test_simple_enum_pattern() do
    temp_string = nil

    color = :red

    temp_string = nil

    case (case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end) do
      0 -> temp_string = "red"
      1 -> temp_string = "green"
      2 -> temp_string = "blue"
      3 -> temp_string = "custom"
    end

    Log.trace("Simple enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "testSimpleEnumPattern"})
  end

  @doc "Generated from Haxe testComplexEnumPattern"
  def test_complex_enum_pattern() do
    temp_string = nil

    color = Color.r_g_b(255, 128, 0)

    case (case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end) do
      0 -> temp_string = "primary"
      1 -> temp_string = "primary"
      2 -> temp_string = "primary"
      {3, _r, _g, _b} -> g_array = elem(color, 1)
    g_array = elem(color, 2)
    g_array = elem(color, 3)
    if ((((r + g_array) + b) > 500)) do
      temp_string = "bright"
    else
      if ((((r + g_array) + b) < 100)) do
        temp_string = "dark"
      else
        temp_string = "medium"
      end
    end
    end

    Log.trace("Complex enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "testComplexEnumPattern"})
  end

  @doc "Generated from Haxe testResultPattern"
  def test_result_pattern() do
    temp_string = nil

    result = {:ok, "success"}

    case (case result do :ok -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(result, 1)
    temp_string = "Got value: " <> value
      {1, error} -> g_array = elem(result, 1)
    temp_string = "Got error: " <> error
    end

    Log.trace("Result pattern: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "testResultPattern"})
  end

  @doc "Generated from Haxe testGuardPatterns"
  def test_guard_patterns() do
    temp_string = nil

    numbers = [1, 5, 10, 15, 20]

    g_counter = 0

    Enum.each(g_array, fn num -> 
      
      n = num
    if ((n < 5)) do
      temp_string = "small"
    else
      n = num
      if (((n >= 5) && (n < 15))) do
        temp_string = "medium"
      else
        n = num
        if ((n >= 15)), do: temp_string = "large", else: temp_string = "unknown"
      end
    end
      category = temp_string
      Log.trace("Number " <> to_string(num) <> " is " <> category, %{"fileName" => "Main.hx", "lineNumber" => 98, "className" => "Main", "methodName" => "testGuardPatterns"})
    end)
  end

  @doc "Generated from Haxe testArrayPatterns"
  def test_array_patterns() do
    temp_string = nil
    temp_string1 = nil

    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]

    g_counter = 0

    Enum.each(g_array, fn arr -> 
      
      case (arr.length) do
      _ ->
        temp_string = "empty"
      _ ->
        g_array = Enum.at(arr, 0)
    x = g_array
    temp_string = "single: " <> to_string(x)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    x = g_array
    y = g_array
    temp_string = "pair: " <> to_string(x) <> ", " <> to_string(y)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    g_array = Enum.at(arr, 2)
    x = g_array
    y = g_array
    z = g_array
    temp_string = "triple: " <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z)
      _ -> temp_string1 = nil
    if ((arr.length > 0)), do: temp_string1 = Std.string(Enum.at(arr, 0)), else: temp_string1 = "none"
    temp_string = "length=" <> to_string(arr.length) <> ", first=" <> temp_string1
    end
      description = temp_string
      Log.trace("Array pattern: " <> description, %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "testArrayPatterns"})
    end)
  end

  @doc "Generated from Haxe testObjectPatterns"
  def test_object_patterns() do
    temp_string = nil

    point_x = 10

    point_y = 20

    g_array = point_x
    g_array = point_y
    x = g_array
    y = g_array
    if (((x > 0) && (y > 0))) do
      temp_string = "first"
    else
      x = g_array
      y = g_array
      if (((x < 0) && (y > 0))) do
        temp_string = "second"
      else
        x = g_array
        y = g_array
        if (((x < 0) && (y < 0))) do
          temp_string = "third"
        else
          x = g_array
          y = g_array
          if (((x > 0) && (y < 0))) do
            temp_string = "fourth"
          else
            if ((g_array == 0)) do
              temp_string = "axis"
            else
              if ((g_array == 0)), do: temp_string = "axis", else: temp_string = "origin"
            end
          end
        end
      end
    end

    Log.trace("Point " <> to_string(point_x) <> "," <> to_string(point_y) <> " is in " <> temp_string <> " quadrant", %{"fileName" => "Main.hx", "lineNumber" => 135, "className" => "Main", "methodName" => "testObjectPatterns"})
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
