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
    color = :red
    temp_string = nil
    case (elem(color, 0)) do
      0 ->
        temp_string = "red"
      1 ->
        temp_string = "green"
      2 ->
        temp_string = "blue"
      3 ->
        _g_1 = elem(color, 1)
        _g_1 = elem(color, 2)
        _g_2 = elem(color, 3)
        temp_string = "custom"
    end
    Log.trace("Simple enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "testSimpleEnumPattern"})
  end

  @doc "Function test_complex_enum_pattern"
  @spec test_complex_enum_pattern() :: nil
  def test_complex_enum_pattern() do
    color = {:r_g_b, 255, 128, 0}
    temp_string = nil
    case (elem(color, 0)) do
      0 ->
        temp_string = "primary"
      1 ->
        temp_string = "primary"
      2 ->
        temp_string = "primary"
      3 ->
        _g_1 = elem(color, 1)
        _g_1 = elem(color, 2)
        _g_2 = elem(color, 3)
        r = _g_2
        g = _g_2
        b = _g_2
        if (r + g + b > 500), do: temp_string = "bright", else: r = _g_2
        g = _g_2
        b = _g_2
        if (r + g + b < 100), do: temp_string = "dark", else: r = _g_2
        g = _g_2
        b = _g_2
        temp_string = "medium"
    end
    Log.trace("Complex enum result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "testComplexEnumPattern"})
  end

  @doc "Function test_result_pattern"
  @spec test_result_pattern() :: nil
  def test_result_pattern() do
    result = {:ok, "success"}
    temp_string = nil
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        temp_string = "Got value: " <> value
      1 ->
        g = elem(result, 1)
        error = g
        temp_string = "Got error: " <> error
    end
    Log.trace("Result pattern: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "testResultPattern"})
  end

  @doc "Function test_guard_patterns"
  @spec test_guard_patterns() :: nil
  def test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            num = Enum.at(numbers, g)
          g = g + 1
          temp_string = nil
          n = num
    if (n < 5) do
      temp_string = "small"
    else
      n = num
      if (n >= 5 && n < 15) do
        temp_string = "medium"
      else
        n = num
        temp_string = if (n >= 15), do: "large", else: "unknown"
      end
    end
          category = temp_string
          Log.trace("Number " <> Integer.to_string(num) <> " is " <> category, %{"fileName" => "Main.hx", "lineNumber" => 98, "className" => "Main", "methodName" => "testGuardPatterns"})
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
  end

  @doc "Function test_array_patterns"
  @spec test_array_patterns() :: nil
  def test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < arrays.length) do
          try do
            arr = Enum.at(arrays, g)
          g = g + 1
          temp_string = nil
          case (arr.length) do
      0 ->
        temp_string = "empty"
      1 ->
        g = Enum.at(arr, 0)
        x = g
        temp_string = "single: " <> Integer.to_string(x)
      2 ->
        _g_1 = Enum.at(arr, 0)
        _g_1 = Enum.at(arr, 1)
        x = _g_1
        y = _g_1
        temp_string = "pair: " ++ x ++ ", " ++ y
      3 ->
        _g_1 = Enum.at(arr, 0)
        _g_1 = Enum.at(arr, 1)
        _g_2 = Enum.at(arr, 2)
        x = _g_2
        y = _g_2
        z = _g_2
        temp_string = "triple: " ++ x ++ ", " ++ y ++ ", " ++ z
      _ ->
        nil
        temp_string1 = if (arr.length > 0), do: Std.string(Enum.at(arr, 0)), else: "none"
        temp_string = "length=" <> Integer.to_string(arr.length) <> ", first=" <> (temp_string1)
    end
          description = temp_string
          Log.trace("Array pattern: " <> description, %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "testArrayPatterns"})
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
  end

  @doc "Function test_object_patterns"
  @spec test_object_patterns() :: nil
  def test_object_patterns() do
    point_x = 10
    point_y = 20
    temp_string = nil
    _g_1 = point_x
    _g_1 = point_y
    x = _g_1
    y = _g_1
    if (x > 0 && y > 0), do: temp_string = "first", else: x = _g_1
    y = _g_1
    if (x < 0 && y > 0), do: temp_string = "second", else: x = _g_1
    y = _g_1
    if (x < 0 && y < 0), do: temp_string = "third", else: x = _g_1
    y = _g_1
    if (x > 0 && y < 0), do: temp_string = "fourth", else: if (g == 0), do: temp_string = "axis", else: if (g == 0), do: temp_string = "axis", else: temp_string = "origin"
    Log.trace("Point " <> Integer.to_string(point_x) <> "," <> Integer.to_string(point_y) <> " is in " <> temp_string <> " quadrant", %{"fileName" => "Main.hx", "lineNumber" => 135, "className" => "Main", "methodName" => "testObjectPatterns"})
  end

end
