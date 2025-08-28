defmodule PatternMatchingTest do
  @moduledoc "PatternMatchingTest module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe matchColor"
  def match_color(color) do
    temp_result = nil

    temp_result = nil

    case color do
      0 -> temp_result = "red"
      1 -> temp_result = "green"
      2 -> temp_result = "blue"
      3 -> g_param_0 = elem(color, 1)
    g_param_1 = elem(color, 2)
    g_param_2 = elem(color, 3)
    r = g_param_2
    g_array = g_array
    b = g_param_2
    temp_result = "rgb(" <> to_string(r) <> "," <> to_string(g_array) <> "," <> to_string(b) <> ")"
    end

    temp_result
  end

  @doc "Generated from Haxe matchOption"
  def match_option(option) do
    temp_result = nil

    case option do
      0 -> temp_result = "none"
      1 -> value = elem(option, 1)
    temp_result = "some(" <> Std.string(value) <> ")"
    end

    temp_result
  end

  @doc "Generated from Haxe matchInt"
  def match_int(value) do
    temp_result = nil

    case value do
      0 -> "zero"
      1 -> "one"
      _ -> n = value
    if ((n < 0)) do
      temp_result = "negative"
    else
      n = value
      if ((n > 100)), do: temp_result = "large", else: temp_result = "other"
    end
    end

    temp_result
  end

  @doc "Generated from Haxe matchString"
  def match_string(str) do
    temp_result = nil

    case str do
      "" -> "empty"
      "hello" -> "greeting"
      _ -> s = str
    if ((s.length > 10)), do: temp_result = "long", else: temp_result = "other"
    end

    temp_result
  end

  @doc "Generated from Haxe matchArray"
  def match_array(arr) do
    temp_result = nil

    case arr.length do
      0 -> temp_result = "empty"
      1 -> g_array = Enum.at(arr, 0)
    x = g_array
    temp_result = "single(" <> to_string(x) <> ")"
      2 -> g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    x = g_array
    y = g_array
    temp_result = "pair(" <> to_string(x) <> "," <> to_string(y) <> ")"
      3 -> g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    g_array = Enum.at(arr, 2)
    x = g_array
    y = g_array
    z = g_array
    temp_result = "triple(" <> to_string(x) <> "," <> to_string(y) <> "," <> to_string(z) <> ")"
      _ -> temp_result = "many"
    end

    temp_result
  end

  @doc "Generated from Haxe matchNested"
  def match_nested(option) do
    temp_result = nil

    case option do
      0 -> temp_result = "no color"
      1 -> g_param_0 = elem(option, 1)
    case g_array do
      0 -> temp_result = "red color"
      1 -> temp_result = "green color"
      2 -> temp_result = "blue color"
      3 -> g_param_0 = elem(g_array, 1)
    g_param_1 = elem(g_array, 2)
    g_param_2 = elem(g_array, 3)
    r = g_param_2
    g_array = g_array
    _b = g_param_2
    if ((r > 128)) do
      temp_result = "bright rgb"
    else
      _r = g_param_2
      g_array = g_array
      _b = g_param_2
      temp_result = "dark rgb"
    end
    end
    end

    temp_result
  end

  @doc "Generated from Haxe matchBool"
  def match_bool(flag, count) do
    temp_result = nil

    if flag do
      if ((count == 0)) do
        temp_result = "true zero"
      else
        n = count
        if ((n > 0)), do: temp_result = "true positive", else: temp_result = "other combination"
      end
    else
      if ((count == 0)) do
        temp_result = "false zero"
      else
        n = count
        if ((n > 0)), do: temp_result = "false positive", else: temp_result = "other combination"
      end
    end

    temp_result
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("Pattern matching compilation test", %{"fileName" => "Main.hx", "lineNumber" => 110, "className" => "PatternMatchingTest", "methodName" => "main"})
  end

end
