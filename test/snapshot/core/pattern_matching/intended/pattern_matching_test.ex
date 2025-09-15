defmodule PatternMatchingTest do
  def match_color(color) do
    case color do
      :red ->
        "red"
      :green ->
        "green"
      :blue ->
        "blue"
      {:rgb, r, g, b} ->
        "rgb(#{r},#{g},#{b})"
    end
  end

  def match_option(option) do
    case option do
      :none ->
        "none"
      {:some, value} ->
        "some(#{inspect(value)})"
    end
  end

  def match_int(value) do
    case value do
      0 ->
        "zero"
      1 ->
        "one"
      n when n < 0 ->
        "negative"
      n when n > 100 ->
        "large"
      _ ->
        "other"
    end
  end

  def match_string(str) do
    case str do
      "" ->
        "empty"
      "hello" ->
        "greeting"
      s when byte_size(s) > 10 ->
        "long"
      _ ->
        "other"
    end
  end

  def match_array(arr) do
    case arr do
      [] ->
        "empty"
      [x] ->
        "single(#{x})"
      [x, y] ->
        "pair(#{x},#{y})"
      [x, y, z] ->
        "triple(#{x},#{y},#{z})"
      _ ->
        "many"
    end
  end

  def match_nested(option) do
    case option do
      :none ->
        "no color"
      {:some, :red} ->
        "red color"
      {:some, :green} ->
        "green color"
      {:some, :blue} ->
        "blue color"
      {:some, {:rgb, r, g, b}} when r > 128 ->
        "bright rgb"
      {:some, {:rgb, r, g, b}} ->
        "dark rgb"
    end
  end

  def match_bool(flag, count) do
    case {flag, count} do
      {true, 0} ->
        "true zero"
      {false, 0} ->
        "false zero"
      {true, n} when n > 0 ->
        "true positive"
      {false, n} when n > 0 ->
        "false positive"
      _ ->
        "other combination"
    end
  end

  def main() do
    # Test entry point for compilation
    Log.trace("Pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 110, :class_name => "PatternMatchingTest", :method_name => "main"})
  end
end